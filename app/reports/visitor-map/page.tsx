"use client"

import { useState, useEffect } from 'react';
import { MainLayout } from '@/components/layout/main-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { db } from '@/lib/firebase';
import { collection, getDocs, query, orderBy } from 'firebase/firestore';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Fix untuk ikon default Leaflet yang rusak di React
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';

let DefaultIcon = L.icon({
    iconUrl: icon.src,
    shadowUrl: iconShadow.src,
    iconSize: [25, 41],
    iconAnchor: [12, 41]
});

L.Marker.prototype.options.icon = DefaultIcon;


interface LocationData {
    id: string;
    latitude: number;
    longitude: number;
    timestamp: any;
}

export default function VisitorMapPage() {
    const [locations, setLocations] = useState<LocationData[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        const fetchLocations = async () => {
            setIsLoading(true);
            try {
                const q = query(collection(db, "visitor_locations"), orderBy("timestamp", "desc"));
                const querySnapshot = await getDocs(q);
                const locationsList = querySnapshot.docs.map(doc => ({
                    id: doc.id,
                    ...doc.data()
                } as LocationData));
                setLocations(locationsList);
            } catch (error) {
                console.error("Gagal mengambil data lokasi:", error);
            } finally {
                setIsLoading(false);
            }
        };
        fetchLocations();
    }, []);

    return (
        <MainLayout>
            <div className="space-y-6">
                <Card>
                    <CardHeader>
                        <CardTitle>Peta Persebaran Pengunjung</CardTitle>
                        <CardDescription>
                            Menampilkan lokasi pengunjung yang mengizinkan akses. Total tercatat: {locations.length} pengunjung.
                        </CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="h-[60vh] w-full rounded-md overflow-hidden">
                            {isLoading ? (
                                <p>Memuat peta...</p>
                            ) : (
                                <MapContainer center={[-7.4189, 110.2545]} zoom={10} style={{ height: '100%', width: '100%' }}>
                                    <TileLayer
                                        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                                        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                                    />
                                    {locations.map(loc => (
                                        <Marker key={loc.id} position={[loc.latitude, loc.longitude]}>
                                            <Popup>
                                                Pengunjung tercatat pada: <br /> {loc.timestamp?.toDate().toLocaleString('id-ID')}
                                            </Popup>
                                        </Marker>
                                    ))}
                                </MapContainer>
                            )}
                        </div>
                    </CardContent>
                </Card>
            </div>
        </MainLayout>
    );
}
