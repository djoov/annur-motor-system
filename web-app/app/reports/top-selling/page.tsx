"use client"

import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { collection, getDocs } from "firebase/firestore"
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
      const transactionsSnapshot = await getDocs(collection(db, "transactions"));
      
      const itemSales: { [key: string]: { name: string, quantity: number, revenue: number } } = {};

      transactionsSnapshot.forEach(doc => {
        const transaction = doc.data();
        if (transaction.items && Array.isArray(transaction.items)) {
          transaction.items.forEach(item => {
            const itemId = item.itemId;
            if (itemSales[itemId]) {
              itemSales[itemId].quantity += item.quantity;
              itemSales[itemId].revenue += item.quantity * item.sellPrice;
            } else {
              itemSales[itemId] = {
                name: item.itemName,
                quantity: item.quantity,
                revenue: item.quantity * item.sellPrice
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
      })).sort((a, b) => b.quantitySold - a.quantitySold).slice(0, 20); // Ambil 20 barang teratas

      setTopItems(formattedData);
      setIsLoading(false);
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
            <CardDescription>Berdasarkan jumlah unit yang terjual dari semua transaksi.</CardDescription>
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