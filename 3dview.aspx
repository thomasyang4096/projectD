<%@ Page Language="VB" AutoEventWireup="false" CodeFile="3dview.aspx.vb" Inherits="three3dview" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="UTF-8" />
    <title>Three.js 活動箭頭 + 能量脈衝</title>
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

    <script>
     //   const arrowData = <%= ArrowJson %>;
    // ====== 從 VB 傳入資料 ======
    const arrowData = <%= ArrowJson %>;
    const labelData = <%= LabelJson %>;
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

    scene.add(new THREE.AmbientLight(0xffffff, 0.6));
    const light = new THREE.DirectionalLight(0xffffff, 1);
    light.position.set(10, 10, 10);
    scene.add(light);

    scene.add(new THREE.GridHelper(10, 10));
    scene.add(new THREE.AxesHelper(2));

    // === 載入 GLB 模型 ===
    const loader = new GLTFLoader();
    loader.load('3d/abc.glb', (gltf) => scene.add(gltf.scene));

    // === 支援換行的 createTextLabel ===
    function createTextLabel(text, color = '#ffffff', fontSize = 48, maxWidth = 512) {
      const lines = text.split('\n'); // 支援 VB vbLf 換行
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      ctx.font = `${fontSize}px Arial`;

      let textWidth = 0;
      for (const line of lines)
        textWidth = Math.max(textWidth, ctx.measureText(line).width);

      const lineHeight = fontSize * 1.2;
      canvas.width = Math.min(textWidth + 40, maxWidth);
      canvas.height = lineHeight * lines.length + 40;

      ctx.font = `${fontSize}px Arial`;
      ctx.fillStyle = color;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';

      const cx = canvas.width / 2;
      let y = lineHeight / 2 + 20;
      for (const line of lines) {
        ctx.fillText(line, cx, y);
        y += lineHeight;
      }

      const texture = new THREE.CanvasTexture(canvas);
      const material = new THREE.SpriteMaterial({ map: texture, transparent: true });
      const sprite = new THREE.Sprite(material);

      const scale = 0.01 * fontSize;
      sprite.scale.set(scale * (canvas.width / canvas.height), scale * lines.length, 1);
      return sprite;
    }

    // 根據 VB 傳入的 labelData 產生 3D 文字
    for (const label of labelData) {
      const sprite = createTextLabel(label.text, label.color, label.size);
      sprite.position.set(label.pos.x, label.pos.y, label.pos.z);
      scene.add(sprite);
    }


    // === 建立自訂箭頭 ===
    function createCustomArrow(dir, pos, length, color, radius = 0.05, scale = 1) {
        const group = new THREE.Group();

        // 箭桿
        const shaftGeo = new THREE.CylinderGeometry(radius, radius, length * 0.8, 8);
        const shaftMat = new THREE.MeshBasicMaterial({ color });
        const shaft = new THREE.Mesh(shaftGeo, shaftMat);
        shaft.position.y = length * 0.4;
        shaft.userData.isHighlightable = true;
        group.add(shaft);

        // 箭頭錐
        const coneGeo = new THREE.ConeGeometry(radius * 1.8, length * 0.35, 16); // 可調尖度
        const coneMat = new THREE.MeshBasicMaterial({ color });
        const cone = new THREE.Mesh(coneGeo, coneMat);
        cone.position.y = length * 0.9;
        cone.userData.isHighlightable = true;
        group.add(cone);

        // 方向
        const axis = new THREE.Vector3(0, 1, 0);
        const quaternion = new THREE.Quaternion().setFromUnitVectors(axis, dir.clone().normalize());
        group.quaternion.copy(quaternion);
        group.position.copy(pos);

        group.scale.set(scale, scale, scale);

        return group;
    }

    // === 建立箭頭列表 ===
    const arrows = [];
    for (const data of arrowData) {
        const dir = new THREE.Vector3(data.dir.x, data.dir.y, data.dir.z).normalize();
        const pos = new THREE.Vector3(data.pos.x, data.pos.y, data.pos.z);
        const arrow = createCustomArrow(dir, pos, data.len, data.color, 0.1, 1);
        arrow.userData = {
            url: data.url,
            basePos: pos.clone(),
            dir: dir.clone(),
            phase: Math.random() * Math.PI * 2
        };
        scene.add(arrow);
        arrows.push(arrow);
    }

    // === Raycaster 滑鼠互動 ===
    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();
    let lastHovered = null;

    window.addEventListener('mousemove', (event) => {
        mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
        mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

        raycaster.setFromCamera(mouse, camera);
        const intersects = raycaster.intersectObjects(scene.children, true);

        if (intersects.length > 0) {
            let obj = intersects[0].object;
            while (obj && !obj.userData.isHighlightable) obj = obj.parent;

            if (obj && obj !== lastHovered) {
                // 滑鼠移上去 → 閃亮 + 能量脈衝
                const worldPos = new THREE.Vector3();
                obj.getWorldPosition(worldPos);
                createEnergyPulse(worldPos, 0x00ff88);

                if (obj.material && obj.material.color) {
                    const originalColor = obj.material.color.getHex();
                    obj.material.color.setHex(0x00ff99);
                    setTimeout(() => obj.material.color.setHex(originalColor), 200);
                }
                lastHovered = obj;
            }
        } else {
            lastHovered = null;
        }
    });

    // === 點擊開啟連結 ===
    window.addEventListener('click', (event) => {
        mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
        mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
        raycaster.setFromCamera(mouse, camera);
        const intersects = raycaster.intersectObjects(scene.children, true);
        if (intersects.length > 0) {
            let obj = intersects[0].object;
            while (obj && !obj.userData.url) obj = obj.parent;
            if (obj && obj.userData.url) window.open(obj.userData.url, '_blank');
        }
    });

    // === 能量脈衝函式 ===
    function createEnergyPulse(position, color = 0x00ffcc) {
        const geo = new THREE.SphereGeometry(0.5, 32, 32);
        const mat = new THREE.MeshBasicMaterial({
            color,
            transparent: true,
            opacity: 0.5,
            side: THREE.DoubleSide
        });
        const pulse = new THREE.Mesh(geo, mat);
        pulse.position.copy(position);
        scene.add(pulse);

        const start = performance.now();
        const duration = 600;
        const animatePulse = () => {
            const elapsed = performance.now() - start;
            const progress = elapsed / duration;
            const scale = 1 + progress * 2.5;
            pulse.scale.set(scale, scale, scale);
            pulse.material.opacity = 0.5 * (1 - progress);
            if (progress < 1) requestAnimationFrame(animatePulse);
            else {
                scene.remove(pulse);
                pulse.geometry.dispose();
                pulse.material.dispose();
            }
        };
        animatePulse();
    }

    // === 動畫 ===
    let t = 0;
    function animate() {
        requestAnimationFrame(animate);
        t += 0.05;

        // 箭頭呼吸移動
        arrows.forEach(arrow => {
            const amplitude = 0.4;
            const offset = Math.sin(t + arrow.userData.phase) * amplitude;
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
