"use client"

import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent } from "@/components/ui/card"
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
import { Plus, Edit, Trash2, Search, Package, Clock, RefreshCw } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { Badge } from "@/components/ui/badge"

import { db } from "@/lib/firebase"
import { collection, addDoc, updateDoc, deleteDoc, doc, serverTimestamp, onSnapshot, query, orderBy, Unsubscribe } from "firebase/firestore"

interface Category {
  id: string
  name: string
  description: string
  createdAt: any
}

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([])
  const [isLoading, setIsLoading] = useState(true)

  const [searchTerm, setSearchTerm] = useState("")
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingCategory, setEditingCategory] = useState<Category | null>(null)
  const [formData, setFormData] = useState({ name: "", description: "" })
  const { toast } = useToast()

  // Real-time Data Fetching
  useEffect(() => {
    setIsLoading(true);
    const q = query(collection(db, "categories"), orderBy("name"));

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const fetchedCategories = snapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as Category));
      setCategories(fetchedCategories);
      setIsLoading(false);
    }, (error) => {
      console.error("Error fetching categories: ", error);
      toast({ title: "Gagal memuat data", description: "Periksa koneksi internet anda.", variant: "destructive" });
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, [toast]);

  const filteredCategories = categories.filter(
    (category) => {
      const term = searchTerm.toLowerCase();
      return (
        (category.name || '').toLowerCase().includes(term) ||
        (category.description || '').toLowerCase().includes(term)
      );
    }
  )

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData.name.trim()) return;

    const categoryData = {
      name: formData.name,
      description: formData.description,
    };

    try {
      if (editingCategory) {
        const categoryDoc = doc(db, "categories", editingCategory.id);
        await updateDoc(categoryDoc, categoryData);
        toast({ title: "Berhasil!", description: "Kategori telah diperbarui." })
      } else {
        await addDoc(collection(db, "categories"), { ...categoryData, createdAt: serverTimestamp() });
        toast({ title: "Berhasil!", description: "Kategori baru ditambahkan." })
      }
    } catch (error) {
      console.error("Error saving: ", error);
      toast({ title: "Gagal Menyimpan", description: "Terjadi kesalahan sistem.", variant: "destructive" });
    } finally {
      setIsDialogOpen(false)
      setEditingCategory(null)
      setFormData({ name: "", description: "" })
    }
  }

  const handleEdit = (category: Category) => {
    setEditingCategory(category)
    setFormData({ name: category.name, description: category.description })
    setIsDialogOpen(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm("Hapus kategori ini? Data barang yang menggunakan kategori ini mungkin akan terdampak.")) return;
    try {
      await deleteDoc(doc(db, "categories", id));
      toast({ title: "Terhapus", description: "Kategori berhasil dihapus." })
    } catch (error) {
      console.error("Error deleting: ", error);
      toast({ title: "Gagal Hapus", description: "Terjadi kesalahan sistem.", variant: "destructive" });
    }
  }

  const openAddDialog = () => {
    setEditingCategory(null)
    setFormData({ name: "", description: "" })
    setIsDialogOpen(true)
  }

  return (
    <MainLayout>
      <div className="space-y-6 pb-20">
        {/* Header Section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-6 rounded-xl border border-slate-100 shadow-sm">
          <div>
            <h1 className="text-2xl font-bold text-slate-800 flex items-center gap-2">
              <Package className="w-6 h-6 text-blue-600" />
              Kategori Barang
            </h1>
            <p className="text-sm text-slate-500 mt-1">Kelompokkan barang untuk manajemen stok yang lebih rapi.</p>
          </div>

          <div className="flex items-center gap-2 w-full md:w-auto">
            <div className="relative w-full md:w-64">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
              <Input
                placeholder="Cari kategori..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9 bg-slate-50 border-slate-200"
              />
            </div>

            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
              <DialogTrigger asChild>
                <Button onClick={openAddDialog} className="bg-blue-600 hover:bg-blue-700 shadow-lg shadow-blue-200">
                  <Plus className="mr-2 h-4 w-4" /> Baru
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>{editingCategory ? "Edit Kategori" : "Tambah Kategori Baru"}</DialogTitle>
                  <DialogDescription>
                    {editingCategory ? "Ubah detail kategori di bawah ini." : "Buat kategori baru untuk mengelompokkan barang."}
                  </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4 py-4">
                  <div>
                    <Label htmlFor="name" className="text-right">Nama Kategori</Label>
                    <Input
                      id="name"
                      value={formData.name}
                      onChange={(e) => setFormData((prev) => ({ ...prev, name: e.target.value }))}
                      placeholder="Contoh: Oli, Ban, Sparepart..."
                      required
                      className="mt-1"
                    />
                  </div>
                  <div>
                    <Label htmlFor="description" className="text-right">Keterangan (Opsional)</Label>
                    <Textarea
                      id="description"
                      value={formData.description}
                      onChange={(e) => setFormData((prev) => ({ ...prev, description: e.target.value }))}
                      placeholder="Deskripsi singkat kategori ini..."
                      rows={3}
                      className="mt-1"
                    />
                  </div>
                  <DialogFooter>
                    <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>Batal</Button>
                    <Button type="submit" disabled={isLoading} className="bg-blue-600 hover:bg-blue-700">{editingCategory ? "Simpan Perubahan" : "Buat Kategori"}</Button>
                  </DialogFooter>
                </form>
              </DialogContent>
            </Dialog>
          </div>
        </div>

        {/* Content Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {isLoading ? (
            Array.from({ length: 6 }).map((_, i) => (
              <Card key={i} className="h-32 bg-slate-50 animate-pulse border-none shadow-none" />
            ))
          ) : filteredCategories.length === 0 ? (
            <div className="col-span-full py-12 text-center text-slate-400 bg-slate-50/50 rounded-xl border border-dashed">
              <Package className="w-12 h-12 mx-auto mb-3 opacity-20" />
              <p>Tidak ada kategori ditemukan</p>
            </div>
          ) : (
            filteredCategories.map((category) => (
              <Card key={category.id} className="group hover:shadow-md transition-all border-slate-200 hover:border-blue-200 cursor-default">
                <CardContent className="p-5">
                  <div className="flex justify-between items-start mb-3">
                    <div className="p-2 bg-blue-50 text-blue-600 rounded-lg group-hover:bg-blue-600 group-hover:text-white transition-colors">
                      <Package className="w-5 h-5" />
                    </div>
                    <div className="flex space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <Button variant="ghost" size="icon" className="h-8 w-8 text-slate-400 hover:text-blue-600" onClick={() => handleEdit(category)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" className="h-8 w-8 text-slate-400 hover:text-red-600" onClick={() => handleDelete(category.id)}>
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>

                  <h3 className="font-bold text-lg text-slate-800 mb-1">{category.name}</h3>
                  <p className="text-sm text-slate-500 line-clamp-2 h-10 mb-4">{category.description || "Tidak ada deskripsi."}</p>

                  <div className="flex items-center gap-2 text-[10px] text-slate-400 border-t pt-3">
                    <Clock className="w-3 h-3" />
                    <span>Dibuat: {category.createdAt?.toDate ? category.createdAt.toDate().toLocaleDateString("id-ID") : "Baru saja"}</span>
                  </div>
                </CardContent>
              </Card>
            ))
          )}
        </div>
      </div>
    </MainLayout>
  )
}