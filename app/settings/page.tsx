"use client"

import type React from "react"
import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Store, Printer, Users, Plus, Edit, Trash2 } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { useAuth } from "@/components/auth-provider"

// --- Impor dari Firebase ---
import { db } from "@/lib/firebase"
import { doc, getDoc, setDoc, collection, getDocs, addDoc, updateDoc, deleteDoc, serverTimestamp } from "firebase/firestore"

// --- Interface untuk data ---
interface StoreSettings {
  name: string
  npwp: string
  address: string
  city: string
  province: string
  phone: string
  email: string
}

interface PrinterSettings {
  printerBrand: string
  printerPort: string
  paperWidth: string
  showLogo: boolean
  headerText: string
  footerText: string
}

interface UserData {
  id: string
  name: string
  email: string
  role: "admin" | "staff"
}

export default function SettingsPage() {
  const { user } = useAuth()
  const { toast } = useToast()
  
  // State untuk setiap tab
  const [storeSettings, setStoreSettings] = useState<StoreSettings>({ name: '', npwp: '', address: '', city: '', province: '', phone: '', email: '' });
  const [printerSettings, setPrinterSettings] = useState<PrinterSettings>({ printerBrand: '', printerPort: '', paperWidth: '80mm', showLogo: true, headerText: '', footerText: '' });
  const [users, setUsers] = useState<UserData[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // State untuk dialog manajemen user
  const [isUserDialogOpen, setIsUserDialogOpen] = useState(false)
  const [editingUser, setEditingUser] = useState<UserData | null>(null)
  const [userForm, setUserForm] = useState({ name: '', email: '', role: 'staff' as 'admin' | 'staff' });

  // --- [BARU] Fungsi Fetch Data dari Firestore ---
  useEffect(() => {
    const fetchSettings = async () => {
      // Ambil data toko & printer dari satu dokumen
      const settingsDocRef = doc(db, "settings", "storeConfig");
      const settingsDoc = await getDoc(settingsDocRef);
      if (settingsDoc.exists()) {
        const data = settingsDoc.data();
        setStoreSettings({
          name: data.name || '',
          npwp: data.npwp || '',
          address: data.address || '',
          city: data.city || '',
          province: data.province || '',
          phone: data.phone || '',
          email: data.email || '',
        });
        setPrinterSettings({
          printerBrand: data.printerBrand || '',
          printerPort: data.printerPort || '',
          paperWidth: data.paperWidth || '80mm',
          showLogo: data.showLogo === true,
          headerText: data.headerText || '',
          footerText: data.footerText || '',
        });
      }

      // Ambil data pengguna dari koleksi 'users'
      const usersCollectionRef = collection(db, "users");
      const usersSnapshot = await getDocs(usersCollectionRef);
      const usersList = usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as UserData));
      setUsers(usersList);

      setIsLoading(false);
    }
    fetchSettings();
  }, []);

  // --- [BARU] Handler untuk menyimpan data ke Firestore ---
  const handleSettingsSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const settingsDocRef = doc(db, "settings", "storeConfig");
      // Gabungkan kedua state untuk disimpan dalam satu dokumen
      await setDoc(settingsDocRef, { ...storeSettings, ...printerSettings }, { merge: true });
      toast({ title: 'Pengaturan berhasil disimpan' });
    } catch (error) {
      console.error("Error saving settings: ", error);
      toast({ title: 'Gagal menyimpan pengaturan', variant: 'destructive' });
    }
  }
  
  // Catatan: Fungsi tambah, edit, hapus user memerlukan hak akses yang lebih tinggi (via Cloud Functions)
  // untuk membuat user di Firebase Authentication. Kode di bawah ini hanya mengelola data di Firestore.
  const handleUserSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if(editingUser) {
        const userDoc = doc(db, "users", editingUser.id);
        await updateDoc(userDoc, {
          name: userForm.name,
          email: userForm.email,
          role: userForm.role,
        });
        toast({ title: 'Pengguna berhasil diperbarui'});
      } else {
        // Logika untuk menambah user baru di Firestore.
        // PENTING: Ini tidak membuat user bisa login. Perlu Cloud Function untuk itu.
        await addDoc(collection(db, "users"), {
           name: userForm.name,
           email: userForm.email,
           role: userForm.role,
           createdAt: serverTimestamp(),
        });
        toast({ title: 'Data pengguna ditambahkan ke Firestore'});
      }
      // Refresh user list
      const usersSnapshot = await getDocs(collection(db, "users"));
      setUsers(usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as UserData)));
    } catch (error) {
      console.error("Error submitting user:", error);
      toast({ title: 'Gagal memproses data pengguna', variant: 'destructive' });
    } finally {
       setIsUserDialogOpen(false);
    }
  }
  
  const handleEditUser = (user: UserData) => {
    setEditingUser(user);
    setUserForm({ name: user.name, email: user.email, role: user.role });
    setIsUserDialogOpen(true);
  }

  const handleDeleteUser = async (id: string) => {
    if(id === user?.id) {
        toast({title: "Tidak dapat menghapus akun sendiri", variant: "destructive"});
        return;
    }
    if(confirm("Yakin ingin menghapus pengguna ini? Ini hanya akan menghapus data dari Firestore.")) {
        await deleteDoc(doc(db, "users", id));
        toast({title: "Pengguna dihapus dari Firestore"});
        setUsers(users.filter(u => u.id !== id));
    }
  }


  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Pengaturan Sistem</h1>
          <p className="text-gray-600">Konfigurasi sistem dan pengaturan toko</p>
        </div>

        <Tabs defaultValue="store" className="space-y-6">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="store" className="flex items-center gap-2"><Store className="h-4 w-4" />Data Toko</TabsTrigger>
            <TabsTrigger value="printer" className="flex items-center gap-2"><Printer className="h-4 w-4" />Printer & Struk</TabsTrigger>
            <TabsTrigger value="users" className="flex items-center gap-2"><Users className="h-4 w-4" />Pengguna</TabsTrigger>
          </TabsList>

          {/* Store Settings Tab */}
          <TabsContent value="store">
            <Card>
              <CardHeader>
                <CardTitle>Informasi Toko</CardTitle>
                <CardDescription>Pengaturan informasi dasar mengenai toko Anda.</CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleSettingsSubmit} className="space-y-4 max-w-2xl">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <Label htmlFor="storeName">Nama Toko</Label>
                            <Input id="storeName" value={storeSettings.name} onChange={(e) => setStoreSettings({...storeSettings, name: e.target.value})}/>
                        </div>
                        <div>
                            <Label htmlFor="npwp">NPWP</Label>
                            <Input id="npwp" value={storeSettings.npwp} onChange={(e) => setStoreSettings({...storeSettings, npwp: e.target.value})}/>
                        </div>
                        <div className="col-span-2">
                            <Label htmlFor="address">Alamat</Label>
                            <Textarea id="address" value={storeSettings.address} onChange={(e) => setStoreSettings({...storeSettings, address: e.target.value})}/>
                        </div>
                         <div>
                            <Label htmlFor="city">Kota</Label>
                            <Input id="city" value={storeSettings.city} onChange={(e) => setStoreSettings({...storeSettings, city: e.target.value})}/>
                        </div>
                         <div>
                            <Label htmlFor="province">Provinsi</Label>
                            <Input id="province" value={storeSettings.province} onChange={(e) => setStoreSettings({...storeSettings, province: e.target.value})}/>
                        </div>
                         <div>
                            <Label htmlFor="phone">Telepon</Label>
                            <Input id="phone" value={storeSettings.phone} onChange={(e) => setStoreSettings({...storeSettings, phone: e.target.value})}/>
                        </div>
                         <div>
                            <Label htmlFor="email">Email</Label>
                            <Input id="email" type="email" value={storeSettings.email} onChange={(e) => setStoreSettings({...storeSettings, email: e.target.value})}/>
                        </div>
                    </div>
                    <Button type="submit">Simpan Perubahan</Button>
                </form>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Printer Settings Tab */}
          <TabsContent value="printer">
            <Card>
              <CardHeader>
                <CardTitle>Pengaturan Printer</CardTitle>
                <CardDescription>Konfigurasi printer kasir dan format struk belanja.</CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleSettingsSubmit} className="space-y-4 max-w-2xl">
                    <div className="flex items-center space-x-2">
                        <Switch id="show-logo" checked={printerSettings.showLogo} onCheckedChange={(checked) => setPrinterSettings(prev => ({ ...prev, showLogo: checked }))}/>
                        <Label htmlFor="show-logo">Tampilkan logo pada struk</Label>
                    </div>
                     <div>
                        <Label htmlFor="headerText">Teks Header Struk</Label>
                        <Textarea id="headerText" value={printerSettings.headerText} onChange={(e) => setPrinterSettings({...printerSettings, headerText: e.target.value})}/>
                    </div>
                     <div>
                        <Label htmlFor="footerText">Teks Footer Struk</Label>
                        <Textarea id="footerText" value={printerSettings.footerText} onChange={(e) => setPrinterSettings({...printerSettings, footerText: e.target.value})}/>
                    </div>
                    <Button type="submit">Simpan Perubahan</Button>
                </form>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Users Management Tab */}
          <TabsContent value="users">
            <Card>
              <CardHeader>
                 <div className="flex justify-between items-center">
                    <div>
                        <CardTitle>Manajemen Pengguna</CardTitle>
                        <CardDescription>Kelola akun pengguna yang dapat mengakses sistem.</CardDescription>
                    </div>
                    {/* <Button onClick={() => setIsUserDialogOpen(true)}><Plus className="mr-2 h-4 w-4"/> Tambah Pengguna</Button> */}
                 </div>
              </CardHeader>
              <CardContent>
                <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead>
                           <tr className="border-b">
                                <th className="text-left p-2">Nama</th>
                                <th className="text-left p-2">Email</th>
                                <th className="text-left p-2">Role</th>
                                <th className="text-right p-2">Aksi</th>
                           </tr>
                        </thead>
                        <tbody>
                            {isLoading ? (<tr><td colSpan={4} className="text-center p-4">Loading...</td></tr>) : users.map(u => (
                                <tr key={u.id} className="border-b">
                                    <td className="p-2 font-medium">{u.name}</td>
                                    <td className="p-2">{u.email}</td>
                                    <td className="p-2 capitalize">{u.role}</td>
                                    <td className="p-2 text-right">
                                        <Button variant="ghost" size="icon" onClick={() => handleEditUser(u)}><Edit className="h-4 w-4"/></Button>
                                        <Button variant="ghost" size="icon" onClick={() => handleDeleteUser(u.id)}><Trash2 className="h-4 w-4 text-red-500"/></Button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>

        {/* Dialog for Edit User */}
        <Dialog open={isUserDialogOpen} onOpenChange={setIsUserDialogOpen}>
            <DialogContent>
                <DialogHeader>
                    <DialogTitle>{editingUser ? 'Edit Pengguna' : 'Tambah Pengguna Baru'}</DialogTitle>
                </DialogHeader>
                <form onSubmit={handleUserSubmit} className="space-y-4 py-4">
                    <div>
                        <Label htmlFor="userName">Nama</Label>
                        <Input id="userName" value={userForm.name} onChange={(e) => setUserForm({...userForm, name: e.target.value})} />
                    </div>
                     <div>
                        <Label htmlFor="userEmail">Email</Label>
                        <Input id="userEmail" type="email" value={userForm.email} onChange={(e) => setUserForm({...userForm, email: e.target.value})} />
                    </div>
                     <div>
                        <Label htmlFor="userRole">Role</Label>
                        <Select value={userForm.role} onValueChange={(value) => setUserForm({...userForm, role: value as "admin" | "staff"})}>
                            <SelectTrigger><SelectValue/></SelectTrigger>
                            <SelectContent>
                                <SelectItem value="admin">Admin</SelectItem>
                                <SelectItem value="staff">Staff</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    <DialogFooter>
                        <Button type="button" variant="outline" onClick={() => setIsUserDialogOpen(false)}>Batal</Button>
                        <Button type="submit">Simpan</Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
      </div>
    </MainLayout>
  )
}