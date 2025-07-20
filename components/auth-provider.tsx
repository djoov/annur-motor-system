"use client"

import type React from "react"
import { createContext, useContext, useState, useEffect } from "react"
import { useRouter, usePathname } from "next/navigation" // <-- Impor usePathname

import { auth, db } from "@/lib/firebase" 
import { 
  onAuthStateChanged, 
  signInWithEmailAndPassword, 
  signOut, 
  User as FirebaseUser,
  GoogleAuthProvider,
  signInWithPopup
} from "firebase/auth"
import { doc, getDoc, setDoc, serverTimestamp } from "firebase/firestore"

interface User {
  id: string
  email: string | null
  role: "admin" | "staff"
  name: string
}

interface AuthContextType {
  user: User | null
  login: (email: string, password: string) => Promise<boolean>
  loginWithGoogle: () => Promise<boolean>
  logout: () => void
  isLoading: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()
  const pathname = usePathname() // <-- Dapatkan path halaman saat ini

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
          console.log("User baru terdeteksi, membuat dokumen di Firestore...");
          const newUserData = {
            name: firebaseUser.displayName || "Pengguna Baru",
            email: firebaseUser.email,
            role: "staff",
            createdAt: serverTimestamp() // Gunakan serverTimestamp
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

  // --- [BARU] useEffect untuk menangani redirect secara terpusat ---
  useEffect(() => {
    // Jangan lakukan apa-apa jika masih loading
    if (isLoading) return;

    // Jika user sudah login dan masih berada di halaman login, arahkan ke dashboard
    if (user && pathname === '/login') {
      router.push('/dashboard');
    }

    // Jika user belum login dan mencoba mengakses halaman selain login, arahkan ke login
    if (!user && pathname !== '/login') {
      router.push('/login');
    }

  }, [user, isLoading, pathname, router]);


  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      await signInWithEmailAndPassword(auth, email, password);
      return true
    } catch (error) {
      console.error("Login Gagal:", error);
      return false
    }
  }

  const loginWithGoogle = async (): Promise<boolean> => {
    try {
      const provider = new GoogleAuthProvider();
      await signInWithPopup(auth, provider);
      return true;
    } catch (error) {
      console.error("Google Login Gagal:", error);
      return false;
    }
  };

  const logout = async () => {
    await signOut(auth)
    // Redirect setelah logout akan ditangani oleh useEffect di atas
  }

  // --- [DIUBAH] Kita tidak perlu lagi MainLayout dan page.tsx untuk redirect ---
  // Kita hanya tampilkan children jika loading sudah selesai
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