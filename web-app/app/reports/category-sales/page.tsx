"use client"

import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from "recharts"
import { collection, getDocs, query, where, Timestamp } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { BarChart3 } from "lucide-react"

interface CategorySalesData {
  category: string;
  totalSales: number;
}

export default function CategorySalesPage() {
  const [salesData, setSalesData] = useState<CategorySalesData[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchCategorySales = async () => {
      setIsLoading(true);
      try {
        // Last 90 days only: reading the whole history on every visit gets slow and costly.
        const since = new Date();
        since.setHours(0, 0, 0, 0);
        since.setDate(since.getDate() - 89);
        const transactionsSnapshot = await getDocs(
          query(collection(db, "transactions"), where("transactionDate", ">=", Timestamp.fromDate(since)))
        );
      
        const categorySales: { [key: string]: number } = {};

        transactionsSnapshot.forEach(doc => {
          const transaction = doc.data();
          if (transaction.items && Array.isArray(transaction.items)) {
            transaction.items.forEach((item: any) => {
              const category = item.category || "Tanpa Kategori";
              const saleAmount = (Number(item.quantity) || 0) * (Number(item.sellPrice) || 0);
            
              if (categorySales[category]) {
                categorySales[category] += saleAmount;
              } else {
                categorySales[category] = saleAmount;
              }
            });
          }
        });

        const formattedData = Object.keys(categorySales).map(category => ({
          category: category,
          totalSales: categorySales[category]
        })).sort((a, b) => b.totalSales - a.totalSales); // Urutkan dari penjualan tertinggi

        setSalesData(formattedData);
      } catch (error) {
        console.error("Gagal memuat penjualan per kategori:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchCategorySales();
  }, []);

  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Laporan Penjualan per Kategori</h1>
          <p className="text-gray-600">Analisis kontribusi penjualan dari setiap kategori barang.</p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 />
              Grafik Penjualan per Kategori
            </CardTitle>
            <CardDescription>Total penjualan tiap kategori dalam 90 hari terakhir (dikurangi retur).</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="flex justify-center items-center h-[400px]">
                <p>Memuat data laporan...</p>
              </div>
            ) : salesData.length === 0 ? (
              <div className="flex justify-center items-center h-[400px]">
                <p>Belum ada data transaksi untuk ditampilkan.</p>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={salesData} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis type="number" tickFormatter={(value) => `Rp ${(Number(value) / 1000000).toFixed(1)}Jt`} />
                  <YAxis type="category" dataKey="category" width={150} />
                  <Tooltip formatter={(value: number) => [`Rp ${value.toLocaleString("id-ID")}`, "Total Penjualan"]} />
                  <Legend />
                  <Bar dataKey="totalSales" fill="#2563eb" name="Total Penjualan" />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  );
}