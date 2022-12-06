

uniform sampler2D frameTexture;
uniform vec2 frameResolution;


void main() {
  vec2 pixelCoords = (vUvs - 0.5) * resolution;

  float curTime = time*TIME_SPEED + TIME_OFFSET;

  vec4 colour = texture(frameTexture, vUvs);

#ifdef USE_OKLAB
  colour.xyz = oklabToRGB(colour.xyz);
#endif

  // Vignette
  colour.xyz *= vignette(vUvs);
  colour.xyz = pow(saturate3(colour.xyz), vec3(1.0 / 2.2));

  gl_FragColor = vec4(colour.xyz, 1.0);
}

