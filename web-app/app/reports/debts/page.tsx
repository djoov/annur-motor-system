"use client"

import React, { useState, useEffect, useMemo } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { Search, Wallet, AlertTriangle, CheckCircle, Clock, CreditCard, History, RefreshCw, DollarSign } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, onSnapshot, doc, writeBatch, serverTimestamp, query, where, orderBy, Timestamp, arrayUnion, increment } from "firebase/firestore"
import { useAuth } from "@/components/auth-provider"
import { useToast } from "@/hooks/use-toast"

import type { Debt, DebtPaymentLog } from "@/types"

export default function DebtsPage() {
    const [debts, setDebts] = useState<Debt[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [searchTerm, setSearchTerm] = useState("")
    const [filterStatus, setFilterStatus] = useState<string>("active") // active = unpaid + partial

    // Payment Modal
    const [isPaymentOpen, setIsPaymentOpen] = useState(false)
    const [selectedDebt, setSelectedDebt] = useState<Debt | null>(null)
    const [paymentAmount, setPaymentAmount] = useState("")
    const [paymentNote, setPaymentNote] = useState("")
    const [isSaving, setIsSaving] = useState(false)

    // History Modal
    const [isHistoryOpen, setIsHistoryOpen] = useState(false)

    const { user } = useAuth()
    const { toast } = useToast()

    // Real-time Data Fetching
    useEffect(() => {
        setIsLoading(true)

        let q;
        if (filterStatus === "active") {
            q = query(
                collection(db, "debts"),
                where("status", "in", ["unpaid", "partial"]),
                orderBy("createdAt", "desc")
            )
        } else if (filterStatus === "paid") {
            q = query(
                collection(db, "debts"),
                where("status", "==", "paid"),
                orderBy("createdAt", "desc")
            )
        } else {
            q = query(collection(db, "debts"), orderBy("createdAt", "desc"))
        }

        const unsubscribe = onSnapshot(q, (snapshot) => {
            const fetchedDebts = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            } as Debt))
            setDebts(fetchedDebts)
            setIsLoading(false)
        }, (error) => {
            console.error("Error fetching debts:", error)
            toast({ title: "Gagal memuat data", variant: "destructive" })
            setIsLoading(false)
        })

        return () => unsubscribe()
    }, [filterStatus, toast])

    // Filtered by search
    const filteredDebts = useMemo(() => {
        return debts.filter(debt =>
            debt.customerName.toLowerCase().includes(searchTerm.toLowerCase())
        )
    }, [debts, searchTerm])

    // Summary stats
    const stats = useMemo(() => {
        const activeDebts = debts.filter(d => d.status !== 'paid')
        const totalRemaining = activeDebts.reduce((sum, d) => sum + (d.remainingAmount || 0), 0)
        const overdue = activeDebts.filter(d => {
            if (!d.dueDate) return false
            const due = d.dueDate.toDate ? d.dueDate.toDate() : new Date(d.dueDate)
            return due < new Date()
        }).length
        return { activeCount: activeDebts.length, totalRemaining, overdue }
    }, [debts])

    // Open payment modal
    const openPaymentModal = (debt: Debt) => {
        setSelectedDebt(debt)
        setPaymentAmount("")
        setPaymentNote("")
        setIsPaymentOpen(true)
    }

    // Open history modal
    const openHistoryModal = (debt: Debt) => {
        setSelectedDebt(debt)
        setIsHistoryOpen(true)
    }

    // Handle payment submission
    const handlePayment = async () => {
        if (!selectedDebt || !paymentAmount) return

        const amount = Number(paymentAmount)
        if (amount <= 0 || amount > selectedDebt.remainingAmount) {
            toast({ title: "Jumlah tidak valid", description: "Tidak boleh melebihi sisa hutang.", variant: "destructive" })
            return
        }

        setIsSaving(true)
        try {
            const batch = writeBatch(db)
            const debtRef = doc(db, "debts", selectedDebt.id)

            const newRemaining = selectedDebt.remainingAmount - amount
            const newStatus = newRemaining === 0 ? 'paid' : 'partial'

            const paymentLog = {
                date: Timestamp.now(),
                amount: amount,
                note: paymentNote || `Pembayaran oleh ${user?.name || 'Admin'}`
            }

            // Update debt
            batch.update(debtRef, {
                remainingAmount: newRemaining,
                status: newStatus,
                logs: arrayUnion(paymentLog),
                updatedAt: serverTimestamp()
            })

            // Update customer totalDebt
            if (selectedDebt.customerId && selectedDebt.customerId !== 'umum') {
                const customerRef = doc(db, "customers", selectedDebt.customerId)
                batch.update(customerRef, {
                    totalDebt: increment(-amount),
                    updatedAt: serverTimestamp()
                })
            }

            await batch.commit()

            toast({
                title: newStatus === 'paid' ? "Hutang Lunas!" : "Pembayaran Dicatat",
                description: `Rp ${amount.toLocaleString('id-ID')} berhasil dicatat.`
            })
            setIsPaymentOpen(false)
        } catch (error) {
            console.error(error)
            toast({ title: "Gagal menyimpan", variant: "destructive" })
        } finally {
            setIsSaving(false)
        }
    }

    const formatCurrency = (amount: number) => `Rp ${(amount || 0).toLocaleString('id-ID')}`
    const formatDate = (timestamp: any) => {
        if (!timestamp) return '-'
        const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp)
        return date.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
    }

    return (
        <MainLayout>
            <div className="space-y-6 pb-20">
                {/* Header */}
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                    <div>
                        <h1 className="text-3xl font-bold text-slate-800">Laporan Piutang</h1>
                        <p className="text-slate-500 mt-1">Kelola hutang pelanggan dan catat pembayaran cicilan.</p>
                    </div>
                    <Button variant="outline" onClick={() => window.location.reload()}>
                        <RefreshCw className="mr-2 h-4 w-4" /> Refresh
                    </Button>
                </div>

                {/* Summary Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <Card className="bg-gradient-to-br from-orange-500 to-orange-600 text-white border-none shadow-lg">
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium text-orange-100">Total Piutang</CardTitle>
                            <Wallet className="h-5 w-5 text-orange-200" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold">{formatCurrency(stats.totalRemaining)}</div>
                            <p className="text-xs text-orange-200">{stats.activeCount} hutang aktif</p>
                        </CardContent>
                    </Card>

                    <Card className="cursor-pointer hover:border-amber-300 transition-all border-amber-100 bg-amber-50/30">
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium text-amber-700">Jatuh Tempo</CardTitle>
                            <AlertTriangle className="h-5 w-5 text-amber-500" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-amber-700">{stats.overdue}</div>
                            <p className="text-xs text-amber-600">Lewat tanggal jatuh tempo</p>
                        </CardContent>
                    </Card>

                    <Card className="cursor-pointer hover:border-emerald-300 transition-all border-emerald-100 bg-emerald-50/30">
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium text-emerald-700">Aktif</CardTitle>
                            <Clock className="h-5 w-5 text-emerald-500" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-emerald-700">{stats.activeCount}</div>
                            <p className="text-xs text-emerald-600">Belum lunas / cicilan</p>
                        </CardContent>
                    </Card>
                </div>

                {/* Main Table */}
                <Card className="border-slate-200 shadow-sm">
                    <CardHeader>
                        <div className="flex flex-col md:flex-row justify-between md:items-center gap-4">
                            <div>
                                <CardTitle>Daftar Hutang Pelanggan</CardTitle>
                                <CardDescription>Klik untuk mencatat pembayaran atau lihat riwayat.</CardDescription>
                            </div>
                            <div className="flex gap-2">
                                <div className="relative w-full md:w-64">
                                    <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                                    <Input
                                        placeholder="Cari nama pelanggan..."
                                        value={searchTerm}
                                        onChange={(e) => setSearchTerm(e.target.value)}
                                        className="pl-9"
                                    />
                                </div>
                                <Select value={filterStatus} onValueChange={setFilterStatus}>
                                    <SelectTrigger className="w-[140px]">
                                        <SelectValue />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="active">Belum Lunas</SelectItem>
                                        <SelectItem value="paid">Sudah Lunas</SelectItem>
                                        <SelectItem value="all">Semua</SelectItem>
                                    </SelectContent>
                                </Select>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent>
                        <div className="rounded-lg border border-slate-100 overflow-hidden">
                            <table className="w-full text-sm">
                                <thead className="bg-slate-50 text-slate-500 font-medium border-b border-slate-100">
                                    <tr>
                                        <th className="px-4 py-3 text-left">Pelanggan</th>
                                        <th className="px-4 py-3 text-right">Total Tagihan</th>
                                        <th className="px-4 py-3 text-right">Sisa Hutang</th>
                                        <th className="px-4 py-3 text-center">Status</th>
                                        <th className="px-4 py-3 text-center">Jatuh Tempo</th>
                                        <th className="px-4 py-3 text-right">Aksi</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {isLoading ? (
                                        <tr><td colSpan={6} className="h-32 text-center text-slate-400">Memuat data...</td></tr>
                                    ) : filteredDebts.length === 0 ? (
                                        <tr><td colSpan={6} className="h-32 text-center text-slate-400">
                                            <CheckCircle className="w-12 h-12 mx-auto mb-2 text-emerald-200" />
                                            Tidak ada data hutang
                                        </td></tr>
                                    ) : (
                                        filteredDebts.map((debt) => {
                                            const isOverdue = debt.dueDate && (debt.dueDate.toDate ? debt.dueDate.toDate() : new Date(debt.dueDate)) < new Date() && debt.status !== 'paid'
                                            return (
                                                <tr key={debt.id} className="hover:bg-slate-50/50 transition-colors">
                                                    <td className="px-4 py-3">
                                                        <div className="font-medium text-slate-800">{debt.customerName}</div>
                                                        <div className="text-xs text-slate-400">{formatDate(debt.createdAt)}</div>
                                                    </td>
                                                    <td className="px-4 py-3 text-right font-medium text-slate-600">
                                                        {formatCurrency(debt.totalAmount)}
                                                    </td>
                                                    <td className="px-4 py-3 text-right">
                                                        <span className={`font-bold ${debt.remainingAmount > 0 ? 'text-red-600' : 'text-emerald-600'}`}>
                                                            {formatCurrency(debt.remainingAmount)}
                                                        </span>
                                                    </td>
                                                    <td className="px-4 py-3 text-center">
                                                        <Badge variant={debt.status === 'paid' ? 'default' : debt.status === 'partial' ? 'secondary' : 'destructive'}
                                                            className={debt.status === 'paid' ? 'bg-emerald-100 text-emerald-700 hover:bg-emerald-100' : ''}>
                                                            {debt.status === 'paid' ? 'Lunas' : debt.status === 'partial' ? 'Cicilan' : 'Belum Bayar'}
                                                        </Badge>
                                                    </td>
                                                    <td className="px-4 py-3 text-center">
                                                        {debt.dueDate ? (
                                                            <span className={isOverdue ? 'text-red-600 font-medium' : 'text-slate-600'}>
                                                                {formatDate(debt.dueDate)}
                                                                {isOverdue && <AlertTriangle className="inline w-3 h-3 ml-1" />}
                                                            </span>
                                                        ) : '-'}
                                                    </td>
                                                    <td className="px-4 py-3 text-right">
                                                        <div className="flex justify-end gap-1">
                                                            {debt.status !== 'paid' && (
                                                                <Button variant="ghost" size="sm" className="h-8 text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50" onClick={() => openPaymentModal(debt)}>
                                                                    <DollarSign className="w-4 h-4 mr-1" /> Bayar
                                                                </Button>
                                                            )}
                                                            <Button variant="ghost" size="sm" className="h-8 text-slate-500 hover:text-slate-700" onClick={() => openHistoryModal(debt)}>
                                                                <History className="w-4 h-4" />
                                                            </Button>
                                                        </div>
                                                    </td>
                                                </tr>
                                            )
                                        })
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </CardContent>
                </Card>

                {/* Payment Modal */}
                <Dialog open={isPaymentOpen} onOpenChange={setIsPaymentOpen}>
                    <DialogContent className="sm:max-w-md">
                        <DialogHeader>
                            <DialogTitle className="flex items-center gap-2">
                                <CreditCard className="w-5 h-5 text-emerald-600" />
                                Bayar Hutang
                            </DialogTitle>
                            <DialogDescription>
                                Catat pembayaran untuk <strong>{selectedDebt?.customerName}</strong>
                            </DialogDescription>
                        </DialogHeader>

                        <div className="space-y-4 py-2">
                            <div className="p-3 bg-slate-50 rounded-lg flex justify-between items-center border">
                                <span className="text-sm text-slate-500">Sisa Hutang</span>
                                <span className="text-lg font-bold text-red-600">{formatCurrency(selectedDebt?.remainingAmount || 0)}</span>
                            </div>

                            <div className="space-y-2">
                                <Label>Jumlah Pembayaran</Label>
                                <div className="relative">
                                    <span className="absolute left-3 top-2.5 text-slate-400">Rp</span>
                                    <Input
                                        type="number"
                                        min={0}
                                        max={selectedDebt?.remainingAmount || 0}
                                        value={paymentAmount}
                                        onChange={(e) => setPaymentAmount(e.target.value)}
                                        className="pl-9 text-right font-bold"
                                        placeholder="0"
                                    />
                                </div>
                            </div>

                            <div className="space-y-2">
                                <Label>Catatan (Opsional)</Label>
                                <Textarea
                                    value={paymentNote}
                                    onChange={(e) => setPaymentNote(e.target.value)}
                                    placeholder="Contoh: Cicilan ke-2"
                                    rows={2}
                                />
                            </div>

                            {paymentAmount && Number(paymentAmount) > 0 && (
                                <div className="p-3 bg-emerald-50 rounded-lg flex justify-between items-center border border-emerald-100">
                                    <span className="text-sm text-emerald-600">Sisa Setelah Bayar</span>
                                    <span className="text-lg font-bold text-emerald-700">
                                        {formatCurrency((selectedDebt?.remainingAmount || 0) - Number(paymentAmount))}
                                    </span>
                                </div>
                            )}
                        </div>

                        <DialogFooter>
                            <Button variant="ghost" onClick={() => setIsPaymentOpen(false)} disabled={isSaving}>Batal</Button>
                            <Button onClick={handlePayment} disabled={isSaving || !paymentAmount} className="bg-emerald-600 hover:bg-emerald-700">
                                {isSaving ? "Menyimpan..." : "Simpan Pembayaran"}
                            </Button>
                        </DialogFooter>
                    </DialogContent>
                </Dialog>

                {/* History Modal */}
                <Dialog open={isHistoryOpen} onOpenChange={setIsHistoryOpen}>
                    <DialogContent className="sm:max-w-md">
                        <DialogHeader>
                            <DialogTitle className="flex items-center gap-2">
                                <History className="w-5 h-5 text-indigo-600" />
                                Riwayat Pembayaran
                            </DialogTitle>
                            <DialogDescription>
                                <strong>{selectedDebt?.customerName}</strong> - Total: {formatCurrency(selectedDebt?.totalAmount || 0)}
                            </DialogDescription>
                        </DialogHeader>

                        <div className="space-y-3 py-2 max-h-[300px] overflow-y-auto">
                            {selectedDebt?.logs && selectedDebt.logs.length > 0 ? (
                                selectedDebt.logs.map((log, idx) => (
                                    <div key={idx} className="flex justify-between items-center p-3 bg-slate-50 rounded-lg border">
                                        <div>
                                            <p className="font-medium text-slate-800">{formatCurrency(log.amount)}</p>
                                            <p className="text-xs text-slate-500">{log.note || 'Pembayaran'}</p>
                                        </div>
                                        <span className="text-xs text-slate-400">{formatDate(log.date)}</span>
                                    </div>
                                ))
                            ) : (
                                <p className="text-center text-slate-400 py-4">Belum ada riwayat pembayaran</p>
                            )}
                        </div>

                        <DialogFooter>
                            <Button variant="outline" onClick={() => setIsHistoryOpen(false)}>Tutup</Button>
                        </DialogFooter>
                    </DialogContent>
                </Dialog>
            </div>
        </MainLayout>
    )
}
