"use client"

import { useState, useEffect, useMemo } from "react"
import dynamic from "next/dynamic"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Button } from "@/components/ui/button"
import { Calendar, FileSpreadsheet } from "lucide-react"
import { collection, getDocs, query, orderBy, Timestamp } from "firebase/firestore"
import { db } from "@/lib/firebase"

const ProfitChart = dynamic(
  () => import('@/components/layout/ProfitChart').then(mod => mod.ProfitChart),
  {
    ssr: false,
    loading: () => <div className="h-[400px] w-full flex items-center justify-center bg-slate-50 rounded-xl animate-pulse text-slate-400">Memuat Analisis Profit...</div>
  }
);

interface DailyProfitData {
  date: string;
  profit: number;
  revenue: number;
}

export default function ProfitReportPage() {
  const [profitData, setProfitData] = useState<DailyProfitData[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Default last 30 days
  const [startDate, setStartDate] = useState(() => {
    const date = new Date();
    date.setDate(date.getDate() - 29);
    return date.toISOString().split('T')[0];
  });
  const [endDate, setEndDate] = useState(() => new Date().toISOString().split('T')[0]);

  useEffect(() => {
    const fetchProfitData = async () => {
      setIsLoading(true);
      try {
        const q = query(collection(db, "transactions"), orderBy("transactionDate", "asc"));
        const querySnapshot = await getDocs(q);

        const dailyData: { [key: string]: { profit: number, revenue: number } } = {};

        querySnapshot.forEach(doc => {
          const transaction = doc.data();
          if (transaction.transactionDate) {
            const date = (transaction.transactionDate as Timestamp).toDate().toISOString().split('T')[0];

            if (!dailyData[date]) {
              dailyData[date] = { profit: 0, revenue: 0 };
            }

            dailyData[date].profit += transaction.totalProfit || 0;
            dailyData[date].revenue += transaction.totalAmount || 0;
          }
        });

        const formattedData = Object.keys(dailyData).sort().map(date => ({
          date: date,
          profit: dailyData[date].profit,
          revenue: dailyData[date].revenue,
        }));

        setProfitData(formattedData);
      } catch (error) {
        console.error("Error fetching profit data:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchProfitData();
  }, []);

  const filteredData = useMemo(() => profitData.filter(item => {
    return item.date >= startDate && item.date <= endDate;
  }), [profitData, startDate, endDate]);

  // Helper for quick date selection
  const setRange = (days: number) => {
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - days + 1);
    setEndDate(end.toISOString().split('T')[0]);
    setStartDate(start.toISOString().split('T')[0]);
  }

  const exportData = () => {
    const csvContent = [
      ["Tanggal", "Omzet", "Keuntungan", "Margin %"].join(","),
      ...filteredData.map((item) => {
        const margin = item.revenue > 0 ? (item.profit / item.revenue) * 100 : 0;
        return [item.date, item.revenue, item.profit, margin.toFixed(2)].join(",")
      }),
    ].join("\n")
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" })
    const link = document.createElement("a")
    const url = URL.createObjectURL(blob)
    link.setAttribute("href", url)
    link.setAttribute("download", `Laporan_Profit_${startDate}_${endDate}.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  return (
    <MainLayout>
      <div className="space-y-8 pb-20">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-slate-800">Laporan Keuntungan</h1>
            <p className="text-slate-500 mt-1">Analisis mendalam profitabilitas bisnis Anda.</p>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={() => setRange(30)}>30 Hari</Button>
            <Button variant="outline" size="sm" onClick={() => setRange(90)}>3 Bulan</Button>
            <Button onClick={exportData} disabled={filteredData.length === 0} className="bg-emerald-600 hover:bg-emerald-700">
              <FileSpreadsheet className="mr-2 h-4 w-4" /> Export CSV
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
            </div>
          </CardContent>
        </Card>

        {/* Chart */}
        {isLoading ? (
          <div className="h-64 flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
          </div>
        ) : filteredData.length > 0 ? (
          <ProfitChart data={filteredData} />
        ) : (
          <div className="text-center py-20 bg-slate-50 rounded-xl border border-dashed text-slate-400">
            Tidak ada data keuntungan pada periode ini.
          </div>
        )}

        {/* Detailed Table */}
        {filteredData.length > 0 && (
          <Card className="border-slate-200 shadow-sm">
            <CardHeader>
              <CardTitle>Rincian Profit Harian</CardTitle>
              <CardDescription>Detail keuntungan dan margin harian.</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto rounded-lg border border-slate-100">
                <table className="w-full text-sm">
                  <thead className="bg-slate-50 text-slate-500 font-medium">
                    <tr>
                      <th className="px-4 py-3 text-left">Tanggal</th>
                      <th className="px-4 py-3 text-right">Omzet</th>
                      <th className="px-4 py-3 text-right">Modal Estimasi</th>
                      <th className="px-4 py-3 text-right">Keuntungan Bersih</th>
                      <th className="px-4 py-3 text-center">Margin</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredData.map((item, idx) => {
                      const modal = item.revenue - item.profit;
                      const margin = item.revenue > 0 ? (item.profit / item.revenue) * 100 : 0;
                      return (
                        <tr key={idx} className="hover:bg-slate-50/50">
                          <td className="px-4 py-3 font-medium text-slate-700">
                            {new Date(item.date).toLocaleDateString("id-ID", { weekday: 'short', day: 'numeric', month: 'long', year: 'numeric' })}
                          </td>
                          <td className="px-4 py-3 text-right font-medium text-slate-600">Rp {item.revenue.toLocaleString("id-ID")}</td>
                          <td className="px-4 py-3 text-right text-slate-500">Rp {modal.toLocaleString("id-ID")}</td>
                          <td className="px-4 py-3 text-right font-bold text-emerald-600">Rp {item.profit.toLocaleString("id-ID")}</td>
                          <td className="px-4 py-3 text-center text-slate-600">{margin.toFixed(1)}%</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </MainLayout>
  );
}
