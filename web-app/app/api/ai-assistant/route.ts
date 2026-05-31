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

export async function POST(req: Request) {
    try {
        const apiKey = process.env.GEMINI_API_KEY;

        if (!apiKey || apiKey === 'ISI_API_KEY_GEMINI_ANDA_DI_SINI') {
            return NextResponse.json({ 
                error: "GEMINI_API_KEY belum dikonfigurasi di file .env" 
            }, { status: 500 });
        }

        const ai = new GoogleGenAI({ apiKey });

        const body = await req.json();
        const { messages } = body;

        if (!messages || !Array.isArray(messages)) {
            return NextResponse.json({ error: "Invalid messages array" }, { status: 400 });
        }

        const contents = messages.map((msg: any) => ({
            role: msg.role === 'user' ? 'user' : 'model',
            parts: [{ text: msg.content }]
        }));

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
        console.error("AI Assistant Error:", error);
        return NextResponse.json({ 
            error: "Gagal memproses: " + (error.message || "Unknown error")
        }, { status: 500 });
    }
}

