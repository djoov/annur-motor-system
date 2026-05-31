import { Loader2, Zap } from "lucide-react";

export default function Loading() {
    return (
        <div className="fixed inset-0 z-[9999] bg-black flex flex-col items-center justify-center selection:bg-orange-500/30">
            {/* Tech background elements */}
            <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:2rem_2rem] pointer-events-none"></div>
            
            <div className="relative z-10 flex flex-col items-center">
                <div className="w-24 h-24 mb-8 relative flex items-center justify-center">
                    {/* Outer static ring */}
                    <div className="absolute inset-0 border border-zinc-800 rounded-full"></div>
                    {/* Inner spinning loader */}
                    <Loader2 className="w-12 h-12 text-orange-500 animate-spin" />
                    {/* Center point */}
                    <div className="absolute w-2 h-2 bg-orange-500 rounded-full animate-pulse"></div>
                </div>

                <div className="inline-flex items-center gap-2 px-3 py-1 bg-zinc-900 border border-zinc-800 text-orange-500 font-mono text-[10px] mb-4 tracking-widest uppercase">
                    <Zap className="w-3 h-3 animate-pulse" />
                    SYSTEM BOOT SEQUENCE
                </div>
                
                <h2 className="text-xl md:text-2xl font-black text-white uppercase tracking-tighter animate-pulse">
                    MEMUAT DATA...
                </h2>
                
                <div className="mt-6 w-48 h-1 bg-zinc-900 overflow-hidden">
                    <div className="h-full bg-orange-600 w-full origin-left animate-[scale-x_1.5s_ease-in-out_infinite]"></div>
                </div>
                
                <p className="mt-4 text-[10px] font-mono text-zinc-600 uppercase tracking-widest">
                    Menghubungkan ke Database Pusat
                </p>
            </div>
        </div>
    );
}
