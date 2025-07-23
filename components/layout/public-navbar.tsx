"use client"

import Link from "next/link"
import { Bike, Wrench, LogIn } from "lucide-react"
import { Button } from "@/components/ui/button"

export function PublicNavbar() {
  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-white shadow-md">
      <div className="container mx-auto px-4 py-3 flex justify-between items-center">
        <Link href="/" className="flex items-center space-x-2">
            <div className="relative">
                <Bike className="h-8 w-8 text-blue-600" />
                <Wrench className="h-4 w-4 text-orange-500 absolute -bottom-1 -right-1" />
            </div>
            <span className="text-xl font-bold text-blue-600">ANNUR MOTOR</span>
        </Link>
        <nav className="hidden md:flex items-center space-x-6">
          <a href="#layanan" className="text-gray-600 hover:text-blue-600 transition-colors">Layanan</a>
          <a href="#produk" className="text-gray-600 hover:text-blue-600 transition-colors">Produk</a>
          <a href="#lokasi" className="text-gray-600 hover:text-blue-600 transition-colors">Lokasi</a>
        </nav>
        <Link href="/login">
          <Button variant="outline">
            <LogIn className="mr-2 h-4 w-4" />
            Login Staf
          </Button>
        </Link>
      </div>
    </header>
  )
}
