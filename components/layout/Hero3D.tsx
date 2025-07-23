"use client"

import { useEffect, useRef } from 'react';
import * as THREE from 'three';

const Hero3D = () => {
    const mountRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (!mountRef.current) return;

        const currentMount = mountRef.current;

        // Scene setup
        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(75, currentMount.clientWidth / currentMount.clientHeight, 0.1, 1000);
        const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
        renderer.setSize(currentMount.clientWidth, currentMount.clientHeight);
        currentMount.appendChild(renderer.domElement);

        camera.position.z = 5;

        // Lighting
        const ambientLight = new THREE.AmbientLight(0xffffff, 0.3);
        scene.add(ambientLight);
        const pointLight = new THREE.PointLight(0xffffff, 1.5);
        pointLight.position.set(5, 5, 5);
        scene.add(pointLight);

        // 3D Objects
        const objects: THREE.Mesh[] = [];
        const material = new THREE.MeshStandardMaterial({ color: 0x007BFF, roughness: 0.4, metalness: 0.9 });

        // 1. Gear
        const gearShape = new THREE.Shape();
        const teeth = 10;
        const outerRadius = 1.2;
        const innerRadius = 0.8;
        const toothDepth = 0.4;
        for (let i = 0; i < teeth; i++) {
            const angle = (i / teeth) * Math.PI * 2;
            const nextAngle = ((i + 1) / teeth) * Math.PI * 2;
            gearShape.moveTo(Math.cos(angle) * innerRadius, Math.sin(angle) * innerRadius);
            gearShape.lineTo(Math.cos(angle) * (outerRadius - toothDepth), Math.sin(angle) * (outerRadius - toothDepth));
            gearShape.lineTo(Math.cos(nextAngle) * (outerRadius - toothDepth), Math.sin(nextAngle) * (outerRadius - toothDepth));
            gearShape.lineTo(Math.cos(nextAngle) * innerRadius, Math.sin(nextAngle) * innerRadius);
        }
        const extrudeSettings = { depth: 0.4, bevelEnabled: true, bevelSegments: 1, steps: 1, bevelSize: 0.05, bevelThickness: 0.05 };
        const gearGeometry = new THREE.ExtrudeGeometry(gearShape, extrudeSettings);
        const gear = new THREE.Mesh(gearGeometry, material);
        gear.position.set(-3, 1, 0);
        scene.add(gear);
        objects.push(gear);
        
        // 2. Simple Piston
        const pistonGeometry = new THREE.CylinderGeometry(0.5, 0.5, 2, 32);
        const piston = new THREE.Mesh(pistonGeometry, material);
        piston.position.set(3, -1, 0);
        piston.rotation.z = Math.PI / 4;
        scene.add(piston);
        objects.push(piston);

        // 3. Simple Spark Plug
        const sparkPlugGroup = new THREE.Group();
        const insulator = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.3, 1.5, 16), new THREE.MeshStandardMaterial({color: 0xEAEAEA}));
        const terminal = new THREE.Mesh(new THREE.CylinderGeometry(0.1, 0.1, 0.2, 8), new THREE.MeshStandardMaterial({color: 0x777777}));
        terminal.position.y = 0.85;
        sparkPlugGroup.add(insulator);
        sparkPlugGroup.add(terminal);
        sparkPlugGroup.position.set(0, 0, -2);
        scene.add(sparkPlugGroup);

        // Animation loop
        const animate = () => {
            requestAnimationFrame(animate);
            objects.forEach(obj => {
                obj.rotation.x += 0.003;
                obj.rotation.y += 0.004;
            });
            sparkPlugGroup.rotation.y += 0.005;
            renderer.render(scene, camera);
        };
        animate();

        // Handle resize
        const handleResize = () => {
            if (currentMount) {
                camera.aspect = currentMount.clientWidth / currentMount.clientHeight;
                camera.updateProjectionMatrix();
                renderer.setSize(currentMount.clientWidth, currentMount.clientHeight);
            }
        };
        window.addEventListener('resize', handleResize);

        // Cleanup
        return () => {
            window.removeEventListener('resize', handleResize);
            if (currentMount) {
                currentMount.removeChild(renderer.domElement);
            }
        };
    }, []);

    return <div ref={mountRef} style={{ width: '100%', height: '100%', position: 'absolute', top: 0, left: 0, zIndex: 1 }} />;
};

export default Hero3D;
