# Design System: Annur Motor System (Mobile)

Dokumen ini mendeskripsikan pedoman desain (Design Guidelines) khusus untuk **Home Screen** (Dashboard) yang baru saja diperbarui menggunakan referensi gaya "MekanikHub".

## 1. Palet Warna (Color Palette)
Desain baru meninggalkan warna solid statis (mis. biru tua standar) dan beralih ke warna dengan *gradient* yang terasa lebih hidup dan modern.

| Nama Warna | Hex Code | Penggunaan |
|---|---|---|
| **Primary Color** | `#0058BE` | Warna utama aplikasi (Teks header, icon aktif, elemen utama) |
| **Secondary Color** | `#6B38D4` | Warna pendamping utama (Digunakan bersama Primary untuk efek *gradient*) |
| **Background Color** | `#F8FAFC` | Warna latar belakang Scaffold aplikasi (Slightly blueish white) |
| **Surface Color** | `#FFFFFF` | Warna latar belakang Cards, Bottom Nav, dan komponen _floating_ |
| **Text Primary** | `#131B2E` | Teks judul utama (Headings) |
| **Text Secondary** | `#424754` | Teks keterangan, *subtitle*, ikon tidak aktif |
| **Muted/Border** | `#C2C6D6` | Garis batas (*border*) dan pemisah (*divider*) |

### Gradient Standard
Gradient digunakan pada tombol pencarian (opsional) dan khususnya pada tombol menu Kasir di tengah navbar.
```dart
LinearGradient(
  colors: [Color(0xFF0058BE), Color(0xFF6B38D4)],
)
```

---

## 2. Struktur Komponen Home Screen (`home_screen.dart`)

Halaman utama dirancang untuk dapat di-*scroll* secara penuh (`CustomScrollView`) dan memiliki lapisan bawah (_bottom_) terpisah untuk *Bottom Navigation*.

### A. Header Panel
- **Profile Picture**: Inisial user ditampilkan di dalam lingkaran berwarna `Color(0xFFDAE2FD)`.
- **Title**: Teks "Annur Motor" dengan *font weight* bold, warna Primary.
- **Action Button**: Tombol "Scan QR" (ikon `LucideIcons.scan`) berada di sebelah kanan.

### B. Hero Card (Penjualan Hari Ini)
Sebuah _card_ besar yang menonjol untuk memberikan _summary_ harian kepada pemilik bengkel.
- **Styling**: Latar putih dengan _soft shadow_.
- **Pill Badge**: "Hari Ini" dengan warna latar ungu pucat `Color(0xFFE9DDFF)` dan warna teks secondary.
- **Informasi Utama**: Menampilkan Total Pendapatan berukuran besar (24px, Bold) dan Total Transaksi.
- **Icon**: Ikon Dompet (_Wallet_) di sebelah kanan di dalam lingkaran ber-*gradient*.

### C. Quick Access Grid (Akses Cepat)
Menu utama untuk navigasi yang lebih kompleks.
- **Layout**: Grid 4-kolom (`crossAxisCount: 4`).
- **Card Menu**: Tiap menu (Kasir, Kategori, Pelanggan, dll) diletakkan di dalam container berujung membulat (radius 16px) dengan *shadow* yang sangat halus (opacity 5%).
- **Icon**: Menggunakan `lucide_icons_flutter`. Warnanya dibedakan antar-fitur agar *user* lebih mudah menghafal lokasi fitur berdasarkan warna ikon.

### D. Daftar Transaksi Terbaru
- Menampilkan 3 transaksi terakhir.
- **Icon**: Ikon tas belanja dalam lingkaran biru pucat (`#EAEDFF`).
- **Divider**: Pemisah antar *item* di dalam *card* menggunakan garis tipis.

### E. Floating Bottom Navigation Bar
Desain navbar diubah dari statis-menempel-bawah menjadi melayang (*floating*).
- **Glassmorphism**: Memiliki efek blur (_BackdropFilter_ `sigmaX: 10, sigmaY: 10`) dipadukan dengan `Colors.white.withValues(alpha: 0.9)`.
- **Pill Shape**: Memiliki radius luar 30px (berbentuk kapsul).
- **Center Button**: Tab tengah (Kasir/POS) ditekankan melalui bentuk lingkaran penuh yang diberi _gradient_ biru-ungu dengan _glow shadow_ kecil.
- **Indikator Aktif**: Tab yang aktif (kecuali bagian tengah) akan diberi warna _background_ biru pucat (`Color(0xFF2170E4)` opacity 10%) berbentuk membulat.

---

## 3. Efek & Shadows
- **Shadow Default**: Digunakan pada sebagian besar card untuk kesan "mengambang".
  ```dart
  BoxShadow(
    color: Color(0xFF0F172A).withValues(alpha: 0.05),
    blurRadius: 20,
    offset: Offset(0, 4),
  )
  ```
- **Shadow Navbar**: Lebih tegas agar navbar terpisah jelas dari konten utama yang di-*scroll*.
  ```dart
  BoxShadow(
    color: Color(0xFF0F172A).withValues(alpha: 0.08),
    blurRadius: 30,
    offset: Offset(0, 10),
  )
  ```

---

## 4. Tipografi
Aplikasi ini memakai tipografi _default_ dari Material Design (Roboto) dengan penyesuaian _font weight_.
- **Section Titles**: 20px, Semi-Bold (`FontWeight.w600`), Warna Text Primary.
- **Value Highlight**: 24px, Bold (`FontWeight.bold`), Warna Text Primary.
- **Grid Menu Text**: 11px, Medium (`FontWeight.w500`), Warna Text Secondary.
- **Pill Text**: 12px, Medium (`FontWeight.w500`).
