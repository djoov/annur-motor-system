"use client";

import { useState, useRef, useEffect } from "react";
import { Terminal, Send, Loader2, Zap, AlertCircle } from "lucide-react";

type Message = {
    role: "user" | "model";
    content: string;
};

export function AIAssistant() {
    const [messages, setMessages] = useState<Message[]>([
        { role: "model", content: "SISTEM DIAGNOSTIK PELUMAS ONLINE. SAYA MEKANIK DIGITAL ANDA. APA SPESIFIKASI KENDARAAN ATAU KENDALA YANG ANDA ALAMI?" }
    ]);
    const [input, setInput] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const scrollRef = useRef<HTMLDivElement>(null);

    // Auto scroll to bottom
    useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }
    }, [messages]);

    const handleSend = async () => {
        if (!input.trim()) return;

        const userMsg = { role: "user" as const, content: input.trim() };
        setMessages(prev => [...prev, userMsg]);
        setInput("");
        setIsLoading(true);

        try {
            const res = await fetch("/api/ai-assistant", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ messages: [...messages, userMsg] }),
            });

            const data = await res.json();

            if (res.ok && data.reply) {
                setMessages(prev => [...prev, { role: "model", content: data.reply }]);
            } else {
                throw new Error(data.error || "Gagal menghubungkan ke server AI");
            }
        } catch (error: any) {
            setMessages(prev => [...prev, { 
                role: "model", 
                content: "[ERROR] TRANSMISI TERPUTUS: " + error.message + ". PASTIKAN KUNCI API (GEMINI_API_KEY) TELAH TERPASANG DI SISTEM." 
            }]);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="w-full max-w-4xl mx-auto bg-black border border-zinc-800 shadow-2xl flex flex-col h-[500px]">
            {/* Header Terminal */}
            <div className="flex items-center justify-between px-4 py-3 bg-zinc-950 border-b border-zinc-800">
                <div className="flex items-center gap-3">
                    <Terminal className="w-5 h-5 text-orange-500" />
                    <span className="font-mono text-sm font-bold text-zinc-300 uppercase tracking-widest">
                        Neural Diagnostics // OLI & PELUMAS
                    </span>
                </div>
                <div className="flex items-center gap-2">
                    <span className="relative flex h-3 w-3">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-orange-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-3 w-3 bg-orange-500"></span>
                    </span>
                    <span className="text-[10px] text-orange-500 font-mono tracking-widest uppercase">Active</span>
                </div>
            </div>

            {/* Area Chat */}
            <div 
                ref={scrollRef}
                className="flex-1 overflow-y-auto p-6 space-y-6 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] relative"
            >
                <div className="absolute inset-0 bg-black/80 pointer-events-none"></div>
                
                {messages.map((msg, i) => (
                    <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'} relative z-10`}>
                        <div className={`max-w-[85%] border px-4 py-3 font-mono text-sm uppercase leading-relaxed tracking-wider ${
                            msg.role === 'user' 
                                ? 'bg-zinc-900 border-zinc-700 text-white border-r-4 border-r-orange-500' 
                                : 'bg-black border-zinc-800 text-orange-400 border-l-4 border-l-zinc-700'
                        }`}>
                            {msg.role === 'model' && (
                                <div className="text-[10px] text-zinc-600 mb-2 flex items-center gap-1">
                                    <Zap className="w-3 h-3" /> SYSTEM
                                </div>
                            )}
                            {msg.role === 'user' && (
                                <div className="text-[10px] text-zinc-500 mb-2 text-right">USER // GUEST</div>
                            )}
                            {msg.content}
                        </div>
                    </div>
                ))}
                
                {isLoading && (
                    <div className="flex justify-start relative z-10">
                        <div className="bg-black border border-zinc-800 border-l-4 border-l-zinc-700 px-4 py-3 font-mono text-sm flex items-center gap-3 text-orange-500">
                            <Loader2 className="w-4 h-4 animate-spin" />
                            <span className="animate-pulse">MEMPROSES DATA...</span>
                        </div>
                    </div>
                )}
            </div>

            {/* Input Area */}
            <div className="p-4 bg-zinc-950 border-t border-zinc-800">
                <div className="flex items-center gap-0">
                    <div className="bg-zinc-900 px-4 py-3 h-12 border-y border-l border-zinc-800 flex items-center text-orange-500 font-mono font-bold">
                        {'>'}
                    </div>
                    <input
                        type="text"
                        value={input}
                        onChange={(e) => setInput(e.target.value)}
                        onKeyDown={(e) => e.key === 'Enter' && handleSend()}
                        placeholder="MASUKAN PERINTAH ATAU PERTANYAAN TENTANG OLI..."
                        className="flex-1 bg-black text-white px-4 h-12 border-y border-zinc-800 focus:outline-none focus:border-orange-500 font-mono text-sm uppercase placeholder:text-zinc-700 transition-colors"
                        disabled={isLoading}
                    />
                    <button
                        onClick={handleSend}
                        disabled={isLoading || !input.trim()}
                        className="h-12 px-6 bg-orange-600 hover:bg-orange-500 disabled:bg-zinc-800 disabled:text-zinc-600 text-white font-bold transition-colors flex items-center justify-center border border-transparent disabled:border-zinc-800"
                    >
                        <Send className="w-5 h-5" />
                    </button>
                </div>
                <div className="mt-3 flex items-center gap-2 text-[10px] font-mono text-zinc-600 uppercase tracking-widest">
                    <AlertCircle className="w-3 h-3" />
                    Sistem dibatasi secara ketat hanya merespons topik komponen dan pelumas mesin.
                </div>
            </div>
        </div>
    );
}
