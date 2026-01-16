"use client"

import React, { useState, useEffect, useMemo, useCallback } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Badge } from "@/components/ui/badge"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Plus, Trash2, Archive, Upload, FileText, ShoppingCart, User, AlertCircle, Search, Eye } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { db } from "@/lib/firebase"
import {
  collection,
  getDocs,
  doc,
  writeBatch,
  serverTimestamp,
  query,
  orderBy,
  Timestamp,
  increment,
  where,
  limit,
  onSnapshot
} from "firebase/firestore"
import { useAuth } from "@/components/auth-provider"
import Papa from "papaparse"

import type { Item } from "@/types"
interface Supplier { id: string; name: string }
interface PurchaseItem { itemId: string; itemName: string; quantity: number; buyPrice: number; code: string; isNew?: boolean }
interface Purchase { id: string; purchaseDate: any; supplierName: string; totalAmount: number; items: PurchaseItem[]; invoiceNumber?: string; recordedBy?: string }

export default function PurchasesPage() {
  const { user } = useAuth()
  const { toast } = useToast()

  // Data States
  const [purchases, setPurchases] = useState<Purchase[]>([])
  const [suppliers, setSuppliers] = useState<Supplier[]>([])
  const [items, setItems] = useState<Item[]>([]) // For item lookup if needed (though we might just query on demand for large datasets)

  // UI States
  const [isLoading, setIsLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const [isCsvLoading, setIsCsvLoading] = useState(false)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [searchTerm, setSearchTerm] = useState("")
  const [selectedPurchase, setSelectedPurchase] = useState<Purchase | null>(null)

  // Form States
  const [selectedSupplier, setSelectedSupplier] = useState("")
  const [invoiceNumber, setInvoiceNumber] = useState("")
  const [purchaseItems, setPurchaseItems] = useState<PurchaseItem[]>([])

  // --- Real-time Data Fetching ---
  useEffect(() => {
    setIsLoading(true);

    // 1. Listen to Purchases
    const qPurchases = query(collection(db, "purchases"), orderBy("purchaseDate", "desc"));
    const unsubPurchases = onSnapshot(qPurchases, (snap) => {
      setPurchases(snap.docs.map(d => ({ id: d.id, ...d.data() } as Purchase)));
      setIsLoading(false);
    });

    // 2. Listen to Suppliers (usually small list)
    const unsubSuppliers = onSnapshot(collection(db, "suppliers"), (snap) => {
      setSuppliers(snap.docs.map(d => ({ id: d.id, ...d.data() } as Supplier)));
    });

    return () => {
      unsubPurchases();
      unsubSuppliers();
    };
  }, []);

  const resetForm = useCallback(() => {
    setSelectedSupplier("")
    setInvoiceNumber("")
    setPurchaseItems([])
  }, [])

  const updatePurchaseItem = useCallback(
    (itemId: string, field: "quantity" | "buyPrice", value: number) => {
      setPurchaseItems((prev) => prev.map((it) => (it.itemId === itemId ? { ...it, [field]: Math.max(0, value) } : it)))
    },
    []
  )

  const removePurchaseItem = useCallback((itemId: string) => {
    setPurchaseItems((prev) => prev.filter((it) => it.itemId !== itemId))
  }, [])

  const handleDownloadTemplate = () => {
    const headers = "KODE,NAMA BARANG,JUMLAH,HARGA BELI";
    const example = "ALI-001,Contoh Barang,10,50000";
    const csvContent = "data:text/csv;charset=utf-8," + headers + "\n" + example;
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "template_faktur_pembelian.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  const handleCsvImport = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setIsCsvLoading(true)
    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: async (res) => {
        const imported: PurchaseItem[] = []
        // Process sequentially
        for (let idx = 0; idx < res.data.length; idx++) {
          const row: any = (res.data as any[])[idx]

          // Flexible Header Matching (Web vs Mobile format)
          // Mobile: KODE, NAMA BARANG, STOK TOKO, HARGA BELI
          // Web: kode_barang, nama_barang, jumlah, harga_beli

          const rawCode = row.kode_barang || row.code || row.KODE || row["Kode Barang"];
          const code = (rawCode || "").toString().trim().toUpperCase();

          const name = row.nama_barang || row.name || row["NAMA BARANG"] || row["Nama Barang"];

          // For Quantity: Check 'jumlah' first, then fallback to 'STOK TOKO' (if using mobile template)
          const qtyRaw = row.jumlah || row.quantity || row["STOK TOKO"] || row["Stok Toko"];
          const qty = parseInt(qtyRaw) || 0;

          const priceRaw = row.harga_beli || row.buyPrice || row["HARGA BELI"] || row["Harga Beli"];
          const price = parseInt(priceRaw) || 0;

          if (!code || !name || qty <= 0) continue

          // Check if item exists
          const snap = await getDocs(query(collection(db, "items"), where("code", "==", code), limit(1)))

          if (snap.empty) {
            imported.push({ itemId: `new_${code}`, itemName: name, quantity: qty, buyPrice: price, code, isNew: true })
          } else {
            const existing = snap.docs[0].data();
            imported.push({ itemId: snap.docs[0].id, itemName: existing.name || name, quantity: qty, buyPrice: price, code })
          }
        }
        setPurchaseItems(prev => [...prev, ...imported]);
        toast({ title: "Import Berhasil", description: `${imported.length} item ditambahkan.` })
        setIsCsvLoading(false)
        e.target.value = '';
      },
      error: () => {
        toast({ title: "Import Gagal", description: "Format CSV tidak valid.", variant: "destructive" });
        setIsCsvLoading(false);
      }
    })
  }

  const totalAmount = useMemo(() => purchaseItems.reduce((sum, it) => sum + it.quantity * it.buyPrice, 0), [purchaseItems])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedSupplier || purchaseItems.length === 0) {
      toast({ title: "Data tidak lengkap", description: "Pilih supplier dan minimal 1 item.", variant: "destructive" })
      return
    }
    setIsSaving(true)
    try {
      const batch = writeBatch(db)
      const purchaseRef = doc(collection(db, "purchases"))
      const supplier = suppliers.find((s) => s.id === selectedSupplier)
      const itemsForDoc: PurchaseItem[] = []

      for (const it of purchaseItems) {
        if (it.isNew) {
          const newRef = doc(collection(db, "items"))
          batch.set(newRef, {
            code: it.code,
            name: it.itemName,
            buyPrice: it.buyPrice,
            stock: it.quantity, // Legacy
            qty_display: it.quantity, // Sync Mobile
            qty_warehouse: 0, // Default 0 for new purchases unless specified? Defaulting to Shop.
            sellPrice: it.buyPrice * 1.3, // Default margin 30%
            minStock: 5,
            category: "Lain-lain", // Default category
            description: "Auto-created from Purchase",
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
          })
          itemsForDoc.push({ ...it, itemId: newRef.id })
        } else {
          // Update existing item stock
          const itemRef = doc(db, "items", it.itemId);
          batch.update(itemRef, {
            stock: increment(it.quantity), // Legacy
            qty_display: increment(it.quantity), // Sync Mobile (Assume Purchase -> Shop)
            buyPrice: it.buyPrice, // Update buy price to latest
            updatedAt: serverTimestamp()
          })
          itemsForDoc.push(it)
        }
      }

      batch.set(purchaseRef, {
        purchaseDate: serverTimestamp(),
        supplierId: selectedSupplier,
        supplierName: supplier?.name || "N/A",
        invoiceNumber,
        totalAmount,
        items: itemsForDoc,
        recordedBy: user?.name || "Admin",
      })

      // Also Log Item Movements for each item
      itemsForDoc.forEach(it => {
        const movementRef = doc(collection(db, "itemMovements"));
        batch.set(movementRef, {
          itemId: it.itemId,
          itemName: it.itemName,
          itemCode: it.code,
          transactionType: 'purchase_in',
          quantity: it.quantity,
          referenceId: purchaseRef.id,
          userId: user?.id || 'system',
          userName: user?.name || 'System',
          timestamp: serverTimestamp()
        });
      });

      await batch.commit()
      toast({ title: "Pembelian Berhasil Dicatat", description: "Stok otomatis bertambah." })
      resetForm()
      setIsDialogOpen(false)
    } catch (err: any) {
      console.error(err);
      toast({ title: "Gagal menyimpan", description: err.message, variant: "destructive" })
    } finally {
      setIsSaving(false)
    }
  }

  const handleDeletePurchase = async (purchase: Purchase) => {
    setIsSaving(true) // Reuse saving state for UI blocking
    try {
      const batch = writeBatch(db)

      // Revert Stock
      for (const it of purchase.items) {
        const itemRef = doc(db, "items", it.itemId);
        batch.update(itemRef, {
          stock: increment(-it.quantity),
          qty_display: increment(-it.quantity) // Sync with Mobile
        })

        // Log Reversal
        const movementRef = doc(collection(db, "itemMovements"));
        batch.set(movementRef, {
          itemId: it.itemId,
          itemName: it.itemName,
          itemCode: it.code,
          transactionType: 'purchase_void',
          quantity: it.quantity,
          referenceId: purchase.id,
          userId: user?.id || 'system',
          userName: user?.name || 'System',
          timestamp: serverTimestamp()
        });
      }

      batch.delete(doc(db, "purchases", purchase.id))
      await batch.commit()
      toast({ title: "Faktur Dibatalkan", description: "Stok telah dikembalikan." })
    } catch (err: any) {
      toast({ title: "Gagal menghapus", description: err.message, variant: "destructive" })
    } finally {
      setIsSaving(false)
    }
  }

  const filteredPurchases = useMemo(() => {
    return purchases.filter(p =>
      p.supplierName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (p.invoiceNumber && p.invoiceNumber.toLowerCase().includes(searchTerm.toLowerCase()))
    )
  }, [purchases, searchTerm]);

  return (
    <MainLayout>
      <div className="space-y-6 pb-20">
        {/* HEADER */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-slate-800">Pembelian & Stok Masuk</h1>
            <p className="text-slate-500 mt-1">Catat faktur dari supplier untuk menambah stok gudang.</p>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={() => { resetForm(); setIsDialogOpen(true) }} className="bg-indigo-600 hover:bg-indigo-700 text-white">
                <Plus className="mr-2 h-4 w-4" /> Input Faktur Baru
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-4xl h-[90vh] flex flex-col p-0 gap-0 bg-slate-50">
              <div className="p-6 pb-4 border-b border-slate-200 bg-white rounded-t-lg">
                <DialogHeader>
                  <DialogTitle className="flex items-center gap-2 text-xl">
                    <ShoppingCart className="w-5 h-5 text-indigo-600" />
                    Input Faktur Pembelian
                  </DialogTitle>
                  <p className="text-sm text-slate-500">Isi detail faktur dan upload CSV jika ada banyak item.</p>
                </DialogHeader>
              </div>

              <div className="flex-grow overflow-y-auto p-6 space-y-6">
                <form id="purchase-form" onSubmit={handleSubmit} className="space-y-6">
                  {/* Supplier & Invoice Info */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6 p-4 bg-white rounded-xl border border-slate-200 shadow-sm">
                    <div className="space-y-2">
                      <Label className="text-slate-600">Supplier <span className="text-red-500">*</span></Label>
                      <Select value={selectedSupplier} onValueChange={setSelectedSupplier}>
                        <SelectTrigger className="bg-slate-50 border-slate-200">
                          <SelectValue placeholder="Pilih Supplier..." />
                        </SelectTrigger>
                        <SelectContent>
                          {suppliers.map((s) => (
                            <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-2">
                      <Label className="text-slate-600">No. Faktur (Opsional)</Label>
                      <Input
                        placeholder="Contoh: INV-001"
                        value={invoiceNumber}
                        onChange={(e) => setInvoiceNumber(e.target.value)}
                        className="bg-slate-50 border-slate-200"
                      />
                    </div>
                  </div>

                  {/* Import CSV Section */}
                  <div className="flex items-center justify-between p-4 bg-indigo-50 border border-indigo-100 rounded-xl">
                    <div className="flex items-center gap-3">
                      <div className="bg-indigo-100 p-2 rounded-lg">
                        <FileText className="w-5 h-5 text-indigo-600" />
                      </div>
                      <div>
                        <h4 className="font-semibold text-indigo-900">Import dari Excel/CSV</h4>
                        <p className="text-xs text-indigo-700">Mobile Format Supported (KODE, NAMA, STOK TOKO, HARGA)</p>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Button type="button" variant="outline" size="sm" onClick={handleDownloadTemplate} className="text-indigo-600 border-indigo-200 hover:bg-indigo-100">
                        Download Template
                      </Button>
                      <Label htmlFor="csv-upload" className="cursor-pointer">
                        <div className="flex items-center gap-2 px-4 py-2 bg-white border border-indigo-200 text-indigo-700 hover:bg-indigo-50 rounded-md transition-colors shadow-sm font-medium text-sm">
                          {isCsvLoading ? <span className="animate-spin mr-2">⏳</span> : <Upload className="w-4 h-4" />}
                          {isCsvLoading ? "Memproses..." : "Upload File"}
                        </div>
                        <Input id="csv-upload" type="file" accept=".csv" className="hidden" onChange={handleCsvImport} disabled={isCsvLoading} />
                      </Label>
                    </div>
                  </div>

                  {/* Items Table */}
                  <Card className="border-slate-200 shadow-sm overflow-hidden">
                    <CardHeader className="py-3 px-4 bg-slate-100/50 border-b border-slate-200">
                      <div className="flex justify-between items-center">
                        <h4 className="font-semibold text-slate-700 text-sm">Daftar Item</h4>
                        <span className="text-xs bg-slate-200 text-slate-600 px-2 py-1 rounded-full">{purchaseItems.length} Item</span>
                      </div>
                    </CardHeader>
                    <CardContent className="p-0">
                      <div className="max-h-[300px] overflow-y-auto">
                        <table className="w-full text-sm">
                          <thead className="bg-slate-50 text-slate-500 font-medium sticky top-0 z-10 border-b border-slate-200">
                            <tr>
                              <th className="p-3 text-left w-1/3">Barang</th>
                              <th className="p-3 text-center w-24">Qty</th>
                              <th className="p-3 text-right w-32">Harga Beli</th>
                              <th className="p-3 text-right">Subtotal</th>
                              <th className="p-3 w-10"></th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-slate-100 bg-white">
                            {purchaseItems.length === 0 ? (
                              <tr>
                                <td colSpan={5} className="text-center py-12">
                                  <div className="flex flex-col items-center gap-2 text-slate-400">
                                    <ShoppingCart className="w-8 h-8 opacity-20" />
                                    <p>Belum ada barang. Upload CSV atau scan barang.</p>
                                  </div>
                                </td>
                              </tr>
                            ) : (
                              purchaseItems.map((item, idx) => (
                                <tr key={`${item.itemId}-${idx}`} className="group hover:bg-slate-50">
                                  <td className="p-3">
                                    <p className="font-medium text-slate-700 line-clamp-1">{item.itemName}</p>
                                    <div className="flex items-center gap-2 mt-0.5">
                                      <span className="font-mono text-[10px] text-slate-400 bg-slate-100 px-1 rounded">{item.code}</span>
                                      {item.isNew && <Badge variant="secondary" className="text-[10px] h-4 bg-green-100 text-green-700 border-green-200">Baru</Badge>}
                                    </div>
                                  </td>
                                  <td className="p-3">
                                    <Input
                                      type="number"
                                      className="h-8 text-center"
                                      value={item.quantity}
                                      onChange={(e) => updatePurchaseItem(item.itemId, "quantity", parseInt(e.target.value) || 0)}
                                    />
                                  </td>
                                  <td className="p-3">
                                    <Input
                                      type="number"
                                      className="h-8 text-right"
                                      value={item.buyPrice}
                                      onChange={(e) => updatePurchaseItem(item.itemId, "buyPrice", parseInt(e.target.value) || 0)}
                                    />
                                  </td>
                                  <td className="p-3 text-right font-medium text-slate-700">
                                    Rp {(item.quantity * item.buyPrice).toLocaleString("id-ID")}
                                  </td>
                                  <td className="p-3 text-center">
                                    <Button
                                      type="button"
                                      variant="ghost"
                                      size="icon"
                                      className="h-7 w-7 text-slate-400 hover:text-red-500 hover:bg-red-50"
                                      onClick={() => removePurchaseItem(item.itemId)}
                                    >
                                      <Trash2 className="h-4 w-4" />
                                    </Button>
                                  </td>
                                </tr>
                              ))
                            )}
                          </tbody>
                        </table>
                      </div>
                    </CardContent>
                  </Card>
                </form>
              </div>

              <div className="p-4 border-t border-slate-200 bg-white rounded-b-lg flex justify-between items-center">
                <div className="text-right">
                  <p className="text-xs text-slate-500 uppercase font-semibold">Total Faktur</p>
                  <p className="text-2xl font-bold text-indigo-600">Rp {totalAmount.toLocaleString("id-ID")}</p>
                </div>
                <div className="flex gap-3">
                  <Button variant="outline" onClick={() => setIsDialogOpen(false)} disabled={isSaving}>Batal</Button>
                  <Button type="submit" form="purchase-form" className="bg-indigo-600 hover:bg-indigo-700" disabled={isSaving}>
                    {isSaving ? "Menyimpan..." : "Simpan Faktur"}
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>

        {/* RIWAYAT PEMBELIAN */}
        <Card className="border-slate-200 shadow-sm bg-white">
          <CardHeader className="pb-3">
            <div className="flex flex-col md:flex-row justify-between items-center gap-4">
              <div className="flex items-center gap-2">
                <Archive className="h-5 w-5 text-slate-500" />
                <div>
                  <CardTitle className="text-lg">Riwayat Pembelian</CardTitle>
                  <CardDescription>Daftar semua transaksi barang masuk.</CardDescription>
                </div>
              </div>
              <div className="relative w-full md:w-64">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                <Input
                  placeholder="Cari Supplier / No. Faktur..."
                  className="pl-9"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="rounded-lg border border-slate-100 overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 text-slate-500 font-medium">
                  <tr>
                    <th className="px-4 py-3 text-left w-32">Tanggal</th>
                    <th className="px-4 py-3 text-left">Supplier</th>
                    <th className="px-4 py-3 text-left">No. Faktur</th>
                    <th className="px-4 py-3 text-center">Item</th>
                    <th className="px-4 py-3 text-right">Total</th>
                    <th className="px-4 py-3 text-center w-20">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {isLoading ? (
                    <tr><td colSpan={6} className="h-32 text-center text-slate-400">Memuat riwayat...</td></tr>
                  ) : filteredPurchases.length === 0 ? (
                    <tr><td colSpan={6} className="h-32 text-center text-slate-400">Tidak ada data pembelian.</td></tr>
                  ) : (
                    filteredPurchases.map((p) => (
                      <tr key={p.id} className="hover:bg-slate-50/50 group">
                        <td className="px-4 py-3 font-medium text-slate-600">
                          {(p.purchaseDate as Timestamp)?.toDate
                            ? (p.purchaseDate as Timestamp).toDate().toLocaleDateString("id-ID", { day: '2-digit', month: 'short', year: 'numeric' })
                            : "-"}
                        </td>
                        <td className="px-4 py-3 font-semibold text-slate-700">{p.supplierName}</td>
                        <td className="px-4 py-3 font-mono text-xs text-slate-500">{p.invoiceNumber || "-"}</td>
                        <td className="px-4 py-3 text-center text-slate-600">{p.items.length}</td>
                        <td className="px-4 py-3 text-right font-bold text-slate-700">Rp {p.totalAmount.toLocaleString("id-ID")}</td>
                        <td className="px-4 py-3 text-center">
                          <div className="flex items-center justify-center gap-2">
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8 text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                              onClick={() => setSelectedPurchase(p)}
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                            <AlertDialog>
                              <AlertDialogTrigger asChild>
                                <Button variant="ghost" size="icon" className="h-8 w-8 text-slate-400 hover:text-red-500 hover:bg-red-50" disabled={isSaving}>
                                  <Trash2 className="h-4 w-4" />
                                </Button>
                              </AlertDialogTrigger>
                              <AlertDialogContent>
                                <AlertDialogHeader>
                                  <AlertDialogTitle className="flex items-center gap-2 text-red-600">
                                    <AlertCircle className="w-5 h-5" />
                                    Batalkan Faktur?
                                  </AlertDialogTitle>
                                  <AlertDialogDescription>
                                    Stok barang yang ada di faktur ini akan dikurangi kembali.
                                    Pastikan stok fisik mencukupi sebelum membatalkan.
                                  </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                  <AlertDialogCancel disabled={isSaving}>Batal</AlertDialogCancel>
                                  <AlertDialogAction onClick={() => handleDeletePurchase(p)} className="bg-red-600 hover:bg-red-700" disabled={isSaving}>
                                    {isSaving ? "Memproses..." : "Ya, Batalkan"}
                                  </AlertDialogAction>
                                </AlertDialogFooter>
                              </AlertDialogContent>
                            </AlertDialog>
                          </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>

        {/* Purchase Detail Dialog */}
        <Dialog open={!!selectedPurchase} onOpenChange={(open) => !open && setSelectedPurchase(null)}>
          <DialogContent className="max-w-3xl max-h-[85vh] flex flex-col overflow-hidden">
            <DialogHeader className="flex-shrink-0">
              <DialogTitle className="flex items-center gap-2">
                <FileText className="w-5 h-5 text-indigo-600" />
                Detail Faktur Pembelian
              </DialogTitle>
              <DialogDescription>
                Informasi lengkap barang masuk dari supplier.
              </DialogDescription>
            </DialogHeader>

            {selectedPurchase && (
              <div className="space-y-6 overflow-y-auto pr-2 pb-4">
                {/* Header Info */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 p-4 bg-slate-50 rounded-lg border border-slate-100">
                  <div>
                    <p className="text-xs text-slate-500 uppercase tracking-wide font-medium">No. Faktur</p>
                    <p className="font-mono text-sm font-semibold text-slate-700">{selectedPurchase.invoiceNumber || "-"}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500 uppercase tracking-wide font-medium">Supplier</p>
                    <p className="font-medium text-slate-700">{selectedPurchase.supplierName}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500 uppercase tracking-wide font-medium">Tanggal</p>
                    <p className="font-medium text-slate-700">
                      {selectedPurchase.purchaseDate?.toDate().toLocaleString("id-ID", { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500 uppercase tracking-wide font-medium">Petugas</p>
                    <p className="font-medium text-slate-700 flex items-center gap-1">
                      <User className="w-3 h-3" />
                      {selectedPurchase.recordedBy || "-"}
                    </p>
                  </div>
                </div>

                {/* Items Table */}
                <div>
                  <h4 className="text-sm font-semibold text-slate-800 mb-3 flex items-center gap-2">
                    <ShoppingCart className="w-4 h-4 text-slate-500" />
                    Daftar Barang
                  </h4>
                  <div className="rounded-lg border border-slate-200 overflow-hidden">
                    <table className="w-full text-sm">
                      <thead className="bg-slate-50 border-b border-slate-200">
                        <tr>
                          <th className="px-4 py-2 text-left font-medium text-slate-500">Barang</th>
                          <th className="px-4 py-2 text-center font-medium text-slate-500">Qty</th>
                          <th className="px-4 py-2 text-right font-medium text-slate-500">Harga Beli</th>
                          <th className="px-4 py-2 text-right font-medium text-slate-500">Subtotal</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {selectedPurchase.items.map((item, idx) => (
                          <tr key={idx} className="hover:bg-slate-50/50">
                            <td className="px-4 py-2">
                              <p className="font-medium text-slate-700">{item.itemName}</p>
                              <p className="font-mono text-[10px] text-slate-400">{item.code}</p>
                            </td>
                            <td className="px-4 py-2 text-center font-medium">{item.quantity}</td>
                            <td className="px-4 py-2 text-right font-mono text-slate-600">Rp {item.buyPrice.toLocaleString("id-ID")}</td>
                            <td className="px-4 py-2 text-right font-bold text-slate-700">Rp {(item.quantity * item.buyPrice).toLocaleString("id-ID")}</td>
                          </tr>
                        ))}
                      </tbody>
                      <tfoot className="bg-slate-50 border-t border-slate-200 font-bold">
                        <tr>
                          <td colSpan={3} className="px-4 py-3 text-right text-slate-600">Total Pembelian</td>
                          <td className="px-4 py-3 text-right text-indigo-600 text-base">Rp {selectedPurchase.totalAmount.toLocaleString("id-ID")}</td>
                        </tr>
                      </tfoot>
                    </table>
                  </div>
                </div>
              </div>
            )}
          </DialogContent>
        </Dialog>
      </div>
    </MainLayout>
  )
}
