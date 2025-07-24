'use client';

import { useState } from 'react';
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Eye } from "lucide-react";
import Image from "next/image";
import { getStockImageUrl } from "@/app/page"; // Import fungsi dari page utama

interface Item {
  id: string;
  name: string;
  description: string;
  sellPrice: number;
  imageUrl?: string;
}

// --- Komponen Modal untuk Detail Produk ---
const ProductModal = ({ product, isOpen, onClose }: { product: Item | null, isOpen: boolean, onClose: () => void }) => {
  if (!isOpen || !product) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white rounded-lg max-w-md w-full max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
        <div className="p-6">
          <div className="flex justify-between items-start mb-4">
            <h3 className="text-xl font-bold">{product.name}</h3>
            <button 
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 text-2xl"
            >
              ×
            </button>
          </div>
          
          <div className="aspect-square bg-gray-100 rounded-lg mb-4 relative overflow-hidden">
            <Image 
              src={product.imageUrl || getStockImageUrl(product.name)} 
              alt={product.name} 
              fill
              className="object-contain p-4"
            />
          </div>
          
          <div className="space-y-3">
            <h4 className="font-semibold text-gray-700">Deskripsi Produk:</h4>
            <p className="text-gray-600 leading-relaxed">
              {product.description || "Deskripsi produk tidak tersedia."}
            </p>
            
            <div className="pt-4 border-t">
              <Button 
                className="w-full bg-green-500 hover:bg-green-600"
                onClick={() => {
                  const message = `Halo Annur Motor, saya tertarik dengan produk: ${product.name}. Bisakah saya mendapatkan informasi lebih lanjut?`;
                  window.open(`https://wa.me/6288983773114?text=${encodeURIComponent(message)}`, '_blank');
                }}
              >
                Tanya via WhatsApp
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// --- Komponen ProductCard ---
const ProductCard = ({ product }: { product: Item }) => {
  const [selectedProduct, setSelectedProduct] = useState<Item | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleViewDetails = (product: Item) => {
    setSelectedProduct(product);
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setSelectedProduct(null);
  };

  // Fungsi untuk memotong deskripsi dengan kata utuh
  const truncateDescription = (text: string, maxLength: number = 80) => {
    if (text.length <= maxLength) return text;
    const truncated = text.substring(0, maxLength);
    const lastSpace = truncated.lastIndexOf(' ');
    return truncated.substring(0, lastSpace) + '...';
  };

  return (
    <>
      <Card className="group flex flex-col text-center shadow-lg hover:shadow-2xl transition-all duration-300 rounded-lg overflow-hidden h-full">
        <div className="relative bg-gray-100 flex-grow flex items-center justify-center aspect-square">
          <Image 
            src={product.imageUrl || getStockImageUrl(product.name)} 
            alt={product.name} 
            fill
            className="object-contain p-4 group-hover:scale-110 transition-transform duration-300"
          />
        </div>
        <CardContent className="p-4 bg-white flex-grow flex flex-col justify-between">
          <div>
            <h3 className="font-semibold truncate mb-2">{product.name}</h3>
            <p className="text-gray-500 text-sm leading-relaxed mb-3">
              {truncateDescription(product.description || "Deskripsi produk tidak tersedia.")}
            </p>
          </div>
          
          <Button 
            variant="outline" 
            size="sm" 
            className="mt-auto flex items-center gap-2 hover:bg-blue-50 hover:border-blue-300"
            onClick={() => handleViewDetails(product)}
          >
            <Eye className="h-4 w-4" />
            Lihat Detail
          </Button>
        </CardContent>
      </Card>

      <ProductModal 
        product={selectedProduct}
        isOpen={isModalOpen}
        onClose={closeModal}
      />
    </>
  );
};

// --- Komponen Utama ProductGrid ---
export default function ProductGrid({ products }: { products: Item[] }) {
  return (
    <div className="mt-12 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {products.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}