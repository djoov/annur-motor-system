"use client"

import type React from "react"

import { useAuth } from "@/components/auth-provider"
import { Sidebar } from "./sidebar"
import { useRouter } from "next/navigation"
import { useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Clock, Lock } from "lucide-react"

export function MainLayout({ children }: { children: React.ReactNode }) {
  const { user, isLoading, logout } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!isLoading && !user) {
      router.push("/login")
    }
  }, [user, isLoading, router])

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (!user) {
    return null
  }

  // New accounts stay 'pending' until an admin approves them (see firestore.rules).
  if (user.role === "pending") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50 p-6">
        <div className="max-w-sm text-center space-y-4">
          <Clock className="mx-auto h-12 w-12 text-slate-400" />
          <h1 className="text-xl font-bold text-slate-800">Menunggu persetujuan admin</h1>
          <p className="text-sm text-slate-500">
            Akun {user.email} sudah terdaftar. Minta admin menyetujuinya di aplikasi HP
            (Kelola Pengguna), lalu muat ulang halaman ini.
          </p>
          <Button variant="outline" onClick={logout}>Keluar</Button>
        </div>
      </div>
    )
  }

  // The web panel is the owner's monitoring tool; staff work in the mobile app.
  if (user.role !== "admin") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50 p-6">
        <div className="max-w-sm text-center space-y-4">
          <Lock className="mx-auto h-12 w-12 text-slate-400" />
          <h1 className="text-xl font-bold text-slate-800">Web khusus admin</h1>
          <p className="text-sm text-slate-500">
            Akun {user.email} adalah staff. Silakan gunakan aplikasi Annur Motor di HP.
          </p>
          <Button variant="outline" onClick={logout}>Keluar</Button>
        </div>
      </div>
    )
  }

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 lg:ml-72 overflow-auto">
        <div className="p-6 pt-16 lg:pt-6">{children}</div>
      </main>
    </div>
  )
}
