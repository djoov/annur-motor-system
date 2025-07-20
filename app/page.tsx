&quot;use client&quot;

import { useEffect } from "react"
import { useRouter } from "next/navigation"
import { useAuth } from "@/components/auth-provider"

export default function HomePage() {
const { user, isLoading } = useAuth()
const router = useRouter()

useEffect(() =\> {
if (\!isLoading) {
if (user) {
router.push("/dashboard")
} else {
router.push("/login")
}
}
}, [user, isLoading, router])

// Tampilkan layar loading yang jelas saat aplikasi memeriksa status login
return (
&lt;div className=&quot;flex items-center justify-center min-h-screen bg-gray-100&quot;&gt;
&lt;div className=&quot;text-center&quot;&gt;
&lt;div className=&quot;animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600 mx-auto&quot;&gt;&lt;/div&gt;
&lt;p className=&quot;mt-4 text-lg text-gray-700&quot;&gt;Memuat Aplikasi Annur Motor...&lt;/p&gt;
&lt;/div&gt;
&lt;/div&gt;
)
}