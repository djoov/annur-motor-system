"use client"

import React, { useState, useEffect, useMemo } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Search, Package, AlertTriangle, CheckCircle, XCircle, Edit } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, getDocs, doc, writeBatch, serverTimestamp, increment } from "firebase/firestore"
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
    if (stock <= 0) return { status: "empty", text: "Habis", icon: XCircle, color: "text-red-700" }
    if (stock <= minStock * 0.5) return { status: "critical", text: "Kritis", icon: AlertTriangle, color: "text-red-600" }
    if (stock <= minStock) return { status: "low", text: "Rendah", icon: AlertTriangle, color: "text-yellow-600" }
    return { status: "safe", text: "Aman", icon: CheckCircle, color: "text-green-600" }
}

// --- Sub-Component for Summary Cards ---
const SummaryCards = ({ items, setFilter }: { items: StockItem[], setFilter: (status: any) => void }) => {
    const summary = useMemo(() => ({
        total: items.length,
        safe: items.filter(item => getStockStatus(item.stock, item.minStock).status === 'safe').length,
        low: items.filter(item => getStockStatus(item.stock, item.minStock).status === 'low').length,
        critical: items.filter(item => getStockStatus(item.stock, item.minStock).status === 'critical').length,
        empty: items.filter(item => getStockStatus(item.stock, item.minStock).status === 'empty').length,
    }), [items]);

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            <Card className="cursor-pointer hover:shadow-md" onClick={() => setFilter('all')}>
                <CardContent className="p-4 flex justify-between items-center">
                    <div><p className="text-sm font-medium">Total Item</p><p className="text-2xl font-bold">{summary.total}</p></div>
                    <Package className="h-8 w-8 text-blue-600" />
                </CardContent>
            </Card>
            <Card className="cursor-pointer hover:shadow-md" onClick={() => setFilter('safe')}>
                <CardContent className="p-4 flex justify-between items-center">
                    <div><p className="text-sm font-medium">Stok Aman</p><p className="text-2xl font-bold text-green-600">{summary.safe}</p></div>
                    <CheckCircle className="h-8 w-8 text-green-600" />
                </CardContent>
            </Card>
            <Card className="cursor-pointer hover:shadow-md" onClick={() => setFilter('low')}>
                <CardContent className="p-4 flex justify-between items-center">
                    <div><p className="text-sm font-medium">Stok Rendah</p><p className="text-2xl font-bold text-yellow-600">{summary.low}</p></div>
                    <AlertTriangle className="h-8 w-8 text-yellow-600" />
                </CardContent>
            </Card>
            <Card className="cursor-pointer hover:shadow-md" onClick={() => setFilter('critical')}>
                <CardContent className="p-4 flex justify-between items-center">
                    <div><p className="text-sm font-medium">Stok Kritis</p><p className="text-2xl font-bold text-red-600">{summary.critical}</p></div>
                    <AlertTriangle className="h-8 w-8 text-red-600" />
                </CardContent>
            </Card>
            <Card className="cursor-pointer hover:shadow-md" onClick={() => setFilter('empty')}>
                <CardContent className="p-4 flex justify-between items-center">
                    <div><p className="text-sm font-medium">Stok Habis</p><p className="text-2xl font-bold text-red-700">{summary.empty}</p></div>
                    <XCircle className="h-8 w-8 text-red-700" />
                </CardContent>
            </Card>
        </div>
    );
};

