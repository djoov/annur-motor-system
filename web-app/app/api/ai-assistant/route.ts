import { NextResponse } from 'next/server';
import { GoogleGenAI } from '@google/genai';

const SYSTEM_INSTRUCTION = `
Anda adalah AI Assistant cerdas milik Annur Motor (Toko Sparepart dan Bengkel Motor).
TUGAS UTAMA ANDA: Memberikan rekomendasi oli, cairan mesin, dan suku cadang motor secara presisi dan profesional.

ATURAN KETAT (CRITICAL RULES):
1. ANDA HANYA BOLEH membahas tentang produk pelumas, suku cadang motor, servis/perawatan kendaraan bermotor, dan hal terkait otomotif.
2. JIKA pengguna bertanya hal di luar otomotif (seperti politik, cuaca, coding, atau topik umum lainnya), ANDA HARUS MENOLAK DENGAN SOPAN dan mengarahkan kembali ke topik perawatan motor.
3. JAWABLAH DENGAN SANGAT SINGKAT, PADAT, DAN JELAS. (Maksimal 3-4 kalimat).
4. Gunakan gaya bahasa profesional, informatif, dan "tech-savvy" layaknya teknisi mesin tingkat tinggi (NVIDIA-style vibe).
5. Jangan berikan harga pasti, minta pengguna menghubungi bengkel untuk harga terbaru.
`;

// This endpoint is public (the /oli page), so cap what one visitor can spend.
const MAX_MESSAGES = 10;          // only the latest turns are sent to Gemini
const MAX_MESSAGE_CHARS = 500;
const RATE_LIMIT = 10;            // requests per IP per window
const RATE_WINDOW_MS = 10 * 60 * 1000;

// Best effort: per server instance, resets on cold start.
const hits = new Map<string, number[]>();

function isRateLimited(ip: string): boolean {
    const now = Date.now();
    const recent = (hits.get(ip) || []).filter(t => now - t < RATE_WINDOW_MS);
    if (recent.length >= RATE_LIMIT) {
        hits.set(ip, recent);
        return true;
    }
    recent.push(now);
    hits.set(ip, recent);
    if (hits.size > 5000) hits.clear();
    return false;
}

export async function POST(req: Request) {
    try {
        const apiKey = process.env.GEMINI_API_KEY;

        if (!apiKey || apiKey === 'ISI_API_KEY_GEMINI_ANDA_DI_SINI') {
            return NextResponse.json({
                error: "GEMINI_API_KEY belum dikonfigurasi di file .env"
            }, { status: 500 });
        }

        const ip = (req.headers.get('x-nf-client-connection-ip')
            || req.headers.get('x-forwarded-for')?.split(',')[0]
            || 'unknown').trim();
        if (isRateLimited(ip)) {
            return NextResponse.json({
                error: "Terlalu banyak pertanyaan. Coba lagi beberapa menit lagi"
            }, { status: 429 });
        }

        const body = await req.json().catch(() => null);
        const messages = body?.messages;

        if (!Array.isArray(messages) || messages.length === 0) {
            return NextResponse.json({ error: "Invalid messages array" }, { status: 400 });
        }

        const recent = messages.slice(-MAX_MESSAGES);
        if (recent.some((msg: any) => typeof msg?.content !== 'string' || msg.content.length > MAX_MESSAGE_CHARS)) {
            return NextResponse.json({
                error: `Pertanyaan terlalu panjang (maksimal ${MAX_MESSAGE_CHARS} karakter)`
            }, { status: 400 });
        }

        const contents = recent.map((msg: any) => ({
            role: msg.role === 'user' ? 'user' : 'model',
            parts: [{ text: msg.content }]
        }));

        const ai = new GoogleGenAI({ apiKey });
        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: contents,
            config: {
                systemInstruction: SYSTEM_INSTRUCTION,
                temperature: 0.2,
                maxOutputTokens: 400,
            }
        });

        const replyText = response.text || "Sistem mengalami gangguan transmisi. Silakan coba lagi.";

        return NextResponse.json({ reply: replyText });

    } catch (error: any) {
        // Details stay in the server log; visitors get a generic message.
        console.error("AI Assistant Error:", error);
        return NextResponse.json({
            error: "Gagal memproses pertanyaan"
        }, { status: 500 });
    }
}
