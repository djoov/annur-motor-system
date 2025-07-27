"use client"

import { useState, useEffect, useMemo } from "react"
import dynamic from "next/dynamic"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Button } from "@/components/ui/button"
import { Calendar, Download } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, getDocs, query, orderBy, Timestamp } from "firebase/firestore"

// --- [DIPERBAIKI] Muat komponen grafik secara dinamis hanya di sisi klien ---
const DailySalesChart = dynamic(
    () => import('@/components/layout/DailySalesChart').then(mod => mod.DailySalesChart),
    { 
        ssr: false,
        loading: () => <div className="text-center p-10">Memuat data grafik...</div>
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
  const [startDate, setStartDate] = useState(() => {
    const date = new Date();
    date.setDate(date.getDate() - 6);
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
          if (trx.transactionDate) { // Pastikan timestamp ada
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
        setAllSalesData(Object.values(dailyData));
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
    link.setAttribute("download", `laporan_penjualan_harian_${startDate}_${endDate}.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Laporan Penjualan Harian</h1>
            <p className="text-gray-600">Analisis penjualan dan omzet harian berdasarkan data transaksi nyata.</p>
          </div>
          <Button onClick={exportData} variant="outline" disabled={filteredData.length === 0}>
            <Download className="mr-2 h-4 w-4" /> Export CSV
          </Button>
        </div>

        <Card>
          <CardHeader><CardTitle className="flex items-center"><Calendar className="mr-2 h-5 w-5" />Filter Periode</CardTitle></CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div><Label htmlFor="startDate">Tanggal Mulai</Label><Input id="startDate" type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} /></div>
              <div><Label htmlFor="endDate">Tanggal Akhir</Label><Input id="endDate" type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} /></div>
            </div>
          </CardContent>
        </Card>

        {isLoading ? <p className="text-center p-10">Memuat data laporan...</p> : <DailySalesChart data={filteredData} />}
      </div>
    </MainLayout>
  )
}
