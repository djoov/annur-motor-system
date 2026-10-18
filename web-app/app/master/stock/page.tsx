"use client"

import React, { useState, useEffect, useMemo } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Search, Package, AlertTriangle, CheckCircle, XCircle, Edit, ArrowRightLeft, History, RefreshCw } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, onSnapshot, doc, runTransaction, serverTimestamp } from "firebase/firestore"
import { itemStock } from "@/lib/shop-data"
import { useAuth } from "@/components/auth-provider"
import { useToast } from "@/hooks/use-toast"

// --- Interfaces ---
interface StockItem {
    id: string
    code: string
    name: string
    category: string
    stock: number
    minStock: number
    buyPrice: number
}

// --- Helper Function ---
const getStockStatus = (stock: number, minStock: number) => {
    stock = stock || 0;
    minStock = minStock || 0;
    if (stock <= 0) return { status: "empty", text: "Habis", icon: XCircle, color: "text-red-600", bg: "bg-red-50", border: "border-red-200" }
    if (stock <= minStock) return { status: "low", text: "Menipis", icon: AlertTriangle, color: "text-amber-600", bg: "bg-amber-50", border: "border-amber-200" }
    return { status: "safe", text: "Aman", icon: CheckCircle, color: "text-emerald-600", bg: "bg-emerald-50", border: "border-emerald-200" }
}

