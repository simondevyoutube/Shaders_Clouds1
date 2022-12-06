const float GOLDEN_RATIO = 1.61803398875;
const vec3 EXTINCTION_MULT = vec3(0.8, 0.8, 1.0);

const float DUAL_LOBE_WEIGHT = 0.7;
const float AMBIENT_STRENGTH = 0.1;

const float CLOUD_LIGHT_MULTIPLIER = 50.0;
const vec3 CLOUD_LIGHT_DIR = normalize(vec3(-1.0, 0.0, 0.0));

const float CLOUD_EXPOSURE = 1.0;
const float CLOUD_STEPS_MIN = 16.0;
const float CLOUD_STEPS_MAX = 128.0;
const float CLOUD_LIGHT_STEPS = 12.0;
const float CLOUD_DENSITY = 0.5;

const vec3 CLOUD_OFFSET = vec3(0.0, 0.0, 0.0);

vec3 CLOUD_SIZE = vec3(4000.0);
vec3 CLOUD_BOUNDS_MIN;
vec3 CLOUD_BOUNDS_MAX;

const float CLOUD_BASE_STRENGTH = 0.8;
const float CLOUD_DETAIL_STRENGTH = 0.2;

const vec3 CLOUD_COLOUR = vec3(1.0);
const float CLOUD_FALLOFF = 25.0;

// #define SHOW_CLOUD_MAP


float HenyeyGreenstein(float g, float mu) {
  float gg = g * g;
	return (1.0 / (4.0 * PI))  * ((1.0 - gg) / pow(1.0 + gg - 2.0 * g * mu, 1.5));
}

float IsotropicPhaseFunction(float g, float costh) {
  return 1.0 / (4.0 * PI);
}

float DualHenyeyGreenstein(float g, float costh) {
  return mix(HenyeyGreenstein(-g, costh), HenyeyGreenstein(g, costh), DUAL_LOBE_WEIGHT);
}

float PhaseFunction(float g, float costh) {
  return DualHenyeyGreenstein(g, costh);
}


vec4 SamplePerlinWorleyNoise(vec3 pos) {
  vec3 coord = pos.xzy * vec3(1.0 / 32.0, 1.0 / 32.0, 1.0 / 64.0) * 1.0;
  vec4 s = texture(perlinWorley, coord);

  return s;
}


float SampleLowResolutionCloudMap(vec3 p) {
  float sdfValue = sdfBox(p, vec3(50.0));

  sdfValue = sdCutSphere(p, 60.0, -40.0);
  sdfValue = min(sdfValue, sdCutSphere(p - vec3(60.0, -20.0, 0.0), 40.0, -20.0));
  sdfValue = min(sdfValue, sdCutSphere(p - vec3(-60.0, -20.0, -50.0), 20.0, -20.0));

  return sdfValue;
}

float SampleHighResolutionCloudDetail(float cloudSDF, vec3 worldPos, vec3 cameraOrigin, float curTime) {
  float cloud = circularOut(linearstep(0.0, -CLOUD_FALLOFF, cloudSDF)) * 0.85;

  if(cloud > 0.0) {
    vec3 samplePos = worldPos + vec3(-2.0 * curTime, 0.0, curTime) * 1.5;

    float shapeSize = 0.4;
    vec4 perlinWorleySample = SamplePerlinWorleyNoise(samplePos * shapeSize);

    float shapeStrength = CLOUD_BASE_STRENGTH;
    cloud = saturate(remap(cloud, shapeStrength * perlinWorleySample.x, 1.0, 0.0, 1.0));

    if(cloud > 0.0) {
      float distToSample = distance(cameraOrigin, worldPos);
      float t_detailDropout = smoothstep(1000.0, 800.0, distToSample);

      if (t_detailDropout > 0.0) {
        samplePos += vec3(4.0 * curTime, 3.0 * curTime, 2.0 * curTime) * 0.01;

        float detailSize = 1.8;
        float detailStrength = CLOUD_DETAIL_STRENGTH * t_detailDropout;
        float detail = SamplePerlinWorleyNoise(detailSize * samplePos).y;
        cloud = saturate(remap(cloud, detailStrength * detail, 1.0, 0.0, 1.0));
      }
    }
  }

  return cloud * CLOUD_DENSITY;
}


