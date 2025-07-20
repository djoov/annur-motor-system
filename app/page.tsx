&quot;use client&quot;

import { useEffect } from "react"
import { useRouter } from "next/navigation"
import { useAuth } from "@/components/auth-provider"
import { MainLayout } from "@/components/layout/main-layout"

export default function HomePage() {
const { user, isLoading } = useAuth()
const router = useRouter()

useEffect(() =\> {
// Logika redirect tetap sama, tetapi sekarang ada UI di bawahnya
if (\!isLoading) {
if (user) {
router.push("/dashboard")
} else {
router.push("/login")
}
}
}, [user, isLoading, router])

// --- [DIUBAH] Tampilkan layar loading yang jelas ---
// Ini akan menjadi konten halaman utama saat situs di-build
// dan saat pengguna pertama kali membukanya.
return (
&lt;div className=&quot;flex items-center justify-center min-h-screen bg-gray-100&quot;&gt;
&lt;div className=&quot;text-center&quot;&gt;
&lt;div className=&quot;animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600 mx-auto&quot;&gt;&lt;/div&gt;
&lt;p className=&quot;mt-4 text-lg text-gray-700&quot;&gt;Memuat Aplikasi Annur Motor...&lt;/p&gt;
&lt;/div&gt;
&lt;/div&gt;
)
}