#define PI 3.14159265359


float saturate(float x) {
  return clamp(x, 0.0, 1.0);
}

vec3 saturate3(vec3 x) {
  return clamp(x, vec3(0.0), vec3(1.0));
}


float linearstep(float minValue, float maxValue, float v) {
  return clamp((v - minValue) / (maxValue - minValue), 0.0, 1.0);
}

float inverseLerp(float minValue, float maxValue, float v) {
  return (v - minValue) / (maxValue - minValue);
}

float inverseLerpSat(float minValue, float maxValue, float v) {
  return saturate((v - minValue) / (maxValue - minValue));
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(inMin, inMax, v);
  return mix(outMin, outMax, t);
}

float smootherstep(float edge0, float edge1, float x) {
  x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

vec2 smootherstep2(vec2 edge0, vec2 edge1, vec2 x) {
  x = clamp((x - edge0) / (edge1 - edge0), vec2(0.0), vec2(1.0));
  return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

vec3 smootherstep3(vec3 edge0, vec3 edge1, vec3 x) {
  x = clamp((x - edge0) / (edge1 - edge0), vec3(0.0), vec3(1.0));
  return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

float circularOut(float t) {
  return sqrt((2.0 - t) * t);
}

/////////////////////////////////////////////////////////////////////////
//
// 3D SDF's
//
/////////////////////////////////////////////////////////////////////////

// https://iquilezles.org/articles/distfunctions/

float sdfSphere(vec3 p, float r) {
  return length(p) - r;
}

float sdfBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdCutSphere( vec3 p, float r, float h )
{
  // sampling independent computations (only depend on shape)
  float w = sqrt(r*r-h*h);

  // sampling dependant computations
  vec2 q = vec2( length(p.xz), p.y );
  float s = max( (h-r)*q.x*q.x+w*w*(h+r-2.0*q.y), h*q.x-w*q.y );
  return (s<0.0) ? length(q)-r :
         (q.x<w) ? h - q.y     :
                   length(q-vec2(w,h));
}

/////////////////////////////////////////////////////////////////////////
//
// Misc
//
/////////////////////////////////////////////////////////////////////////
vec3 vignette(vec2 uvs) {
  float v1 = smoothstep(0.5, 0.3, abs(uvs.x - 0.5));
  float v2 = smoothstep(0.5, 0.3, abs(uvs.y - 0.5));
  float v = v1 * v2;
  v = pow(v, 0.25);
  v = remap(v, 0.0, 1.0, 0.4, 1.0);
  return vec3(v);
}


/////////////////////////////////////////////////////////////////////////
//
// ToneMapping Operators
//
/////////////////////////////////////////////////////////////////////////
vec3 ACESToneMap(vec3 color){	
	mat3 m1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
	);
	mat3 m2 = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602
	);
	vec3 v = m1 * color;    
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
	return saturate3(m2 * (a / b));	
}

/////////////////////////////////////////////////////////////////////////
//
// Intersections
//
/////////////////////////////////////////////////////////////////////////

// Return the near and far intersections of an infinite ray and a sphere. 
// Assumes sphere at origin. No intersection if result.x > result.y
vec2 sphereIntersections(vec3 start, vec3 dir, float radius){
	float a = dot(dir, dir);
	float b = 2.0 * dot(dir, start);
    float c = dot(start, start) - (radius * radius);
	float d = (b*b) - 4.0*a*c;
	if (d < 0.0){
        return vec2(1e5, -1e5);
	}
	return vec2((-b - sqrt(d))/(2.0*a), (-b + sqrt(d))/(2.0*a));
}

struct AABB {
  vec3 min;
  vec3 max;
};

struct AABBIntersectResult {
  float near;
  float far;
};

bool insideAABB(vec3 rayOrigin, AABB box) {
  return all(lessThanEqual(rayOrigin, box.max)) && all(lessThan(box.min, rayOrigin));
}

// https://gist.github.com/DomNomNom/46bb1ce47f68d255fd5d
// Compute the near and far intersections using the slab method.
// No intersection if tNear > tFar.
AABBIntersectResult intersectAABB(vec3 rayOrigin, vec3 rayDir, AABB box) {
    vec3 tMin = (box.min - rayOrigin) / rayDir;
    vec3 tMax = (box.max - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return AABBIntersectResult(tNear, tFar);
}

struct AABB2D {
  vec2 min;
  vec2 max;
};

struct AABB2DIntersectResult {
  float near;
  float far;
};

bool insideAABB(vec2 rayOrigin, AABB2D box) {
  return all(lessThanEqual(rayOrigin, box.max)) && all(lessThan(box.min, rayOrigin));
}

// https://gist.github.com/DomNomNom/46bb1ce47f68d255fd5d
// Compute the near and far intersections using the slab method.
// No intersection if tNear > tFar.
AABB2DIntersectResult intersectAABB2D(vec2 rayOrigin, vec2 rayDir, AABB2D box) {
    vec2 tMin = (box.min - rayOrigin) / rayDir;
    vec2 tMax = (box.max - rayOrigin) / rayDir;
    vec2 t1 = min(tMin, tMax);
    vec2 t2 = max(tMin, tMax);
    float tNear = max(t1.x, t1.y);
    float tFar = min(t2.x, t2.y);
    return AABB2DIntersectResult(tNear, tFar);
}

