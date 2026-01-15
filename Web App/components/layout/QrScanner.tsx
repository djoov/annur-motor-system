"use client"

import { useState, useEffect, useRef } from 'react';
import { Html5Qrcode, Html5QrcodeScannerState } from 'html5-qrcode';
import { db } from '@/lib/firebase';
import { collection, query, where, getDocs, doc, writeBatch, serverTimestamp, increment } from 'firebase/firestore';
import { useAuth } from '@/components/auth-provider';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { XCircle, CameraOff } from 'lucide-react';

// --- [BARU] Interface untuk konfigurasi scanner ---
const QR_SCANNER_CONFIG = {
    fps: 10,
    qrbox: { width: 250, height: 250 },
    rememberLastUsedCamera: true,
    supportedScanTypes: [] // Gunakan default (kamera)
};
const QR_READER_ELEMENT_ID = 'qr-reader';

import type { Item } from "@/types";

interface MovementLog {
    itemId: string;
    itemName: string;
    itemCode: string;
    transactionType: 'masuk_gudang' | 'keluar_gudang' | 'masuk_toko' | 'keluar_toko' | 'retur';
    quantity: number;
    userId: string;
    userName: string;
    timestamp: any;
}

export function QrScanner() {
    const [scanResult, setScanResult] = useState<string | null>(null);
    const [scannedItem, setScannedItem] = useState<Item | null>(null);
    const [isLoading, setIsLoading] = useState(false);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [cameraError, setCameraError] = useState<string | null>(null);
    const [quantity, setQuantity] = useState(1);
    const [transactionType, setTransactionType] = useState<MovementLog['transactionType']>('keluar_toko');
    const { user } = useAuth();
    const { toast } = useToast();
    const html5QrcodeRef = useRef<Html5Qrcode | null>(null);

    // --- [DIPERBAIKI] Logika untuk memulai dan menghentikan scanner ---
    useEffect(() => {
        if (!scanResult && !html5QrcodeRef.current) {
            const scanner = new Html5Qrcode(QR_READER_ELEMENT_ID);
            html5QrcodeRef.current = scanner;

            const startScanner = async () => {
                try {
                    await scanner.start(
                        { facingMode: "environment" }, // Prioritaskan kamera belakang
                        QR_SCANNER_CONFIG,
                        (decodedText) => {
                            setScanResult(decodedText);
                        },
                        (errorMessage) => {
                            // error parsing QR, abaikan
                        }
                    );
                } catch (err: any) {
                    console.error("Gagal memulai scanner:", err);
                    setCameraError("Tidak bisa mengakses kamera. Pastikan Anda memberikan izin dan tidak ada aplikasi lain yang sedang menggunakan kamera.");
                }
            };
            startScanner();
        }

        return () => {
            if (html5QrcodeRef.current && html5QrcodeRef.current.isScanning) {
                html5QrcodeRef.current.stop().catch(err => console.error("Gagal menghentikan scanner:", err));
                html5QrcodeRef.current = null;
            }
        };
    }, [scanResult]);


    useEffect(() => {
        const fetchItemData = async () => {
            if (!scanResult) return;
            setIsLoading(true);
            try {
                const itemsRef = collection(db, "items");
                const q = query(itemsRef, where("code", "==", scanResult));
                const querySnapshot = await getDocs(q);

                if (querySnapshot.empty) {
                    toast({ title: "Barang Tidak Ditemukan", description: `Tidak ada barang dengan kode: ${scanResult}`, variant: "destructive" });
                    setScannedItem(null);
                } else {
                    const itemData = querySnapshot.docs[0].data() as Item;
                    itemData.id = querySnapshot.docs[0].id;
                    setScannedItem(itemData);
                }
            } catch (error) {
                toast({ title: "Error", description: "Gagal mengambil data barang.", variant: "destructive" });
            } finally {
                setIsLoading(false);
            }
        };

        fetchItemData();
    }, [scanResult, toast]);

    const handleTransactionSubmit = async () => {
        if (!scannedItem || !user || quantity <= 0) return;
        setIsSubmitting(true);
        const stockChange = { 'masuk_gudang': quantity, 'keluar_gudang': -quantity, 'masuk_toko': quantity, 'keluar_toko': -quantity, 'retur': quantity }[transactionType];
        if (scannedItem.stock + stockChange < 0) {
            toast({ title: "Stok Tidak Cukup", variant: "destructive" });
            setIsSubmitting(false);
            return;
        }
        try {
            const batch = writeBatch(db);
            const itemRef = doc(db, "items", scannedItem.id);
            batch.update(itemRef, { stock: increment(stockChange) });
            const logRef = doc(collection(db, "itemMovements"));
            batch.set(logRef, { itemId: scannedItem.id, itemName: scannedItem.name, itemCode: scannedItem.code, transactionType, quantity, userId: user.id, userName: user.name, timestamp: serverTimestamp() });
            await batch.commit();
            toast({ title: "Sukses", description: "Pergerakan barang berhasil dicatat." });
            resetState();
        } catch (error) {
            toast({ title: "Error", description: "Gagal menyimpan transaksi.", variant: "destructive" });
        } finally {
            setIsSubmitting(false);
        }
    };

    const resetState = () => {
        setScanResult(null);
        setScannedItem(null);
        setQuantity(1);
        setCameraError(null);
    };

    if (cameraError) {
        return (
            <Card>
                <CardHeader><CardTitle>Error Kamera</CardTitle></CardHeader>
                <CardContent className="text-center">
                    <CameraOff className="mx-auto h-16 w-16 text-destructive mb-4" />
                    <p className="text-destructive">{cameraError}</p>
                    <Button onClick={() => window.location.reload()} className="mt-4">Coba Lagi</Button>
                </CardContent>
            </Card>
        )
    }

    if (!scanResult) {
        return (
            <Card>
                <CardHeader>
                    <CardTitle>Arahkan Kamera ke QR Code</CardTitle>
                </CardHeader>
                <CardContent>
                    <div id={QR_READER_ELEMENT_ID} className="w-full"></div>
                </CardContent>
            </Card>
        );
    }

    if (isLoading) {
        return <p className="text-center">Memvalidasi kode QR...</p>;
    }

    return (
        <Card>
            <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle>Form Transaksi Barang</CardTitle>
                <Button variant="ghost" size="icon" onClick={resetState}>
                    <XCircle className="h-6 w-6" />
                </Button>
            </CardHeader>
            <CardContent className="space-y-4">
                {scannedItem ? (
                    <>
                        <div>
                            <p className="text-sm text-muted-foreground">Nama Barang</p>
                            <p className="text-lg font-bold">{scannedItem.name}</p>
                        </div>
                        <div>
                            <p className="text-sm text-muted-foreground">Stok Saat Ini</p>
                            <p className="font-semibold">{scannedItem.stock} unit</p>
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="transactionType">Jenis Transaksi</Label>
                            <Select value={transactionType} onValueChange={(v) => setTransactionType(v as any)}>
                                <SelectTrigger id="transactionType"><SelectValue /></SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="keluar_toko">Keluar Toko (Penjualan)</SelectItem>
                                    <SelectItem value="masuk_toko">Masuk Toko</SelectItem>
                                    <SelectItem value="keluar_gudang">Keluar Gudang</SelectItem>
                                    <SelectItem value="masuk_gudang">Masuk Gudang (Pembelian)</SelectItem>
                                    <SelectItem value="retur">Retur Barang</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="quantity">Jumlah</Label>
                            <Input id="quantity" type="number" value={quantity} onChange={(e) => setQuantity(Math.max(1, parseInt(e.target.value) || 1))} min="1" />
                        </div>
                        <Button onClick={handleTransactionSubmit} disabled={isSubmitting} className="w-full">
                            {isSubmitting ? "Menyimpan..." : "Submit Transaksi"}
                        </Button>
                    </>
                ) : (
                    <p className="text-center text-red-500">Barang tidak ditemukan. Silakan coba scan ulang.</p>
                )}
            </CardContent>
        </Card>
    );
}
