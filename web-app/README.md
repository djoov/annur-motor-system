# Annur Motor - Sistem Manajemen & Landing Page

Sistem Manajemen Toko & Bengkel Motor Berbasis Web Modern yang Terintegrasi Penuh dengan Halaman Publik untuk Branding.

Aplikasi ini dirancang untuk mendigitalkan dan mengoptimalkan operasional harian bengkel dan toko spare part "Annur Motor". Terdiri dari dua bagian utama: halaman landing page publik yang elegan untuk menarik pelanggan, dan sistem manajemen internal yang komprehensif untuk staf dan admin.

---

## ✨ Fitur Utama

Aplikasi ini dilengkapi dengan serangkaian fitur canggih untuk memenuhi kebutuhan bisnis modern.

### Halaman Publik (Etalase Digital)

* 🎨 **Landing Page Menarik**: Desain modern dengan image carousel otomatis di hero section.
* 🚀 **SEO-Optimized**: Dibangun dengan Next.js Server Components dan metadata yang kaya untuk visibilitas maksimal di mesin pencari.
* 📦 **Produk Unggulan Dinamis**: Menampilkan produk secara acak dari database setiap kali halaman dimuat.
* 📱 **Desain Responsif**: Tampilan sempurna di semua perangkat, dari desktop hingga mobile.
* 💬 **Tombol WhatsApp**: Memudahkan calon pelanggan untuk menghubungi Anda secara langsung.

### Sistem Manajemen Internal (Back Office)

* 📈 **Dashboard Real-time**: Memantau statistik kunci seperti penjualan harian, keuntungan, dan status stok secara langsung.
* 🛒 **Point of Sale (POS) / Kasir**: Sistem kasir yang terintegrasi penuh, secara otomatis mengurangi stok dan mencatat setiap transaksi.
* 🗃️ **Manajemen Master Data (CRUD)**:

  * **Barang**: Kelola data produk lengkap dengan gambar, stok, harga beli, dan harga jual.
  * **Pelanggan, Supplier, Kategori**: Manajemen data yang terstruktur.
* 📊 **Sistem Laporan Dinamis**: Hasilkan laporan penjualan, keuntungan, barang terlaris, dan lainnya berdasarkan data transaksi nyata.
* 👤 **Manajemen Profil Pengguna**: Pengguna dapat mengedit profil mereka, termasuk mengunggah foto.
* 🔄 **Impor & Ekspor CSV**: Kelola data dalam jumlah besar dengan mudah melalui fitur impor dari template dan ekspor data ke file CSV.
* 🔐 **Autentikasi Aman**: Sistem login yang aman menggunakan Firebase Authentication (Email/Password & Google) dengan fitur "Ingat Saya".

---

## 🛠️ Teknologi yang Digunakan

Proyek ini dibangun menggunakan tumpukan teknologi modern yang cepat, andal, dan skalabel.

* **Framework**: Next.js (App Router)
* **Bahasa**: TypeScript
* **Backend & Database**: Google Firebase (Authentication, Firestore, Storage)
* **Styling**: Tailwind CSS
* **Komponen UI**: shadcn/ui
* **Deployment**: Netlify

---

## 🚀 Cara Menjalankan Proyek Secara Lokal

Ikuti langkah-langkah ini untuk menjalankan aplikasi di komputer Anda.

### Prasyarat

* Node.js (v18 atau lebih baru)
* pnpm (instal dengan `npm install -g pnpm`)

### 1. Kloning Repositori

```bash
git clone https://github.com/djoov/annur-motor-system.git
cd annur-motor-system
```

### 2. Instal Dependensi

```bash
pnpm install
```

### 3. Siapkan Firebase

* Buka [Firebase Console](https://console.firebase.google.com/) dan buat proyek baru.
* Aktifkan **Authentication** (dengan provider Email/Password dan Google).
* Aktifkan **Firestore Database** (mulai dalam mode produksi).
* Aktifkan **Firebase Storage**.
* Atur **Security Rules** untuk Firestore dan Storage sesuai dengan panduan pengembangan.

### 4. Konfigurasi Environment Variables

* Buat file baru di root direktori bernama `.env.local`.
* Salin konten dari file firebaseConfig di proyek Firebase Anda ke dalam `.env.local` dengan format berikut:

```env
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
NEXT_PUBLIC_FIREBASE_APP_ID=...
```

### 5. Jalankan Server Development

```bash
pnpm dev
```

Aplikasi akan berjalan di `http://localhost:3000`

---

## ☁️ Deployment

Proyek ini dikonfigurasi untuk deployment yang mudah di **Netlify**.

1. **Push ke GitHub**: Pastikan semua kode Anda sudah di-push ke repositori GitHub.
2. **Hubungkan ke Netlify**: Impor repositori Anda dari GitHub ke Netlify.
3. **Konfigurasi Variabel**: Tambahkan semua environment variables dari file `.env.local` Anda ke pengaturan situs di Netlify (`Site configuration > Environment variables`).
4. **Deploy**: Netlify akan secara otomatis membangun dan men-deploy situs Anda menggunakan konfigurasi dari file `netlify.toml`.

---

**✨ Dibuat dengan cinta untuk efisiensi operasional dan kesan profesional bisnis bengkel modern.**
