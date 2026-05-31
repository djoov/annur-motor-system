"use client";

import { useState, useEffect, useMemo, useCallback } from "react";
import { PublicNavbar } from "@/components/layout/public-navbar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Search, Package, X as CloseIcon, MessageCircle, ChevronDown, Zap, Eye } from "lucide-react";
import Image from "next/image";
import { db } from "@/lib/firebase";
import { collection, onSnapshot, query, orderBy } from "firebase/firestore";
import { Item } from "@/types";
import { SITE_CONFIG } from "@/lib/config";

// --- Helper: Get Stock Image ---
function getStockImageUrl(productName: string): string {
    const name = productName.toLowerCase();
    if (name.includes('oli')) return "https://images.unsplash.com/photo-1627866502353-6113c8542a8c?q=80&w=800";
    if (name.includes('ban')) return "https://images.unsplash.com/photo-1617008394248-a765dd79462b?q=80&w=800";
    if (name.includes('aki')) return "https://images.unsplash.com/photo-1588287314523-2334485b63bc?q=80&w=800";
    if (name.includes('kampas')) return "https://images.unsplash.com/photo-1620892379929-4786d52a2f26?q=80&w=800";
    if (name.includes('busi')) return "https://images.unsplash.com/photo-1617153200151-a5836d502158?q=80&w=800";
    return `https://placehold.co/400x400/09090b/e4e4e7?text=${encodeURIComponent(productName)}`;
}

