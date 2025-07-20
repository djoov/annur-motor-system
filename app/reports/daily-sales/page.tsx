"use client"

import { useState } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Button } from "@/components/ui/button"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts"
import { Calendar, TrendingUp, DollarSign, ShoppingCart, Download } from "lucide-react"

interface DailySales {
  date: string
  transactions: number
  revenue: number
  profit: number
  items_sold: number
}

export default function DailySalesPage() {
  const [startDate, setStartDate] = useState("2024-01-01")
  const [endDate, setEndDate] = useState("2024-01-07")

  const [salesData] = useState<DailySales[]>([
    { date: "2024-01-01", transactions: 25, revenue: 4500000, profit: 1350000, items_sold: 45 },
    { date: "2024-01-02", transactions: 18, revenue: 3200000, profit: 960000, items_sold: 32 },
    { date: "2024-01-03", transactions: 32, revenue: 5100000, profit: 1530000, items_sold: 58 },
    { date: "2024-01-04", transactions: 28, revenue: 4800000, profit: 1440000, items_sold: 51 },
    { date: "2024-01-05", transactions: 35, revenue: 6200000, profit: 1860000, items_sold: 67 },
    { date: "2024-01-06", transactions: 30, revenue: 5500000, profit: 1650000, items_sold: 62 },
    { date: "2024-01-07", transactions: 42, revenue: 7100000, profit: 2130000, items_sold: 78 },
  ])

  const filteredData = salesData.filter((item) => {
    const itemDate = new Date(item.date)
    const start = new Date(startDate)
    const end = new Date(endDate)
    return itemDate >= start && itemDate <= end
  })

  const totals = filteredData.reduce(
    (acc, item) => ({
      transactions: acc.transactions + item.transactions,
      revenue: acc.revenue + item.revenue,
      profit: acc.profit + item.profit,
      items_sold: acc.items_sold + item.items_sold,
    }),
    { transactions: 0, revenue: 0, profit: 0, items_sold: 0 },
  )

  const averages = {
    transactions: Math.round(totals.transactions / filteredData.length),
    revenue: Math.round(totals.revenue / filteredData.length),
    profit: Math.round(totals.profit / filteredData.length),
    items_sold: Math.round(totals.items_sold / filteredData.length),
  }

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
    link.style.visibility = "hidden"
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
            <p className="text-gray-600">Analisis penjualan dan omzet harian</p>
          </div>
          <Button onClick={exportData} variant="outline">
            <Download className="mr-2 h-4 w-4" />
            Export CSV
          </Button>
        </div>

        {/* Date Filter */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Calendar className="mr-2 h-5 w-5" />
              Filter Periode
            </CardTitle>
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
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Transaksi</CardTitle>
              <ShoppingCart className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{totals.transactions}</div>
              <p className="text-xs text-muted-foreground">Rata-rata: {averages.transactions}/hari</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Omzet</CardTitle>
              <DollarSign className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">Rp {totals.revenue.toLocaleString("id-ID")}</div>
              <p className="text-xs text-muted-foreground">
                Rata-rata: Rp {averages.revenue.toLocaleString("id-ID")}/hari
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Keuntungan</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">Rp {totals.profit.toLocaleString("id-ID")}</div>
              <p className="text-xs text-muted-foreground">
                Rata-rata: Rp {averages.profit.toLocaleString("id-ID")}/hari
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Item Terjual</CardTitle>
              <ShoppingCart className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{totals.items_sold}</div>
              <p className="text-xs text-muted-foreground">Rata-rata: {averages.items_sold}/hari</p>
            </CardContent>
          </Card>
        </div>

        {/* Chart */}
        <Card>
          <CardHeader>
            <CardTitle>Trend Penjualan Harian</CardTitle>
            <CardDescription>Grafik omzet dan keuntungan per hari</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={400}>
              <LineChart data={filteredData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="date"
                  tickFormatter={(value) =>
                    new Date(value).toLocaleDateString("id-ID", { day: "2-digit", month: "2-digit" })
                  }
                />
                <YAxis tickFormatter={(value) => `${(value / 1000000).toFixed(1)}M`} />
                <Tooltip
                  formatter={(value: number, name: string) => [
                    `Rp ${value.toLocaleString("id-ID")}`,
                    name === "revenue" ? "Omzet" : "Keuntungan",
                  ]}
                  labelFormatter={(label) => new Date(label).toLocaleDateString("id-ID")}
                />
                <Line type="monotone" dataKey="revenue" stroke="#2563eb" strokeWidth={2} name="revenue" />
                <Line type="monotone" dataKey="profit" stroke="#ea580c" strokeWidth={2} name="profit" />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Detailed Table */}
        <Card>
          <CardHeader>
            <CardTitle>Detail Penjualan Harian</CardTitle>
            <CardDescription>Rincian lengkap penjualan per hari</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-2">Tanggal</th>
                    <th className="text-center py-3 px-2">Transaksi</th>
                    <th className="text-right py-3 px-2">Omzet</th>
                    <th className="text-right py-3 px-2">Keuntungan</th>
                    <th className="text-center py-3 px-2">Item Terjual</th>
                    <th className="text-center py-3 px-2">Margin (%)</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredData.map((item) => {
                    const margin = ((item.profit / item.revenue) * 100).toFixed(1)
                    return (
                      <tr key={item.date} className="border-b hover:bg-gray-50">
                        <td className="py-3 px-2">
                          {new Date(item.date).toLocaleDateString("id-ID", {
                            weekday: "long",
                            year: "numeric",
                            month: "long",
                            day: "numeric",
                          })}
                        </td>
                        <td className="py-3 px-2 text-center">{item.transactions}</td>
                        <td className="py-3 px-2 text-right">Rp {item.revenue.toLocaleString("id-ID")}</td>
                        <td className="py-3 px-2 text-right">Rp {item.profit.toLocaleString("id-ID")}</td>
                        <td className="py-3 px-2 text-center">{item.items_sold}</td>
                        <td className="py-3 px-2 text-center">{margin}%</td>
                      </tr>
                    )
                  })}
                </tbody>
                <tfoot>
                  <tr className="border-t-2 font-semibold bg-gray-50">
                    <td className="py-3 px-2">TOTAL</td>
                    <td className="py-3 px-2 text-center">{totals.transactions}</td>
                    <td className="py-3 px-2 text-right">Rp {totals.revenue.toLocaleString("id-ID")}</td>
                    <td className="py-3 px-2 text-right">Rp {totals.profit.toLocaleString("id-ID")}</td>
                    <td className="py-3 px-2 text-center">{totals.items_sold}</td>
                    <td className="py-3 px-2 text-center">{((totals.profit / totals.revenue) * 100).toFixed(1)}%</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  )
}
