"use client"

import type React from "react"
import { useState } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Progress } from "@/components/ui/progress"
// --- [DIPERBAIKI] Menambahkan 'Plus' ke dalam import ---
import { Upload, Download, FileText, CheckCircle, AlertCircle, Edit, Plus } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import Papa from "papaparse"
import { db } from "@/lib/firebase"
import { collection, writeBatch, doc, serverTimestamp, getDocs, query, where, limit, DocumentData } from "firebase/firestore"

interface ImportResult {
  added: number
  updated: number
  failed: number
  errors: string[]
}
type CsvData = { [key: string]: any }[];

const dataTypesConfig = {
  items: {
    label: "Data Barang",
    collection: "items",
    // Match Mobile App Headers EXACTLY
    headers: ["KODE", "NAMA BARANG", "HARGA BELI", "HARGA JUAL (UMUM)", "STOK TOKO", "STOK GUDANG", "KATEGORI"] as const,
    sample: [
      {
        "KODE": "OLI-SAMPLE",
        "NAMA BARANG": "Oli Contoh",
        "HARGA BELI": 50000,
        "HARGA JUAL (UMUM)": 65000,
        "STOK TOKO": 100,
        "STOK GUDANG": 50,
        "KATEGORI": "Oli & Pelumas"
      },
    ],
  },
  customers: {
    label: "Data Pelanggan",
    collection: "customers",
    headers: ["name", "phone", "email", "address"] as const,
    sample: [
      { name: "Budi Pelanggan", phone: "081234567890", email: "budi@email.com", address: "Jl. Merdeka 1" },
    ],
  },
  suppliers: {
    label: "Data Supplier",
    collection: "suppliers",
    headers: ["name", "contact", "phone", "email", "address"] as const,
    sample: [
      { name: "PT. Pemasok Jaya", contact: "Andi", phone: "021-9876543", email: "andi@pemasok.com", address: "Jl. Industri 2" },
    ],
  },
} as const;

type DataTypeKey = keyof typeof dataTypesConfig;

