"use client"

import { useState, useEffect } from 'react';
import Image from 'next/image';

// --- [DIUBAH] Daftar gambar sekarang mengambil dari folder public/images ---
const images = [
  '/images/hero-1.jpg',
  '/images/hero-2.jpg',
  '/images/hero-3.jpg',
  '/images/hero-4.jpg',
];

const ImageCarousel = () => {
  const [currentIndex, setCurrentIndex] = useState(0);

  useEffect(() => {
    // Atur interval untuk mengganti gambar setiap 5 detik
    const interval = setInterval(() => {
      setCurrentIndex((prevIndex) => (prevIndex + 1) % images.length);
    }, 5000); 

    // Bersihkan interval saat komponen tidak lagi digunakan
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="absolute inset-0 w-full h-full overflow-hidden">
      {images.map((src, index) => (
        <Image
          key={src}
          src={src}
          alt={`Bengkel Annur Motor slide ${index + 1}`}
          layout="fill"
          objectFit="cover"
          // Efek transisi fade-in/fade-out
          className={`transition-opacity duration-1000 ease-in-out ${
            index === currentIndex ? 'opacity-100' : 'opacity-0'
          }`}
          // Prioritaskan gambar pertama agar dimuat lebih cepat
          priority={index === 0}
        />
      ))}
    </div>
  );
};

export default ImageCarousel;
