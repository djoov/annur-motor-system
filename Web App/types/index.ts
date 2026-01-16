export interface Item {
    id: string;
    code?: string;
    name: string;
    description?: string;
    category?: string;
    buyPrice: number;
    sellPrice: number;

    // Legacy stock field (kept for backward compatibility)
    stock: number;
    // Multi-warehouse stock fields
    stockDisplay: number; // qty_display
    stockWarehouse: number; // qty_warehouse

    minStock?: number;
    imageUrl?: string;
    barcode?: string;
    tags?: string[];
    createdAt?: any;
}

export interface Category {
    id: string;
    name: string;
}

export interface Customer {
    id: string;
    name: string;
}

export interface CartItem extends Item {
    quantity: number;
}

export interface TransactionItem {
    itemId: string;
    itemName: string;
    category?: string;
    quantity: number;
    sellPrice: number;
    buyPrice: number;
}

export interface Transaction {
    id?: string;
    transactionDate: any;
    customerId: string;
    customerName: string;
    totalAmount: number;
    totalProfit: number;
    items: TransactionItem[];

    // Extended fields for Mobile App compatibility
    type: 'sale' | 'return';
    paymentMethod: 'cash' | 'transfer' | 'tempo'; // cash, transfer, tempo (hutang)
    paymentStatus: 'paid' | 'unpaid' | 'partial';
    cashierName?: string;
    returnedItems?: Record<string, number>;
}

// Debt/Piutang interfaces (synced with Mobile App)
export interface DebtPaymentLog {
    date: any; // Timestamp
    amount: number;
    note: string;
}

export interface Debt {
    id: string;
    customerId: string;
    customerName: string;
    transactionId: string;
    totalAmount: number;
    remainingAmount: number;
    status: 'unpaid' | 'partial' | 'paid';
    createdAt: any;
    updatedAt: any;
    dueDate?: any;
    logs: DebtPaymentLog[];
}

