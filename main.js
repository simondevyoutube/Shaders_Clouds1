import * as THREE from 'https://cdn.skypack.dev/three@0.146';


class CloudGeneratorAtlas {
  constructor() {
  }

  async init_(threejs) {
    this.create_();
    this.onLoad = () => {};

    this.threejs_ = threejs;

    const header = await fetch('./shaders/header.glsl');
    const common = await fetch('./shaders/common.glsl');
    const oklab = await fetch('./shaders/oklab.glsl');
    const blends = await fetch('./shaders/blend-modes.glsl');
    const noise = await fetch('./shaders/noise.glsl');
    const vsh = await fetch('./shaders/vertex-shader.glsl');
    const fsh = await fetch('./shaders/generator-shader.glsl');
  
    const material = new THREE.ShaderMaterial({
      uniforms: {
        zLevel: { value: 0.0 },
        numCells: { value: 2.0 },
      },
      vertexShader: await vsh.text(),
      fragmentShader: (
        await header.text() + '\n' +
        await oklab.text() + '\n' +
        await common.text() + '\n' +
        await blends.text() + '\n' +
        await noise.text() + '\n' +
        await fsh.text())
    });

    this.material_ = material;
    this.scene_ = new THREE.Scene();
    this.camera_ = new THREE.OrthographicCamera(0, 1, 1, 0, 0.1, 1000);
    this.camera_.position.set(0, 0, 1);
  
    const geometry = new THREE.PlaneGeometry(1, 1);
    const plane = new THREE.Mesh(geometry, material);
    plane.position.set(0.5, 0.5, 0);
    this.scene_.add(plane);

    this.resolution_ = 32;
    this.rt_ = new THREE.WebGLRenderTarget(this.resolution_, this.resolution_);
  }

  create_() {
    this.manager_ = new THREE.LoadingManager();
    this.loader_ = new THREE.TextureLoader(this.manager_);
    this.textures_ = {};

    this.manager_.onLoad = () => {
      this.onLoad_();
    };
  }

  get Info() {
    return this.textures_;
  }

  render_(t) {
    this.material_.uniforms.zLevel.value = t;

    this.threejs_.setRenderTarget(this.rt_);
    this.threejs_.render(this.scene_, this.camera_);
  
    const pixelBuffer = new Uint8Array(this.resolution_ * this.resolution_ * 4);
    this.threejs_.readRenderTargetPixels(this.rt_, 0, 0, this.resolution_, this.resolution_, pixelBuffer );
    this.threejs_.setRenderTarget(null);
    this.threejs_.outputEncoding = THREE.LinearEncoding;
    return pixelBuffer;
  }

  onLoad_() {
    const X = this.resolution_;
    const Y = this.resolution_;

    this.textures_['diffuse'] = {
      textures: []
    };
    for (let i = 0; i < 64; i++) {
      this.textures_['diffuse'].textures.push(this.render_(i / 4.0));
    }

    for (let k in this.textures_) {
      const atlas = this.textures_[k];
      const data = new Uint8Array(atlas.textures.length * 4 * X * Y);

      for (let t = 0; t < atlas.textures.length; t++) {
        const curData = atlas.textures[t];
        const offset = t * (4 * X * Y);

        data.set(curData, offset);
      }

      // const diffuse = new THREE.DataArrayTexture(data, X, Y, atlas.textures.length);
      const diffuse = new THREE.Data3DTexture(data, X, Y, atlas.textures.length);
      diffuse.format = THREE.RGBAFormat;
      diffuse.type = THREE.UnsignedByteType;
      diffuse.minFilter = THREE.LinearFilter;
      diffuse.magFilter = THREE.LinearFilter;
      // diffuse.anisotropy = this.threejs_.capabilities.getMaxAnisotropy();
      diffuse.wrapS = THREE.RepeatWrapping;
      diffuse.wrapT = THREE.RepeatWrapping;
      diffuse.wrapR = THREE.RepeatWrapping;
      diffuse.generateMipmaps = true;
      diffuse.needsUpdate = true;

      atlas.atlas = diffuse;
    }

    this.onLoad();
  }

  Load() {
    this.onLoad_();
  }
}

class SDFFieldGenerator {
  constructor() {
  }

  async init_(threejs) {
    this.create_();
    this.onLoad = () => {};

    this.threejs_ = threejs;

    const header = await fetch('./shaders/header.glsl');
    const common = await fetch('./shaders/common.glsl');
    const oklab = await fetch('./shaders/oklab.glsl');
    const blends = await fetch('./shaders/blend-modes.glsl');
    const noise = await fetch('./shaders/noise.glsl');
    const vsh = await fetch('./shaders/vertex-shader.glsl');
    const fsh = await fetch('./shaders/sdf-generator-shader.glsl');
  
    const material = new THREE.ShaderMaterial({
      uniforms: {
        zLevel: { value: 0.0 },
        numCells: { value: 2.0 },
      },
      vertexShader: await vsh.text(),
      fragmentShader: (
        await header.text() + '\n' +
        await oklab.text() + '\n' +
        await common.text() + '\n' +
        await blends.text() + '\n' +
        await noise.text() + '\n' +
        await fsh.text())
    });

    this.material_ = material;
    this.scene_ = new THREE.Scene();
    this.camera_ = new THREE.OrthographicCamera(0, 1, 1, 0, 0.1, 1000);
    this.camera_.position.set(0, 0, 1);
  
    const geometry = new THREE.PlaneGeometry(1, 1);
    const plane = new THREE.Mesh(geometry, material);
    plane.position.set(0.5, 0.5, 0);
    this.scene_.add(plane);

    this.resolution_ = 128;
    this.rt_ = new THREE.WebGLRenderTarget(this.resolution_, this.resolution_);
  }

