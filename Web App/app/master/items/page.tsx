"use client"

import type React from "react"
import { useState, useEffect, useRef } from "react"
import Image from "next/image"
import { MainLayout } from "@/components/layout/main-layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Plus, Edit, Trash2, Search, Package, UploadCloud, X, QrCode, Store, Warehouse, AlertTriangle } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { db } from "@/lib/firebase"
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc, serverTimestamp, query, where, limit } from "firebase/firestore"
import { QRCodeCanvas } from "qrcode.react"
import { Badge } from "@/components/ui/badge"

import type { Item, Category } from "@/types"

// --- Helper Functions ---
async function getUniqueItemCode(initialCode: string): Promise<string> {
  const itemsRef = collection(db, "items");
  const q = query(itemsRef, where("code", "==", initialCode), limit(1));
  const querySnapshot = await getDocs(q);

  if (querySnapshot.empty) {
    return initialCode;
  }

  const baseCodeMatch = initialCode.match(/^(.*?)(-?)(\d+)$/);
  if (!baseCodeMatch) {
    return `${initialCode}-1`;
  }

  const base = baseCodeMatch[1];
  const separator = baseCodeMatch[2] || '-';
  let nextNumber = parseInt(baseCodeMatch[3], 10) + 1;

  let newCode: string = "";
  let isUnique = false;

  while (!isUnique) {
    const padding = baseCodeMatch[3].length;
    newCode = `${base}${separator}${String(nextNumber).padStart(padding, '0')}`;
    const nextQuery = query(itemsRef, where("code", "==", newCode), limit(1));
    const nextSnapshot = await getDocs(nextQuery);
    if (nextSnapshot.empty) {
      isUnique = true;
    } else {
      nextNumber++;
    }
  }
  return newCode;
}

