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
import { Plus, Edit, Trash2, Search, Package, UploadCloud, X } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { db } from "@/lib/firebase"
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc, serverTimestamp } from "firebase/firestore"

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
  imageUrl?: string
  barcode?: string
  createdAt: any
}

interface Category {
    id: string;
    name: string;
}

export default function ItemsPage() {
  const [items, setItems] = useState<Item[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const [searchTerm, setSearchTerm] = useState("")
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingItem, setEditingItem] = useState<Item | null>(null)
  const [formData, setFormData] = useState({ code: "", name: "", description: "", category: "", buyPrice: "", sellPrice: "", stock: "", minStock: "", barcode: "" })
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const [imageBase64, setImageBase64] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const { toast } = useToast()

  const itemsCollectionRef = collection(db, "items")
  const fetchItems = async () => fetchData()

  const fetchData = async () => {
    setIsLoading(true)
    try {
        const itemsSnapshot = await getDocs(collection(db, "items"))
        const categoriesSnapshot = await getDocs(collection(db, "categories"))

        const fetchedItems = itemsSnapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as Item))
        const fetchedCategories = categoriesSnapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as Category))

        setItems(fetchedItems)
        setCategories(fetchedCategories)
    } catch (error: any) {
        console.error("Gagal mengambil data:", error)
        toast({ title: "Gagal Memuat Data", description: error.message, variant: "destructive" })
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
  const aHasCat = a.category ? 1 : 0
  const bHasCat = b.category ? 1 : 0
  // 1) Barang dengan kategori (1) datang sebelum tanpa kategori (0)
  if (aHasCat !== bHasCat) return bHasCat - aHasCat
  // 2) Urutkan menurut nama kategori
  if (a.category !== b.category) {
    return a.category.localeCompare(b.category)
  }
  // 3) Kalau sama kategori, urutkan menurut nama barang
  return a.name.localeCompare(b.name)
})

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0]
      if (file) {
          if (!file.type.startsWith("image/")) {
              toast({ title: "File harus berupa gambar", variant: "destructive" })
              return
          }
          if (file.size > 500 * 1024) {
              toast({ title: "Ukuran file terlalu besar", description: "Maksimal 500KB untuk metode ini.", variant: "destructive" })
              return
          }
          const reader = new FileReader()
          reader.onloadend = () => {
              setImageBase64(reader.result as string)
          }
          reader.readAsDataURL(file)
      }
  }

  const resetForm = () => {
    setFormData({ code: "", name: "", description: "", category: "", buyPrice: "", sellPrice: "", stock: "", minStock: "", barcode: "" })
    setImageBase64(null)
    setEditingItem(null)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isSaving) return
    setIsSaving(true)

    try {
        const imageUrl = imageBase64 || editingItem?.imageUrl || ''
        const itemData = {
          code: formData.code, name: formData.name, description: formData.description, category: formData.category,
          buyPrice: Number(formData.buyPrice), sellPrice: Number(formData.sellPrice), stock: Number(formData.stock),
          minStock: Number(formData.minStock), barcode: formData.barcode, imageUrl,
        }

        if (editingItem) {
          const itemDoc = doc(db, "items", editingItem.id)
          await updateDoc(itemDoc, itemData)
          toast({ title: "Barang berhasil diperbarui" })
        } else {
          await addDoc(itemsCollectionRef, { ...itemData, createdAt: serverTimestamp() })
          toast({ title: "Barang berhasil ditambahkan" })
        }
        
        await fetchItems()
        setIsDialogOpen(false)
        resetForm()

    } catch (error: any) {
        console.error("Gagal menyimpan barang:", error)
        toast({ title: "Gagal Menyimpan", description: `Terjadi kesalahan: ${error.message}`, variant: "destructive" })
    } finally {
        setIsSaving(false)
    }
  }

  const handleEdit = (item: Item) => {
    setEditingItem(item)
    setFormData({
      code: item.code || '', name: item.name || '', description: item.description || '', category: item.category || '',
      buyPrice: (item.buyPrice || 0).toString(), sellPrice: (item.sellPrice || 0).toString(),
      stock: (item.stock || 0).toString(), minStock: (item.minStock || 0).toString(), barcode: item.barcode || '',
    })
    setImageBase64(item.imageUrl || null)
    setIsDialogOpen(true)
  }

  const handleDelete = async (id: string) => {
     if (!confirm("Apakah Anda yakin ingin menghapus barang ini?")) return
    await deleteDoc(doc(db, "items", id))
    toast({ title: "Barang berhasil dihapus" })
    await fetchItems()
  }
  
  const handleDialogChange = (open: boolean) => {
      if (!open) {
          resetForm()
          setIsSaving(false)
      }
      setIsDialogOpen(open)
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Data Barang</h1>
            <p className="text-gray-600">Kelola data barang, stok, dan gambar produk.</p>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={handleDialogChange}>
            <DialogTrigger asChild>
              <Button onClick={() => setIsDialogOpen(true)}>
                <Plus className="mr-2 h-4 w-4" />
                Tambah Barang
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-3xl">
              <DialogHeader>
                <DialogTitle>{editingItem ? "Edit Barang" : "Tambah Barang Baru"}</DialogTitle>
              </DialogHeader>
              <form onSubmit={handleSubmit}>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 py-4">
                  <div className="md:col-span-1 flex flex-col items-center">
                      <Label className="mb-2 self-start">Gambar Produk</Label>
                      <div 
                        className="flex justify-center items-center w-full h-48 border-2 border-dashed rounded-md cursor-pointer bg-gray-50 hover:bg-gray-100"
                        onClick={() => fileInputRef.current?.click()}
                      >
                        {imageBase64 ? (
                            <div className="relative w-full h-full">
                                <Image src={imageBase64} alt="Preview" layout="fill" objectFit="contain" className="rounded-md" />
                                <Button variant="destructive" size="icon" className="absolute top-1 right-1 h-7 w-7 z-10" onClick={(e) => { e.stopPropagation(); setImageBase64(null); if(fileInputRef.current) fileInputRef.current.value = ""; }}>
                                    <X size={16}/>
                                </Button>
                            </div>
                        ) : (
                            <div className="text-center text-gray-500">
                                <UploadCloud className="mx-auto h-12 w-12"/>
                                <p className="text-sm mt-2">Klik untuk mengunggah</p>
                            </div>
                        )}
                      </div>
                      <Input type="file" ref={fileInputRef} className="hidden" onChange={handleFileChange} accept="image/*"/>
                  </div>
                  <div className="md:col-span-2 grid grid-cols-2 gap-4">
                    <div className="col-span-2">
                        <Label htmlFor="barcode">Barcode</Label>
                        <Input id="barcode" placeholder="Scan atau ketik manual..." value={formData.barcode} onChange={(e) => setFormData((prev) => ({ ...prev, barcode: e.target.value }))} />
                    </div>
                    <div>
                        <Label htmlFor="code">Kode Barang</Label>
                        <Input id="code" value={formData.code} onChange={(e) => setFormData((prev) => ({ ...prev, code: e.target.value }))} required />
                    </div>
                    <div>
                        <Label htmlFor="category">Kategori</Label>
                        <Select value={formData.category} onValueChange={(value) => setFormData((prev) => ({ ...prev, category: value }))}>
                          <SelectTrigger><SelectValue placeholder="Pilih kategori" /></SelectTrigger>
                          <SelectContent>
                            {categories.map((c) => <SelectItem key={c.id} value={c.name}>{c.name}</SelectItem>)}
                          </SelectContent>
                        </Select>
                    </div>
                    <div className="col-span-2">
                        <Label htmlFor="name">Nama Barang</Label>
                        <Input id="name" value={formData.name} onChange={(e) => setFormData((prev) => ({ ...prev, name: e.target.value }))} required />
                    </div>
                    <div className="col-span-2">
                        <Label htmlFor="description">Deskripsi</Label>
                        <Textarea id="description" value={formData.description} onChange={(e) => setFormData((prev) => ({ ...prev, description: e.target.value }))} rows={2} />
                    </div>
                    <div>
                        <Label htmlFor="buyPrice">Harga Beli</Label>
                        <Input id="buyPrice" type="number" value={formData.buyPrice} onChange={(e) => setFormData((prev) => ({ ...prev, buyPrice: e.target.value }))} required />
                    </div>
                    <div>
                        <Label htmlFor="sellPrice">Harga Jual</Label>
                        <Input id="sellPrice" type="number" value={formData.sellPrice} onChange={(e) => setFormData((prev) => ({ ...prev, sellPrice: e.target.value }))} required />
                    </div>
                    <div>
                        <Label htmlFor="stock">Stok</Label>
                        <Input id="stock" type="number" value={formData.stock} onChange={(e) => setFormData((prev) => ({ ...prev, stock: e.target.value }))} required />
                    </div>
                    <div>
                        <Label htmlFor="minStock">Stok Minimum</Label>
                        <Input id="minStock" type="number" value={formData.minStock} onChange={(e) => setFormData((prev) => ({ ...prev, minStock: e.target.value }))} required />
                    </div>
                  </div>
                </div>
                <DialogFooter className="mt-6">
                  <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)} disabled={isSaving}>Batal</Button>
                  <Button type="submit" disabled={isSaving}>
                    {isSaving ? "Menyimpan..." : (editingItem ? "Perbarui" : "Simpan")}
                  </Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center"><Package className="mr-2 h-5 w-5" />Daftar Barang</CardTitle>
            <CardDescription>Total {items.length} barang terdaftar</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-2 mb-4">
              <Search className="h-4 w-4 text-gray-400" />
              <Input placeholder="Cari barang..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} className="max-w-sm" />
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-2 w-16">Gambar</th>
                    <th className="text-left py-3 px-2">Kode</th>
                    <th className="text-left py-3 px-2">Nama Barang</th>
                    <th className="text-right py-3 px-2">Harga Jual</th>
                    <th className="text-center py-3 px-2">Stok</th>
                    <th className="text-center py-3 px-2">Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (<tr><td colSpan={6} className="text-center p-4">Memuat...</td></tr>) : sortedItems.map((item) => (
                    <tr key={item.id} className="border-b hover:bg-gray-50">
                      <td className="py-2 px-2">
                        <div className="h-12 w-12 relative bg-gray-100 rounded-md flex items-center justify-center">
                          {item.imageUrl ? (
                            <Image src={item.imageUrl} alt={item.name} layout="fill" objectFit="cover" className="rounded-md" />
                          ) : (
                            <Package size={24} className="text-gray-400"/>
                          )}
                        </div>
                      </td>
                      <td className="py-3 px-2 font-mono text-sm">{item.code}</td>
                      <td className="py-3 px-2 font-medium">{item.name}</td>
                      <td className="py-3 px-2 text-right">Rp {(item.sellPrice || 0).toLocaleString("id-ID")}</td>
                      <td className="py-3 px-2 text-center">{item.stock}</td>
                      <td className="py-3 px-2">
                        <div className="flex justify-center space-x-2">
                          <Button variant="outline" size="sm" onClick={() => handleEdit(item)}><Edit className="h-4 w-4" /></Button>
                          <Button variant="outline" size="sm" onClick={() => handleDelete(item.id)} className="text-red-600 hover:text-red-700"><Trash2 className="h-4 w-4" /></Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  )
}
