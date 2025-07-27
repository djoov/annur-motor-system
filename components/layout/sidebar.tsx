"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/components/auth-provider";
import { 
    LayoutDashboard, Package, Users, Truck, FileText, Settings, 
    LogOut, Menu, X, Bike, Wrench, ShoppingCart, BarChart3, 
    Database, Upload, MapPin, Archive, ScanLine, History // <-- [DIPERBAIKI] Menambahkan 'History'
} from "lucide-react";

const navigation = [
  { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { name: "Scan QR", href: "/scan", icon: ScanLine },
  { name: "Kasir (POS)", href: "/pos", icon: ShoppingCart },
  {
    name: "Master Data",
    icon: Database,
    children: [
      { name: "Kategori", href: "/master/categories", icon: Package },
      { name: "Barang", href: "/master/items", icon: ShoppingCart },
      { name: "Pelanggan", href: "/master/customers", icon: Users },
      { name: "Supplier", href: "/master/suppliers", icon: Truck },
      { name: "Stok Barang", href: "/master/stock", icon: Package },
      { name: "Pencatatan Pembelian", href: "/master/purchases", icon: Archive },
      { name: "Import CSV", href: "/master/import", icon: Upload },
    ],
  },
  {
    name: "Laporan",
    icon: BarChart3,
    children: [
      { name: "Penjualan Harian", href: "/reports/daily-sales", icon: FileText },
      { name: "Per Kategori", href: "/reports/category-sales", icon: FileText },
      { name: "Top Selling", href: "/reports/top-selling", icon: FileText },
      { name: "Transaksi", href: "/reports/transactions", icon: FileText },
      { name: "Keuntungan", href: "/reports/profit", icon: FileText },
      { name: "Peta Pengunjung", href: "/reports/visitor-map", icon: MapPin },
      { name: "Riwayat Pergerakan", href: "/reports/movement-history", icon: History },
    ],
  },
  { name: "Pengaturan", href: "/settings", icon: Settings },
];

export function Sidebar() {
  const [isOpen, setIsOpen] = useState(false);
  const [expandedItems, setExpandedItems] = useState<string[]>(["Master Data", "Laporan"]);
  const pathname = usePathname();
  const { user, logout } = useAuth();

  const toggleExpanded = (name: string) => {
    setExpandedItems((prev) => (prev.includes(name) ? prev.filter((item) => item !== name) : [...prev, name]));
  };

  const NavItem = ({ item, level = 0 }: { item: any; level?: number }) => {
    const isActive = pathname === item.href;
    const isExpanded = expandedItems.includes(item.name);
    const hasChildren = item.children && item.children.length > 0;

    const Icon = item.icon; // Variabel dengan huruf kapital

    return (
      <div>
        {hasChildren ? (
          <button onClick={() => toggleExpanded(item.name)} className={cn("w-full flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors", "hover:bg-blue-50 hover:text-blue-600", level > 0 && "ml-4")}>
            {/* --- [DIPERBAIKI] Menggunakan 'Icon' --- */}
            <Icon className="mr-3 h-4 w-4" />
            {item.name}
            <span className="ml-auto">{isExpanded ? "−" : "+"}</span>
          </button>
        ) : (
          <Link
            href={item.href}
            className={cn("flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors", isActive ? "bg-blue-100 text-blue-600" : "text-gray-600 hover:bg-blue-50 hover:text-blue-600", level > 0 && "ml-4")}
            onClick={() => setIsOpen(false)}
          >
            <Icon className="mr-3 h-4 w-4" />
            {item.name}
          </Link>
        )}
        {hasChildren && isExpanded && (
          <div className="mt-1 space-y-1">
            {item.children.map((child: any) => (
              <NavItem key={child.name} item={child} level={level + 1} />
            ))}
          </div>
        )}
      </div>
    );
  };

  return (
    <>
      {/* Mobile menu button */}
      <div className="lg:hidden fixed top-4 left-4 z-50">
        <Button variant="outline" size="icon" onClick={() => setIsOpen(!isOpen)}>
          {isOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
        </Button>
      </div>

      {/* Sidebar */}
      <div className={cn("fixed inset-y-0 left-0 z-40 w-64 bg-white border-r border-gray-200 transform transition-transform duration-300 ease-in-out lg:translate-x-0", isOpen ? "translate-x-0" : "-translate-x-full")}>
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="flex items-center px-6 py-4 border-b border-gray-200">
            <div className="flex items-center">
              <div className="relative">
                <Bike className="h-8 w-8 text-blue-600" />
                <Wrench className="h-4 w-4 text-orange-500 absolute -bottom-1 -right-1" />
              </div>
              <div className="ml-3">
                <h1 className="text-lg font-bold text-blue-600">ANNUR MOTOR</h1>
                <p className="text-xs text-gray-500">Sistem Manajemen</p>
              </div>
            </div>
          </div>

          {/* Navigation */}
          <nav className="flex-1 px-4 py-4 space-y-2 overflow-y-auto">
            {navigation.map((item) => (
              <NavItem key={item.name} item={item} />
            ))}
          </nav>

          {/* User info and logout */}
          <div className="border-t border-gray-200 p-4">
            <Link href="/profile" className="block hover:bg-gray-100 rounded-md p-2 mb-2">
              <div className="flex items-center">
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">{user?.name}</p>
                  <p className="text-xs text-gray-500 capitalize">{user?.role}</p>
                </div>
              </div>
            </Link>
            <Button variant="outline" size="sm" onClick={logout} className="w-full bg-transparent">
              <LogOut className="mr-2 h-4 w-4" />
              Keluar
            </Button>
          </div>
        </div>
      </div>

      {/* Overlay for mobile */}
      {isOpen && <div className="fixed inset-0 z-30 bg-black bg-opacity-50 lg:hidden" onClick={() => setIsOpen(false)} />}
    </>
  );
}
