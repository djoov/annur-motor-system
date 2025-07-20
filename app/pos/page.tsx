"use client"

import { useState, useEffect, useMemo } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
// --- [DIPERBAIKI] Tambahkan 'Label' di sini ---
import { Label } from "@/components/ui/label"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Search, X, Plus, Minus, User, ShoppingCart, DollarSign } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { db } from "@/lib/firebase"
import { collection, getDocs, doc, writeBatch, serverTimestamp } from "firebase/firestore"

// --- Interfaces ---
interface Item {
  id: string
  name: string
  code: string
  sellPrice: number
  buyPrice: number
  stock: number
  category?: string
}

interface CartItem extends Item {
  quantity: number
}

interface Customer {
    id: string
    name: string
}

export default function PosPage() {
  const { toast } = useToast()
  const [allItems, setAllItems] = useState<Item[]>([])
  const [filteredItems, setFilteredItems] = useState<Item[]>([])
  const [customers, setCustomers] = useState<Customer[]>([])
  const [cart, setCart] = useState<CartItem[]>([])
  const [searchTerm, setSearchTerm] = useState("")
  const [isLoading, setIsLoading] = useState(true)
  const [isProcessing, setIsProcessing] = useState(false)
  
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false)
  const [selectedCustomer, setSelectedCustomer] = useState<string>("Pelanggan Umum")

  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true)
      try {
        const itemsSnapshot = await getDocs(collection(db, "items"))
        const itemsList = itemsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Item))
        setAllItems(itemsList)
        setFilteredItems(itemsList.slice(0, 10))

        const customersSnapshot = await getDocs(collection(db, "customers"));
        const customersList = customersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Customer));
        setCustomers(customersList);

      } catch (error) {
        console.error("Error fetching data: ", error)
        toast({ title: "Gagal memuat data awal", variant: "destructive" })
      }
      setIsLoading(false)
    }
    fetchData()
  }, [toast])

  useEffect(() => {
    if (searchTerm === "") {
      setFilteredItems(allItems.slice(0, 10))
    } else {
      const lowercasedTerm = searchTerm.toLowerCase()
      const results = allItems.filter(
        item =>
          (item.name || '').toLowerCase().includes(lowercasedTerm) ||
          (item.code || '').toLowerCase().includes(lowercasedTerm)
      )
      setFilteredItems(results)
    }
  }, [searchTerm, allItems])

  const addToCart = (item: Item) => {
    setCart(prevCart => {
      const existingItem = prevCart.find(cartItem => cartItem.id === item.id)
      if (existingItem) {
        if ((existingItem.quantity || 0) < (item.stock || 0)) {
            return prevCart.map(cartItem =>
              cartItem.id === item.id ? { ...cartItem, quantity: (cartItem.quantity || 0) + 1 } : cartItem
            )
        } else {
            toast({ title: "Stok tidak mencukupi", variant: "destructive" });
            return prevCart;
        }
      }
      if ((item.stock || 0) > 0) {
        return [...prevCart, { ...item, quantity: 1 }]
      } else {
        toast({ title: "Barang habis", variant: "destructive" });
        return prevCart;
      }
    })
  }

  const updateQuantity = (itemId: string, newQuantity: number) => {
    const itemInAllItems = allItems.find(item => item.id === itemId);
    if (itemInAllItems && newQuantity > (itemInAllItems.stock || 0)) {
        toast({ title: "Stok tidak mencukupi", variant: "destructive" });
        return;
    }
    
    setCart(prevCart =>
      prevCart.map(item =>
        item.id === itemId ? { ...item, quantity: newQuantity } : item
      ).filter(item => item.quantity > 0)
    )
  }

  const removeFromCart = (itemId: string) => {
    setCart(prevCart => prevCart.filter(item => item.id !== itemId))
  }

  const cartSummary = useMemo(() => {
    const totalAmount = cart.reduce((sum, item) => sum + (item.sellPrice || 0) * (item.quantity || 0), 0)
    const totalProfit = cart.reduce((sum, item) => sum + ((item.sellPrice || 0) - (item.buyPrice || 0)) * (item.quantity || 0), 0)
    return { totalAmount, totalProfit }
  }, [cart])

  const handleCheckout = async () => {
    if (cart.length === 0) {
      toast({ title: "Keranjang kosong!", variant: "destructive" });
      return;
    }
    setIsProcessing(true);

    try {
        const batch = writeBatch(db);
        const transactionRef = doc(collection(db, "transactions"));
        batch.set(transactionRef, {
            transactionDate: serverTimestamp(),
            customerName: selectedCustomer,
            totalAmount: cartSummary.totalAmount,
            totalProfit: cartSummary.totalProfit,
            items: cart.map(item => ({
                itemId: item.id,
                itemName: item.name || 'Nama Tidak Ada',
                category: item.category || 'Lain-lain',
                quantity: item.quantity || 0,
                sellPrice: item.sellPrice || 0,
                buyPrice: item.buyPrice || 0,
            }))
        });

        for (const item of cart) {
            const itemRef = doc(db, "items", item.id);
            const newStock = (item.stock || 0) - (item.quantity || 0);
            batch.update(itemRef, { stock: newStock });
        }

        await batch.commit();

        toast({ title: "Transaksi Berhasil!", description: "Stok barang telah diperbarui." });
        setCart([]);
        setIsCheckoutOpen(false);
        
        const updatedItems = allItems.map(item => {
            const cartItem = cart.find(ci => ci.id === item.id);
            if (cartItem) {
                return { ...item, stock: (item.stock || 0) - (cartItem.quantity || 0) };
            }
            return item;
        });
        setAllItems(updatedItems);

    } catch (error) {
        console.error("Transaction failed: ", error);
        toast({ title: "Transaksi Gagal!", description: "Terjadi kesalahan saat menyimpan data.", variant: "destructive" });
    } finally {
        setIsProcessing(false);
    }
  }


  return (
    <MainLayout>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-[calc(100vh-80px)]">
        {/* Kolom Kiri: Daftar Barang */}
        <div className="lg:col-span-2 flex flex-col h-full">
          <Card className="flex-grow flex flex-col">
            <CardHeader>
              <CardTitle>Pilih Barang</CardTitle>
              <div className="relative mt-2">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Cari berdasarkan nama atau kode barang..."
                  className="pl-10"
                  value={searchTerm}
                  onChange={e => setSearchTerm(e.target.value)}
                />
              </div>
            </CardHeader>
            <CardContent className="flex-grow overflow-y-auto">
              {isLoading ? (
                <p>Memuat data barang...</p>
              ) : (
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                  {filteredItems.map(item => (
                    <Card
                      key={item.id}
                      className="cursor-pointer hover:shadow-lg transition-shadow"
                      onClick={() => addToCart(item)}
                    >
                      <CardContent className="p-3 text-center">
                        <p className="font-semibold text-sm truncate">{item.name || "Nama Barang"}</p>
                        <p className="text-xs text-muted-foreground">Stok: {item.stock || 0}</p>
                        <p className="font-bold text-blue-600 mt-1">
                          Rp {(item.sellPrice || 0).toLocaleString("id-ID")}
                        </p>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Kolom Kanan: Keranjang Belanja */}
        <div className="flex flex-col h-full">
          <Card className="flex-grow flex flex-col">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <ShoppingCart /> Keranjang
              </CardTitle>
            </CardHeader>
            <CardContent className="flex-grow overflow-y-auto space-y-2">
              {cart.length === 0 ? (
                <p className="text-center text-muted-foreground py-10">Keranjang masih kosong</p>
              ) : (
                cart.map(item => (
                  <div key={item.id} className="flex items-center gap-2 border-b pb-2">
                    <div className="flex-grow">
                      <p className="font-medium text-sm">{item.name || "Nama Barang"}</p>
                      <p className="text-xs text-muted-foreground">
                        Rp {(item.sellPrice || 0).toLocaleString("id-ID")}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <Button variant="outline" size="icon" className="h-6 w-6" onClick={() => updateQuantity(item.id, (item.quantity || 0) - 1)}>
                        <Minus className="h-3 w-3" />
                      </Button>
                      <span className="w-6 text-center">{item.quantity || 0}</span>
                      <Button variant="outline" size="icon" className="h-6 w-6" onClick={() => updateQuantity(item.id, (item.quantity || 0) + 1)}>
                        <Plus className="h-3 w-3" />
                      </Button>
                    </div>
                    <Button variant="ghost" size="icon" className="h-6 w-6 text-red-500" onClick={() => removeFromCart(item.id)}>
                      <X className="h-4 w-4" />
                    </Button>
                  </div>
                ))
              )}
            </CardContent>
            <CardFooter className="flex flex-col gap-4 border-t pt-4">
              <div className="w-full flex justify-between text-lg font-bold">
                <span>Total</span>
                <span>Rp {cartSummary.totalAmount.toLocaleString("id-ID")}</span>
              </div>
              <Dialog open={isCheckoutOpen} onOpenChange={setIsCheckoutOpen}>
                <DialogTrigger asChild>
                    <Button className="w-full" size="lg" disabled={cart.length === 0 || isProcessing}>
                        <DollarSign className="mr-2 h-5 w-5"/> Bayar
                    </Button>
                </DialogTrigger>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Konfirmasi Pembayaran</DialogTitle>
                    </DialogHeader>
                    <div className="py-4 space-y-4">
                        <div>
                            <Label htmlFor="customer">Pelanggan</Label>
                            <select id="customer" value={selectedCustomer} onChange={(e) => setSelectedCustomer(e.target.value)} className="w-full p-2 border rounded-md">
                                <option>Pelanggan Umum</option>
                                {customers.map(c => <option key={c.id} value={c.name}>{c.name}</option>)}
                            </select>
                        </div>
                        <div className="text-center space-y-2">
                            <p className="text-muted-foreground">Total Tagihan</p>
                            <p className="text-4xl font-bold">Rp {cartSummary.totalAmount.toLocaleString("id-ID")}</p>
                        </div>
                    </div>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsCheckoutOpen(false)}>Batal</Button>
                        <Button onClick={handleCheckout} disabled={isProcessing}>
                            {isProcessing ? "Memproses..." : "Konfirmasi & Simpan Transaksi"}
                        </Button>
                    </DialogFooter>
                </DialogContent>
              </Dialog>
            </CardFooter>
          </Card>
        </div>
      </div>
    </MainLayout>
  )
}