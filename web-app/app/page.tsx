import { PublicNavbar } from "@/components/layout/public-navbar";
import { Button } from "@/components/ui/button";
import { db } from "@/lib/firebase";
import { collection, getDocs, query, where, limit } from "firebase/firestore";
import { Wrench, Droplets, ShoppingCart, MapPin, Mail, ShieldCheck, Tag, Clock, ArrowRight, Star, ChevronRight, Phone, Zap } from "lucide-react";
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
  title: 'Annur Motor - Performa Otomotif Maksimal',
  description: 'Annur Motor menyediakan sparepart original, pelumas, dan layanan mekanik berstandar tinggi di Secang, Magelang. Tingkatkan performa mesin Anda.',
  keywords: ['bengkel motor magelang', 'toko spare part secang', 'servis motor', 'ganti oli', 'annur motor', 'racing parts'],
  openGraph: {
    title: 'Annur Motor - Performa Otomotif Maksimal',
    description: 'Sparepart berkualitas tinggi dan layanan mekanik profesional.',
    images: [
      {
        url: 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=1200&auto=format&fit=crop',
        width: 1200,
        height: 630,
        alt: 'Annur Motor Workshop',
      },
    ],
  },
}

const WhatsAppButton = () => (
  <a
    href={SITE_CONFIG.whatsapp.getLink()}
    target="_blank"
    rel="noopener noreferrer"
    className="fixed bottom-6 right-6 z-50 bg-orange-600 text-white p-4 rounded-none shadow-2xl hover:bg-orange-500 transition-all hover:scale-105 flex items-center gap-2 group border border-orange-400"
    aria-label="Hubungi via WhatsApp"
  >
    <Phone className="h-6 w-6" />
    <span className="max-w-0 overflow-hidden group-hover:max-w-xs transition-all duration-300 ease-in-out whitespace-nowrap font-bold uppercase tracking-wider text-sm">
      Chat WhatsApp
    </span>
  </a>
);

