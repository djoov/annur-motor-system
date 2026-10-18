"use client"

import { useState, useEffect, useMemo } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { collection, onSnapshot, orderBy, query, where, Timestamp } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { endOfLocalDay, localDateKey, paymentLabel, startOfLocalDay } from "@/lib/shop-data"
import { Search, Eye, Calendar, FileText, ShoppingBag, User, CreditCard } from "lucide-react"

// Item fields as written by the mobile app (older docs may only have some).
interface TransactionItem {
  id?: string
  itemId?: string
  name?: string
  itemName?: string
  sellPrice?: number
  quantity: number
}

interface Transaction {
  id: string
  transactionDate: Timestamp
  totalAmount: number
  totalProfit: number
  customerName: string
  paymentMethod?: string
  type?: string
  has_return?: boolean
  items: TransactionItem[]
}

const rupiah = (value: number) => {
  const amount = value || 0
  return `${amount < 0 ? "−" : ""}Rp ${Math.abs(amount).toLocaleString("id-ID")}`
}

const badgeClass: Record<string, string> = {
  Hutang: "bg-amber-100 text-amber-800 hover:bg-amber-100",
  Retur: "bg-red-100 text-red-700 hover:bg-red-100",
  Transfer: "bg-blue-100 text-blue-700 hover:bg-blue-100",
  Tunai: "bg-slate-100 text-slate-600 hover:bg-slate-100",
}

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState("")
  const [selectedTransaction, setSelectedTransaction] = useState<Transaction | null>(null)

  // Date Filters (local dates, default last 7 days)
  const [startDate, setStartDate] = useState(() => {
    const date = new Date();
    date.setDate(date.getDate() - 6);
    return localDateKey(date);
  })
  const [endDate, setEndDate] = useState(() => localDateKey(new Date()))

  // Only the chosen date range is read, so the page stays cheap as history grows.
  useEffect(() => {
    if (!startDate || !endDate) return;
    setIsLoading(true);
    const q = query(
      collection(db, "transactions"),
      where("transactionDate", ">=", Timestamp.fromDate(startOfLocalDay(startDate))),
      where("transactionDate", "<=", Timestamp.fromDate(endOfLocalDay(endDate))),
      orderBy("transactionDate", "desc")
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      } as Transaction));
      setTransactions(data);
      setIsLoading(false);
    }, (error) => {
      console.error("Error fetching transactions:", error);
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, [startDate, endDate]);

  const filteredTransactions = useMemo(() => {
    const searchLower = searchTerm.toLowerCase();
    if (!searchLower) return transactions;
    return transactions.filter(t =>
      (t.customerName || "").toLowerCase().includes(searchLower) ||
      t.id.toLowerCase().includes(searchLower)
    );
  }, [transactions, searchTerm]);

  return (
    <MainLayout>
      <div className="space-y-6 pb-20">
        {/* Title Section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-slate-800">Riwayat Transaksi</h1>
            <p className="text-slate-500 mt-1">Daftar lengkap transaksi penjualan dan retur dengan detail item.</p>
          </div>
        </div>

        {/* Filters Card */}
        <Card className="border-slate-200 shadow-sm bg-white">
          <CardContent className="p-4 flex flex-col md:flex-row gap-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                <Input
                  placeholder="Cari No. Struk atau Nama Pelanggan..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-9"
                />
              </div>
            </div>
            <div className="flex gap-2 items-center">
              <div className="relative">
                <Calendar className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                <Input type="date" className="pl-9 w-40" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
              </div>
              <span className="text-slate-400">-</span>
              <div className="relative">
                <Calendar className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                <Input type="date" className="pl-9 w-40" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Transactions Table */}
        <Card className="border-slate-200 shadow-sm">
          <CardHeader className="pb-2">
            <CardTitle className="text-lg flex items-center gap-2">
              <FileText className="w-5 h-5 text-indigo-600" />
              Daftar Transaksi
            </CardTitle>
            <CardDescription>Menampilkan {filteredTransactions.length} transaksi.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="rounded-lg border border-slate-100 overflow-hidden">
              <Table>
                <TableHeader className="bg-slate-50">
                  <TableRow>
                    <TableHead className="w-[180px]">Waktu Transaksi</TableHead>
                    <TableHead>No. Struk</TableHead>
                    <TableHead>Pelanggan</TableHead>
                    <TableHead className="text-center">Metode</TableHead>
                    <TableHead className="text-right">Total Belanja</TableHead>
                    <TableHead className="w-[100px] text-center">Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {isLoading ? (
                    <TableRow>
                      <TableCell colSpan={6} className="h-24 text-center text-slate-500">
                        Memuat data transaksi...
                      </TableCell>
                    </TableRow>
                  ) : filteredTransactions.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className="h-24 text-center text-slate-500">
                        Tidak ada transaksi yang ditemukan.
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredTransactions.map((trx) => {
                      const label = paymentLabel(trx);
                      return (
                        <TableRow key={trx.id} className="hover:bg-slate-50/50">
                          <TableCell className="font-medium text-slate-700">
                            {trx.transactionDate?.toDate ? trx.transactionDate.toDate().toLocaleString("id-ID", {
                              day: '2-digit', month: 'short', year: 'numeric',
                              hour: '2-digit', minute: '2-digit'
                            }) : "-"}
                          </TableCell>
                          <TableCell className="font-mono text-xs text-slate-500">{trx.id.substring(0, 8)}...</TableCell>
                          <TableCell>
                            <div className="flex items-center gap-2">
                              <User className="w-3 h-3 text-slate-400" />
                              <span className="font-medium text-slate-700">{trx.customerName || "Umum"}</span>
                            </div>
                          </TableCell>
                          <TableCell className="text-center">
                            <div className="flex items-center justify-center gap-1">
                              <Badge variant="secondary" className={`font-normal text-xs ${badgeClass[label]}`}>
                                {label}
                              </Badge>
                              {trx.has_return && (
                                <Badge variant="outline" className="font-normal text-xs text-red-600 border-red-200">
                                  Ada retur
                                </Badge>
                              )}
                            </div>
                          </TableCell>
                          <TableCell className={`text-right font-bold ${(trx.totalAmount || 0) < 0 ? "text-red-600" : "text-indigo-600"}`}>
                            {rupiah(trx.totalAmount)}
                          </TableCell>
                          <TableCell className="text-center">
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-8 w-8 p-0 text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                              onClick={() => setSelectedTransaction(trx)}
                            >
                              <Eye className="w-4 h-4" />
                            </Button>
                          </TableCell>
                        </TableRow>
                      );
                    })
                  )}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>

        {/* Transaction Detail Dialog */}
        <Dialog open={!!selectedTransaction} onOpenChange={(open) => !open && setSelectedTransaction(null)}>
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <ShoppingBag className="w-5 h-5 text-indigo-600" />
                Detail Transaksi
              </DialogTitle>
              <DialogDescription>
                No. Struk: <span className="font-mono text-xs text-slate-600">{selectedTransaction?.id}</span>
              </DialogDescription>
            </DialogHeader>

            {selectedTransaction && (
              <div className="space-y-4">
                {/* Summary Info */}
                <div className="grid grid-cols-2 gap-4 text-sm bg-slate-50 p-3 rounded-lg border border-slate-100">
                  <div>
                    <p className="text-xs text-slate-400">Waktu</p>
                    <p className="font-medium text-slate-700">
                      {selectedTransaction.transactionDate?.toDate?.().toLocaleString("id-ID") ?? "-"}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-400">Pembayaran</p>
                    <div className="flex items-center gap-1 font-medium text-slate-700">
                      <CreditCard className="w-3 h-3" />
                      {paymentLabel(selectedTransaction)}
                    </div>
                  </div>
                  <div>
                    <p className="text-xs text-slate-400">Pelanggan</p>
                    <p className="font-medium text-slate-700">{selectedTransaction.customerName}</p>
                  </div>
                </div>

                {/* Items List */}
                <div>
                  <h4 className="text-sm font-semibold text-slate-800 mb-2">
                    {selectedTransaction.type === "return" ? "Item Diretur" : "Item Dibeli"}
                  </h4>
                  <div className="border rounded-lg divide-y divide-slate-100 max-h-[300px] overflow-y-auto">
                    {(selectedTransaction.items || []).map((item, idx) => {
                      const price = item.sellPrice || 0;
                      const qty = item.quantity || 0;
                      return (
                        <div key={idx} className="p-3 flex justify-between items-center text-sm">
                          <div>
                            <p className="font-medium text-slate-700 line-clamp-1">{item.itemName || item.name || "-"}</p>
                            <p className="text-xs text-slate-500">
                              {Math.abs(qty)} x Rp {price.toLocaleString("id-ID")}
                            </p>
                          </div>
                          <p className="font-semibold text-slate-800">
                            {rupiah(price * qty)}
                          </p>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* Grand Total */}
                <div className="flex justify-between items-center pt-4 border-t border-slate-200">
                  <span className="text-base font-bold text-slate-600">Total Transaksi</span>
                  <span className={`text-xl font-black ${(selectedTransaction.totalAmount || 0) < 0 ? "text-red-600" : "text-indigo-600"}`}>
                    {rupiah(selectedTransaction.totalAmount)}
                  </span>
                </div>
              </div>
            )}
          </DialogContent>
        </Dialog>
      </div>
    </MainLayout>
  )
}
