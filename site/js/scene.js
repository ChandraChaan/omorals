/* OMorals Media — WebGL stage.
   One fixed canvas behind the page. Three "totems" (the O/play mark, a growth
   chart, a phone + browser) fly in and out as the matching chapter scrolls by.
   Poses are interpolated from scroll position and then damped every frame, so
   motion stays smooth whatever the scroll input does. */
import * as THREE from '/vendor/three.bundle.min.js';

const OM = window.OM || { pointer: { x: 0, y: 0 }, intro: { v: 1 }, reduce: false, done() {} };
const canvas = document.getElementById('scene');

try {
  init();
} catch (err) {
  console.warn('[scene] WebGL unavailable, continuing without it.', err);
  document.documentElement.classList.add('no-webgl');
  if (canvas) canvas.style.display = 'none';
  OM.done('scene');
}

function init() {
  const small = () => innerWidth < 820;
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Math.min(devicePixelRatio || 1, 1.5));
  renderer.toneMapping = THREE.NeutralToneMapping;
  renderer.toneMappingExposure = 1.0;
  renderer.outputColorSpace = THREE.SRGBColorSpace;

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(35, 1, 0.1, 100);
  camera.position.set(0, 0, 9);

  const pmrem = new THREE.PMREMGenerator(renderer);
  scene.environment = pmrem.fromScene(new THREE.RoomEnvironment(), 0.04).texture;
  scene.environmentIntensity = 0.72;

  const key = new THREE.DirectionalLight(0xffffff, 1.25);
  key.position.set(4, 6, 8);
  const warm = new THREE.PointLight(0xff7a3d, 16, 14, 1.6);
  warm.position.set(1.5, -1.2, 3.2);
  const cool = new THREE.PointLight(0x6f8bff, 22, 16, 1.6);
  cool.position.set(-5, 2.5, 2.5);
  scene.add(key, warm, cool);

  const world = new THREE.Group();
  scene.add(world);

  /* ── Materials ── */
  const pearl = new THREE.MeshPhysicalMaterial({
    color: 0xf3eee5, roughness: 0.28, metalness: 0.05, clearcoat: 1, clearcoatRoughness: 0.18,
  });
  const chrome = new THREE.MeshPhysicalMaterial({
    color: 0x12141c, roughness: 0.2, metalness: 1, clearcoat: 1, clearcoatRoughness: 0.12,
  });
  const glow = (hex, k = 0.6) => new THREE.MeshStandardMaterial({
    color: hex, emissive: hex, emissiveIntensity: k, roughness: 0.55, metalness: 0, envMapIntensity: 0.18,
    toneMapped: false, // keep brand colours exact instead of letting tone mapping wash them out
  });
  const orange = glow(0xff5a1f, 0.42);
  const green = glow(0x19c99a, 0.3);
  const blue = glow(0x6f8bff, 0.3);

  const seg = small() ? 0.6 : 1;

  /* ── Totem 1: the O with a play mark ── */
  const ring = makeTotem();
  const torus = new THREE.Mesh(new THREE.TorusGeometry(1.15, 0.4, Math.round(56 * seg), Math.round(160 * seg)), pearl);
  const play = new THREE.Mesh(
    new THREE.ExtrudeGeometry(
      roundedShape([[-0.3, 0.44], [0.5, 0], [-0.3, -0.44]], 0.1),
      { depth: 0.2, bevelEnabled: true, bevelThickness: 0.05, bevelSize: 0.05, bevelSegments: 5, curveSegments: 14 },
    ).center(),
    orange,
  );
  play.position.x = 0.04;
  ring.inner.add(torus, play);

  const satellites = [
    { mesh: new THREE.Mesh(new THREE.IcosahedronGeometry(0.2, 0), orange), r: 2.05, speed: 0.42, phase: 0.2, tilt: 0.5 },
    { mesh: new THREE.Mesh(new THREE.SphereGeometry(0.15, 32, 32), chrome), r: 2.35, speed: -0.3, phase: 2.1, tilt: -0.75 },
    { mesh: new THREE.Mesh(new THREE.RoundedBoxGeometry(0.26, 0.26, 0.26, 4, 0.06), blue), r: 1.9, speed: 0.34, phase: 4.0, tilt: 1.15 },
    { mesh: new THREE.Mesh(new THREE.TorusGeometry(0.13, 0.05, 16, 40), green), r: 2.5, speed: 0.24, phase: 5.3, tilt: -0.25 },
    { mesh: new THREE.Mesh(new THREE.SphereGeometry(0.08, 24, 24), pearl), r: 1.75, speed: -0.5, phase: 1.2, tilt: 1.6 },
  ];
  satellites.forEach((s) => ring.inner.add(s.mesh));

  /* ── Totem 2: growth chart ── */
  const chart = makeTotem();
  const heights = [0.7, 1.15, 0.95, 1.7, 2.45];
  const bars = heights.map((h, i) => {
    const m = new THREE.Mesh(new THREE.RoundedBoxGeometry(0.44, 1, 0.44, 4, 0.09), i === heights.length - 1 ? green : (i === 3 ? pearl : chrome));
    m.position.x = (i - 2) * 0.62;
    m.userData.h = h;
    chart.inner.add(m);
    return m;
  });
  const plate = new THREE.Mesh(new THREE.RoundedBoxGeometry(3.7, 0.09, 1.15, 4, 0.045), chrome);
  plate.position.y = -1.3;
  chart.inner.add(plate);
  const curve = new THREE.CatmullRomCurve3([
    new THREE.Vector3(-1.7, -0.35, 0.42), new THREE.Vector3(-0.75, 0.3, 0.42), new THREE.Vector3(-0.05, 0.1, 0.42),
    new THREE.Vector3(0.8, 1.0, 0.42), new THREE.Vector3(1.65, 1.95, 0.42),
  ]);
  const tubeGeo = new THREE.TubeGeometry(curve, 90, 0.035, 10, false);
  const tube = new THREE.Mesh(tubeGeo, orange);
  const tubeCount = tubeGeo.index.count;
  const head = new THREE.Mesh(new THREE.ConeGeometry(0.11, 0.28, 20), orange);
  chart.inner.add(tube, head);
  const coins = [0, 1, 2].map((i) => {
    const c = new THREE.Mesh(new THREE.CylinderGeometry(0.17, 0.17, 0.05, 36), i === 1 ? pearl : orange);
    c.userData = { x: [-1.9, 2.15, 1.5][i], y: [1.2, 0.3, -0.75][i], z: [0.2, 0.7, 1.0][i], p: i * 2.1 };
    chart.inner.add(c);
    return c;
  });
  chart.inner.rotation.set(0.16, -0.5, 0);

  /* ── Totem 3: phone + browser window ── */
  const device = makeTotem();
  const win = new THREE.Group();
  win.add(new THREE.Mesh(new THREE.RoundedBoxGeometry(3.5, 2.3, 0.08, 5, 0.04), chrome));
  win.add(screenMesh(3.36, 2.16, 0.045, drawSite, 1120, 720, 0.04));
  win.position.set(-0.75, 0.35, -0.7);
  win.rotation.y = 0.26;
  const phone = new THREE.Group();
  phone.add(new THREE.Mesh(new THREE.RoundedBoxGeometry(1.42, 2.95, 0.15, 8, 0.075), chrome));
  phone.add(screenMesh(1.3, 2.83, 0.08, drawApp, 520, 1132, 0.1));
  phone.position.set(1.0, -0.25, 0.35);
  phone.rotation.set(0, -0.42, 0.05);
  device.inner.add(win, phone);
  const blocks = [
    { m: blue, p: [-2.3, -1.15, 0.5], s: 0.3 }, { m: orange, p: [2.15, 1.35, -0.2], s: 0.22 }, { m: green, p: [0.1, 1.75, 0.3], s: 0.17 },
  ].map((b, i) => {
    const mesh = new THREE.Mesh(new THREE.RoundedBoxGeometry(1, 1, 1, 4, 0.2), b.m);
    mesh.scale.setScalar(b.s);
    mesh.position.set(...b.p);
    mesh.userData = { y: b.p[1], p: i * 1.9 };
    device.inner.add(mesh);
    return mesh;
  });

  world.add(ring.group, chart.group, device.group);

  /* ── Dust ── */
  const COUNT = small() ? 420 : 1300;
  const dustGeo = new THREE.BufferGeometry();
  const pos = new Float32Array(COUNT * 3);
  const aSize = new Float32Array(COUNT);
  const aSeed = new Float32Array(COUNT);
  for (let i = 0; i < COUNT; i++) {
    pos[i * 3] = (Math.random() - 0.5) * 22;
    pos[i * 3 + 1] = (Math.random() - 0.5) * 14;
    pos[i * 3 + 2] = -9 + Math.random() * 12;
    aSize[i] = 0.35 + Math.pow(Math.random(), 3) * 1.6;
    aSeed[i] = Math.random();
  }
  dustGeo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  dustGeo.setAttribute('aSize', new THREE.BufferAttribute(aSize, 1));
  dustGeo.setAttribute('aSeed', new THREE.BufferAttribute(aSeed, 1));
  const dustMat = new THREE.ShaderMaterial({
    transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
    uniforms: { uTime: { value: 0 }, uShift: { value: 0 }, uPR: { value: renderer.getPixelRatio() }, uTint: { value: new THREE.Color(0xff5a1f) } },
    vertexShader: /* glsl */`
      attribute float aSize; attribute float aSeed;
      uniform float uTime; uniform float uShift; uniform float uPR;
      varying float vAlpha; varying float vSeed;
      void main() {
        vec3 p = position;
        p.y = mod(p.y + uShift * (0.35 + aSize * 0.5) + 7.0, 14.0) - 7.0;
        p.x += sin(uTime * 0.12 + aSeed * 40.0) * 0.25;
        vec4 mv = modelViewMatrix * vec4(p, 1.0);
        gl_Position = projectionMatrix * mv;
        gl_PointSize = aSize * uPR * (26.0 / -mv.z);
        float tw = sin(uTime * (0.6 + aSeed * 1.4) + aSeed * 60.0);
        vAlpha = (0.25 + 0.75 * tw * tw) * smoothstep(-16.0, -6.0, mv.z);
        vSeed = aSeed;
      }`,
    fragmentShader: /* glsl */`
      uniform vec3 uTint; varying float vAlpha; varying float vSeed;
      void main() {
        float d = length(gl_PointCoord - 0.5);
        float a = smoothstep(0.5, 0.0, d);
        vec3 c = mix(vec3(0.95, 0.93, 0.9), uTint, step(0.72, vSeed));
        gl_FragColor = vec4(c * a * vAlpha * 0.7, a * vAlpha * 0.7);
      }`,
  });
  const dust = new THREE.Points(dustGeo, dustMat);
  dust.frustumCulled = false;
  scene.add(dust);

  /* ── Poses ──
     Wide screens: [x, y, z, scale, rotX, rotY, rotZ] per totem, per chapter.
     The totem sits beside the text and is interpolated between chapters.

     Narrow screens (single-column layout): every totem is glued to a blank
     "stage" element in the page (data-anchor) and scrolls with it like an
     inline picture, so it can never sit behind text. */
  const OFF_R = [7.5, -1.5, -3, 0.001, 0, 0.9, 0];
  const OFF_L = [-7.5, -1.5, -3, 0.001, 0, -0.9, 0];
  const RING_AWAY = [-6.2, 4.2, -3, 0.4, 0.8, 1.4, 0];
  const POSES = {
    hero:      { ring: [3.1, 0.85, 0, 1.0, 0.28, -0.52, 0.06], chart: OFF_R, device: OFF_L, fade: 1 },
    manifesto: { ring: [3.0, -1.75, -2, 1.5, 1.12, 0.25, 0.35], chart: OFF_R, device: OFF_L, fade: 0.7 },
    youtube:   { ring: [-2.65, 0.25, 0, 1.2, 0.12, 0.55, -0.04], chart: OFF_R, device: OFF_L, fade: 1 },
    reel:      { ring: [-4.7, 2.5, -3, 0.5, 0.7, 0.9, 0.2], chart: OFF_R, device: OFF_L, fade: 0.7 },
    marketing: { ring: RING_AWAY, chart: [2.2, 0.05, 0, 0.86, 0, 0, 0], device: OFF_L, fade: 1 },
    apps:      { ring: RING_AWAY, chart: OFF_R, device: [-1.95, 0.05, 0, 0.84, 0.04, 0.3, 0], fade: 1 },
    work:      { ring: RING_AWAY, chart: OFF_R, device: [-4.6, 2.3, -3.5, 0.5, 0.2, 0.7, 0.1], fade: 0.7 },
    process:   { ring: [4.3, 2.35, -3.2, 0.62, 0.7, -0.9, 0.2], chart: OFF_R, device: OFF_L, fade: 0.75 },
    board:     { ring: [-4.9, -2.6, -3, 0.75, 1.0, 0.5, 0.2], chart: OFF_R, device: OFF_L, fade: 0.6 },
    contact:   { ring: [3.75, 1.7, 0, 0.5, 0.3, -0.62, 0.08], chart: OFF_R, device: OFF_L, fade: 0.95 },
    footer:    { ring: [3.9, 3.6, -2, 0.001, 1.2, -1.4, 0.3], chart: OFF_R, device: OFF_L, fade: 0.8 },
  };
  const sections = Array.from(document.querySelectorAll('[data-scene]'))
    .filter((el) => POSES[el.dataset.scene]);
  const anchors = Array.from(document.querySelectorAll('[data-anchor]'));
  // how much room each totem needs at scale 1 (world units) and how it is turned on a stage
  const FIT = {
    ring: { w: 3.9, h: 3.9, rot: [0.22, -0.42, 0.05] },
    chart: { w: 4.4, h: 4.3, rot: [0, 0.16, 0] },
    device: { w: 5.0, h: 3.5, rot: [0.03, 0.12, 0] },
  };
  const narrow = matchMedia('(max-width: 1100px)');
  const totems = { ring, chart, device };
  const NAMES = ['ring', 'chart', 'device'];
  const target = { ring: OFF_R.slice(), chart: OFF_R.slice(), device: OFF_L.slice(), fade: 1 };
  const glued = { ring: false, chart: false, device: false };
  const smooth = (a, b, x) => { const t = Math.min(1, Math.max(0, (x - a) / (b - a))); return t * t * (3 - 2 * t); };
  const mix = (a, b, t) => a + (b - a) * t;

  function solveTargets() {
    if (narrow.matches) return solveAnchored();
    const vh = innerHeight;
    const mid = vh * 0.5;
    const band = vh * 0.5;
    const rects = sections.map((el) => el.getBoundingClientRect());
    // Start from the first chapter and fold in each following one as its
    // upper edge crosses the middle of the screen.
    const start = POSES[sections[0].dataset.scene];
    for (const name of NAMES) {
      glued[name] = false;
      for (let k = 0; k < 7; k++) target[name][k] = start[name][k];
    }
    target.fade = start.fade;
    for (let j = 0; j < rects.length - 1; j++) {
      const edge = (rects[j].bottom + rects[j + 1].top) / 2;
      const w = 1 - smooth(mid - band, mid + band, edge); // 0 while the edge is below the middle, 1 once passed
      if (w <= 0) break;
      const next = POSES[sections[j + 1].dataset.scene];
      for (const name of NAMES) for (let k = 0; k < 7; k++) target[name][k] = mix(target[name][k], next[name][k], w);
      target.fade = mix(target.fade, next.fade, w);
    }
  }

  function solveAnchored() {
    const vw = innerWidth;
    const vh = innerHeight;
    const H = 2 * camera.position.z * Math.tan((camera.fov * Math.PI) / 360); // world height at z = 0
    const unit = H / vh; // world units per CSS pixel
    for (const name of NAMES) { glued[name] = false; target[name][3] = 0.001; }
    target.fade = 1;
    for (const el of anchors) {
      const name = el.dataset.anchor;
      const r = el.getBoundingClientRect();
      if (!FIT[name] || r.height < 10 || r.bottom < -vh * 0.4 || r.top > vh * 1.4) continue;
      const fit = FIT[name];
      const scale = Math.min((r.width * unit) / fit.w, (r.height * unit) / fit.h);
      const t = target[name];
      t[0] = (r.left + r.width / 2 - vw / 2) * unit;
      t[1] = (vh / 2 - (r.top + r.height / 2)) * unit;
      t[2] = 0;
      t[3] = scale;
      t[4] = fit.rot[0]; t[5] = fit.rot[1]; t[6] = fit.rot[2];
      glued[name] = true;
    }
  }

  /* ── Frame loop ── */
  const euler = new THREE.Euler();
  const quat = new THREE.Quaternion();
  const vec = new THREE.Vector3();
  let last = performance.now();
  let time = 0;
  let lastScroll = window.scrollY;
  let spin = 0;
  let grow = 0;
  let fade = 1;
  let first = true;

  function resize() {
    const w = innerWidth;
    const h = innerHeight;
    renderer.setPixelRatio(Math.min(devicePixelRatio || 1, 1.5));
    renderer.setSize(w, h, false);
    dustMat.uniforms.uPR.value = renderer.getPixelRatio();
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }
  window.addEventListener('resize', resize);
  resize();
  renderer.compile(scene, camera);

  function frame(now) {
    requestAnimationFrame(frame);
    if (document.hidden) { last = now; return; }
    const gap = (now - last) / 1000;
    const dt = Math.min(0.05, gap);
    last = now;
    time += dt;
    // Damping factor. If frames arrive far apart (throttled tab) jump straight
    // to the target instead of crawling there one slow frame at a time.
    const k = gap > 0.3 ? 1 : 1 - Math.exp(-dt * 3.4);
    const intro = OM.intro.v;

    solveTargets();

    const sy = window.scrollY;
    const vel = sy - lastScroll;
    lastScroll = sy;
    spin += (vel * 0.0016 - spin) * 0.08;

    for (const name of NAMES) {
      const g = totems[name].group;
      const p = target[name];
      // glued totems track their page anchor exactly; free ones glide
      if (glued[name]) g.position.set(p[0], p[1], p[2]);
      else if (g.scale.x < 0.02 && narrow.matches) g.position.set(p[0], p[1], p[2]);
      else g.position.lerp(vec.set(p[0], p[1], p[2]), k);
      const s = p[3] * (name === 'ring' ? Math.max(0.0001, intro) : 1);
      g.scale.lerp(vec.set(s, s, s), k);
      g.quaternion.slerp(quat.setFromEuler(euler.set(p[4], p[5], p[6])), k);
      g.visible = g.scale.x > 0.01;
    }

    // idle life
    ring.inner.rotation.y = Math.sin(time * 0.35) * 0.28 + (1 - intro) * 4.2;
    ring.inner.rotation.x = Math.cos(time * 0.27) * 0.12;
    ring.inner.position.y = Math.sin(time * 0.8) * 0.08;
    torus.rotation.z += dt * 0.12 + spin;
    play.position.z = Math.sin(time * 1.4) * 0.07;
    play.scale.setScalar(1 + Math.sin(time * 2.2) * 0.035);
    satellites.forEach((s) => {
      const a = time * s.speed + s.phase;
      s.mesh.position.set(Math.cos(a) * s.r, Math.sin(a) * s.r * Math.sin(s.tilt), Math.sin(a) * s.r * Math.cos(s.tilt));
      s.mesh.rotation.x += dt * 0.7; s.mesh.rotation.y += dt * 0.5;
    });

    const chartOn = target.chart[3] > 0.5 ? 1 : 0;
    grow += (chartOn - grow) * (gap > 0.3 ? 1 : 1 - Math.exp(-dt * 2.2));
    bars.forEach((b, i) => {
      const g = Math.min(1, Math.max(0.02, grow * 1.5 - i * 0.1));
      const e = 1 - Math.pow(1 - g, 3);
      const h = b.userData.h * e;
      b.scale.y = h; b.position.y = -1.25 + h / 2;
    });
    const drawn = Math.min(1, Math.max(0, grow * 1.6 - 0.45));
    tubeGeo.setDrawRange(0, Math.floor((tubeCount * drawn) / 6) * 6);
    const tip = curve.getPointAt(Math.max(0.001, drawn));
    const tan = curve.getTangentAt(Math.max(0.001, drawn));
    head.position.copy(tip);
    head.quaternion.setFromUnitVectors(vec.set(0, 1, 0), tan);
    head.visible = drawn > 0.02;
    coins.forEach((c) => {
      const u = c.userData;
      c.position.set(u.x, u.y + Math.sin(time * 0.9 + u.p) * 0.14, u.z);
      c.rotation.set(Math.PI / 2 + Math.sin(time * 0.7 + u.p) * 0.5, time * 0.8 + u.p, 0);
    });
    chart.inner.position.y = Math.sin(time * 0.7) * 0.07;
    chart.inner.rotation.y = -0.5 + Math.sin(time * 0.3) * 0.12;

    device.inner.position.y = Math.sin(time * 0.75 + 1) * 0.08;
    device.inner.rotation.y = Math.sin(time * 0.32) * 0.14;
    phone.position.z = 0.35 + Math.sin(time * 0.9) * 0.08;
    blocks.forEach((b) => {
      b.position.y = b.userData.y + Math.sin(time + b.userData.p) * 0.14;
      b.rotation.x += dt * 0.4; b.rotation.y += dt * 0.55;
    });

    // pointer parallax on the whole world
    const par = narrow.matches ? 0 : 1; // no parallax while glued to the page
    world.rotation.y += (OM.pointer.x * 0.16 * par - world.rotation.y) * k;
    world.rotation.x += (OM.pointer.y * 0.09 * par - world.rotation.x) * k;
    warm.position.x = 1.5 + OM.pointer.x * 2.5;
    warm.position.y = -1.2 - OM.pointer.y * 2;

    dustMat.uniforms.uTime.value = time;
    dustMat.uniforms.uShift.value = sy * 0.0032;

    fade += (target.fade * Math.min(1, intro * 1.4 + 0.15) - fade) * k;
    canvas.style.opacity = fade.toFixed(3);

    renderer.render(scene, camera);
    if (first) { first = false; OM.done('scene'); }
  }

  if (OM.reduce) {
    // one settled frame, no loop
    solveTargets();
    for (const name of ['ring', 'chart', 'device']) {
      const g = totems[name].group; const p = target[name];
      g.position.set(p[0], p[1], p[2]); g.scale.setScalar(p[3]); g.rotation.set(p[4], p[5], p[6]);
    }
    renderer.render(scene, camera);
    OM.done('scene');
  } else {
    requestAnimationFrame(frame);
  }

  /* ── Builders ── */
  function makeTotem() {
    const group = new THREE.Group();
    const inner = new THREE.Group();
    group.add(inner);
    group.scale.setScalar(0.001);
    group.position.set(0, 0, -4);
    return { group, inner };
  }

  function roundedShape(points, r) {
    const pts = points.map(([x, y]) => new THREE.Vector2(x, y));
    const shape = new THREE.Shape();
    const n = pts.length;
    for (let i = 0; i < n; i++) {
      const prev = pts[(i - 1 + n) % n];
      const cur = pts[i];
      const next = pts[(i + 1) % n];
      const a = prev.clone().sub(cur).normalize().multiplyScalar(r).add(cur);
      const b = next.clone().sub(cur).normalize().multiplyScalar(r).add(cur);
      if (i === 0) shape.moveTo(a.x, a.y); else shape.lineTo(a.x, a.y);
      shape.quadraticCurveTo(cur.x, cur.y, b.x, b.y);
    }
    shape.closePath();
    return shape;
  }

  function screenMesh(w, h, z, draw, pw, ph, radius) {
    const c = document.createElement('canvas');
    c.width = pw; c.height = ph;
    const ctx = c.getContext('2d');
    const r = (radius / w) * pw;
    ctx.beginPath();
    ctx.roundRect(0, 0, pw, ph, r);
    ctx.clip();
    draw(ctx, pw, ph);
    const tex = new THREE.CanvasTexture(c);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.anisotropy = renderer.capabilities.getMaxAnisotropy();
    const mesh = new THREE.Mesh(
      new THREE.PlaneGeometry(w, h),
      new THREE.MeshBasicMaterial({ map: tex, transparent: true, toneMapped: false }),
    );
    mesh.position.z = z;
    return mesh;
  }

  function pill(ctx, x, y, w, h, r, fill) {
    ctx.beginPath(); ctx.roundRect(x, y, w, h, r); ctx.fillStyle = fill; ctx.fill();
  }

  // Phone screen: a little task/pipeline app
  function drawApp(ctx, w, h) {
    ctx.fillStyle = '#f5f3ee'; ctx.fillRect(0, 0, w, h);
    ctx.fillStyle = '#0b1020'; ctx.fillRect(0, 0, w, 210);
    ctx.lineWidth = 16; ctx.strokeStyle = '#f3eee5';
    ctx.beginPath(); ctx.arc(74, 112, 30, 0, Math.PI * 2); ctx.stroke();
    ctx.fillStyle = '#ff5a1f';
    ctx.beginPath(); ctx.moveTo(66, 96); ctx.lineTo(92, 112); ctx.lineTo(66, 128); ctx.fill();
    pill(ctx, 130, 92, 190, 18, 9, '#f3eee5');
    pill(ctx, 130, 124, 120, 12, 6, '#59607a');
    pill(ctx, w - 96, 84, 56, 56, 28, '#1b2238');
    const colors = ['#ff5a1f', '#19c99a', '#6f8bff', '#e5383b', '#19c99a'];
    const prog = [0.55, 0.82, 0.3, 1, 0.68];
    for (let i = 0; i < 5; i++) {
      const y = 250 + i * 152;
      pill(ctx, 30, y, w - 60, 128, 22, '#ffffff');
      ctx.strokeStyle = '#e6e2d8'; ctx.lineWidth = 2; ctx.beginPath(); ctx.roundRect(30, y, w - 60, 128, 22); ctx.stroke();
      pill(ctx, 48, y + 22, 8, 84, 4, colors[i]);
      pill(ctx, 76, y + 28, 230 + (i % 3) * 40, 18, 9, '#141826');
      pill(ctx, 76, y + 60, 150, 12, 6, '#b9bccb');
      pill(ctx, 76, y + 92, w - 190, 8, 4, '#ece8de');
      pill(ctx, 76, y + 92, (w - 190) * prog[i], 8, 4, colors[i]);
      pill(ctx, w - 96, y + 24, 44, 44, 22, i % 2 ? '#ffd9c9' : '#d9e0ff');
    }
    pill(ctx, 30, h - 104, w - 60, 72, 36, '#ff5a1f');
    pill(ctx, w / 2 - 70, h - 76, 140, 16, 8, '#0b1020');
  }

  // Browser window: a dark landing page
  function drawSite(ctx, w, h) {
    ctx.fillStyle = '#07080c'; ctx.fillRect(0, 0, w, h);
    const g = ctx.createRadialGradient(w * 0.82, h * 0.2, 10, w * 0.82, h * 0.2, w * 0.55);
    g.addColorStop(0, 'rgba(255,90,31,0.55)'); g.addColorStop(1, 'rgba(255,90,31,0)');
    ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
    ctx.fillStyle = '#12141c'; ctx.fillRect(0, 0, w, 58);
    ['#ff5a1f', '#2c3144', '#2c3144'].forEach((c, i) => pill(ctx, 26 + i * 26, 22, 14, 14, 7, c));
    pill(ctx, 150, 18, w - 300, 22, 11, '#1d2130');
    pill(ctx, 60, 150, 560, 54, 10, '#f3eee5');
    pill(ctx, 60, 224, 430, 54, 10, '#f3eee5');
    pill(ctx, 510, 224, 210, 54, 10, '#ff5a1f');
    pill(ctx, 60, 320, 380, 14, 7, '#6b6f7d');
    pill(ctx, 60, 346, 300, 14, 7, '#6b6f7d');
    pill(ctx, 60, 404, 180, 56, 28, '#ff5a1f');
    pill(ctx, 256, 404, 180, 56, 28, '#1d2130');
    ctx.lineWidth = 44; ctx.strokeStyle = '#f3eee5';
    ctx.beginPath(); ctx.arc(w * 0.8, h * 0.44, 96, 0, Math.PI * 2); ctx.stroke();
    ctx.fillStyle = '#ff5a1f';
    ctx.beginPath(); ctx.moveTo(w * 0.8 - 26, h * 0.44 - 44); ctx.lineTo(w * 0.8 + 48, h * 0.44); ctx.lineTo(w * 0.8 - 26, h * 0.44 + 44); ctx.fill();
    for (let i = 0; i < 3; i++) {
      const x = 60 + i * ((w - 120 - 40) / 3 + 20);
      pill(ctx, x, h - 170, (w - 160) / 3, 130, 18, '#12141c');
      pill(ctx, x + 22, h - 146, 90, 12, 6, ['#ff3b3f', '#19c99a', '#6f8bff'][i]);
      pill(ctx, x + 22, h - 96, 190, 20, 10, '#f3eee5');
    }
  }
}
