"use client"

import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, Legend, AreaChart, Area } from "recharts"
import { TrendingUp, Package, DollarSign, ShoppingCart, AlertTriangle, ArrowUpRight, ArrowDownRight, Activity } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, query, where, getDocs, Timestamp, orderBy, limit } from "firebase/firestore"
import { Badge } from "@/components/ui/badge"

// --- Interface Data ---
interface DashboardStats {
  todaySales: number;
  todayProfit: number;
  totalItems: number;
  lowStockItemsCount: number;
  totalStockValue: number; // Nilai asset stok
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
  stockTotal: number;
  stockDisplay: number;
  stockWarehouse: number;
  minStock: number;
  unit: string;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats>({
    todaySales: 0,
    todayProfit: 0,
    totalItems: 0,
    lowStockItemsCount: 0,
    totalStockValue: 0
  });
  const [salesChartData, setSalesChartData] = useState<SalesChartData[]>([]);
  const [categoryChartData, setCategoryChartData] = useState<CategoryChartData[]>([]);
  const [lowStockItems, setLowStockItems] = useState<LowStockItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      setIsLoading(true);

      // --- 1. Ambil data Transaksi (7 Hari Terakhir) ---
      const today = new Date();
      const todayStart = new Date(today.setHours(0, 0, 0, 0));
      const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);

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
        // Handle Firestore Timestamp properly
        let trxDate = new Date();
        if (trx.transactionDate instanceof Timestamp) {
          trxDate = trx.transactionDate.toDate();
        } else if (trx.transactionDate) {
          trxDate = new Date(trx.transactionDate);
        }

        // Statistik Hari Ini
        if (trxDate >= todayStart) {
          todaySales += trx.totalAmount || 0;
          todayProfit += trx.totalProfit || 0;
        }

        // Grafik Penjualan 7 Hari
        const dateString = trxDate.toISOString().split('T')[0];
        if (!dailySales[dateString]) {
          dailySales[dateString] = { sales: 0, profit: 0 };
        }
        dailySales[dateString].sales += trx.totalAmount || 0;
        dailySales[dateString].profit += trx.totalProfit || 0;

        // Grafik Kategori
        (trx.items || []).forEach((item: any) => {
          const category = item.category || 'Umum';
          const itemRevenue = (item.sellPrice || 0) * (item.quantity || 0);
          categorySales[category] = (categorySales[category] || 0) + itemRevenue;
        });
      });

      // Format Data Grafik
      const formattedSalesChart = Object.keys(dailySales).map(date => ({
        date,
        ...dailySales[date]
      })).sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

      const formattedCategoryChart = Object.keys(categorySales).map(category => ({
        category,
        sales: categorySales[category]
      })).sort((a, b) => b.sales - a.sales).slice(0, 5); // Top 5 Kategori

      // --- 2. Ambil Data Barang (Inventaris) ---
      const itemsSnapshot = await getDocs(collection(db, "items"));
      const totalItems = itemsSnapshot.size;
      const lowStockItemsList: LowStockItem[] = [];
      let totalStockValue = 0;

      itemsSnapshot.forEach(doc => {
        const item = doc.data();

        // Kalkulasi Stok Total (Gudang + Toko)
        const stockDisplay = item.qty_display || item.stock || 0;
        const stockWarehouse = item.qty_warehouse || 0;
        const totalStock = stockDisplay + stockWarehouse;

        // Nilai Aset (Harga Beli * Total Stok)
        totalStockValue += (item.buyPrice || 0) * totalStock;

        // Cek Stok Min (Hanya jika stok total di bawah batas)
        if (totalStock <= (item.minStock || 5)) {
          lowStockItemsList.push({
            name: item.name,
            stockTotal: totalStock,
            stockDisplay: stockDisplay,
            stockWarehouse: stockWarehouse,
            minStock: item.minStock || 5,
            unit: item.unit || 'pcs'
          });
        }
      });

      setStats({
        todaySales,
        todayProfit,
        totalItems,
        lowStockItemsCount: lowStockItemsList.length,
        totalStockValue
      });
      setSalesChartData(formattedSalesChart);
      setCategoryChartData(formattedCategoryChart);
      setLowStockItems(lowStockItemsList.sort((a, b) => a.stockTotal - b.stockTotal));
      setIsLoading(false);
    };

    fetchDashboardData();
  }, []);

  if (isLoading) {
    return (
      <MainLayout>
        <div className="flex flex-col items-center justify-center min-h-[calc(100vh-100px)] space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <p className="text-slate-500 animate-pulse">Menyiapkan data dashboard...</p>
        </div>
      </MainLayout>
    );
  }

  return (
    <MainLayout>
      <div className="space-y-8 pb-10">

        {/* Header Section */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tight">Dashboard Overview</h1>
            <p className="text-slate-500 mt-1">Laporan kinerja & status inventaris terkini.</p>
          </div>
          <div className="flex items-center gap-2 bg-white px-4 py-2 rounded-full border shadow-sm text-sm text-slate-600">
            <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
            Update Live: {new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}
          </div>
        </div>

        {/* --- STATS GRID --- */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">

          {/* Card 1: Penjualan */}
          <Card className="border-none shadow-md bg-gradient-to-br from-blue-600 to-blue-700 text-white relative overflow-hidden group">
            <div className="absolute right-0 top-0 opacity-10 transform translate-x-4 -translate-y-4 transition-transform group-hover:scale-110">
              <DollarSign className="w-32 h-32" />
            </div>
            <CardHeader className="flex flex-row items-center justify-between pb-2 relative z-10">
              <CardTitle className="text-sm font-medium text-blue-100">Penjualan Hari Ini</CardTitle>
              <DollarSign className="h-5 w-5 text-blue-100" />
            </CardHeader>
            <CardContent className="relative z-10">
              <div className="text-3xl font-bold">Rp {stats.todaySales.toLocaleString("id-ID")}</div>
              <div className="flex items-center text-xs mt-2 text-blue-100/80">
                <ArrowUpRight className="w-3 h-3 mr-1" />
                <span>Update real-time</span>
              </div>
            </CardContent>
          </Card>

          {/* Card 2: Keuntungan */}
          <Card className="border-none shadow-md bg-white hover:shadow-lg transition-shadow border-l-4 border-l-green-500">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-slate-500">Profit Hari Ini</CardTitle>
              <div className="p-2 bg-green-50 rounded-lg">
                <TrendingUp className="h-5 w-5 text-green-600" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-slate-900">Rp {stats.todayProfit.toLocaleString("id-ID")}</div>
              <p className="text-xs text-slate-500 mt-1">Margin aman terkendali</p>
            </CardContent>
          </Card>

          {/* Card 3: Nilai Stok */}
          <Card className="border-none shadow-md bg-white hover:shadow-lg transition-shadow border-l-4 border-l-orange-500">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-slate-500">Total Aset Barang</CardTitle>
              <div className="p-2 bg-orange-50 rounded-lg">
                <Package className="h-5 w-5 text-orange-600" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-slate-900">Rp {(stats.totalStockValue / 1000000).toFixed(1)} Jt</div>
              <div className="flex justify-between text-xs text-slate-500 mt-1">
                <span>{stats.totalItems} Items Total</span>
              </div>
            </CardContent>
          </Card>

          {/* Card 4: Peringatan Stok */}
          <Card className={`border-none shadow-md transition-shadow border-l-4 ${stats.lowStockItemsCount > 0 ? 'bg-red-50 border-l-red-500' : 'bg-white border-l-slate-200'}`}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-slate-600">Perlu Restok</CardTitle>
              <div className={`p-2 rounded-lg ${stats.lowStockItemsCount > 0 ? 'bg-red-100' : 'bg-slate-100'}`}>
                <AlertTriangle className={`h-5 w-5 ${stats.lowStockItemsCount > 0 ? 'text-red-600' : 'text-slate-500'}`} />
              </div>
            </CardHeader>
            <CardContent>
              <div className={`text-2xl font-bold ${stats.lowStockItemsCount > 0 ? 'text-red-600' : 'text-slate-900'}`}>
                {stats.lowStockItemsCount} Item
              </div>
              <p className="text-xs text-slate-500 mt-1">Stok di bawah batas minimum</p>
            </CardContent>
          </Card>
        </div>

        {/* --- CHARTS SECTION --- */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main Chart */}
          <Card className="lg:col-span-2 shadow-sm border-slate-200">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Activity className="w-5 h-5 text-blue-600" />
                Tren Penjualan (7 Hari)
              </CardTitle>
              <CardDescription>Grafik pendapatan dan keuntungan bersih per hari.</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="h-[350px] w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={salesChartData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
                    <defs>
                      <linearGradient id="colorSales" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#2563eb" stopOpacity={0.3} />
                        <stop offset="95%" stopColor="#2563eb" stopOpacity={0} />
                      </linearGradient>
                      <linearGradient id="colorProfit" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#16a34a" stopOpacity={0.3} />
                        <stop offset="95%" stopColor="#16a34a" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <XAxis dataKey="date" tickFormatter={(date) => new Date(date).toLocaleDateString('id-ID', { weekday: 'short' })} stroke="#94a3b8" tick={{ fontSize: 12 }} />
                    <YAxis tickFormatter={(value) => `${(value / 1000).toFixed(0)}k`} stroke="#94a3b8" tick={{ fontSize: 12 }} />
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                    <Tooltip
                      contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                      formatter={(value: number) => [`Rp ${value.toLocaleString("id-ID")}`, '']}
                    />
                    <Legend />
                    <Area type="monotone" dataKey="sales" stroke="#2563eb" fillOpacity={1} fill="url(#colorSales)" name="Omzet" strokeWidth={3} />
                    <Area type="monotone" dataKey="profit" stroke="#16a34a" fillOpacity={1} fill="url(#colorProfit)" name="Profit" strokeWidth={3} />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </CardContent>
          </Card>

          {/* Category Chart */}
          <Card className="shadow-sm border-slate-200">
            <CardHeader>
              <CardTitle>Top Kategori</CardTitle>
              <CardDescription>Kontribusi pendapatan.</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="h-[350px] w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={categoryChartData} layout="vertical" margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                    <XAxis type="number" hide />
                    <YAxis dataKey="category" type="category" width={100} tick={{ fontSize: 12 }} />
                    <Tooltip
                      cursor={{ fill: 'transparent' }}
                      contentStyle={{ borderRadius: '8px' }}
                      formatter={(value: number) => [`Rp ${value.toLocaleString("id-ID")}`, '']}
                    />
                    <Bar dataKey="sales" fill="#3b82f6" radius={[0, 4, 4, 0]} barSize={30} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* --- STOCK ALERT TABLE --- */}
        <Card className="shadow-sm border-slate-200 overflow-hidden">
          <CardHeader className="bg-red-50/50 border-b border-red-100">
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-red-700 flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5" />
                  Peringatan Stok Menipis
                </CardTitle>
                <CardDescription>Segera lakukan restok untuk barang-barang berikut.</CardDescription>
              </div>
              {lowStockItems.length > 5 && (
                <Badge variant="outline" className="bg-white text-red-600 border-red-200">
                  Lihat Semua ({lowStockItems.length})
                </Badge>
              )}
            </div>
          </CardHeader>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full text-sm text-left">
                <thead className="bg-slate-50 text-slate-500 uppercase font-medium text-xs">
                  <tr>
                    <th className="px-6 py-4">Nama Barang</th>
                    <th className="px-6 py-4 text-center">Total Stok</th>
                    <th className="px-6 py-4 text-center">Gudang Toko</th>
                    <th className="px-6 py-4 text-center">Gudang Utama</th>
                    <th className="px-6 py-4 text-center">Min. Stok</th>
                    <th className="px-6 py-4 text-center">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {lowStockItems.length > 0 ? (
                    lowStockItems.slice(0, 5).map((item, index) => (
                      <tr key={index} className="hover:bg-slate-50 transition-colors">
                        <td className="px-6 py-4 font-medium text-slate-800">{item.name}</td>
                        <td className="px-6 py-4 text-center font-bold text-red-600">{item.stockTotal}</td>
                        <td className="px-6 py-4 text-center text-slate-500">{item.stockDisplay}</td>
                        <td className="px-6 py-4 text-center text-slate-500">{item.stockWarehouse}</td>
                        <td className="px-6 py-4 text-center text-slate-400">{item.minStock}</td>
                        <td className="px-6 py-4 text-center">
                          <Badge variant="destructive" className="bg-red-100 text-red-700 hover:bg-red-200 border-none shadow-none">
                            Kritis
                          </Badge>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center text-slate-400">
                        <div className="flex flex-col items-center justify-center">
                          <Package className="w-12 h-12 mb-3 text-slate-200" />
                          <p>Semua stok aman terkendali.</p>
                        </div>
                      </td>
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
