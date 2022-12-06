uniform float zLevel;
uniform float numCells;


float GenerateGridClouds(vec3 coords, float seed, float CELL_WIDTH) {
  vec3 cellCoords = vec3((fract(coords.xy / CELL_WIDTH) - 0.5) * CELL_WIDTH, coords.z);
  vec2 cellID = floor(coords.xy / CELL_WIDTH) + hash2(vec2(seed));

  float radius = remap(hash1(seed), -1.0, 1.0, 25.0, 45.0);

  vec3 cellHashValue = hash3(vec3(cellID, seed)) * (CELL_WIDTH * 0.5 - radius);
  vec3 cloudPosition = vec3(0.0);

  cloudPosition.xy += cellHashValue.xy;
  // cloudPosition.z += cellHashValue.z * 0.1;

  return sdfSphere(cellCoords - cloudPosition, radius);
}

float GenerateCloudCluster(vec3 coords, float seed, float CELL_WIDTH) {
  if (hash1(seed * 3.124513 + 0.001) < 0.5) {
    return 100000.0;
  }

  vec3 cellCoords = vec3((fract(coords.xy / CELL_WIDTH) - 0.5) * CELL_WIDTH, coords.z);
  vec2 cellID = floor(coords.xy / CELL_WIDTH) + hash2(vec2(seed));

  float radius = 40.0;

  vec3 cellHashValue = hash3(vec3(cellID, seed));
  vec3 cloudPosition = cellHashValue * vec3(1.0, 1.0, 0.0) * (CELL_WIDTH * 0.25 - radius);
  cloudPosition.z = -radius * 0.5;

  float sdfValue = sdfSphere(cellCoords - cloudPosition, radius);

  for (float i = 0.0; i < 32.0; ++i) {
    float curSeed = seed + i * 0.0001;

    radius = remap(hash1(curSeed), -1.0, 1.0, 30.0, 40.0);
    cellHashValue = hash3(vec3(cellID, curSeed)) * (CELL_WIDTH * 0.125 - radius);
    vec3 offset = cellHashValue * vec3(1.0, 1.0, 0.0);
    offset.z = -radius * 0.5;

    sdfValue = min(sdfValue, sdfSphere(cellCoords - (cloudPosition + offset), radius));
  }

  for (float i = 0.0; i < 32.0; ++i) {
    float curSeed = seed + i * 0.0001 + 6429.264358;

    radius = remap(hash1(curSeed), -1.0, 1.0, 10.0, 20.0);
    cellHashValue = hash3(vec3(cellID, curSeed)) * (CELL_WIDTH * 0.175 - radius);
    vec3 offset = cellHashValue * vec3(1.0, 1.0, 0.0);
    offset.z = -radius * 0.5;

    sdfValue = min(sdfValue, sdfSphere(cellCoords - (cloudPosition + offset), radius));
  }
  return sdfValue;
}

float voronoiSlow(vec3 coords, float maxOffset, float cellsMult, float seed, float fixedZ, float cutoff) {
  vec2 seedHash = hash2(vec2(seed, seed * seed * 3.14159));

  vec2 gridBasePosition = floor(coords.xy);
  vec2 gridCoordOffset = fract(coords.xy);
  float maxCellSearch = ceil(maxOffset) + 1.0;

  vec3 gridCoordOffsetZ = fract(coords);

  float closest = 1.0;
  for (float y = -maxCellSearch; y <= maxCellSearch; y += 1.0) {
    for (float x = -maxCellSearch; x <= maxCellSearch; x += 1.0) {
      vec2 neighbourCellPosition = vec2(x, y);
      vec2 cellWorldPosition = gridBasePosition + neighbourCellPosition;
      cellWorldPosition.xy = mod(cellWorldPosition.xy, vec2(cellsMult));

      if (hash(cellWorldPosition + seedHash) < cutoff) {
        continue;
      }

      vec2 cellOffset = hash2(cellWorldPosition + seedHash);
      cellOffset *= maxOffset;

      // Figure out cell position of fixedZ
      vec3 neighbourCellPositionZ = vec3(neighbourCellPosition, floor(fixedZ - coords.z)) + vec3(cellOffset, 0.0);

      float distToNeighbour = length(neighbourCellPositionZ - gridCoordOffsetZ);
      closest = min(closest, distToNeighbour);
    }
  }

  return saturate(closest);
}

float getCloudMap(vec3 pos) {
  float mult = 16.0;
  float v1 = 0.0;

  mult = 16.0;
  // v1 = max(v1, 1.0 - voronoiSlow(pos * mult, 2.0, 8.0, 1.0, 0.5 * mult, 0.85));

  mult = 8.0;
  v1 = max(v1, 1.0 - voronoiSlow(pos * mult, 4.0, 8.0, 2.0, 0.5 * mult, 0.85));

  // mult = 4.0;
  // v1 = max(v1, 1.0 - voronoiSlow(pos * mult, 2.0, 4.0, 3.0, 0.5 * mult, 0.5));

  // Layer 2
  // mult = 16.0;
  // v1 = max(v1, 1.0 - voronoiSlow(pos * mult, 4.0, 8.0, -1.0, 0.75 * mult, 0.75));

  mult = 8.0;
  for (float i = 0.0; i < 10.0; i++) {
    v1 = max(v1, 1.0 - voronoiSlow(pos * mult, 4.0, 8.0, i + 1523.6234, 0.5 * mult, 0.75));
    v1 = max(v1, 1.0 - voronoiSlow(pos * mult, 2.0, 8.0, i + 2355.6325, 0.5 * mult, 0.65));
  }

  return v1;
}

void main() {
  vec3 pos = vec3(vUvs, remap(zLevel, 0.0, 31.0, 0.0, 1.0));
  float res = getCloudMap(pos);

  float v1 = smoothstep(0.5, 0.3, abs(vUvs.x - 0.5));
  float v2 = smoothstep(0.5, 0.3, abs(vUvs.y - 0.5));
  float v3 = smoothstep(16.0, 12.0, abs(zLevel - 16.0));
  float v = v1 * v2 * v3;
  // v = pow(v, 2.0);
  // res *= v;

// float mult = 7.0;
// res =  1.0 - voronoiSlow(vec3(pos.xy, 0.0) * mult, 0.5, mult, 1.0, 0.0, -1.0);

  gl_FragColor = vec4(res);
}

