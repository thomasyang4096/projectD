<%@ Page Language="VB" AutoEventWireup="false" CodeFile="3dview.aspx.vb" Inherits="three3dview" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="UTF-8" />
    <title>Three.js 多箭頭互動範例</title>
    <style>
        body { margin: 0; overflow: hidden; background: #111; }
        canvas { cursor: pointer; }
    </style>

    <script type="importmap">
    {
      "imports": {
        "three": "https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js",
        "three/examples/": "https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/"
      }
    }
    </script>
</head>

<body>
    <form id="form1" runat="server"></form>

    <!-- 後端注入的 JSON 資料 -->
    <script>
      const arrowData = <%= ArrowJson %>;
      const glowBallData = <%= GlowBallJson %>;
    </script>

    <script type="module">
    import * as THREE from 'three';
    import { OrbitControls } from 'three/examples/controls/OrbitControls.js';
    import { GLTFLoader } from 'three/examples/loaders/GLTFLoader.js';

    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x111111);

    const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 5000);
    camera.position.set(8, 8, 8);

    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(renderer.domElement);

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;

    // === 光源 ===
    scene.add(new THREE.AmbientLight(0xffffff, 0.7));
    const dirLight = new THREE.DirectionalLight(0xffffff, 1);
    dirLight.position.set(10, 10, 10);
    scene.add(dirLight);

    // === GLB 模型 ===
    const loader = new GLTFLoader();
    loader.load('3d/abc.glb', (gltf) => {
        scene.add(gltf.scene);
    });

    // === 建立 Glow 群組 ===
    function createGlowGroup(color = 0x00ff00) {
        const group = new THREE.Group();
        const baseRadius = 0.3;
        for (let i = 0; i < 4; i++) {
            const geo = new THREE.SphereGeometry(baseRadius, 32, 32);
            const mat = new THREE.MeshBasicMaterial({
                color,
                transparent: true,
                opacity: 0.4 / (i + 1),
                blending: THREE.AdditiveBlending,
                depthWrite: false
            });
            const mesh = new THREE.Mesh(geo, mat);
            mesh.scale.setScalar(1 + i * 0.5);
            group.add(mesh);
        }
        return group;
    }
function createCustomArrow(dir, pos, length, color, radius = 0.05, scale = 1) {
    const group = new THREE.Group();

    const shaftGeo = new THREE.CylinderGeometry(radius, radius, length * 0.8, 8);
    const shaftMat = new THREE.MeshBasicMaterial({ color });
    const shaft = new THREE.Mesh(shaftGeo, shaftMat);
    shaft.position.y = length * 0.4;
    group.add(shaft);

    const coneGeo = new THREE.ConeGeometry(radius * 3, length * 0.2, 12);
    const coneMat = new THREE.MeshBasicMaterial({ color });
    const cone = new THREE.Mesh(coneGeo, coneMat);
    cone.position.y = length * 0.9;
    group.add(cone);

    const axis = new THREE.Vector3(0, 1, 0);
    const quaternion = new THREE.Quaternion().setFromUnitVectors(axis, dir.clone().normalize());
    group.quaternion.copy(quaternion);
    group.position.copy(pos);

    // 🟢 新增：整體縮放
    group.scale.set(scale, scale, scale);

    return group;
}
// === 建立箭頭 ===
const arrows = [];
for (const data of arrowData) {
    const dir = new THREE.Vector3(data.dir.x, data.dir.y, data.dir.z).normalize();
    const pos = new THREE.Vector3(data.pos.x, data.pos.y, data.pos.z);
   const arrow = createCustomArrow(dir, pos, data.len, data.color, 0.1, 1.5); // ← 這裡 radius 控線寬
    arrow.userData = {
        url: data.url,
        basePos: pos.clone(),
        dir: dir.clone(),
        phase: Math.random() * Math.PI * 2
    };
    scene.add(arrow);
    arrows.push(arrow);
}

    // === 光球 ===
    const glowBalls = [];
    for (const g of glowBallData) {
        const group = new THREE.Group();
        group.position.set(g.pos.x, g.pos.y, g.pos.z);
        group.userData.url = g.url;

        const color = new THREE.Color(g.color);
        const core = new THREE.Mesh(new THREE.SphereGeometry(0.2, 32, 32),
            new THREE.MeshBasicMaterial({ color }));
        group.add(core);

        for (let i = 0; i < 4; i++) {
            const geo = new THREE.SphereGeometry(0.3 + i * 0.2, 32, 32);
            const mat = new THREE.MeshBasicMaterial({
                color,
                transparent: true,
                opacity: 0.3 / (i + 1),
                blending: THREE.AdditiveBlending,
                depthWrite: false
            });
            const halo = new THREE.Mesh(geo, mat);
            group.add(halo);
        }
        scene.add(group);
        glowBalls.push(group);
    }

    // === 動畫 ===
    let pulse = 0;
    function animate() {
        requestAnimationFrame(animate);
        pulse += 0.05;
        arrows.forEach(arrow => {
            const glow = arrow.children[0];
            const breath = 1 + Math.sin(pulse) * 0.15;
            glow.children.forEach((m, i) => {
                m.scale.setScalar((1 + i * 0.5) * breath);
            });
        });
        glowBalls.forEach(ball => {
            const t = Math.sin(pulse * 1.5);
            const scale = 1 + t * 0.1;
            for (let i = 1; i < ball.children.length; i++) {
                ball.children[i].scale.setScalar((1 + i * 0.2) * scale);
            }
        });

       // 箭頭前後擺動
        arrows.forEach(arrow => {
            const phase = arrow.userData.phase;
            const amplitude = 0.4; // 擺動距離
            const offset = Math.sin(t + phase) * amplitude;

            const newPos = arrow.userData.basePos.clone()
                .add(arrow.userData.dir.clone().multiplyScalar(offset));

            arrow.position.copy(newPos);
        });

        controls.update();
        renderer.render(scene, camera);
    }
    animate();

    window.addEventListener('resize', () => {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
    });
    </script>
</body>
</html>
