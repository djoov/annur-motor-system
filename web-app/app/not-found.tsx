import Link from 'next/link';
import { AlertTriangle, Home, RotateCcw } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function NotFound() {
    return (
        <div className="min-h-screen bg-black flex flex-col items-center justify-center selection:bg-orange-500/30 text-zinc-300 font-sans p-4 relative overflow-hidden">
            {/* Tech background elements */}
            <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:4rem_4rem] pointer-events-none z-0"></div>
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-red-900/10 blur-[100px] rounded-full pointer-events-none z-0"></div>

            <div className="relative z-10 max-w-2xl w-full bg-zinc-950 border border-zinc-800 p-8 md:p-12 shadow-2xl text-center">
                {/* Top Accent Line */}
                <div className="absolute top-0 left-0 w-full h-1 bg-red-600"></div>

                <div className="flex justify-center mb-8">
                    <div className="relative">
                        <div className="absolute inset-0 bg-red-500/20 blur-xl rounded-full"></div>
                        <AlertTriangle className="w-24 h-24 text-red-500 relative z-10" />
                    </div>
                </div>

                <div className="inline-flex items-center gap-2 px-3 py-1 bg-zinc-900 border border-zinc-800 text-red-500 font-mono text-[10px] mb-6 tracking-widest uppercase">
                    SYSTEM ERROR 404
                </div>

                <h1 className="text-5xl md:text-7xl font-black text-white uppercase tracking-tighter mb-4 leading-none">
                    DATA <span className="text-red-500">NOT FOUND</span>
                </h1>

                <p className="text-zinc-400 font-mono text-sm uppercase tracking-widest mb-10 border-l-2 border-red-500 pl-4 text-left max-w-md mx-auto bg-black p-4">
                    [FATAL] Modul atau halaman yang Anda minta tidak terdeteksi dalam database sistem saat ini. Berkas mungkin telah dihapus atau tautan rusak.
                </p>

                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                    <Button asChild size="lg" className="bg-red-600 hover:bg-red-700 text-white font-black tracking-widest uppercase h-14 rounded-none transition-colors border border-red-500 flex items-center gap-3">
                        <Link href="/">
                            <Home className="w-5 h-5" />
                            Return to Base
                        </Link>
                    </Button>
                    <Button asChild size="lg" variant="outline" className="bg-transparent hover:bg-zinc-900 border-zinc-800 text-zinc-300 font-bold tracking-widest uppercase h-14 rounded-none transition-colors flex items-center gap-3">
                        <Link href="/katalog">
                            <RotateCcw className="w-5 h-5" />
                            Search Hardware
                        </Link>
                    </Button>
                </div>
            </div>
            
            <div className="absolute bottom-8 font-mono text-[10px] text-zinc-600 uppercase tracking-widest text-center w-full z-10">
                ANNUR MOTOR SECURE SYSTEM v2.0
            </div>
        </div>
    );
}