async function getFeaturedProducts(): Promise<Item[]> {
  try {
    const itemsRef = collection(db, "items");
    const q = query(itemsRef, where("stock", ">", 0), limit(20));
    const querySnapshot = await getDocs(q);

    const allProducts = querySnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name,
        description: data.description,
        sellPrice: data.sellPrice || 0,
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
    <div className="bg-zinc-950 text-zinc-300 font-sans selection:bg-orange-500/30 selection:text-white">
      <PublicNavbar />
      <WhatsAppButton />
      <LocationTracker />

      <main className="min-h-screen">
        {/* --- HERO SECTION (NVIDIA STYLE) --- */}
        <section className="relative min-h-[90vh] flex items-center pt-20 overflow-hidden bg-black border-b border-zinc-800">
          <div className="absolute inset-0 z-0">
            {/* Dark, High-Contrast Background Image */}
            <Image
              src="https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=1920&auto=format&fit=crop"
              alt="Engine parts background"
              fill
              className="object-cover opacity-60 scale-105 animate-pulse-slow"
              priority
            />
            {/* Harsh Gradients for depth */}
            <div className="absolute inset-0 bg-gradient-to-r from-black/90 via-black/50 to-transparent z-10" />
            <div className="absolute inset-0 bg-gradient-to-t from-zinc-950/90 via-transparent to-transparent z-10" />
            
            {/* Technical Grid Overlay */}
            <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-10 z-10 mix-blend-overlay"></div>
            <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.03)_1px,transparent_1px)] bg-[size:4rem_4rem] z-10"></div>
          </div>

          <div className="container relative z-20 mx-auto px-4 md:px-8">
            <div className="max-w-4xl">
              <h1 className="text-6xl md:text-8xl lg:text-9xl font-black tracking-tighter text-white uppercase leading-[0.9] animate-fade-in-up opacity-0" style={{ animationDelay: '0.3s', animationFillMode: 'forwards' }}>
                PERFORMA <br />
                <span className="text-orange-500">TANPA BATAS.</span>
              </h1>

              <p className="mt-8 text-lg md:text-2xl text-zinc-400 max-w-2xl font-medium tracking-wide leading-relaxed animate-fade-in-up opacity-0" style={{ animationDelay: '0.5s', animationFillMode: 'forwards' }}>
                Tingkatkan tenaga dan ketahanan mesin Anda. Suku cadang original dan pelumas racing-grade untuk pengalaman berkendara maksimal.
              </p>

              <div className="mt-12 flex flex-col sm:flex-row gap-4 animate-fade-in-up opacity-0" style={{ animationDelay: '0.7s', animationFillMode: 'forwards' }}>
                <Button asChild size="lg" className="bg-orange-600 hover:bg-orange-500 text-white px-12 py-8 text-xl font-black tracking-widest uppercase rounded-none transition-all border border-orange-500 group relative overflow-hidden">
                  <a href="/katalog">
                    <span className="relative z-10 flex items-center">
                      Jelajahi Katalog
                      <ArrowRight className="ml-3 w-6 h-6 group-hover:translate-x-2 transition-transform" />
                    </span>
                  </a>
                </Button>
                <Button asChild size="lg" variant="outline" className="border-zinc-700 bg-black/50 text-white hover:bg-zinc-800 hover:text-white px-12 py-8 text-xl font-bold tracking-widest uppercase rounded-none backdrop-blur-md transition-all">
                  <a href="#lokasi">Lokasi Bengkel</a>
                </Button>
              </div>
            </div>
          </div>
          
          {/* Decorative Edge Lines */}
          <div className="absolute bottom-0 left-0 w-full h-px bg-gradient-to-r from-orange-500 via-zinc-800 to-transparent z-20"></div>
          <div className="absolute bottom-0 left-0 w-1/3 h-1 bg-orange-600 z-20"></div>
        </section>

        {/* --- STATS BAR --- */}
        <div className="border-b border-zinc-800 bg-zinc-950">
          <div className="container mx-auto">
            <div className="grid grid-cols-2 md:grid-cols-4 divide-x divide-zinc-800">
              <div className="p-8 text-center hover:bg-zinc-900 transition-colors">
                <h4 className="text-4xl lg:text-5xl font-black text-white mb-2 font-mono">1000+</h4>
                <p className="text-zinc-500 text-xs font-bold tracking-[0.2em] uppercase">Pelanggan Puas</p>
              </div>
              <div className="p-8 text-center hover:bg-zinc-900 transition-colors">
                <h4 className="text-4xl lg:text-5xl font-black text-white mb-2 font-mono">500+</h4>
                <p className="text-zinc-500 text-xs font-bold tracking-[0.2em] uppercase">Komponen Tersedia</p>
              </div>
              <div className="p-8 text-center hover:bg-zinc-900 transition-colors">
                <h4 className="text-4xl lg:text-5xl font-black text-white mb-2 font-mono">100%</h4>
                <p className="text-zinc-500 text-xs font-bold tracking-[0.2em] uppercase">Sertifikasi Original</p>
              </div>
              <div className="p-8 text-center hover:bg-zinc-900 transition-colors">
                <h4 className="text-4xl lg:text-5xl font-black text-white mb-2 font-mono">4.9</h4>
                <p className="text-zinc-500 text-xs font-bold tracking-[0.2em] uppercase">Rating Google</p>
              </div>
            </div>
          </div>
        </div>

        {/* --- KEUNGGULAN (HARDWARE SPECS STYLE) --- */}
        <section id="keunggulan" className="py-24 bg-zinc-950 border-b border-zinc-800 relative">
          <div className="container mx-auto px-4">
            <div className="mb-16">
              <div className="flex items-center gap-4 mb-4">
                <div className="w-12 h-px bg-orange-500"></div>
                <h2 className="text-orange-500 font-bold tracking-[0.2em] uppercase text-sm">Arsitektur Layanan</h2>
              </div>
              <h3 className="text-4xl md:text-5xl font-black text-white uppercase tracking-tighter">Standar Spesifikasi Tinggi</h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {[
                {
                  icon: ShieldCheck,
                  title: "RELIABILITY",
                  subtitle: "Mekanik Ahli",
                  desc: "Dikalibrasi oleh tenaga profesional yang mengerti seluk beluk teknis setiap jengkal mesin kendaraan Anda.",
                },
                {
                  icon: Tag,
                  title: "TRANSPARENCY",
                  subtitle: "Harga Jujur",
                  desc: "Sistem penetapan harga kompetitif tanpa biaya tersembunyi. Anda hanya membayar untuk performa yang Anda dapatkan.",
                },
                {
                  icon: Clock,
                  title: "EFFICIENCY",
                  subtitle: "Waktu Presisi",
                  desc: "SLA (Service Level Agreement) yang ketat memastikan kendaraan Anda kembali ke jalanan dalam waktu tersingkat.",
                }
              ].map((item, idx) => (
                <div key={idx} className="bg-zinc-900 border border-zinc-800 p-8 hover:border-orange-500 transition-all duration-300 group relative overflow-hidden">
                  <div className="absolute top-0 right-0 w-24 h-24 bg-zinc-800 rounded-bl-full -mr-12 -mt-12 transition-transform group-hover:bg-orange-600/20"></div>
                  <item.icon className="h-12 w-12 text-zinc-600 group-hover:text-orange-500 transition-colors mb-8" strokeWidth={1.5} />
                  <h4 className="text-xs font-bold text-orange-500 tracking-[0.2em] mb-2">{item.title}</h4>
                  <h3 className="text-2xl font-black text-white uppercase tracking-tight mb-4">{item.subtitle}</h3>
                  <p className="text-zinc-400 leading-relaxed font-medium">{item.desc}</p>
                  
                  {/* Tech decoration */}
                  <div className="absolute bottom-0 left-0 w-full h-1 bg-zinc-800 group-hover:bg-orange-500 transition-colors"></div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* --- LAYANAN (CORE MODULES) --- */}
        <section id="layanan" className="py-24 bg-[#0a0a0b] border-b border-zinc-800 relative">
          <div className="absolute right-0 top-0 w-1/3 h-full bg-[radial-gradient(ellipse_at_right,_var(--tw-gradient-stops))] from-orange-900/20 via-transparent to-transparent pointer-events-none"></div>
          
          <div className="container mx-auto px-4 relative z-10">
            <div className="mb-16 text-right flex flex-col items-end">
              <div className="flex items-center gap-4 mb-4">
                <h2 className="text-orange-500 font-bold tracking-[0.2em] uppercase text-sm">Modul Inti</h2>
                <div className="w-12 h-px bg-orange-500"></div>
              </div>
              <h3 className="text-4xl md:text-5xl font-black text-white uppercase tracking-tighter">Sistem Perawatan</h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-0 border border-zinc-800">
              {/* Service Item 1 */}
              <div className="bg-black p-10 border-b md:border-b-0 md:border-r border-zinc-800 group hover:bg-zinc-900 transition-colors relative">
                <div className="w-16 h-16 bg-zinc-900 flex items-center justify-center mb-8 border border-zinc-800 group-hover:border-orange-500 transition-colors">
                  <Droplets className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-2xl font-black text-white uppercase tracking-tight mb-4">LUBRICANTS</h3>
                <p className="text-zinc-400 mb-8 font-medium">Oli sintetis dan cairan pendingin grade kompetisi untuk menjaga temperatur dan friksi mesin tetap optimal.</p>
                <div className="text-orange-500 font-bold text-xs tracking-widest uppercase flex items-center gap-2 group-hover:gap-4 transition-all cursor-pointer">
                  LIHAT KATALOG <ChevronRight className="w-4 h-4" />
                </div>
              </div>

              {/* Service Item 2 */}
              <div className="bg-black p-10 border-b md:border-b-0 md:border-r border-zinc-800 group hover:bg-zinc-900 transition-colors relative">
                <div className="w-16 h-16 bg-zinc-900 flex items-center justify-center mb-8 border border-zinc-800 group-hover:border-orange-500 transition-colors">
                  <ShoppingCart className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-2xl font-black text-white uppercase tracking-tight mb-4">COMPONENTS</h3>
                <p className="text-zinc-400 mb-8 font-medium">Ribuan SKU suku cadang mekanikal dan elektrikal. 100% Genuine Parts dan Aftermarket terkemuka.</p>
                <div className="text-orange-500 font-bold text-xs tracking-widest uppercase flex items-center gap-2 group-hover:gap-4 transition-all cursor-pointer">
                  CARI SPAREPART <ChevronRight className="w-4 h-4" />
                </div>
              </div>

              {/* Service Item 3 */}
              <div className="bg-black p-10 group hover:bg-zinc-900 transition-colors relative">
                <div className="w-16 h-16 bg-zinc-900 flex items-center justify-center mb-8 border border-zinc-800 group-hover:border-orange-500 transition-colors relative">
                  <Wrench className="h-8 w-8 text-white" />
                  <div className="absolute -top-2 -right-2 bg-orange-600 text-white text-[10px] font-bold px-2 py-0.5 animate-pulse">SOON</div>
                </div>
                <h3 className="text-2xl font-black text-white uppercase tracking-tight mb-4">DIAGNOSTICS</h3>
                <p className="text-zinc-400 mb-8 font-medium">Servis ringan dan overhaul segera hadir dengan prosedur standar pabrikan dan alat diagnosa presisi.</p>
              </div>
            </div>
          </div>
        </section>

        {/* --- PRODUK (FEATURED COMPONENTS) --- */}
        <section id="produk" className="py-24 bg-zinc-950 border-b border-zinc-800">
          <div className="container mx-auto px-4">
            <div className="flex flex-col md:flex-row justify-between items-end mb-12 gap-6">
              <div>
                <div className="flex items-center gap-4 mb-4">
                  <div className="w-12 h-px bg-orange-500"></div>
                  <h2 className="text-orange-500 font-bold tracking-[0.2em] uppercase text-sm">Top Tier Hardware</h2>
                </div>
                <h3 className="text-4xl md:text-5xl font-black text-white uppercase tracking-tighter">Komponen Unggulan</h3>
              </div>
              <Button asChild variant="outline" className="border-zinc-700 bg-transparent text-white hover:bg-white hover:text-black font-bold uppercase tracking-widest rounded-none">
                <Link href="/katalog">
                  Full Database <ArrowRight className="ml-2 w-4 h-4" />
                </Link>
              </Button>
            </div>

            <ProductGrid products={featuredProducts} />
          </div>
        </section>

        {/* --- LOKASI (COORDINATES) --- */}
        <section id="lokasi" className="py-24 bg-black relative overflow-hidden">
          <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] opacity-5 z-0"></div>
          
          <div className="container mx-auto px-4 relative z-10">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-0 border border-zinc-800">
              
              {/* Info Panel */}
              <div className="lg:col-span-5 bg-zinc-950 p-10 md:p-16 border-b lg:border-b-0 lg:border-r border-zinc-800 flex flex-col justify-center">
                <div className="inline-block px-3 py-1 bg-zinc-900 border border-zinc-800 text-zinc-400 font-mono text-xs mb-8">
                  SYS.LOC // 110.2520, -7.5186
                </div>
                <h2 className="text-5xl font-black uppercase tracking-tighter text-white mb-8 leading-none">Pusat <br/><span className="text-orange-500">Operasi</span></h2>
                
                <div className="space-y-8 font-mono text-sm">
                  <div>
                    <div className="text-zinc-500 uppercase tracking-widest mb-2 font-bold">ALAMAT FISIK</div>
                    <p className="text-zinc-300 leading-relaxed uppercase">{SITE_CONFIG.contact.address}</p>
                  </div>
                  
                  <div>
                    <div className="text-zinc-500 uppercase tracking-widest mb-2 font-bold">WAKTU OPERASIONAL</div>
                    <div className="text-zinc-300 uppercase space-y-1">
                      <p>{SITE_CONFIG.contact.hours.weekdays}</p>
                      <p className="text-orange-500">{SITE_CONFIG.contact.hours.sunday}</p>
                    </div>
                  </div>
                  
                  <div>
                    <div className="text-zinc-500 uppercase tracking-widest mb-2 font-bold">TRANSMISI DATA</div>
                    <p className="text-zinc-300 uppercase">{SITE_CONFIG.contact.email}</p>
                    <p className="text-zinc-300 uppercase mt-1">TEL: {SITE_CONFIG.whatsapp.number}</p>
                  </div>
                </div>
              </div>

              {/* Map Panel */}
              <div className="lg:col-span-7 h-[500px] lg:h-auto bg-zinc-900 relative group">
                {/* Tech overlay on map */}
                <div className="absolute inset-0 bg-blue-900/10 mix-blend-color z-10 pointer-events-none group-hover:opacity-0 transition-opacity duration-1000"></div>
                <div className="absolute inset-0 border-[20px] border-black/20 z-10 pointer-events-none"></div>
                
                <iframe
                  src={SITE_CONFIG.contact.mapUrl}
                  width="100%"
                  height="100%"
                  style={{ border: 0 }}
                  allowFullScreen={false}
                  loading="lazy"
                  referrerPolicy="no-referrer-when-downgrade"
                  className="w-full h-full grayscale invert opacity-80 contrast-125 group-hover:grayscale-0 group-hover:invert-0 group-hover:opacity-100 transition-all duration-1000 ease-in-out"
                ></iframe>
                
                <div className="absolute bottom-6 right-6 z-20 bg-black border border-zinc-800 px-4 py-2 text-xs font-mono text-zinc-400">
                  SAT.LINK ESTABLISHED
                </div>
              </div>

            </div>
          </div>
        </section>
      </main>

      {/* --- FOOTER --- */}
      <footer className="bg-black text-zinc-500 py-12 border-t-4 border-orange-600 font-mono text-sm">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row justify-between items-center gap-6">
            <div className="font-black text-2xl text-white tracking-tighter uppercase">
              {SITE_CONFIG.name}
            </div>
            
            <div className="flex flex-wrap justify-center gap-6 md:gap-12 text-xs font-bold tracking-widest uppercase">
              <a href="#layanan" className="hover:text-orange-500 transition-colors">Modul</a>
              <a href="#produk" className="hover:text-orange-500 transition-colors">Hardware</a>
              <a href="#lokasi" className="hover:text-orange-500 transition-colors">Koordinat</a>
              <Link href="/login" className="hover:text-white transition-colors">SYS.ADMIN</Link>
            </div>
          </div>
          
          <div className="mt-12 pt-8 border-t border-zinc-900 flex flex-col md:flex-row justify-between items-center gap-4 text-xs">
            <p>COPYRIGHT © {new Date().getFullYear()} {SITE_CONFIG.name}. ALL RIGHTS RESERVED.</p>
            <p className="text-zinc-700">v1.0.0 // SECANG_MGL</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