// --- Main Page Component ---
export default function StockPage() {
    const [stockItems, setStockItems] = useState<StockItem[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState("");
    const [filterStatus, setFilterStatus] = useState<string>("all");
    const [isAdjustDialogOpen, setIsAdjustDialogOpen] = useState(false);
    const [selectedItem, setSelectedItem] = useState<StockItem | null>(null);
    const [adjustment, setAdjustment] = useState({ type: 'koreksi_tambah', quantity: 1, reason: 'stock_opname' });
    const [isSaving, setIsSaving] = useState(false);
    const { user } = useAuth();
    const { toast } = useToast();

    const fetchStockItems = async () => {
        setIsLoading(true);
        try {
            const itemsSnapshot = await getDocs(collection(db, "items"));
            const itemsList = itemsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as StockItem))
                .sort((a, b) => (a.name || '').localeCompare(b.name || ''));
            setStockItems(itemsList);
        } catch (error) {
            console.error("Gagal mengambil data stok: ", error);
            toast({ title: "Gagal memuat data", variant: "destructive" });
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchStockItems();
    }, []);

    const filteredItems = useMemo(() => {
        return stockItems.filter((item) => {
            const matchesSearch = (item.name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
                                  (item.code || '').toLowerCase().includes(searchTerm.toLowerCase());
            if (!matchesSearch) return false;
            if (filterStatus === "all") return true;
            return getStockStatus(item.stock, item.minStock).status === filterStatus;
        });
    }, [stockItems, searchTerm, filterStatus]);

    const handleOpenAdjustDialog = (item: StockItem) => {
        setSelectedItem(item);
        setAdjustment({ type: 'koreksi_tambah', quantity: 1, reason: 'stock_opname' });
        setIsAdjustDialogOpen(true);
    };

    const handleStockAdjustment = async () => {
        if (!selectedItem || !user || adjustment.quantity <= 0) return;
        setIsSaving(true);

        const quantityChange = adjustment.type === 'koreksi_tambah' ? adjustment.quantity : -adjustment.quantity;
        const newStock = (selectedItem.stock || 0) + quantityChange;

        if (newStock < 0) {
            toast({ title: "Stok tidak boleh minus", variant: "destructive" });
            setIsSaving(false);
            return;
        }

        try {
            const batch = writeBatch(db);
            const itemRef = doc(db, "items", selectedItem.id);
            batch.update(itemRef, { stock: newStock });

            const logRef = doc(collection(db, "itemMovements"));
            batch.set(logRef, {
                itemId: selectedItem.id, itemName: selectedItem.name, itemCode: selectedItem.code,
                transactionType: `${adjustment.type}_(${adjustment.reason})`,
                quantity: adjustment.quantity, userId: user.id, userName: user.name,
                timestamp: serverTimestamp()
            });
            
            await batch.commit();
            await fetchStockItems(); // Re-fetch all data to ensure consistency
            toast({ title: "Stok berhasil diperbarui" });
            setIsAdjustDialogOpen(false);
        } catch (error) {
            toast({ title: "Gagal memperbarui stok", variant: "destructive" });
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <MainLayout>
            <div className="space-y-6">
                <div>
                    <h1 className="text-3xl font-bold text-gray-900">Stok Barang</h1>
                    <p className="text-gray-600">Monitoring dan kelola stok barang secara real-time.</p>
                </div>

                <SummaryCards items={stockItems} setFilter={setFilterStatus} />

                <Card>
                    <CardHeader>
                        <CardTitle className="flex items-center"><Package className="mr-2 h-5 w-5" />Daftar Stok Barang</CardTitle>
                        <CardDescription>Menampilkan {filteredItems.length} dari {stockItems.length} total barang.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="flex items-center space-x-2 mb-4">
                            <Search className="h-4 w-4 text-gray-400" />
                            <Input placeholder="Cari barang (nama atau kode)..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} className="max-w-sm" />
                        </div>
                        <div className="overflow-x-auto">
                            <table className="w-full">
                                <thead>
                                    <tr className="border-b">
                                        <th className="text-left py-3 px-2">Kode</th>
                                        <th className="text-left py-3 px-2">Nama Barang</th>
                                        <th className="text-center py-3 px-2">Stok</th>
                                        <th className="text-center py-3 px-2">Status</th>
                                        <th className="text-center py-3 px-2">Aksi Cepat</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {isLoading ? (<tr><td colSpan={5} className="text-center p-4">Memuat data...</td></tr>) : filteredItems.map((item) => {
                                        const stockStatus = getStockStatus(item.stock, item.minStock);
                                        const StatusIcon = stockStatus.icon;
                                        return (
                                            <tr key={item.id} className="border-b hover:bg-gray-50">
                                                <td className="py-3 px-2 font-mono text-sm">{item.code}</td>
                                                <td className="py-3 px-2 font-medium">{item.name}</td>
                                                <td className="py-3 px-2 text-center font-bold">{item.stock}</td>
                                                <td className="py-3 px-2 text-center">
                                                    <div className={`flex items-center justify-center ${stockStatus.color}`}>
                                                        <StatusIcon className="h-4 w-4 mr-1" />
                                                        <span className="text-xs font-medium">{stockStatus.text}</span>
                                                    </div>
                                                </td>
                                                <td className="py-3 px-2 text-center">
                                                    <Button variant="outline" size="sm" onClick={() => handleOpenAdjustDialog(item)}>
                                                        <Edit className="h-4 w-4 mr-1" /> Koreksi
                                                    </Button>
                                                </td>
                                            </tr>
                                        )
                                    })}
                                </tbody>
                            </table>
                        </div>
                    </CardContent>
                </Card>
            </div>

            <Dialog open={isAdjustDialogOpen} onOpenChange={setIsAdjustDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Koreksi Stok: {selectedItem?.name}</DialogTitle>
                        <p className="text-sm text-muted-foreground">Stok saat ini: <span className="font-bold">{selectedItem?.stock}</span> unit</p>
                    </DialogHeader>
                    <div className="space-y-4 py-4">
                        <div className="grid grid-cols-2 gap-4">
                            <Button variant={adjustment.type === 'koreksi_tambah' ? 'default' : 'outline'} onClick={() => setAdjustment(prev => ({...prev, type: 'koreksi_tambah'}))}>Tambah Stok</Button>
                            <Button variant={adjustment.type === 'koreksi_kurang' ? 'destructive' : 'outline'} onClick={() => setAdjustment(prev => ({...prev, type: 'koreksi_kurang'}))}>Kurangi Stok</Button>
                        </div>
                        <div>
                            <Label htmlFor="quantity">Jumlah</Label>
                            <Input id="quantity" type="number" min="1" value={adjustment.quantity} onChange={e => setAdjustment(prev => ({...prev, quantity: parseInt(e.target.value) || 1}))} />
                        </div>
                        <div>
                            <Label htmlFor="reason">Alasan Koreksi</Label>
                            <Select value={adjustment.reason} onValueChange={v => setAdjustment(prev => ({...prev, reason: v}))}>
                                <SelectTrigger id="reason"><SelectValue /></SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="stock_opname">Stock Opname</SelectItem>
                                    <SelectItem value="barang_rusak">Barang Rusak</SelectItem>
                                    <SelectItem value="koreksi_sistem">Koreksi Sistem</SelectItem>
                                    <SelectItem value="lainnya">Lainnya</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                    </div>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsAdjustDialogOpen(false)}>Batal</Button>
                        <Button onClick={handleStockAdjustment} disabled={isSaving}>
                            {isSaving ? "Menyimpan..." : "Simpan Perubahan"}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </MainLayout>
    )
}
