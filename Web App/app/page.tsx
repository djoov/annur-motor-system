import { PublicNavbar } from "@/components/layout/public-navbar";
import { Button } from "@/components/ui/button";
import { db } from "@/lib/firebase";
import { collection, getDocs, query, where } from "firebase/firestore";
import { Wrench, Droplets, ShoppingCart, MapPin, Mail, ShieldCheck, Tag, Clock, ArrowRight, Star, ChevronRight, Phone } from "lucide-react";
import Image from "next/image";
import type { Metadata } from 'next'
import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import LocationTracker from "@/components/layout/LocationTracker";
import ProductGrid from "@/components/layout/ProductGrid";
import { Item } from "@/types";
import { SITE_CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: 'Annur Motor - Toko Spare Part Motor Terpercaya di Magelang',
  description: 'Annur Motor menyediakan layanan servis motor profesional, ganti oli, dan menjual spare part original dan aftermarket terlengkap di Secang, Magelang. Kunjungi kami untuk solusi lengkap motor Anda.',
  keywords: ['bengkel motor magelang', 'toko spare part secang', 'servis motor', 'ganti oli', 'annur motor'],
  openGraph: {
    title: 'Annur Motor - Bengkel & Toko Spare Part Motor Terpercaya di Magelang',
    description: 'Layanan servis profesional dan spare part terlengkap.',
    images: [
      {
        url: 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=1200&auto=format&fit=crop',
        width: 1200,
        height: 630,
        alt: 'Bengkel Motor Annur Motor',
      },
    ],
  },
}

const WhatsAppButton = () => (
  <a
    href={SITE_CONFIG.whatsapp.getLink()}
    target="_blank"
    rel="noopener noreferrer"
    className="fixed bottom-6 right-6 z-50 bg-green-500 text-white p-4 rounded-full shadow-lg hover:bg-green-600 transition-transform hover:scale-110 flex items-center gap-2 group"
    aria-label="Hubungi via WhatsApp"
  >
    <Phone className="h-6 w-6" />
    <span className="max-w-0 overflow-hidden group-hover:max-w-xs transition-all duration-300 ease-in-out whitespace-nowrap">
      Chat WhatsApp
    </span>
  </a>
);

async function getFeaturedProducts(): Promise<Item[]> {
  try {
    const itemsRef = collection(db, "items");
    const q = query(itemsRef, where("stock", ">", 0));
    const querySnapshot = await getDocs(q);

    const allProducts = querySnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name,
        description: data.description,
        sellPrice: data.sellPrice || 0,
        buyPrice: data.buyPrice || 0,
        // Map legacy and new stock fields
        stock: data.stock || data.qty_display || 0,
        stockDisplay: data.qty_display || data.stock || 0,
        stockWarehouse: data.qty_warehouse || 0,
        imageUrl: data.imageUrl,
        category: data.category,
      } as Item;
    });

    for (let i = allProducts.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [allProducts[i], allProducts[j]] = [allProducts[j], allProducts[i]];
    }
    return allProducts.slice(0, 4); // Limit to 4 for the grid

  } catch (error) {
    console.error("Error fetching featured products:", error);
    return [];
  }
}

