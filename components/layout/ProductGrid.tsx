'use client';

import { useState } from 'react';
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Eye, X as CloseIcon } from "lucide-react";
import Image from "next/image";

// --- Interface untuk data produk ---
interface Item {
  id: string;
  name: string;
  description: string;
  sellPrice: number;
  imageUrl?: string;
}

// --- Fungsi Helper dipindahkan ke sini agar mandiri ---
function getStockImageUrl(productName: string): string {
    const name = productName.toLowerCase();
    if (name.includes('oli')) return "https://images.unsplash.com/photo-1627866502353-6113c8542a8c?q=80&w=800";
    if (name.includes('ban')) return "https://images.unsplash.com/photo-1617008394248-a765dd79462b?q=80&w=800";
    if (name.includes('aki')) return "https://images.unsplash.com/photo-1588287314523-2334485b63bc?q=80&w=800";
    if (name.includes('kampas')) return "https://images.unsplash.com/photo-1620892379929-4786d52a2f26?q=80&w=800";
    if (name.includes('busi')) return "https://images.unsplash.com/photo-1617153200151-a5836d502158?q=80&w=800";
    return `https://placehold.co/400x400/e2e8f0/64748b?text=${encodeURIComponent(productName)}`;
}

// --- Komponen Modal untuk Detail Produk ---
const ProductModal = ({ product, onClose }: { product: Item, onClose: () => void }) => {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-60 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white rounded-lg max-w-lg w-full max-h-[90vh] overflow-y-auto relative" onClick={(e) => e.stopPropagation()}>
        <button 
          onClick={onClose}
          className="absolute top-2 right-2 text-gray-400 hover:text-gray-800 z-10"
          aria-label="Tutup"
        >
          <CloseIcon size={24} />
        </button>
        <div className="aspect-square bg-gray-100 rounded-t-lg relative overflow-hidden">
          <Image 
            src={product.imageUrl || getStockImageUrl(product.name)} 
            alt={product.name} 
            layout="fill" 
            objectFit="contain"
            className="p-4"
          />
        </div>
        <div className="p-6">
          <h3 className="text-2xl font-bold mb-2">{product.name}</h3>
          <p className="text-gray-600 leading-relaxed mb-4">
            {product.description || "Deskripsi produk tidak tersedia."}
          </p>
          <p className="text-2xl font-bold text-blue-600 mb-6">
            Rp {(product.sellPrice || 0).toLocaleString("id-ID")}
          </p>
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
  );
};

// --- Komponen Kartu Produk ---
const ProductCard = ({ product, onViewDetails }: { product: Item, onViewDetails: (product: Item) => void }) => {
  const truncateDescription = (text: string, maxLength: number = 60) => {
    if (!text || text.length <= maxLength) return text;
    const truncated = text.substring(0, maxLength);
    const lastSpace = truncated.lastIndexOf(' ');
    return truncated.substring(0, lastSpace > 0 ? lastSpace : maxLength) + '...';
  };

  return (
    <Card className="group flex flex-col text-center shadow-lg hover:shadow-2xl transition-all duration-300 rounded-lg overflow-hidden h-full">
      <div className="relative bg-gray-100 flex-grow flex items-center justify-center aspect-square">
        <Image 
          src={product.imageUrl || getStockImageUrl(product.name)} 
          alt={product.name} 
          layout="fill" 
          objectFit="contain"
          className="p-4 group-hover:scale-110 transition-transform duration-300"
        />
      </div>
      <CardContent className="p-4 bg-white flex-grow flex flex-col justify-between">
        <div>
          <h3 className="font-semibold truncate mb-2">{product.name}</h3>
          <p className="text-gray-500 text-sm leading-relaxed h-12">
            {truncateDescription(product.description || "Deskripsi produk tidak tersedia.")}
          </p>
        </div>
        <Button 
          variant="outline" 
          size="sm" 
          className="mt-4 w-full flex items-center gap-2 hover:bg-blue-50 hover:border-blue-300"
          onClick={() => onViewDetails(product)}
        >
          <Eye className="h-4 w-4" />
          Lihat Detail
        </Button>
      </CardContent>
    </Card>
  );
};

// --- Komponen Utama ProductGrid ---
export default function ProductGrid({ products }: { products: Item[] }) {
  const [selectedProduct, setSelectedProduct] = useState<Item | null>(null);

  const handleViewDetails = (product: Item) => {
    setSelectedProduct(product);
  };

  const closeModal = () => {
    setSelectedProduct(null);
  };
  
  return (
    <>
        <div className="mt-12 grid grid-cols-2 md:grid-cols-4 gap-6">
            {products.map((product) => (
                <ProductCard key={product.id} product={product} onViewDetails={handleViewDetails} />
            ))}
        </div>
        {selectedProduct && <ProductModal product={selectedProduct} onClose={closeModal} />}
    </>
  );
}
