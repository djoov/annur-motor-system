import { PublicNavbar } from "@/components/layout/public-navbar";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { db } from "@/lib/firebase";
import { collection, getDocs, query, where } from "firebase/firestore";
import { Wrench, Droplets, ShoppingCart, MapPin, Phone, Mail, ShieldCheck, Tag, Clock } from "lucide-react";
import Image from "next/image";
import ImageCarousel from "@/components/layout/ImageCarousel";
import type { Metadata } from 'next'
import LocationTracker from "@/components/layout/LocationTracker";

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

interface Item {
  id: string;
  name: string;
  description: string;
  sellPrice: number;
  imageUrl?: string;
}

// --- Komponen Tombol WhatsApp Mengambang ---
const WhatsAppButton = () => (
    <a 
        href="https://wa.me/6288983773114?text=Halo%20Annur%20Motor,%20saya%20ingin%20bertanya..."
        target="_blank"
        rel="noopener noreferrer"
        className="fixed bottom-6 right-6 z-50 bg-green-500 text-white p-4 rounded-full shadow-lg hover:bg-green-600 transition-transform hover:scale-110"
        aria-label="Hubungi via WhatsApp"
    >
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path></svg>
    </a>
);

// --- Fungsi untuk menyediakan gambar stok dari internet ---
function getStockImageUrl(productName: string): string {
    const name = productName.toLowerCase();
    if (name.includes('oli')) return "https://images.unsplash.com/photo-1627866502353-6113c8542a8c?q=80&w=800";
    if (name.includes('ban')) return "https://images.unsplash.com/photo-1617008394248-a765dd79462b?q=80&w=800";
    if (name.includes('aki')) return "https://images.unsplash.com/photo-1588287314523-2334485b63bc?q=80&w=800";
    if (name.includes('kampas')) return "https://images.unsplash.com/photo-1620892379929-4786d52a2f26?q=80&w=800";
    if (name.includes('busi')) return "https://images.unsplash.com/photo-1617153200151-a5836d502158?q=80&w=800";
    return `https://placehold.co/400x400/e2e8f0/64748b?text=${encodeURIComponent(productName)}`;
}

// Fungsi untuk memotong teks dengan aman
function truncateText(text: string, maxLength: number = 100): string {
  if (text.length <= maxLength) return text;
  const truncated = text.substring(0, maxLength);
  const lastSpace = truncated.lastIndexOf(' ');
  return truncated.substring(0, lastSpace > 0 ? lastSpace : maxLength) + '...';
}

// --- Fungsi Server-Side untuk mengambil produk secara acak ---
async function getFeaturedProducts(): Promise<Item[]> {
  try {
    const itemsRef = collection(db, "items");
    const q = query(itemsRef, where("stock", ">", 0));
    const querySnapshot = await getDocs(q);
    const allProducts = querySnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as Item));
    for (let i = allProducts.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [allProducts[i], allProducts[j]] = [allProducts[j], allProducts[i]];
    }
    return allProducts.slice(0, 4);
  } catch (error) {
    console.error("Error fetching featured products:", error);
    return [];
  }
}

