import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
// --- [BARU] Impor komponen Providers ---
import { Providers } from "@/components/providers";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "ANNUR MOTOR - Sistem Manajemen",
  description: "Sistem Annur Motor Pucang",
  generator: "v0.dev", 
  verification: {
    google: "BFUh7rV1V4UvzJwP2X1IEgMp7pgApnb-UnyuMyTAyZI", 
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="id" suppressHydrationWarning>
      <body className={inter.className}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
