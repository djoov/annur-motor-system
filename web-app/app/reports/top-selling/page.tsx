"use client"

import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { collection, getDocs, query, where, Timestamp } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { TrendingUp } from "lucide-react"

interface TopSellingItem {
  itemId: string;
  itemName: string;
  quantitySold: number;
  totalRevenue: number;
}

export default function TopSellingPage() {
  const [topItems, setTopItems] = useState<TopSellingItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchTopSelling = async () => {
      setIsLoading(true);
      try {
        // Last 90 days only: reading the whole history on every visit gets slow and costly.
        const since = new Date();
        since.setHours(0, 0, 0, 0);
        since.setDate(since.getDate() - 89);
        const transactionsSnapshot = await getDocs(
          query(collection(db, "transactions"), where("transactionDate", ">=", Timestamp.fromDate(since)))
        );
      
        const itemSales: { [key: string]: { name: string, quantity: number, revenue: number } } = {};

        transactionsSnapshot.forEach(doc => {
          const transaction = doc.data();
          if (transaction.items && Array.isArray(transaction.items)) {
            transaction.items.forEach((item: any) => {
              const itemId = item.itemId || item.id;
              if (!itemId) return;
              // Returns have negative quantities, so they cancel out the sale.
              const quantity = Number(item.quantity) || 0;
              const revenue = quantity * (Number(item.sellPrice) || 0);
              if (itemSales[itemId]) {
                itemSales[itemId].quantity += quantity;
                itemSales[itemId].revenue += revenue;
              } else {
                itemSales[itemId] = {
                  name: item.itemName || item.name || "-",
                  quantity,
                  revenue
                };
              }
            });
          }
        });

        const formattedData = Object.keys(itemSales).map(itemId => ({
          itemId: itemId,
          itemName: itemSales[itemId].name,
          quantitySold: itemSales[itemId].quantity,
          totalRevenue: itemSales[itemId].revenue
        })).filter(item => item.quantitySold > 0)
          .sort((a, b) => b.quantitySold - a.quantitySold).slice(0, 20); // Ambil 20 barang teratas

        setTopItems(formattedData);
      } catch (error) {
        console.error("Gagal memuat barang terlaris:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchTopSelling();
  }, []);

  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Laporan Barang Terlaris (Top Selling)</h1>
          <p className="text-gray-600">Daftar barang yang paling banyak terjual.</p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
                <TrendingUp />
                Daftar Top 20 Barang Terlaris
            </CardTitle>
            <CardDescription>Berdasarkan jumlah unit terjual (dikurangi retur) dalam 90 hari terakhir.</CardDescription>
          </CardHeader>
          <CardContent>
             <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-2">#</th>
                    <th className="text-left py-3 px-2">Nama Barang</th>
                    <th className="text-center py-3 px-2">Jumlah Terjual</th>
                    <th className="text-right py-3 px-2">Total Omzet</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    <tr><td colSpan={4} className="text-center p-4">Memuat data...</td></tr>
                  ) : topItems.map((item, index) => (
                      <tr key={item.itemId} className="border-b hover:bg-gray-50">
                        <td className="py-3 px-2 font-bold">{index + 1}</td>
                        <td className="py-3 px-2 font-medium">{item.itemName}</td>
                        <td className="py-3 px-2 text-center">{item.quantitySold} unit</td>
                        <td className="py-3 px-2 text-right">Rp {item.totalRevenue.toLocaleString("id-ID")}</td>
                      </tr>
                    ))
                  }
                </tbody>
              </table>
               {!isLoading && topItems.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  Belum ada data transaksi untuk ditampilkan.
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </MainLayout>
  );
}