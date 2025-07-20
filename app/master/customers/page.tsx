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
import { Plus, Edit, Trash2, Search, Users, Phone, MapPin } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

import { db } from "@/lib/firebase"
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc, serverTimestamp } from "firebase/firestore"

interface Customer {
  id: string
  name: string
  phone: string
  email: string
  address: string
  createdAt: any
}

export default function CustomersPage() {
  const [customers, setCustomers] = useState<Customer[]>([])
  const [isLoading, setIsLoading] = useState(true)

  const [searchTerm, setSearchTerm] = useState("")
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingCustomer, setEditingCustomer] = useState<Customer | null>(null)
  const [formData, setFormData] = useState({
    name: "",
    phone: "",
    email: "",
    address: "",
  })
  const { toast } = useToast()
  
  const customersCollectionRef = collection(db, "customers");

  const fetchCustomers = async () => {
      setIsLoading(true);
      try {
          const data = await getDocs(customersCollectionRef);
          const fetchedData = data.docs.map((doc) => ({ ...doc.data(), id: doc.id } as Customer));
          setCustomers(fetchedData);
      } catch (error) {
          console.error("Error fetching customers: ", error);
          toast({ title: "Gagal memuat data", variant: "destructive" });
      } finally {
          setIsLoading(false);
      }
  }

  useEffect(() => {
    fetchCustomers();
  }, []);

  // --- [DIPERBAIKI] Logika filter dibuat lebih aman ---
  const filteredCustomers = customers.filter(
    (customer) => {
      const nameMatch = (customer.name || '').toLowerCase().includes(searchTerm.toLowerCase());
      const phoneMatch = (customer.phone || '').includes(searchTerm);
      const emailMatch = (customer.email || '').toLowerCase().includes(searchTerm.toLowerCase());
      return nameMatch || phoneMatch || emailMatch;
    }
  )

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const customerData = { ...formData };
    try {
        if (editingCustomer) {
          const customerDoc = doc(db, "customers", editingCustomer.id);
          await updateDoc(customerDoc, customerData);
          toast({ title: "Data pelanggan berhasil diperbarui" })
        } else {
          await addDoc(customersCollectionRef, { ...customerData, createdAt: serverTimestamp() });
          toast({ title: "Pelanggan berhasil ditambahkan" })
        }
        await fetchCustomers();
    } catch (error) {
        console.error("Error submitting customer: ", error);
        toast({ title: "Gagal menyimpan data", variant: "destructive" });
    } finally {
        setIsDialogOpen(false)
        setEditingCustomer(null)
        resetForm()
    }
  }

  const resetForm = () => {
    setFormData({ name: "", phone: "", email: "", address: "" })
  }

  const handleEdit = (customer: Customer) => {
    setEditingCustomer(customer)
    setFormData({
      name: customer.name || '',
      phone: customer.phone || '',
      email: customer.email || '',
      address: customer.address || '',
    })
    setIsDialogOpen(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm("Apakah Anda yakin ingin menghapus pelanggan ini?")) return;
    try {
        const customerDoc = doc(db, "customers", id);
        await deleteDoc(customerDoc);
        toast({ title: "Pelanggan berhasil dihapus" })
        await fetchCustomers();
    } catch (error) {
        console.error("Error deleting customer: ", error);
        toast({ title: "Gagal menghapus data", variant: "destructive" });
    }
  }

  const openAddDialog = () => {
    setEditingCustomer(null)
    resetForm()
    setIsDialogOpen(true)
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Data Pelanggan</h1>
            <p className="text-gray-600">Kelola data pelanggan toko</p>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={openAddDialog}>
                <Plus className="mr-2 h-4 w-4" />
                Tambah Pelanggan
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>{editingCustomer ? "Edit Pelanggan" : "Tambah Pelanggan Baru"}</DialogTitle>
                <DialogDescription>
                  {editingCustomer ? "Perbarui informasi pelanggan" : "Masukkan informasi pelanggan baru"}
                </DialogDescription>
              </DialogHeader>
              <form onSubmit={handleSubmit}>
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="name">Nama Lengkap</Label>
                    <Input
                      id="name"
                      value={formData.name}
                      onChange={(e) => setFormData((prev) => ({ ...prev, name: e.target.value }))}
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
                  <Button type="submit">{editingCustomer ? "Perbarui" : "Simpan"}</Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Users className="mr-2 h-5 w-5" />
              Daftar Pelanggan
            </CardTitle>
            <CardDescription>Total {customers.length} pelanggan terdaftar</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-2 mb-4">
              <Search className="h-4 w-4 text-gray-400" />
              <Input
                placeholder="Cari pelanggan..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="max-w-sm"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {isLoading ? Array.from({ length: 3 }).map((_, index) => (
                  <Card key={index}><CardContent className="p-4 h-48 animate-pulse bg-gray-200 rounded-lg"></CardContent></Card>
              )) : filteredCustomers.map((customer) => (
                <Card key={customer.id} className="hover:shadow-md transition-shadow">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start mb-3">
                      <h3 className="font-semibold text-lg">{customer.name}</h3>
                      <div className="flex space-x-1">
                        <Button variant="outline" size="sm" onClick={() => handleEdit(customer)}>
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleDelete(customer.id)}
                          className="text-red-600 hover:text-red-700"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>

                    <div className="space-y-2 text-sm text-gray-600">
                      <div className="flex items-center">
                        <Phone className="h-4 w-4 mr-2" />
                        {customer.phone}
                      </div>
                      {customer.email && (
                        <div className="flex items-center">
                          <span className="h-4 w-4 mr-2">@</span>
                          {customer.email}
                        </div>
                      )}
                      {customer.address && (
                        <div className="flex items-start">
                          <MapPin className="h-4 w-4 mr-2 mt-0.5 flex-shrink-0" />
                          <span className="break-words">{customer.address}</span>
                        </div>
                      )}
                    </div>

                    <div className="mt-3 pt-3 border-t text-xs text-gray-500">
                      Terdaftar: {customer.createdAt?.toDate().toLocaleDateString("id-ID") || 'N/A'}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>

            {!isLoading && filteredCustomers.length === 0 && (
              <div className="text-center py-8 text-gray-500">
                {searchTerm ? "Tidak ada pelanggan yang ditemukan" : "Belum ada pelanggan"}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  )
}
