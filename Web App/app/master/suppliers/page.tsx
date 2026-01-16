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
import { Plus, Edit, Trash2, Search, Truck, Phone, MapPin, Building2, User } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { Badge } from "@/components/ui/badge"

import { db } from "@/lib/firebase"
import { collection, addDoc, updateDoc, deleteDoc, doc, serverTimestamp, onSnapshot, query, orderBy } from "firebase/firestore"

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

  // Real-time Data Fetching
  useEffect(() => {
    setIsLoading(true);
    const q = query(collection(db, "suppliers"), orderBy("name"));

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const fetchedData = snapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as Supplier));
      setSuppliers(fetchedData);
      setIsLoading(false);
    }, (error) => {
      console.error("Error fetching suppliers: ", error);
      toast({ title: "Gagal memuat data", description: "Periksa koneksi internet anda.", variant: "destructive" });
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, [toast]);

  const filteredSuppliers = suppliers.filter(
    (supplier) => {
      const term = searchTerm.toLowerCase();
      return (
        (supplier.name || '').toLowerCase().includes(term) ||
        (supplier.contact || '').toLowerCase().includes(term) ||
        (supplier.phone || '').includes(searchTerm)
      );
    }
  )

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData.name.trim()) return;

    const supplierData = { ...formData };

    try {
      if (editingSupplier) {
        await updateDoc(doc(db, "suppliers", editingSupplier.id), supplierData);
        toast({ title: "Berhasil!", description: "Data supplier diperbarui." })
      } else {
        await addDoc(collection(db, "suppliers"), { ...supplierData, createdAt: serverTimestamp() });
        toast({ title: "Berhasil!", description: "Supplier baru ditambahkan." })
      }
    } catch (error) {
      console.error("Error saving: ", error);
      toast({ title: "Gagal Menyimpan", description: "Terjadi kesalahan sistem.", variant: "destructive" });
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
    if (!confirm("Hapus supplier ini? Pastikan tidak ada tagihan hutang yang belum lunas ke supplier ini.")) return;
    try {
      await deleteDoc(doc(db, "suppliers", id));
      toast({ title: "Terhapus", description: "Data supplier dihapus." })
    } catch (error) {
      console.error("Error deleting: ", error);
      toast({ title: "Gagal Hapus", description: "Terjadi kesalahan sistem.", variant: "destructive" });
    }
  }

  const openAddDialog = () => {
    setEditingSupplier(null)
    resetForm()
    setIsDialogOpen(true)
  }

  return (
    <MainLayout>
      <div className="space-y-6 pb-20">
        {/* Header Section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-6 rounded-xl border border-slate-100 shadow-sm">
          <div>
            <h1 className="text-2xl font-bold text-slate-800 flex items-center gap-2">
              <Truck className="w-6 h-6 text-orange-600" />
              Data Supplier
            </h1>
            <p className="text-sm text-slate-500 mt-1">Kelola daftar pemasok dan distributor barang.</p>
          </div>

          <div className="flex items-center gap-2 w-full md:w-auto">
            <div className="relative w-full md:w-64">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
              <Input
                placeholder="Cari PT / Sales..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9 bg-slate-50 border-slate-200"
              />
            </div>

            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
              <DialogTrigger asChild>
                <Button onClick={openAddDialog} className="bg-orange-600 hover:bg-orange-700 shadow-lg shadow-orange-200">
                  <Plus className="mr-2 h-4 w-4" /> Baru
                </Button>
              </DialogTrigger>
              <DialogContent className="sm:max-w-[500px]">
                <DialogHeader>
                  <DialogTitle>{editingSupplier ? "Edit Supplier" : "Tambah Supplier Baru"}</DialogTitle>
                  <DialogDescription>
                    {editingSupplier ? "Update informasi supplier." : "Masukkan data pemasok baru."}
                  </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4 py-4">
                  <div className="grid gap-2">
                    <Label htmlFor="name">Nama Perusahaan / Toko</Label>
                    <Input id="name" value={formData.name} onChange={(e) => setFormData(p => ({ ...p, name: e.target.value }))} placeholder="PT. Maju Mundur" required maxLength={100} />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="grid gap-2">
                      <Label htmlFor="contact">Nama Sales / PIC</Label>
                      <Input id="contact" value={formData.contact} onChange={(e) => setFormData(p => ({ ...p, contact: e.target.value }))} placeholder="Bpk. Budi" required maxLength={100} />
                    </div>
                    <div className="grid gap-2">
                      <Label htmlFor="phone">No. HP / Telp</Label>
                      <Input id="phone" type="tel" value={formData.phone} onChange={(e) => setFormData(p => ({ ...p, phone: e.target.value.replace(/[^0-9+\-\s]/g, '') }))} placeholder="08xxx" required maxLength={20} />
                    </div>
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="email">Email (Opsional)</Label>
                    <Input id="email" type="email" value={formData.email} onChange={(e) => setFormData(p => ({ ...p, email: e.target.value }))} maxLength={100} placeholder="email@contoh.com" />
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="address">Alamat Kantor / Gudang</Label>
                    <Textarea id="address" value={formData.address} onChange={(e) => setFormData(p => ({ ...p, address: e.target.value }))} rows={2} maxLength={500} placeholder="Maks. 500 karakter" />
                  </div>
                  <DialogFooter>
                    <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>Batal</Button>
                    <Button type="submit" className="bg-orange-600 hover:bg-orange-700">{editingSupplier ? "Simpan Perubahan" : "Simpan Data"}</Button>
                  </DialogFooter>
                </form>
              </DialogContent>
            </Dialog>
          </div>
        </div>

        {/* Suppliers List */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => (
              <Card key={i} className="h-56 bg-slate-50 animate-pulse border-none shadow-none" />
            ))
          ) : filteredSuppliers.length === 0 ? (
            <div className="col-span-full py-12 text-center text-slate-400 bg-slate-50/50 rounded-xl border border-dashed">
              <Truck className="w-12 h-12 mx-auto mb-3 opacity-20" />
              <p>Tidak ada supplier ditemukan</p>
            </div>
          ) : (
            filteredSuppliers.map((supplier) => (
              <Card key={supplier.id} className="group hover:shadow-lg transition-all border-slate-200 hover:border-orange-200 cursor-default">
                <CardContent className="p-5 space-y-4">
                  <div className="flex justify-between items-start">
                    <div className="flex items-center gap-3">
                      <div className="h-10 w-10 flex items-center justify-center bg-orange-50 text-orange-600 rounded-lg">
                        <Building2 className="w-5 h-5" />
                      </div>
                      <div>
                        <h3 className="font-bold text-slate-800 line-clamp-1">{supplier.name}</h3>
                        <Badge variant="secondary" className="text-[10px] px-1.5 h-5 font-normal bg-slate-100 text-slate-500 hover:bg-slate-200">
                          {supplier.contact}
                        </Badge>
                      </div>
                    </div>
                    <div className="flex space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <Button variant="ghost" size="icon" className="h-7 w-7 text-slate-400 hover:text-orange-600" onClick={() => handleEdit(supplier)}>
                        <Edit className="h-3.5 w-3.5" />
                      </Button>
                      <Button variant="ghost" size="icon" className="h-7 w-7 text-slate-400 hover:text-red-600" onClick={() => handleDelete(supplier.id)}>
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </div>
                  </div>

                  <div className="space-y-2 text-sm pt-2 border-t border-slate-50">
                    <div className="flex items-center gap-3 text-slate-600">
                      <Phone className="w-4 h-4 text-slate-400" />
                      <span className="font-medium">{supplier.phone}</span>
                    </div>
                    <div className="flex items-start gap-3 text-slate-600">
                      <MapPin className="w-4 h-4 text-slate-400 mt-0.5 shrink-0" />
                      <span className="line-clamp-2 text-xs leading-relaxed text-slate-500">
                        {supplier.address || "Alamat belum dilengkapi"}
                      </span>
                    </div>
                  </div>

                  <div className="pt-2 text-[10px] text-slate-400 flex items-center gap-1 justify-end">
                    <User className="w-3 h-3" />
                    <span>PIC: {supplier.contact}</span>
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