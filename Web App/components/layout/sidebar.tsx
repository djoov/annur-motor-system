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
  Database, Upload, MapPin, Archive, History, ChevronDown, ChevronRight, Layers, UserCircle
} from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

// Navigation Structure
const navigation = [
  {
    section: "Menu Utama",
    items: [
      { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
      { name: "Kasir (POS)", href: "/pos", icon: ShoppingCart },
    ]
  },
  {
    section: "Manajemen Data",
    items: [
      {
        name: "Master Data",
        icon: Database,
        href: "#", // Parent
        children: [
          { name: "Kategori", href: "/master/categories", icon: Layers },
          { name: "Barang", href: "/master/items", icon: Package },
          { name: "Stok Opname", href: "/master/stock", icon: Archive },
          { name: "Pelanggan", href: "/master/customers", icon: Users },
          { name: "Supplier", href: "/master/suppliers", icon: Truck },
          { name: "Pembelian", href: "/master/purchases", icon: ShoppingCart }, // Reused ShoppingCart or a better one
          { name: "Import Data", href: "/master/import", icon: Upload },
        ],
      },
    ]
  },
  {
    section: "Analisa & Laporan",
    items: [
      {
        name: "Laporan",
        icon: BarChart3,
        href: "#",
        children: [
          { name: "Penjualan Harian", href: "/reports/daily-sales", icon: FileText },
          { name: "Per Kategori", href: "/reports/category-sales", icon: Layers },
          { name: "Top Selling", href: "/reports/top-selling", icon: BarChart3 },
          { name: "Riwayat Transaksi", href: "/reports/transactions", icon: History },
          { name: "Profit / Rugi", href: "/reports/profit", icon: FileText },
          { name: "Peta Pengunjung", href: "/reports/visitor-map", icon: MapPin },
          { name: "Arus Stok", href: "/reports/movement-history", icon: Archive },
        ],
      },
    ]
  },
  {
    section: "Sistem",
    items: [
      { name: "Pengaturan", href: "/settings", icon: Settings },
    ]
  }
];

export function Sidebar() {
  const [isOpen, setIsOpen] = useState(false);
  // Default expanded sections for easier navigation
  const [expandedItems, setExpandedItems] = useState<string[]>(["Master Data", "Laporan"]);
  const pathname = usePathname();
  const { user, logout } = useAuth();

  const toggleExpanded = (name: string) => {
    setExpandedItems((prev) => (prev.includes(name) ? prev.filter((item) => item !== name) : [...prev, name]));
  };

  // Safe check for active link to auto-expand parents
  // (Optional improvement logic could go here)

  const NavItem = ({ item, isChild = false }: { item: any; isChild?: boolean }) => {
    const isActive = pathname === item.href;
    const isExpanded = expandedItems.includes(item.name);
    const hasChildren = item.children && item.children.length > 0;
    const Icon = item.icon;

    if (hasChildren) {
      return (
        <div className="mb-1">
          <button
            onClick={() => toggleExpanded(item.name)}
            className={cn(
              "w-full flex items-center justify-between px-3 py-2.5 text-sm font-medium rounded-lg transition-all duration-200",
              isExpanded
                ? "bg-slate-100 text-slate-800"
                : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
            )}
          >
            <div className="flex items-center">
              <Icon className={cn("mr-3 h-4.5 w-4.5", isExpanded ? "text-indigo-600" : "text-slate-400")} />
              {item.name}
            </div>
            {isExpanded ? <ChevronDown className="h-4 w-4 text-slate-400" /> : <ChevronRight className="h-4 w-4 text-slate-400" />}
          </button>

          <div className={cn(
            "overflow-hidden transition-all duration-300 ease-in-out pl-4 space-y-0.5",
            isExpanded ? "max-h-[500px] opacity-100 mt-1" : "max-h-0 opacity-0"
          )}>
            <div className="border-l-2 border-slate-100 pl-2">
              {item.children.map((child: any) => (
                <NavItem key={child.name} item={child} isChild={true} />
              ))}
            </div>
          </div>
        </div>
      );
    }

    return (
      <Link
        href={item.href}
        onClick={() => setIsOpen(false)}
        className={cn(
          "flex items-center px-3 py-2.5 text-sm font-medium rounded-lg transition-all duration-200 mb-0.5",
          isActive
            ? "bg-indigo-50 text-indigo-700 shadow-sm ring-1 ring-indigo-200/50"
            : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
        )}
      >
        <Icon className={cn("mr-3 h-4.5 w-4.5", isActive ? "text-indigo-600" : "text-slate-400 group-hover:text-indigo-500")} />
        {item.name}
      </Link>
    );
  };

  // Get Initials for Avatar
  const getInitials = (name: string) => name?.substring(0, 2).toUpperCase() || "AM";

  return (
    <>
      {/* Mobile Trigger */}
      <div className="lg:hidden fixed top-4 left-4 z-50">
        <Button variant="outline" size="icon" className="shadow-md bg-white border-indigo-100 text-indigo-700" onClick={() => setIsOpen(!isOpen)}>
          {isOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
        </Button>
      </div>

      {/* Sidebar Container */}
      <aside className={cn(
        "fixed inset-y-0 left-0 z-40 w-72 bg-white border-r border-slate-200 transform transition-transform duration-300 ease-in-out lg:translate-x-0 flex flex-col shadow-[4px_0_24px_-4px_rgba(0,0,0,0.02)]",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}>

        {/* Helper Overlay for Mobile */}
        {isOpen && <div className="fixed inset-0 z-[-1] bg-black/20 backdrop-blur-sm lg:hidden" onClick={() => setIsOpen(false)} />}

        {/* 1. Header / Logo */}
        <div className="h-16 flex items-center px-6 border-b border-slate-100 bg-gradient-to-r from-white to-slate-50">
          <div className="flex items-center gap-3">
            <div className="relative flex items-center justify-center w-8 h-8 bg-indigo-600 rounded-lg shadow-lg shadow-indigo-200 text-white">
              <Bike className="h-5 w-5" />
              <div className="absolute -bottom-1 -right-1 bg-orange-500 rounded-full p-0.5 border-2 border-white">
                <Wrench className="h-2 w-2 text-white" />
              </div>
            </div>
            <div>
              <h1 className="text-sm font-black text-slate-800 tracking-tight leading-none">ANNUR MOTOR</h1>
              <p className="text-[10px] font-medium text-slate-500 tracking-wide uppercase mt-0.5">System v2.0</p>
            </div>
          </div>
        </div>

        {/* 2. Scrollable Navigation */}
        <div className="flex-1 overflow-y-auto px-4 py-4 custom-scrollbar space-y-6">
          {navigation.map((group, idx) => (
            <div key={idx}>
              {group.section && (
                <h3 className="px-3 text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">
                  {group.section}
                </h3>
              )}
              <div className="space-y-0.5">
                {group.items.map((item) => (
                  <NavItem key={item.name} item={item} />
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* 3. Footer / User Profile */}
        <div className="p-4 border-t border-slate-100 bg-slate-50/50">
          <div className="flex items-center gap-3 p-2 rounded-xl bg-white border border-slate-200 shadow-sm mb-3">
            <Avatar className="h-9 w-9 border border-indigo-100">
              <AvatarFallback className="bg-indigo-50 text-indigo-600 font-bold text-xs">{getInitials(user?.name || "Admin")}</AvatarFallback>
            </Avatar>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-bold text-slate-800 truncate">{user?.name || "Administrator"}</p>
              <p className="text-[10px] text-slate-500 capitalize flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-green-500 inline-block" />
                {user?.role || "Super Admin"}
              </p>
            </div>
          </div>

          <Button
            variant="outline"
            className="w-full text-red-600 border-red-100 hover:bg-red-50 hover:text-red-700 hover:border-red-200 transition-colors h-9 text-xs font-medium"
            onClick={logout}
          >
            <LogOut className="mr-2 h-3.5 w-3.5" />
            Keluar Sistem
          </Button>
        </div>

      </aside>
    </>
  );
}
