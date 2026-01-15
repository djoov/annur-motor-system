"use client"

import type React from "react"
import { useState } from "react"
import Link from "next/link"
import Image from "next/image" // Import Image
import { useAuth } from "@/components/auth-provider"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Checkbox } from "@/components/ui/checkbox"
import { ArrowLeft, Loader2, Eye, EyeOff } from "lucide-react"
import { FcGoogle } from "react-icons/fc";

export default function LoginPage() {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [rememberMe, setRememberMe] = useState(true)
  const [error, setError] = useState("")
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const { login, loginWithGoogle } = useAuth()

  const handleEmailSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")
    setIsLoggingIn(true);
    const success = await login(email, password, rememberMe);
    if (!success) setError("Email atau password salah.");
    setIsLoggingIn(false);
  }

  const handleGoogleLogin = async () => {
    setError("");
    setIsLoggingIn(true);
    const success = await loginWithGoogle();
    if (!success) setError("Gagal login dengan Google.");
    setIsLoggingIn(false);
  };

  const togglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden bg-slate-950">
      {/* --- Background Elements --- */}
      <div className="absolute inset-0 z-0">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-blue-900/40 via-slate-950/90 to-slate-950 z-10" />
        <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-10 z-0 mix-blend-overlay"></div>
        <Image
          src="https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=1200&auto=format&fit=crop"
          alt="Background Bengkel"
          fill
          className="object-cover opacity-20"
          priority
        />
      </div>

      <div className="absolute top-8 left-8 z-20">
        <Link href="/" className="flex items-center text-slate-400 hover:text-white transition-colors group">
          <div className="bg-white/10 p-2 rounded-full backdrop-blur-sm group-hover:bg-white/20 transition-colors mr-2">
            <ArrowLeft className="h-5 w-5" />
          </div>
          <span className="font-medium">Kembali ke Beranda</span>
        </Link>
      </div>

      <Card className="w-full max-w-md relative z-20 border-white/10 bg-white/5 backdrop-blur-xl shadow-2xl animate-fade-in-up">
        <CardHeader className="text-center pb-2">
          <div className="flex items-center justify-center mb-6">
            <div className="relative w-20 h-20 bg-white/10 rounded-2xl p-2 shadow-inner ring-1 ring-white/20">
              <Image
                src="/logo.png"
                alt="Annur Motor Logo"
                fill
                className="object-contain p-2 hover:scale-110 transition-transform duration-500"
              />
            </div>
          </div>
          <CardTitle className="text-3xl font-bold text-white tracking-tight">Selamat Datang</CardTitle>
          <CardDescription className="text-slate-400 text-base mt-2">Masuk untuk mengakses dashboard</CardDescription>
        </CardHeader>
        <CardContent className="pt-6">
          <form onSubmit={handleEmailSubmit} className="space-y-5">
            <div className="space-y-2">
              <Label htmlFor="email" className="text-slate-300">Email</Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nama@email.com"
                required
                className="bg-white/5 border-white/10 text-white placeholder:text-slate-600 focus:border-blue-500 focus:ring-blue-500/20"
              />
            </div>
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="password" className="text-slate-300">Password</Label>
                <a href="#" className="text-xs text-blue-400 hover:text-blue-300">Lupa password?</a>
              </div>

              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="bg-white/5 border-white/10 text-white placeholder:text-slate-600 focus:border-blue-500 focus:ring-blue-500/20 pr-10"
                />
                <button type="button" onClick={togglePasswordVisibility} className="absolute inset-y-0 right-0 flex items-center px-3 text-slate-500 hover:text-slate-300 transition-colors" tabIndex={-1}>
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            <div className="flex items-center space-x-2">
              <Checkbox
                id="remember-me"
                checked={rememberMe}
                onCheckedChange={(checked) => setRememberMe(checked as boolean)}
                className="border-slate-600 data-[state=checked]:bg-blue-600 data-[state=checked]:border-blue-600"
              />
              <label htmlFor="remember-me" className="text-sm font-medium leading-none text-slate-400 cursor-pointer">
                Ingat Saya
              </label>
            </div>

            {error && (
              <Alert variant="destructive" className="bg-red-900/50 border-red-900/50 text-red-200">
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}

            <Button type="submit" className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-5 shadow-lg shadow-blue-900/20 transition-all duration-300" disabled={isLoggingIn}>
              {isLoggingIn ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" /> Memproses...</> : 'Masuk sekarang'}
            </Button>
          </form>

          <div className="relative my-8">
            <div className="absolute inset-0 flex items-center"><span className="w-full border-t border-white/10" /></div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-slate-900/50 px-2 text-slate-500 backdrop-blur-sm">Atau</span>
            </div>
          </div>

          <Button variant="outline" className="w-full bg-white text-slate-900 hover:bg-slate-200 border-none font-medium h-12" onClick={handleGoogleLogin} disabled={isLoggingIn}>
            <FcGoogle className="mr-2 h-5 w-5" />
            Lanjutkan dengan Google
          </Button>
        </CardContent>
      </Card>

      <div className="absolute bottom-6 text-center text-slate-600 text-xs">
        &copy; {new Date().getFullYear()} Annur Motor. All Rights Reserved.
      </div>
    </div>
  )
}
