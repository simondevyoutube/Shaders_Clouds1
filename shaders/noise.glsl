
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
// https://www.shadertoy.com/view/lsf3WH


float hash(vec2 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + vec2(0.71,0.113));
    return -1.0+2.0*fract( p.x*p.y*(p.x+p.y) );
}

float hash(vec3 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + vec3(0.71, 0.113, 0.5231));
    return -1.0+2.0*fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

vec2 hash2(vec2 p)
{
 	return fract(cos(p*mat2(57.3,37.36,83.17,-23.2))*28.9) * 2.0 - 1.0;   
}

vec2 hash2( ivec2 z )  // replace this anything that returns a random vector
{
    // 2D to 1D  (feel free to replace by some other)
    int n = z.x+z.y*11111;

    // Hugo Elias hash (feel free to replace by another one)
    n = (n<<13)^n;
    n = (n*(n*n*15731+789221)+1376312589)>>16;

    // Perlin style vectors
    n &= 7;
    vec2 gr = vec2(n&1,n>>1)*2.0-1.0;
    return ( n>=6 ) ? vec2(0.0,gr.x) : 
           ( n>=4 ) ? vec2(gr.x,0.0) :
                              gr;
}

vec3 hash3(vec2 p ) {
	vec3 p3 = vec3( dot(p,vec2(127.1,311.7)),
			  dot(p,vec2(269.5,183.3)),
			  dot(p,vec2(113.5,271.9)));

	return -1.0 + 2.0*fract(sin(p3)*43758.5453123);
}

vec3 hash3( vec3 p ) // replace this by something better
{
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
			  dot(p,vec3(269.5,183.3,246.1)),
			  dot(p,vec3(113.5,271.9,124.6)));

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

vec3 hash3( vec4 p ) // replace this by something better
{
	vec3 r = vec3(
      dot(p, vec4(127.1, 311.7, 74.7, 93.124)),
      dot(p, vec4(269.5, 183.3, 246.1, 55.432)),
      dot(p, vec4(113.5, 271.9, 124.6, 6.823)));

	return -1.0 + 2.0*fract(sin(r)*43758.5453123);
}

