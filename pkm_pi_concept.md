# Konsep Proposal PKM-PI 2026: Annur Motor System

Jika aplikasi **Annur Motor System** ini diajukan untuk Program Kreativitas Mahasiswa - Penerapan Iptek (PKM-PI), maka fokus proposal harus mengarah pada **penyelesaian masalah nyata yang dihadapi oleh mitra (Bengkel Annur Motor) melalui teknologi yang kita bangun.**

Pendekatan PKM-PI mengharuskan adanya "Mitra Profit" (usaha berorientasi laba seperti bengkel/toko sparepart) yang memiliki permasalahan spesifik yang dapat diselesaikan dengan solusi IPTEK.

Berikut adalah kerangka/ide besar untuk proposal PKM-PI 2026:

## 1. Judul yang Menarik (Saran)
**Penerapan Annur Motor System: Aplikasi Point of Sale (POS) dan Inventori Terintegrasi Multi-Gudang dengan Dual Pricing System untuk Meningkatkan Akuntabilitas dan Tata Kelola Manajemen Bengkel Annur Motor**

## 2. Analisis Situasi & Permasalahan Mitra (Latar Belakang)
Di bagian ini, ceritakan kondisi Annur Motor sebelum adanya aplikasi ini. Permasalahan utama yang diangkat harus cocok dengan fitur unggulan aplikasi:
*   **Masalah Inventori Kesasar (Toko vs Gudang):** Seringnya ketidakcocokan antara barang yang dipajang di etalase/toko dengan yang ada di gudang penyimpanan. 
*   **Harga Majemuk yang Membingungkan (Mekanik vs Umum):** Bengkel melayani dua jenis penjualan: eceran biasa (pelanggan beli bawa pulang) dan pemasangan oleh mekanik. Harga jualnya berbeda, namun pencatatannya manual dan rawan salah hitung.
*   **Permintaan Stok Tidak Tercatat:** Mekanik atau kasir toko sering mengambil barang dari gudang tanpa dokumentasi yang jelas, menyebabkan hilangnya jejak barang ("barang gaib").
*   **Audit Stok (Stock Opname) yang Melelahkan:** Perhitungan stok fisik masih pakai buku besar, rawan selisih, dan butuh waktu lama untuk rekonsiliasi.

## 3. Solusi IPTEK yang Ditawarkan (Aplikasi Annur Motor)
Sebutkan bagaimana fitur-fitur aplikasi ini menjadi jawaban dari masalah di atas secara elegan:
*   **Manajemen Multi-Lokasi Stok (Fitur *Store/Gudang*):** Aplikasi memisahkan angka stok antara stok pajangan (Toko) dan stok penyimpanan (Gudang). Semuanya dapat dilacak real-time.
*   **Role-Based Access Control & Dashboard Staff vs Admin:** Karyawan (Staff) hanya bisa mengakses fitur kasir dan melihat laporan hari ini, tanpa bisa melihat harga modal (Buy Price) atau profit. Hanya pemilik (Admin) yang punya kontrol penuh.
*   **Sistem Permintaan Stok Digital (Stock Request):** Kasir/Mekanik (Staff) tidak bisa langsung ubah angka stok gudang. Mereka harus melakukan "Permintaan Stok" di aplikasi, dan Admin akan me- *review/approve*. Otomatis angka stok berpindah dari Gudang ke Toko secara aman dan tercatat.
*   **Dual-Pricing Checkout:** Kasir bisa dengan mudah memilih harga *Ecer* atau harga *Mekanik* dengan sekali klik saat transaksi, memastikan nota dan laporan keuangan akurat secara otomatis.
*   **Mobile & Desktop (Fitur Responsif Multiplatform):** Kasir bisa menggunakan Desktop PC karena layarnya lebar (layout profesional split-view), sedangkan Pemilik/Admin bisa memantau semuanya (Laporan Laba, Top Items) sambil berjalan menggunakan Smartphone secara Real-time dengan Cloud Firestore database.

## 4. Manfaat & Luaran bagi Mitra (Annur Motor)
*   **Zero Leakage (Nihil Kebocoran):** Pergerakan barang dari gudang ke etalase toko, dan dari etalase ke nota pelanggan semua terekam jelas di history transaksi.
*   **Penghematan Waktu (Efisiensi):** Proses Stock Opname dan pembuatan laporan penjualan harian yang dulunya manual berjam-jam kini instan ter-generate otomatis dengan grafik (*Weekly Revenue Chart*).
*   **Keputusan Bisnis Lebih Cepat:** Dengan alert *Stok Menipis* otomatis, mitra bisa restock sparepart terlaris tepat waktu tanpa kehilangan potensi pelanggan.

---

### Tips Khusus untuk PKM-PI:
1.  **Tekankan Aspek "Penerapan":** Juri PKM-PI suka dengan teknologi yang **sudah siap dan benar-benar dipakai/menyelesaikan masalah mitra**, bukan sekadar aplikasi pura-pura. Pastikan Anda punya foto/video saat tim menginstalasikan aplikasi ini di PC/Tablet Annur Motor dan melatih kasirnya.
2.  **Highlight UI/UX:** Ceritakan bahwa UI/UX didesain khusus agar mudah dipelajari oleh kasir/mekanik (desain Livin-style, *Traffic Light Stock Indicators* untuk stok tipis, dan icon font besar). Desktop shortcuts seperti `F4` untuk bayar menunjukkan bahwa pembuat aplikasi *melek* kenyataan lapangan kasir.
3.  **Surat Mitra:** Siapkan surat pernyataan kesediaan bekerja sama dari pemilik Annur Motor (tanda tangan & cap).

Pada intinya, aplikasi ini sangat cocok dan **powerful** jika diajukan ke PKM-PI karena memiliki tingkat kompleksitas bisnis yang menyentuh urat nadi UMKM bengkel (Stok, Hak Akses, Aliran Barang, dan Multi-Harga), bukan sekadar aplikasi kasir sederhana.
