"use client";

import { useState, useEffect, useMemo } from "react";
import { PublicNavbar } from "@/components/layout/public-navbar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Search, Package, X as CloseIcon, MessageCircle, Filter, ChevronDown } from "lucide-react";
import Image from "next/image";
import { db } from "@/lib/firebase";
import { collection, onSnapshot, query, orderBy } from "firebase/firestore";
import { Item } from "@/types";
import { SITE_CONFIG } from "@/lib/config";
import Link from "next/link"; // Ensure Link is imported if needed, although mostly used in Navbar

// --- Helper: Get Stock Image ---
function getStockImageUrl(productName: string): string {
    const name = productName.toLowerCase();
    if (name.includes('oli')) return "https://images.unsplash.com/photo-1627866502353-6113c8542a8c?q=80&w=800";
    if (name.includes('ban')) return "https://images.unsplash.com/photo-1617008394248-a765dd79462b?q=80&w=800";
    if (name.includes('aki')) return "https://images.unsplash.com/photo-1588287314523-2334485b63bc?q=80&w=800";
    if (name.includes('kampas')) return "https://images.unsplash.com/photo-1620892379929-4786d52a2f26?q=80&w=800";
    if (name.includes('busi')) return "https://images.unsplash.com/photo-1617153200151-a5836d502158?q=80&w=800";
    return `https://placehold.co/400x400/f1f5f9/475569?text=${encodeURIComponent(productName)}`;
}

