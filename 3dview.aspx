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

    // === 建立箭頭 ===
    const arrows = [];
    for (const data of arrowData) {
        const dir = new THREE.Vector3(data.dir.x, data.dir.y, data.dir.z).normalize();
        const pos = new THREE.Vector3(data.pos.x, data.pos.y, data.pos.z);
        const arrow = new THREE.ArrowHelper(dir, pos, data.len, data.color);
        arrow.userData.url = data.url;

        const glow = createGlowGroup(data.color);
        arrow.add(glow);
        glow.position.copy(dir.clone().multiplyScalar(data.len));

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
