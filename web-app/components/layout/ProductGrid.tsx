'use client';

import { useState } from 'react';
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardFooter } from "@/components/ui/card";
import { Eye, X as CloseIcon, ShoppingCart, MessageCircle } from "lucide-react";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";
import { Item } from "@/types";

// --- Fungsi Helper ---
function getStockImageUrl(productName: string): string {
  const name = productName.toLowerCase();
  if (name.includes('oli')) return "https://images.unsplash.com/photo-1627866502353-6113c8542a8c?q=80&w=800";
  if (name.includes('ban')) return "https://images.unsplash.com/photo-1617008394248-a765dd79462b?q=80&w=800";
  if (name.includes('aki')) return "https://images.unsplash.com/photo-1588287314523-2334485b63bc?q=80&w=800";
  if (name.includes('kampas')) return "https://images.unsplash.com/photo-1620892379929-4786d52a2f26?q=80&w=800";
  if (name.includes('busi')) return "https://images.unsplash.com/photo-1617153200151-a5836d502158?q=80&w=800";
  return `https://placehold.co/400x400/f1f5f9/475569?text=${encodeURIComponent(productName)}`;
}

// --- Komponen Modal untuk Detail Produk ---
const ProductModal = ({ product, onClose }: { product: Item, onClose: () => void }) => {
  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in duration-200" onClick={onClose}>
      <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto relative shadow-2xl scale-100 animate-in zoom-in-95 duration-200" onClick={(e) => e.stopPropagation()}>
        <button
          onClick={onClose}
          className="absolute top-4 right-4 bg-white/80 p-2 rounded-full text-slate-500 hover:text-red-500 hover:bg-red-50 transition-colors z-20"
          aria-label="Tutup"
        >
          <CloseIcon size={20} />
        </button>

        <div className="grid md:grid-cols-2">
          <div className="aspect-square bg-slate-50 relative flex items-center justify-center border-b md:border-b-0 md:border-r border-slate-100">
            <Image
              src={product.imageUrl || getStockImageUrl(product.name)}
              alt={product.name}
              fill
              className="object-contain p-8"
            />
          </div>

          <div className="p-8 flex flex-col justify-between h-full">
            <div>
              <div className="mb-2">
                <Badge variant="outline" className="text-blue-600 border-blue-200 bg-blue-50">Stok Tersedia</Badge>
              </div>
              <h3 className="text-2xl font-bold text-slate-900 mb-4 leading-tight">{product.name}</h3>
              <p className="text-slate-600 leading-relaxed mb-6 bg-slate-50 p-4 rounded-lg border border-slate-100 text-sm">
                {product.description || "Deskripsi lengkap produk belum tersedia saat ini. Silakan hubungi kami untuk detail lebih lanjut."}
              </p>
            </div>

            <div>
              <p className="text-sm text-slate-500 mb-1">Harga Satuan</p>
              <p className="text-3xl font-extrabold text-orange-600 mb-8">
                Rp {(product.sellPrice || 0).toLocaleString("id-ID")}
              </p>
              <Button
                size="lg"
                className="w-full bg-green-500 hover:bg-green-600 text-white font-bold h-12 text-base shadow-lg shadow-green-500/20"
                onClick={() => {
                  const message = `Halo Annur Motor, saya tertarik dengan produk: ${product.name}. Apakah stoknya masih tersedia?`;
                  window.open(`https://wa.me/6288983773114?text=${encodeURIComponent(message)}`, '_blank');
                }}
              >
                <MessageCircle className="w-5 h-5 mr-2" />
                Beli via WhatsApp
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// --- Komponen Kartu Produk ---
const ProductCard = ({ product, onViewDetails }: { product: Item, onViewDetails: (product: Item) => void }) => {
  return (
    <Card className="group flex flex-col h-full border-none shadow-sm hover:shadow-xl transition-all duration-300 hover:-translate-y-1 bg-white overflow-hidden ring-1 ring-slate-100 cursor-pointer" onClick={() => onViewDetails(product)}>
      <div className="relative bg-slate-50 aspect-[4/3] flex items-center justify-center overflow-hidden">
        <div className="absolute inset-0 bg-white/50 opacity-0 group-hover:opacity-100 transition-opacity z-10" />
        <Image
          src={product.imageUrl || getStockImageUrl(product.name)}
          alt={product.name}
          fill
          className="object-contain p-6 group-hover:scale-110 transition-transform duration-500 ease-out mix-blend-multiply"
        />
        <div className="absolute bottom-3 right-3 z-20 translate-y-10 group-hover:translate-y-0 transition-transform duration-300">
          <Button size="icon" className="rounded-full shadow-lg bg-white text-slate-900 hover:bg-blue-600 hover:text-white" onClick={(e) => { e.stopPropagation(); onViewDetails(product); }}>
            <Eye className="w-4 h-4" />
          </Button>
        </div>
      </div>

      <CardContent className="p-5 flex-grow">
        <h3 className="font-bold text-slate-900 mb-2 line-clamp-2 min-h-[3rem] group-hover:text-blue-600 transition-colors" title={product.name}>
          {product.name}
        </h3>
        <p className="text-slate-500 text-xs leading-relaxed line-clamp-2 mb-3">
          {product.description || "Spesifikasi standar orisinil pabrik."}
        </p>
        <p className="text-lg font-extrabold text-orange-600">
          Rp {(product.sellPrice || 0).toLocaleString("id-ID")}
        </p>
      </CardContent>
    </Card>
  );
};

// --- Komponen Utama ProductGrid ---
export default function ProductGrid({ products }: { products: Item[] }) {
  const [selectedProduct, setSelectedProduct] = useState<Item | null>(null);

  return (
    <>
      {products.length > 0 ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6 lg:gap-8">
          {products.map((product) => (
            <ProductCard key={product.id} product={product} onViewDetails={setSelectedProduct} />
          ))}
        </div>
      ) : (
        <div className="text-center py-20 bg-slate-50 rounded-2xl border border-dashed border-slate-200">
          <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <ShoppingCart className="w-8 h-8 text-slate-400" />
          </div>
          <h3 className="text-lg font-medium text-slate-900">Belum ada produk</h3>
          <p className="text-slate-500 max-w-md mx-auto mt-1">
            Katalog produk sedang disiapkan. Silakan hubungi kami untuk menanyakan ketersediaan sparepart.
          </p>
        </div>
      )}

      {selectedProduct && <ProductModal product={selectedProduct} onClose={() => setSelectedProduct(null)} />}
    </>
  );
}