// Adapted from: https://twitter.com/FewesW/status/1364629939568451587/photo/1
vec3 MultipleOctaveScattering(float density, float mu) {
  float attenuation = 0.2;
  float contribution = 0.2;
  float phaseAttenuation = 0.5;

  float a = 1.0;
  float b = 1.0;
  float c = 1.0;
  float g = 0.85;
  const float scatteringOctaves = 4.0;
  
  vec3 luminance = vec3(0.0);

  for (float i = 0.0; i < scatteringOctaves; i++) {
    float phaseFunction = PhaseFunction(0.3 * c, mu);
    vec3 beers = exp(-density * EXTINCTION_MULT * a);

    luminance += b * phaseFunction * beers;

    a *= attenuation;
    b *= contribution;
    c *= (1.0 - phaseAttenuation);
  }
  return luminance;
}


vec3 CalculateLightEnergy(
    vec3 lightOrigin, vec3 lightDirection, vec3 cameraOrigin, float mu, float maxDistance, float curTime) {
  float stepLength = maxDistance / CLOUD_LIGHT_STEPS;
	float lightRayDensity = 0.0;
  float distAccumulated = 0.0;

  for(float j = 0.0; j < CLOUD_LIGHT_STEPS; j++) {
    vec3 lightSamplePos = lightOrigin + lightDirection * distAccumulated;
	
    float cloudSDF = SampleLowResolutionCloudMap(lightSamplePos);

    lightRayDensity += SampleHighResolutionCloudDetail(cloudSDF, lightSamplePos, cameraOrigin, curTime) * stepLength;
    distAccumulated += stepLength;
  }

	vec3 beersLaw = MultipleOctaveScattering(lightRayDensity, mu);
  vec3 powder = 1.0 - exp(-lightRayDensity * 2.0 * EXTINCTION_MULT);

	return beersLaw * mix(2.0 * powder, vec3(1.0), remap(mu, -1.0, 1.0, 0.0, 1.0));
}

struct ScatteringTransmittance {
  vec3 scattering;
  vec3 transmittance;
};

ScatteringTransmittance CloudMarch(vec2 pixelCoords, vec3 cameraOrigin, vec3 cameraDirection, float curTime) {
  AABB cloudAABB;
  cloudAABB.min = CLOUD_BOUNDS_MIN;
  cloudAABB.max = CLOUD_BOUNDS_MAX;

  ScatteringTransmittance result;
  result.scattering = vec3(0.0);
  result.transmittance = vec3(1.0);

  AABBIntersectResult rayCloudIntersection = intersectAABB(cameraOrigin, cameraDirection, cloudAABB);
  if (rayCloudIntersection.near >= rayCloudIntersection.far) {
    // Debug
    // return vec4(vec3(0.0), 0.0);
    return result;
  }

  if (insideAABB(cameraOrigin, cloudAABB)) {
    rayCloudIntersection.near = 0.0;
  }

  vec3 sunDirection = CLOUD_LIGHT_DIR;
  vec3 sunLightColour = vec3(1.0);
  vec3 sunLight = sunLightColour * CLOUD_LIGHT_MULTIPLIER;
  vec3 ambient = vec3(AMBIENT_STRENGTH * sunLightColour);

  // TODO: Cap steps based on distance
  vec2 aspect = vec2(1.0, resolution.y / resolution.x);
  float blueNoiseSample = texture2D(blueNoise, (pixelCoords / resolution + 0.5) * aspect * (resolution.x / 32.0)).x;

  // Animating Noise For Integration Over Time
  // https://blog.demofox.org/2017/10/31/animating-noise-for-integration-over-time/
  blueNoiseSample = fract(blueNoiseSample + float(frame % 32) * GOLDEN_RATIO);

  float mu = dot(cameraDirection, sunDirection);
	float phaseFunction = PhaseFunction(0.3, mu);

  float distNearToFar = rayCloudIntersection.far - rayCloudIntersection.near;
  float stepDropoff = linearstep(1.0, 0.0, pow(dot(vec3(0.0, 1.0, 0.0), cameraDirection), 4.0));

  const int NUM_COUNT = 16;
  float lqStepLength = distNearToFar / CLOUD_STEPS_MIN; 
  float hqStepLength = lqStepLength / float(NUM_COUNT);
  float numCloudSteps = CLOUD_STEPS_MAX;

  float offset = lqStepLength * blueNoiseSample;
  float distTravelled = rayCloudIntersection.near;

  int hqMarcherCountdown = 0;

  float previousStepLength = 0.0;

	for (float i = 0.0; i < numCloudSteps; i++) {
    if (distTravelled > rayCloudIntersection.far) {
      break;
    }

    vec3 samplePos = cameraOrigin + cameraDirection * distTravelled;
    float cloudMapSDFSample = SampleLowResolutionCloudMap(samplePos);

    float currentStepLength = cloudMapSDFSample;

    if (hqMarcherCountdown <= 0) {
      if (cloudMapSDFSample < hqStepLength) {
        // Hit some clouds, step back
        hqMarcherCountdown = NUM_COUNT;

        distTravelled += hqStepLength * blueNoiseSample;

      } else {
        distTravelled += currentStepLength;
        continue;
      }
    }

    if (hqMarcherCountdown > 0) {
      hqMarcherCountdown--;

      if (cloudMapSDFSample < 0.0) {
        hqMarcherCountdown = NUM_COUNT;

        float extinction = SampleHighResolutionCloudDetail(cloudMapSDFSample, samplePos, cameraOrigin, curTime);

        if (extinction > 0.01) {
          vec3 luminance = ambient + sunLight * CalculateLightEnergy(samplePos, sunDirection, cameraOrigin, mu, 50.0, curTime);
          vec3 transmittance = exp(-extinction * hqStepLength * EXTINCTION_MULT);
          vec3 integScatt = extinction * (luminance - luminance * transmittance) / extinction;

          result.scattering += result.transmittance * integScatt;
          result.transmittance *= transmittance;  

          if (length(result.transmittance) <= 0.01) {
            result.transmittance = vec3(0.0);
            break;
          }
        }
      }

      distTravelled += hqStepLength;
    }

    previousStepLength = currentStepLength;
	}

  result.scattering = col3(result.scattering) * CLOUD_COLOUR;
  result.transmittance = saturate3(result.transmittance);
  return result;
}


