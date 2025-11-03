<%@ Page Language="VB" AutoEventWireup="false" CodeFile="3dview.vb" Inherits="three3dview" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="utf-8" />
<title>3D 箭頭與光球 + Tooltip</title>
<style>
body { margin: 0; overflow: hidden; background: #111; }
#tooltip {
  position: absolute;
  padding: 6px 10px;
  background: rgba(0,0,0,0.7);
  color: #0f0;
  border-radius: 6px;
  font-family: "Microsoft JhengHei";
  font-size: 14px;
  pointer-events: none;
  display: none;
  white-space: nowrap;
}
</style>
</head>
<body>
<div id="tooltip"></div>
<script type="module">
import * as THREE from 'https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js';
import { OrbitControls } from 'https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/controls/OrbitControls.js';

// 從 VB.NET 傳入的資料
const data = <%= ObjectJson %>;

// === 場景與相機 ===
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

// === Raycaster 與互動物件收集 ===
const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();
const interactables = [];
const tooltip = document.getElementById('tooltip');

// === 自訂箭頭工廠 ===
function createArrow(position, direction, color, tooltipText) {
    const group = new THREE.Group();

    const shaftGeo = new THREE.CylinderGeometry(0.05, 0.05, 1, 12);
    const shaftMat = new THREE.MeshBasicMaterial({ color });
    const shaft = new THREE.Mesh(shaftGeo, shaftMat);
    shaft.position.y = 0.5;
    group.add(shaft);

    const coneGeo = new THREE.ConeGeometry(0.12, 0.25, 16);
    const coneMat = new THREE.MeshBasicMaterial({ color });
    const cone = new THREE.Mesh(coneGeo, coneMat);
    cone.position.y = 1.15;
    group.add(cone);

    const axis = new THREE.Vector3(0, 1, 0);
    const targetDir = direction.clone().normalize();
    const quaternion = new THREE.Quaternion().setFromUnitVectors(axis, targetDir);
    group.quaternion.copy(quaternion);

    group.position.copy(position);
    group.userData.tooltip = tooltipText;

    // 註冊可互動 Mesh
    group.traverse(obj => {
        if (obj.isMesh) {
            obj.userData = group.userData; // 子 Mesh 指向完整 userData
            interactables.push(obj);
        }
    });

    group.userData.animPhase = Math.random() * Math.PI * 2;
    group.userData.animDir = targetDir.clone().multiplyScalar(0.2);

    scene.add(group);
    return group;
}

// === 建立光球工廠 ===
function createLight(position, color, tooltipText) {
    const geo = new THREE.SphereGeometry(0.3, 32, 32);
    const mat = new THREE.MeshBasicMaterial({ color });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.copy(position);
    mesh.userData.tooltip = tooltipText;
    scene.add(mesh);
    interactables.push(mesh);
    return mesh;
}

// === 根據資料建立物件 ===
const arrows = [];
for (const obj of data) {
    if (obj.type === "arrow") {
        const arrow = createArrow(
            new THREE.Vector3(obj.pos.x, obj.pos.y, obj.pos.z),
            new THREE.Vector3(obj.dir.x, obj.dir.y, obj.dir.z),
            0xff5533,
            obj.tooltip
        );
        arrows.push(arrow);
    }
    if (obj.type === "light") {
        createLight(new THREE.Vector3(obj.pos.x, obj.pos.y, obj.pos.z), 0x33ff66, obj.tooltip);
    }
}

// === 動畫 ===
function animate(time) {
    requestAnimationFrame(animate);
    // 呼吸動畫
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
window.addEventListener('mousemove', (event) => {
 event.preventDefault(); // 防止頁面滾動
    mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

    raycaster.setFromCamera(mouse, camera);
    const hits = raycaster.intersectObjects(interactables, false);

    if (hits.length > 0) {
        const hit = hits[0].object;
        tooltip.innerText = hit.userData.tooltip || "";
        tooltip.style.left = `${event.clientX + 10}px`;
        tooltip.style.top = `${event.clientY + 10}px`;
        tooltip.style.display = 'block';
    } else {
        tooltip.style.display = 'none';
    }
});

// === 視窗調整 ===
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
});
</script>
</body>
</html>