  create_() {
    this.manager_ = new THREE.LoadingManager();
    this.loader_ = new THREE.TextureLoader(this.manager_);
    this.textures_ = {};

    this.manager_.onLoad = () => {
      this.onLoad_();
    };
  }

  get Info() {
    return this.textures_;
  }

  render_(t) {
    this.material_.uniforms.zLevel.value = t;

    this.threejs_.setRenderTarget(this.rt_);
    this.threejs_.render(this.scene_, this.camera_);
  
    const pixelBuffer = new Uint8Array(this.resolution_ * this.resolution_ * 4);
    this.threejs_.readRenderTargetPixels(this.rt_, 0, 0, this.resolution_, this.resolution_, pixelBuffer );
    this.threejs_.setRenderTarget(null);
    this.threejs_.outputEncoding = THREE.LinearEncoding;
    return pixelBuffer;
  }

  onLoad_() {
    const X = this.resolution_;
    const Y = this.resolution_;
    const CHANNELS = 4;

    this.textures_['diffuse'] = {
      textures: []
    };
    for (let i = 0; i < 32; i++) {
      this.textures_['diffuse'].textures.push(this.render_(i));
    }

    for (let k in this.textures_) {
      const atlas = this.textures_[k];
      const data = new Uint8Array(atlas.textures.length * CHANNELS * X * Y);

      for (let t = 0; t < atlas.textures.length; t++) {
        const curData = atlas.textures[t];
        const offset = t * (CHANNELS * X * Y);

        data.set(curData, offset);
      }

      // const diffuse = new THREE.DataArrayTexture(data, X, Y, atlas.textures.length);
      const diffuse = new THREE.Data3DTexture(data, X, Y, atlas.textures.length);
      diffuse.format = THREE.RGBAFormat;
      diffuse.type = THREE.UnsignedByteType;
      diffuse.minFilter = THREE.LinearFilter;
      diffuse.magFilter = THREE.LinearFilter;
      diffuse.anisotropy = this.threejs_.capabilities.getMaxAnisotropy();
      diffuse.wrapS = THREE.RepeatWrapping;
      diffuse.wrapT = THREE.RepeatWrapping;
      diffuse.wrapR = THREE.ClampToEdgeWrapping;
      diffuse.generateMipmaps = true;
      diffuse.needsUpdate = true;

      atlas.atlas = diffuse;
    }

    this.onLoad();
  }

  Load() {
    this.onLoad_();
  }
}


class SimonDev {
  constructor() {
  }

  async initialize() {
    this.threejs_ = new THREE.WebGLRenderer();
    this.threejs_.outputEncoding = THREE.LinearEncoding;
    document.body.appendChild(this.threejs_.domElement);

    window.addEventListener('resize', () => {
      this.onWindowResize_();
    }, false);

    this.scene_ = new THREE.Scene();
    this.finalScene_ = new THREE.Scene();

    this.camera_ = new THREE.OrthographicCamera(0, 1, 1, 0, 0.1, 1000);
    this.camera_.position.set(0, 0, 1);

    this.rtScale_ = 0.5;
    this.rtParams_ = {
        type: THREE.HalfFloatType,
        magFilter: THREE.LinearFilter,
        minFilter: THREE.LinearMipmapLinearFilter,
        anisotropy: this.threejs_.capabilities.getMaxAnisotropy(),
        generateMipmaps: true,
    };
    this.rt_ = new THREE.WebGLRenderTarget(
        window.innerWidth * this.rtScale_, window.innerHeight * this.rtScale_, this.rtParams_);

    await this.setupProject_();
  }

