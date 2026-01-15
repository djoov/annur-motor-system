"use client"

import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from "recharts"
import { TrendingUp, DollarSign, ShoppingCart, Percent } from "lucide-react"

interface DailySales {
  date: string
  transactions: number
  revenue: number
  profit: number
  items_sold: number
}

interface DailySalesChartProps {
  data: DailySales[];
}

export function DailySalesChart({ data }: DailySalesChartProps) {
  const totals = data.reduce(
    (acc, item) => ({
      transactions: acc.transactions + item.transactions,
      revenue: acc.revenue + item.revenue,
      profit: acc.profit + item.profit,
      items_sold: acc.items_sold + item.items_sold,
    }),
    { transactions: 0, revenue: 0, profit: 0, items_sold: 0 },
  );

  const averages = {
    transactions: data.length > 0 ? Math.round(totals.transactions / data.length) : 0,
    revenue: data.length > 0 ? Math.round(totals.revenue / data.length) : 0,
    profit: data.length > 0 ? Math.round(totals.profit / data.length) : 0,
    items_sold: data.length > 0 ? Math.round(totals.items_sold / data.length) : 0,
  };

  const marginPercentage = totals.revenue > 0 ? ((totals.profit / totals.revenue) * 100).toFixed(1) : "0";

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="border-indigo-100 shadow-sm bg-gradient-to-br from-white to-indigo-50/50">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Total Omzet</CardTitle>
            <DollarSign className="h-4 w-4 text-indigo-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-800">Rp {totals.revenue.toLocaleString("id-ID")}</div>
            <p className="text-xs text-slate-500 mt-1">
              Rata-rata: <span className="font-medium text-indigo-600">Rp {averages.revenue.toLocaleString("id-ID")}</span>/hari
            </p>
          </CardContent>
        </Card>

        <Card className="border-emerald-100 shadow-sm bg-gradient-to-br from-white to-emerald-50/50">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Keuntungan Bersih</CardTitle>
            <TrendingUp className="h-4 w-4 text-emerald-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-800">Rp {totals.profit.toLocaleString("id-ID")}</div>
            <div className="flex items-center text-xs text-slate-500 mt-1">
              Margin: <span className="font-medium text-emerald-600 ml-1">{marginPercentage}%</span>
            </div>
          </CardContent>
        </Card>

        <Card className="border-blue-100 shadow-sm bg-gradient-to-br from-white to-blue-50/50">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Total Transaksi</CardTitle>
            <ShoppingCart className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-800">{totals.transactions}</div>
            <p className="text-xs text-slate-500 mt-1">
              Rata-rata: <span className="font-medium text-blue-600">{averages.transactions}</span> struk/hari
            </p>
          </CardContent>
        </Card>

        <Card className="border-orange-100 shadow-sm bg-gradient-to-br from-white to-orange-50/50">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Item Terjual</CardTitle>
            <Percent className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-800">{totals.items_sold}</div>
            <p className="text-xs text-slate-500 mt-1">
              Unit barang keluar
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Chart */}
      <Card className="border-slate-200 shadow-sm">
        <CardHeader>
          <CardTitle>Grafik Tren Penjualan</CardTitle>
          <CardDescription>Visualisasi pergerakan omzet dan profit selama periode terpilih.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[400px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="colorProfit" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" />
                <XAxis
                  dataKey="date"
                  tickFormatter={(value) => new Date(value).toLocaleDateString("id-ID", { day: "2-digit", month: "short" })}
                  stroke="#64748B"
                  fontSize={12}
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis
                  tickFormatter={(value) => `${(value / 1000).toFixed(0)}k`}
                  stroke="#64748B"
                  fontSize={12}
                  tickLine={false}
                  axisLine={false}
                />
                <Tooltip
                  contentStyle={{ backgroundColor: '#fff', borderRadius: '8px', border: '1px solid #e2e8f0', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                  formatter={(value: number, name: string) => [
                    `Rp ${value.toLocaleString("id-ID")}`,
                    name === "revenue" ? "Omzet" : "Keuntungan"
                  ]}
                  labelFormatter={(label) => new Date(label).toLocaleDateString("id-ID", { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
                />
                <Legend iconType="circle" />
                <Area
                  type="monotone"
                  dataKey="revenue"
                  stroke="#6366f1"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#colorRevenue)"
                  name="Omzet"
                  activeDot={{ r: 6, strokeWidth: 0 }}
                />
                <Area
                  type="monotone"
                  dataKey="profit"
                  stroke="#10b981"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#colorProfit)"
                  name="Keuntungan"
                  activeDot={{ r: 6, strokeWidth: 0 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
