"use client"

import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, Legend } from "recharts"
import { TrendingUp, Package, DollarSign, ShoppingCart } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, query, where, getDocs, Timestamp } from "firebase/firestore"

// --- Interface untuk data yang akan diolah ---
interface DashboardStats {
  todaySales: number;
  todayProfit: number;
  totalItems: number;
  lowStockItemsCount: number;
}

interface SalesChartData {
  date: string;
  sales: number;
  profit: number;
}

interface CategoryChartData {
  category: string;
  sales: number;
}

interface LowStockItem {
    name: string;
    stock: number;
    minStock: number;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats>({ todaySales: 0, todayProfit: 0, totalItems: 0, lowStockItemsCount: 0 });
  const [salesChartData, setSalesChartData] = useState<SalesChartData[]>([]);
  const [categoryChartData, setCategoryChartData] = useState<CategoryChartData[]>([]);
  const [lowStockItems, setLowStockItems] = useState<LowStockItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      setIsLoading(true);

      // --- 1. Ambil data Transaksi ---
      const today = new Date();
      const todayStart = new Date(today.setHours(0, 0, 0, 0));
      const sevenDaysAgo = new Date(today.setDate(today.getDate() - 7));

      const transactionsQuery = query(
        collection(db, "transactions"),
        where("transactionDate", ">=", Timestamp.fromDate(sevenDaysAgo))
      );
      const transactionsSnapshot = await getDocs(transactionsQuery);

      let todaySales = 0;
      let todayProfit = 0;
      const dailySales: { [key: string]: { sales: number, profit: number } } = {};
      const categorySales: { [key: string]: number } = {};

      transactionsSnapshot.forEach(doc => {
        const trx = doc.data();
        const trxDate = (trx.transactionDate as Timestamp).toDate();
        
        // Kalkulasi untuk kartu statistik hari ini
        if (trxDate >= todayStart) {
          todaySales += trx.totalAmount || 0;
          todayProfit += trx.totalProfit || 0;
        }

        // Agregasi data untuk grafik penjualan 7 hari
        const dateString = trxDate.toISOString().split('T')[0];
        if (!dailySales[dateString]) {
          dailySales[dateString] = { sales: 0, profit: 0 };
        }
        dailySales[dateString].sales += trx.totalAmount || 0;
        dailySales[dateString].profit += trx.totalProfit || 0;
        
        // Agregasi data untuk grafik kategori
        (trx.items || []).forEach((item: any) => {
            const category = item.category || 'Lain-lain';
            const itemRevenue = (item.sellPrice || 0) * (item.quantity || 0);
            categorySales[category] = (categorySales[category] || 0) + itemRevenue;
        });
      });

      // Format data untuk grafik
      const formattedSalesChart = Object.keys(dailySales).map(date => ({ date, ...dailySales[date] })).sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
      const formattedCategoryChart = Object.keys(categorySales).map(category => ({ category, sales: categorySales[category] })).sort((a, b) => b.sales - a.sales);

      // --- 2. Ambil data Barang ---
      const itemsSnapshot = await getDocs(collection(db, "items"));
      const totalItems = itemsSnapshot.size;
      const lowStockItemsList: LowStockItem[] = [];
      itemsSnapshot.forEach(doc => {
          const item = doc.data();
          if (item.stock <= item.minStock) {
              lowStockItemsList.push({ name: item.name, stock: item.stock, minStock: item.minStock });
          }
      });

      // --- 3. Set semua state ---
      setStats({ todaySales, todayProfit, totalItems, lowStockItemsCount: lowStockItemsList.length });
      setSalesChartData(formattedSalesChart);
      setCategoryChartData(formattedCategoryChart);
      setLowStockItems(lowStockItemsList.sort((a,b) => a.stock - b.stock)); // Urutkan dari stok terendah
      setIsLoading(false);
    };

    fetchDashboardData();
  }, []);

  if (isLoading) {
    return (
        <MainLayout>
            <div className="flex items-center justify-center min-h-[calc(100vh-80px)]">
                <p>Memuat data dashboard...</p>
            </div>
        </MainLayout>
    );
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600">Monitoring real-time ANNUR MOTOR</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Penjualan Hari Ini</CardTitle>
              <DollarSign className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">Rp {stats.todaySales.toLocaleString("id-ID")}</div>
              <p className="text-xs text-muted-foreground">Total omzet hari ini</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Keuntungan Hari Ini</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">Rp {stats.todayProfit.toLocaleString("id-ID")}</div>
              <p className="text-xs text-muted-foreground">Estimasi profit hari ini</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Jenis Barang</CardTitle>
              <Package className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalItems}</div>
              <p className="text-xs text-muted-foreground">Item unik di database</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Stok Rendah</CardTitle>
              <ShoppingCart className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-red-600">{stats.lowStockItemsCount}</div>
              <p className="text-xs text-muted-foreground">Item perlu restok</p>
            </CardContent>
          </Card>
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle>Penjualan & Keuntungan (7 Hari Terakhir)</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={salesChartData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" tickFormatter={(date) => new Date(date).toLocaleDateString('id-ID', {weekday: 'short'})}/>
                  <YAxis tickFormatter={(value) => `${(value / 1000000).toFixed(1)}Jt`} />
                  <Tooltip formatter={(value: number) => `Rp ${value.toLocaleString("id-ID")}`} />
                  <Legend />
                  <Line type="monotone" dataKey="sales" stroke="#2563eb" name="Penjualan" />
                  <Line type="monotone" dataKey="profit" stroke="#16a34a" name="Keuntungan" />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle>Penjualan per Kategori</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={categoryChartData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="category" angle={-45} textAnchor="end" height={80} fontSize={12} />
                  <YAxis tickFormatter={(value) => `${(value / 1000000).toFixed(1)}Jt`} />
                  <Tooltip formatter={(value: number) => `Rp ${value.toLocaleString("id-ID")}`} />
                  <Bar dataKey="sales" fill="#2563eb" name="Total Penjualan" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>

        {/* Stock Alert Table */}
        <Card>
          <CardHeader>
            <CardTitle>Status Stok Barang Kritis</CardTitle>
            <CardDescription>Daftar barang yang stoknya di bawah batas minimum.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-2">Nama Barang</th>
                    <th className="text-center py-2">Stok Saat Ini</th>
                    <th className="text-center py-2">Stok Minimum</th>
                    <th className="text-center py-2">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {lowStockItems.length > 0 ? lowStockItems.map((item, index) => (
                    <tr key={index} className="border-b">
                      <td className="py-2">{item.name}</td>
                      <td className="text-center py-2 font-bold text-red-500">{item.stock}</td>
                      <td className="text-center py-2">{item.minStock}</td>
                      <td className="text-center py-2">
                        <span className="px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                          Perlu Restok
                        </span>
                      </td>
                    </tr>
                  )) : (
                    <tr>
                        <td colSpan={4} className="text-center py-4 text-muted-foreground">Semua stok aman.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  )
}
