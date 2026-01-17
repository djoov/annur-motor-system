"use client"

import type React from "react"
import { createContext, useContext, useState, useEffect } from "react"
import { useRouter, usePathname } from "next/navigation"
import { useToast } from "@/hooks/use-toast" // <-- Gunakan useToast yang sudah ada

import { auth, db } from "@/lib/firebase"
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  User as FirebaseUser,
  GoogleAuthProvider,
  signInWithPopup,
  setPersistence,
  browserSessionPersistence,
  browserLocalPersistence
} from "firebase/auth"
import { doc, getDoc, setDoc, serverTimestamp } from "firebase/firestore"

interface User {
  id: string
  email: string | null
  role: "admin" | "staff"
  name: string
}

interface AuthContextType {
  login: (email: string, password: string, rememberMe: boolean) => Promise<boolean>
  loginWithGoogle: () => Promise<boolean>
  logout: () => void
  user: User | null
  isLoading: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()
  const pathname = usePathname()
  const { toast } = useToast() // <-- Panggil hook di sini

  const publicPaths = ['/', '/katalog', '/oli'];

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser: FirebaseUser | null) => {
      if (firebaseUser) {
        const userDocRef = doc(db, "users", firebaseUser.uid);
        const userDoc = await getDoc(userDocRef);

        if (userDoc.exists()) {
          const userData = userDoc.data();
          setUser({
            id: firebaseUser.uid,
            email: firebaseUser.email,
            name: userData.name || firebaseUser.displayName || "Pengguna Baru",
            role: userData.role || "staff"
          });
        } else {
          const newUserData = {
            name: firebaseUser.displayName || "Pengguna Baru",
            email: firebaseUser.email,
            role: "staff",
            createdAt: serverTimestamp()
          };
          await setDoc(userDocRef, newUserData);
          setUser({
            id: firebaseUser.uid,
            email: firebaseUser.email,
            name: newUserData.name,
            role: newUserData.role as "admin" | "staff"
          });
        }
      } else {
        setUser(null)
      }
      setIsLoading(false)
    })

    return () => unsubscribe()
  }, [])

  useEffect(() => {
    if (isLoading) return;
    const isPublicPath = publicPaths.includes(pathname);
    if (user && pathname === '/login') {
      router.push('/dashboard');
    }
    if (!user && !isPublicPath && pathname !== '/login') {
      router.push('/login');
    }
  }, [user, isLoading, pathname, router]);

  const login = async (email: string, password: string, rememberMe: boolean): Promise<boolean> => {
    try {
      const persistence = rememberMe ? browserLocalPersistence : browserSessionPersistence;
      await setPersistence(auth, persistence);
      await signInWithEmailAndPassword(auth, email, password);
      return true
    } catch (error) {
      console.error("Login Gagal:", error);
      // --- [DIPERBAIKI] Gunakan toast yang benar ---
      toast({
        title: "Login Gagal",
        description: "Periksa email dan kata sandi Anda.",
        variant: "destructive"
      });
      return false
    }
  }

  const loginWithGoogle = async (): Promise<boolean> => {
    try {
      await setPersistence(auth, browserLocalPersistence);
      const provider = new GoogleAuthProvider();
      await signInWithPopup(auth, provider);
      return true;
    } catch (error) {
      console.error("Google Login Gagal:", error);
      toast({
        title: "Login dengan Google Gagal",
        description: "Silakan coba lagi.",
        variant: "destructive"
      });
      return false;
    }
  };

  const logout = async () => {
    await signOut(auth)
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return <AuthContext.Provider value={{ user, login, loginWithGoogle, logout, isLoading }}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider")
  }
  return context
}