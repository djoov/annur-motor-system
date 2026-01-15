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
import { Plus, Edit, Trash2, Search, Users, Phone, MapPin, Mail, User } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

import { db } from "@/lib/firebase"
import { collection, addDoc, updateDoc, deleteDoc, doc, serverTimestamp, onSnapshot, query, orderBy } from "firebase/firestore"

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

  // Real-time Data Fetching
  useEffect(() => {
    setIsLoading(true);
    const q = query(collection(db, "customers"), orderBy("name"));

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const fetchedData = snapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as Customer));
      setCustomers(fetchedData);
      setIsLoading(false);
    }, (error) => {
      console.error("Error fetching customers: ", error);
      toast({ title: "Gagal memuat data", description: "Periksa koneksi internet anda.", variant: "destructive" });
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, [toast]);

  const filteredCustomers = customers.filter(
    (customer) => {
      const term = searchTerm.toLowerCase();
      return (
        (customer.name || '').toLowerCase().includes(term) ||
        (customer.phone || '').includes(searchTerm) ||
        (customer.email || '').toLowerCase().includes(term)
      );
    }
  )

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData.name.trim()) return;

    const customerData = { ...formData };

    try {
      if (editingCustomer) {
        await updateDoc(doc(db, "customers", editingCustomer.id), customerData);
        toast({ title: "Berhasil!", description: "Data pelanggan diperbarui." })
      } else {
        await addDoc(collection(db, "customers"), { ...customerData, createdAt: serverTimestamp() });
        toast({ title: "Berhasil!", description: "Pelanggan baru ditambahkan." })
      }
    } catch (error) {
      console.error("Error saving: ", error);
      toast({ title: "Gagal Menyimpan", description: "Terjadi kesalahan sistem.", variant: "destructive" });
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
    if (!confirm("Hapus data pelanggan ini? riwayat transaksi mungkin tetap ada namun nama akan hilang.")) return;
    try {
      await deleteDoc(doc(db, "customers", id));
      toast({ title: "Terhapus", description: "Data pelanggan dihapus." })
    } catch (error) {
      console.error("Error deleting: ", error);
      toast({ title: "Gagal Hapus", description: "Terjadi kesalahan sistem.", variant: "destructive" });
    }
  }

  const openAddDialog = () => {
    setEditingCustomer(null)
    resetForm()
    setIsDialogOpen(true)
  }

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map((n) => n[0])
      .slice(0, 2)
      .join('')
      .toUpperCase();
  }

  return (
    <MainLayout>
      <div className="space-y-6 pb-20">
        {/* Header Section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-6 rounded-xl border border-slate-100 shadow-sm">
          <div>
            <h1 className="text-2xl font-bold text-slate-800 flex items-center gap-2">
              <Users className="w-6 h-6 text-indigo-600" />
              Data Pelanggan
            </h1>
            <p className="text-sm text-slate-500 mt-1">Kelola data member dan pelanggan setia toko.</p>
          </div>

          <div className="flex items-center gap-2 w-full md:w-auto">
            <div className="relative w-full md:w-64">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
              <Input
                placeholder="Cari nama / HP..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9 bg-slate-50 border-slate-200"
              />
            </div>

            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
              <DialogTrigger asChild>
                <Button onClick={openAddDialog} className="bg-indigo-600 hover:bg-indigo-700 shadow-lg shadow-indigo-200">
                  <Plus className="mr-2 h-4 w-4" /> Baru
                </Button>
              </DialogTrigger>
              <DialogContent className="sm:max-w-[425px]">
                <DialogHeader>
                  <DialogTitle>{editingCustomer ? "Edit Pelanggan" : "Tambah Pelanggan Baru"}</DialogTitle>
                  <DialogDescription>
                    {editingCustomer ? "Update data pelanggan." : "Masukkan biodata pelanggan baru."}
                  </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4 py-4">
                  <div className="grid gap-2">
                    <Label htmlFor="name">Nama Lengkap</Label>
                    <Input id="name" value={formData.name} onChange={(e) => setFormData(p => ({ ...p, name: e.target.value }))} required />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="grid gap-2">
                      <Label htmlFor="phone">No. HP / WA</Label>
                      <Input id="phone" value={formData.phone} onChange={(e) => setFormData(p => ({ ...p, phone: e.target.value }))} required />
                    </div>
                    <div className="grid gap-2">
                      <Label htmlFor="email">Email (Opsional)</Label>
                      <Input id="email" type="email" value={formData.email} onChange={(e) => setFormData(p => ({ ...p, email: e.target.value }))} />
                    </div>
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="address">Alamat Domisili</Label>
                    <Textarea id="address" value={formData.address} onChange={(e) => setFormData(p => ({ ...p, address: e.target.value }))} rows={3} />
                  </div>
                  <DialogFooter>
                    <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>Batal</Button>
                    <Button type="submit" className="bg-indigo-600 hover:bg-indigo-700">{editingCustomer ? "Simpan Perubahan" : "Simpan Data"}</Button>
                  </DialogFooter>
                </form>
              </DialogContent>
            </Dialog>
          </div>
        </div>

        {/* Customer Content */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {isLoading ? (
            Array.from({ length: 6 }).map((_, i) => (
              <Card key={i} className="h-48 bg-slate-50 animate-pulse border-none shadow-none" />
            ))
          ) : filteredCustomers.length === 0 ? (
            <div className="col-span-full py-12 text-center text-slate-400 bg-slate-50/50 rounded-xl border border-dashed">
              <Users className="w-12 h-12 mx-auto mb-3 opacity-20" />
              <p>Tidak ada data pelanggan ditemukan</p>
            </div>
          ) : (
            filteredCustomers.map((customer) => (
              <Card key={customer.id} className="group hover:shadow-lg transition-all border-slate-200 hover:border-indigo-200 cursor-default overflow-hidden relative">
                {/* Action Buttons (Absolute Top Right) */}
                <div className="absolute top-3 right-3 flex space-x-1 opacity-0 group-hover:opacity-100 transition-opacity bg-white/80 p-1 rounded-lg backdrop-blur-sm z-10">
                  <Button variant="ghost" size="icon" className="h-7 w-7 text-slate-400 hover:text-indigo-600" onClick={() => handleEdit(customer)}>
                    <Edit className="h-3.5 w-3.5" />
                  </Button>
                  <Button variant="ghost" size="icon" className="h-7 w-7 text-slate-400 hover:text-red-600" onClick={() => handleDelete(customer.id)}>
                    <Trash2 className="h-3.5 w-3.5" />
                  </Button>
                </div>

                <CardContent className="p-0">
                  <div className="p-5 flex items-start gap-4">
                    <Avatar className="h-12 w-12 border-2 border-white shadow-sm">
                      <AvatarFallback className="bg-indigo-50 text-indigo-600 font-bold">
                        {getInitials(customer.name)}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex-1 min-w-0 pt-1">
                      <h3 className="font-bold text-slate-800 truncate">{customer.name}</h3>
                      <p className="text-xs text-slate-500 flex items-center mt-1">
                        <Clock className="w-3 h-3 mr-1" />
                        Sejak {customer.createdAt?.toDate ? customer.createdAt.toDate().toLocaleDateString("id-ID", { month: 'short', year: 'numeric' }) : "-"}
                      </p>
                    </div>
                  </div>

                  <div className="px-5 pb-5 space-y-3">
                    <div className="flex items-center gap-3 text-sm text-slate-600 bg-slate-50 p-2 rounded-lg">
                      <Phone className="w-4 h-4 text-indigo-400" />
                      <span className="font-medium">{customer.phone}</span>
                    </div>
                    {customer.email && (
                      <div className="flex items-center gap-3 text-sm text-slate-600 px-2">
                        <Mail className="w-4 h-4 text-slate-400" />
                        <span className="truncate">{customer.email}</span>
                      </div>
                    )}
                    <div className="flex items-start gap-3 text-sm text-slate-600 px-2">
                      <MapPin className="w-4 h-4 text-slate-400 mt-0.5 shrink-0" />
                      <span className="line-clamp-2 text-xs leading-relaxed">
                        {customer.address || "Alamat belum dilengkapi."}
                      </span>
                    </div>
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

function Clock({ className }: { className?: string }) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>
  )
}
