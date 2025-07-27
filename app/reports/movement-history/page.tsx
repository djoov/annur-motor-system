"use client"

import { useState, useEffect } from "react";
import { MainLayout } from "@/components/layout/main-layout";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { collection, getDocs, query, orderBy, Timestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { History } from "lucide-react";

interface Movement {
    id: string;
    itemName: string;
    itemCode: string;
    quantity: number;
    transactionType: string;
    userName: string;
    timestamp: Timestamp;
}

export default function MovementHistoryPage() {
    const [movements, setMovements] = useState<Movement[]>([]);
    const [filteredMovements, setFilteredMovements] = useState<Movement[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');
    const [productSearch, setProductSearch] = useState('');

    useEffect(() => {
        const fetchMovements = async () => {
            setIsLoading(true);
            const q = query(collection(db, "itemMovements"), orderBy("timestamp", "desc"));
            const snapshot = await getDocs(q);
            const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Movement));
            setMovements(data);
            setFilteredMovements(data);
            setIsLoading(false);
        };
        fetchMovements();
    }, []);

    useEffect(() => {
        let result = movements;

        if (startDate) {
            const start = new Date(startDate);
            result = result.filter(m => m.timestamp && m.timestamp.toDate() >= start);
        }
        if (endDate) {
            const end = new Date(endDate);
            end.setHours(23, 59, 59, 999);
            result = result.filter(m => m.timestamp && m.timestamp.toDate() <= end);
        }
        if (productSearch) {
            const term = productSearch.toLowerCase();
            result = result.filter(m => 
                (m.itemName || '').toLowerCase().includes(term) || 
                (m.itemCode || '').toLowerCase().includes(term)
            );
        }

        setFilteredMovements(result);
    }, [startDate, endDate, productSearch, movements]);

    // --- [DIPERBAIKI] Tambahkan pengecekan untuk menghindari eror ---
    const formatTransactionType = (type: string) => {
        if (typeof type !== 'string' || !type) {
            return 'N/A'; // Tampilkan N/A jika tipe tidak valid
        }
        return type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
    };

    return (
        <MainLayout>
            <div className="space-y-6">
                <Card>
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2"><History /> Riwayat Pergerakan Barang</CardTitle>
                        <CardDescription>Mencatat semua aktivitas stok barang.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                            <div>
                                <Label htmlFor="productSearch">Cari Barang</Label>
                                <Input id="productSearch" placeholder="Nama atau kode..." value={productSearch} onChange={e => setProductSearch(e.target.value)} />
                            </div>
                            <div>
                                <Label htmlFor="startDate">Dari Tanggal</Label>
                                <Input id="startDate" type="date" value={startDate} onChange={e => setStartDate(e.target.value)} />
                            </div>
                            <div>
                                <Label htmlFor="endDate">Sampai Tanggal</Label>
                                <Input id="endDate" type="date" value={endDate} onChange={e => setEndDate(e.target.value)} />
                            </div>
                        </div>

                        <div className="overflow-x-auto">
                            <table className="w-full text-sm">
                                <thead>
                                    <tr className="border-b">
                                        <th className="text-left p-2">Waktu</th>
                                        <th className="text-left p-2">Barang</th>
                                        <th className="text-left p-2">Tipe Transaksi</th>
                                        <th className="text-center p-2">Jumlah</th>
                                        <th className="text-left p-2">Oleh</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {isLoading ? (
                                        <tr><td colSpan={5} className="text-center p-4">Memuat data...</td></tr>
                                    ) : filteredMovements.map(m => (
                                        <tr key={m.id} className="border-b hover:bg-gray-50">
                                            <td className="p-2">{m.timestamp ? m.timestamp.toDate().toLocaleString('id-ID') : 'N/A'}</td>
                                            <td className="p-2">
                                                <div className="font-medium">{m.itemName || 'N/A'}</div>
                                                <div className="text-xs text-muted-foreground">{m.itemCode || 'N/A'}</div>
                                            </td>
                                            <td className="p-2">{formatTransactionType(m.transactionType)}</td>
                                            <td className="p-2 text-center font-bold">{m.quantity}</td>
                                            <td className="p-2">{m.userName}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                             {!isLoading && filteredMovements.length === 0 && (
                                <div className="text-center py-8 text-gray-500">
                                    Tidak ada data pergerakan barang yang cocok.
                                </div>
                             )}
                        </div>
                    </CardContent>
                </Card>
            </div>
        </MainLayout>
    );
}
