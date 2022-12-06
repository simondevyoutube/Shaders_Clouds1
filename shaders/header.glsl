
precision highp float;
precision highp sampler2DArray;
precision highp sampler3D;
precision highp float;
precision highp int;

varying vec2 vUvs;
uniform vec2 resolution;
uniform float time;
uniform int frame;

uniform sampler2D blueNoise;
uniform sampler3D perlinWorley;


vec3 COLOUR_LIGHT_BLUE = vec3(0.42, 0.65, 0.85);
vec3 COLOUR_LIGHT_GREEN = vec3(0.25, 1.0, 0.25);
vec3 COLOUR_PALE_GREEN = vec3(0.42, 0.85, 0.65);
vec3 COLOUR_LIGHT_PURPLE = vec3(0.85, 0.25, 0.85);
vec3 COLOUR_BRIGHT_PINK = vec3(1.0, 0.5, 0.5);

vec3 COLOUR_BRIGHT_RED = vec3(1.0, 0.1, 0.02);
vec3 COLOUR_BRIGHT_BLUE = vec3(0.01, 0.2, 1.0);
vec3 COLOUR_BRIGHT_GREEN = vec3(0.01, 1.0, 0.2);
vec3 COLOUR_PALE_BLUE = vec3(0.42, 0.65, 0.85);
vec3 COLOUR_LIGHT_YELLOW = vec3(1.0, 1.0, 0.25);


const float TIME_OFFSET = 0.0;
const float TIME_SPEED = 1.0;


#define USE_OKLAB