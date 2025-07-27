"use client"

import { useState, useEffect } from 'react';
import { Html5QrcodeScanner, QrCodeSuccessCallback } from 'html5-qrcode';
import { db } from '@/lib/firebase';
import { collection, query, where, getDocs, doc, writeBatch, serverTimestamp, increment } from 'firebase/firestore';
import { useAuth } from '@/components/auth-provider';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { XCircle } from 'lucide-react';

interface Item {
    id: string;
    name: string;
    code: string;
    stock: number;
}

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
    const [quantity, setQuantity] = useState(1);
    const [transactionType, setTransactionType] = useState<MovementLog['transactionType']>('keluar_toko');
    const { user } = useAuth();
    const { toast } = useToast();
    const [scanner, setScanner] = useState<Html5QrcodeScanner | null>(null);

    // Effect to initialize the scanner
    useEffect(() => {
        const qrCodeScanner = new Html5QrcodeScanner(
            'qr-reader',
            { fps: 10, qrbox: 250 },
            false
        );
        setScanner(qrCodeScanner);
    }, []);

    // Effect to start scanning when component is ready and not showing a result
    useEffect(() => {
        if (scanner && !scanResult) {
            const onScanSuccess: QrCodeSuccessCallback = (decodedText, decodedResult) => {
                setScanResult(decodedText);
            };
            scanner.render(onScanSuccess, (error) => {
                // handle scan error, usually ignored
            });
        }

        // Cleanup function to clear the scanner
        return () => {
            if (scanner && scanner.getState()) {
                scanner.clear().catch(err => console.error("Failed to clear scanner", err));
            }
        };
    }, [scanner, scanResult]);


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
        if (!scannedItem || !user || quantity <= 0) {
            toast({ title: "Data tidak valid", variant: "destructive" });
            return;
        }
        setIsSubmitting(true);

        const stockChange = {
            'masuk_gudang': quantity,
            'keluar_gudang': -quantity,
            'masuk_toko': quantity,
            'keluar_toko': -quantity,
            'retur': quantity,
        }[transactionType];

        if (scannedItem.stock + stockChange < 0) {
            toast({ title: "Stok Tidak Cukup", description: `Stok saat ini: ${scannedItem.stock}, Anda mencoba mengurangi ${quantity}.`, variant: "destructive"});
            setIsSubmitting(false);
            return;
        }

        try {
            const batch = writeBatch(db);
            const itemRef = doc(db, "items", scannedItem.id);
            batch.update(itemRef, { stock: increment(stockChange) });
            const logRef = doc(collection(db, "itemMovements"));
            const logData: MovementLog = {
                itemId: scannedItem.id,
                itemName: scannedItem.name,
                itemCode: scannedItem.code,
                transactionType: transactionType,
                quantity: quantity,
                userId: user.id,
                userName: user.name,
                timestamp: serverTimestamp()
            };
            batch.set(logRef, logData);
            await batch.commit();
            toast({ title: "Sukses", description: "Pergerakan barang berhasil dicatat." });
            resetState();
        } catch (error) {
            console.error("Gagal menyimpan transaksi:", error);
            toast({ title: "Error", description: "Gagal menyimpan transaksi.", variant: "destructive" });
        } finally {
            setIsSubmitting(false);
        }
    };
    
    const resetState = () => {
        setScanResult(null);
        setScannedItem(null);
        setQuantity(1);
    };

    if (!scanResult) {
        return (
            <Card>
                <CardHeader>
                    <CardTitle>Scan QR Code Barang</CardTitle>
                </CardHeader>
                <CardContent>
                    <div id="qr-reader" className="w-full"></div>
                </CardContent>
            </Card>
        );
    }

    if (isLoading) {
        return <p>Mencari data barang...</p>;
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
                            <p className="text-sm text-muted-foreground">Kode Barang</p>
                            <p className="font-semibold">{scannedItem.code}</p>
                        </div>
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
                                <SelectTrigger id="transactionType">
                                    <SelectValue />
                                </SelectTrigger>
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
                            <Input
                                id="quantity"
                                type="number"
                                value={quantity}
                                onChange={(e) => setQuantity(Math.max(1, parseInt(e.target.value) || 1))}
                                min="1"
                            />
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