export default async function HomePage() {
  const featuredProducts = await getFeaturedProducts();

  return (
    <div className="bg-slate-50 text-slate-900 font-sans selection:bg-blue-100">
      <PublicNavbar />
      <WhatsAppButton />
      <LocationTracker />

      <main className="min-h-screen">
        {/* --- HERO SECTION --- */}
        <section className="relative pt-32 pb-20 lg:pt-48 lg:pb-32 overflow-hidden bg-slate-950">
          <div className="absolute inset-0 z-0">
            {/* Dynamic Background */}
            <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,_var(--tw-gradient-stops))] from-blue-900/30 via-slate-950/80 to-slate-950 z-10" />
            <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-10 z-0 mix-blend-overlay"></div>

            <Image
              src="https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=1200&auto=format&fit=crop"
              alt="Background Bengkel"
              fill
              className="object-cover opacity-20 animate-pulse-slow"
              priority
            />

            {/* Animated Decorative Floating Gears */}
            <div className="absolute top-20 right-[10%] opacity-10 animate-spin-slow duration-[20s] hidden lg:block pointer-events-none">
              <Wrench className="w-64 h-64 text-white" />
            </div>
            <div className="absolute bottom-40 left-[5%] opacity-5 animate-spin-reverse-slow duration-[25s] hidden lg:block pointer-events-none">
              <div className="w-48 h-48 rounded-full border-4 border-dashed border-orange-500/30"></div>
            </div>
          </div>

          <div className="container relative z-20 mx-auto px-4 text-center">
            <div className="animate-fade-in-down opacity-0" style={{ animationDelay: '0.1s', animationFillMode: 'forwards' }}>
              <Badge variant="secondary" className="mb-8 px-6 py-2 text-sm font-medium bg-blue-500/10 text-blue-300 border border-blue-500/20 backdrop-blur-md shadow-[0_0_20px_rgba(59,130,246,0.2)]">
                <Star className="w-3 h-3 mr-2 inline fill-blue-400 text-blue-400 animate-pulse" />
                Solusi Otomotif Terpercaya No. 1
              </Badge>
            </div>

            <h1 className="text-5xl md:text-7xl lg:text-8xl font-black tracking-tighter text-white mb-8 leading-[1.1] animate-fade-in-up opacity-0" style={{ animationDelay: '0.3s', animationFillMode: 'forwards' }}>
              Performa <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-500 via-cyan-400 to-blue-500 bg-[length:200%_auto] animate-pulse-slow">Maksimal</span> <br />
              <span className="relative inline-block mt-2">
                <span className="relative z-10">Untuk Kendaraan Anda</span>
                <span className="absolute bottom-3 left-0 w-full h-4 bg-orange-600/90 -rotate-1 z-0 blur-xl opacity-50"></span>
                <span className="absolute bottom-3 left-0 w-full h-4 bg-gradient-to-r from-orange-600 to-red-600 -rotate-1 z-0 mix-blend-overlay"></span>
              </span>
            </h1>

            <p className="mt-8 text-lg md:text-xl text-slate-300 max-w-2xl mx-auto mb-12 leading-relaxed animate-fade-in-up opacity-0" style={{ animationDelay: '0.5s', animationFillMode: 'forwards' }}>
              Menyediakan sparepart original, pelumas berkualitas, dan layanan servis profesional untuk motor dan sepeda onthel kesayangan Anda.
            </p>

            <div className="flex flex-col sm:flex-row gap-5 justify-center items-center animate-fade-in-up opacity-0" style={{ animationDelay: '0.7s', animationFillMode: 'forwards' }}>
              <Button asChild size="lg" className="bg-gradient-to-r from-orange-500 to-red-600 hover:from-orange-600 hover:to-red-700 text-white px-10 py-7 text-lg shadow-xl hover:shadow-orange-500/30 transition-all rounded-full group relative overflow-hidden">
                <a href="#produk">
                  <span className="relative z-10 flex items-center">
                    Cari Sparepart
                    <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
                  </span>
                  <div className="absolute inset-0 bg-white/20 translate-y-full group-hover:translate-y-0 transition-transform duration-300"></div>
                </a>
              </Button>
              <Button asChild size="lg" variant="outline" className="border-slate-700 text-slate-300 hover:bg-slate-800 hover:text-white px-10 py-7 text-lg rounded-full backdrop-blur-sm hover:border-slate-500 transition-all">
                <a href="#lokasi">Hubungi Kami</a>
              </Button>
            </div>

            {/* Stats / Trust Indicators */}
            <div className="mt-20 grid grid-cols-2 md:grid-cols-4 gap-8 border-t border-white/5 pt-12 max-w-5xl mx-auto animate-fade-in-up opacity-0" style={{ animationDelay: '0.9s', animationFillMode: 'forwards' }}>
              <div className="p-4 rounded-2xl hover:bg-white/5 transition-colors">
                <h4 className="text-4xl font-black text-white mb-1">1000+</h4>
                <p className="text-blue-400 text-sm font-medium tracking-wide uppercase">Pelanggan Puas</p>
              </div>
              <div className="p-4 rounded-2xl hover:bg-white/5 transition-colors">
                <h4 className="text-4xl font-black text-white mb-1">500+</h4>
                <p className="text-blue-400 text-sm font-medium tracking-wide uppercase">Produk Tersedia</p>
              </div>
              <div className="p-4 rounded-2xl hover:bg-white/5 transition-colors">
                <h4 className="text-4xl font-black text-white mb-1">100%</h4>
                <p className="text-blue-400 text-sm font-medium tracking-wide uppercase">Original</p>
              </div>
              <div className="p-4 rounded-2xl hover:bg-white/5 transition-colors">
                <h4 className="text-4xl font-black text-white mb-1">4.9</h4>
                <p className="text-blue-400 text-sm font-medium tracking-wide uppercase">Rating Google</p>
              </div>
            </div>
          </div>
        </section>

        {/* --- KEUNGGULAN (WHY CHOOSE US) --- */}
        <section id="keunggulan" className="py-24 bg-white relative">
          <div className="container mx-auto px-4">
            <div className="text-center max-w-3xl mx-auto mb-16">
              <h2 className="text-blue-600 font-bold tracking-wider uppercase text-sm mb-3">Mengapa Kami?</h2>
              <h3 className="text-3xl md:text-4xl font-extrabold text-slate-900">Alasan Memilih Annur Motor</h3>
              <p className="mt-4 text-slate-600 text-lg">Kami berkomitmen memberikan yang terbaik untuk setiap pelanggan.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {[
                {
                  icon: ShieldCheck,
                  title: "Terpercaya & Berpengalaman",
                  desc: "Didukung oleh mekanik berpengalaman yang mengerti detail setiap jengkal mesin kendaraan Anda.",
                  color: "text-blue-600",
                  bg: "bg-blue-50"
                },
                {
                  icon: Tag,
                  title: "Harga Transparan",
                  desc: "Kami memberikan harga yang jujur dan kompetitif tanpa biaya tersembunyi yang mengejutkan.",
                  color: "text-orange-500",
                  bg: "bg-orange-50"
                },
                {
                  icon: Clock,
                  title: "Pelayanan Cepat",
                  desc: "Waktu Anda berharga. Kami bekerja efisien untuk memastikan kendaraan segera siap digunakan.",
                  color: "text-green-600",
                  bg: "bg-green-50"
                }
              ].map((item, idx) => (
                <Card key={idx} className="border-none shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-2 group overflow-hidden bg-slate-50/50">
                  <CardContent className="p-8 text-center">
                    <div className={`w-20 h-20 mx-auto rounded-2xl ${item.bg} flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300`}>
                      <item.icon className={`h-10 w-10 ${item.color}`} />
                    </div>
                    <h3 className="text-xl font-bold text-slate-900 mb-3">{item.title}</h3>
                    <p className="text-slate-600 leading-relaxed">{item.desc}</p>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        </section>

        {/* --- LAYANAN (SERVICES) --- */}
        <section id="layanan" className="py-24 bg-slate-100/50">
          <div className="container mx-auto px-4 text-center">
            <div className="max-w-3xl mx-auto mb-16">
              <h2 className="text-orange-500 font-bold tracking-wider uppercase text-sm mb-3">Layanan Kami</h2>
              <h3 className="text-3xl md:text-4xl font-extrabold text-slate-900">Solusi Lengkap Kendaraan</h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {/* Service Item 1 */}
              <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-lg transition-all duration-300 border border-slate-100 text-left group relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-blue-50 rounded-bl-full -mr-8 -mt-8 transition-transform group-hover:scale-110"></div>
                <div className="relative z-10">
                  <div className="w-14 h-14 bg-blue-100 rounded-xl flex items-center justify-center mb-6 group-hover:bg-blue-600 transition-colors duration-300">
                    <Droplets className="h-7 w-7 text-blue-600 group-hover:text-white transition-colors" />
                  </div>
                  <h3 className="text-xl font-bold text-slate-900 mb-2">Ganti Oli & Cairan</h3>
                  <p className="text-slate-600 mb-6">Pilihan oli terlengkap dan berkualitas untuk menjaga performa mesin tetap prima.</p>
                  <span className="text-blue-600 font-bold text-sm flex items-center group-hover:translate-x-1 transition-transform cursor-pointer">
                    Lihat Produk <ChevronRight className="w-4 h-4 ml-1" />
                  </span>
                </div>
              </div>

              {/* Service Item 2 */}
              <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-lg transition-all duration-300 border border-slate-100 text-left group relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-orange-50 rounded-bl-full -mr-8 -mt-8 transition-transform group-hover:scale-110"></div>
                <div className="relative z-10">
                  <div className="w-14 h-14 bg-orange-100 rounded-xl flex items-center justify-center mb-6 group-hover:bg-orange-500 transition-colors duration-300">
                    <ShoppingCart className="h-7 w-7 text-orange-600 group-hover:text-white transition-colors" />
                  </div>
                  <h3 className="text-xl font-bold text-slate-900 mb-2">Sparepart Lengkap</h3>
                  <p className="text-slate-600 mb-6">Menyediakan suku cadang original dan aftermarket terpercaya untuk berbagai tipe motor.</p>
                  <span className="text-orange-600 font-bold text-sm flex items-center group-hover:translate-x-1 transition-transform cursor-pointer">
                    Cari Sparepart <ChevronRight className="w-4 h-4 ml-1" />
                  </span>
                </div>
              </div>

              {/* Service Item 3 */}
              <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-lg transition-all duration-300 border border-slate-100 text-left group relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-slate-100 rounded-bl-full -mr-8 -mt-8 transition-transform group-hover:scale-110"></div>
                <div className="relative z-10">
                  <div className="w-14 h-14 bg-slate-100 rounded-xl flex items-center justify-center mb-6 group-hover:bg-slate-800 transition-colors duration-300">
                    <Wrench className="h-7 w-7 text-slate-600 group-hover:text-white transition-colors" />
                  </div>
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="text-xl font-bold text-slate-900">Servis Profesional</h3>
                    <Badge variant="secondary" className="text-xs bg-slate-200 text-slate-700">Segera</Badge>
                  </div>
                  <p className="text-slate-600 mb-6">Layanan servis ringan hingga berat segera hadir dengan standar mekanik profesional.</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* --- PRODUK (PRODUCT HIGHLIGHT) --- */}
        <section id="produk" className="py-24 bg-white">
          <div className="container mx-auto px-4">
            <div className="flex flex-col md:flex-row justify-between items-end mb-12 gap-4 border-b border-slate-100 pb-8">
              <div className="max-w-2xl">
                <h2 className="text-blue-600 font-bold tracking-wider uppercase text-sm mb-3">Katalog Pilihan</h2>
                <h3 className="text-3xl md:text-4xl font-extrabold text-slate-900">Produk Terlaris Minggu Ini</h3>
                <p className="mt-4 text-slate-600 text-lg">Dapatkan sparepart berkualitas dengan harga terbaik.</p>
              </div>
              <Button variant="ghost" className="text-blue-600 hover:text-blue-700 hover:bg-blue-50 font-semibold">
                Lihat Semua Produk <ArrowRight className="ml-2 w-4 h-4" />
              </Button>
            </div>

            <ProductGrid products={featuredProducts} />
          </div>
        </section>

        {/* --- LOKASI (LOCATION) --- */}
        <section id="lokasi" className="py-24 bg-slate-900 text-white relative overflow-hidden">
          {/* Background Pattern */}
          <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-blue-600/20 rounded-full blur-[100px] -translate-y-1/2 translate-x-1/2 pointer-events-none" />
          <div className="absolute bottom-0 left-0 w-[300px] h-[300px] bg-orange-600/10 rounded-full blur-[80px] translate-y-1/2 -translate-x-1/4 pointer-events-none" />

          <div className="container mx-auto px-4 relative z-10">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
              <div>
                <Badge variant="outline" className="text-blue-300 border-blue-500/50 mb-6 px-3 py-1">Lokasi Kami</Badge>
                <h2 className="text-3xl md:text-5xl font-extrabold mb-8 leading-tight">Kunjungi <br />Bengkel Kami</h2>
                <p className="text-slate-300 mb-10 max-w-lg leading-relaxed text-lg">
                  Kami berlokasi strategis di Secang, Magelang. Siap melayani kebutuhan motor Anda setiap hari dengan pelayanan ramah.
                </p>

                <div className="space-y-6">
                  <div className="flex items-start gap-4 p-5 bg-white/5 rounded-2xl backdrop-blur-md border border-white/10 hover:bg-white/10 transition-colors">
                    <MapPin className="h-6 w-6 text-orange-500 mt-1 flex-shrink-0" />
                    <div>
                      <h3 className="font-bold text-lg text-white">Alamat</h3>
                      <p className="text-slate-300 text-sm mt-1 leading-relaxed">{SITE_CONFIG.contact.address}</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="flex items-start gap-4 p-5 bg-white/5 rounded-2xl backdrop-blur-md border border-white/10 hover:bg-white/10 transition-colors">
                      <Clock className="h-6 w-6 text-blue-500 mt-1 flex-shrink-0" />
                      <div>
                        <h3 className="font-bold text-white">Jam Buka</h3>
                        <p className="text-slate-300 text-sm mt-1 whitespace-pre-line leading-relaxed">
                          <span className="block">{SITE_CONFIG.contact.hours.weekdays}</span>
                          <span className="block text-slate-400">{SITE_CONFIG.contact.hours.sunday}</span>
                        </p>
                      </div>
                    </div>
                    <div className="flex items-start gap-4 p-5 bg-white/5 rounded-2xl backdrop-blur-md border border-white/10 hover:bg-white/10 transition-colors">
                      <Mail className="h-6 w-6 text-green-500 mt-1 flex-shrink-0" />
                      <div>
                        <h3 className="font-bold text-white">Kontak</h3>
                        <a href={`mailto:${SITE_CONFIG.contact.email}`} className="text-slate-300 hover:text-white text-sm mt-1 block truncate transition-colors">
                          {SITE_CONFIG.contact.email}
                        </a>
                        <p className="text-slate-400 text-sm mt-1 font-mono">{SITE_CONFIG.whatsapp.number}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="h-[450px] w-full rounded-2xl overflow-hidden shadow-2xl border-4 border-white/10 relative group">
                <div className="absolute inset-0 bg-slate-900/20 group-hover:bg-transparent transition-colors z-10 pointer-events-none"></div>
                {/* Map Overlay */}
                <iframe
                  src={SITE_CONFIG.contact.mapUrl}
                  width="100%"
                  height="100%"
                  style={{ border: 0 }}
                  allowFullScreen={false}
                  loading="lazy"
                  referrerPolicy="no-referrer-when-downgrade"
                  className="grayscale group-hover:grayscale-0 transition-all duration-700 w-full h-full"
                ></iframe>
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="bg-slate-950 text-slate-400 py-12 border-t border-slate-900">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-2xl font-bold text-white mb-6 uppercase tracking-widest">{SITE_CONFIG.name}</h2>
          <div className="flex justify-center gap-8 mb-8 text-sm font-medium">
            <a href="#layanan" className="hover:text-blue-500 transition-colors">Layanan</a>
            <a href="#produk" className="hover:text-blue-500 transition-colors">Produk</a>
            <a href="#lokasi" className="hover:text-blue-500 transition-colors">Lokasi</a>
          </div>
          <p className="text-xs text-slate-600">
            © {new Date().getFullYear()} {SITE_CONFIG.name}. All Rights Reserved.
            <span className="mx-2 opacity-50">|</span>
            <Link href="/login" className="text-slate-600 hover:text-blue-500 transition-colors">Login Staf</Link>
          </p>
        </div>
      </footer>
    </div>
  );
}
