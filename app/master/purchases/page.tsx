"use client"

import { useState, useEffect, useMemo } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label" // <-- [DIPERBAIKI] Impor Label ditambahkan di sini
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Plus, Trash2, Archive, Search, X, Upload } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { db } from "@/lib/firebase"
import { collection, getDocs, doc, writeBatch, serverTimestamp, query, orderBy, Timestamp, increment, where, limit, setDoc } from "firebase/firestore"
import { useAuth } from "@/components/auth-provider"
import Papa from "papaparse"

// --- Interfaces ---
interface Item { id: string; name: string; code: string; buyPrice: number; }
interface Supplier { id: string; name: string; }
interface PurchaseItem { itemId: string; itemName: string; quantity: number; buyPrice: number; code: string; isNew?: boolean; }
interface Purchase { id: string; purchaseDate: any; supplierName: string; totalAmount: number; items: PurchaseItem[]; }

export default function PurchasesPage() {
  const { user } = useAuth();
  const { toast } = useToast();
  const [purchases, setPurchases] = useState<Purchase[]>([]);
  const [items, setItems] = useState<Item[]>([]);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isDialogOpen, setIsDialogOpen] = useState(false);

  // --- State untuk form pembelian baru ---
  const [selectedSupplier, setSelectedSupplier] = useState("");
  const [invoiceNumber, setInvoiceNumber] = useState("");
  const [purchaseItems, setPurchaseItems] = useState<PurchaseItem[]>([]);
  const [itemSearch, setItemSearch] = useState("");

  // --- Fetch data awal ---
  const fetchData = async () => {
    setIsLoading(true);
    try {
      const purchasesQuery = query(collection(db, "purchases"), orderBy("purchaseDate", "desc"));
      const [purchasesSnapshot, itemsSnapshot, suppliersSnapshot] = await Promise.all([
        getDocs(purchasesQuery),
        getDocs(collection(db, "items")),
        getDocs(collection(db, "suppliers"))
      ]);
      
      setPurchases(purchasesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Purchase)));
      setItems(itemsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Item)));
      setSuppliers(suppliersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Supplier)));
    } catch (error) {
      toast({ title: "Gagal memuat data", variant: "destructive" });
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchData();
  }, []);

  const resetForm = () => {
    setSelectedSupplier("");
    setInvoiceNumber("");
    setPurchaseItems([]);
    setItemSearch("");
  };

  const addItemToPurchase = (item: Item) => {
    if (purchaseItems.some(pItem => pItem.itemId === item.id)) {
        toast({ title: "Barang sudah ada di daftar", variant: "destructive" });
        return;
    }
    setPurchaseItems([...purchaseItems, {
      itemId: item.id, itemName: item.name, quantity: 1,
      buyPrice: item.buyPrice || 0, code: item.code
    }]);
    setItemSearch("");
  };

  const updatePurchaseItem = (itemId: string, field: 'quantity' | 'buyPrice', value: number) => {
    setPurchaseItems(purchaseItems.map(item => 
      item.itemId === itemId ? { ...item, [field]: value } : item
    ));
  };
  
  const removePurchaseItem = (itemId: string) => {
    setPurchaseItems(purchaseItems.filter(item => item.itemId !== itemId));
  };

  const totalAmount = useMemo(() => {
    return purchaseItems.reduce((sum, item) => sum + item.buyPrice * item.quantity, 0);
  }, [purchaseItems]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (purchaseItems.length === 0 || !selectedSupplier) {
      toast({ title: "Data tidak lengkap", description: "Pilih supplier dan tambahkan minimal satu barang.", variant: "destructive" });
      return;
    }
    setIsSaving(true);
    
    try {
      const batch = writeBatch(db);
      
      // 1. Buat dokumen pembelian baru
      const purchaseRef = doc(collection(db, "purchases"));
      const supplierData = suppliers.find(s => s.id === selectedSupplier);
      batch.set(purchaseRef, {
        purchaseDate: serverTimestamp(), supplierId: selectedSupplier,
        supplierName: supplierData?.name || "N/A", invoiceNumber, totalAmount,
        items: purchaseItems, recordedBy: user?.name || "N/A"
      });

      // 2. Update stok dan buat item baru jika ada
      for (const item of purchaseItems) {
        if (item.isNew) {
          // Buat master data barang baru
          const newItemRef = doc(collection(db, "items"));
          batch.set(newItemRef, {
              code: item.code, name: item.itemName, buyPrice: item.buyPrice,
              stock: item.quantity, sellPrice: item.buyPrice * 1.25, // Default margin 25%
              minStock: 5, category: "Lain-lain", description: "Barang baru dari faktur",
              createdAt: serverTimestamp()
          });
        } else {
          // Update stok barang yang sudah ada
          const itemRef = doc(db, "items", item.itemId);
          batch.update(itemRef, { stock: increment(item.quantity) });
        }
      }

      await batch.commit();
      toast({ title: "Pembelian Berhasil Dicatat", description: "Stok barang telah diperbarui." });
      
      await fetchData(); // Refresh semua data
      resetForm();
      setIsDialogOpen(false);

    } catch (error: any) {
      toast({ title: "Gagal menyimpan pembelian", description: error.message, variant: "destructive" });
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeletePurchase = async (purchase: Purchase) => {
    setIsLoading(true);
    try {
        const batch = writeBatch(db);

        // 1. Kurangi stok untuk setiap barang dalam pembelian
        for (const item of purchase.items) {
            const itemRef = doc(db, "items", item.itemId);
            // Gunakan increment dengan nilai negatif untuk mengurangi
            batch.update(itemRef, { stock: increment(-item.quantity) });
        }

        // 2. Hapus dokumen pembelian itu sendiri
        const purchaseRef = doc(db, "purchases", purchase.id);
        batch.delete(purchaseRef);

        await batch.commit();
        toast({ title: "Pembelian Dihapus", description: "Stok barang telah dikembalikan." });
        
        // Refresh data di state tanpa panggil ulang dari server
        setPurchases(prev => prev.filter(p => p.id !== purchase.id));

    } catch (error: any) {
        toast({ title: "Gagal menghapus", description: error.message, variant: "destructive" });
    } finally {
        setIsLoading(false);
    }
  };

  const handleCsvImport = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    Papa.parse(file, {
        header: true,
        skipEmptyLines: true,
        complete: async (results) => {
            const newPurchaseItems: PurchaseItem[] = [];
            for (const row of results.data as any[]) {
                const code = row.kode_barang || row.code;
                const name = row.nama_barang || row.name;
                const quantity = parseInt(row.jumlah) || 0;
                const buyPrice = parseInt(row.harga_beli) || 0;

                if (!code || !name || quantity <= 0) continue;

                // Cek apakah barang sudah ada di master
                const q = query(collection(db, "items"), where("code", "==", code), limit(1));
                const itemSnapshot = await getDocs(q);

                if (itemSnapshot.empty) {
                    // Barang baru
                    newPurchaseItems.push({ itemId: `new_${code}`, itemName: name, quantity, buyPrice, code, isNew: true });
                } else {
                    // Barang sudah ada
                    const existingItem = itemSnapshot.docs[0];
                    newPurchaseItems.push({ itemId: existingItem.id, itemName: name, quantity, buyPrice, code });
                }
            }
            setPurchaseItems(newPurchaseItems);
            toast({ title: "CSV Berhasil Dibaca", description: `${newPurchaseItems.length} item siap untuk dicatat.` });
        }
    });
  };

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Pencatatan Pembelian</h1>
            <p className="text-gray-600">Catat barang masuk dari supplier untuk memperbarui stok.</p>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={() => { resetForm(); setIsDialogOpen(true); }}>
                <Plus className="mr-2 h-4 w-4" />
                Catat Pembelian Baru
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-4xl">
              <DialogHeader><DialogTitle>Form Pembelian Baru</DialogTitle></DialogHeader>
              <form onSubmit={handleSubmit}>
                <div className="flex justify-between items-end gap-4 py-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 flex-grow">
                    <Select onValueChange={setSelectedSupplier} value={selectedSupplier}>
                      <SelectTrigger><SelectValue placeholder="Pilih Supplier..." /></SelectTrigger>
                      <SelectContent>{suppliers.map(s => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}</SelectContent>
                    </Select>
                    <Input placeholder="Nomor Faktur (Opsional)" value={invoiceNumber} onChange={e => setInvoiceNumber(e.target.value)} />
                  </div>
                  <Label htmlFor="csv-upload" className="cursor-pointer">
                    <Button asChild variant="outline"><span className="flex items-center gap-2"><Upload size={16}/> Impor Faktur CSV</span></Button>
                    <Input id="csv-upload" type="file" className="hidden" accept=".csv" onChange={handleCsvImport}/>
                  </Label>
                </div>
                
                <Card>
                  <CardHeader>
                    <CardTitle>Daftar Barang Dibeli</CardTitle>
                    {/* ... (pencarian manual bisa tetap ada atau dihapus) ... */}
                  </CardHeader>
                  <CardContent>
                    <table className="w-full text-sm">
                      <thead><tr className="border-b"><th className="p-2 text-left">Nama Barang</th><th className="p-2 text-center w-24">Jumlah</th><th className="p-2 text-center w-32">Harga Beli</th><th className="p-2 text-right">Subtotal</th><th className="p-2 w-10"></th></tr></thead>
                      <tbody>
                        {purchaseItems.map(item => (
                          <tr key={item.itemId} className={`border-b ${item.isNew ? 'bg-green-50' : ''}`}>
                            <td className="p-2">{item.itemName} {item.isNew && <span className="text-xs text-green-600 font-bold">(BARU)</span>}</td>
                            <td className="p-1"><Input type="number" value={item.quantity} onChange={e => updatePurchaseItem(item.itemId, 'quantity', parseInt(e.target.value) || 0)} className="w-full text-center"/></td>
                            <td className="p-1"><Input type="number" value={item.buyPrice} onChange={e => updatePurchaseItem(item.itemId, 'buyPrice', parseInt(e.target.value) || 0)} className="w-full text-right"/></td>
                            <td className="p-2 text-right">Rp {(item.quantity * item.buyPrice).toLocaleString('id-ID')}</td>
                            <td className="p-2 text-center"><Button variant="ghost" size="icon" onClick={() => removePurchaseItem(item.itemId)}><Trash2 className="h-4 w-4 text-red-500"/></Button></td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </CardContent>
                </Card>

                <div className="text-right font-bold text-xl mt-4">Total: Rp {totalAmount.toLocaleString('id-ID')}</div>
                <DialogFooter className="mt-6">
                  <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)} disabled={isSaving}>Batal</Button>
                  <Button type="submit" disabled={isSaving}>
                    {isSaving ? "Menyimpan..." : "Simpan Pembelian"}
                  </Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center"><Archive className="mr-2 h-5 w-5"/> Riwayat Pembelian</CardTitle>
            <CardDescription>Daftar semua pencatatan pembelian barang dari supplier.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead><tr className="border-b"><th className="p-2 text-left">Tanggal</th><th className="p-2 text-left">Supplier</th><th className="p-2 text-right">Total</th><th className="p-2 text-center">Item</th><th className="p-2 text-right">Aksi</th></tr></thead>
                <tbody>
                  {isLoading ? (<tr><td colSpan={5} className="text-center p-4">Memuat riwayat...</td></tr>) 
                  : purchases.map(p => (
                    <tr key={p.id} className="border-b hover:bg-gray-50">
                      <td className="p-2">{(p.purchaseDate as Timestamp).toDate().toLocaleDateString('id-ID')}</td>
                      <td className="p-2 font-medium">{p.supplierName}</td>
                      <td className="p-2 text-right">Rp {p.totalAmount.toLocaleString('id-ID')}</td>
                      <td className="p-2 text-center">{p.items.length} jenis</td>
                      <td className="p-2 text-right">
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button variant="ghost" size="icon"><Trash2 className="h-4 w-4 text-red-500"/></Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader><AlertDialogTitle>Anda Yakin?</AlertDialogTitle><AlertDialogDescription>Tindakan ini akan menghapus catatan pembelian dan mengembalikan (mengurangi) stok barang yang terkait. Tindakan ini tidak dapat diurungkan.</AlertDialogDescription></AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Batal</AlertDialogCancel>
                              <AlertDialogAction onClick={() => handleDeletePurchase(p)}>Ya, Hapus</AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
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
