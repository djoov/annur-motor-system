"use client"

import { useEffect } from 'react';
import { db } from '@/lib/firebase';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';

const LocationTracker = () => {
  useEffect(() => {
    // Cek sessionStorage untuk memastikan kita hanya bertanya sekali per sesi
    if (sessionStorage.getItem('location_recorded')) {
      return;
    }

    // Cek apakah browser mendukung Geolocation API
    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        // Success callback
        async (position) => {
          const { latitude, longitude } = position.coords;
          
          try {
            // Simpan data ke Firestore
            await addDoc(collection(db, 'visitor_locations'), {
              latitude,
              longitude,
              timestamp: serverTimestamp(),
              userAgent: navigator.userAgent, // Simpan info browser (opsional)
            });
            
            // Tandai bahwa lokasi sudah direkam untuk sesi ini
            sessionStorage.setItem('location_recorded', 'true');
            console.log('Lokasi pengunjung berhasil direkam.');

          } catch (error) {
            console.error("Gagal menyimpan lokasi ke Firestore:", error);
          }
        },
        // Error callback
        (error) => {
          console.warn(`Gagal mendapatkan lokasi: ${error.message}`);
          // Tandai juga jika pengguna menolak, agar tidak ditanya lagi
          sessionStorage.setItem('location_recorded', 'denied');
        }
      );
    } else {
      console.log("Geolocation tidak didukung oleh browser ini.");
    }
  }, []); // Array dependensi kosong agar hanya berjalan sekali

  // Komponen ini tidak merender apa pun ke layar
  return null;
};

export default LocationTracker;
