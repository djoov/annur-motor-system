import { PublicNavbar } from "@/components/layout/public-navbar"
import Image from "next/image"
import Link from "next/link"
import { Droplet, Shield, Clock, Wrench, CheckCircle, AlertCircle, Phone, Package } from "lucide-react"
import { Metadata } from "next"
import { db } from "@/lib/firebase"
import { collection, getDocs, query, where, orderBy } from "firebase/firestore"
import { Item } from "@/types"

export const metadata: Metadata = {
    title: 'Ganti Oli & Cairan - Annur Motor Magelang',
    description: 'Layanan ganti oli dan produk oli motor terlengkap di Magelang. Oli mesin, oli gardan, oli transmisi, dan cairan pendingin berkualitas.',
}

// Fetch oil products from database
async function getOilProducts(): Promise<Item[]> {
    try {
        // Query products with category containing 'pelumas' or 'cairan' (case insensitive match)
        const q = query(
            collection(db, "items"),
            orderBy("name")
        )
        const snapshot = await getDocs(q)

        // Filter for pelumas/cairan category (case insensitive)
        const items = snapshot.docs
            .map(doc => ({ id: doc.id, ...doc.data() } as Item))
            .filter(item => {
                const cat = (item.category || '').toLowerCase()
                return cat.includes('pelumas') || cat.includes('cairan') || cat.includes('oli')
            })

        return items
    } catch (error) {
        console.error("Error fetching oil products:", error)
        return []
    }
}

// Tips perawatan
const maintenanceTips = [
    {
        icon: Clock,
        title: "Ganti Tepat Waktu",
        desc: "Ganti oli setiap 2.000-3.000 km atau 1-2 bulan sekali untuk perlindungan optimal."
    },
    {
        icon: Droplet,
        title: "Cek Level Oli",
        desc: "Periksa level oli sebelum berkendara jauh. Oli rendah bisa menyebabkan overheat."
    },
    {
        icon: Shield,
        title: "Gunakan Oli Sesuai",
        desc: "Pilih viskositas oli yang tepat sesuai rekomendasi pabrikan motor Anda."
    },
    {
        icon: Wrench,
        title: "Servis Berkala",
        desc: "Lakukan tune-up rutin untuk memastikan mesin selalu dalam kondisi prima."
    },
]

// Manfaat ganti oli rutin
const benefits = [
    "Mesin lebih awet dan tahan lama",
    "Bahan bakar lebih hemat (irit bensin)",
    "Performa mesin tetap maksimal",
    "Mencegah overheat dan kerusakan",
    "Mengurangi gesekan komponen mesin",
    "Suara mesin lebih halus dan senyap",
]

