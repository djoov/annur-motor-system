"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from "recharts"
import { TrendingUp, DollarSign, ShoppingCart } from "lucide-react"

// Definisikan tipe data yang akan diterima oleh komponen ini
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

// Komponen ini hanya bertanggung jawab untuk menampilkan data yang diberikan
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

    return (
        <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <Card><CardHeader className="flex flex-row items-center justify-between pb-2"><CardTitle className="text-sm font-medium">Total Transaksi</CardTitle><ShoppingCart className="h-4 w-4 text-muted-foreground" /></CardHeader><CardContent><div className="text-2xl font-bold">{totals.transactions}</div><p className="text-xs text-muted-foreground">Rata-rata: {averages.transactions}/hari</p></CardContent></Card>
                <Card><CardHeader className="flex flex-row items-center justify-between pb-2"><CardTitle className="text-sm font-medium">Total Omzet</CardTitle><DollarSign className="h-4 w-4 text-muted-foreground" /></CardHeader><CardContent><div className="text-2xl font-bold">Rp {totals.revenue.toLocaleString("id-ID")}</div><p className="text-xs text-muted-foreground">Rata-rata: Rp {averages.revenue.toLocaleString("id-ID")}/hari</p></CardContent></Card>
                <Card><CardHeader className="flex flex-row items-center justify-between pb-2"><CardTitle className="text-sm font-medium">Total Keuntungan</CardTitle><TrendingUp className="h-4 w-4 text-muted-foreground" /></CardHeader><CardContent><div className="text-2xl font-bold">Rp {totals.profit.toLocaleString("id-ID")}</div><p className="text-xs text-muted-foreground">Rata-rata: Rp {averages.profit.toLocaleString("id-ID")}/hari</p></CardContent></Card>
                <Card><CardHeader className="flex flex-row items-center justify-between pb-2"><CardTitle className="text-sm font-medium">Item Terjual</CardTitle><ShoppingCart className="h-4 w-4 text-muted-foreground" /></CardHeader><CardContent><div className="text-2xl font-bold">{totals.items_sold}</div><p className="text-xs text-muted-foreground">Rata-rata: {averages.items_sold}/hari</p></CardContent></Card>
            </div>

            <Card>
              <CardHeader><CardTitle>Trend Penjualan Harian</CardTitle><CardDescription>Grafik omzet dan keuntungan per hari</CardDescription></CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={400}>
                  <LineChart data={data}>
                    <CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="date" tickFormatter={(value) => new Date(value).toLocaleDateString("id-ID", { day: "2-digit", month: "short" })} /><YAxis tickFormatter={(value) => `${(value / 1000000).toFixed(1)}Jt`} />
                    <Tooltip formatter={(value: number, name: string) => [`Rp ${value.toLocaleString("id-ID")}`, name === "revenue" ? "Omzet" : "Keuntungan"]} labelFormatter={(label) => new Date(label).toLocaleDateString("id-ID")} />
                    <Legend />
                    <Line type="monotone" dataKey="revenue" stroke="#2563eb" strokeWidth={2} name="Omzet" />
                    <Line type="monotone" dataKey="profit" stroke="#16a34a" strokeWidth={2} name="Keuntungan" />
                  </LineChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
        </>
    )
}
