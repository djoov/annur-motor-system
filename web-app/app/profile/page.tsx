"use client"

import { useState, useEffect, useRef } from "react"
import { MainLayout } from "@/components/layout/main-layout"
import { useAuth } from "@/components/auth-provider"
import { db } from "@/lib/firebase"
import { doc, getDoc, updateDoc } from "firebase/firestore"
import { useToast } from "@/hooks/use-toast"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { User, Mail, Shield, Save, Camera, Trash2 } from "lucide-react"

interface UserProfile {
    name: string;
    email: string;
    role: "admin" | "staff";
    photoURL?: string;
}

export default function ProfilePage() {
    const { user, isLoading: isAuthLoading } = useAuth();
    const { toast } = useToast();
    const [profile, setProfile] = useState<UserProfile | null>(null);
    const [isEditing, setIsEditing] = useState(false);
    const [isSaving, setIsSaving] = useState(false);
    
    const [imageBase64, setImageBase64] = useState<string | null>(null);
    const [isPhotoRemoved, setIsPhotoRemoved] = useState(false); // <-- State baru untuk menandai foto dihapus
    const fileInputRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        const fetchProfile = async () => {
            if (user?.id) {
                const userDocRef = doc(db, "users", user.id);
                const userDoc = await getDoc(userDocRef);
                if (userDoc.exists()) {
                    setProfile(userDoc.data() as UserProfile);
                }
            }
        };

        if (!isAuthLoading) {
            fetchProfile();
        }
    }, [user, isAuthLoading]);

    const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (file) {
            if (!file.type.startsWith("image/")) {
                toast({ title: "File tidak valid", description: "Silakan pilih file gambar.", variant: "destructive" });
                return;
            }
            if (file.size > 500 * 1024) { 
                toast({ title: "Ukuran file terlalu besar", description: "Maksimal ukuran gambar adalah 500KB.", variant: "destructive" });
                return;
            }

            const reader = new FileReader();
            reader.onloadend = () => {
                setImageBase64(reader.result as string);
                setIsPhotoRemoved(false); // Jika upload baru, batalkan status hapus
                if (!isEditing) setIsEditing(true);
            };
            reader.readAsDataURL(file);
        }
    };

    // --- [BARU] Fungsi untuk menghapus foto profil ---
    const handleRemovePhoto = () => {
        setIsPhotoRemoved(true);
        setImageBase64(null); // Hapus preview jika ada
        if (!isEditing) setIsEditing(true); // Otomatis masuk mode edit
    };

    const handleSave = async () => {
        if (!user?.id || !profile) return;
        setIsSaving(true);
        
        let newPhotoURL;
        if (isPhotoRemoved) {
            newPhotoURL = null; // Set ke null jika foto dihapus
        } else {
            newPhotoURL = imageBase64 || profile.photoURL;
        }

        try {
            const userDocRef = doc(db, "users", user.id);
            await updateDoc(userDocRef, {
                name: profile.name,
                role: profile.role,
                photoURL: newPhotoURL,
            });
            toast({ title: "Profil Berhasil Diperbarui" });
            setIsEditing(false);
            setImageBase64(null);
            setIsPhotoRemoved(false);
            window.location.reload(); 
        } catch (error) {
            console.error("Error updating profile: ", error);
            toast({ title: "Gagal Memperbarui Profil", variant: "destructive" });
        } finally {
            setIsSaving(false);
        }
    };
    
    if (isAuthLoading || !profile) {
        return <MainLayout><p className="text-center mt-10">Memuat profil...</p></MainLayout>;
    }

    const currentPhoto = isPhotoRemoved ? null : imageBase64 || profile.photoURL;

    return (
        <MainLayout>
            <div className="max-w-2xl mx-auto">
                <div className="text-center mb-6">
                    <h1 className="text-3xl font-bold text-gray-900">Profil Pengguna</h1>
                    <p className="text-gray-600">Lihat dan kelola detail profil Anda.</p>
                </div>

                <Card>
                    <CardHeader>
                        <div className="flex flex-col items-center space-y-4">
                            <div className="relative group">
                                <Avatar className="h-24 w-24">
                                    <AvatarImage src={currentPhoto || undefined} alt={profile.name} />
                                    <AvatarFallback className="text-4xl">
                                        {profile.name?.charAt(0).toUpperCase()}
                                    </AvatarFallback>
                                </Avatar>
                                <div 
                                    className="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center rounded-full opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
                                    onClick={() => fileInputRef.current?.click()}
                                >
                                    <Camera className="text-white h-8 w-8"/>
                                </div>
                                <input 
                                    type="file" 
                                    ref={fileInputRef} 
                                    className="hidden" 
                                    onChange={handleFileChange}
                                    accept="image/*"
                                />
                            </div>
                            {/* --- [BARU] Tombol Hapus Foto --- */}
                            {isEditing && currentPhoto && (
                                <Button variant="link" size="sm" className="text-red-500" onClick={handleRemovePhoto}>
                                    <Trash2 className="mr-2 h-4 w-4"/> Hapus Foto
                                </Button>
                            )}
                            <div>
                                <CardTitle className="text-2xl text-center">{profile.name}</CardTitle>
                                <CardDescription className="capitalize text-center">{profile.role}</CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="name" className="flex items-center gap-2"><User size={16}/> Nama Pengguna</Label>
                            <Input id="name" value={profile.name} onChange={(e) => setProfile({...profile, name: e.target.value})} disabled={!isEditing || isSaving}/>
                        </div>
                         <div className="space-y-2">
                            <Label htmlFor="email" className="flex items-center gap-2"><Mail size={16}/> Alamat Email</Label>
                            <Input id="email" value={profile.email} disabled className="bg-gray-100"/>
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="role" className="flex items-center gap-2"><Shield size={16}/> Hak Akses (Role)</Label>
                            <Select value={profile.role} onValueChange={(value) => setProfile({...profile, role: value as "admin" | "staff"})} disabled={user?.role !== 'admin' || !isEditing || isSaving}>
                                <SelectTrigger className={user?.role !== 'admin' ? "bg-gray-100" : ""}>
                                    <SelectValue />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="admin">Admin</SelectItem>
                                    <SelectItem value="staff">Staff</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>

                        <div className="flex justify-end space-x-2 pt-4">
                            {isEditing ? (
                                <>
                                <Button variant="outline" onClick={() => {setIsEditing(false); setImageBase64(null); setIsPhotoRemoved(false);}} disabled={isSaving}>Batal</Button>
                                <Button onClick={handleSave} disabled={isSaving}>
                                    <Save className="mr-2 h-4 w-4"/>
                                    {isSaving ? "Menyimpan..." : "Simpan Perubahan"}
                                </Button>
                                </>
                            ) : (
                                <Button onClick={() => setIsEditing(true)}>Edit Profil</Button>
                            )}
                        </div>
                    </CardContent>
                </Card>
            </div>
        </MainLayout>
    );
}
