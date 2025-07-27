"use client"

import { MainLayout } from "@/components/layout/main-layout";
import dynamic from 'next/dynamic';

// --- [DIPERBAIKI] Gunakan dynamic import untuk komponen QrScanner ---
const QrScannerWithNoSSR = dynamic(
  () => import('@/components/layout/QrScanner').then(mod => mod.QrScanner),
  { 
    ssr: false,
    loading: () => <p className="text-center">Memuat pemindai QR...</p> 
  }
);

export default function ScanPage() {
    return (
        <MainLayout>
            <div className="max-w-md mx-auto">
                <QrScannerWithNoSSR />
            </div>
        </MainLayout>
    )
}
