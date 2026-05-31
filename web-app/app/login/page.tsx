"use client"

import type React from "react"
import { useState } from "react"
import Link from "next/link"
import Image from "next/image"
import { useAuth } from "@/components/auth-provider"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Checkbox } from "@/components/ui/checkbox"
import { ArrowLeft, Loader2, Eye, EyeOff, Terminal, Zap } from "lucide-react"
import { FcGoogle } from "react-icons/fc"

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
    if (!success) setError("Akses ditolak: Kredensial tidak valid.");
    setIsLoggingIn(false);
  }

  const handleGoogleLogin = async () => {
    setError("");
    setIsLoggingIn(true);
    const success = await loginWithGoogle();
    if (!success) setError("Gagal melakukan otentikasi via Google.");
    setIsLoggingIn(false);
  };

  const togglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  return (
    <div className="min-h-screen flex items-center justify-center relative bg-black text-zinc-300 font-sans selection:bg-orange-500/30 selection:text-white">
      {/* --- Background Elements --- */}
      <div className="absolute inset-0 z-0 overflow-hidden">
        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.03)_1px,transparent_1px)] bg-[size:4rem_4rem]"></div>
        <div className="absolute top-0 right-0 w-[800px] h-full bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-orange-900/20 via-transparent to-transparent pointer-events-none"></div>
        <Image
          src="https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=1200&auto=format&fit=crop"
          alt="Engine Background"
          fill
          className="object-cover opacity-20 filter grayscale contrast-125 mix-blend-luminosity"
          priority
        />
        <div className="absolute inset-0 bg-black/60 z-10" />
      </div>

      <div className="absolute top-8 left-8 z-20">
        <Link href="/" className="inline-flex items-center gap-2 px-4 py-2 bg-zinc-900 border border-zinc-800 text-zinc-400 hover:text-orange-500 hover:border-orange-500 transition-colors font-mono text-xs tracking-widest uppercase">
          <ArrowLeft className="h-4 w-4" />
          Abort sequence
        </Link>
      </div>

      <div className="w-full max-w-md relative z-20 bg-zinc-950 border border-zinc-800 shadow-2xl animate-in fade-in zoom-in-95 duration-500">
        {/* Top Accent Line */}
        <div className="h-1 w-full bg-orange-600"></div>

        <div className="p-6 md:p-8">
          {/* Header */}
          <div className="mb-8 text-center">
            <div className="flex justify-center mb-6">
              <div className="relative w-16 h-16 filter grayscale contrast-200">
                <Image
                  src="/logo.png"
                  alt="Annur Motor Logo"
                  fill
                  className="object-contain"
                />
              </div>
            </div>
            <div className="inline-flex items-center gap-2 px-3 py-1 bg-zinc-900 border border-zinc-800 text-orange-500 font-mono text-[10px] mb-4 tracking-widest uppercase">
              <Terminal className="w-3 h-3" />
              SYSTEM AUTHENTICATION
            </div>
            <h1 className="text-2xl md:text-3xl font-black text-white uppercase tracking-tighter">Otorisasi Admin</h1>
          </div>

          {/* Form */}
          <form onSubmit={handleEmailSubmit} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="email" className="text-zinc-400 font-mono text-xs uppercase tracking-widest">Identitas (Email)</Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="NAMA@DOMAIN.COM"
                required
                className="bg-black border-zinc-800 text-white placeholder:text-zinc-700 h-14 rounded-none focus:border-orange-500 focus:ring-0 font-mono text-sm uppercase"
              />
            </div>
            
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="password" className="text-zinc-400 font-mono text-xs uppercase tracking-widest">Sandi Keamanan</Label>
              </div>

              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  className="bg-black border-zinc-800 text-white placeholder:text-zinc-700 h-14 rounded-none focus:border-orange-500 focus:ring-0 font-mono text-sm tracking-widest pr-12"
                />
                <button type="button" onClick={togglePasswordVisibility} className="absolute inset-y-0 right-0 flex items-center px-4 text-zinc-500 hover:text-orange-500 transition-colors" tabIndex={-1}>
                  {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                </button>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <Checkbox
                id="remember-me"
                checked={rememberMe}
                onCheckedChange={(checked) => setRememberMe(checked as boolean)}
                className="border-zinc-700 rounded-none w-5 h-5 data-[state=checked]:bg-orange-600 data-[state=checked]:border-orange-600"
              />
              <label htmlFor="remember-me" className="text-xs font-mono uppercase tracking-widest text-zinc-400 cursor-pointer">
                Pertahankan Sesi
              </label>
            </div>

            {error && (
              <Alert variant="destructive" className="bg-black border border-red-900/50 text-red-500 rounded-none">
                <AlertDescription className="font-mono text-xs tracking-widest uppercase">{error}</AlertDescription>
              </Alert>
            )}

            <Button 
              type="submit" 
              disabled={isLoggingIn}
              className="w-full bg-orange-600 hover:bg-orange-500 text-white font-black tracking-widest uppercase h-14 rounded-none transition-colors border border-orange-500 flex items-center justify-center gap-3 mt-4"
            >
              {isLoggingIn ? (
                <><Loader2 className="h-5 w-5 animate-spin" /> MENGOTENTIKASI...</>
              ) : (
                <><Zap className="h-5 w-5" /> INITIATE LOGIN</>
              )}
            </Button>
          </form>

          {/* Divider */}
          <div className="relative my-8">
            <div className="absolute inset-0 flex items-center"><span className="w-full border-t border-zinc-800" /></div>
            <div className="relative flex justify-center">
              <span className="bg-zinc-950 px-4 font-mono text-[10px] uppercase tracking-widest text-zinc-600">OVERRIDE PROTOCOL</span>
            </div>
          </div>

          {/* Google Login */}
          <Button 
            variant="outline" 
            onClick={handleGoogleLogin} 
            disabled={isLoggingIn}
            className="w-full bg-black hover:bg-zinc-900 border-zinc-800 text-zinc-300 font-bold uppercase tracking-widest h-14 rounded-none transition-colors flex items-center justify-center"
          >
            <FcGoogle className="mr-3 h-6 w-6" />
            Akses via Google
          </Button>

        </div>
      </div>

      <div className="absolute bottom-8 font-mono text-[10px] text-zinc-600 uppercase tracking-widest text-center w-full">
        ANNUR MOTOR SECURE SYSTEM v2.0
      </div>
    </div>
  )
}