// --- Product Modal (No Price) ---
const ProductModal = ({ product, onClose }: { product: Item; onClose: () => void }) => {
    return (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in duration-200" onClick={onClose}>
            <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto relative shadow-2xl" onClick={(e) => e.stopPropagation()}>
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
                            {product.category && (
                                <Badge variant="secondary" className="mb-4">{product.category}</Badge>
                            )}
                        </div>

                        <div>
                            <p className="text-sm text-slate-500 mb-4 italic">Untuk harga terbaru, silakan hubungi kami.</p>
                            <Button
                                size="lg"
                                className="w-full bg-green-500 hover:bg-green-600 text-white font-bold h-12 text-base shadow-lg shadow-green-500/20"
                                onClick={() => {
                                    const message = `Halo Annur Motor, saya tertarik dengan produk: ${product.name}. Berapa harganya dan apakah stoknya masih tersedia?`;
                                    window.open(`${SITE_CONFIG.whatsapp.getLink(message)}`, '_blank');
                                }}
                            >
                                <MessageCircle className="w-5 h-5 mr-2" />
                                Tanya Harga via WhatsApp
                            </Button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

// --- Product Card (No Price) ---
const ProductCard = ({ product, onViewDetails }: { product: Item; onViewDetails: (product: Item) => void }) => {
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
            </div>

            <CardContent className="p-5 flex-grow flex flex-col">
                <h3 className="font-bold text-slate-900 mb-2 line-clamp-2 min-h-[3rem] group-hover:text-blue-600 transition-colors" title={product.name}>
                    {product.name}
                </h3>
                <p className="text-slate-500 text-xs leading-relaxed line-clamp-2 mb-3 flex-grow">
                    {product.description || "Spesifikasi standar orisinil pabrik."}
                </p>
                {product.category && (
                    <Badge variant="outline" className="w-fit text-xs">{product.category}</Badge>
                )}
            </CardContent>
        </Card>
    );
};

// --- Main Katalog Page ---
export default function KatalogPage() {
    const [products, setProducts] = useState<Item[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState("");
    const [selectedCategory, setSelectedCategory] = useState("Semua");
    const [selectedProduct, setSelectedProduct] = useState<Item | null>(null);

    // Fetch Products Real-time
    useEffect(() => {
        setIsLoading(true);
        const q = query(collection(db, "items"), orderBy("name"));

        const unsubscribe = onSnapshot(q, (snapshot) => {
            const fetchedProducts = snapshot.docs
                .map((doc) => {
                    const data = doc.data();
                    return {
                        id: doc.id,
                        name: data.name,
                        description: data.description,
                        sellPrice: data.sellPrice || 0,
                        buyPrice: data.buyPrice || 0,
                        stock: data.stock || data.qty_display || 0,
                        stockDisplay: data.qty_display || data.stock || 0,
                        stockWarehouse: data.qty_warehouse || 0,
                        imageUrl: data.imageUrl,
                        category: data.category || "Lain-lain",
                        code: data.code,
                    } as Item;
                })
                .filter((item) => item.stock > 0); // Only show items in stock
            setProducts(fetchedProducts);
            setIsLoading(false);
        });

        return () => unsubscribe();
    }, []);

    // Extract unique categories
    const categories = useMemo(() => {
        const cats = new Set(products.map((p) => p.category || "Lain-lain"));
        return ["Semua", ...Array.from(cats).sort()];
    }, [products]);

    // Filter products
    const filteredProducts = useMemo(() => {
        return products.filter((product) => {
            const matchSearch =
                product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                (product.code && product.code.toLowerCase().includes(searchTerm.toLowerCase()));
            const matchCategory = selectedCategory === "Semua" || product.category === selectedCategory;
            return matchSearch && matchCategory;
        });
    }, [products, searchTerm, selectedCategory]);

    return (
        <div className="bg-slate-50 min-h-screen">
            <PublicNavbar />

            {/* Header */}
            <header className="bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 pt-28 pb-16">
                <div className="container mx-auto px-4 text-center">
                    <Badge variant="secondary" className="mb-4 bg-blue-500/10 text-blue-300 border-blue-500/20">
                        <Package className="w-3 h-3 mr-2" />
                        Katalog Lengkap
                    </Badge>
                    <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">Daftar Sparepart</h1>
                    <p className="text-slate-400 max-w-xl mx-auto">
                        Temukan sparepart motor yang Anda butuhkan. Hubungi kami untuk informasi harga terbaru.
                    </p>
                </div>
            </header>

            {/* Search & Filter */}
            <div className="container mx-auto px-4 -mt-8">
                <div className="bg-white rounded-2xl shadow-lg p-4 md:p-6 flex flex-col md:flex-row gap-4 items-center">
                    <div className="relative flex-grow w-full md:w-auto">
                        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-5 h-5" />
                        <Input
                            placeholder="Cari nama atau kode barang..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="pl-12 h-12 text-base bg-slate-50 border-slate-200 focus:border-blue-500"
                        />
                    </div>
                    <div className="flex gap-2 flex-wrap justify-center">
                        {categories.slice(0, 5).map((cat) => (
                            <Button
                                key={cat}
                                variant={selectedCategory === cat ? "default" : "outline"}
                                size="sm"
                                onClick={() => setSelectedCategory(cat)}
                                className={selectedCategory === cat ? "bg-blue-600" : ""}
                            >
                                {cat}
                            </Button>
                        ))}
                        {categories.length > 5 && (
                            <Button variant="ghost" size="sm">
                                <ChevronDown className="w-4 h-4 mr-1" /> Lainnya
                            </Button>
                        )}
                    </div>
                </div>
            </div>

            {/* Product Grid */}
            <main className="container mx-auto px-4 py-12">
                {isLoading ? (
                    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                        {[...Array(8)].map((_, i) => (
                            <div key={i} className="bg-white rounded-xl h-72 animate-pulse" />
                        ))}
                    </div>
                ) : filteredProducts.length > 0 ? (
                    <>
                        <p className="text-slate-500 mb-6">Menampilkan {filteredProducts.length} produk</p>
                        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                            {filteredProducts.map((product) => (
                                <ProductCard key={product.id} product={product} onViewDetails={setSelectedProduct} />
                            ))}
                        </div>
                    </>
                ) : (
                    <div className="text-center py-20 bg-white rounded-2xl border border-dashed border-slate-200">
                        <Package className="w-12 h-12 text-slate-300 mx-auto mb-4" />
                        <h3 className="text-lg font-medium text-slate-900">Tidak ada produk ditemukan</h3>
                        <p className="text-slate-500 mt-1">Coba ubah kata kunci atau filter kategori.</p>
                    </div>
                )}
            </main>

            {/* Modal */}
            {selectedProduct && <ProductModal product={selectedProduct} onClose={() => setSelectedProduct(null)} />}
        </div>
    );
}
