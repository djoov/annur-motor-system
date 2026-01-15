import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
// --- [BARU] Impor komponen Providers ---
import { Providers } from "@/components/providers";

import NextTopLoader from 'nextjs-toploader';

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
        <NextTopLoader
          color="#2563eb"
          initialPosition={0.08}
          crawlSpeed={200}
          height={3}
          crawl={true}
          showSpinner={false}
          easing="ease"
          speed={200}
          shadow="0 0 10px #2299DD,0 0 5px #2299DD"
        />
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
