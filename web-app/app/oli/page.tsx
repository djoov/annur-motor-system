import { PublicNavbar } from "@/components/layout/public-navbar"
import Image from "next/image"
import Link from "next/link"
import { Droplet, Shield, Clock, Wrench, CheckCircle, AlertCircle, Phone, Package, Zap } from "lucide-react"
import { Metadata } from "next"
import { db } from "@/lib/firebase"
import { collection, getDocs, query, orderBy } from "firebase/firestore"
import { Item } from "@/types"
import { AIAssistant } from "@/components/ai-assistant"

export const metadata: Metadata = {
    title: 'Ganti Oli & Cairan - Annur Motor Magelang',
    description: 'Sistem pelumas dan cairan mesin berkualitas tinggi.',
}

async function getOilProducts(): Promise<Item[]> {
    try {
        const q = query(collection(db, "items"), orderBy("name"))
        const snapshot = await getDocs(q)

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

const maintenanceTips = [
    {
        icon: Clock,
        title: "TIMING PRESISI",
        desc: "Siklus penggantian setiap 2.000 KM memastikan viskositas tetap pada level struktural."
    },
    {
        icon: Droplet,
        title: "LEVEL MONITORING",
        desc: "Inspeksi volume pelumas berkala mencegah kegagalan fatal akibat overheat."
    },
    {
        icon: Shield,
        title: "SPESIFIKASI OEM",
        desc: "Penerapan grade pelumas yang sesuai blueprint pabrikan asli."
    },
    {
        icon: Wrench,
        title: "TUNE-UP RUTIN",
        desc: "Kalibrasi menyeluruh untuk mempertahankan Output Horsepower maksimal."
    },
]

export default async function OilChangePage() {
    const oilProducts = await getOilProducts()

    return (
        <main className="bg-zinc-950 min-h-screen text-zinc-300 font-sans selection:bg-orange-500/30 selection:text-white">
            <PublicNavbar />

            {/* --- HERO SECTION --- */}
            <section className="relative min-h-[85vh] flex items-center pt-24 pb-16 px-4 bg-black border-b border-zinc-800 overflow-hidden">
                <div className="absolute inset-0 z-0">
                    <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.03)_1px,transparent_1px)] bg-[size:4rem_4rem]"></div>
                    <div className="absolute top-0 right-0 w-[800px] h-full bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-orange-900/20 via-transparent to-transparent pointer-events-none"></div>
                </div>

                <div className="container mx-auto relative z-10 flex flex-col lg:flex-row items-center gap-16">
                    <div className="flex-1">
                        <div className="inline-flex items-center gap-2 px-3 py-1 bg-zinc-900 border border-zinc-800 text-orange-500 font-mono text-xs mb-8 tracking-widest uppercase">
                            <Droplet className="w-4 h-4 fill-orange-500" />
                            Modul Lubrikasi Aktif
                        </div>
                        <h1 className="text-5xl md:text-7xl lg:text-8xl font-black text-white mb-6 uppercase tracking-tighter leading-[0.9]">
                            LUBRICANT <br/>
                            <span className="text-orange-500">SYSTEMS</span>
                        </h1>
                        <p className="text-lg text-zinc-400 max-w-xl mb-12 font-medium tracking-wide">
                            Formula pelumas high-grade untuk meminimalisir friksi, meredam panas termal, dan mengekstraksi tenaga murni mesin Anda.
                        </p>
                        <div className="flex flex-col sm:flex-row gap-4">
                            <Link
                                href="https://wa.me/6281287562914?text=Halo, saya mau ganti oli..."
                                target="_blank"
                                className="inline-flex items-center justify-center gap-3 px-10 py-6 bg-orange-600 hover:bg-orange-500 text-white font-black uppercase tracking-widest rounded-none border border-orange-500 transition-colors"
                            >
                                <Phone className="w-5 h-5" />
                                RESERVASI SERVIS
                            </Link>
                        </div>
                    </div>

                    {/* AI ASSISTANT INJECTED IN HERO */}
                    <div className="flex-1 w-full lg:max-w-xl">
                        <AIAssistant />
                    </div>
                </div>
            </section>

            {/* --- SYSTEM REQUIREMENT (Pentingnya Oli) --- */}
            <section className="py-24 px-4 bg-zinc-950 border-b border-zinc-800">
                <div className="container mx-auto">
                    <div className="grid md:grid-cols-2 gap-16 items-center">
                        <div className="order-2 md:order-1 relative h-96 rounded-none overflow-hidden border border-zinc-800 group">
                            <Image
                                src="https://images.unsplash.com/photo-1487754180451-c456f719a1fc?w=800&h=600&fit=crop"
                                alt="Mekanik ganti oli motor"
                                fill
                                className="object-cover filter grayscale contrast-125 group-hover:grayscale-0 transition-all duration-700"
                            />
                            <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-20 mix-blend-overlay"></div>
                            <div className="absolute inset-0 border-[10px] border-black/40"></div>
                            <div className="absolute bottom-4 left-4 bg-black border border-zinc-800 px-3 py-1 font-mono text-[10px] text-zinc-500">IMG // MAINTENANCE_BAY_01</div>
                        </div>

                        <div className="order-1 md:order-2">
                            <div className="flex items-center gap-4 mb-4">
                                <div className="w-12 h-px bg-orange-500"></div>
                                <h2 className="text-orange-500 font-bold tracking-[0.2em] uppercase text-sm">CRITICAL MAINTENANCE</h2>
                            </div>
                            <h3 className="text-4xl md:text-5xl font-black text-white uppercase tracking-tighter mb-8">
                                Mengapa Pelumasan Itu Vital?
                            </h3>
                            <p className="text-zinc-400 mb-8 leading-relaxed font-medium">
                                Oli mesin bertindak sebagai sistem perlindungan utama dari friksi mekanis dan fluktuasi panas ekstrem. Kegagalan sistem pelumasan dapat mengakibatkan keausan fatal pada komponen internal.
                            </p>

                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                {[
                                    "Masa pakai komponen meningkat",
                                    "Efisiensi termal lebih baik",
                                    "Output tenaga maksimal",
                                    "Mencegah overheat blok silinder",
                                    "Reduksi friksi mekanikal",
                                    "Peredaman suara operasional",
                                ].map((benefit, i) => (
                                    <div key={i} className="flex items-start gap-3 text-zinc-300">
                                        <Zap className="w-5 h-5 text-orange-500 flex-shrink-0 mt-0.5" />
                                        <span className="text-sm font-bold uppercase tracking-wider">{benefit}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* --- DATABASE OLI --- */}
            <section className="py-24 px-4 bg-black border-b border-zinc-800">
                <div className="container mx-auto">
                    <div className="mb-12">
                        <div className="flex items-center gap-4 mb-4">
                            <div className="w-12 h-px bg-orange-500"></div>
                            <h2 className="text-orange-500 font-bold tracking-[0.2em] uppercase text-sm">DATABASE INVENTORY</h2>
                        </div>
                        <h3 className="text-4xl md:text-5xl font-black text-white uppercase tracking-tighter">Liquid Hardware</h3>
                        <p className="text-zinc-400 mt-4 max-w-xl font-medium">
                            {oilProducts.length} SKU terdeteksi dalam sub-kategori pelumas dan cairan pendingin.
                        </p>
                    </div>

                    {oilProducts.length === 0 ? (
                        <div className="text-center py-20 bg-zinc-950 border border-zinc-800">
                            <AlertCircle className="w-12 h-12 text-zinc-600 mx-auto mb-4" />
                            <h3 className="font-black text-white uppercase tracking-widest">DATA TIDAK DITEMUKAN</h3>
                        </div>
                    ) : (
                        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
                            {oilProducts.map((product) => (
                                <div key={product.id} className="bg-zinc-950 border border-zinc-800 hover:border-orange-500 transition-all p-5 text-center group cursor-pointer relative overflow-hidden">
                                    <div className="absolute top-0 left-0 w-full h-1 bg-zinc-800 group-hover:bg-orange-500 transition-colors z-20"></div>
                                    <div className="relative w-full aspect-square bg-black border border-zinc-900 mb-4 flex items-center justify-center p-4">
                                        {product.imageUrl ? (
                                            <Image
                                                src={product.imageUrl}
                                                alt={product.name}
                                                fill
                                                className="object-contain p-4 filter brightness-75 group-hover:brightness-110 transition-all"
                                            />
                                        ) : (
                                            <Package className="w-12 h-12 text-zinc-800" />
                                        )}
                                    </div>
                                    <h3 className="font-black text-white text-sm mb-2 uppercase tracking-tight line-clamp-2 leading-tight group-hover:text-orange-500 transition-colors">
                                        {product.name}
                                    </h3>
                                    {product.code && (
                                        <p className="text-[10px] text-zinc-500 font-mono border border-zinc-800 inline-block px-2 py-0.5 mt-2 bg-black">{product.code}</p>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </section>

            {/* --- PROTOKOL PERAWATAN --- */}
            <section className="py-24 px-4 bg-zinc-950 border-b border-orange-600">
                <div className="container mx-auto">
                    <div className="text-center mb-16">
                        <h2 className="text-orange-500 font-bold tracking-[0.2em] uppercase text-sm mb-4">STANDARD OPERATING PROCEDURE</h2>
                        <h3 className="text-4xl md:text-5xl font-black text-white uppercase tracking-tighter">Protokol Perawatan</h3>
                    </div>

                    <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-0 border border-zinc-800">
                        {maintenanceTips.map((tip, i) => (
                            <div key={i} className="bg-black p-8 border-b lg:border-b-0 lg:border-r border-zinc-800 hover:bg-zinc-900 transition-colors group relative">
                                <div className="absolute top-0 right-0 w-16 h-16 bg-zinc-900 rounded-bl-full -mr-8 -mt-8 transition-transform group-hover:bg-orange-600/20"></div>
                                <div className="w-12 h-12 bg-zinc-900 border border-zinc-800 flex items-center justify-center mb-6 group-hover:border-orange-500 transition-colors">
                                    <tip.icon className="w-6 h-6 text-zinc-500 group-hover:text-orange-500" />
                                </div>
                                <h3 className="font-black text-white mb-4 uppercase tracking-tighter text-xl">{tip.title}</h3>
                                <p className="text-sm text-zinc-400 font-medium leading-relaxed">{tip.desc}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>
        </main>
    )
}
