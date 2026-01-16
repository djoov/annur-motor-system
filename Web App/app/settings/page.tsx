"use client"

import type React from "react"
import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Store, Printer, Users, Plus, Edit, Trash2, Save, MapPin, Phone, Mail, CreditCard, UserCog, AlertTriangle, Database } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { useAuth } from "@/components/auth-provider"

// --- Impor dari Firebase ---
import { db } from "@/lib/firebase"
import { doc, getDoc, setDoc, collection, onSnapshot, addDoc, updateDoc, deleteDoc, serverTimestamp, getDocs, writeBatch, query, where } from "firebase/firestore"

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
  createdAt?: any
}

export default function SettingsPage() {
  const { user } = useAuth()
  const { toast } = useToast()

  // State untuk setiap tab
  const [storeSettings, setStoreSettings] = useState<StoreSettings>({ name: '', npwp: '', address: '', city: '', province: '', phone: '', email: '' });
  const [printerSettings, setPrinterSettings] = useState<PrinterSettings>({ printerBrand: '', printerPort: '', paperWidth: '80mm', showLogo: true, headerText: '', footerText: '' });
  const [users, setUsers] = useState<UserData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  // State untuk dialog manajemen user
  const [isUserDialogOpen, setIsUserDialogOpen] = useState(false)
  const [editingUser, setEditingUser] = useState<UserData | null>(null)
  const [userForm, setUserForm] = useState({ name: '', email: '', role: 'staff' as 'admin' | 'staff' });

  // State untuk reset data
  const [isResetDialogOpen, setIsResetDialogOpen] = useState(false);
  const [resetType, setResetType] = useState<'transactions' | 'debts' | 'all'>('transactions');
  const [resetConfirmText, setResetConfirmText] = useState('');
  const [isResetting, setIsResetting] = useState(false);

  // --- Realtime Data Fetching ---
  useEffect(() => {
    setIsLoading(true);

    // 1. Listen to Settings Doc
    const settingsDocRef = doc(db, "settings", "storeConfig");
    const unsubscribeSettings = onSnapshot(settingsDocRef, (doc) => {
      if (doc.exists()) {
        const data = doc.data();
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
      setIsLoading(false);
    });

    // 2. Listen to Users Collection
    const usersCollectionRef = collection(db, "users");
    const unsubscribeUsers = onSnapshot(usersCollectionRef, (snapshot) => {
      const usersList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as UserData));
      setUsers(usersList);
    });

    return () => {
      unsubscribeSettings();
      unsubscribeUsers();
    }
  }, []);

  // --- Handler untuk menyimpan data ke Firestore ---
  const handleSettingsSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    try {
      const settingsDocRef = doc(db, "settings", "storeConfig");
      // Gabungkan kedua state untuk disimpan dalam satu dokumen
      await setDoc(settingsDocRef, { ...storeSettings, ...printerSettings }, { merge: true });
      toast({ title: 'Pengaturan tersimpan', description: "Konfigurasi toko dan printer berhasil diperbarui." });
    } catch (error) {
      console.error("Error saving settings: ", error);
      toast({ title: 'Gagal menyimpan', description: "Terjadi kesalahan koneksi.", variant: 'destructive' });
    } finally {
      setIsSaving(false);
    }
  }

  const handleUserSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    try {
      if (editingUser) {
        const userDoc = doc(db, "users", editingUser.id);
        await updateDoc(userDoc, {
          name: userForm.name,
          email: userForm.email,
          role: userForm.role,
        });
        toast({ title: 'Data pengguna diperbarui' });
      } else {
        await addDoc(collection(db, "users"), {
          name: userForm.name,
          email: userForm.email,
          role: userForm.role,
          createdAt: serverTimestamp(),
          // Note: In a real app, you'd trigger a cloud function to create Auth user here
        });
        toast({ title: 'Pengguna baru ditambahkan' });
      }
      setIsUserDialogOpen(false);
    } catch (error) {
      console.error("Error submitting user:", error);
      toast({ title: 'Gagal memproses data', variant: 'destructive' });
    } finally {
      setIsSaving(false);
    }
  }

  const handleEditUser = (user: UserData) => {
    setEditingUser(user);
    setUserForm({ name: user.name, email: user.email, role: user.role });
    setIsUserDialogOpen(true);
  }

  const handleDeleteUser = async (id: string) => {
    if (id === user?.id) {
      toast({ title: "Akses Ditolak", description: "Anda tidak dapat menghapus akun sendiri.", variant: "destructive" });
      return;
    }
    if (confirm("Hapus pengguna ini dari daftar akses?")) {
      await deleteDoc(doc(db, "users", id));
      toast({ title: "Pengguna dihapus" });
    }
  }

  const getInitials = (name: string) => name.split(" ").map(n => n[0]).join("").substring(0, 2).toUpperCase();

  // Handler untuk reset data
  const handleResetData = async () => {
    if (resetConfirmText !== 'HAPUS SEMUA') {
      toast({ title: 'Konfirmasi salah', description: 'Ketik "HAPUS SEMUA" untuk melanjutkan.', variant: 'destructive' });
      return;
    }

    setIsResetting(true);
    try {
      const batch = writeBatch(db);
      let deletedCount = 0;

      // Reset Transactions
      if (resetType === 'transactions' || resetType === 'all') {
        const transactionsSnapshot = await getDocs(collection(db, 'transactions'));
        transactionsSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
          deletedCount++;
        });
      }

      // Reset Debts
      if (resetType === 'debts' || resetType === 'all') {
        const debtsSnapshot = await getDocs(collection(db, 'debts'));
        debtsSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
          deletedCount++;
        });

        // Also reset totalDebt on all customers
        const customersSnapshot = await getDocs(collection(db, 'customers'));
        customersSnapshot.docs.forEach(doc => {
          batch.update(doc.ref, { totalDebt: 0 });
        });
      }

      // Reset Item Movements if resetting all
      if (resetType === 'all') {
        const movementsSnapshot = await getDocs(collection(db, 'itemMovements'));
        movementsSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
          deletedCount++;
        });
      }

      await batch.commit();

      toast({
        title: 'Data Berhasil Dihapus',
        description: `${deletedCount} record telah dihapus secara permanen.`
      });
      setIsResetDialogOpen(false);
      setResetConfirmText('');
    } catch (error) {
      console.error('Reset error:', error);
      toast({ title: 'Gagal menghapus data', description: 'Terjadi kesalahan sistem.', variant: 'destructive' });
    } finally {
      setIsResetting(false);
    }
  };

  return (
    <MainLayout>
      <div className="space-y-6 pb-20">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-slate-800">Pengaturan</h1>
            <p className="text-slate-500 mt-1">Pusat kendali konfigurasi toko dan akses pengguna.</p>
          </div>
        </div>

        <Tabs defaultValue="store" className="space-y-6">
          <TabsList className="grid w-full grid-cols-4 lg:w-[520px]">
            <TabsTrigger value="store" className="flex items-center gap-2"><Store className="h-4 w-4" />Info Toko</TabsTrigger>
            <TabsTrigger value="printer" className="flex items-center gap-2"><Printer className="h-4 w-4" />Printer</TabsTrigger>
            <TabsTrigger value="users" className="flex items-center gap-2"><Users className="h-4 w-4" />Pengguna</TabsTrigger>
            <TabsTrigger value="danger" className="flex items-center gap-2 text-red-600 data-[state=active]:text-red-600"><AlertTriangle className="h-4 w-4" />Reset</TabsTrigger>
          </TabsList>

          {/* Store Settings Tab */}
          <TabsContent value="store" className="space-y-6">
            <form onSubmit={handleSettingsSubmit}>
              <Card className="border-slate-200 shadow-sm">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Store className="w-5 h-5 text-indigo-600" /> Profil Usaha
                  </CardTitle>
                  <CardDescription>Informasi ini akan muncul pada struk dan laporan.</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <Label htmlFor="storeName">Nama Toko / Bengkel</Label>
                      <Input id="storeName" placeholder="Contoh: Annur Motor" value={storeSettings.name} onChange={(e) => setStoreSettings({ ...storeSettings, name: e.target.value })} />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="npwp">NPWP (Opsional)</Label>
                      <Input id="npwp" placeholder="00.000.000.0-000.000" value={storeSettings.npwp} onChange={(e) => setStoreSettings({ ...storeSettings, npwp: e.target.value })} />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="address">Alamat Lengkap</Label>
                    <div className="relative">
                      <MapPin className="absolute left-3 top-3 h-4 w-4 text-slate-400" />
                      <Textarea className="pl-9" id="address" placeholder="Jalan Raya..." value={storeSettings.address} onChange={(e) => setStoreSettings({ ...storeSettings, address: e.target.value })} />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <Label htmlFor="phone">No. Telepon / WA</Label>
                      <div className="relative">
                        <Phone className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                        <Input className="pl-9" id="phone" type="tel" placeholder="08..." value={storeSettings.phone} onChange={(e) => setStoreSettings({ ...storeSettings, phone: e.target.value })} />
                      </div>
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="email">Email Resmi</Label>
                      <div className="relative">
                        <Mail className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                        <Input className="pl-9" id="email" type="email" placeholder="admin@annur.com" value={storeSettings.email} onChange={(e) => setStoreSettings({ ...storeSettings, email: e.target.value })} />
                      </div>
                    </div>
                  </div>
                </CardContent>
                <CardFooter className="bg-slate-50 border-t border-slate-100 flex justify-end py-3">
                  <Button type="submit" disabled={isSaving} className="bg-indigo-600 hover:bg-indigo-700">
                    {isSaving ? "Menyimpan..." : <><Save className="w-4 h-4 mr-2" /> Simpan Profil</>}
                  </Button>
                </CardFooter>
              </Card>
            </form>
          </TabsContent>

          {/* Printer Settings Tab */}
          <TabsContent value="printer">
            <form onSubmit={handleSettingsSubmit}>
              <Card className="border-slate-200 shadow-sm">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Printer className="w-5 h-5 text-indigo-600" /> Konfigurasi Struk
                  </CardTitle>
                  <CardDescription>Sesuaikan tampilan struk belanja customer.</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="flex items-center justify-between p-4 bg-slate-50 rounded-lg border border-slate-200">
                    <div className="space-y-0.5">
                      <Label htmlFor="show-logo" className="text-base">Tampilkan Logo</Label>
                      <p className="text-xs text-slate-500">Logo toko akan dicetak di bagian atas struk.</p>
                    </div>
                    <Switch id="show-logo" checked={printerSettings.showLogo} onCheckedChange={(checked) => setPrinterSettings(prev => ({ ...prev, showLogo: checked }))} />
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <Label htmlFor="headerText">Pesan Header</Label>
                      <Textarea id="headerText" placeholder="Selamat Datang..." value={printerSettings.headerText} onChange={(e) => setPrinterSettings({ ...printerSettings, headerText: e.target.value })} />
                      <p className="text-xs text-slate-500">Teks pembuka di atas daftar belanja.</p>
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="footerText">Pesan Footer</Label>
                      <Textarea id="footerText" placeholder="Terima Kasih..." value={printerSettings.footerText} onChange={(e) => setPrinterSettings({ ...printerSettings, footerText: e.target.value })} />
                      <p className="text-xs text-slate-500">Teks penutup di bawah total belanja.</p>
                    </div>
                  </div>
                </CardContent>
                <CardFooter className="bg-slate-50 border-t border-slate-100 flex justify-end py-3">
                  <Button type="submit" disabled={isSaving} className="bg-indigo-600 hover:bg-indigo-700">
                    {isSaving ? "Menyimpan..." : <><Save className="w-4 h-4 mr-2" /> Simpan Konfigurasi</>}
                  </Button>
                </CardFooter>
              </Card>
            </form>
          </TabsContent>

          {/* Users Management Tab */}
          <TabsContent value="users">
            <Card className="border-slate-200 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between pb-4">
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <UserCog className="w-5 h-5 text-indigo-600" /> Akses Pengguna
                  </CardTitle>
                  <CardDescription>Kelola tim dan hak akses aplikasi.</CardDescription>
                </div>
                <Button onClick={() => { setEditingUser(null); setUserForm({ name: '', email: '', role: 'staff' }); setIsUserDialogOpen(true); }}>
                  <Plus className="mr-2 h-4 w-4" /> Tambah User
                </Button>
              </CardHeader>
              <CardContent>
                <div className="overflow-hidden rounded-lg border border-slate-200">
                  <table className="w-full text-sm">
                    <thead className="bg-slate-50 border-b border-slate-200">
                      <tr>
                        <th className="text-left py-3 px-4 font-medium text-slate-500">Pengguna</th>
                        <th className="text-left py-3 px-4 font-medium text-slate-500">Role</th>
                        <th className="text-left py-3 px-4 font-medium text-slate-500">Status</th>
                        <th className="text-right py-3 px-4 font-medium text-slate-500">Aksi</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {isLoading ? (<tr><td colSpan={4} className="text-center p-8 text-slate-400">Loading data...</td></tr>) : users.map(u => (
                        <tr key={u.id} className="hover:bg-slate-50/50">
                          <td className="py-3 px-4">
                            <div className="flex items-center gap-3">
                              <Avatar className="h-9 w-9 border border-indigo-100 shadow-sm">
                                <AvatarImage src={`https://api.dicebear.com/7.x/initials/svg?seed=${u.name}`} />
                                <AvatarFallback className="bg-indigo-100 text-indigo-600 font-bold">{getInitials(u.name)}</AvatarFallback>
                              </Avatar>
                              <div>
                                <p className="font-medium text-slate-900">{u.name}</p>
                                <p className="text-xs text-slate-500">{u.email}</p>
                              </div>
                            </div>
                          </td>
                          <td className="py-3 px-4">
                            <Badge variant="outline" className={u.role === 'admin' ? "bg-purple-50 text-purple-700 border-purple-200 capitalize" : "bg-slate-50 text-slate-600 border-slate-200 capitalize"}>
                              {u.role}
                            </Badge>
                          </td>
                          <td className="py-3 px-4">
                            <Badge variant="secondary" className="bg-emerald-50 text-emerald-600 font-normal">Aktif</Badge>
                          </td>
                          <td className="py-3 px-4 text-right">
                            <Button variant="ghost" size="icon" className="h-8 w-8 text-blue-600 hover:bg-blue-50 hover:text-blue-700 mr-1" onClick={() => handleEditUser(u)}>
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button variant="ghost" size="icon" className="h-8 w-8 text-red-400 hover:bg-red-50 hover:text-red-500" onClick={() => handleDeleteUser(u.id)}>
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Danger Zone Tab */}
          <TabsContent value="danger">
            <Card className="border-red-200 shadow-sm bg-red-50/30">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-red-700">
                  <AlertTriangle className="w-5 h-5" /> Zona Berbahaya
                </CardTitle>
                <CardDescription className="text-red-600">
                  Operasi di bawah ini bersifat PERMANEN dan tidak dapat dibatalkan.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Reset Transactions */}
                <div className="p-4 bg-white rounded-lg border border-red-200 flex justify-between items-center">
                  <div>
                    <h4 className="font-medium text-slate-800">Reset Riwayat Transaksi</h4>
                    <p className="text-sm text-slate-500">Hapus semua data penjualan dari sistem.</p>
                  </div>
                  <Button variant="outline" className="border-red-300 text-red-600 hover:bg-red-50 hover:text-red-700" onClick={() => { setResetType('transactions'); setResetConfirmText(''); setIsResetDialogOpen(true); }}>
                    <Trash2 className="w-4 h-4 mr-2" /> Reset
                  </Button>
                </div>

                {/* Reset Debts */}
                <div className="p-4 bg-white rounded-lg border border-red-200 flex justify-between items-center">
                  <div>
                    <h4 className="font-medium text-slate-800">Reset Data Hutang/Piutang</h4>
                    <p className="text-sm text-slate-500">Hapus semua data piutang pelanggan.</p>
                  </div>
                  <Button variant="outline" className="border-red-300 text-red-600 hover:bg-red-50 hover:text-red-700" onClick={() => { setResetType('debts'); setResetConfirmText(''); setIsResetDialogOpen(true); }}>
                    <Trash2 className="w-4 h-4 mr-2" /> Reset
                  </Button>
                </div>

                {/* Reset All */}
                <div className="p-4 bg-red-100 rounded-lg border-2 border-red-300 flex justify-between items-center">
                  <div>
                    <h4 className="font-bold text-red-700">Reset Semua Data Transaksi</h4>
                    <p className="text-sm text-red-600">Hapus transaksi, hutang, dan arus stok sekaligus.</p>
                  </div>
                  <Button variant="destructive" className="bg-red-600 hover:bg-red-700" onClick={() => { setResetType('all'); setResetConfirmText(''); setIsResetDialogOpen(true); }}>
                    <Database className="w-4 h-4 mr-2" /> Reset Semua
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>

        {/* Dialog for Edit User */}
        <Dialog open={isUserDialogOpen} onOpenChange={setIsUserDialogOpen}>
          <DialogContent className="sm:max-w-md">
            <DialogHeader>
              <DialogTitle>{editingUser ? 'Edit Pengguna' : 'Tambah Pengguna Baru'}</DialogTitle>
              <DialogDescription>
                {editingUser ? 'Perbarui informasi akses pengguna.' : 'Undang anggota tim baru.'}
              </DialogDescription>
            </DialogHeader>
            <form onSubmit={handleUserSubmit} className="space-y-4 py-2">
              <div className="space-y-2">
                <Label htmlFor="userName">Nama Lengkap</Label>
                <Input id="userName" placeholder="Nama..." value={userForm.name} onChange={(e) => setUserForm({ ...userForm, name: e.target.value })} required />
              </div>
              <div className="space-y-2">
                <Label htmlFor="userEmail">Email</Label>
                <Input id="userEmail" type="email" placeholder="email@contoh.com" value={userForm.email} onChange={(e) => setUserForm({ ...userForm, email: e.target.value })} required />
              </div>
              <div className="space-y-2">
                <Label htmlFor="userRole">Hak Akses</Label>
                <Select value={userForm.role} onValueChange={(value) => setUserForm({ ...userForm, role: value as "admin" | "staff" })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="admin">Admin (Akses Penuh)</SelectItem>
                    <SelectItem value="staff">Staff (Terbatas)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <DialogFooter>
                <Button type="button" variant="outline" onClick={() => setIsUserDialogOpen(false)} disabled={isSaving}>Batal</Button>
                <Button type="submit" disabled={isSaving}>
                  {isSaving ? "Menyimpan..." : "Simpan Data"}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>

        {/* Reset Confirmation Dialog */}
        <Dialog open={isResetDialogOpen} onOpenChange={setIsResetDialogOpen}>
          <DialogContent className="sm:max-w-md">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2 text-red-700">
                <AlertTriangle className="w-5 h-5" /> Konfirmasi Penghapusan
              </DialogTitle>
              <DialogDescription className="text-slate-600">
                {resetType === 'transactions' && 'Anda akan menghapus SEMUA riwayat transaksi penjualan.'}
                {resetType === 'debts' && 'Anda akan menghapus SEMUA data piutang pelanggan.'}
                {resetType === 'all' && 'Anda akan menghapus transaksi, piutang, dan arus stok sekaligus.'}
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-4 py-4">
              <div className="p-3 bg-red-50 rounded-lg border border-red-200 text-center">
                <p className="text-sm text-red-600 font-medium">
                  ⚠️ Operasi ini TIDAK DAPAT dibatalkan!
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirmText" className="text-slate-600">
                  Ketik <span className="font-bold text-red-600">HAPUS SEMUA</span> untuk konfirmasi:
                </Label>
                <Input
                  id="confirmText"
                  value={resetConfirmText}
                  onChange={(e) => setResetConfirmText(e.target.value)}
                  placeholder="HAPUS SEMUA"
                  className="border-red-200 focus:border-red-400"
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setIsResetDialogOpen(false)} disabled={isResetting}>
                Batal
              </Button>
              <Button
                variant="destructive"
                onClick={handleResetData}
                disabled={isResetting || resetConfirmText !== 'HAPUS SEMUA'}
                className="bg-red-600 hover:bg-red-700"
              >
                {isResetting ? "Menghapus..." : "Hapus Permanen"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </MainLayout>
  )
}