float RenderGlow(float dist, float radius, float intensity) {
  dist = max(dist, 1e-6);
	return (1.0 - exp(-25.0 * (radius / dist))) * 0.1 + (1.0 - exp(-0.05 * (radius / dist) * (radius / dist))) * 2.0;
}

vec4 RenderSky(vec3 cameraOrigin, vec3 cameraDir, float curTime) {
  vec3 pos;
  float skyT1 = pow(smoothstep(0.0, 1.0, vUvs.y), 0.5);
  float skyT2 = pow(smoothstep(0.5, 1.0, vUvs.y), 1.0);

  vec3 c1 = col3(COLOUR_LIGHT_BLUE * 0.25);
  vec3 c2 = col3(COLOUR_BRIGHT_BLUE);
  vec3 c3 = col3(COLOUR_BRIGHT_BLUE * 1.25);
  vec3 sky = mix(c1, c2, skyT1);
  sky = mix(sky, c3, skyT2);

  float mu = remap(dot(cameraDir, CLOUD_LIGHT_DIR), -1.0, 1.0, 1.0, 0.0);
  float glow = RenderGlow(mu, 0.001, 0.5);

  sky += col3(glow, glow, 0.0);

  vec4 result = vec4(sky, 0.0);
  return result;
}


mat3 MakeCamera(vec3 ro, vec3 rd, vec3 ru) {
	vec3 z = normalize(rd - ro);
	vec3 cp = ru;
	vec3 x = normalize(cross(z, cp));
	vec3 y = cross(x, z);
  return mat3(x, y, z);
}


void main() {
  vec2 pixelCoords = (vUvs - 0.5) * resolution;
  float curTime = time * TIME_SPEED + TIME_OFFSET;

  CLOUD_SIZE = vec3(100.0);
  CLOUD_BOUNDS_MIN = CLOUD_OFFSET - CLOUD_SIZE;
  CLOUD_BOUNDS_MAX = CLOUD_OFFSET + CLOUD_SIZE;

  vec3 rayOrigin = vec3(200.0, 50.0, -150.0) * 0.75;
  vec3 rayLookAt = vec3(80.0, -10.0, 45.0) + CLOUD_LIGHT_DIR * 150.0;
  mat3 camera = MakeCamera(rayOrigin, rayLookAt, vec3(0.0, 1.0, 0.0));

  vec2 rayCoords = (2.0 * (gl_FragCoord.xy - 0.5) - resolution) / resolution.y;
  vec3 rayDir = normalize(vec3(rayCoords, 2.0));

  vec4 pixel = RenderSky(rayOrigin, camera * rayDir, curTime);
 
  ScatteringTransmittance scatterTransmittance = CloudMarch(
      pixelCoords, rayOrigin, normalize(camera * rayDir), curTime);

  vec3 colour;

#ifdef USE_OKLAB
  colour = oklabToRGB(pixel.xyz) * scatterTransmittance.transmittance + oklabToRGB(scatterTransmittance.scattering) * CLOUD_EXPOSURE;
  colour = ACESToneMap(colour);
  colour = col3(colour);
#else
  colour = pixel.xyz * scatterTransmittance.transmittance + scatterTransmittance.scattering * CLOUD_EXPOSURE;
  colour = ACESToneMap(colour);
#endif

  gl_FragColor = vec4(colour, pixel.w);
}

