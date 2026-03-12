"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useTheme } from "@/components/ThemeProvider";
import { useWishlist } from "@/components/WishlistProvider";
import { useCart } from "@/components/CartProvider";
import { getProducts } from "@/lib/products";
import { getMaleCategories, getFemaleCategories } from "@/lib/categories";
import { Product, Category } from "@/lib/types";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { signOutUser } from "@/lib/auth";
import { toast } from "sonner";
import Image from "next/image";

const NAV_LINKS: { label: string; href: string; accent?: boolean; hasDropdown?: boolean }[] = [
    { label: "Trang Chủ", href: "/" },
    { label: "Sản Phẩm", href: "/san-pham", hasDropdown: true },
    { label: "Bộ Sưu Tập", href: "/bo-suu-tap" },
    { label: "Sale", href: "/sale", accent: true },
];

export default function Header() {
    const [isScrolled, setIsScrolled] = useState(false);
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
    const { theme, toggleTheme } = useTheme();
    const { wishlistCount } = useWishlist();
    const { cartCount } = useCart();
    const pathname = usePathname();
    const [isSearchOpen, setIsSearchOpen] = useState(false);
    const [searchQuery, setSearchQuery] = useState("");
    const [allProducts, setAllProducts] = useState<Product[]>([]);
    const [searchLoaded, setSearchLoaded] = useState(false);
    const searchInputRef = useRef<HTMLInputElement>(null);
    const [isLoggedIn, setIsLoggedIn] = useState(false);
    const [userPhotoURL, setUserPhotoURL] = useState<string | null>(null);
    const [userDisplayName, setUserDisplayName] = useState<string | null>(null);
    const [userEmail, setUserEmail] = useState<string | null>(null);
    const [isUserDropdownOpen, setIsUserDropdownOpen] = useState(false);
    const userDropdownRef = useRef<HTMLDivElement>(null);
    const router = useRouter();

    // Mega dropdown state
    const [isMegaOpen, setIsMegaOpen] = useState(false);
    const megaTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const megaDropdownRef = useRef<HTMLDivElement>(null);
    const [maleCategories, setMaleCategories] = useState<Category[]>([]);
    const [femaleCategories, setFemaleCategories] = useState<Category[]>([]);
    const [categoriesLoaded, setCategoriesLoaded] = useState(false);
    const [mobileProductsOpen, setMobileProductsOpen] = useState(false);

    // Track auth state for user icon
    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (user) => {
            setIsLoggedIn(!!user);
            setUserPhotoURL(user?.photoURL || null);
            setUserDisplayName(user?.displayName || null);
            setUserEmail(user?.email || null);
        });
        return () => unsubscribe();
    }, []);

    // Close user dropdown on click outside
    useEffect(() => {
        const handleClickOutside = (e: MouseEvent) => {
            if (userDropdownRef.current && !userDropdownRef.current.contains(e.target as Node)) {
                setIsUserDropdownOpen(false);
            }
        };
        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
    }, []);

    // Close dropdown on route change
    useEffect(() => {
        setIsUserDropdownOpen(false);
    }, [pathname]);

    // Track last visited shopping page for "Continue Shopping" link
    useEffect(() => {
        const shoppingPaths = ["/nam", "/nu", "/bo-suu-tap", "/sale"];
        if (shoppingPaths.some((p) => pathname.startsWith(p))) {
            localStorage.setItem("lastShoppingPage", pathname);
        }
    }, [pathname]);

    useEffect(() => {
        const handleScroll = () => {
            setIsScrolled(window.scrollY > 20);
        };
        window.addEventListener("scroll", handleScroll, { passive: true });
        return () => window.removeEventListener("scroll", handleScroll);
    }, []);

    // Lock body scroll when mobile menu is open
    useEffect(() => {
        document.body.style.overflow = isMobileMenuOpen ? "hidden" : "";
        return () => {
            document.body.style.overflow = "";
        };
    }, [isMobileMenuOpen]);

    // Fetch categories for mega dropdown
    useEffect(() => {
        if (categoriesLoaded) return;
        Promise.all([getMaleCategories(), getFemaleCategories()]).then(([male, female]) => {
            setMaleCategories(male.filter(c => !c.parentId || c.parentId === ""));
            setFemaleCategories(female.filter(c => !c.parentId || c.parentId === ""));
            setCategoriesLoaded(true);
        });
    }, [categoriesLoaded]);

    const handleMegaEnter = useCallback(() => {
        if (megaTimeoutRef.current) clearTimeout(megaTimeoutRef.current);
        setIsMegaOpen(true);
    }, []);

    const handleMegaLeave = useCallback(() => {
        megaTimeoutRef.current = setTimeout(() => setIsMegaOpen(false), 200);
    }, []);

    // Fetch products for search (lazy — only when search is opened)
    useEffect(() => {
        if (isSearchOpen && !searchLoaded) {
            getProducts(200).then((products) => {
                setAllProducts(products);
                setSearchLoaded(true);
            });
        }
        if (isSearchOpen) {
            document.body.style.overflow = "hidden";
            setTimeout(() => searchInputRef.current?.focus(), 100);
        } else {
            if (!isMobileMenuOpen) document.body.style.overflow = "";
            setSearchQuery("");
        }
    }, [isSearchOpen, searchLoaded, isMobileMenuOpen]);

    const searchResults = searchQuery.trim().length >= 1
        ? allProducts.filter((p) =>
            p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            p.brandName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            p.categoryName?.toLowerCase().includes(searchQuery.toLowerCase())
        ).slice(0, 8)
        : [];

    const isLight = theme === "light";

    return (
        <>
            <header
                className="header"
                style={{
                    position: "fixed",
                    top: 0,
                    left: 0,
                    right: 0,
                    zIndex: 1000,
                    height: "var(--header-height)",
                    display: "flex",
                    alignItems: "center",
                    transition: "all var(--transition-base)",
                    background: isScrolled
                        ? isLight
                            ? "rgba(255, 255, 255, 0.9)"
                            : "rgba(0, 0, 0, 0.9)"
                        : "transparent",
                    backdropFilter: isScrolled ? "blur(16px)" : "none",
                    WebkitBackdropFilter: isScrolled ? "blur(16px)" : "none",
                    borderBottom: isScrolled
                        ? "1px solid var(--border-color)"
                        : "1px solid transparent",
                }}
            >
                <div
                    className="container"
                    style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                    }}
                >
                    {/* Logo */}
                    <Link href="/" onClick={(e) => { if (pathname === "/") { e.preventDefault(); window.location.href = "/"; } }} style={{ textDecoration: "none" }}>
                        <div style={{ display: "flex", alignItems: "center", gap: "2px" }}>
                            <span
                                style={{
                                    fontSize: "1.5rem",
                                    fontWeight: 800,
                                    letterSpacing: "0.15em",
                                    color: "var(--logo-color)",
                                    textTransform: "uppercase",
                                }}
                            >
                                Style
                            </span>
                            <span
                                style={{
                                    fontSize: "1.5rem",
                                    fontWeight: 800,
                                    letterSpacing: "0.15em",
                                    color: "var(--color-accent)",
                                    textTransform: "uppercase",
                                }}
                            >
                                Zone
                            </span>
                        </div>
                    </Link>

                    <nav
                        style={{
                            display: "flex",
                            alignItems: "center",
                            gap: "var(--space-2xl)",
                            userSelect: "none",
                        }}
                        className="desktop-nav"
                    >
                        {NAV_LINKS.map((link) => {
                            const isActive =
                                link.href === "/"
                                    ? pathname === "/"
                                    : pathname.startsWith(link.href);

                            // Mega dropdown for "Sản Phẩm"
                            if (link.hasDropdown) {
                                return (
                                    <div
                                        key={link.href}
                                        ref={megaDropdownRef}
                                        style={{ position: "relative" }}
                                        onMouseEnter={handleMegaEnter}
                                        onMouseLeave={handleMegaLeave}
                                    >
                                        <span
                                            style={{
                                                fontSize: "0.875rem",
                                                fontWeight: 600,
                                                letterSpacing: "0.06em",
                                                textTransform: "uppercase",
                                                color: isMegaOpen || isActive
                                                    ? "var(--text-primary)"
                                                    : "var(--text-secondary)",
                                                transition: "color var(--transition-fast)",
                                                position: "relative",
                                                paddingBottom: "4px",
                                                cursor: "pointer",
                                                display: "inline-flex",
                                                alignItems: "center",
                                                gap: "4px",
                                            }}
                                        >
                                            {link.label}
                                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" style={{ transition: "transform 0.25s ease", transform: isMegaOpen ? "rotate(180deg)" : "rotate(0deg)" }}>
                                                <polyline points="6 9 12 15 18 9" />
                                            </svg>
                                            {isActive && (
                                                <span
                                                    style={{
                                                        position: "absolute",
                                                        bottom: 0,
                                                        left: "50%",
                                                        transform: "translateX(-50%)",
                                                        width: "70%",
                                                        height: "2px",
                                                        borderRadius: "1px",
                                                        background: "var(--color-accent)",
                                                    }}
                                                />
                                            )}
                                        </span>

                                        {/* Mega Dropdown Panel */}
                                        <div
                                            className="mega-dropdown"
                                            style={{
                                                position: "absolute",
                                                top: "calc(100% + 20px)",
                                                left: "50%",
                                                transform: "translateX(-50%)",
                                                width: "560px",
                                                background: "var(--bg-card)",
                                                border: "1px solid var(--border-color)",
                                                borderRadius: "var(--radius-lg)",
                                                boxShadow: "0 16px 48px rgba(0,0,0,0.4)",
                                                padding: 0,
                                                opacity: isMegaOpen ? 1 : 0,
                                                visibility: isMegaOpen ? "visible" : "hidden",
                                                transition: "opacity 0.2s ease, visibility 0.2s ease, transform 0.2s ease",
                                                zIndex: 100,
                                                overflow: "hidden",
                                            }}
                                        >
                                            {/* Invisible bridge to prevent gap */}
                                            <div style={{ position: "absolute", top: "-20px", left: 0, right: 0, height: "20px" }} />

                                            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr" }}>
                                                {/* Male Column */}
                                                <div style={{ padding: "var(--space-xl) var(--space-xl) var(--space-xl) var(--space-xl)", borderRight: "1px solid var(--border-color)" }}>
                                                    <Link
                                                        href="/nam"
                                                        onClick={() => setIsMegaOpen(false)}
                                                        style={{
                                                            display: "flex",
                                                            alignItems: "center",
                                                            gap: "var(--space-sm)",
                                                            fontSize: "0.8rem",
                                                            fontWeight: 700,
                                                            letterSpacing: "0.1em",
                                                            textTransform: "uppercase",
                                                            color: "var(--color-accent)",
                                                            marginBottom: "var(--space-lg)",
                                                            paddingBottom: "var(--space-sm)",
                                                            borderBottom: "1px solid rgba(139,92,246,0.15)",
                                                            textDecoration: "none",
                                                            transition: "opacity 0.2s",
                                                        }}
                                                        onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.8")}
                                                        onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
                                                    >
                                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>
                                                        Nam
                                                    </Link>
                                                    <div style={{ display: "flex", flexDirection: "column", gap: "2px" }}>
                                                        {maleCategories.map((cat) => (
                                                            <Link
                                                                key={cat.id}
                                                                href={`/nam?danh-muc=${cat.id}`}
                                                                onClick={() => setIsMegaOpen(false)}
                                                                style={{
                                                                    display: "block",
                                                                    padding: "8px 10px",
                                                                    borderRadius: "var(--radius-md)",
                                                                    fontSize: "0.88rem",
                                                                    color: "var(--text-secondary)",
                                                                    textDecoration: "none",
                                                                    transition: "all 0.15s ease",
                                                                }}
                                                                onMouseEnter={(e) => {
                                                                    e.currentTarget.style.color = "var(--text-primary)";
                                                                    e.currentTarget.style.background = "var(--bg-elevated)";
                                                                    e.currentTarget.style.paddingLeft = "14px";
                                                                }}
                                                                onMouseLeave={(e) => {
                                                                    e.currentTarget.style.color = "var(--text-secondary)";
                                                                    e.currentTarget.style.background = "transparent";
                                                                    e.currentTarget.style.paddingLeft = "10px";
                                                                }}
                                                            >
                                                                {cat.name}
                                                            </Link>
                                                        ))}
                                                        <Link
                                                            href="/nam"
                                                            onClick={() => setIsMegaOpen(false)}
                                                            style={{
                                                                display: "inline-flex",
                                                                alignItems: "center",
                                                                gap: "4px",
                                                                padding: "8px 10px",
                                                                marginTop: "var(--space-sm)",
                                                                fontSize: "0.8rem",
                                                                fontWeight: 600,
                                                                color: "var(--color-accent)",
                                                                textDecoration: "none",
                                                                transition: "opacity 0.2s",
                                                            }}
                                                            onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.7")}
                                                            onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
                                                        >
                                                            Xem tất cả →
                                                        </Link>
                                                    </div>
                                                </div>

                                                {/* Female Column */}
                                                <div style={{ padding: "var(--space-xl)" }}>
                                                    <Link
                                                        href="/nu"
                                                        onClick={() => setIsMegaOpen(false)}
                                                        style={{
                                                            display: "flex",
                                                            alignItems: "center",
                                                            gap: "var(--space-sm)",
                                                            fontSize: "0.8rem",
                                                            fontWeight: 700,
                                                            letterSpacing: "0.1em",
                                                            textTransform: "uppercase",
                                                            color: "var(--color-accent)",
                                                            marginBottom: "var(--space-lg)",
                                                            paddingBottom: "var(--space-sm)",
                                                            borderBottom: "1px solid rgba(139,92,246,0.15)",
                                                            textDecoration: "none",
                                                            transition: "opacity 0.2s",
                                                        }}
                                                        onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.8")}
                                                        onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
                                                    >
                                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>
                                                        Nữ
                                                    </Link>
                                                    <div style={{ display: "flex", flexDirection: "column", gap: "2px" }}>
                                                        {femaleCategories.map((cat) => (
                                                            <Link
                                                                key={cat.id}
                                                                href={`/nu?danh-muc=${cat.id}`}
                                                                onClick={() => setIsMegaOpen(false)}
                                                                style={{
                                                                    display: "block",
                                                                    padding: "8px 10px",
                                                                    borderRadius: "var(--radius-md)",
                                                                    fontSize: "0.88rem",
                                                                    color: "var(--text-secondary)",
                                                                    textDecoration: "none",
                                                                    transition: "all 0.15s ease",
                                                                }}
                                                                onMouseEnter={(e) => {
                                                                    e.currentTarget.style.color = "var(--text-primary)";
                                                                    e.currentTarget.style.background = "var(--bg-elevated)";
                                                                    e.currentTarget.style.paddingLeft = "14px";
                                                                }}
                                                                onMouseLeave={(e) => {
                                                                    e.currentTarget.style.color = "var(--text-secondary)";
                                                                    e.currentTarget.style.background = "transparent";
                                                                    e.currentTarget.style.paddingLeft = "10px";
                                                                }}
                                                            >
                                                                {cat.name}
                                                            </Link>
                                                        ))}
                                                        <Link
                                                            href="/nu"
                                                            onClick={() => setIsMegaOpen(false)}
                                                            style={{
                                                                display: "inline-flex",
                                                                alignItems: "center",
                                                                gap: "4px",
                                                                padding: "8px 10px",
                                                                marginTop: "var(--space-sm)",
                                                                fontSize: "0.8rem",
                                                                fontWeight: 600,
                                                                color: "var(--color-accent)",
                                                                textDecoration: "none",
                                                                transition: "opacity 0.2s",
                                                            }}
                                                            onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.7")}
                                                            onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
                                                        >
                                                            Xem tất cả →
                                                        </Link>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                );
                            }

                            return (
                                <Link
                                    key={link.href}
                                    href={link.href}
                                    onClick={(e) => {
                                        if (isActive) {
                                            e.preventDefault();
                                            window.location.href = link.href;
                                        }
                                    }}
                                    style={{
                                        fontSize: "0.875rem",
                                        fontWeight: 600,
                                        letterSpacing: "0.06em",
                                        textTransform: "uppercase",
                                        color: link.accent
                                            ? "var(--color-accent)"
                                            : isActive
                                                ? "var(--text-primary)"
                                                : "var(--text-secondary)",
                                        transition: "color var(--transition-fast)",
                                        position: "relative",
                                        paddingBottom: "4px",
                                    }}
                                    onMouseEnter={(e) =>
                                        (e.currentTarget.style.color = "var(--header-hover)")
                                    }
                                    onMouseLeave={(e) =>
                                    (e.currentTarget.style.color = link.accent
                                        ? "var(--color-accent)"
                                        : isActive
                                            ? "var(--text-primary)"
                                            : "var(--text-secondary)")
                                    }
                                >
                                    {link.label}
                                    {isActive && !link.accent && (
                                        <span
                                            style={{
                                                position: "absolute",
                                                bottom: 0,
                                                left: "50%",
                                                transform: "translateX(-50%)",
                                                width: "70%",
                                                height: "2px",
                                                borderRadius: "1px",
                                                background: "var(--color-accent)",
                                            }}
                                        />
                                    )}
                                </Link>
                            );
                        })}
                    </nav>

                    <div
                        style={{
                            display: "flex",
                            alignItems: "center",
                            gap: "var(--space-lg)",
                        }}
                    >
                        {/* Search */}
                        <button
                            aria-label="Tìm kiếm"
                            onClick={() => setIsSearchOpen(true)}
                            style={{
                                padding: "var(--space-sm)",
                                color: "var(--text-secondary)",
                                transition: "color var(--transition-fast)",
                            }}
                            onMouseEnter={(e) =>
                                (e.currentTarget.style.color = "var(--header-hover)")
                            }
                            onMouseLeave={(e) =>
                                (e.currentTarget.style.color = "var(--text-secondary)")
                            }
                        >
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <circle cx="11" cy="11" r="8" />
                                <path d="M21 21l-4.35-4.35" />
                            </svg>
                        </button>

                        {/* Theme Toggle */}
                        <button
                            aria-label={isLight ? "Chế độ tối" : "Chế độ sáng"}
                            title={isLight ? "Chế độ tối" : "Chế độ sáng"}
                            onClick={toggleTheme}
                            style={{
                                padding: "var(--space-sm)",
                                color: "var(--text-secondary)",
                                transition: "color var(--transition-fast), transform 0.3s ease",
                            }}
                            onMouseEnter={(e) => {
                                e.currentTarget.style.color = "var(--color-accent)";
                                e.currentTarget.style.transform = "rotate(30deg)";
                            }}
                            onMouseLeave={(e) => {
                                e.currentTarget.style.color = "var(--text-secondary)";
                                e.currentTarget.style.transform = "rotate(0)";
                            }}
                        >
                            {isLight ? (
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
                                </svg>
                            ) : (
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <circle cx="12" cy="12" r="5" />
                                    <line x1="12" y1="1" x2="12" y2="3" />
                                    <line x1="12" y1="21" x2="12" y2="23" />
                                    <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" />
                                    <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" />
                                    <line x1="1" y1="12" x2="3" y2="12" />
                                    <line x1="21" y1="12" x2="23" y2="12" />
                                    <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" />
                                    <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" />
                                </svg>
                            )}
                        </button>

                        {/* Wishlist */}
                        <Link
                            href="/yeu-thich"
                            aria-label="Yêu thích"
                            style={{
                                padding: "var(--space-sm)",
                                color: "var(--text-secondary)",
                                transition: "color var(--transition-fast)",
                                position: "relative",
                            }}
                            className="desktop-only"
                            onMouseEnter={(e) =>
                                (e.currentTarget.style.color = "var(--color-accent)")
                            }
                            onMouseLeave={(e) =>
                                (e.currentTarget.style.color = "var(--text-secondary)")
                            }
                        >
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                            </svg>
                            {wishlistCount > 0 && (
                                <span
                                    style={{
                                        position: "absolute",
                                        top: 0,
                                        right: 0,
                                        width: "16px",
                                        height: "16px",
                                        borderRadius: "50%",
                                        background: "var(--color-accent)",
                                        color: "#fff",
                                        fontSize: "0.6rem",
                                        fontWeight: 700,
                                        display: "flex",
                                        alignItems: "center",
                                        justifyContent: "center",
                                    }}
                                >
                                    {wishlistCount}
                                </span>
                            )}
                        </Link>

                        {/* Cart */}
                        <Link
                            href="/gio-hang"
                            aria-label="Giỏ hàng"
                            style={{
                                padding: "var(--space-sm)",
                                color: "var(--text-secondary)",
                                transition: "color var(--transition-fast)",
                                position: "relative",
                            }}
                            onMouseEnter={(e) =>
                                (e.currentTarget.style.color = "var(--header-hover)")
                            }
                            onMouseLeave={(e) =>
                                (e.currentTarget.style.color = "var(--text-secondary)")
                            }
                        >
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" />
                                <line x1="3" y1="6" x2="21" y2="6" />
                                <path d="M16 10a4 4 0 0 1-8 0" />
                            </svg>
                            {cartCount > 0 && (
                                <span
                                    style={{
                                        position: "absolute",
                                        top: "2px",
                                        right: "0",
                                        width: "16px",
                                        height: "16px",
                                        borderRadius: "50%",
                                        background: "var(--color-accent)",
                                        color: "var(--color-white)",
                                        fontSize: "0.6rem",
                                        fontWeight: 700,
                                        display: "flex",
                                        alignItems: "center",
                                        justifyContent: "center",
                                    }}
                                >
                                    {cartCount}
                                </span>
                            )}
                        </Link>

                        {/* User */}
                        {isLoggedIn ? (
                            <div ref={userDropdownRef} style={{ position: "relative" }} className="desktop-only">
                                <button
                                    onClick={() => setIsUserDropdownOpen(!isUserDropdownOpen)}
                                    aria-label="Tài khoản"
                                    style={{
                                        padding: "var(--space-sm)",
                                        color: "var(--text-secondary)",
                                        transition: "all var(--transition-fast)",
                                        display: "inline-flex",
                                        background: "transparent",
                                        border: "none",
                                        cursor: "pointer",
                                    }}
                                >
                                    {userPhotoURL ? (
                                        <Image src={userPhotoURL} alt="Avatar" width={28} height={28} style={{ borderRadius: "50%", border: "2px solid var(--color-accent)", objectFit: "cover" }} />
                                    ) : (
                                        <div style={{ width: 28, height: 28, borderRadius: "50%", background: "var(--color-accent)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "0.75rem", fontWeight: 700, color: "#fff" }}>
                                            {userDisplayName?.charAt(0)?.toUpperCase() || "U"}
                                        </div>
                                    )}
                                </button>

                                {/* Dropdown */}
                                {isUserDropdownOpen && (
                                    <div style={{
                                        position: "absolute",
                                        top: "calc(100% + 8px)",
                                        right: 0,
                                        width: "260px",
                                        background: "var(--bg-card)",
                                        border: "1px solid var(--border-color)",
                                        borderRadius: "var(--radius-lg)",
                                        boxShadow: "0 12px 40px rgba(0,0,0,0.3)",
                                        zIndex: 100,
                                        overflow: "hidden",
                                        animation: "fadeInDown 0.15s ease",
                                    }}>
                                        {/* User info */}
                                        <div style={{ padding: "16px", borderBottom: "1px solid var(--border-color)", display: "flex", alignItems: "center", gap: "12px" }}>
                                            {userPhotoURL ? (
                                                <Image src={userPhotoURL} alt="Avatar" width={40} height={40} style={{ borderRadius: "50%", objectFit: "cover", flexShrink: 0, border: "2px solid var(--color-accent)" }} />
                                            ) : (
                                                <div style={{ width: 40, height: 40, borderRadius: "50%", background: "rgba(139,92,246,0.15)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "1rem", fontWeight: 700, color: "var(--color-accent)", flexShrink: 0 }}>
                                                    {userDisplayName?.charAt(0)?.toUpperCase() || "U"}
                                                </div>
                                            )}
                                            <div style={{ overflow: "hidden" }}>
                                                <p style={{ fontSize: "0.85rem", fontWeight: 600, color: "var(--text-primary)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{userDisplayName || "Người dùng"}</p>
                                                <p style={{ fontSize: "0.72rem", color: "var(--text-muted)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{userEmail}</p>
                                            </div>
                                        </div>

                                        {/* Menu items */}
                                        <div style={{ padding: "6px" }}>
                                            <Link
                                                href="/tai-khoan"
                                                onClick={() => setIsUserDropdownOpen(false)}
                                                style={{ display: "flex", alignItems: "center", gap: "10px", padding: "10px 12px", borderRadius: "var(--radius-md)", color: "var(--text-primary)", fontSize: "0.82rem", fontWeight: 500, textDecoration: "none", transition: "background 0.15s" }}
                                                onMouseEnter={(e) => e.currentTarget.style.background = "var(--bg-elevated)"}
                                                onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
                                            >
                                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>
                                                Thông tin tài khoản
                                            </Link>
                                        </div>

                                        {/* Logout */}
                                        <div style={{ padding: "6px", borderTop: "1px solid var(--border-color)" }}>
                                            <button
                                                onClick={async () => {
                                                    setIsUserDropdownOpen(false);
                                                    await signOutUser();
                                                    toast.success("Đã đăng xuất thành công!");
                                                    router.push("/");
                                                }}
                                                style={{ display: "flex", alignItems: "center", gap: "10px", padding: "10px 12px", borderRadius: "var(--radius-md)", color: "#ef4444", fontSize: "0.82rem", fontWeight: 500, width: "100%", background: "transparent", border: "none", cursor: "pointer", transition: "background 0.15s", textAlign: "left" }}
                                                onMouseEnter={(e) => e.currentTarget.style.background = "rgba(239,68,68,0.06)"}
                                                onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
                                            >
                                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" /></svg>
                                                Đăng xuất
                                            </button>
                                        </div>
                                    </div>
                                )}
                            </div>
                        ) : (
                            <Link
                                href="/dang-nhap"
                                aria-label="\u0110\u0103ng nh\u1eadp"
                                style={{
                                    padding: "var(--space-sm)",
                                    color: "var(--text-secondary)",
                                    transition: "color var(--transition-fast)",
                                    display: "inline-flex",
                                }}
                                className="desktop-only"
                                onMouseEnter={(e) => (e.currentTarget.style.color = "var(--color-white)")}
                                onMouseLeave={(e) => (e.currentTarget.style.color = "var(--text-secondary)")}
                            >
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                                    <circle cx="12" cy="7" r="4" />
                                </svg>
                            </Link>
                        )}

                        {/* Mobile Hamburger */}
                        <button
                            aria-label="Menu"
                            className="mobile-only"
                            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                            style={{
                                padding: "var(--space-sm)",
                                color: "var(--text-primary)",
                                display: "none",
                            }}
                        >
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                {isMobileMenuOpen ? (
                                    <>
                                        <line x1="18" y1="6" x2="6" y2="18" />
                                        <line x1="6" y1="6" x2="18" y2="18" />
                                    </>
                                ) : (
                                    <>
                                        <line x1="3" y1="6" x2="21" y2="6" />
                                        <line x1="3" y1="12" x2="21" y2="12" />
                                        <line x1="3" y1="18" x2="21" y2="18" />
                                    </>
                                )}
                            </svg>
                        </button>
                    </div>
                </div>
            </header>

            {/* Mobile Menu Overlay */}
            {isMobileMenuOpen && (
                <div
                    className="mobile-menu-overlay"
                    style={{
                        position: "fixed",
                        inset: 0,
                        zIndex: 999,
                        background: "rgba(0, 0, 0, 0.6)",
                    }}
                    onClick={() => setIsMobileMenuOpen(false)}
                />
            )}

            {/* Mobile Menu Drawer */}
            <div
                className="mobile-menu-drawer"
                style={{
                    position: "fixed",
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: "280px",
                    zIndex: 1001,
                    background: "var(--bg-secondary)",
                    borderLeft: "1px solid var(--border-color)",
                    transform: isMobileMenuOpen ? "translateX(0)" : "translateX(100%)",
                    transition: "transform var(--transition-slow)",
                    padding: "var(--space-2xl) var(--space-lg)",
                    display: "flex",
                    flexDirection: "column",
                    gap: "var(--space-sm)",
                }}
            >
                {/* Close button */}
                <button
                    onClick={() => setIsMobileMenuOpen(false)}
                    style={{
                        alignSelf: "flex-end",
                        padding: "var(--space-sm)",
                        color: "var(--text-secondary)",
                        marginBottom: "var(--space-lg)",
                    }}
                >
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <line x1="18" y1="6" x2="6" y2="18" />
                        <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                </button>

                {NAV_LINKS.map((link) => {
                    if (link.hasDropdown) {
                        return (
                            <div key={link.href}>
                                <button
                                    onClick={() => setMobileProductsOpen(!mobileProductsOpen)}
                                    style={{
                                        fontSize: "1.05rem",
                                        fontWeight: 500,
                                        padding: "var(--space-md) 0",
                                        borderBottom: "1px solid var(--border-color)",
                                        color: "var(--text-primary)",
                                        width: "100%",
                                        display: "flex",
                                        alignItems: "center",
                                        justifyContent: "space-between",
                                        background: "transparent",
                                        border: "none",
                                        borderBottomStyle: "solid",
                                        borderBottomWidth: "1px",
                                        borderBottomColor: "var(--border-color)",
                                        cursor: "pointer",
                                    }}
                                >
                                    {link.label}
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" style={{ transition: "transform 0.25s ease", transform: mobileProductsOpen ? "rotate(180deg)" : "rotate(0deg)" }}>
                                        <polyline points="6 9 12 15 18 9" />
                                    </svg>
                                </button>
                                <div style={{
                                    maxHeight: mobileProductsOpen ? "600px" : "0",
                                    opacity: mobileProductsOpen ? 1 : 0,
                                    overflow: "hidden",
                                    transition: "max-height 0.35s ease, opacity 0.25s ease",
                                    paddingLeft: "var(--space-md)",
                                }}>
                                    <p style={{ fontSize: "0.75rem", fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", color: "var(--color-accent)", padding: "var(--space-sm) 0", marginTop: "var(--space-sm)" }}>Nam</p>
                                    {maleCategories.map((cat) => (
                                        <Link key={cat.id} href={`/nam?danh-muc=${cat.id}`} onClick={() => setIsMobileMenuOpen(false)} style={{ display: "block", padding: "6px 0", fontSize: "0.9rem", color: "var(--text-secondary)" }}>{cat.name}</Link>
                                    ))}
                                    <Link href="/nam" onClick={() => setIsMobileMenuOpen(false)} style={{ display: "block", padding: "6px 0", fontSize: "0.82rem", fontWeight: 600, color: "var(--color-accent)" }}>Xem tất cả Nam →</Link>

                                    <p style={{ fontSize: "0.75rem", fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", color: "var(--color-accent)", padding: "var(--space-sm) 0", marginTop: "var(--space-sm)" }}>Nữ</p>
                                    {femaleCategories.map((cat) => (
                                        <Link key={cat.id} href={`/nu?danh-muc=${cat.id}`} onClick={() => setIsMobileMenuOpen(false)} style={{ display: "block", padding: "6px 0", fontSize: "0.9rem", color: "var(--text-secondary)" }}>{cat.name}</Link>
                                    ))}
                                    <Link href="/nu" onClick={() => setIsMobileMenuOpen(false)} style={{ display: "block", padding: "6px 0 var(--space-md)", fontSize: "0.82rem", fontWeight: 600, color: "var(--color-accent)" }}>Xem tất cả Nữ →</Link>
                                </div>
                            </div>
                        );
                    }
                    const isActive = link.href === "/" ? pathname === "/" : pathname.startsWith(link.href);
                    return (
                        <Link
                            key={link.href}
                            href={link.href}
                            onClick={(e) => {
                                setIsMobileMenuOpen(false);
                                if (isActive) {
                                    e.preventDefault();
                                    window.location.href = link.href;
                                }
                            }}
                            style={{
                                fontSize: "1.05rem",
                                fontWeight: 500,
                                padding: "var(--space-md) 0",
                                borderBottom: "1px solid var(--border-color)",
                                color: link.accent
                                    ? "var(--color-accent)"
                                    : "var(--text-primary)",
                            }}
                        >
                            {link.label}
                        </Link>
                    );
                })}
            </div>

            {/* Responsive styles */}
            <style jsx global>{`
        .desktop-nav {
          display: flex !important;
        }
        .desktop-only {
          display: inline-flex !important;
        }
        .mobile-only {
          display: none !important;
        }

        @media (max-width: 768px) {
          .desktop-nav {
            display: none !important;
          }
          .desktop-only {
            display: none !important;
          }
          .mobile-only {
            display: inline-flex !important;
          }
        }
      `}</style>

            {/* Search Overlay */}
            {isSearchOpen && (
                <div
                    style={{
                        position: "fixed",
                        inset: 0,
                        zIndex: 9999,
                        background: "rgba(0,0,0,0.7)",
                        backdropFilter: "blur(8px)",
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        paddingTop: "120px",
                        animation: "fadeIn 0.2s ease",
                    }}
                    onClick={() => setIsSearchOpen(false)}
                >
                    <div
                        style={{
                            width: "100%",
                            maxWidth: "640px",
                            padding: "0 var(--space-lg)",
                        }}
                        onClick={(e) => e.stopPropagation()}
                    >
                        {/* Search input */}
                        <div
                            style={{
                                display: "flex",
                                alignItems: "center",
                                gap: "var(--space-md)",
                                padding: "14px 20px",
                                borderRadius: "var(--radius-lg)",
                                border: "1px solid var(--color-accent)",
                                background: "var(--bg-card)",
                                boxShadow: "0 8px 32px rgba(139,92,246,0.15)",
                            }}
                        >
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2">
                                <circle cx="11" cy="11" r="8" />
                                <path d="M21 21l-4.35-4.35" />
                            </svg>
                            <input
                                ref={searchInputRef}
                                type="text"
                                placeholder="Tìm kiếm sản phẩm..."
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                onKeyDown={(e) => {
                                    if (e.key === "Escape") setIsSearchOpen(false);
                                }}
                                style={{
                                    flex: 1,
                                    background: "transparent",
                                    border: "none",
                                    outline: "none",
                                    color: "var(--text-primary)",
                                    fontSize: "1rem",
                                }}
                            />
                            <button
                                onClick={() => setIsSearchOpen(false)}
                                style={{
                                    padding: "4px",
                                    color: "var(--text-muted)",
                                    cursor: "pointer",
                                    background: "transparent",
                                    border: "none",
                                }}
                            >
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                    <line x1="18" y1="6" x2="6" y2="18" />
                                    <line x1="6" y1="6" x2="18" y2="18" />
                                </svg>
                            </button>
                        </div>

                        {/* Results */}
                        {searchQuery.trim().length >= 1 && (
                            <div
                                style={{
                                    marginTop: "var(--space-md)",
                                    borderRadius: "var(--radius-lg)",
                                    border: "1px solid var(--border-color)",
                                    background: "var(--bg-card)",
                                    maxHeight: "420px",
                                    overflowY: "auto",
                                    boxShadow: "0 12px 40px rgba(0,0,0,0.3)",
                                }}
                            >
                                {!searchLoaded ? (
                                    <div style={{ padding: "24px", textAlign: "center", color: "var(--text-muted)", fontSize: "0.85rem" }}>
                                        Đang tải...
                                    </div>
                                ) : searchResults.length === 0 ? (
                                    <div style={{ padding: "24px", textAlign: "center", color: "var(--text-muted)", fontSize: "0.85rem" }}>
                                        Không tìm thấy sản phẩm phù hợp
                                    </div>
                                ) : (
                                    searchResults.map((product) => {
                                        const saleActive = product.salePrice > 0 && product.salePrice < product.price;
                                        return (
                                            <Link
                                                key={product.id}
                                                href={`/san-pham/${product.id}`}
                                                onClick={() => setIsSearchOpen(false)}
                                                style={{
                                                    display: "flex",
                                                    alignItems: "center",
                                                    gap: "var(--space-md)",
                                                    padding: "12px 16px",
                                                    borderBottom: "1px solid rgba(255,255,255,0.04)",
                                                    transition: "background 0.15s",
                                                    textDecoration: "none",
                                                }}
                                                onMouseEnter={(e) =>
                                                    (e.currentTarget.style.background = "rgba(139,92,246,0.06)")
                                                }
                                                onMouseLeave={(e) =>
                                                    (e.currentTarget.style.background = "transparent")
                                                }
                                            >
                                                {/* Thumbnail */}
                                                <div style={{
                                                    width: "48px",
                                                    height: "60px",
                                                    borderRadius: "var(--radius-sm)",
                                                    overflow: "hidden",
                                                    position: "relative",
                                                    flexShrink: 0,
                                                    background: "var(--bg-tertiary)",
                                                }}>
                                                    {product.images?.[0] && (
                                                        <Image
                                                            src={product.images[0]}
                                                            alt={product.name}
                                                            fill
                                                            sizes="48px"
                                                            style={{ objectFit: "cover" }}
                                                        />
                                                    )}
                                                </div>
                                                {/* Info */}
                                                <div style={{ flex: 1, minWidth: 0 }}>
                                                    <p style={{
                                                        fontSize: "0.65rem",
                                                        color: "var(--text-muted)",
                                                        textTransform: "uppercase",
                                                        letterSpacing: "0.06em",
                                                        marginBottom: "2px",
                                                    }}>{product.brandName}</p>
                                                    <p style={{
                                                        fontSize: "0.85rem",
                                                        fontWeight: 600,
                                                        color: "var(--text-primary)",
                                                        whiteSpace: "nowrap",
                                                        overflow: "hidden",
                                                        textOverflow: "ellipsis",
                                                    }}>{product.name}</p>
                                                </div>
                                                {/* Price */}
                                                <div style={{ textAlign: "right", flexShrink: 0 }}>
                                                    <span style={{
                                                        fontSize: "0.85rem",
                                                        fontWeight: 700,
                                                        color: saleActive ? "var(--color-accent)" : "var(--text-primary)",
                                                    }}>
                                                        {new Intl.NumberFormat("vi-VN").format(saleActive ? product.salePrice : product.price)}đ
                                                    </span>
                                                    {saleActive && (
                                                        <span style={{
                                                            display: "block",
                                                            fontSize: "0.7rem",
                                                            color: "var(--text-muted)",
                                                            textDecoration: "line-through",
                                                        }}>
                                                            {new Intl.NumberFormat("vi-VN").format(product.price)}đ
                                                        </span>
                                                    )}
                                                </div>
                                            </Link>
                                        );
                                    })
                                )}
                            </div>
                        )}
                    </div>
                </div>
            )}
        </>
    );
}