export default function ImportPage() {
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [importType, setImportType] = useState<DataTypeKey | "">("")
  const [isProcessing, setIsProcessing] = useState(false)
  const [uploadProgress, setUploadProgress] = useState(0)
  const [importResult, setImportResult] = useState<ImportResult | null>(null)
  const [parsedData, setParsedData] = useState<CsvData>([])
  const [headers, setHeaders] = useState<string[]>([])
  const { toast } = useToast()

  const [exportType, setExportType] = useState<DataTypeKey | "">("")
  const [isExporting, setIsExporting] = useState(false)

  const downloadTemplate = (type: DataTypeKey) => {
    const config = dataTypesConfig[type];
    const csv = Papa.unparse({ fields: [...config.headers], data: config.sample as any });
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    link.setAttribute("href", URL.createObjectURL(blob));
    link.setAttribute("download", `template_${type}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  const handleExportData = async () => {
    if (!exportType) return;
    setIsExporting(true);
    try {
      const config = dataTypesConfig[exportType];
      const querySnapshot = await getDocs(collection(db, config.collection));
      const dataToExport = querySnapshot.docs.map(doc => {
        const data = doc.data();
        const row: { [key: string]: any } = {};
        // Basic mapping for export - might need refinement for renamed columns, but keeping simple for now
        // If we use mobile headers for items, we should map them back
        if (exportType === 'items') {
          row["KODE"] = data.code;
          row["NAMA BARANG"] = data.name;
          row["HARGA BELI"] = data.buyPrice;
          row["HARGA JUAL (UMUM)"] = data.sellPrice;
          row["STOK TOKO"] = data.stock;
          row["STOK GUDANG"] = data.qty_warehouse || 0;
          row["KATEGORI"] = data.category;
        } else {
          config.headers.forEach(header => {
            if (header in data) {
              row[header] = data[header];
            }
          });
        }
        return row;
      });
      if (dataToExport.length === 0) {
        toast({ title: "Tidak ada data untuk diekspor" });
        return;
      }
      const csv = Papa.unparse(dataToExport);
      const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
      const link = document.createElement("a");
      link.setAttribute("href", URL.createObjectURL(blob));
      link.setAttribute("download", `export_${exportType}_${new Date().toISOString().split('T')[0]}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      toast({ title: "Ekspor Berhasil", description: `${dataToExport.length} baris data telah diunduh.` });
    } catch (e: any) {
      toast({ title: "Ekspor Gagal", description: e.message, variant: "destructive" });
    } finally {
      setIsExporting(false);
    }
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.type !== "text/csv" && !file.name.endsWith(".csv")) {
        toast({ title: "Format file tidak valid", variant: "destructive" });
        return;
      }
      setSelectedFile(file);
      setImportResult(null);
      Papa.parse(file, {
        header: true,
        skipEmptyLines: true,
        complete: (results) => {
          setParsedData(results.data as CsvData);
          setHeaders(results.meta.fields || []);
        },
      });
    }
  }

  const handleImport = async () => {
    if (!selectedFile || !importType || parsedData.length === 0) {
      toast({ title: "Data tidak lengkap", variant: "destructive" });
      return;
    }
    setIsProcessing(true);
    setUploadProgress(0);

    const collectionRef = collection(db, importType);
    const batch = writeBatch(db);
    let added = 0, updated = 0;
    const errors: string[] = [];

    for (const [index, row] of parsedData.entries()) {
      try {
        let keyField = importType === 'items' ? 'code' : 'name';

        // --- NORMALISASI & MAPPING HEADER (Mobile Sync) ---
        let processedRow: DocumentData = {};

        if (importType === 'items') {
          // Mapping Mobile -> Web fields
          const getVal = (keys: string[]) => keys.reduce((acc, k) => acc || row[k] || row[k.toUpperCase()] || row[k.toLowerCase()], undefined);

          const rawCode = getVal(['code', 'KODE', 'Kode Barang', 'kode_barang']);
          const rawName = getVal(['name', 'NAMA BARANG', 'Nama Barang', 'nama_barang']);
          const rawBuy = getVal(['buyPrice', 'HARGA BELI', 'Harga Beli', 'harga_beli']);
          const rawSell = getVal(['sellPrice', 'HARGA JUAL (UMUM)', 'HARGA JUAL', 'Harga Jual', 'harga_jual']);
          const rawStock = getVal(['stock', 'qt_display', 'STOK TOKO', 'STOCK DISPLAY', 'Stok Toko', 'jumlah']);
          const rawQtyWarehouse = getVal(['qty_warehouse', 'STOK GUDANG', 'Stok Gudang']);
          const rawMinStock = getVal(['minStock', 'min_stock', 'stok_min']);
          const rawCategory = getVal(['category', 'KATEGORI', 'Category', 'brand']);

          processedRow = {
            code: (rawCode || "").toString().trim().toUpperCase(),
            name: (rawName || "").toString().trim(),
            description: row.description || "",
            category: rawCategory || "Uncategorized",
            buyPrice: Number(rawBuy) || 0,
            sellPrice: Number(rawSell) || 0,
            stock: Number(rawStock) || 0,
            qty_warehouse: Number(rawQtyWarehouse) || 0,
            minStock: Number(rawMinStock) || 5,
          };

          keyField = 'code';
          // Don't use the raw row[keyField] anymore, use processedRow.code
        } else {
          // For Customers/Suppliers, keep standard behavior but trim names
          processedRow = { ...row };
          if (row.name) processedRow.name = row.name.toString().trim();
        }

        const keyFieldValue = processedRow[keyField];

        if (!keyFieldValue) {
          errors.push(`Baris ${index + 2}: Kolom kunci '${keyField}' (atau aliasnya) wajib diisi.`);
          continue;
        }

        const q = query(collectionRef, where(keyField, "==", keyFieldValue), limit(1));
        const snapshot = await getDocs(q);

        if (snapshot.empty) {
          const newDocRef = doc(collectionRef);
          batch.set(newDocRef, { ...processedRow, createdAt: serverTimestamp() });
          added++;
        } else {
          const existingDocRef = snapshot.docs[0].ref;
          // Merge logic: only update fields present in CSV? 
          // Current requirement: "Sync" usually means overwrite/update.
          batch.update(existingDocRef, processedRow);
          updated++;
        }
      } catch (e: any) {
        errors.push(`Baris ${index + 2}: ${e.message}`);
      }
      setUploadProgress(((index + 1) / parsedData.length) * 100);
    }

    try {
      await batch.commit();
      setImportResult({ added, updated, failed: errors.length, errors });
      toast({ title: "Import Selesai", description: `Ditambah: ${added}, Diperbarui: ${updated}, Gagal: ${errors.length}.` });
      setSelectedFile(null);
      setParsedData([]);
      setHeaders([]);
    } catch (e: any) {
      toast({ title: "Gagal menyimpan data", description: e.message, variant: "destructive" });
    } finally {
      setIsProcessing(false);
    }
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Impor & Ekspor Data</h1>
          <p className="text-gray-600">Kelola data Anda secara massal menggunakan file CSV.</p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center"><Download className="mr-2 h-5 w-5" />Ekspor Data ke CSV</CardTitle>
            <CardDescription>Unduh semua data yang ada di database ke dalam format file CSV.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col sm:flex-row gap-4 items-end">
              <div className="flex-grow w-full">
                <Label htmlFor="exportType">Pilih Jenis Data</Label>
                <Select value={exportType} onValueChange={(value) => setExportType(value as DataTypeKey)} disabled={isExporting}>
                  <SelectTrigger><SelectValue placeholder="Pilih data untuk diekspor" /></SelectTrigger>
                  <SelectContent>
                    {Object.keys(dataTypesConfig).map((key) => (<SelectItem key={key} value={key}>{dataTypesConfig[key as DataTypeKey].label}</SelectItem>))}
                  </SelectContent>
                </Select>
              </div>
              <Button onClick={handleExportData} disabled={isExporting || !exportType} className="w-full sm:w-auto">
                {isExporting ? "Mengekspor..." : "Ekspor Data"}
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center"><Upload className="mr-2 h-5 w-5" />Impor Data dari CSV</CardTitle>
            <CardDescription>
              Sistem akan menambah data baru dan memperbarui data yang sudah ada berdasarkan Kode Barang (untuk barang) atau Nama (untuk pelanggan/supplier).
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label>1. Unduh Template (Opsional)</Label>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 mt-1">
                {Object.keys(dataTypesConfig).map(key => (<Button key={key} variant="outline" onClick={() => downloadTemplate(key as DataTypeKey)}><FileText className="mr-2 h-4 w-4" /> Template {dataTypesConfig[key as DataTypeKey].label}</Button>))}
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 items-end">
              <div>
                <Label htmlFor="importType">2. Pilih Jenis Data</Label>
                <Select value={importType} onValueChange={(value) => setImportType(value as DataTypeKey)} disabled={isProcessing}>
                  <SelectTrigger><SelectValue placeholder="Pilih jenis data" /></SelectTrigger>
                  <SelectContent>
                    {Object.keys(dataTypesConfig).map(key => (<SelectItem key={key} value={key}>{dataTypesConfig[key as DataTypeKey].label}</SelectItem>))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="csvFile">3. Pilih File CSV</Label>
                <Input id="csvFile" type="file" accept=".csv" onChange={handleFileChange} disabled={isProcessing} />
              </div>
            </div>
            {isProcessing && <Progress value={uploadProgress} />}
            <Button onClick={handleImport} disabled={!selectedFile || !importType || isProcessing || parsedData.length === 0} className="w-full">
              {isProcessing ? "Sedang Memproses..." : `4. Proses ${parsedData.length} Baris Data`}
            </Button>
          </CardContent>
        </Card>

        {importResult && (
          <Card>
            <CardHeader><CardTitle>Hasil Import</CardTitle></CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div className="flex items-center p-3 bg-green-50 rounded-lg">
                  <Plus className="h-8 w-8 text-green-600 mr-3" />
                  <div><p className="font-semibold text-green-800">Data Ditambahkan</p><p className="text-2xl font-bold text-green-600">{importResult.added}</p></div>
                </div>
                <div className="flex items-center p-3 bg-blue-50 rounded-lg">
                  <Edit className="h-8 w-8 text-blue-600 mr-3" />
                  <div><p className="font-semibold text-blue-800">Data Diperbarui</p><p className="text-2xl font-bold text-blue-600">{importResult.updated}</p></div>
                </div>
                <div className="flex items-center p-3 bg-red-50 rounded-lg">
                  <AlertCircle className="h-8 w-8 text-red-600 mr-3" />
                  <div><p className="font-semibold text-red-800">Gagal</p><p className="text-2xl font-bold text-red-600">{importResult.failed}</p></div>
                </div>
              </div>
              {importResult.errors.length > 0 && (
                <div>
                  <h4 className="font-semibold mb-2 text-red-800">Detail Eror:</h4>
                  <div className="bg-red-50 border border-red-200 rounded-lg p-3 max-h-40 overflow-y-auto">
                    <ul className="list-disc list-inside space-y-1 text-sm text-red-700">
                      {importResult.errors.map((error, index) => (<li key={index}>{error}</li>))}
                    </ul>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </div>
    </MainLayout>
  )
}
