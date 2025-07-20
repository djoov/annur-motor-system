import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "./globals.css"
// --- [BARU] Impor komponen Providers ---
import { Providers } from "@/components/providers" 

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "ANNUR MOTOR - Sistem Manajemen",
  description: "Sistem manajemen untuk ANNUR MOTOR",
  generator: 'v0.dev'
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="id" suppressHydrationWarning> 
      {/* tambahkan suppressHydrationWarning di sini. 
        Ini aman dilakukan karena kita sudah mengelola tema di komponen klien.
      */}
      <body className={inter.className}>
        {/* --- [DIUBAH] Bungkus children dengan komponen Providers --- */}
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  )
}