  async setupProject_() {
    
    {
      const header = await fetch('./shaders/header.glsl');
      const common = await fetch('./shaders/common.glsl');
      const oklab = await fetch('./shaders/oklab.glsl');
      const blends = await fetch('./shaders/blend-modes.glsl');
      const noise = await fetch('./shaders/noise.glsl');
      const ui2d = await fetch('./shaders/ui2d.glsl');
      const vsh = await fetch('./shaders/vertex-shader.glsl');
      const fshComposite = await fetch('./shaders/fragment-shader-composite.glsl');

      const compositeMaterial = new THREE.ShaderMaterial({
        uniforms: {
          resolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
          frameResolution: { value: new THREE.Vector2(this.rt_.width, this.rt_.height) },
          time: { value: 0.0 },
          frameTexture: { value: null },
          uiTextures: { value: null },
        },
        vertexShader: await vsh.text(),
        fragmentShader: (
          await header.text() + '\n' +
          await oklab.text() + '\n' +
          await common.text() + '\n' +
          await blends.text() + '\n' +
          await noise.text() + '\n' +
          await ui2d.text() + '\n' +
          await fshComposite.text())
      });
  
      this.compositeMaterial_ = compositeMaterial;
      const geometry = new THREE.PlaneGeometry(1, 1);
      const plane = new THREE.Mesh(geometry, compositeMaterial);
      plane.position.set(0.5, 0.5, 0);
      this.finalScene_.add(plane);
    }

    const header = await fetch('./shaders/header.glsl');
    const common = await fetch('./shaders/common.glsl');
    const oklab = await fetch('./shaders/oklab.glsl');
    const blends = await fetch('./shaders/blend-modes.glsl');
    const noise = await fetch('./shaders/noise.glsl');
    const ui2d = await fetch('./shaders/ui2d.glsl');
    const vsh = await fetch('./shaders/vertex-shader.glsl');
    const fsh = await fetch('./shaders/fragment-shader.glsl');


    const loader = new THREE.TextureLoader();
    const blueNoise = loader.load('./textures/HDR_L_0.png');

    blueNoise.wrapS = THREE.RepeatWrapping;
    blueNoise.wrapT = THREE.RepeatWrapping;
    blueNoise.minFilter = THREE.NearestFilter;
    blueNoise.magFilter = THREE.NearestFilter;

    const material = new THREE.ShaderMaterial({
      uniforms: {
        resolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
        time: { value: 0.0 },
        frame: { value: 0 },
        perlinWorley: { value: null },
        sdfField: { value: null },
        blueNoise: { value: blueNoise },
      },
      vertexShader: await vsh.text(),
      fragmentShader: (
        await header.text() + '\n' +
        await oklab.text() + '\n' +
        await common.text() + '\n' +
        await blends.text() + '\n' +
        await noise.text() + '\n' +
        await ui2d.text() + '\n' +
        await fsh.text())
    });

    const diffuse = new CloudGeneratorAtlas(this.threejs_);
    await diffuse.init_(this.threejs_);
    diffuse.onLoad = () => {     
      material.uniforms.perlinWorley.value = diffuse.Info['diffuse'].atlas;
    };
    diffuse.Load();

    const sdfTextureGenerator = new SDFFieldGenerator(this.threejs_);
    await sdfTextureGenerator.init_(this.threejs_);
    sdfTextureGenerator.onLoad = () => {     
      material.uniforms.sdfField.value = sdfTextureGenerator.Info['diffuse'].atlas;
    };
    sdfTextureGenerator.Load();

    const geometry = new THREE.PlaneGeometry(1, 1);
    const plane = new THREE.Mesh(geometry, material);
    plane.position.set(0.5, 0.5, 0);
    this.scene_.add(plane);

    this.material_ = material;

    this.clock_ = new THREE.Clock();
    this.totalTime_ = 0;
    this.previousRAF_ = null;
    this.onWindowResize_();
    this.raf_();  

  }

  onWindowResize_() {
    this.threejs_.setSize(window.innerWidth, window.innerHeight);
    this.rt_.setSize(window.innerWidth * this.rtScale_, window.innerHeight * this.rtScale_);
    this.material_.uniforms.resolution.value = new THREE.Vector2(this.rt_.width, this.rt_.height);
    this.compositeMaterial_.uniforms.resolution.value = new THREE.Vector2(window.innerWidth, window.innerHeight);
    this.compositeMaterial_.uniforms.frameResolution.value = new THREE.Vector2(this.rt_.width, this.rt_.height);
  }

  raf_() {
    requestAnimationFrame((t) => {
      this.step_(t - this.previousRAF_);
      this.render_();

      if (!this.clock_.running) {
        this.clock_.start();
      }

      setTimeout(() => {
        this.raf_();
        this.previousRAF_ = t;
      }, 1);
    });
  }

  step_(timeElapsed) {
    this.totalTime_ = this.clock_.getElapsedTime();

    this.material_.uniforms.time.value = this.totalTime_;
    this.material_.uniforms.frame.value = this.material_.uniforms.frame.value + 1;
    this.compositeMaterial_.uniforms.time.value = this.totalTime_;
  }

  render_() {
    this.threejs_.setRenderTarget(this.rt_);
    this.threejs_.render(this.scene_, this.camera_);

    this.threejs_.setRenderTarget(null);
    this.compositeMaterial_.uniforms.frameTexture.value = this.rt_.texture;
    this.threejs_.render(this.finalScene_, this.camera_);
  }
}


let APP_ = null;

window.addEventListener('DOMContentLoaded', async () => {
  APP_ = new SimonDev();
  await APP_.initialize();
});
