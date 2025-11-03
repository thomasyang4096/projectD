<%@ Page Language="VB" AutoEventWireup="false" CodeFile="3dview.aspx.vb" Inherits="ThreeDView" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <title>3DView - Three.js 動態示範</title>
    <style>
        html, body {
            margin: 0;
            padding: 0;
            overflow: hidden;
            width: 100%;
            height: 100%;
            background: #111;
        }

        #tooltip {
            position: absolute;
            padding: 6px 10px;
            background: rgba(0, 0, 0, 0.7);
            color: #0f0;
            border-radius: 6px;
            font-family: "Microsoft JhengHei";
            font-size: 14px;
            pointer-events: none;
            display: none;
            z-index: 1000;
            white-space: nowrap;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <!-- 用 HiddenField 將後端資料傳給前端 -->
        <asp:HiddenField ID="hfSceneData" runat="server" />
    </form>

    <div id="tooltip"></div>

    <script type="module">
        import * as THREE from 'https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js';
        import { OrbitControls } from 'https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/controls/OrbitControls.js';

        const scene = new THREE.Scene();
        scene.background = new THREE.Color(0x111111);

        const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 1000);
        camera.position.set(10, 8, 10);

        const renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
        document.body.appendChild(renderer.domElement);

        const controls = new OrbitControls(camera, renderer.domElement);
        controls.enableDamping = true;

        scene.add(new THREE.AmbientLight(0xffffff, 1));

        const raycaster = new THREE.Raycaster();
        const mouse = new THREE.Vector2();
        const interactables = [];

        // Tooltip 元素
        const tooltip = document.getElementById("tooltip");

        // 從 HiddenField 讀取 JSON
        const jsonData = document.getElementById("<%= hfSceneData.ClientID %>").value;
        const data = JSON.parse(jsonData);

        // === 建立箭頭 ===
        function createArrow(userData) {
            const group = new THREE.Group();
            group.userData = userData;

            const shaftGeo = new THREE.CylinderGeometry(0.05, 0.05, 1, 12);
            const shaftMat = new THREE.MeshBasicMaterial({ color: 0xff5533 });
            const shaft = new THREE.Mesh(shaftGeo, shaftMat);
            shaft.position.y = 0.5;
            group.add(shaft);

            const coneGeo = new THREE.ConeGeometry(0.12, 0.25, 16);
            const coneMat = new THREE.MeshBasicMaterial({ color: 0xff5533 });
            const cone = new THREE.Mesh(coneGeo, coneMat);
            cone.position.y = 1.15;
            group.add(cone);

            const axis = new THREE.Vector3(0, 1, 0);
            const targetDir = new THREE.Vector3(userData.dir.x, userData.dir.y, userData.dir.z).normalize();
            const quaternion = new THREE.Quaternion().setFromUnitVectors(axis, targetDir);
            group.quaternion.copy(quaternion);
            group.position.set(userData.basePos.x, userData.basePos.y, userData.basePos.z);

            group.userData.animPhase = userData.phase || Math.random() * Math.PI * 2;
            group.userData.animDir = targetDir.clone().multiplyScalar(0.2);

            group.traverse(obj => {
                if (obj.isMesh) {
                    obj.userData = group.userData;
                    interactables.push(obj);
                }
            });

            scene.add(group);
            return group;
        }

        // === 建立光球 ===
        function createLight(userData) {
            const geo = new THREE.SphereGeometry(0.3, 32, 32);
            const mat = new THREE.MeshBasicMaterial({ color: 0x33ff66 });
            const mesh = new THREE.Mesh(geo, mat);
            mesh.position.set(userData.pos.x, userData.pos.y, userData.pos.z);
            mesh.userData = userData;
            scene.add(mesh);
            interactables.push(mesh);
            return mesh;
        }

        const arrows = [];
        data.forEach(d => {
            if (d.type === "arrow") arrows.push(createArrow(d));
            if (d.type === "light") createLight(d);
        });

        // === 動畫 ===
        function animate(time) {
            requestAnimationFrame(animate);
            arrows.forEach(a => {
                const phase = time * 0.002 + a.userData.animPhase;
                const offset = Math.sin(phase) * 0.3;
                a.position.addScaledVector(a.userData.animDir, offset * 0.02);
            });
            controls.update();
            renderer.render(scene, camera);
        }
        animate();

        // === 滑鼠移動 Tooltip ===
        window.addEventListener('mousemove', event => {
            event.preventDefault();
            mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
            mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

            raycaster.setFromCamera(mouse, camera);
            const hits = raycaster.intersectObjects(interactables, false);
            if (hits.length > 0) {
                const hit = hits[0].object;
                tooltip.innerText = hit.userData.tooltip || "";
                tooltip.style.left = (event.clientX + 10) + "px";
                tooltip.style.top = (event.clientY + 10) + "px";
                tooltip.style.display = "block";
            } else {
                tooltip.style.display = "none";
            }
        });

        // === 點擊開啟 URL ===
        window.addEventListener('click', event => {
            mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
            mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
            raycaster.setFromCamera(mouse, camera);
            const hits = raycaster.intersectObjects(interactables, false);
            if (hits.length > 0) {
                const hit = hits[0].object;
                if (hit.userData.url) window.open(hit.userData.url, "_blank");
            }
        });

        // === 視窗大小改變 ===
        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });
    </script>
</body>
</html>
