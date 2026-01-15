import { useState, useMemo } from 'react';
import { Item, CartItem } from '@/types';
import { useToast } from "@/hooks/use-toast";
import { db } from "@/lib/firebase";
import { collection, doc, writeBatch, serverTimestamp, increment } from "firebase/firestore";

export function usePos() {
    const { toast } = useToast();
    const [cart, setCart] = useState<CartItem[]>([]);
    const [isProcessing, setIsProcessing] = useState(false);
    const [lastTransaction, setLastTransaction] = useState<any>(null); // To store receipt data

    // Add Item to Cart
    const addToCart = (item: Item) => {
        setCart(prevCart => {
            const existingItem = prevCart.find(cartItem => cartItem.id === item.id);
            const currentQty = existingItem ? (existingItem.quantity || 0) : 0;
            const availableStock = (item.stockDisplay || 0) + (item.stockWarehouse || 0); // Check total stock available

            if (currentQty + 1 > availableStock) {
                toast({ title: "Stok Habis!", description: "Jumlah melebihi total stok yang tersedia.", variant: "destructive" });
                return prevCart;
            }

            if (existingItem) {
                return prevCart.map(cartItem =>
                    cartItem.id === item.id ? { ...cartItem, quantity: (cartItem.quantity || 0) + 1 } : cartItem
                );
            }
            return [...prevCart, { ...item, quantity: 1 }];
        });
    };

    // Update Quantity
    const updateQuantity = (itemId: string, newQuantity: number) => {
        if (newQuantity < 1) {
            removeFromCart(itemId);
            return;
        }

        setCart(prevCart => {
            return prevCart.map(item => {
                if (item.id === itemId) {
                    const availableStock = (item.stockDisplay || 0) + (item.stockWarehouse || 0);
                    if (newQuantity > availableStock) {
                        toast({ title: "Stok Habis!", description: "Jumlah melebihi total stok.", variant: "destructive" });
                        return item;
                    }
                    return { ...item, quantity: newQuantity };
                }
                return item;
            });
        });
    };

    // Remove Item
    const removeFromCart = (itemId: string) => {
        setCart(prevCart => prevCart.filter(item => item.id !== itemId));
    };

    // Clear Cart
    const clearCart = () => {
        setCart([]);
        setLastTransaction(null);
    }

    // Calculate Totals
    const cartSummary = useMemo(() => {
        const totalAmount = cart.reduce((sum, item) => sum + (item.sellPrice || 0) * (item.quantity || 0), 0);
        const totalProfit = cart.reduce((sum, item) => sum + ((item.sellPrice || 0) - (item.buyPrice || 0)) * (item.quantity || 0), 0);
        const totalItems = cart.reduce((sum, item) => sum + (item.quantity || 0), 0);
        return { totalAmount, totalProfit, totalItems };
    }, [cart]);

    // Checkout Logic
    const processCheckout = async (customerId: string, customerName: string, paymentMethod: 'cash' | 'transfer', amountPaid: number) => {
        if (cart.length === 0) return false;

        setIsProcessing(true);
        try {
            const batch = writeBatch(db);
            const transactionRef = doc(collection(db, "transactions"));

            // Transaction Data
            const transactionData = {
                transactionDate: serverTimestamp(),
                customerId,
                customerName,
                totalAmount: cartSummary.totalAmount,
                totalProfit: cartSummary.totalProfit,
                items: cart.map(item => ({
                    itemId: item.id,
                    itemName: item.name || 'Unknown',
                    category: item.category || 'Lain-lain',
                    quantity: item.quantity || 0,
                    sellPrice: item.sellPrice || 0,
                    buyPrice: item.buyPrice || 0,
                })),
                paymentMethod,
                amountPaid: paymentMethod === 'cash' ? amountPaid : cartSummary.totalAmount,
                change: paymentMethod === 'cash' ? (amountPaid - cartSummary.totalAmount) : 0,
                status: 'paid', // Default paid for POS
                type: 'sale'
            };

            batch.set(transactionRef, transactionData);

            // Update Stock
            for (const item of cart) {
                const itemRef = doc(db, "items", item.id);
                // Logic: Sync with Mobile App -> Only deduct from Display Stock (Shop)
                // Mobile App allows negative stock (deficits) on Display rather than complex warehouse deduction.

                const qtyToDeduct = item.quantity || 0;

                // Use FieldValue.increment for atomicity and consistency with Mobile
                batch.update(itemRef, {
                    stockDisplay: increment(-qtyToDeduct),
                    stock: increment(-qtyToDeduct), // Legacy field
                    qty_display: increment(-qtyToDeduct), // Sync mobile field
                    // qty_warehouse: item.stockWarehouse, // Do NOT touch warehouse stock
                    updatedAt: serverTimestamp()
                });
            }

            await batch.commit();

            toast({ title: "Transaksi Berhasil!", description: "Stok telah diperbarui." });
            return true;
        } catch (error) {
            console.error("Checkout Failed:", error);
            toast({ title: "Gagal Memproses", description: "Terjadi kesalahan sistem.", variant: "destructive" });
            return false;
        } finally {
            setIsProcessing(false);
        }
    };

    return {
        cart,
        addToCart,
        updateQuantity,
        removeFromCart,
        clearCart,
        cartSummary,
        processCheckout,
        isProcessing,
        lastTransaction,
        setLastTransaction
    };
}