export default async function HomePage() {
  const featuredProducts = await getFeaturedProducts();

  return (
    <div className="bg-gray-50 text-gray-800">
      <PublicNavbar />
      <WhatsAppButton />
      <LocationTracker />

      <main>
        <section className="relative h-[80vh] flex items-center justify-center text-center text-white bg-gray-900 overflow-hidden">
          <ImageCarousel />
          <div className="absolute inset-0 bg-black opacity-50 z-10"></div>
          <div className="relative z-20 p-4">
            <h1 className="text-4xl md:text-6xl font-extrabold tracking-tight animate-fade-in-down">Solusi Lengkap untuk Motor Anda</h1>
            <p className="mt-4 text-lg md:text-xl max-w-2xl mx-auto animate-fade-in-up">Menyediakan spare part Sepeda Motor, Sepeda Onthel, dan Pelumas Kendaraan, Annur Motor siap melayani.</p>
            <Button asChild size="lg" className="mt-8 bg-blue-600 hover:bg-blue-700 animate-fade-in-up">
              <a href="#lokasi">Kunjungi Kami</a>
            </Button>
          </div>
        </section>

        {/* "Mengapa Memilih Kami?" Section */}
        <section id="keunggulan" className="py-20 bg-white">
            <div className="container mx-auto px-4 text-center">
                <h2 className="text-3xl font-bold">Mengapa Memilih Annur Motor?</h2>
                <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-8">
                    <div className="p-6">
                        <ShieldCheck className="h-12 w-12 mx-auto text-blue-600" />
                        <h3 className="mt-4 text-xl font-semibold">Terpercaya & Berpengalaman</h3>
                        <p className="mt-2 text-gray-600">Mekanik kami memiliki pengalaman dalam menyediakan sparepart motor dan sepeda.</p>
                    </div>
                    <div className="p-6">
                        <Tag className="h-12 w-12 mx-auto text-blue-600" />
                        <h3 className="mt-4 text-xl font-semibold">Harga Jujur & Transparan</h3>
                        <p className="mt-2 text-gray-600">Tidak ada biaya tersembunyi. Kami selalu memberikan estimasi harga di awal.</p>
                    </div>
                    <div className="p-6">
                        <Clock className="h-12 w-12 mx-auto text-blue-600" />
                        <h3 className="mt-4 text-xl font-semibold">Pengerjaan Cepat & Efisien</h3>
                        <p className="mt-2 text-gray-600">Kami menghargai waktu Anda dengan memberikan pelayanan yang cepat dan tepat.</p>
                    </div>
                </div>
            </div>
        </section>

        {/* Layanan Section */}
        <section id="layanan" className="py-20 bg-gray-50">
          <div className="container mx-auto px-4 text-center">
            <h2 className="text-3xl font-bold">Layanan Kami</h2>
            <p className="mt-2 text-gray-600">Kami menyediakan sparepart terbaik untuk menjaga performa motor Anda.</p>
            <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="p-6">
                <Wrench className="h-12 w-12 mx-auto text-blue-600" />
                <h3 className="mt-4 text-xl font-semibold">Servis Profesional - Soon!</h3>
                <p className="mt-2 text-gray-600">Ditangani oleh mekanik berpengalaman untuk servis ringan hingga turun mesin.</p>
              </div>
              <div className="p-6">
                <Droplets className="h-12 w-12 mx-auto text-blue-600" />
                <h3 className="mt-4 text-xl font-semibold">Ganti Oli & Cairan</h3>
                <p className="mt-2 text-gray-600">Pilihan oli dan pelumas berkualitas untuk menjaga keawetan mesin motor Anda.</p>
              </div>
              <div className="p-6">
                <ShoppingCart className="h-12 w-12 mx-auto text-blue-600" />
                <h3 className="mt-4 text-xl font-semibold">Spare Part Lengkap</h3>
                <p className="mt-2 text-gray-600">Menyediakan suku cadang original dan aftermarket terpercaya.</p>
              </div>
            </div>
          </div>
        </section>

        {/* --- SOLUSI SEDERHANA: Produk Unggulan dengan Tooltip/Hover --- */}
        <section id="produk" className="py-20 bg-white">
          <div className="container mx-auto px-4 text-center">
            <h2 className="text-3xl font-bold">Produk Unggulan</h2>
            <p className="mt-2 text-gray-600">Beberapa produk terlaris yang tersedia di toko kami. Hover pada produk untuk melihat deskripsi lengkap.</p>
            <div className="mt-12 grid grid-cols-2 md:grid-cols-4 gap-6">
              {featuredProducts.map((product) => (
                <div key={product.id} className="group relative">
                  <Card className="flex flex-col text-center shadow-lg hover:shadow-2xl transition-all duration-300 rounded-lg overflow-hidden h-full">
                    <div className="relative bg-gray-100 flex-grow flex items-center justify-center aspect-square overflow-hidden">
                        <Image 
                            src={product.imageUrl || getStockImageUrl(product.name)} 
                            alt={product.name} 
                            width={300}
                            height={300}
                            className="object-contain p-4 group-hover:scale-110 transition-transform duration-300"
                        />
                    </div>
                    <CardContent className="p-4 bg-white flex-grow flex flex-col justify-between">
                      <div>
                        <h3 className="font-semibold truncate mb-2">{product.name}</h3>
                        <p className="text-gray-500 text-sm leading-relaxed mb-3 min-h-[2.5rem]">
                          {truncateText(product.description || "Deskripsi produk tidak tersedia.", 80)}
                        </p>
                      </div>
                      
                      <a 
                        href={`https://wa.me/6288983773114?text=${encodeURIComponent(`Halo Annur Motor, saya tertarik dengan produk: ${product.name}. Bisakah saya mendapatkan informasi lebih lanjut?`)}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="mt-auto inline-flex items-center justify-center px-4 py-2 text-sm font-medium text-white bg-green-500 hover:bg-green-600 rounded-md transition-colors duration-200"
                      >
                        Tanya via WhatsApp
                      </a>
                    </CardContent>
                  </Card>
                  
                  {/* Tooltip untuk deskripsi lengkap */}
                  <div className="absolute top-0 left-0 right-0 bg-black bg-opacity-90 text-white p-4 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300 z-10 max-h-40 overflow-y-auto">
                    <h4 className="font-semibold mb-2">{product.name}</h4>
                    <p className="text-sm leading-relaxed">
                      {product.description || "Deskripsi produk tidak tersedia."}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Lokasi Section */}
        <section id="lokasi" className="py-20 bg-gray-50">
          <div className="container mx-auto px-4">
            <div className="text-center">
              <h2 className="text-3xl font-bold">Temukan Kami</h2>
              <p className="mt-2 text-gray-600">Kunjungi Toko kami atau hubungi kami untuk informasi lebih lanjut.</p>
            </div>
            <div className="mt-12 grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
              <div>
                <div className="aspect-w-16 aspect-h-9 rounded-lg overflow-hidden shadow-lg">
                  <iframe
                    src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2157.251982231738!2d110.2545485834527!3d-7.4189610409443345!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x2e7a8693aee2065f%3A0xfb90c5a96cf4c97a!2sToko%20Sparepart%20-%20Annur%20Motor!5e0!3m2!1sen!2sid!4v1753231579874!5m2!1sen!2sid"
                    width="100%"
                    height="450"
                    style={{ border: 0 }}
                    allowFullScreen={false}
                    loading="lazy"
                    referrerPolicy="no-referrer-when-downgrade"
                  ></iframe>
                </div>
              </div>
              <div className="space-y-6">
                <div className="flex items-start gap-4">
                  <MapPin className="h-6 w-6 text-blue-600 mt-1" />
                  <div>
                    <h3 className="font-semibold">Alamat</h3>
                    <p>Jl. Raya Pucang No. 12, Karang Wetan, Pucang, Secang, Kabupaten Magelang, Jawa Tengah</p>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <Mail className="h-6 w-6 text-blue-600 mt-1" />
                  <div>
                    <h3 className="font-semibold">Alamat Email</h3>
                    <a href="mailto:annurmotorpucang@gmail.com" className="text-blue-600 hover:underline">
                      annurmotorpucang@gmail.com
                    </a>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <Wrench className="h-6 w-6 text-blue-600 mt-1" />
                  <div>
                    <h3 className="font-semibold">Jam Buka</h3>
                    <p>Senin - Sabtu: 07:30 - 17:00</p>
                    <p>Minggu: 08:00 - 17:00</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="bg-gray-800 text-white py-8">
        <div className="container mx-auto px-4 text-center">
          <p>&copy; {new Date().getFullYear()} Annur Motor. All Rights Reserved.</p>
        </div>
      </footer>
    </div>
  );
}