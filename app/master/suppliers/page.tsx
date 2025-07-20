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
import { Plus, Edit, Trash2, Search, Truck, Phone, MapPin } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

import { db } from "@/lib/firebase"
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc, serverTimestamp } from "firebase/firestore"

interface Supplier {
  id: string
  name: string
  contact: string
  phone: string
  email: string
  address: string
  createdAt: any
}

export default function SuppliersPage() {
  const [suppliers, setSuppliers] = useState<Supplier[]>([])
  const [isLoading, setIsLoading] = useState(true)

  const [searchTerm, setSearchTerm] = useState("")
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingSupplier, setEditingSupplier] = useState<Supplier | null>(null)
  const [formData, setFormData] = useState({
    name: "",
    contact: "",
    phone: "",
    email: "",
    address: "",
  })
  const { toast } = useToast()

  const suppliersCollectionRef = collection(db, "suppliers");

  const fetchSuppliers = async () => {
    setIsLoading(true);
    try {
        const data = await getDocs(suppliersCollectionRef);
        const fetchedData = data.docs.map((doc) => ({ ...doc.data(), id: doc.id } as Supplier));
        setSuppliers(fetchedData);
    } catch (error) {
        console.error("Error fetching suppliers: ", error);
        toast({ title: "Gagal memuat data", variant: "destructive" });
    } finally {
        setIsLoading(false);
    }
  }

  useEffect(() => {
    fetchSuppliers();
  }, []);

  // --- [DIPERBAIKI] Logika filter dibuat lebih aman ---
  const filteredSuppliers = suppliers.filter(
    (supplier) => {
      const nameMatch = (supplier.name || '').toLowerCase().includes(searchTerm.toLowerCase());
      const contactMatch = (supplier.contact || '').toLowerCase().includes(searchTerm.toLowerCase());
      const phoneMatch = (supplier.phone || '').includes(searchTerm);
      return nameMatch || contactMatch || phoneMatch;
    }
  )

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const supplierData = { ...formData };
    try {
        if (editingSupplier) {
          const supplierDoc = doc(db, "suppliers", editingSupplier.id);
          await updateDoc(supplierDoc, supplierData);
          toast({ title: "Data supplier berhasil diperbarui" })
        } else {
          await addDoc(suppliersCollectionRef, { ...supplierData, createdAt: serverTimestamp() });
          toast({ title: "Supplier berhasil ditambahkan" })
        }
        await fetchSuppliers();
    } catch (error) {
        console.error("Error submitting supplier: ", error);
        toast({ title: "Gagal menyimpan data", variant: "destructive" });
    } finally {
        setIsDialogOpen(false)
        setEditingSupplier(null)
        resetForm()
    }
  }

  const resetForm = () => {
    setFormData({ name: "", contact: "", phone: "", email: "", address: "" })
  }

  const handleEdit = (supplier: Supplier) => {
    setEditingSupplier(supplier)
    setFormData({
      name: supplier.name,
      contact: supplier.contact,
      phone: supplier.phone,
      email: supplier.email,
      address: supplier.address,
    })
    setIsDialogOpen(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm("Apakah Anda yakin ingin menghapus supplier ini?")) return;
    try {
        const supplierDoc = doc(db, "suppliers", id);
        await deleteDoc(supplierDoc);
        toast({ title: "Supplier berhasil dihapus" })
        await fetchSuppliers();
    } catch (error) {
        console.error("Error deleting supplier: ", error);
        toast({ title: "Gagal menghapus data", variant: "destructive" });
    }
  }

  const openAddDialog = () => {
    setEditingSupplier(null)
    resetForm()
    setIsDialogOpen(true)
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Data Supplier</h1>
            <p className="text-gray-600">Kelola data supplier dan pemasok</p>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={openAddDialog}>
                <Plus className="mr-2 h-4 w-4" />
                Tambah Supplier
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>{editingSupplier ? "Edit Supplier" : "Tambah Supplier Baru"}</DialogTitle>
                <DialogDescription>
                  {editingSupplier ? "Perbarui informasi supplier" : "Masukkan informasi supplier baru"}
                </DialogDescription>
              </DialogHeader>
              <form onSubmit={handleSubmit}>
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="name">Nama Perusahaan</Label>
                    <Input
                      id="name"
                      value={formData.name}
                      onChange={(e) => setFormData((prev) => ({ ...prev, name: e.target.value }))}
                      required
                    />
                  </div>
                  <div>
                    <Label htmlFor="contact">Nama Kontak</Label>
                    <Input
                      id="contact"
                      value={formData.contact}
                      onChange={(e) => setFormData((prev) => ({ ...prev, contact: e.target.value }))}
                      required
                    />
                  </div>
                  <div>
                    <Label htmlFor="phone">Nomor Telepon</Label>
                    <Input
                      id="phone"
                      value={formData.phone}
                      onChange={(e) => setFormData((prev) => ({ ...prev, phone: e.target.value }))}
                      required
                    />
                  </div>
                  <div>
                    <Label htmlFor="email">Email</Label>
                    <Input
                      id="email"
                      type="email"
                      value={formData.email}
                      onChange={(e) => setFormData((prev) => ({ ...prev, email: e.target.value }))}
                    />
                  </div>
                  <div>
                    <Label htmlFor="address">Alamat</Label>
                    <Textarea
                      id="address"
                      value={formData.address}
                      onChange={(e) => setFormData((prev) => ({ ...prev, address: e.target.value }))}
                      rows={3}
                    />
                  </div>
                </div>
                <DialogFooter className="mt-6">
                  <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>
                    Batal
                  </Button>
                  <Button type="submit">{editingSupplier ? "Perbarui" : "Simpan"}</Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Truck className="mr-2 h-5 w-5" />
              Daftar Supplier
            </CardTitle>
            <CardDescription>Total {suppliers.length} supplier terdaftar</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-2 mb-4">
              <Search className="h-4 w-4 text-gray-400" />
              <Input
                placeholder="Cari supplier..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="max-w-sm"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {isLoading ? Array.from({ length: 3 }).map((_, index) => (
                  <Card key={index}><CardContent className="p-4 h-52 animate-pulse bg-gray-200 rounded-lg"></CardContent></Card>
              )) : filteredSuppliers.map((supplier) => (
                <Card key={supplier.id} className="hover:shadow-md transition-shadow">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start mb-3">
                      <h3 className="font-semibold text-lg">{supplier.name}</h3>
                      <div className="flex space-x-1">
                        <Button variant="outline" size="sm" onClick={() => handleEdit(supplier)}>
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleDelete(supplier.id)}
                          className="text-red-600 hover:text-red-700"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>

                    <div className="space-y-2 text-sm text-gray-600">
                      <div className="flex items-center">
                        <span className="font-medium mr-2">Kontak:</span>
                        {supplier.contact}
                      </div>
                      <div className="flex items-center">
                        <Phone className="h-4 w-4 mr-2" />
                        {supplier.phone}
                      </div>
                      {supplier.email && (
                        <div className="flex items-center">
                          <span className="h-4 w-4 mr-2">@</span>
                          {supplier.email}
                        </div>
                      )}
                      {supplier.address && (
                        <div className="flex items-start">
                          <MapPin className="h-4 w-4 mr-2 mt-0.5 flex-shrink-0" />
                          <span className="break-words">{supplier.address}</span>
                        </div>
                      )}
                    </div>

                    <div className="mt-3 pt-3 border-t text-xs text-gray-500">
                      Terdaftar: {supplier.createdAt?.toDate().toLocaleDateString("id-ID") || 'N/A'}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>

            {!isLoading && filteredSuppliers.length === 0 && (
              <div className="text-center py-8 text-gray-500">
                {searchTerm ? "Tidak ada supplier yang ditemukan" : "Belum ada supplier"}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  )
}