"use client"

import type React from "react"
import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Plus, Edit, Trash2, Search, Package } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

// --- Impor dari Firebase ---
import { db } from "@/lib/firebase"
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc, serverTimestamp } from "firebase/firestore"

// --- Interface tetap sama, tapi createdAt diubah untuk menerima Timestamp ---
interface Item {
  id: string
  code: string
  name: string
  description: string
  category: string
  buyPrice: number
  sellPrice: number
  stock: number
  minStock: number
  createdAt: any 
}

const categories = ["Spare Part Motor", "Oli & Pelumas", "Ban & Velg", "Aksesoris", "Service"]

export default function ItemsPage() {
  // --- State untuk data, sekarang awalnya kosong dan ada state loading ---
  const [items, setItems] = useState<Item[]>([])
  const [isLoading, setIsLoading] = useState(true)
  
  const [searchTerm, setSearchTerm] = useState("")
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingItem, setEditingItem] = useState<Item | null>(null)
  const [formData, setFormData] = useState({
    code: "",
    name: "",
    description: "",
    category: "",
    buyPrice: "",
    sellPrice: "",
    stock: "",
    minStock: "",
  })
  const { toast } = useToast()
  
  const itemsCollectionRef = collection(db, "items");

  // --- [BARU] Fungsi untuk mengambil data dari Firestore ---
  const fetchItems = async () => {
    setIsLoading(true);
    try {
      const data = await getDocs(itemsCollectionRef);
      const fetchedItems = data.docs.map((doc) => ({ ...doc.data(), id: doc.id } as Item));
      setItems(fetchedItems);
    } catch (error) {
      console.error("Error fetching items: ", error);
      toast({
        title: "Gagal memuat data",
        description: "Terjadi kesalahan saat mengambil data dari server.",
        variant: "destructive",
      })
    } finally {
      setIsLoading(false);
    }
  }
  
  // --- [BARU] Gunakan useEffect untuk memanggil fetchItems saat komponen pertama kali dimuat ---
  useEffect(() => {
    fetchItems();
  }, []);

  const filteredItems = items.filter(
    (item) =>
      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.category.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  // --- [DIUBAH] handleSubmit sekarang berinteraksi dengan Firestore ---
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    const itemData = {
      code: formData.code,
      name: formData.name,
      description: formData.description,
      category: formData.category,
      buyPrice: Number(formData.buyPrice),
      sellPrice: Number(formData.sellPrice),
      stock: Number(formData.stock),
      minStock: Number(formData.minStock),
    };

    try {
      if (editingItem) {
        // Update data
        const itemDoc = doc(db, "items", editingItem.id);
        await updateDoc(itemDoc, itemData);
        toast({ title: "Barang berhasil diperbarui" })
      } else {
        // Tambah data baru
        await addDoc(itemsCollectionRef, { ...itemData, createdAt: serverTimestamp() });
        toast({ title: "Barang berhasil ditambahkan" })
      }
      
      await fetchItems(); // Muat ulang data setelah submit
    } catch (error) {
       console.error("Error submitting item: ", error);
       toast({
        title: "Gagal menyimpan data",
        description: "Terjadi kesalahan saat menyimpan data ke server.",
        variant: "destructive",
      })
    } finally {
      setIsDialogOpen(false)
      setEditingItem(null)
      resetForm()
    }
  }

  const resetForm = () => {
    setFormData({ code: "", name: "", description: "", category: "", buyPrice: "", sellPrice: "", stock: "", minStock: "" })
  }

  const handleEdit = (item: Item) => {
    setEditingItem(item)
    setFormData({
      code: item.code,
      name: item.name,
      description: item.description,
      category: item.category,
      buyPrice: item.buyPrice.toString(),
      sellPrice: item.sellPrice.toString(),
      stock: item.stock.toString(),
      minStock: item.minStock.toString(),
    })
    setIsDialogOpen(true)
  }

  // --- [DIUBAH] handleDelete sekarang menghapus dokumen dari Firestore ---
  const handleDelete = async (id: string) => {
     if (!confirm("Apakah Anda yakin ingin menghapus barang ini?")) {
      return;
    }
    try {
      const itemDoc = doc(db, "items", id);
      await deleteDoc(itemDoc);
      toast({ title: "Barang berhasil dihapus" })
      await fetchItems(); // Muat ulang data
    } catch (error) {
       console.error("Error deleting item: ", error);
       toast({
        title: "Gagal menghapus data",
        description: "Terjadi kesalahan saat menghapus data dari server.",
        variant: "destructive",
      })
    }
  }

  const openAddDialog = () => {
    setEditingItem(null)
    resetForm()
    setIsDialogOpen(true)
  }

  const getStockStatus = (stock: number, minStock: number) => {
    if (stock <= 0) return { text: "Habis", color: "bg-red-100 text-red-800" }
    if (stock <= minStock) return { text: "Rendah", color: "bg-yellow-100 text-yellow-800" }
    return { text: "Aman", color: "bg-green-100 text-green-800" }
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Data Barang</h1>
            <p className="text-gray-600">Kelola data barang dan stok</p>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={openAddDialog}>
                <Plus className="mr-2 h-4 w-4" />
                Tambah Barang
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-2xl">
              <DialogHeader>
                <DialogTitle>{editingItem ? "Edit Barang" : "Tambah Barang Baru"}</DialogTitle>
                <DialogDescription>
                  {editingItem ? "Perbarui informasi barang" : "Masukkan informasi barang baru"}
                </DialogDescription>
              </DialogHeader>
              <form onSubmit={handleSubmit}>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="code">Kode Barang</Label>
                    <Input
                      id="code"
                      value={formData.code}
                      onChange={(e) => setFormData((prev) => ({ ...prev, code: e.target.value }))}
                      required
                    />
                  </div>
                  <div>
                    <Label htmlFor="category">Kategori</Label>
                    <Select
                      value={formData.category}
                      onValueChange={(value) => setFormData((prev) => ({ ...prev, category: value }))}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Pilih kategori" />
                      </SelectTrigger>
                      <SelectContent>
                        {categories.map((category) => (
                          <SelectItem key={category} value={category}>
                            {category}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="col-span-2">
                    <Label htmlFor="name">Nama Barang</Label>
                    <Input
                      id="name"
                      value={formData.name}
                      onChange={(e) => setFormData((prev) => ({ ...prev, name: e.target.value }))}
                      required
                    />
                  </div>
                  <div className="col-span-2">
                    <Label htmlFor="description">Deskripsi</Label>
                    <Textarea
                      id="description"
                      value={formData.description}
                      onChange={(e) => setFormData((prev) => ({ ...prev, description: e.target.value }))}
                      rows={2}
                    />
                  </div>
                  <div>
                    <Label htmlFor="buyPrice">Harga Beli</Label>
                    <Input
                      id="buyPrice"
                      type="number"
                      value={formData.buyPrice}
                      onChange={(e) => setFormData((prev) => ({ ...prev, buyPrice: e.target.value }))}
                      required
                    />
                  </div>
                  <div>
                    <Label htmlFor="sellPrice">Harga Jual</Label>
                    <Input
                      id="sellPrice"
                      type="number"
                      value={formData.sellPrice}
                      onChange={(e) => setFormData((prev) => ({ ...prev, sellPrice: e.target.value }))}
                      required
                    />
                  </div>
                  <div>
                    <Label htmlFor="stock">Stok</Label>
                    <Input
                      id="stock"
                      type="number"
                      value={formData.stock}
                      onChange={(e) => setFormData((prev) => ({ ...prev, stock: e.target.value }))}
                      required
                    />
                  </div>
                  <div>
                    <Label htmlFor="minStock">Stok Minimum</Label>
                    <Input
                      id="minStock"
                      type="number"
                      value={formData.minStock}
                      onChange={(e) => setFormData((prev) => ({ ...prev, minStock: e.target.value }))}
                      required
                    />
                  </div>
                </div>
                <DialogFooter className="mt-6">
                  <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>
                    Batal
                  </Button>
                  <Button type="submit">{editingItem ? "Perbarui" : "Simpan"}</Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Package className="mr-2 h-5 w-5" />
              Daftar Barang
            </CardTitle>
            <CardDescription>Total {items.length} barang terdaftar</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-2 mb-4">
              <Search className="h-4 w-4 text-gray-400" />
              <Input
                placeholder="Cari barang..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="max-w-sm"
              />
            </div>

            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-2">Kode</th>
                    <th className="text-left py-3 px-2">Nama Barang</th>
                    <th className="text-left py-3 px-2">Kategori</th>
                    <th className="text-right py-3 px-2">Harga Beli</th>
                    <th className="text-right py-3 px-2">Harga Jual</th>
                    <th className="text-center py-3 px-2">Stok</th>
                    <th className="text-center py-3 px-2">Status</th>
                    <th className="text-center py-3 px-2">Aksi</th>
                  </tr>
                </thead>
                {/* --- [DIUBAH] Tambahkan logika untuk menampilkan loading state --- */}
                <tbody>
                  {isLoading ? (
                    <tr>
                      <td colSpan={8} className="text-center py-10">
                        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mx-auto"></div>
                        <p className="mt-2 text-gray-500">Memuat data barang...</p>
                      </td>
                    </tr>
                  ) : (
                    filteredItems.map((item) => {
                      const stockStatus = getStockStatus(item.stock, item.minStock)
                      return (
                        <tr key={item.id} className="border-b hover:bg-gray-50">
                          <td className="py-3 px-2 font-mono text-sm">{item.code}</td>
                          <td className="py-3 px-2">
                            <div>
                              <div className="font-medium">{item.name}</div>
                              <div className="text-sm text-gray-500">{item.description}</div>
                            </div>
                          </td>
                          <td className="py-3 px-2 text-sm">{item.category}</td>
                          <td className="py-3 px-2 text-right">Rp {item.buyPrice.toLocaleString("id-ID")}</td>
                          <td className="py-3 px-2 text-right">Rp {item.sellPrice.toLocaleString("id-ID")}</td>
                          <td className="py-3 px-2 text-center">{item.stock}</td>
                          <td className="py-3 px-2 text-center">
                            <span className={`px-2 py-1 rounded-full text-xs font-medium ${stockStatus.color}`}>
                              {stockStatus.text}
                            </span>
                          </td>
                          <td className="py-3 px-2">
                            <div className="flex justify-center space-x-2">
                              <Button variant="outline" size="sm" onClick={() => handleEdit(item)}>
                                <Edit className="h-4 w-4" />
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => handleDelete(item.id)}
                                className="text-red-600 hover:text-red-700"
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </td>
                        </tr>
                      )
                    })
                  )}
                </tbody>
              </table>

              {!isLoading && filteredItems.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  {searchTerm ? "Tidak ada barang yang ditemukan" : "Belum ada barang. Silakan tambahkan."}
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  )
}