export default function StockPage() {
    const [stockItems, setStockItems] = useState<StockItem[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState("");
    const [filterStatus, setFilterStatus] = useState<string>("all");

    // Adjustment State
    const [isAdjustDialogOpen, setIsAdjustDialogOpen] = useState(false);
    const [selectedItem, setSelectedItem] = useState<StockItem | null>(null);
    const [adjustment, setAdjustment] = useState({ type: 'add', quantity: 1, reason: 'stock_opname' });
    const [isSaving, setIsSaving] = useState(false);

    const { user } = useAuth();
    const { toast } = useToast();

    // Real-time Data Fetching
    useEffect(() => {
        setIsLoading(true);
        const unsubscribe = onSnapshot(collection(db, "items"), (snapshot) => {
            const itemsList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data(), stock: itemStock(doc.data()) } as StockItem))
                .sort((a, b) => (a.name || '').localeCompare(b.name || ''));
            setStockItems(itemsList);
            setIsLoading(false);
        }, (error) => {
            console.error("Error fetching stock items:", error);
            toast({ title: "Gagal memuat data live", variant: "destructive" });
            setIsLoading(false);
        });

        return () => unsubscribe();
    }, [toast]);

    const filteredItems = useMemo(() => {
        return stockItems.filter((item) => {
            const matchesSearch = (item.name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
                (item.code || '').toLowerCase().includes(searchTerm.toLowerCase());

            if (!matchesSearch) return false;

            if (filterStatus === "all") return true;

            const status = getStockStatus(item.stock, item.minStock).status;
            if (filterStatus === "safe") return status === "safe";
            if (filterStatus === "warning") return status === "low" || status === "empty"; // Combine low and empty for warning filter

            return true;
        });
    }, [stockItems, searchTerm, filterStatus]);

    const stats = useMemo(() => {
        const total = stockItems.length;
        const low = stockItems.filter(i => getStockStatus(i.stock, i.minStock).status === 'low').length;
        const empty = stockItems.filter(i => getStockStatus(i.stock, i.minStock).status === 'empty').length;
        const safe = total - low - empty;
        return { total, low, empty, safe };
    }, [stockItems]);

    const handleOpenAdjustDialog = (item: StockItem) => {
        setSelectedItem(item);
        setAdjustment({ type: 'add', quantity: 1, reason: 'stock_opname' });
        setIsAdjustDialogOpen(true);
    };

    const handleStockAdjustment = async () => {
        if (!selectedItem || !user || adjustment.quantity <= 0) return;
        setIsSaving(true);

        const quantityChange = adjustment.type === 'add' ? adjustment.quantity : -adjustment.quantity;

        try {
            const itemRef = doc(db, "items", selectedItem.id);
            const logRef = doc(collection(db, "itemMovements"));

            // Apply the change to the current server stock (phones may have sold
            // since this page loaded), same as the mobile app's stock writes.
            await runTransaction(db, async (tx) => {
                const snap = await tx.get(itemRef);
                if (!snap.exists()) throw new Error("Barang tidak ditemukan.");
                const previousStock = itemStock(snap.data());
                const newStock = previousStock + quantityChange;
                if (newStock < 0) throw new Error(`Stok tidak boleh kurang dari 0 (stok sekarang ${previousStock}).`);

                // 1. Update Stock
                tx.update(itemRef, {
                    stock: newStock,
                    qty_display: newStock, // Sync with Mobile
                    updatedAt: serverTimestamp()
                });

                // 2. Log Movement
                tx.set(logRef, {
                    itemId: selectedItem.id,
                    itemName: selectedItem.name,
                    itemCode: selectedItem.code,
                    transactionType: adjustment.type === 'add' ? 'adjustment_in' : 'adjustment_out',
                    reason: adjustment.reason,
                    quantity: Math.abs(quantityChange),
                    previousStock,
                    newStock,
                    userId: user.id,
                    userName: user.name,
                    timestamp: serverTimestamp()
                });
            });

            toast({ title: "Stok berhasil diperbarui" });
            setIsAdjustDialogOpen(false);
        } catch (error) {
            console.error(error);
            const message = error instanceof Error ? error.message : undefined;
            toast({ title: "Gagal memperbarui stok", description: message, variant: "destructive" });
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <MainLayout>
            <div className="space-y-6 pb-20">
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                    <div>
                        <h1 className="text-3xl font-bold text-slate-800">Stok Opname</h1>
                        <p className="text-slate-500 mt-1">Monitor level stok dan lakukan penyesuaian (opname) real-time.</p>
                    </div>
                    <Button variant="outline" onClick={() => window.location.reload()}>
                        <RefreshCw className="mr-2 h-4 w-4" /> Refresh Data
                    </Button>
                </div>

                {/* Summary Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <Card className="cursor-pointer hover:border-slate-300 transition-all border-slate-200 shadow-sm" onClick={() => setFilterStatus('all')}>
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium text-slate-600">Total Item</CardTitle>
                            <Package className="h-4 w-4 text-slate-400" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-slate-800">{stats.total}</div>
                            <p className="text-xs text-slate-500">Semua barang terdaftar</p>
                        </CardContent>
                    </Card>

                    <Card className="cursor-pointer hover:border-emerald-300 transition-all bg-emerald-50/30 border-emerald-100 shadow-sm" onClick={() => setFilterStatus('safe')}>
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium text-emerald-600">Stok Aman</CardTitle>
                            <CheckCircle className="h-4 w-4 text-emerald-500" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-emerald-700">{stats.safe}</div>
                            <p className="text-xs text-emerald-600/80">Siap dijual</p>
                        </CardContent>
                    </Card>

                    <Card className="cursor-pointer hover:border-amber-300 transition-all bg-amber-50/30 border-amber-100 shadow-sm" onClick={() => setFilterStatus('warning')}>
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium text-amber-600">Perlu Perhatian</CardTitle>
                            <AlertTriangle className="h-4 w-4 text-amber-500" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-amber-700">{stats.low + stats.empty}</div>
                            <p className="text-xs text-amber-600/80">{stats.empty} Habis, {stats.low} Menipis</p>
                        </CardContent>
                    </Card>
                </div>

                {/* Main Table */}
                <Card className="border-slate-200 shadow-sm bg-white">
                    <CardHeader>
                        <div className="flex flex-col md:flex-row justify-between md:items-center gap-4">
                            <div>
                                <CardTitle>Daftar Inventaris</CardTitle>
                                <CardDescription>Kelola jumlah stok fisik di toko/gudang.</CardDescription>
                            </div>
                            <div className="relative w-full md:w-72">
                                <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                                <Input
                                    placeholder="Cari nama atau kode barang..."
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                    className="pl-9"
                                />
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent>
                        <div className="rounded-lg border border-slate-100 overflow-hidden">
                            <table className="w-full text-sm">
                                <thead className="bg-slate-50 text-slate-500 font-medium border-b border-slate-100">
                                    <tr>
                                        <th className="px-4 py-3 text-left w-[120px]">Kode</th>
                                        <th className="px-4 py-3 text-left">Nama Barang</th>
                                        <th className="px-4 py-3 text-center w-[100px]">Min. Stok</th>
                                        <th className="px-4 py-3 text-center w-[120px]">Stok Fisik</th>
                                        <th className="px-4 py-3 text-center w-[140px]">Status</th>
                                        <th className="px-4 py-3 text-right w-[120px]">Aksi</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {isLoading ? (
                                        <tr><td colSpan={6} className="h-32 text-center text-slate-400">Memuat data stok...</td></tr>
                                    ) : filteredItems.length === 0 ? (
                                        <tr><td colSpan={6} className="h-32 text-center text-slate-400">Tidak ada barang ditemukan.</td></tr>
                                    ) : (
                                        filteredItems.map((item) => {
                                            const { status, text, icon: Icon, color, bg, border } = getStockStatus(item.stock, item.minStock);
                                            return (
                                                <tr key={item.id} className="hover:bg-slate-50/50 transition-colors group">
                                                    <td className="px-4 py-3 font-mono text-xs text-slate-500">{item.code}</td>
                                                    <td className="px-4 py-3 font-medium text-slate-700">{item.name}</td>
                                                    <td className="px-4 py-3 text-center text-slate-500">{item.minStock}</td>
                                                    <td className="px-4 py-3 text-center">
                                                        <span className="font-bold text-slate-800 text-base">{item.stock}</span>
                                                    </td>
                                                    <td className="px-4 py-3 text-center">
                                                        <div className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${bg} ${color} ${border}`}>
                                                            <Icon className="w-3 h-3 mr-1.5" />
                                                            {text}
                                                        </div>
                                                    </td>
                                                    <td className="px-4 py-3 text-right">
                                                        <Button
                                                            variant="ghost"
                                                            size="sm"
                                                            className="h-8 text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                                                            onClick={() => handleOpenAdjustDialog(item)}
                                                        >
                                                            <ArrowRightLeft className="w-4 h-4 mr-2" />
                                                            Opname
                                                        </Button>
                                                    </td>
                                                </tr>
                                            )
                                        })
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </CardContent>
                </Card>

                {/* Adjustment Dialog */}
                <Dialog open={isAdjustDialogOpen} onOpenChange={setIsAdjustDialogOpen}>
                    <DialogContent className="sm:max-w-md">
                        <DialogHeader>
                            <DialogTitle className="flex items-center gap-2">
                                <History className="w-5 h-5 text-indigo-600" />
                                Koreksi Stok Barang
                            </DialogTitle>
                            <DialogDescription>
                                Perbarui jumlah stok fisik untuk <strong>{selectedItem?.name}</strong>.
                            </DialogDescription>
                        </DialogHeader>

                        <div className="space-y-4 py-2">
                            <div className="p-3 bg-slate-50 rounded-lg flex justify-between items-center border border-slate-100">
                                <span className="text-sm text-slate-500">Stok Saat Ini</span>
                                <span className="text-lg font-bold text-slate-800">{selectedItem?.stock} Unit</span>
                            </div>

                            <div className="grid grid-cols-2 gap-3">
                                <Button
                                    type="button"
                                    variant={adjustment.type === 'add' ? 'default' : 'outline'}
                                    className={adjustment.type === 'add' ? "bg-emerald-600 hover:bg-emerald-700" : ""}
                                    onClick={() => setAdjustment(prev => ({ ...prev, type: 'add' }))}
                                >
                                    + Tambah
                                </Button>
                                <Button
                                    type="button"
                                    variant={adjustment.type === 'remove' ? 'default' : 'outline'}
                                    className={adjustment.type === 'remove' ? "bg-red-600 hover:bg-red-700" : ""}
                                    onClick={() => setAdjustment(prev => ({ ...prev, type: 'remove' }))}
                                >
                                    - Kurang
                                </Button>
                            </div>

                            <div className="space-y-2">
                                <Label>Jumlah Penyesuaian</Label>
                                <Input
                                    type="number"
                                    min="1"
                                    value={adjustment.quantity}
                                    onChange={e => setAdjustment(prev => ({ ...prev, quantity: parseInt(e.target.value) || 0 }))}
                                    className="text-center text-lg font-bold"
                                />
                            </div>

                            <div className="space-y-2">
                                <Label>Alasan</Label>
                                <Select value={adjustment.reason} onValueChange={v => setAdjustment(prev => ({ ...prev, reason: v }))}>
                                    <SelectTrigger>
                                        <SelectValue />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="stock_opname">Stock Opname (Rutin)</SelectItem>
                                        <SelectItem value="barang_masuk">Barang Masuk (Non-Beli)</SelectItem>
                                        <SelectItem value="barang_rusak">Barang Rusak / Expired</SelectItem>
                                        <SelectItem value="koreksi_sistem">Koreksi Kesalahan Input</SelectItem>
                                        <SelectItem value="lainnya">Lainnya</SelectItem>
                                    </SelectContent>
                                </Select>
                            </div>

                            <div className="p-3 bg-indigo-50 rounded-lg flex justify-between items-center border border-indigo-100">
                                <span className="text-sm text-indigo-600 font-medium">Stok Akhir Nanti</span>
                                <span className="text-lg font-bold text-indigo-700">
                                    {selectedItem ? (
                                        adjustment.type === 'add'
                                            ? selectedItem.stock + adjustment.quantity
                                            : selectedItem.stock - adjustment.quantity
                                    ) : 0} Unit
                                </span>
                            </div>
                        </div>

                        <DialogFooter>
                            <Button variant="ghost" onClick={() => setIsAdjustDialogOpen(false)} disabled={isSaving}>Batal</Button>
                            <Button onClick={handleStockAdjustment} disabled={isSaving || adjustment.quantity <= 0}>
                                {isSaving ? "Menyimpan..." : "Simpan Perubahan"}
                            </Button>
                        </DialogFooter>
                    </DialogContent>
                </Dialog>
            </div>
        </MainLayout>
    )
}
