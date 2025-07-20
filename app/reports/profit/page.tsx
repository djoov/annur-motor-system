"use client"

import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from "recharts"
import { collection, getDocs, query, orderBy } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { DollarSign, TrendingUp, Percent } from "lucide-react"
import { Timestamp } from "firebase/firestore"

interface DailyProfitData {
  date: string;
  profit: number;
  revenue: number;
}

export default function ProfitReportPage() {
  const [profitData, setProfitData] = useState<DailyProfitData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [startDate, setStartDate] = useState(() => {
    const date = new Date();
    date.setDate(date.getDate() - 30);
    return date.toISOString().split('T')[0];
  });
  const [endDate, setEndDate] = useState(() => new Date().toISOString().split('T')[0]);

  useEffect(() => {
    const fetchProfitData = async () => {
      setIsLoading(true);
      const q = query(collection(db, "transactions"), orderBy("transactionDate", "asc"));
      const querySnapshot = await getDocs(q);
      
      const dailyData: { [key: string]: { profit: number, revenue: number } } = {};

      querySnapshot.forEach(doc => {
        const transaction = doc.data();
        const date = (transaction.transactionDate as Timestamp).toDate().toISOString().split('T')[0];
        
        if (!dailyData[date]) {
          dailyData[date] = { profit: 0, revenue: 0 };
        }
        
        dailyData[date].profit += transaction.totalProfit || 0;
        dailyData[date].revenue += transaction.totalAmount || 0;
      });

      const formattedData = Object.keys(dailyData).map(date => ({
        date: date,
        profit: dailyData[date].profit,
        revenue: dailyData[date].revenue,
      }));

      setProfitData(formattedData);
      setIsLoading(false);
    };

    fetchProfitData();
  }, []);

  const filteredData = profitData.filter(item => {
    return item.date >= startDate && item.date <= endDate;
  });

  const totalProfit = filteredData.reduce((sum, item) => sum + item.profit, 0);
  const totalRevenue = filteredData.reduce((sum, item) => sum + item.revenue, 0);
  const averageProfit = filteredData.length > 0 ? totalProfit / filteredData.length : 0;
  const profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Laporan Keuntungan</h1>
          <p className="text-gray-600">Analisis profitabilitas dan margin keuntungan dari penjualan.</p>
        </div>

        {/* Date Filter */}
        <Card>
          <CardHeader>
            <CardTitle>Filter Periode Laporan</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <Label htmlFor="startDate">Tanggal Mulai</Label>
                <Input id="startDate" type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
              </div>
              <div>
                <Label htmlFor="endDate">Tanggal Akhir</Label>
                <Input id="endDate" type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Keuntungan</CardTitle>
              <DollarSign className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">Rp {totalProfit.toLocaleString("id-ID")}</div>
              <p className="text-xs text-muted-foreground">Dalam periode yang dipilih</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Keuntungan Rata-rata / Hari</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">Rp {averageProfit.toLocaleString("id-ID", { maximumFractionDigits: 0 })}</div>
              <p className="text-xs text-muted-foreground">Rata-rata keuntungan harian</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Margin Keuntungan</CardTitle>
              <Percent className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{profitMargin.toFixed(2)}%</div>
              <p className="text-xs text-muted-foreground">Rasio keuntungan terhadap omzet</p>
            </CardContent>
          </Card>
        </div>

        {/* Chart */}
        <Card>
          <CardHeader>
            <CardTitle>Grafik Tren Keuntungan Harian</CardTitle>
            <CardDescription>Visualisasi keuntungan yang didapat setiap hari dalam periode yang dipilih.</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="flex justify-center items-center h-[400px]">Memuat data...</div>
            ) : filteredData.length === 0 ? (
                <div className="flex justify-center items-center h-[400px]">Tidak ada data pada periode ini.</div>
            ) : (
              <ResponsiveContainer width="100%" height={400}>
                <LineChart data={filteredData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" tickFormatter={(date) => new Date(date).toLocaleDateString('id-ID', {day: '2-digit', month:'short'})} />
                  <YAxis tickFormatter={(value) => `Rp ${(value / 1000000).toFixed(1)}Jt`} />
                  <Tooltip formatter={(value: number) => [`Rp ${value.toLocaleString("id-ID")}`, "Keuntungan"]} />
                  <Legend />
                  <Line type="monotone" dataKey="profit" stroke="#16a34a" strokeWidth={2} name="Keuntungan Harian" />
                </LineChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  );
}