vec4 hash4( vec4 p ) // replace this by something better
{
	p = vec4( dot(p, vec4(127.1,311.7,74.7,93.124)),
            dot(p, vec4(269.5,183.3,246.1,55.432)),
            dot(p, vec4(113.5,271.9,124.6,6.823)),
            dot(p, vec4(37.643,83.42,17.531,11.952)));

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

uint murmurHash11(uint src) {
    const uint M = 0x5bd1e995u;
    uint h = 1190494759u;
    src *= M; src ^= src>>24u; src *= M;
    h *= M; h ^= src;
    h ^= h>>13u; h *= M; h ^= h>>15u;
    return h;
}

// 1 output, 1 input
// float hash1(float src) {
//     uint h = murmurHash11(floatBitsToUint(src));
//     return (uintBitsToFloat(h & 0x007fffffu | 0x3f800000u) - 1.0) * 2.0 - 1.0;
// }
float hash1( float p ) // replace this by something better
{
	p = p * 321.17;

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

// noise definition
float noise( in vec4 p ) {
  vec4 i = floor( p );
  vec4 f = fract( p );

	vec4 u = f * f * (3.0 - 2.0 * f);

  float z1 = mix( mix( mix( dot( hash4( i + vec4(0.0,0.0,0.0,0.0) ), f - vec4(0.0,0.0,0.0,0.0) ), 
                            dot( hash4( i + vec4(1.0,0.0,0.0,0.0) ), f - vec4(1.0,0.0,0.0,0.0) ), u.x),
                       mix( dot( hash4( i + vec4(0.0,1.0,0.0,0.0) ), f - vec4(0.0,1.0,0.0,0.0) ), 
                            dot( hash4( i + vec4(1.0,1.0,0.0,0.0) ), f - vec4(1.0,1.0,0.0,0.0) ), u.x), u.y),
                  mix( mix( dot( hash4( i + vec4(0.0,0.0,1.0,0.0) ), f - vec4(0.0,0.0,1.0,0.0) ), 
                            dot( hash4( i + vec4(1.0,0.0,1.0,0.0) ), f - vec4(1.0,0.0,1.0,0.0) ), u.x),
                       mix( dot( hash4( i + vec4(0.0,1.0,1.0,0.0) ), f - vec4(0.0,1.0,1.0,0.0) ), 
                            dot( hash4( i + vec4(1.0,1.0,1.0,0.0) ), f - vec4(1.0,1.0,1.0,0.0) ), u.x), u.y), u.z );
  float z2 = mix( mix( mix( dot( hash4( i + vec4(0.0,0.0,0.0,1.0) ), f - vec4(0.0,0.0,0.0,1.0) ), 
                            dot( hash4( i + vec4(1.0,0.0,0.0,1.0) ), f - vec4(1.0,0.0,0.0,1.0) ), u.x),
                       mix( dot( hash4( i + vec4(0.0,1.0,0.0,1.0) ), f - vec4(0.0,1.0,0.0,1.0) ), 
                            dot( hash4( i + vec4(1.0,1.0,0.0,1.0) ), f - vec4(1.0,1.0,0.0,1.0) ), u.x), u.y),
                  mix( mix( dot( hash4( i + vec4(0.0,0.0,1.0,1.0) ), f - vec4(0.0,0.0,1.0,1.0) ), 
                            dot( hash4( i + vec4(1.0,0.0,1.0,1.0) ), f - vec4(1.0,0.0,1.0,1.0) ), u.x),
                       mix( dot( hash4( i + vec4(0.0,1.0,1.0,1.0) ), f - vec4(0.0,1.0,1.0,1.0) ), 
                            dot( hash4( i + vec4(1.0,1.0,1.0,1.0) ), f - vec4(1.0,1.0,1.0,1.0) ), u.x), u.y), u.z );
  return mix(z1, z2, u.w);
}

float noise( in vec3 p )
{
    vec3 i = floor( p );
    vec3 f = fract( p );
	
	vec3 u = f*f*(3.0-2.0*f);

    return mix( mix( mix( dot( hash3( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                          dot( hash3( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                     mix( dot( hash3( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                          dot( hash3( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
                mix( mix( dot( hash3( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                          dot( hash3( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                     mix( dot( hash3( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                          dot( hash3( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

float noise( in vec2 p )
{
    vec2 i = vec2(floor( p ));
     vec2 f =       fract( p );
	
	vec2 u = f*f*(3.0-2.0*f); // feel free to replace by a quintic smoothstep instead

    return mix( mix( dot( hash2( i+vec2(0,0) ), f-vec2(0.0,0.0) ), 
                     dot( hash2( i+vec2(1,0) ), f-vec2(1.0,0.0) ), u.x),
                mix( dot( hash2( i+vec2(0,1) ), f-vec2(0.0,1.0) ), 
                     dot( hash2( i+vec2(1,1) ), f-vec2(1.0,1.0) ), u.x), u.y);
}

float noise( float p )
{
  float i = floor( p );
  float f = fract( p );
	
	float u = f*f*(3.0-2.0*f); // feel free to replace by a quintic smoothstep instead

  return mix( hash1( i + 0.0 ) * (f - 0.0), 
              hash1( i + 1.0 ) * (f - 1.0), u);
}

vec2 noise2(vec2 p) {
  return vec2(
      noise(p),
      noise(p + vec2(243.02935, 743.87439))
  );
}

vec3 noise3(vec2 p) {
  return vec3(
      noise(p),
      noise(p + vec2(243.02935, 743.87439)),
      noise(p + vec2(731.8735, 912.4724))
  );
}

vec3 noise3(vec3 p) {
  return vec3(
      noise(p),
      noise(p + vec3(243.02935, 743.87439, -17.5325)),
      noise(p + vec3(731.8735, 912.4724, 1231.43297))
  );
}

vec4 noise4(vec2 p) {
  return vec4(
      noise2(p),
      noise2(p.xy + vec2(314.421, -432.32))
  );
}

// return value noise (in x) and its derivatives (in yzw)
vec4 noiseD( in vec3 x )
{
  // grid
  vec3 i = floor(x);
  vec3 w = fract(x);

  // quintic interpolant
  vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
  vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);

  // gradients
  vec3 ga = hash3( i+vec3(0.0,0.0,0.0) );
  vec3 gb = hash3( i+vec3(1.0,0.0,0.0) );
  vec3 gc = hash3( i+vec3(0.0,1.0,0.0) );
  vec3 gd = hash3( i+vec3(1.0,1.0,0.0) );
  vec3 ge = hash3( i+vec3(0.0,0.0,1.0) );
  vec3 gf = hash3( i+vec3(1.0,0.0,1.0) );
  vec3 gg = hash3( i+vec3(0.0,1.0,1.0) );
  vec3 gh = hash3( i+vec3(1.0,1.0,1.0) );

  // projections
  float va = dot( ga, w-vec3(0.0,0.0,0.0) );
  float vb = dot( gb, w-vec3(1.0,0.0,0.0) );
  float vc = dot( gc, w-vec3(0.0,1.0,0.0) );
  float vd = dot( gd, w-vec3(1.0,1.0,0.0) );
  float ve = dot( ge, w-vec3(0.0,0.0,1.0) );
  float vf = dot( gf, w-vec3(1.0,0.0,1.0) );
  float vg = dot( gg, w-vec3(0.0,1.0,1.0) );
  float vh = dot( gh, w-vec3(1.0,1.0,1.0) );

  // interpolations
  return vec4(
      va + u.x*(vb-va) + u.y*(vc-va) + u.z*(ve-va) + u.x*u.y*(va-vb-vc+vd) + u.y*u.z*(va-vc-ve+vg) +
           u.z*u.x*(va-vb-ve+vf) + (-va+vb+vc-vd+ve-vf-vg+vh)*u.x*u.y*u.z,    // value
      ga + u.x*(gb-ga) + u.y*(gc-ga) + u.z*(ge-ga) + u.x*u.y*(ga-gb-gc+gd) + u.y*u.z*(ga-gc-ge+gg) +
           u.z*u.x*(ga-gb-ge+gf) + (-ga+gb+gc-gd+ge-gf-gg+gh)*u.x*u.y*u.z +   // derivatives
           du * (vec3(vb,vc,ve) - va + u.yzx*vec3(va-vb-vc+vd,va-vc-ve+vg,va-vb-ve+vf) +
              u.zxy*vec3(va-vb-ve+vf,va-vb-vc+vd,va-vc-ve+vg) + u.yzx*u.zxy*(-va+vb+vc-vd+ve-vf-vg+vh) ));
}

const mat2 FBM_M = mat2( 0.80,  0.60, -0.60,  0.80 );
const mat3 FBM_M3 = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float fbm(vec3 p, int octaves, float persistence, float lacunarity, float exponentiation) {
  float amplitude = 1.0;
  float frequency = 1.0;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = noise(p * frequency);
    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    frequency *= lacunarity;
  }

  total /= normalization;
  total = total * 0.5 + 0.5;
  total = pow(total, exponentiation);
  // total = 1.0 - abs(total);

  return total;
}

// noiseFBM function
float noiseFBM(vec4 p, int octaves, float persistence, float lacunarity) {
  float amplitude = 0.5;
  float frequency = 1.0;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = noise(p * frequency);
    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    frequency *= lacunarity;
  }

  return total;
}

float noiseFBM(vec3 p, int octaves, float persistence, float lacunarity) {
  float amplitude = 0.5;
  float frequency = 1.0;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = noise(p * frequency);
    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    frequency *= lacunarity;
  }

  return total;
}

float noiseFBM(vec2 p, int octaves, float persistence, float lacunarity) {
  float amplitude = 0.5;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = noise(p);
    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    p = FBM_M * p * lacunarity;
  }

  return total;
}

float noiseFBM(float p, int octaves, float persistence, float lacunarity) {
  float amplitude = 0.5;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = noise(p);
    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    p = p * lacunarity;
  }

  total /= normalization;

  return total;
}

// noiseFBM3 definition
vec3 noiseFBM3(vec3 p, int octaves, float persistence, float lacunarity) {
  return vec3(
      noiseFBM(p, octaves, persistence, lacunarity),
      noiseFBM(p + 13.2317, octaves, persistence, lacunarity),
      noiseFBM(p + -34.934, octaves, persistence, lacunarity)
  );
}

vec3 noiseFBM3(vec4 p, int octaves, float persistence, float lacunarity) {
  return vec3(
      noiseFBM(p, octaves, persistence, lacunarity),
      noiseFBM(p + 13.2317, octaves, persistence, lacunarity),
      noiseFBM(p + -34.934, octaves, persistence, lacunarity)
  );
}

vec2 noiseFBM2(vec2 p, int octaves, float persistence, float lacunarity) {
  return vec2(
      noiseFBM(p, octaves, persistence, lacunarity),
      noiseFBM(p + 13.2317, octaves, persistence, lacunarity)
  );
}

vec2 noiseFBM2(vec3 p, int octaves, float persistence, float lacunarity) {
  return vec2(
      noiseFBM(p, octaves, persistence, lacunarity),
      noiseFBM(p + vec3(432.532, 5326.3245, -95.9043), octaves, persistence, lacunarity)
  );
}

float noiseWarp(vec3 coords) {
  vec3 offset = vec3(
    noiseFBM(coords, 4, 0.5, 2.0),
    noiseFBM(coords + vec3(43.235, 23.112, 0.0), 4, 0.5, 2.0), 0.0);
  float noiseSample = noiseFBM(coords + offset, 1, 0.5, 2.0);

  vec3 offset2 = vec3(
    noiseFBM(coords + 4.0 * offset + vec3(5.325, 1.421, 3.235), 4, 0.5, 2.0),
    noiseFBM(coords + 4.0 * offset + vec3(4.32, 0.532, 6.324), 4, 0.5, 2.0), 0.0);
  noiseSample = noiseFBM(coords + 4.0 * offset2, 1, 0.5, 2.0);

  return noiseSample;
}

float noiseWarp(vec2 coords) {
  vec2 offset = noiseFBM2(coords, 4, 0.5, 2.0);
  float noiseSample = noiseFBM(coords + offset, 1, 0.5, 2.0);

  vec2 offset2 = noiseFBM2(coords + 4.0 * offset + vec2(5.325, 1.421), 4, 0.5, 2.0);
  noiseSample = noiseFBM(coords + 4.0 * offset2, 1, 0.5, 2.0);

  return noiseSample;
}

float voronoi(vec2 coords, float maxOffset) {
  vec2 gridBasePosition = floor(coords.xy);
  vec2 gridCoordOffset = fract(coords.xy);

  float closest = 1.0;
  for (float y = -2.0; y <= 2.0; y += 1.0) {
    for (float x = -2.0; x <= 2.0; x += 1.0) {
      vec2 neighbourCellPosition = vec2(x, y);
      vec2 cellWorldPosition = gridBasePosition + neighbourCellPosition;
      vec2 cellOffset = hash2(cellWorldPosition);
      cellOffset *= maxOffset;

      float distToNeighbour = length(
          neighbourCellPosition + cellOffset - gridCoordOffset);
      closest = min(closest, distToNeighbour);
    }
  }

  return closest;
}