// --- Product Modal (No Price) ---
const ProductModal = ({ product, onClose }: { product: Item; onClose: () => void }) => {
    const stableOnClose = useCallback(onClose, [onClose]);

    useEffect(() => {
        document.body.style.overflow = 'hidden';
        const handleEscape = (e: KeyboardEvent) => {
            if (e.key === 'Escape') stableOnClose();
        };
        document.addEventListener('keydown', handleEscape);
        return () => {
            document.body.style.overflow = '';
            document.removeEventListener('keydown', handleEscape);
        };
    }, [stableOnClose]);

    const isInStock = (product.stock ?? 0) > 0;

    return (
        <div className="fixed inset-0 bg-black/90 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in duration-200" onClick={onClose}>
            <div className="bg-black border border-zinc-800 rounded-none max-w-4xl w-full max-h-[90vh] overflow-y-auto relative shadow-2xl shadow-orange-900/20 scale-100 animate-in zoom-in-95 duration-200" onClick={(e) => e.stopPropagation()}>
                
                {/* Header Bar */}
                <div className="flex justify-between items-center p-4 border-b border-zinc-800 bg-zinc-950">
                    <div className="font-mono text-xs text-zinc-500 uppercase tracking-widest flex items-center gap-2">
                        <Zap className="w-3 h-3 text-orange-500" />
                        Product Specs Detail
                    </div>
                    <button
                        onClick={onClose}
                        className="text-zinc-500 hover:text-orange-500 transition-colors"
                        aria-label="Tutup"
                    >
                        <CloseIcon size={24} />
                    </button>
                </div>

                <div className="grid md:grid-cols-2">
                    {/* Image Section */}
                    <div className="aspect-square bg-zinc-950 relative flex items-center justify-center border-b md:border-b-0 md:border-r border-zinc-800 p-8 group">
                        {/* Tech grid overlay */}
                        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:2rem_2rem] pointer-events-none"></div>
                        
                        <Image
                            src={product.imageUrl || getStockImageUrl(product.name)}
                            alt={product.name}
                            fill
                            className="object-contain p-8 filter brightness-90 group-hover:brightness-110 transition-all duration-500"
                        />
                    </div>

                    {/* Details Section */}
                    <div className="p-8 md:p-10 flex flex-col justify-between h-full bg-black">
                        <div>
                            <div className="mb-6 flex justify-between items-start">
                                <Badge variant="outline" className={`rounded-none px-3 py-1 font-mono text-xs uppercase tracking-widest ${isInStock ? "text-orange-500 border-orange-500 bg-orange-950/30" : "text-zinc-500 border-zinc-700 bg-zinc-900"}`}>
                                    {isInStock ? "IN STOCK" : "OUT OF STOCK"}
                                </Badge>
                                {product.category && (
                                    <span className="text-zinc-500 text-xs font-mono uppercase tracking-widest">{product.category}</span>
                                )}
                            </div>
                            
                            <h3 className="text-3xl md:text-4xl font-black text-white mb-6 uppercase tracking-tight leading-none">{product.name}</h3>
                            
                            <div className="bg-zinc-950 p-6 border border-zinc-900 mb-8">
                                <p className="text-zinc-400 leading-relaxed text-sm font-medium">
                                    {product.description || "Spesifikasi lengkap untuk komponen ini belum tersedia di database. Hubungi teknisi kami untuk kompatibilitas dan detail teknis lebih lanjut."}
                                </p>
                            </div>
                        </div>

                        <div className="mt-auto">
                            <p className="text-xs text-zinc-500 font-mono tracking-widest uppercase mb-4 border-l-2 border-orange-500 pl-3">Untuk harga terbaru, silakan hubungi kami.</p>
                            <Button
                                size="lg"
                                className="w-full bg-orange-600 hover:bg-orange-500 text-white font-black tracking-widest uppercase h-14 rounded-none transition-colors border border-orange-500"
                                onClick={() => {
                                    const message = `Halo Annur Motor, saya tertarik dengan produk: ${product.name}. Berapa harganya dan apakah stoknya masih tersedia?`;
                                    window.open(`https://wa.me/${SITE_CONFIG.whatsapp.number}?text=${encodeURIComponent(message)}`, '_blank');
                                }}
                            >
                                <MessageCircle className="w-5 h-5 mr-3" />
                                Tanya Harga via WA
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
        <Card className="group flex flex-col h-full border-zinc-800 rounded-none shadow-none hover:border-orange-500 transition-all duration-300 bg-black overflow-hidden cursor-pointer relative" onClick={() => onViewDetails(product)}>
            {/* Top accent line */}
            <div className="absolute top-0 left-0 w-full h-1 bg-zinc-800 group-hover:bg-orange-500 transition-colors z-20"></div>

            <div className="relative bg-zinc-950 aspect-[4/3] flex items-center justify-center overflow-hidden border-b border-zinc-800 group-hover:border-orange-500/30 transition-colors">
                {/* Subtle grid background */}
                <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:1rem_1rem] pointer-events-none"></div>
                
                <Image
                    src={product.imageUrl || getStockImageUrl(product.name)}
                    alt={product.name}
                    fill
                    className="object-contain p-8 group-hover:scale-110 transition-transform duration-700 ease-out filter brightness-90 group-hover:brightness-110"
                />
                
                {/* Techy Eye Button */}
                <div className="absolute bottom-4 right-4 z-20 opacity-0 group-hover:opacity-100 translate-y-4 group-hover:translate-y-0 transition-all duration-300">
                    <div className="bg-orange-600 text-white p-3 border border-orange-400 shadow-[0_0_15px_rgba(234,88,12,0.5)] flex items-center justify-center">
                        <Eye className="w-5 h-5" />
                    </div>
                </div>
            </div>

            <CardContent className="p-6 flex-grow flex flex-col justify-between bg-black relative">
                <div>
                    <h3 className="font-black text-white uppercase tracking-tight mb-3 line-clamp-2 min-h-[3rem] group-hover:text-orange-500 transition-colors leading-tight" title={product.name}>
                        {product.name}
                    </h3>
                    <p className="text-zinc-500 text-xs leading-relaxed line-clamp-2 mb-6 font-medium">
                        {product.description || "Komponen presisi tinggi. Sesuai spesifikasi pabrikan."}
                    </p>
                </div>
                
                <div className="flex items-end justify-between border-t border-zinc-900 pt-4 mt-auto">
                    {product.category && (
                        <Badge variant="outline" className="w-fit text-[10px] rounded-none border-zinc-700 text-zinc-400 uppercase tracking-widest">{product.category}</Badge>
                    )}
                </div>
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
        <div className="bg-zinc-950 min-h-screen text-zinc-300 font-sans">
            <PublicNavbar />

            {/* Header */}
            <header className="relative bg-black pt-32 pb-16 border-b border-zinc-800 overflow-hidden">
                {/* Tech background elements */}
                <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.03)_1px,transparent_1px)] bg-[size:4rem_4rem] z-0 pointer-events-none"></div>
                <div className="absolute top-0 right-0 w-1/2 h-full bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-orange-900/20 via-transparent to-transparent pointer-events-none"></div>

                <div className="container mx-auto px-4 relative z-10">
                    <div className="flex items-center gap-4 mb-6">
                        <div className="w-12 h-px bg-orange-500"></div>
                        <h2 className="text-orange-500 font-bold tracking-[0.2em] uppercase text-sm">Hardware Database</h2>
                    </div>
                    <h1 className="text-5xl md:text-7xl font-black text-white mb-6 uppercase tracking-tighter">Daftar Komponen</h1>
                    <p className="text-zinc-400 max-w-xl text-lg font-medium">
                        Akses penuh ke ribuan SKU suku cadang motor. Temukan komponen spesifik yang Anda cari dengan presisi.
                    </p>
                </div>
            </header>

            {/* Search & Filter */}
            <div className="container mx-auto px-4 relative z-20 -mt-8">
                <div className="bg-black border border-zinc-800 p-6 flex flex-col md:flex-row gap-6 items-center shadow-2xl">
                    <div className="relative flex-grow w-full md:w-auto">
                        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-orange-500 w-5 h-5" />
                        <Input
                            placeholder="INPUT KODE ATAU NAMA KOMPONEN..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="pl-12 h-14 text-base bg-zinc-950 border-zinc-800 focus:border-orange-500 rounded-none text-white font-mono uppercase placeholder:text-zinc-600"
                        />
                    </div>
                    <div className="flex gap-2 flex-wrap justify-center w-full md:w-auto">
                        {categories.slice(0, 5).map((cat) => (
                            <Button
                                key={cat}
                                variant={selectedCategory === cat ? "default" : "outline"}
                                size="sm"
                                onClick={() => setSelectedCategory(cat)}
                                className={`rounded-none h-14 px-6 font-bold tracking-widest uppercase transition-all ${
                                    selectedCategory === cat 
                                    ? "bg-orange-600 hover:bg-orange-500 text-white border-orange-500" 
                                    : "bg-transparent border-zinc-800 text-zinc-400 hover:text-white hover:border-zinc-600"
                                }`}
                            >
                                {cat}
                            </Button>
                        ))}
                        {categories.length > 5 && (
                            <Button variant="outline" size="sm" className="rounded-none h-14 bg-transparent border-zinc-800 text-zinc-400 hover:text-white font-bold tracking-widest uppercase">
                                <ChevronDown className="w-4 h-4 mr-2" /> LAINNYA
                            </Button>
                        )}
                    </div>
                </div>
            </div>

            {/* Product Grid */}
            <main className="container mx-auto px-4 py-16">
                {isLoading ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                        {[...Array(8)].map((_, i) => (
                            <div key={i} className="bg-zinc-900 border border-zinc-800 h-96 animate-pulse" />
                        ))}
                    </div>
                ) : filteredProducts.length > 0 ? (
                    <>
                        <div className="flex items-center gap-4 mb-8">
                            <span className="text-orange-500 font-mono text-xs uppercase tracking-widest bg-orange-500/10 px-3 py-1 border border-orange-500/20">
                                {filteredProducts.length} ITEMS DETECTED
                            </span>
                        </div>
                        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                            {filteredProducts.map((product) => (
                                <ProductCard key={product.id} product={product} onViewDetails={setSelectedProduct} />
                            ))}
                        </div>
                    </>
                ) : (
                    <div className="text-center py-32 bg-black border border-zinc-800 relative overflow-hidden group">
                        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:2rem_2rem] pointer-events-none"></div>
                        <div className="w-20 h-20 bg-zinc-900 border border-zinc-800 flex items-center justify-center mx-auto mb-6">
                            <Package className="w-8 h-8 text-zinc-600" />
                        </div>
                        <h3 className="text-3xl font-black text-white uppercase tracking-tighter mb-4">DATA TIDAK DITEMUKAN</h3>
                        <p className="text-zinc-500 font-mono text-sm uppercase tracking-widest">
                            Ubah parameter pencarian atau filter kategori.
                        </p>
                    </div>
                )}
            </main>

            {/* Modal */}
            {selectedProduct && <ProductModal product={selectedProduct} onClose={() => setSelectedProduct(null)} />}
        </div>
    );
}
