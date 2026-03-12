"use client";

import { createContext, useContext, useEffect, useState, useCallback } from "react";
import { onAuthStateChanged, User } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useRouter, usePathname } from "next/navigation";

export interface CartItem {
    productId: string;
    name: string;
    image: string;
    price: number;
    salePrice: number;
    brandName: string;
    size: string;
    color: string;
    quantity: number;
}

interface CartContextType {
    cart: CartItem[];
    addToCart: (item: CartItem) => void;
    removeFromCart: (productId: string, size: string, color: string) => void;
    updateQuantity: (productId: string, size: string, color: string, quantity: number) => void;
    clearCart: () => void;
    cartCount: number;
    cartTotal: number;
    user: User | null;
}

const CartContext = createContext<CartContextType>({
    cart: [],
    addToCart: () => {},
    removeFromCart: () => {},
    updateQuantity: () => {},
    clearCart: () => {},
    cartCount: 0,
    cartTotal: 0,
    user: null,
});

export function useCart() {
    return useContext(CartContext);
}

const STORAGE_KEY = "sz-cart";

function getItemKey(item: { productId: string; size: string; color: string }) {
    return `${item.productId}-${item.size}-${item.color}`;
}

export default function CartProvider({ children }: { children: React.ReactNode }) {
    const [cart, setCart] = useState<CartItem[]>([]);
    const [user, setUser] = useState<User | null>(null);
    const [mounted, setMounted] = useState(false);
    const router = useRouter();
    const pathname = usePathname();

    // Listen to Firebase Auth state
    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (firebaseUser) => {
            setUser(firebaseUser);
            if (firebaseUser) {
                const key = `${STORAGE_KEY}-${firebaseUser.uid}`;
                const saved = localStorage.getItem(key);
                if (saved) {
                    try {
                        setCart(JSON.parse(saved));
                    } catch {
                        setCart([]);
                    }
                } else {
                    setCart([]);
                }
            } else {
                setCart([]);
            }
        });
        setMounted(true);
        return () => unsubscribe();
    }, []);

    // Persist cart to localStorage
    useEffect(() => {
        if (!mounted || !user) return;
        const key = `${STORAGE_KEY}-${user.uid}`;
        localStorage.setItem(key, JSON.stringify(cart));
    }, [cart, user, mounted]);

    const addToCart = useCallback(
        (item: CartItem) => {
            if (!user) {
                router.push(`/dang-nhap?redirect=${encodeURIComponent(pathname)}`);
                return;
            }
            setCart((prev) => {
                const existingIndex = prev.findIndex(
                    (i) => getItemKey(i) === getItemKey(item)
                );
                if (existingIndex >= 0) {
                    const updated = [...prev];
                    updated[existingIndex] = {
                        ...updated[existingIndex],
                        quantity: updated[existingIndex].quantity + item.quantity,
                    };
                    return updated;
                }
                return [...prev, item];
            });
        },
        [user, router]
    );

    const removeFromCart = useCallback(
        (productId: string, size: string, color: string) => {
            setCart((prev) =>
                prev.filter((i) => getItemKey(i) !== `${productId}-${size}-${color}`)
            );
        },
        []
    );

    const updateQuantity = useCallback(
        (productId: string, size: string, color: string, quantity: number) => {
            if (quantity < 1) return;
            setCart((prev) =>
                prev.map((i) =>
                    getItemKey(i) === `${productId}-${size}-${color}`
                        ? { ...i, quantity }
                        : i
                )
            );
        },
        []
    );

    const clearCart = useCallback(() => {
        setCart([]);
    }, []);

    const cartCount = cart.length;
    const cartTotal = cart.reduce((sum, i) => {
        const price = i.salePrice > 0 && i.salePrice < i.price ? i.salePrice : i.price;
        return sum + price * i.quantity;
    }, 0);

    if (!mounted) return null;

    return (
        <CartContext.Provider
            value={{
                cart,
                addToCart,
                removeFromCart,
                updateQuantity,
                clearCart,
                cartCount,
                cartTotal,
                user,
            }}
        >
            {children}
        </CartContext.Provider>
    );
}
