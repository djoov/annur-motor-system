"use client"

import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from "recharts"
import { TrendingUp, DollarSign, Percent, ArrowUpRight } from "lucide-react"

interface DailyProfitData {
    date: string;
    profit: number;
    revenue: number;
}

interface ProfitChartProps {
    data: DailyProfitData[];
}

export function ProfitChart({ data }: ProfitChartProps) {
    const totalProfit = data.reduce((sum, item) => sum + item.profit, 0);
    const totalRevenue = data.reduce((sum, item) => sum + item.revenue, 0);
    const averageProfit = data.length > 0 ? totalProfit / data.length : 0;
    const profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

    return (
        <div className="space-y-6">
            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <Card className="border-emerald-100 shadow-sm bg-gradient-to-br from-white to-emerald-50/50">
                    <CardHeader className="flex flex-row items-center justify-between pb-2">
                        <CardTitle className="text-sm font-medium text-slate-500">Total Keuntungan</CardTitle>
                        <DollarSign className="h-4 w-4 text-emerald-500" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold text-slate-800">Rp {totalProfit.toLocaleString("id-ID")}</div>
                        <p className="text-xs text-slate-500 mt-1">
                            Net profit periode ini
                        </p>
                    </CardContent>
                </Card>

                <Card className="border-blue-100 shadow-sm bg-gradient-to-br from-white to-blue-50/50">
                    <CardHeader className="flex flex-row items-center justify-between pb-2">
                        <CardTitle className="text-sm font-medium text-slate-500">Rata-rata Harian</CardTitle>
                        <TrendingUp className="h-4 w-4 text-blue-500" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold text-slate-800">Rp {averageProfit.toLocaleString("id-ID", { maximumFractionDigits: 0 })}</div>
                        <p className="text-xs text-slate-500 mt-1">
                            Performa rata-rata per hari
                        </p>
                    </CardContent>
                </Card>

                <Card className="border-violet-100 shadow-sm bg-gradient-to-br from-white to-violet-50/50">
                    <CardHeader className="flex flex-row items-center justify-between pb-2">
                        <CardTitle className="text-sm font-medium text-slate-500">Margin Profit</CardTitle>
                        <Percent className="h-4 w-4 text-violet-500" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold text-slate-800">{profitMargin.toFixed(1)}%</div>
                        <div className="flex items-center text-xs text-slate-500 mt-1">
                            <ArrowUpRight className="h-3 w-3 mr-1 text-violet-600" />
                            Sehat jika {'>'} 20%
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Chart */}
            <Card className="border-slate-200 shadow-sm">
                <CardHeader>
                    <CardTitle>Tren Pertumbuhan Keuntungan</CardTitle>
                    <CardDescription>Grafik pergerakan keuntungan bersih (Net Profit) harian.</CardDescription>
                </CardHeader>
                <CardContent>
                    <div className="h-[400px] w-full">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                                <defs>
                                    <linearGradient id="colorProfitOnly" x1="0" y1="0" x2="0" y2="1">
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
                                    formatter={(value: number) => [`Rp ${value.toLocaleString("id-ID")}`, "Keuntungan"]}
                                    labelFormatter={(label) => new Date(label).toLocaleDateString("id-ID", { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
                                />
                                <Legend />
                                <Area
                                    type="monotone"
                                    dataKey="profit"
                                    stroke="#10b981"
                                    strokeWidth={3}
                                    fillOpacity={1}
                                    fill="url(#colorProfitOnly)"
                                    name="Keuntungan Bersih"
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