export default function ItemsPage() {
  const [items, setItems] = useState<Item[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const [searchTerm, setSearchTerm] = useState("")
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingItem, setEditingItem] = useState<Item | null>(null)

  // Updated FormData state to include separate stock fields
  const [formData, setFormData] = useState({
    code: "",
    name: "",
    description: "",
    category: "",
    buyPrice: "",
    sellPrice: "",
    stockDisplay: "",   // Gudang Toko
    stockWarehouse: "", // Gudang Utama
    minStock: "",
    barcode: ""
  })

  const [imageBase64, setImageBase64] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const { toast } = useToast()

  const fetchData = async () => {
    setIsLoading(true)
    try {
      const itemsSnapshot = await getDocs(collection(db, "items"))
      const categoriesSnapshot = await getDocs(collection(db, "categories"))

      const fetchedItems = itemsSnapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          ...data,
          id: doc.id,
          // Ensure new fields are mapped correctly for legacy data
          stock: data.stock || 0,
          stockDisplay: data.qty_display || data.stockDisplay || data.stock || 0,
          stockWarehouse: data.qty_warehouse || data.stockWarehouse || 0
        } as Item
      })

      const fetchedCategories = categoriesSnapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as Category))
      setItems(fetchedItems)
      setCategories(fetchedCategories)
    } catch (error: any) {
      console.error("Fetch Data Error:", error);
      const msg = error instanceof Error ? error.message : "Gagal memuat data (Unknown Error)";
      toast({ title: "Gagal Memuat Data", description: msg, variant: "destructive" })
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [])

  const filteredItems = items.filter(
    (item) =>
      (item.name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.code || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.category || '').toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const sortedItems = [...filteredItems].sort((a, b) => {
    const categoryA = a.category || '';
    const categoryB = b.category || '';
    if (categoryA !== categoryB) return categoryA.localeCompare(categoryB);
    return (a.name || '').localeCompare(b.name || '');
  });

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      if (!file.type.startsWith("image/")) {
        toast({ title: "File harus berupa gambar", variant: "destructive" })
        return
      }
      if (file.size > 1024 * 1024) { // Increased limit to 1MB
        toast({ title: "Ukuran file terlalu besar", description: "Maksimal 1MB.", variant: "destructive" })
        return
      }
      const reader = new FileReader()
      reader.onloadend = () => { setImageBase64(reader.result as string) }
      reader.onerror = (err) => {
        console.error("File reading error:", err);
        toast({ title: "Gagal membaca file", variant: "destructive" });
      }
      reader.readAsDataURL(file)
    }
  }

  const resetForm = () => {
    setFormData({
      code: "", name: "", description: "", category: "",
      buyPrice: "", sellPrice: "",
      stockDisplay: "", stockWarehouse: "",
      minStock: "", barcode: ""
    })
    setImageBase64(null)
    setEditingItem(null)
  }

  const handleDownloadQR = () => {
    const canvas = document.getElementById('qr-code-canvas') as HTMLCanvasElement;
    if (canvas && formData.code) {
      const pngUrl = canvas.toDataURL("image/png").replace("image/png", "image/octet-stream");
      let downloadLink = document.createElement("a");
      downloadLink.href = pngUrl;
      downloadLink.download = `${formData.code}.png`;
      document.body.appendChild(downloadLink);
      downloadLink.click();
      document.body.removeChild(downloadLink);
      toast({ title: "QR Code Diunduh", description: `File ${formData.code}.png berhasil diunduh.` });
    } else {
      toast({ title: "Gagal Mengunduh", description: "Kode barang tidak boleh kosong.", variant: "destructive" });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isSaving) return
    setIsSaving(true)

    try {
      let finalCode = formData.code;
      if (!editingItem) {
        finalCode = await getUniqueItemCode(formData.code);
        if (finalCode !== formData.code) {
          toast({
            title: "Kode Barang Duplikat",
            description: `Kode diganti menjadi "${finalCode}".`,
          });
        }
      }

      // Calculate total stock (Legacy support)
      const qtyDisplay = Number(formData.stockDisplay) || 0;
      const qtyWarehouse = Number(formData.stockWarehouse) || 0;
      const totalStock = qtyDisplay + qtyWarehouse;

      const itemData: any = {
        code: finalCode,
        name: formData.name,
        description: formData.description,
        category: formData.category,
        buyPrice: Number(formData.buyPrice),
        sellPrice: Number(formData.sellPrice),
        minStock: Number(formData.minStock),
        barcode: formData.barcode,
        imageUrl: imageBase64 || editingItem?.imageUrl || '',

        // Synced Data Model Fields
        qty_display: qtyDisplay,
        qty_warehouse: qtyWarehouse,
        stock: qtyDisplay, // Legacy field matches Shop Stock (Mobile Logic)

        // Also save text fields for easier querying if needed
        stockDisplay: qtyDisplay,
        stockWarehouse: qtyWarehouse
      }

      if (editingItem) {
        const itemDoc = doc(db, "items", editingItem.id)
        await updateDoc(itemDoc, itemData)
        toast({ title: "Barang berhasil diperbarui" })
      } else {
        await addDoc(collection(db, "items"), { ...itemData, createdAt: serverTimestamp() })
        toast({ title: "Barang berhasil ditambahkan" })
      }

      await fetchData()
      setIsDialogOpen(false)
      resetForm()

    } catch (error: any) {
      console.error("Submit Error:", error);
      const msg = error instanceof Error ? error.message : "Terjadi kesalahan saat menyimpan";
      toast({ title: "Gagal Menyimpan", description: msg, variant: "destructive" })
    } finally {
      setIsSaving(false)
    }
  }

  const handleEdit = (item: Item) => {
    setEditingItem(item)
    // Map existing data to form, handling potential missing new fields
    const displayStock = item.stockDisplay ?? item.stock ?? 0;
    const warehouseStock = item.stockWarehouse ?? 0;

    setFormData({
      code: item.code || '',
      name: item.name || '',
      description: item.description || '',
      category: item.category || '',
      buyPrice: (item.buyPrice || 0).toString(),
      sellPrice: (item.sellPrice || 0).toString(),
      stockDisplay: displayStock.toString(),
      stockWarehouse: warehouseStock.toString(),
      minStock: (item.minStock || 0).toString(),
      barcode: item.barcode || '',
    })
    setImageBase64(item.imageUrl || null)
    setIsDialogOpen(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm("Apakah Anda yakin ingin menghapus barang ini?")) return
    await deleteDoc(doc(db, "items", id))
    toast({ title: "Barang berhasil dihapus" })
    await fetchData()
  }

  const handleDialogChange = (open: boolean) => {
    if (!open) { resetForm(); setIsSaving(false); }
    setIsDialogOpen(open)
  }

  return (
    <MainLayout>
      <div className="space-y-6 pb-20">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-slate-900">Master Data Barang</h1>
            <p className="text-slate-500">Kelola inventaris, harga, dan stok multi-gudang.</p>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={handleDialogChange}>
            <DialogTrigger asChild>
              <Button onClick={() => { resetForm(); setIsDialogOpen(true); }} className="bg-blue-600 hover:bg-blue-700">
                <Plus className="mr-2 h-4 w-4" /> Tambah Barang
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>{editingItem ? "Edit Data Barang" : "Tambah Barang Baru"}</DialogTitle>
                <CardDescription>Pastikan kode barang unik dan data stok akurat.</CardDescription>
              </DialogHeader>

              <form onSubmit={handleSubmit} className="space-y-6 mt-4">
                <div className="grid grid-cols-1 md:grid-cols-12 gap-6">

                  {/* Left Column: Image & Basic Info */}
                  <div className="md:col-span-4 space-y-4">
                    <div className="flex flex-col items-center gap-4 p-4 border rounded-lg bg-slate-50/50">
                      <div className="relative w-full aspect-square border-2 border-dashed border-slate-300 rounded-lg flex items-center justify-center overflow-hidden hover:bg-slate-100 transition-colors cursor-pointer group" onClick={() => fileInputRef.current?.click()}>
                        {imageBase64 ? (
                          <>
                            <Image src={imageBase64} alt="Preview" fill className="object-cover" />
                            <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-xs">
                              Klik untuk ganti
                            </div>
                          </>
                        ) : (
                          <div className="text-center text-slate-400">
                            <UploadCloud className="mx-auto h-12 w-12 mb-2 opacity-50" />
                            <span className="text-xs">Upload Gambar (Max 1MB)</span>
                          </div>
                        )}
                      </div>
                      <Input type="file" ref={fileInputRef} className="hidden" onChange={handleFileChange} accept="image/*" />

                      {imageBase64 && (
                        <Button type="button" variant="outline" size="sm" className="w-full text-red-600 hover:text-red-700 hover:bg-red-50" onClick={(e) => { e.stopPropagation(); setImageBase64(null); }}>
                          <Trash2 className="w-4 h-4 mr-2" /> Hapus Gambar
                        </Button>
                      )}
                    </div>

                    <div className="p-4 border rounded-lg bg-white space-y-2 text-center">
                      <Label>QR Code Preview</Label>
                      <div className="flex justify-center py-2 bg-white">
                        <QRCodeCanvas id="qr-code-canvas" value={formData.code || 'ANNUR-MOTOR'} size={150} level="H" />
                      </div>
                      <p className="text-xs text-slate-400">{formData.code || 'Kode belum diisi'}</p>
                      {editingItem && formData.code && (
                        <Button type="button" variant="ghost" size="sm" onClick={handleDownloadQR} className="w-full text-xs">
                          <QrCode className="w-3 h-3 mr-2" /> Download QR
                        </Button>
                      )}
                    </div>
                  </div>

                  {/* Right Column: Details */}
                  <div className="md:col-span-8 space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label htmlFor="code">Kode Barang <span className="text-red-500">*</span></Label>
                        <Input id="code" value={formData.code} onChange={(e) => setFormData(p => ({ ...p, code: e.target.value.toUpperCase() }))} placeholder="Ex: BAN-001" required className="font-mono uppercase" />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="barcode">Barcode (Opsional)</Label>
                        <Input id="barcode" value={formData.barcode} onChange={(e) => setFormData(p => ({ ...p, barcode: e.target.value }))} placeholder="Scan barcode..." />
                      </div>
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="name">Nama Barang <span className="text-red-500">*</span></Label>
                      <Input id="name" value={formData.name} onChange={(e) => setFormData(p => ({ ...p, name: e.target.value }))} placeholder="Contoh: Oli Yamalube Sport 1L" required />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label htmlFor="category">Kategori</Label>
                        <Select value={formData.category} onValueChange={(value) => setFormData((prev) => ({ ...prev, category: value }))}>
                          <SelectTrigger><SelectValue placeholder="Pilih kategori" /></SelectTrigger>
                          <SelectContent>
                            {categories.map((c) => <SelectItem key={c.id} value={c.name}>{c.name}</SelectItem>)}
                          </SelectContent>
                        </Select>
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="minStock">Min. Stok Alert</Label>
                        <Input id="minStock" type="number" value={formData.minStock} onChange={(e) => setFormData(p => ({ ...p, minStock: e.target.value }))} placeholder="5" />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4 p-4 bg-slate-50 rounded-lg border">
                      <div className="space-y-2">
                        <Label htmlFor="buyPrice" className="text-slate-600">Harga Beli (Modal)</Label>
                        <div className="relative">
                          <span className="absolute left-3 top-2.5 text-slate-400">Rp</span>
                          <Input id="buyPrice" type="number" className="pl-9" value={formData.buyPrice} onChange={(e) => setFormData(p => ({ ...p, buyPrice: e.target.value }))} placeholder="0" />
                        </div>
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="sellPrice" className="text-blue-600 font-semibold">Harga Jual</Label>
                        <div className="relative">
                          <span className="absolute left-3 top-2.5 text-slate-400">Rp</span>
                          <Input id="sellPrice" type="number" className="pl-9 font-semibold text-slate-900 border-blue-200 focus:border-blue-500" value={formData.sellPrice} onChange={(e) => setFormData(p => ({ ...p, sellPrice: e.target.value }))} placeholder="0" required />
                        </div>
                      </div>
                    </div>

                    {/* Multi Warehouse Stock Inputs */}
                    <div className="grid grid-cols-2 gap-4 p-4 bg-blue-50/50 rounded-lg border border-blue-100">
                      <div className="space-y-2">
                        <div className="flex items-center gap-2">
                          <Store className="w-4 h-4 text-blue-600" />
                          <Label htmlFor="stockDisplay">Stok Toko (Display)</Label>
                        </div>
                        <Input id="stockDisplay" type="number" className="bg-white border-blue-200" value={formData.stockDisplay} onChange={(e) => setFormData(p => ({ ...p, stockDisplay: e.target.value }))} placeholder="0" />
                        <p className="text-[10px] text-slate-500">Barang di rak depan/etalase.</p>
                      </div>
                      <div className="space-y-2">
                        <div className="flex items-center gap-2">
                          <Warehouse className="w-4 h-4 text-orange-600" />
                          <Label htmlFor="stockWarehouse">Stok Gudang (Utama)</Label>
                        </div>
                        <Input id="stockWarehouse" type="number" className="bg-white border-orange-200" value={formData.stockWarehouse} onChange={(e) => setFormData(p => ({ ...p, stockWarehouse: e.target.value }))} placeholder="0" />
                        <p className="text-[10px] text-slate-500">Stok penyimpanan belakang.</p>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="description">Deskripsi</Label>
                      <Textarea id="description" value={formData.description} onChange={(e) => setFormData(p => ({ ...p, description: e.target.value }))} rows={2} placeholder="Keterangan tambahan..." />
                    </div>
                  </div>
                </div>

                <DialogFooter className="pt-4 border-t">
                  <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)} disabled={isSaving}>Batal</Button>
                  <Button type="submit" disabled={isSaving} className="bg-blue-600 hover:bg-blue-700 w-32">
                    {isSaving ? "Menyimpan..." : (editingItem ? "Update Data" : "Simpan Data")}
                  </Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <Card className="shadow-md border-slate-200">
          <CardHeader className="bg-slate-50 border-b border-slate-100 pb-4">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
              <div className="flex items-center space-x-2 w-full md:w-auto">
                <div className="relative w-full md:w-72">
                  <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                  <Input placeholder="Cari nama, kode, atau kategori..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} className="pl-9 bg-white" />
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Badge variant="outline" className="bg-white px-3 py-1 font-normal text-slate-600">Total: {filteredItems.length} Barang</Badge>
              </div>
            </div>
          </CardHeader>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-slate-50 text-slate-500 text-xs font-semibold uppercase tracking-wider">
                  <tr>
                    <th className="px-6 py-4 text-left w-20">Foto</th>
                    <th className="px-6 py-4 text-left">Kode / Nama</th>
                    <th className="px-6 py-4 text-left">Kategori</th>
                    <th className="px-6 py-4 text-right">Harga</th>
                    <th className="px-6 py-4 text-center w-32">
                      <div className="flex flex-col">
                        <span>Stok Total</span>
                        <span className="text-[10px] lowercase font-normal">(Toko + Gudang)</span>
                      </div>
                    </th>
                    <th className="px-6 py-4 text-center w-24">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 bg-white text-sm">
                  {isLoading ? (
                    <tr><td colSpan={6} className="text-center p-8 text-slate-400">Memuat data barang...</td></tr>
                  ) : filteredItems.length === 0 ? (
                    <tr><td colSpan={6} className="text-center p-8 text-slate-400">Tidak ada barang yang ditemukan.</td></tr>
                  ) : sortedItems.map((item) => {
                    const totalStock = (item.stockDisplay || 0) + (item.stockWarehouse || 0);
                    const isLowStock = totalStock <= (item.minStock || 5);

                    return (
                      <tr key={item.id} className="hover:bg-slate-50 transition-colors group">
                        <td className="px-6 py-3">
                          <div className="h-12 w-12 relative bg-slate-100 rounded-lg overflow-hidden border border-slate-200 flex items-center justify-center">
                            {item.imageUrl ? (
                              <Image src={item.imageUrl} alt={item.name} fill className="object-cover" />
                            ) : (
                              <Package className="text-slate-300 w-6 h-6" />
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-3">
                          <div className="flex flex-col">
                            <span className="font-bold text-slate-800 group-hover:text-blue-600 transition-colors">{item.name}</span>
                            <span className="text-xs font-mono text-slate-500">{item.code}</span>
                          </div>
                        </td>
                        <td className="px-6 py-3">
                          <Badge variant="secondary" className="font-normal text-xs bg-slate-100 text-slate-600">{item.category || '-'}</Badge>
                        </td>
                        <td className="px-6 py-3 text-right font-medium text-slate-700">
                          Rp {(item.sellPrice || 0).toLocaleString("id-ID")}
                        </td>
                        <td className="px-6 py-3 text-center">
                          <div className={`inline-flex flex-col items-center justify-center px-3 py-1 rounded-md border ${isLowStock ? 'bg-red-50 border-red-200 text-red-700' : 'bg-green-50/50 border-green-100 text-slate-700'}`}>
                            <span className="font-bold">{totalStock}</span>
                            <span className="text-[10px] opacity-70">
                              {item.stockDisplay || 0} + {item.stockWarehouse || 0}
                            </span>
                          </div>
                          {isLowStock && (
                            <div className="mt-1 flex items-center justify-center text-[10px] text-red-500 font-medium">
                              <AlertTriangle className="w-3 h-3 mr-1" /> Restok
                            </div>
                          )}
                        </td>
                        <td className="px-6 py-3 text-center">
                          <div className="flex justify-center gap-2">
                            <Button variant="ghost" size="icon" onClick={() => handleEdit(item)} className="h-8 w-8 text-blue-600 hover:bg-blue-50">
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button variant="ghost" size="icon" onClick={() => handleDelete(item.id)} className="h-8 w-8 text-red-600 hover:bg-red-50">
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            <div className="p-4 border-t border-slate-100 text-xs text-slate-500 flex justify-between items-center">
              <span>Menampilkan {filteredItems.length} item</span>
              <span>Data disinkronisasi dengan Mobile App</span>
            </div>
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  )
}
