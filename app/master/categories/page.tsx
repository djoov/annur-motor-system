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
import { Plus, Edit, Trash2, Search } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

import { db } from "@/lib/firebase"
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc, serverTimestamp } from "firebase/firestore"

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

  const categoriesCollectionRef = collection(db, "categories");

  const fetchCategories = async () => {
    setIsLoading(true);
    try {
      const data = await getDocs(categoriesCollectionRef);
      const fetchedCategories = data.docs.map((doc) => ({ ...doc.data(), id: doc.id } as Category));
      setCategories(fetchedCategories);
    } catch (error) {
      console.error("Error fetching categories: ", error);
      toast({ title: "Gagal memuat data", variant: "destructive" });
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    fetchCategories();
  }, []);

  // --- [DIPERBAIKI] Logika filter dibuat lebih aman ---
  const filteredCategories = categories.filter(
    (category) => {
      const nameMatch = (category.name || '').toLowerCase().includes(searchTerm.toLowerCase());
      const descriptionMatch = (category.description || '').toLowerCase().includes(searchTerm.toLowerCase());
      return nameMatch || descriptionMatch;
    }
  )

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const categoryData = {
        name: formData.name,
        description: formData.description,
    };
    try {
        if (editingCategory) {
          const categoryDoc = doc(db, "categories", editingCategory.id);
          await updateDoc(categoryDoc, categoryData);
          toast({ title: "Kategori berhasil diperbarui" })
        } else {
          await addDoc(categoriesCollectionRef, { ...categoryData, createdAt: serverTimestamp() });
          toast({ title: "Kategori berhasil ditambahkan" })
        }
        await fetchCategories();
    } catch (error) {
        console.error("Error submitting category: ", error);
        toast({ title: "Gagal menyimpan data", variant: "destructive" });
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
    if (!confirm("Apakah Anda yakin ingin menghapus kategori ini?")) return;
    try {
        const categoryDoc = doc(db, "categories", id);
        await deleteDoc(categoryDoc);
        toast({ title: "Kategori berhasil dihapus" })
        await fetchCategories();
    } catch (error) {
        console.error("Error deleting category: ", error);
        toast({ title: "Gagal menghapus data", variant: "destructive" });
    }
  }

  const openAddDialog = () => {
    setEditingCategory(null)
    setFormData({ name: "", description: "" })
    setIsDialogOpen(true)
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Kategori Barang</h1>
            <p className="text-gray-600">Kelola kategori barang di toko</p>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={openAddDialog}>
                <Plus className="mr-2 h-4 w-4" />
                Tambah Kategori
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>{editingCategory ? "Edit Kategori" : "Tambah Kategori Baru"}</DialogTitle>
                <DialogDescription>
                  {editingCategory ? "Perbarui informasi kategori" : "Masukkan informasi kategori baru"}
                </DialogDescription>
              </DialogHeader>
              <form onSubmit={handleSubmit}>
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="name">Nama Kategori</Label>
                    <Input
                      id="name"
                      value={formData.name}
                      onChange={(e) => setFormData((prev) => ({ ...prev, name: e.target.value }))}
                      required
                    />
                  </div>
                  <div>
                    <Label htmlFor="description">Deskripsi</Label>
                    <Textarea
                      id="description"
                      value={formData.description}
                      onChange={(e) => setFormData((prev) => ({ ...prev, description: e.target.value }))}
                      rows={3}
                    />
                  </div>
                </div>
                <DialogFooter className="mt-6">
                  <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>
                    Batal
                  </Button>
                  <Button type="submit">{editingCategory ? "Perbarui" : "Simpan"}</Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Daftar Kategori</CardTitle>
            <CardDescription>Total {categories.length} kategori terdaftar</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-2 mb-4">
              <Search className="h-4 w-4 text-gray-400" />
              <Input
                placeholder="Cari kategori..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="max-w-sm"
              />
            </div>

            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-2">Nama Kategori</th>
                    <th className="text-left py-3 px-2">Deskripsi</th>
                    <th className="text-left py-3 px-2">Tanggal Dibuat</th>
                    <th className="text-center py-3 px-2">Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                     <tr><td colSpan={4} className="text-center py-10">Memuat data...</td></tr>
                  ) : filteredCategories.map((category) => (
                    <tr key={category.id} className="border-b hover:bg-gray-50">
                      <td className="py-3 px-2 font-medium">{category.name}</td>
                      <td className="py-3 px-2 text-gray-600">{category.description}</td>
                      <td className="py-3 px-2 text-gray-500">
                        {category.createdAt?.toDate().toLocaleDateString("id-ID") || 'N/A'}
                      </td>
                      <td className="py-3 px-2">
                        <div className="flex justify-center space-x-2">
                          <Button variant="outline" size="sm" onClick={() => handleEdit(category)}>
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleDelete(category.id)}
                            className="text-red-600 hover:text-red-700"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {!isLoading && filteredCategories.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  {searchTerm ? "Tidak ada kategori yang ditemukan" : "Belum ada kategori"}
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  )
}