"use client";

import { createContext, useContext, useEffect, useState, useCallback } from "react";
import { onAuthStateChanged, User } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useRouter, usePathname } from "next/navigation";
import { toast } from "sonner";

interface WishlistContextType {
    wishlist: string[];
    toggleWishlist: (productId: string) => void;
    removeFromWishlist: (productId: string) => void;
    clearWishlist: () => void;
    isInWishlist: (productId: string) => boolean;
    wishlistCount: number;
    user: User | null;
}

const WishlistContext = createContext<WishlistContextType>({
    wishlist: [],
    toggleWishlist: () => {},
    removeFromWishlist: () => {},
    clearWishlist: () => {},
    isInWishlist: () => false,
    wishlistCount: 0,
    user: null,
});

export function useWishlist() {
    return useContext(WishlistContext);
}

const STORAGE_KEY = "sz-wishlist";

export default function WishlistProvider({ children }: { children: React.ReactNode }) {
    const [wishlist, setWishlist] = useState<string[]>([]);
    const [user, setUser] = useState<User | null>(null);
    const [mounted, setMounted] = useState(false);
    const router = useRouter();
    const pathname = usePathname();

    // Listen to Firebase Auth state
    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (firebaseUser) => {
            setUser(firebaseUser);
            if (firebaseUser) {
                // Load wishlist for this user
                const key = `${STORAGE_KEY}-${firebaseUser.uid}`;
                const saved = localStorage.getItem(key);
                if (saved) {
                    try {
                        setWishlist(JSON.parse(saved));
                    } catch {
                        setWishlist([]);
                    }
                } else {
                    setWishlist([]);
                }
            } else {
                // User logged out — clear wishlist state
                setWishlist([]);
            }
        });
        setMounted(true);
        return () => unsubscribe();
    }, []);

    // Persist wishlist to localStorage when it changes
    useEffect(() => {
        if (!mounted || !user) return;
        const key = `${STORAGE_KEY}-${user.uid}`;
        localStorage.setItem(key, JSON.stringify(wishlist));
    }, [wishlist, user, mounted]);

    const toggleWishlist = useCallback(
        (productId: string) => {
            if (!user) {
                router.push(`/dang-nhap?redirect=${encodeURIComponent(pathname)}`);
                return;
            }
            const isAdding = !wishlist.includes(productId);
            setWishlist((prev) =>
                prev.includes(productId)
                    ? prev.filter((id) => id !== productId)
                    : [...prev, productId]
            );
            if (isAdding) {
                toast.success("Đã thêm vào danh sách yêu thích ♥");
            } else {
                toast("Đã xoá khỏi danh sách yêu thích");
            }
        },
        [user, router]
    );

    const removeFromWishlist = useCallback(
        (productId: string) => {
            if (!user) return;
            setWishlist((prev) => prev.filter((id) => id !== productId));
            toast("Đã xoá khỏi danh sách yêu thích");
        },
        [user]
    );

    const clearWishlist = useCallback(() => {
        setWishlist([]);
    }, []);

    const isInWishlist = useCallback(
        (productId: string) => wishlist.includes(productId),
        [wishlist]
    );

    if (!mounted) return null;

    return (
        <WishlistContext.Provider
            value={{
                wishlist,
                toggleWishlist,
                removeFromWishlist,
                clearWishlist,
                isInWishlist,
                wishlistCount: wishlist.length,
                user,
            }}
        >
            {children}
        </WishlistContext.Provider>
    );
}
