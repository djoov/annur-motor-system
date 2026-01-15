"use client"

import Image from "next/image"
import Link from "next/link"
import { SITE_CONFIG } from "@/lib/config"

export function PublicNavbar() {
  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-md shadow-sm border-b border-white/20">
      <div className="container mx-auto px-4 py-4 flex justify-between items-center relative">
        <Link href="/" className="flex items-center space-x-3 group z-20 relative">
          <div className="relative w-10 h-10 transition-transform group-hover:scale-110 duration-300">
            <Image
              src="/logo.png"
              alt="Annur Motor Logo"
              fill
              className="object-contain"
              priority
            />
          </div>
          <span className="text-xl font-black text-slate-800 tracking-tight">ANNUR MOTOR</span>
        </Link>

        {/* Centered Navigation */}
        <nav className="hidden md:flex items-center space-x-8 absolute left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2">
          <a href="#layanan" className="text-sm font-medium text-slate-600 hover:text-blue-600 transition-colors uppercase tracking-wide">Layanan</a>
          <a href="#produk" className="text-sm font-medium text-slate-600 hover:text-blue-600 transition-colors uppercase tracking-wide">Produk</a>
          <a href="#lokasi" className="text-sm font-medium text-slate-600 hover:text-blue-600 transition-colors uppercase tracking-wide">Lokasi</a>
        </nav>

        {/* Right side placeholder (Login button could go here in future) */}
        <div className="w-10"></div>
      </div>
    </header>
  )
}
