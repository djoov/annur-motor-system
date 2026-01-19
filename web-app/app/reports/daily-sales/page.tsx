"use client"

import { useState, useEffect, useMemo } from "react"
import dynamic from "next/dynamic"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Button } from "@/components/ui/button"
import { Calendar, Download, FileSpreadsheet, Search } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, getDocs, query, orderBy, Timestamp } from "firebase/firestore"

// Load chart dynamically to avoid SSR issues
const DailySalesChart = dynamic(
  () => import('@/components/layout/DailySalesChart').then(mod => mod.DailySalesChart),
  {
    ssr: false,
    loading: () => <div className="h-[400px] w-full flex items-center justify-center bg-slate-50 rounded-xl animate-pulse text-slate-400">Memuat Visualisasi...</div>
  }
);

interface DailySales {
  date: string
  transactions: number
  revenue: number
  profit: number
  items_sold: number
}

export default function DailySalesPage() {
  const [allSalesData, setAllSalesData] = useState<DailySales[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Default to last 30 days
  const [startDate, setStartDate] = useState(() => {
    const date = new Date();
    date.setDate(date.getDate() - 29);
    return date.toISOString().split('T')[0];
  });
  const [endDate, setEndDate] = useState(() => new Date().toISOString().split('T')[0]);

  useEffect(() => {
    const fetchSalesData = async () => {
      setIsLoading(true);
      try {
        const transactionsQuery = query(collection(db, "transactions"), orderBy("transactionDate", "asc"));
        const querySnapshot = await getDocs(transactionsQuery);
        const dailyData: { [key: string]: DailySales } = {};

        querySnapshot.forEach(doc => {
          const trx = doc.data();
          if (trx.transactionDate) {
            const date = (trx.transactionDate as Timestamp).toDate().toISOString().split('T')[0];
            if (!dailyData[date]) {
              dailyData[date] = { date, transactions: 0, revenue: 0, profit: 0, items_sold: 0 };
            }
            dailyData[date].transactions += 1;
            dailyData[date].revenue += trx.totalAmount || 0;
            dailyData[date].profit += trx.totalProfit || 0;
            dailyData[date].items_sold += (trx.items || []).reduce((sum: number, item: any) => sum + (item.quantity || 0), 0);
          }
        });

        // Sort keys to ensure order
        const sortedKeys = Object.keys(dailyData).sort();
        setAllSalesData(sortedKeys.map(key => dailyData[key]));
      } catch (error) {
        console.error("Gagal mengambil data penjualan:", error);
      } finally {
        setIsLoading(false);
      }
    };
    fetchSalesData();
  }, []);

  const filteredData = useMemo(() => allSalesData.filter((item) => {
    const itemDate = new Date(item.date)
    const start = new Date(startDate)
    const end = new Date(endDate)
    end.setHours(23, 59, 59, 999);
    return itemDate >= start && itemDate <= end
  }), [allSalesData, startDate, endDate]);

  const exportData = () => {
    const csvContent = [
      ["Tanggal", "Transaksi", "Omzet", "Keuntungan", "Item Terjual"].join(","),
      ...filteredData.map((item) =>
        [item.date, item.transactions, item.revenue, item.profit, item.items_sold].join(","),
      ),
    ].join("\n")
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" })
    const link = document.createElement("a")
    const url = URL.createObjectURL(blob)
    link.setAttribute("href", url)
    link.setAttribute("download", `Laporan_Penjualan_${startDate}_${endDate}.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  // Helper for quick date selection
  const setRange = (days: number) => {
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - days + 1);
    setEndDate(end.toISOString().split('T')[0]);
    setStartDate(start.toISOString().split('T')[0]);
  }

  return (
    <MainLayout>
      <div className="space-y-8 pb-20">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-slate-800">Laporan Penjualan</h1>
            <p className="text-slate-500 mt-1">Pantau performa penjualan dan profitabilitas harian toko Anda.</p>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={() => setRange(7)}>7 Hari</Button>
            <Button variant="outline" size="sm" onClick={() => setRange(30)}>30 Hari</Button>
            <Button onClick={exportData} disabled={filteredData.length === 0} className="bg-emerald-600 hover:bg-emerald-700">
              <FileSpreadsheet className="mr-2 h-4 w-4" /> Export Excel
            </Button>
          </div>
        </div>

        {/* Filters */}
        <Card className="bg-white border-slate-200">
          <CardContent className="p-4 pt-4">
            <div className="flex flex-col md:flex-row gap-4 items-end">
              <div className="grid gap-1.5 flex-1">
                <Label className="text-xs text-slate-500 uppercase tracking-wide">Dari Tanggal</Label>
                <div className="relative">
                  <Calendar className="absolute left-2.5 top-2.5 h-4 w-4 text-slate-400" />
                  <Input type="date" className="pl-9" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
                </div>
              </div>
              <div className="grid gap-1.5 flex-1">
                <Label className="text-xs text-slate-500 uppercase tracking-wide">Sampai Tanggal</Label>
                <div className="relative">
                  <Calendar className="absolute left-2.5 top-2.5 h-4 w-4 text-slate-400" />
                  <Input type="date" className="pl-9" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
                </div>
              </div>
              <div className="pb-0.5">
                <p className="text-sm text-slate-500">
                  Menampilkan data <span className="font-bold text-slate-800">{filteredData.length}</span> hari
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Charts & Summary */}
        {isLoading ? (
          <div className="h-64 flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
          </div>
        ) : filteredData.length > 0 ? (
          <DailySalesChart data={filteredData} />
        ) : (
          <div className="text-center py-20 bg-slate-50 rounded-xl border border-dashed text-slate-400">
            Tidak ada data penjualan pada periode ini.
          </div>
        )}

        {/* Detailed Table */}
        {filteredData.length > 0 && (
          <Card className="border-slate-200 shadow-sm">
            <CardHeader>
              <CardTitle>Rincian Data Harian</CardTitle>
              <CardDescription>Tabel detail angka penjualan per hari.</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto rounded-lg border border-slate-100">
                <table className="w-full text-sm">
                  <thead className="bg-slate-50 text-slate-500 font-medium">
                    <tr>
                      <th className="px-4 py-3 text-left">Tanggal</th>
                      <th className="px-4 py-3 text-center">Jumlah Transaksi</th>
                      <th className="px-4 py-3 text-center">Item Terjual</th>
                      <th className="px-4 py-3 text-right">Omzet</th>
                      <th className="px-4 py-3 text-right">Profit</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredData.map((item, idx) => (
                      <tr key={idx} className="hover:bg-slate-50/50">
                        <td className="px-4 py-3 font-medium text-slate-700">
                          {new Date(item.date).toLocaleDateString("id-ID", { weekday: 'short', day: 'numeric', month: 'long', year: 'numeric' })}
                        </td>
                        <td className="px-4 py-3 text-center text-slate-600">{item.transactions}</td>
                        <td className="px-4 py-3 text-center text-slate-600">{item.items_sold}</td>
                        <td className="px-4 py-3 text-right font-medium text-indigo-600">Rp {item.revenue.toLocaleString("id-ID")}</td>
                        <td className="px-4 py-3 text-right font-medium text-emerald-600">Rp {item.profit.toLocaleString("id-ID")}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </MainLayout>
  )
}
