"use client"

import { useState, useEffect, useRef } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogTrigger,
  DialogDescription
} from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Search, ShoppingCart, DollarSign, CreditCard, Printer, Trash2 } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { db } from "@/lib/firebase"
import { usePos } from "@/hooks/use-pos"
import { collection, onSnapshot, query, limit, orderBy, Unsubscribe } from "firebase/firestore"

import type { Item, Customer } from "@/types"

export default function PosPage() {
  const { toast } = useToast()

  // Custom Hook
  const { cart, addToCart, updateQuantity, removeFromCart, clearCart, cartSummary, processCheckout, isProcessing, lastTransaction } = usePos()

  const [allItems, setAllItems] = useState<Item[]>([]) // Store ALL items here
  const [customers, setCustomers] = useState<Customer[]>([])
  const [searchTerm, setSearchTerm] = useState("")
  // Removed debounce triggers for search, we filter instantly on client
  const [isLoading, setIsLoading] = useState(true)

  // Checkout State
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false)
  const [selectedCustomerId, setSelectedCustomerId] = useState<string>("umum")
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'transfer'>('cash')
  const [amountPaid, setAmountPaid] = useState<string>("")
  const [showReceipt, setShowReceipt] = useState(false)

  const searchInputRef = useRef<HTMLInputElement>(null)

  // --- Initial Load (Customers + All Items Realtime) ---
  useEffect(() => {
    let unsubscribeItems: Unsubscribe;
    let unsubscribeCustomers: Unsubscribe;

    const setupData = async () => {
      setIsLoading(true)

      // 1. Customers (Realtime)
      const custRef = collection(db, "customers");
      unsubscribeCustomers = onSnapshot(custRef, (snap) => {
        setCustomers(snap.docs.map(d => ({ id: d.id, ...d.data() } as Customer)))
      });

      // 2. Items (Realtime - Load ALL for client-side search)
      // We assume dataset is reasonable (< 2000 items). If larger, we need Algolia.
      const itemsRef = collection(db, "items");
      const q = query(itemsRef, orderBy("name"), limit(2000));

      unsubscribeItems = onSnapshot(q, (snapshot) => {
        const loadedItems = snapshot.docs.map(d => ({ id: d.id, ...d.data() } as Item));
        setAllItems(loadedItems);
        setIsLoading(false);
      }, (err) => {
        console.error("Error loading items:", err);
        toast({ title: "Gagal memuat barang", variant: "destructive" });
        setIsLoading(false);
      });
    }

    setupData();
    if (searchInputRef.current) searchInputRef.current.focus()

    return () => {
      if (unsubscribeItems) unsubscribeItems();
      if (unsubscribeCustomers) unsubscribeCustomers();
    }
  }, [])

  // --- Client-Side Filter ---
  const filteredItems = allItems.filter(item => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    // Smart: Match Name (contains), Code (contains), or Category (contains)
    return (
      (item.name || "").toLowerCase().includes(term) ||
      (item.code || "").toLowerCase().includes(term) ||
      (item.category || "").toLowerCase().includes(term)
    );
  });

  // --- Handlers ---
  const handlePaymentSubmit = async () => {
    const customer = customers.find(c => c.id === selectedCustomerId);
    const custName = customer ? customer.name : "Pelanggan Umum";

    const paid = Number(amountPaid.replace(/\./g, ''));
    if (paymentMethod === 'cash' && paid < cartSummary.totalAmount) {
      toast({ title: "Uang Kurang!", description: "Jumlah pembayaran kurang dari total tagihan.", variant: "destructive" });
      return;
    }

    const success = await processCheckout(selectedCustomerId, custName, paymentMethod, paid);
    if (success) {
      setIsCheckoutOpen(false);
      setShowReceipt(true);
      setAmountPaid("");
    }
  }

  const handlePrint = () => {
    window.print();
  }

  return (
    <MainLayout>
      <div className="flex flex-col lg:flex-row h-[calc(100vh-80px)] gap-4 pb-4">

        {/* --- LEFT SIDE: Product Grid --- */}
        <div className="flex-1 flex flex-col gap-4">
          {/* Header / Search */}
          <div className="bg-white p-4 rounded-xl border shadow-sm flex flex-col md:flex-row gap-4 items-center justify-between">
            <div>
              <h1 className="text-xl font-bold text-slate-800">Kasir / POS</h1>
              <p className="text-xs text-slate-500">
                {isLoading ? "Sinkronisasi data..." : `Menampilkan ${filteredItems.length} barang`}
              </p>
            </div>
            <div className="relative w-full md:w-96">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
              <Input
                ref={searchInputRef}
                placeholder="Ketik nama / kode / kategori..."
                className="pl-10 bg-slate-50 border-slate-200 focus:bg-white transition-colors"
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
              />
            </div>
          </div>

          {/* Product List */}
          <div className="flex-1 bg-slate-50/50 rounded-xl border border-dashed border-slate-200 overflow-y-auto p-4 custom-scrollbar">
            {isLoading ? (
              <div className="flex items-center justify-center h-full text-slate-400 animate-pulse">
                Memuat {allItems.length > 0 ? "sisa" : ""} data barang...
              </div>
            ) : filteredItems.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-full text-slate-400">
                <Search className="h-12 w-12 mb-2 opacity-20" />
                <p>Tidak ada barang yang cocok dengan &quot;{searchTerm}&quot;</p>
              </div>
            ) : (
              <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-3">
                {filteredItems.map(item => {
                  // --- STOCK FALLBACK LOGIC ---
                  const display = item.stockDisplay || 0;
                  const warehouse = item.stockWarehouse || 0;
                  const legacyStock = item.stock || 0;
                  // Use legacy if new fields are empty but legacy has value
                  const effectiveDisplay = display === 0 && warehouse === 0 && legacyStock > 0 ? legacyStock : display;

                  const totalStock = effectiveDisplay + warehouse;
                  const isLow = totalStock <= 0;

                  return (
                    <Card
                      key={item.id}
                      className={`cursor-pointer transition-all hover:shadow-md border-slate-200 group ${isLow ? 'opacity-60 grayscale' : 'hover:border-blue-300'}`}
                      onClick={() => !isLow && addToCart({ ...item, stockDisplay: effectiveDisplay })}
                    >
                      <div className="p-3">
                        <div className="flex justify-between items-start mb-2">
                          <Badge variant="outline" className="text-[10px] px-1 py-0 h-5 font-normal text-slate-500 bg-slate-50">
                            {item.code}
                          </Badge>
                          {isLow && <Badge variant="destructive" className="text-[10px] h-5">Habis</Badge>}
                        </div>
                        <h3 className="font-medium text-sm text-slate-800 line-clamp-2 min-h-[40px] leading-tight mb-2 group-hover:text-blue-600">
                          {item.name}
                        </h3>
                        <div className="flex justify-between items-end mt-2">
                          <div>
                            <p className="text-[10px] text-slate-400">Stok</p>
                            <p className="font-bold text-xs text-slate-600">{effectiveDisplay}</p>
                          </div>
                          <div className="text-right">
                            <p className="font-bold text-indigo-600">Rp {(item.sellPrice || 0).toLocaleString("id-ID")}</p>
                          </div>
                        </div>
                      </div>
                    </Card>
                  )
                })}
              </div>
            )}
          </div>
        </div>

        {/* --- RIGHT SIDE: Cart & Checkout --- */}
        <div className="w-full lg:w-[380px] flex flex-col bg-white rounded-xl border shadow-sm overflow-hidden h-full">
          <div className="p-4 bg-slate-50 border-b flex justify-between items-center">
            <div className="flex items-center gap-2">
              <ShoppingCart className="w-5 h-5 text-indigo-600" />
              <span className="font-bold text-slate-800">Keranjang</span>
            </div>
            {cart.length > 0 && (
              <Button variant="ghost" size="sm" onClick={clearCart} className="text-red-500 hover:text-red-600 hover:bg-red-50 h-8 px-2 text-xs">
                <Trash2 className="w-3 h-3 mr-1" /> Reset
              </Button>
            )}
          </div>

          {/* Cart Items */}
          <div className="flex-1 overflow-y-auto p-4 space-y-3 custom-scrollbar">
            {cart.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-48 text-center text-slate-400 mt-10">
                <ShoppingCart className="w-12 h-12 mb-3 opacity-20" />
                <p className="text-sm">Keranjang kosong.<br />Pilih barang di sebelah kiri.</p>
              </div>
            ) : (
              cart.map(item => (
                <div key={item.id} className="flex gap-3 bg-white p-2 rounded-lg border border-slate-100 shadow-sm relative group">
                  <div className="flex-1">
                    <p className="text-sm font-semibold text-slate-800 line-clamp-1">{item.name}</p>
                    <p className="text-xs text-indigo-600 font-medium">@ Rp {(item.sellPrice || 0).toLocaleString("id-ID")}</p>
                  </div>

                  <div className="flex flex-col items-end gap-1">
                    <p className="text-sm font-bold text-slate-900">Rp {((item.sellPrice || 0) * (item.quantity || 1)).toLocaleString("id-ID")}</p>
                    <div className="flex items-center gap-1 bg-slate-100 rounded-md p-1">
                      <button onClick={() => updateQuantity(item.id, (item.quantity || 1) - 1)} className="w-6 h-6 flex items-center justify-center bg-white rounded shadow-sm text-slate-600 hover:bg-slate-50 transition-colors">-</button>
                      <span className="w-6 text-center text-xs font-bold">{item.quantity}</span>
                      <button onClick={() => updateQuantity(item.id, (item.quantity || 1) + 1)} className="w-6 h-6 flex items-center justify-center bg-white rounded shadow-sm text-blue-600 hover:bg-blue-50 transition-colors">+</button>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>

          {/* Footer Summary */}
          <div className="p-4 bg-white border-t space-y-4 shadow-[0_-5px_15px_rgba(0,0,0,0.02)]">
            <div className="space-y-2">
              <div className="flex justify-between text-sm text-slate-500">
                <span>Total Item</span>
                <span>{cartSummary.totalItems} Pcs</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="font-bold text-slate-800">Total Biaya</span>
                <span className="text-2xl font-black text-indigo-600">Rp {cartSummary.totalAmount.toLocaleString("id-ID")}</span>
              </div>
            </div>

            <Dialog open={isCheckoutOpen} onOpenChange={setIsCheckoutOpen}>
              <DialogTrigger asChild>
                <Button className="w-full h-12 text-lg font-bold bg-indigo-600 hover:bg-indigo-700 shadow-lg shadow-indigo-200" disabled={cart.length === 0}>
                  Bayar Sekarang
                </Button>
              </DialogTrigger>
              <DialogContent className="sm:max-w-md">
                <DialogHeader>
                  <DialogTitle>Konfirmasi Pembayaran</DialogTitle>
                  <DialogDescription>Masukan detail pembayaran.</DialogDescription>
                </DialogHeader>

                <div className="space-y-4 py-2">
                  <div className="p-4 bg-slate-50 rounded-lg text-center border">
                    <p className="text-xs text-slate-500 uppercase tracking-widest">Total Tagihan</p>
                    <p className="text-3xl font-black text-indigo-600 mt-1">Rp {cartSummary.totalAmount.toLocaleString("id-ID")}</p>
                  </div>

                  <div className="space-y-2">
                    <Label>Pelanggan</Label>
                    <Select value={selectedCustomerId} onValueChange={setSelectedCustomerId}>
                      <SelectTrigger><SelectValue /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="umum">Pelanggan Umum</SelectItem>
                        {customers.map(c => <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>)}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label>Metode Pembayaran</Label>
                    <Tabs value={paymentMethod} onValueChange={(v) => setPaymentMethod(v as 'cash' | 'transfer')} className="w-full">
                      <TabsList className="grid w-full grid-cols-2">
                        <TabsTrigger value="cash"><DollarSign className="w-4 h-4 mr-2" />Tunai</TabsTrigger>
                        <TabsTrigger value="transfer"><CreditCard className="w-4 h-4 mr-2" />Transfer</TabsTrigger>
                      </TabsList>
                    </Tabs>
                  </div>

                  {paymentMethod === 'cash' && (
                    <div className="space-y-2">
                      <Label>Uang Diterima (Rp)</Label>
                      <Input
                        type="number"
                        placeholder="0"
                        className="text-right font-bold text-lg"
                        value={amountPaid}
                        onChange={(e) => setAmountPaid(e.target.value)}
                        autoFocus
                      />
                      {amountPaid && (Number(amountPaid) - cartSummary.totalAmount >= 0) && (
                        <div className="flex justify-between text-sm p-2 bg-green-50 text-green-700 rounded border border-green-200">
                          <span>Kembalian:</span>
                          <span className="font-bold">Rp {(Number(amountPaid) - cartSummary.totalAmount).toLocaleString("id-ID")}</span>
                        </div>
                      )}
                    </div>
                  )}
                </div>

                <DialogFooter className="sm:justify-between">
                  <Button variant="ghost" onClick={() => setIsCheckoutOpen(false)}>Batal</Button>
                  <Button onClick={handlePaymentSubmit} disabled={isProcessing} className="bg-green-600 hover:bg-green-700">
                    {isProcessing ? "Memproses..." : "Selesaikan Transaksi"}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </div>
        </div>

        {/* --- RECEIPT MODAL --- */}
        <Dialog open={showReceipt} onOpenChange={setShowReceipt}>
          <DialogContent className="max-w-sm bg-white">
            <DialogHeader>
              <DialogTitle className="text-center flex items-center justify-center gap-2">
                <Badge variant="outline" className="bg-green-50 text-green-600 border-green-200">SUKSES</Badge>
              </DialogTitle>
            </DialogHeader>

            {/* Receipt Preview */}
            <div id="receipt-area" className="py-4 px-2 bg-white text-xs font-mono border rounded shadow-sm">
              <div className="text-center mb-4 border-b pb-2 border-dashed">
                <h2 className="font-bold text-base">ANNUR MOTOR</h2>
                <p>Jl. Raya Magelang - Jogja</p>
                <p>0812-3456-7890</p>
              </div>

              {lastTransaction && (
                <div className="space-y-2 mb-4 border-b pb-2 border-dashed">
                  <div className="flex justify-between">
                    <span>Tgl:</span>
                    <span>{new Date().toLocaleDateString('id-ID')} {new Date().toLocaleTimeString()}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>No:</span>
                    <span>#{lastTransaction.id.slice(0, 8)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Plg:</span>
                    <span>{lastTransaction.customerName}</span>
                  </div>
                </div>
              )}

              <div className="space-y-1 mb-4 border-b pb-2 border-dashed">
                {lastTransaction?.items.map((item: any, idx: number) => (
                  <div key={idx} className="flex justify-between">
                    <span className="w-1/2 truncate">{item.itemName}</span>
                    <span className="w-1/8 text-center">x{item.quantity}</span>
                    <span className="w-1/3 text-right">{(item.sellPrice * item.quantity).toLocaleString("id-ID")}</span>
                  </div>
                ))}
              </div>

              <div className="space-y-1">
                <div className="flex justify-between font-bold text-sm">
                  <span>TOTAL</span>
                  <span>Rp {lastTransaction?.totalAmount.toLocaleString("id-ID")}</span>
                </div>
                {lastTransaction?.paymentMethod === 'cash' && (
                  <>
                    <div className="flex justify-between">
                      <span>Bayar</span>
                      <span>Rp {lastTransaction?.amountPaid?.toLocaleString("id-ID")}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Kembali</span>
                      <span>Rp {lastTransaction?.change?.toLocaleString("id-ID")}</span>
                    </div>
                  </>
                )}
                {lastTransaction?.paymentMethod === 'transfer' && (
                  <div className="text-center italic mt-2">(Pembayaran Transfer)</div>
                )}
              </div>

              <div className="text-center mt-6 text-[10px] text-slate-500">
                <p>Terima Kasih atas kunjungan Anda</p>
                <p>Barang yang dibeli tidak dapat ditukar</p>
              </div>
            </div>

            <DialogFooter className="flex-col gap-2 sm:flex-col">
              <Button onClick={handlePrint} className="w-full flex items-center justify-center gap-2">
                <Printer className="w-4 h-4" /> Cetak Struk
              </Button>
              <Button variant="outline" onClick={() => setShowReceipt(false)} className="w-full">
                Tutup & Transaksi Baru
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </MainLayout>
  )
}