export default async function OilChangePage() {
    const oilProducts = await getOilProducts()

    return (
        <main className="bg-gradient-to-b from-slate-50 to-white min-h-screen">
            <PublicNavbar />

            {/* Hero Section */}
            <section className="pt-32 pb-16 px-4 relative overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-br from-amber-500/10 via-orange-500/5 to-transparent" />
                <div className="container mx-auto text-center relative z-10">
                    <div className="inline-flex items-center gap-2 px-4 py-2 bg-amber-100 text-amber-700 rounded-full text-sm font-medium mb-6">
                        <Droplet className="w-4 h-4" />
                        Layanan Ganti Oli & Cairan
                    </div>
                    <h1 className="text-4xl md:text-5xl font-black text-slate-800 mb-6 leading-tight">
                        Jaga Mesin Motor Anda<br />
                        <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-500 to-orange-600">Tetap Prima</span>
                    </h1>
                    <p className="text-lg text-slate-600 max-w-2xl mx-auto mb-8">
                        Kami menyediakan berbagai jenis oli motor berkualitas dan layanan ganti oli profesional untuk menjaga performa mesin Anda.
                    </p>
                    <Link
                        href="https://wa.me/6285743907548?text=Halo, saya mau tanya tentang layanan ganti oli"
                        target="_blank"
                        className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-amber-500 to-orange-600 text-white font-bold rounded-full shadow-lg hover:shadow-xl transition-all hover:-translate-y-1"
                    >
                        <Phone className="w-5 h-5" />
                        Hubungi Kami
                    </Link>
                </div>
            </section>

            {/* Pentingnya Ganti Oli */}
            <section className="py-16 px-4 bg-white">
                <div className="container mx-auto">
                    <div className="grid md:grid-cols-2 gap-12 items-center">
                        <div>
                            <div className="inline-flex items-center gap-2 px-3 py-1 bg-red-100 text-red-700 rounded-full text-sm font-medium mb-4">
                                <AlertCircle className="w-4 h-4" />
                                Penting Diketahui
                            </div>
                            <h2 className="text-3xl font-bold text-slate-800 mb-6">
                                Mengapa Ganti Oli Itu Penting?
                            </h2>
                            <p className="text-slate-600 mb-6 leading-relaxed">
                                Oli mesin berfungsi sebagai pelumas yang melindungi komponen mesin dari gesekan dan panas berlebih.
                                Seiring waktu, oli akan terkontaminasi kotoran dan kehilangan efektivitasnya.
                                Ganti oli tepat waktu adalah investasi kecil untuk mencegah kerusakan besar pada mesin.
                            </p>

                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                {benefits.map((benefit, i) => (
                                    <div key={i} className="flex items-center gap-2 text-slate-700">
                                        <CheckCircle className="w-5 h-5 text-green-500 flex-shrink-0" />
                                        <span className="text-sm">{benefit}</span>
                                    </div>
                                ))}
                            </div>
                        </div>

                        <div className="relative h-80 md:h-96 rounded-2xl overflow-hidden shadow-xl">
                            <Image
                                src="https://images.unsplash.com/photo-1487754180451-c456f719a1fc?w=800&h=600&fit=crop"
                                alt="Mekanik ganti oli motor"
                                fill
                                className="object-cover"
                            />
                            <div className="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent" />
                        </div>
                    </div>
                </div>
            </section>

            {/* Produk Oli dari Database */}
            <section className="py-16 px-4 bg-gradient-to-b from-slate-50 to-white">
                <div className="container mx-auto">
                    <div className="text-center mb-12">
                        <h2 className="text-3xl font-bold text-slate-800 mb-4">Produk Oli & Pelumas Kami</h2>
                        <p className="text-slate-600 max-w-xl mx-auto">
                            Tersedia {oilProducts.length} produk pelumas dan cairan untuk semua jenis motor
                        </p>
                    </div>

                    {oilProducts.length === 0 ? (
                        <div className="text-center py-12 text-slate-400">
                            <Droplet className="w-16 h-16 mx-auto mb-4 opacity-20" />
                            <p>Belum ada produk pelumas di database.</p>
                        </div>
                    ) : (
                        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
                            {oilProducts.map((product) => (
                                <div key={product.id} className="bg-white rounded-xl border border-slate-100 shadow-sm hover:shadow-lg transition-all p-4 text-center group">
                                    <div className="relative w-full aspect-square rounded-lg overflow-hidden mb-3 bg-gradient-to-b from-amber-50 to-orange-50">
                                        {product.imageUrl ? (
                                            <Image
                                                src={product.imageUrl}
                                                alt={product.name}
                                                fill
                                                className="object-cover"
                                            />
                                        ) : (
                                            <Package className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-12 h-12 text-amber-400 opacity-50" />
                                        )}
                                    </div>
                                    <h3 className="font-bold text-slate-800 text-sm mb-1 group-hover:text-amber-600 transition-colors line-clamp-2">{product.name}</h3>
                                    {product.code && (
                                        <p className="text-[10px] text-slate-400 font-mono mb-1">{product.code}</p>
                                    )}
                                    <p className="text-sm font-semibold text-amber-600">
                                        Rp {(product.sellPrice || 0).toLocaleString('id-ID')}
                                    </p>
                                </div>
                            ))}
                        </div>
                    )}

                    <p className="text-center mt-8 text-sm text-slate-500">
                        * Harga dapat berubah sewaktu-waktu. Hubungi kami untuk informasi terbaru.
                    </p>
                </div>
            </section>

            {/* Tips Perawatan */}
            <section className="py-16 px-4 bg-white">
                <div className="container mx-auto">
                    <div className="text-center mb-12">
                        <h2 className="text-3xl font-bold text-slate-800 mb-4">Tips Perawatan Mesin</h2>
                        <p className="text-slate-600 max-w-xl mx-auto">
                            Panduan sederhana untuk menjaga motor Anda selalu dalam kondisi prima
                        </p>
                    </div>

                    <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
                        {maintenanceTips.map((tip, i) => (
                            <div key={i} className="bg-gradient-to-b from-slate-50 to-white p-6 rounded-xl border border-slate-100 hover:border-amber-200 transition-all group">
                                <div className="w-12 h-12 bg-amber-100 rounded-xl flex items-center justify-center mb-4 group-hover:bg-amber-500 group-hover:text-white transition-all">
                                    <tip.icon className="w-6 h-6 text-amber-600 group-hover:text-white" />
                                </div>
                                <h3 className="font-bold text-slate-800 mb-2">{tip.title}</h3>
                                <p className="text-sm text-slate-600">{tip.desc}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* CTA Section */}
            <section className="py-16 px-4 bg-gradient-to-r from-amber-500 to-orange-600">
                <div className="container mx-auto text-center">
                    <h2 className="text-3xl font-bold text-white mb-4">Waktunya Ganti Oli?</h2>
                    <p className="text-amber-100 mb-8 max-w-xl mx-auto">
                        Jangan tunggu mesin bermasalah! Kunjungi Annur Motor untuk layanan ganti oli profesional dengan harga terjangkau.
                    </p>
                    <div className="flex flex-col sm:flex-row gap-4 justify-center">
                        <Link
                            href="https://wa.me/6285743907548?text=Halo, saya mau ganti oli, bisa ke lokasi sekarang?"
                            target="_blank"
                            className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-white text-amber-600 font-bold rounded-full shadow-lg hover:shadow-xl transition-all"
                        >
                            <Phone className="w-5 h-5" />
                            Hubungi via WhatsApp
                        </Link>
                        <Link
                            href="/#lokasi"
                            className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-transparent border-2 border-white text-white font-bold rounded-full hover:bg-white/10 transition-all"
                        >
                            Lihat Lokasi Toko
                        </Link>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer className="py-8 px-4 bg-slate-900 text-center">
                <p className="text-slate-400 text-sm">© 2025 Annur Motor. Toko Spare Part Motor Terpercaya di Magelang.</p>
            </footer>
        </main>
    )
}
