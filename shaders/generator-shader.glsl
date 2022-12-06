
uniform float zLevel;
uniform float numCells;

vec3 hash3_New(vec3 p, float tileLength) {
  p = mod(p, vec3(tileLength));
	p = vec3(
      dot(p,vec3(127.1,311.7, 74.7)),
			dot(p,vec3(269.5,183.3,246.1)),
			dot(p,vec3(113.5,271.9,124.6)));

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float voronoiSlow(float maxOffset, float cellsMult, float seed) {
  vec3 coords = vec3(vUvs * cellsMult, zLevel);
  vec3 seedHash = hash3(vec3(seed, seed * seed * 3.14159, seed * 1.17421));

  vec3 gridBasePosition = floor(coords);
  vec3 gridCoordOffset = fract(coords);
  float maxCellSearch = ceil(maxOffset) + 1.0;

  float closest = 1.0;
  for (float y = -maxCellSearch; y <= maxCellSearch; y += 1.0) {
    for (float x = -maxCellSearch; x <= maxCellSearch; x += 1.0) {
      for (float z = -maxCellSearch; z <= maxCellSearch; z += 1.0) {
        vec3 neighbourCellPosition = vec3(x, y, z);
        vec3 cellWorldPosition = gridBasePosition + neighbourCellPosition;
        cellWorldPosition.xy = mod(cellWorldPosition.xy, vec2(cellsMult));

        vec3 cellOffset = hash3(cellWorldPosition + seedHash);
        cellOffset *= maxOffset;

        float distToNeighbour = length(
            neighbourCellPosition + cellOffset - gridCoordOffset);
        closest = min(closest, distToNeighbour);
      }
    }
  }

  return saturate(closest);
}

float gradientNoise(vec3 p, float tileLength) {
  vec3 i = floor(p);
  vec3 f = fract(p);
	
	vec3 u = smootherstep3(vec3(0.0), vec3(1.0), f);
    
  /*
  * For 1D, the gradient of slope g at vertex u has the form h(x) = g * (x - u), where u 
  * is an integer and g is in [-1, 1]. This is the equation for a line with slope g which 
  * intersects the x-axis at u.
  * For N dimensional noise, use dot product instead of multiplication, and do 
  * component-wise interpolation (for 3D, trilinear)
  */
  return mix( mix( mix( dot( hash3_New(i + vec3(0.0,0.0,0.0), tileLength), f - vec3(0.0,0.0,0.0)), 
                        dot( hash3_New(i + vec3(1.0,0.0,0.0), tileLength), f - vec3(1.0,0.0,0.0)), u.x),
                   mix( dot( hash3_New(i + vec3(0.0,1.0,0.0), tileLength), f - vec3(0.0,1.0,0.0)), 
                        dot( hash3_New(i + vec3(1.0,1.0,0.0), tileLength), f - vec3(1.0,1.0,0.0)), u.x), u.y),
              mix( mix( dot( hash3_New(i + vec3(0.0,0.0,1.0), tileLength), f - vec3(0.0,0.0,1.0)), 
                        dot( hash3_New(i + vec3(1.0,0.0,1.0), tileLength), f - vec3(1.0,0.0,1.0)), u.x),
                   mix( dot( hash3_New(i + vec3(0.0,1.0,1.0), tileLength), f - vec3(0.0,1.0,1.0)), 
                        dot( hash3_New(i + vec3(1.0,1.0,1.0), tileLength), f - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );
}

// https://github.com/sebh/TileableVolumeNoise/blob/master/TileableVolumeNoise.cpp
float tileableFBM(vec3 p, float tileLength) {
  const float persistence = 0.5;
  const float lacunarity = 2.0;
  const int octaves = 8;

  float amplitude = 0.5;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = gradientNoise(p, tileLength * lacunarity * 0.5) * 0.5 + 0.5;
    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    p = p * lacunarity;
  }

  total /= normalization;
  total = smootherstep(0.0, 1.0, total);

  return total;
}

// https://github.com/sebh/TileableVolumeNoise/blob/master/main.cpp
vec4 PerlinWorleyDetails(float CELL_RANGE, float numCells, float mult) {
  float perlinWorley = 0.0;
  {
    float worley0 = 1.0 - voronoiSlow(CELL_RANGE, numCells * 2.0 * mult, 1.0);
    float worley1 = 1.0 - voronoiSlow(CELL_RANGE, numCells * 8.0 * mult, 2.0);
    float worley2 = 1.0 - voronoiSlow(CELL_RANGE, numCells * 16.0 * mult, 3.0);
    float worleyFBM = worley0 * 0.625 + worley1 * 0.25 + worley2 * 0.125;

    float tileLength = 8.0;
    float fbm0 = tileableFBM(vec3(vUvs * tileLength, zLevel) * mult, tileLength);

    perlinWorley = remap(fbm0, 0.0, 1.0, worleyFBM, 1.0);
  }

  float worley0 = 1.0 - voronoiSlow(CELL_RANGE, numCells * 1.0 * mult, 4.0);
  float worley1 = 1.0 - voronoiSlow(CELL_RANGE, numCells * 2.0 * mult, 5.0);
  float worley2 = 1.0 - voronoiSlow(CELL_RANGE, numCells * 4.0 * mult, 6.0);
  float worley3 = 1.0 - voronoiSlow(CELL_RANGE, numCells * 8.0 * mult, 7.0);
  float worley4 = 1.0 - voronoiSlow(CELL_RANGE, numCells * 16.0 * mult, 8.0);
  float worley5 = 1.0 - voronoiSlow(CELL_RANGE, numCells * 32.0 * mult, 9.0);

  float worleyFBM0 = worley1 * 0.625 + worley2 * 0.25 + worley3 * 0.125;
  float worleyFBM1 = worley2 * 0.625 + worley3 * 0.25 + worley4 * 0.125;
  float worleyFBM2 = worley3 * 0.625 + worley4 * 0.25 + worley5 * 0.125;

  float lowFreqFBM = worleyFBM0 * 0.625 + worleyFBM1 * 0.25 + worleyFBM2 * 0.125;

  float tileLength = 8.0;
  float perlinWorleyDetail = remap(perlinWorley, lowFreqFBM, 1.0, 0.0, 1.0);

  return vec4(perlinWorley, perlinWorleyDetail, 0.0, 0.0);
}


void main() {
  const float CELL_RANGE = 1.0;

  vec4 perlinWorleyDetail1 = PerlinWorleyDetails(CELL_RANGE, numCells, 1.0);

  gl_FragColor = perlinWorleyDetail1;
}

