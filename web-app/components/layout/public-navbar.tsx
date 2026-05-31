"use client"

import { useState } from "react"
import Image from "next/image"
import Link from "next/link"
import { Search, User, Menu, X } from "lucide-react"

export function PublicNavbar() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-black border-b border-zinc-800 font-sans">
      {/* Top accent line (NVIDIA signature style) */}
      <div className="h-1 w-full bg-orange-600"></div>
      
      <div className="container mx-auto px-4 h-16 flex justify-between items-stretch relative">
        
        {/* Logo Section */}
        <Link href="/" className="flex items-center space-x-3 group z-20 hover:bg-zinc-900 px-4 -ml-4 transition-colors">
          <div className="relative w-8 h-8 filter grayscale contrast-200">
            <Image
              src="/logo.png"
              alt="Annur Motor Logo"
              fill
              className="object-contain"
              priority
            />
          </div>
          <span className="text-xl font-black text-white tracking-tighter uppercase">ANNUR MOTOR</span>
        </Link>

        {/* Desktop Navigation Links */}
        <nav className="hidden md:flex items-stretch absolute left-1/2 top-0 h-full transform -translate-x-1/2">
          <Link href="/katalog" className="flex items-center px-6 text-sm font-bold text-zinc-300 hover:text-white hover:bg-zinc-900 border-b-2 border-transparent hover:border-orange-500 transition-all uppercase tracking-widest">
            Hardware Database
          </Link>
          <Link href="/#layanan" className="flex items-center px-6 text-sm font-bold text-zinc-300 hover:text-white hover:bg-zinc-900 border-b-2 border-transparent hover:border-orange-500 transition-all uppercase tracking-widest">
            Modul Layanan
          </Link>
          <Link href="/oli" className="flex items-center px-6 text-sm font-bold text-zinc-300 hover:text-white hover:bg-zinc-900 border-b-2 border-transparent hover:border-orange-500 transition-all uppercase tracking-widest">
            Lubricants
          </Link>
        </nav>

        {/* Right side Actions */}
        <div className="flex items-stretch">
          <Link href="/katalog" className="flex items-center justify-center px-4 hover:bg-zinc-900 text-zinc-400 hover:text-white transition-colors border-l border-zinc-800 hidden sm:flex">
            <Search className="w-5 h-5" />
          </Link>
          <Link href="/login" className="flex items-center justify-center px-4 hover:bg-zinc-900 text-zinc-400 hover:text-white transition-colors border-l border-zinc-800 hidden sm:flex">
            <User className="w-5 h-5" />
          </Link>
          
          {/* Mobile Menu Toggle */}
          <button 
            className="md:hidden flex items-center justify-center px-4 hover:bg-zinc-900 text-zinc-400 hover:text-white transition-colors border-l border-zinc-800"
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          >
            {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </div>

      {/* Mobile Menu Dropdown */}
      {isMobileMenuOpen && (
        <div className="md:hidden bg-black border-b border-zinc-800 animate-in slide-in-from-top-2 duration-200">
          <nav className="flex flex-col">
            <Link 
              href="/katalog" 
              className="flex items-center px-6 py-4 text-sm font-bold text-zinc-300 hover:text-white hover:bg-zinc-900 border-l-4 border-transparent hover:border-orange-500 transition-all uppercase tracking-widest border-b border-zinc-900"
              onClick={() => setIsMobileMenuOpen(false)}
            >
              Hardware Database
            </Link>
            <Link 
              href="/#layanan" 
              className="flex items-center px-6 py-4 text-sm font-bold text-zinc-300 hover:text-white hover:bg-zinc-900 border-l-4 border-transparent hover:border-orange-500 transition-all uppercase tracking-widest border-b border-zinc-900"
              onClick={() => setIsMobileMenuOpen(false)}
            >
              Modul Layanan
            </Link>
            <Link 
              href="/oli" 
              className="flex items-center px-6 py-4 text-sm font-bold text-zinc-300 hover:text-white hover:bg-zinc-900 border-l-4 border-transparent hover:border-orange-500 transition-all uppercase tracking-widest border-b border-zinc-900"
              onClick={() => setIsMobileMenuOpen(false)}
            >
              Lubricants
            </Link>
            <div className="flex bg-zinc-950 p-4 gap-4">
               <Link href="/katalog" className="flex-1 flex items-center justify-center py-3 bg-zinc-900 hover:bg-zinc-800 text-white transition-colors border border-zinc-800">
                <Search className="w-5 h-5 mr-2" /> Cari
              </Link>
              <Link href="/login" className="flex-1 flex items-center justify-center py-3 bg-orange-600 hover:bg-orange-500 text-white transition-colors font-bold uppercase tracking-widest">
                <User className="w-5 h-5 mr-2" /> Login
              </Link>
            </div>
          </nav>
        </div>
      )}
    </header>
  )
}
