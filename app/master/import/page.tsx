"use client"

import type React from "react"
import { useState } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Progress } from "@/components/ui/progress"
import { Upload, Download, FileText, CheckCircle, AlertCircle, Info } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import Papa from "papaparse"
import { db } from "@/lib/firebase"
import { collection, writeBatch, doc, serverTimestamp, getDocs } from "firebase/firestore"

// --- Interface & Tipe Data ---
interface ImportResult {
  success: number
  failed: number
  errors: string[]
}
type CsvData = { [key: string]: any }[];

// --- Konfigurasi untuk Template dan Ekspor ---
const dataTypesConfig = {
  items: {
    label: "Data Barang",
    collection: "items",
    headers: ["code", "name", "description", "category", "buyPrice", "sellPrice", "stock", "minStock"],
    sample: [
      { code: "OLI-SAMPLE", name: "Oli Contoh", description: "Deskripsi oli", category: "Oli & Pelumas", buyPrice: 50000, sellPrice: 65000, stock: 100, minStock: 20 },
    ],
  },
  customers: {
    label: "Data Pelanggan",
    collection: "customers",
    headers: ["name", "phone", "email", "address"],
    sample: [
      { name: "Budi Pelanggan", phone: "081234567890", email: "budi@email.com", address: "Jl. Merdeka 1" },
    ],
  },
  suppliers: {
    label: "Data Supplier",
    collection: "suppliers",
    headers: ["name", "contact", "phone", "email", "address"],
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
    const csv = Papa.unparse({
        fields: config.headers,
        data: config.sample
    });
    
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    const url = URL.createObjectURL(blob);
    link.setAttribute("href", url);
    link.setAttribute("download", `template_${type}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  const handleExportData = async () => {
    if (!exportType) {
        toast({ title: "Pilih jenis data untuk diekspor", variant: "destructive" });
        return;
    }
    setIsExporting(true);
    try {
        const config = dataTypesConfig[exportType];
        const querySnapshot = await getDocs(collection(db, config.collection));
        const dataToExport = querySnapshot.docs.map(doc => {
            const data = doc.data();
            const row: {[key: string]: any} = {};
            config.headers.forEach(header => {
                row[header] = data[header];
            });
            return row;
        });

        if (dataToExport.length === 0) {
            toast({ title: "Tidak ada data untuk diekspor" });
            setIsExporting(false);
            return;
        }

        const csv = Papa.unparse(dataToExport);
        const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
        const link = document.createElement("a");
        const url = URL.createObjectURL(blob);
        link.setAttribute("href", url);
        link.setAttribute("download", `export_${exportType}_${new Date().toISOString().split('T')[0]}.csv`);
        link.style.visibility = 'hidden';
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
        toast({ title: "Format file tidak valid", description: "Silakan pilih file CSV.", variant: "destructive" });
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
        error: (error) => {
           toast({ title: "Gagal membaca file CSV", description: error.message, variant: "destructive" });
        }
      });
    }
  }

  const handleImport = async () => {
    if (!selectedFile || !importType || parsedData.length === 0) {
      toast({ title: "Data tidak lengkap", description: "Pilih file dan jenis import terlebih dahulu.", variant: "destructive" });
      return;
    }

    setIsProcessing(true);
    setUploadProgress(0);

    const collectionRef = collection(db, importType);
    const batch = writeBatch(db);
    let successCount = 0;
    const errors: string[] = [];

    parsedData.forEach((row, index) => {
      try {
        const processedRow: { [key: string]: any } = { ...row };
        if (importType === 'items') {
            processedRow.buyPrice = Number(row.buyPrice) || 0;
            processedRow.sellPrice = Number(row.sellPrice) || 0;
            processedRow.stock = Number(row.stock) || 0;
            processedRow.minStock = Number(row.minStock) || 0;
        }

        const newDocRef = doc(collectionRef);
        batch.set(newDocRef, { ...processedRow, createdAt: serverTimestamp() });
        successCount++;
      } catch (e: any) {
        errors.push(`Baris ${index + 2}: ${e.message}`);
      }
      setUploadProgress(((index + 1) / parsedData.length) * 100);
    });

    try {
        await batch.commit();
        setImportResult({ success: successCount, failed: errors.length, errors });
        toast({ title: "Import Selesai", description: `Berhasil import ${successCount} data, gagal ${errors.length}.` });
        setSelectedFile(null);
        setParsedData([]);
        setHeaders([]);
    } catch (e: any) {
        toast({ title: "Gagal menyimpan data ke database", description: e.message, variant: "destructive" });
        setImportResult({ success: 0, failed: parsedData.length, errors: [e.message] });
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
                                {Object.keys(dataTypesConfig).map((key) => (
                                    <SelectItem key={key} value={key}>{dataTypesConfig[key as DataTypeKey].label}</SelectItem>
                                ))}
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
                Untuk mengimpor data, unduh template yang sesuai, isi data, lalu unggah file di bawah ini.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
                <div>
                    <Label>1. Unduh Template</Label>
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 mt-1">
                        {Object.keys(dataTypesConfig).map(key => (
                             <Button key={key} variant="outline" onClick={() => downloadTemplate(key as DataTypeKey)}>
                                <FileText className="mr-2 h-4 w-4"/> Template {dataTypesConfig[key as DataTypeKey].label}
                            </Button>
                        ))}
                    </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 items-end">
                    <div>
                        <Label htmlFor="importType">2. Pilih Jenis Data</Label>
                        <Select value={importType} onValueChange={(value) => setImportType(value as DataTypeKey)} disabled={isProcessing}>
                            <SelectTrigger><SelectValue placeholder="Pilih jenis data" /></SelectTrigger>
                            <SelectContent>
                               {Object.keys(dataTypesConfig).map(key => (
                                    <SelectItem key={key} value={key}>{dataTypesConfig[key as DataTypeKey].label}</SelectItem>
                                ))}
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
                {isProcessing ? "Sedang Mengimpor..." : `4. Import ${parsedData.length} Baris Data`}
              </Button>
            </CardContent>
        </Card>

        {parsedData.length > 0 && (
            <Card>
                <CardHeader>
                    <CardTitle>Preview Data (menampilkan 5 baris pertama)</CardTitle>
                    <CardDescription>Pastikan header dan data Anda sudah benar sebelum melakukan import.</CardDescription>
                </CardHeader>
                <CardContent className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead>
                            <tr className="border-b">
                                {headers.map(header => <th key={header} className="p-2 text-left font-semibold">{header}</th>)}
                            </tr>
                        </thead>
                        <tbody>
                            {parsedData.slice(0, 5).map((row, index) => (
                                <tr key={index} className="border-b">
                                    {headers.map(header => <td key={header} className="p-2 truncate max-w-xs">{row[header]}</td>)}
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </CardContent>
            </Card>
        )}

        {importResult && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <CheckCircle className="mr-2 h-5 w-5 text-green-600" />
                Hasil Import
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                <div className="flex items-center p-3 bg-green-50 rounded-lg">
                  <CheckCircle className="h-8 w-8 text-green-600 mr-3" />
                  <div>
                    <p className="font-semibold text-green-800">Berhasil</p>
                    <p className="text-2xl font-bold text-green-600">{importResult.success}</p>
                  </div>
                </div>
                <div className="flex items-center p-3 bg-red-50 rounded-lg">
                  <AlertCircle className="h-8 w-8 text-red-600 mr-3" />
                  <div>
                    <p className="font-semibold text-red-800">Gagal</p>
                    <p className="text-2xl font-bold text-red-600">{importResult.failed}</p>
                  </div>
                </div>
              </div>

              {importResult.errors.length > 0 && (
                <div>
                  <h4 className="font-semibold mb-2 text-red-800">Detail Eror:</h4>
                  <div className="bg-red-50 border border-red-200 rounded-lg p-3 max-h-40 overflow-y-auto">
                    <ul className="list-disc list-inside space-y-1 text-sm text-red-700">
                      {importResult.errors.map((error, index) => (
                        <li key={index}>{error}</li>
                      ))}
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
