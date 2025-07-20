"use client"

import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Search, Package, AlertTriangle, CheckCircle, XCircle } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, getDocs } from "firebase/firestore"

// --- Interface untuk data item dari Firestore ---
interface StockItem {
  id: string
  code: string
  name: string
  category: string
  stock: number
  minStock: number
  buyPrice: number
}

export default function StockPage() {
  const [stockItems, setStockItems] = useState<StockItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterStatus, setFilterStatus] = useState<"all" | "safe" | "low" | "critical" | "empty">("all");

  // --- [BARU] Mengambil data real-time dari koleksi 'items' ---
  useEffect(() => {
    const fetchStockItems = async () => {
      setIsLoading(true);
      try {
        const itemsSnapshot = await getDocs(collection(db, "items"));
        const itemsList = itemsSnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        } as StockItem));
        setStockItems(itemsList);
      } catch (error) {
        console.error("Gagal mengambil data stok: ", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchStockItems();
  }, []);


  const getStockStatus = (stock: number, minStock: number) => {
    if (stock <= 0) return { status: "empty", text: "Habis", icon: XCircle }
    if (stock <= minStock * 0.5) return { status: "critical", text: "Kritis", icon: AlertTriangle }
    if (stock <= minStock) return { status: "low", text: "Rendah", icon: AlertTriangle }
    return { status: "safe", text: "Aman", icon: CheckCircle }
  }
  
  // --- [DIUBAH] Filter sekarang bekerja pada data real-time ---
  const filteredItems = stockItems.filter((item) => {
    const matchesSearch =
      (item.name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.code || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (item.category || '').toLowerCase().includes(searchTerm.toLowerCase())

    if (!matchesSearch) return false

    if (filterStatus === "all") return true

    const stockStatus = getStockStatus(item.stock || 0, item.minStock || 0)
    return stockStatus.status === filterStatus
  })

  // --- [DIUBAH] Kalkulasi ringkasan sekarang dinamis ---
  const stockSummary = {
    total: stockItems.length,
    safe: stockItems.filter((item) => getStockStatus(item.stock || 0, item.minStock || 0).status === "safe").length,
    low: stockItems.filter((item) => getStockStatus(item.stock || 0, item.minStock || 0).status === "low").length,
    critical: stockItems.filter((item) => getStockStatus(item.stock || 0, item.minStock || 0).status === "critical").length,
    empty: stockItems.filter((item) => getStockStatus(item.stock || 0, item.minStock || 0).status === "empty").length,
  }

  const totalValue = stockItems.reduce((sum, item) => sum + (item.stock || 0) * (item.buyPrice || 0), 0)

  if (isLoading) {
      return (
          <MainLayout>
            <div className="flex items-center justify-center min-h-[calc(100vh-80px)]">
                <p>Memuat data stok barang...</p>
            </div>
          </MainLayout>
      )
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Stok Barang</h1>
          <p className="text-gray-600">Monitoring dan kelola stok barang</p>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <Card className="cursor-pointer hover:shadow-md transition-shadow" onClick={() => setFilterStatus("all")}>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Total Item</p>
                  <p className="text-2xl font-bold">{stockSummary.total}</p>
                </div>
                <Package className="h-8 w-8 text-blue-600" />
              </div>
            </CardContent>
          </Card>
          <Card className="cursor-pointer hover:shadow-md transition-shadow" onClick={() => setFilterStatus("safe")}>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Stok Aman</p>
                  <p className="text-2xl font-bold text-green-600">{stockSummary.safe}</p>
                </div>
                <CheckCircle className="h-8 w-8 text-green-600" />
              </div>
            </CardContent>
          </Card>
          <Card className="cursor-pointer hover:shadow-md transition-shadow" onClick={() => setFilterStatus("low")}>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Stok Rendah</p>
                  <p className="text-2xl font-bold text-yellow-600">{stockSummary.low}</p>
                </div>
                <AlertTriangle className="h-8 w-8 text-yellow-600" />
              </div>
            </CardContent>
          </Card>
          <Card className="cursor-pointer hover:shadow-md transition-shadow" onClick={() => setFilterStatus("critical")}>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Stok Kritis</p>
                  <p className="text-2xl font-bold text-red-600">{stockSummary.critical}</p>
                </div>
                <AlertTriangle className="h-8 w-8 text-red-600" />
              </div>
            </CardContent>
          </Card>
          <Card className="cursor-pointer hover:shadow-md transition-shadow" onClick={() => setFilterStatus("empty")}>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Stok Habis</p>
                  <p className="text-2xl font-bold text-red-700">{stockSummary.empty}</p>
                </div>
                <XCircle className="h-8 w-8 text-red-700" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Value Summary */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Nilai Aset Stok</p>
                <p className="text-2xl font-bold">Rp {totalValue.toLocaleString("id-ID")}</p>
              </div>
              <p className="text-sm text-gray-600">Berdasarkan harga beli</p>
            </div>
          </CardContent>
        </Card>

        {/* Stock Table */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Package className="mr-2 h-5 w-5" />
              Daftar Stok Barang
            </CardTitle>
            <CardDescription>
              Menampilkan {filteredItems.length} dari {stockItems.length} total barang.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-2 mb-4">
              <Search className="h-4 w-4 text-gray-400" />
              <Input
                placeholder="Cari barang..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="max-w-sm"
              />
            </div>

            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-2">Kode</th>
                    <th className="text-left py-3 px-2">Nama Barang</th>
                    <th className="text-center py-3 px-2">Stok</th>
                    <th className="text-center py-3 px-2">Stok Min.</th>
                    <th className="text-center py-3 px-2">Status</th>
                    <th className="text-right py-3 px-2">Nilai Stok</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredItems.map((item) => {
                    const stockStatus = getStockStatus(item.stock, item.minStock)
                    const stockValue = (item.stock || 0) * (item.buyPrice || 0)
                    const StatusIcon = stockStatus.icon

                    return (
                      <tr key={item.id} className="border-b hover:bg-gray-50">
                        <td className="py-3 px-2 font-mono text-sm">{item.code}</td>
                        <td className="py-3 px-2 font-medium">{item.name}</td>
                        <td className="py-3 px-2 text-center font-bold">{item.stock}</td>
                        <td className="py-3 px-2 text-center text-sm text-gray-600">{item.minStock}</td>
                        <td className="py-3 px-2 text-center">
                          <div className="flex items-center justify-center">
                            <StatusIcon className={`h-4 w-4 mr-1 ${
                                stockStatus.status === "safe" ? "text-green-600" :
                                stockStatus.status === "low" ? "text-yellow-600" : "text-red-600"
                              }`}
                            />
                            <span className="text-xs font-medium">{stockStatus.text}</span>
                          </div>
                        </td>
                        <td className="py-3 px-2 text-right">Rp {stockValue.toLocaleString("id-ID")}</td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>

              {filteredItems.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  {searchTerm ? "Tidak ada barang yang ditemukan" : "Tidak ada data stok"}
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  )
}