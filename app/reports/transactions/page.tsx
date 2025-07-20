"use client"

import { useState, useEffect } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { collection, getDocs, orderBy, query } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { FileText } from "lucide-react"
import { Timestamp } from "firebase/firestore"

interface Transaction {
  id: string;
  transactionDate: Timestamp;
  totalAmount: number;
  totalProfit: number;
  customerName: string;
  items: any[];
}

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchTransactions = async () => {
      setIsLoading(true);
      const q = query(collection(db, "transactions"), orderBy("transactionDate", "desc"));
      const querySnapshot = await getDocs(q);
      const transctionsList = querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      } as Transaction));

      setTransactions(transctionsList);
      setIsLoading(false);
    };

    fetchTransactions();
  }, []);

  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Laporan Semua Transaksi</h1>
          <p className="text-gray-600">Rincian semua transaksi penjualan yang tercatat.</p>
        </div>

        <Card>
          <CardHeader>
             <CardTitle className="flex items-center gap-2">
                <FileText />
                Detail Transaksi
            </CardTitle>
            <CardDescription>Menampilkan semua transaksi diurutkan dari yang terbaru.</CardDescription>
          </CardHeader>
          <CardContent>
             <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-2">Tanggal</th>
                    <th className="text-left py-3 px-2">ID Transaksi</th>
                    <th className="text-left py-3 px-2">Pelanggan</th>
                    <th className="text-center py-3 px-2">Jumlah Item</th>
                    <th className="text-right py-3 px-2">Total Omzet</th>
                    <th className="text-right py-3 px-2">Total Keuntungan</th>
                  </tr>
                </thead>
                <tbody>
                  {isLoading ? (
                    <tr><td colSpan={6} className="text-center p-4">Memuat data...</td></tr>
                  ) : transactions.map((trx) => (
                      <tr key={trx.id} className="border-b hover:bg-gray-50">
                        <td className="py-3 px-2">{trx.transactionDate.toDate().toLocaleString("id-ID")}</td>
                        <td className="py-3 px-2 font-mono text-xs">{trx.id}</td>
                        <td className="py-3 px-2">{trx.customerName}</td>
                        <td className="py-3 px-2 text-center">{trx.items.length}</td>
                        <td className="py-3 px-2 text-right">Rp {trx.totalAmount.toLocaleString("id-ID")}</td>
                        <td className="py-3 px-2 text-right text-green-600">Rp {trx.totalProfit.toLocaleString("id-ID")}</td>
                      </tr>
                    ))
                  }
                </tbody>
              </table>
               {!isLoading && transactions.length === 0 && (
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