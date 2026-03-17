"use client";

import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import Image from "next/image";
import { useCart } from "@/components/CartProvider";
import GenderPickerModal from "@/components/GenderPickerModal";

/* ─── Helpers ─── */
function formatPrice(price: number) {
    return new Intl.NumberFormat("vi-VN").format(price) + "đ";
}

function useReveal(direction: "up" | "left" | "right" | "scale" = "up") {
    const ref = useRef<HTMLDivElement>(null);
    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        el.classList.add(`reveal-${direction}`);
        const observer = new IntersectionObserver(
            ([entry]) => {
                if (entry.isIntersecting) {
                    el.classList.add("visible");
                    observer.unobserve(el);
                }
            },
            { threshold: 0.1 }
        );
        observer.observe(el);
        return () => observer.disconnect();
    }, [direction]);
    return ref;
}

/* ─── Cart Item Row ─── */
function CartItemRow({
    item,
    onRemove,
    onUpdateQty,
}: {
    item: {
        productId: string;
        name: string;
        image: string;
        price: number;
        salePrice: number;
        brandName: string;
        size: string;
        color: string;
        quantity: number;
    };
    onRemove: () => void;
    onUpdateQty: (qty: number) => void;
}) {
    const saleActive = item.salePrice > 0 && item.salePrice < item.price;
    const unitPrice = saleActive ? item.salePrice : item.price;
    const lineTotal = unitPrice * item.quantity;

    return (
        <div
            style={{
                display: "grid",
                gridTemplateColumns: "auto 1fr auto",
                gap: "var(--space-lg)",
                padding: "var(--space-lg)",
                alignItems: "center",
                transition: "all 0.2s ease",
                borderBottom: "1px solid var(--border-color)",
            }}
            onMouseEnter={(e) => {
                e.currentTarget.style.background = "rgba(139,92,246,0.02)";
            }}
            onMouseLeave={(e) => {
                e.currentTarget.style.background = "transparent";
            }}
        >
            {/* Image */}
            <Link href={`/san-pham/${item.productId}`} style={{ flexShrink: 0 }}>
                <div
                    style={{
                        width: "100px",
                        height: "120px",
                        borderRadius: "var(--radius-md)",
                        overflow: "hidden",
                        position: "relative",
                        background: "var(--bg-tertiary)",
                    }}
                >
                    {item.image && (
                        <Image
                            src={item.image}
                            alt={item.name}
                            fill
                            sizes="100px"
                            style={{ objectFit: "cover" }}
                        />
                    )}
                </div>
            </Link>

            {/* Info */}
            <div style={{ minWidth: 0 }}>
                <p
                    style={{
                        fontSize: "0.7rem",
                        fontWeight: 600,
                        color: "var(--text-muted)",
                        textTransform: "uppercase",
                        letterSpacing: "0.08em",
                        marginBottom: "4px",
                    }}
                >
                    {item.brandName}
                </p>
                <Link
                    href={`/san-pham/${item.productId}`}
                    style={{
                        fontSize: "0.95rem",
                        fontWeight: 600,
                        color: "var(--text-primary)",
                        display: "-webkit-box",
                        WebkitLineClamp: 2,
                        WebkitBoxOrient: "vertical",
                        overflow: "hidden",
                        lineHeight: 1.4,
                        marginBottom: "8px",
                        transition: "color 0.2s",
                    }}
                    onMouseEnter={(e) =>
                        (e.currentTarget.style.color = "var(--color-accent)")
                    }
                    onMouseLeave={(e) =>
                        (e.currentTarget.style.color = "var(--text-primary)")
                    }
                >
                    {item.name}
                </Link>

                {/* Variant info */}
                <div
                    style={{
                        display: "flex",
                        gap: "var(--space-md)",
                        fontSize: "0.78rem",
                        color: "var(--text-muted)",
                        marginBottom: "12px",
                    }}
                >
                    {item.size && (
                        <span>
                            Size: <strong style={{ color: "var(--text-secondary)" }}>{item.size}</strong>
                        </span>
                    )}
                    {item.color && (
                        <span>
                            Màu: <strong style={{ color: "var(--text-secondary)" }}>{item.color}</strong>
                        </span>
                    )}
                </div>

                {/* Price + quantity (mobile-friendly) */}
                <div
                    style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "var(--space-lg)",
                        flexWrap: "wrap",
                    }}
                >
                    {/* Quantity control */}
                    <div
                        style={{
                            display: "flex",
                            alignItems: "center",
                            border: "1px solid var(--border-color)",
                            borderRadius: "var(--radius-md)",
                            overflow: "hidden",
                        }}
                    >
                        <button
                            onClick={() => onUpdateQty(item.quantity - 1)}
                            disabled={item.quantity <= 1}
                            style={{
                                width: "32px",
                                height: "32px",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                background: "transparent",
                                color: item.quantity <= 1 ? "var(--text-muted)" : "var(--text-primary)",
                                cursor: item.quantity <= 1 ? "not-allowed" : "pointer",
                                fontSize: "1rem",
                                opacity: item.quantity <= 1 ? 0.4 : 1,
                            }}
                        >
                            −
                        </button>
                        <span
                            style={{
                                width: "36px",
                                textAlign: "center",
                                fontSize: "0.85rem",
                                fontWeight: 600,
                                color: "var(--text-primary)",
                                borderLeft: "1px solid var(--border-color)",
                                borderRight: "1px solid var(--border-color)",
                                lineHeight: "32px",
                            }}
                        >
                            {item.quantity}
                        </span>
                        <button
                            onClick={() => onUpdateQty(item.quantity + 1)}
                            style={{
                                width: "32px",
                                height: "32px",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                background: "transparent",
                                color: "var(--text-primary)",
                                cursor: "pointer",
                                fontSize: "1rem",
                            }}
                        >
                            +
                        </button>
                    </div>

                    {/* Unit price */}
                    <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                        <span
                            style={{
                                fontWeight: 700,
                                color: saleActive ? "var(--color-accent)" : "var(--text-primary)",
                                fontSize: "0.9rem",
                            }}
                        >
                            {formatPrice(unitPrice)}
                        </span>
                        {saleActive && (
                            <span
                                style={{
                                    fontSize: "0.75rem",
                                    color: "var(--text-muted)",
                                    textDecoration: "line-through",
                                }}
                            >
                                {formatPrice(item.price)}
                            </span>
                        )}
                    </div>
                </div>
            </div>

            {/* Right side: total + remove */}
            <div
                style={{
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "flex-end",
                    gap: "var(--space-md)",
                }}
            >
                <span
                    style={{
                        fontSize: "1rem",
                        fontWeight: 700,
                        color: "var(--text-primary)",
                        whiteSpace: "nowrap",
                    }}
                >
                    {formatPrice(lineTotal)}
                </span>
                <button
                    onClick={onRemove}
                    title="Xóa"
                    style={{
                        padding: "6px",
                        borderRadius: "var(--radius-md)",
                        background: "transparent",
                        border: "1px solid transparent",
                        color: "var(--text-muted)",
                        cursor: "pointer",
                        transition: "all 0.2s",
                    }}
                    onMouseEnter={(e) => {
                        e.currentTarget.style.color = "#ef4444";
                        e.currentTarget.style.borderColor = "rgba(239,68,68,0.3)";
                        e.currentTarget.style.background = "rgba(239,68,68,0.06)";
                    }}
                    onMouseLeave={(e) => {
                        e.currentTarget.style.color = "var(--text-muted)";
                        e.currentTarget.style.borderColor = "transparent";
                        e.currentTarget.style.background = "transparent";
                    }}
                >
                    <svg
                        width="16"
                        height="16"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                    >
                        <polyline points="3 6 5 6 21 6" />
                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                    </svg>
                </button>
            </div>
        </div>
    );
}

/* ─── Empty State ─── */
function EmptyState() {
    const ref = useReveal("up");
    const [showGender, setShowGender] = useState(false);
    return (
        <>
        <div
            ref={ref}
            style={{
                textAlign: "center",
                padding: "var(--space-3xl) var(--space-2xl)",
                maxWidth: "540px",
                margin: "0 auto",
                borderRadius: "var(--radius-lg)",
                border: "1px solid var(--border-color)",
                background: "var(--bg-card)",
            }}
        >
            <div
                style={{
                    width: "100px",
                    height: "100px",
                    borderRadius: "var(--radius-full)",
                    background: "rgba(139,92,246,0.08)",
                    border: "1px solid rgba(139,92,246,0.15)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    margin: "0 auto var(--space-xl)",
                }}
            >
                <svg
                    width="44"
                    height="44"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="var(--color-accent)"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    style={{ opacity: 0.6 }}
                >
                    <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" />
                    <line x1="3" y1="6" x2="21" y2="6" />
                    <path d="M16 10a4 4 0 0 1-8 0" />
                </svg>
            </div>

            <h2
                style={{
                    fontSize: "1.4rem",
                    fontWeight: 700,
                    color: "var(--text-primary)",
                    marginBottom: "var(--space-md)",
                }}
            >
                Giỏ hàng trống
            </h2>
            <p
                style={{
                    color: "var(--text-muted)",
                    fontSize: "0.9rem",
                    lineHeight: 1.7,
                    marginBottom: "var(--space-xl)",
                }}
            >
                Hãy khám phá bộ sưu tập và thêm sản phẩm vào giỏ hàng của bạn.
            </p>

            <button
                onClick={() => setShowGender(true)}
                style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "var(--space-sm)",
                    padding: "12px 28px",
                    borderRadius: "var(--radius-full)",
                    background:
                        "linear-gradient(135deg, var(--color-accent) 0%, #6366f1 100%)",
                    color: "#fff",
                    fontSize: "0.85rem",
                    fontWeight: 600,
                    border: "none",
                    cursor: "pointer",
                    transition: "all 0.3s ease",
                    boxShadow: "0 4px 20px rgba(139,92,246,0.3)",
                }}
                onMouseEnter={(e) => {
                    e.currentTarget.style.transform = "translateY(-2px)";
                    e.currentTarget.style.boxShadow =
                        "0 8px 30px rgba(139,92,246,0.4)";
                }}
                onMouseLeave={(e) => {
                    e.currentTarget.style.transform = "translateY(0)";
                    e.currentTarget.style.boxShadow =
                        "0 4px 20px rgba(139,92,246,0.3)";
                }}
            >
                Mua Sắm Ngay
                <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.5"
                >
                    <path d="M5 12h14M12 5l7 7-7 7" />
                </svg>
            </button>
        </div>
        {showGender && <GenderPickerModal onClose={() => setShowGender(false)} />}
        </>
    );
}

/* ─── Login Prompt ─── */
function LoginPrompt() {
    const ref = useReveal("up");
    return (
        <div
            ref={ref}
            style={{
                textAlign: "center",
                padding: "var(--space-3xl) var(--space-2xl)",
                maxWidth: "540px",
                margin: "0 auto",
                borderRadius: "var(--radius-lg)",
                border: "1px solid var(--border-color)",
                background: "var(--bg-card)",
            }}
        >
            <div
                style={{
                    width: "100px",
                    height: "100px",
                    borderRadius: "var(--radius-full)",
                    background: "rgba(139,92,246,0.08)",
                    border: "1px solid rgba(139,92,246,0.15)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    margin: "0 auto var(--space-xl)",
                }}
            >
                <svg
                    width="44"
                    height="44"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="var(--color-accent)"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    style={{ opacity: 0.6 }}
                >
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                    <circle cx="12" cy="7" r="4" />
                </svg>
            </div>

            <h2
                style={{
                    fontSize: "1.4rem",
                    fontWeight: 700,
                    color: "var(--text-primary)",
                    marginBottom: "var(--space-md)",
                }}
            >
                Đăng nhập để xem Giỏ hàng
            </h2>
            <p
                style={{
                    color: "var(--text-muted)",
                    fontSize: "0.9rem",
                    lineHeight: 1.7,
                    marginBottom: "var(--space-xl)",
                }}
            >
                Bạn cần đăng nhập để quản lý giỏ hàng và tiến hành thanh toán.
            </p>

            <div
                style={{
                    display: "flex",
                    gap: "var(--space-md)",
                    justifyContent: "center",
                    flexWrap: "wrap",
                }}
            >
                <Link
                    href="/dang-nhap"
                    style={{
                        display: "inline-flex",
                        alignItems: "center",
                        padding: "12px 28px",
                        borderRadius: "var(--radius-full)",
                        background:
                            "linear-gradient(135deg, var(--color-accent) 0%, #6366f1 100%)",
                        color: "#fff",
                        fontSize: "0.85rem",
                        fontWeight: 600,
                        textDecoration: "none",
                        transition: "all 0.3s ease",
                        boxShadow: "0 4px 20px rgba(139,92,246,0.3)",
                    }}
                    onMouseEnter={(e) => {
                        e.currentTarget.style.transform = "translateY(-2px)";
                        e.currentTarget.style.boxShadow =
                            "0 8px 30px rgba(139,92,246,0.4)";
                    }}
                    onMouseLeave={(e) => {
                        e.currentTarget.style.transform = "translateY(0)";
                        e.currentTarget.style.boxShadow =
                            "0 4px 20px rgba(139,92,246,0.3)";
                    }}
                >
                    Đăng Nhập
                </Link>
                <Link
                    href="/dang-ky"
                    style={{
                        display: "inline-flex",
                        alignItems: "center",
                        padding: "12px 28px",
                        borderRadius: "var(--radius-full)",
                        border: "1px solid var(--border-color)",
                        background: "transparent",
                        color: "var(--text-primary)",
                        fontSize: "0.85rem",
                        fontWeight: 600,
                        textDecoration: "none",
                        transition: "all 0.3s ease",
                    }}
                    onMouseEnter={(e) => {
                        e.currentTarget.style.borderColor = "var(--color-accent)";
                        e.currentTarget.style.color = "var(--color-accent)";
                    }}
                    onMouseLeave={(e) => {
                        e.currentTarget.style.borderColor = "var(--border-color)";
                        e.currentTarget.style.color = "var(--text-primary)";
                    }}
                >
                    Đăng Ký
                </Link>
            </div>
        </div>
    );
}

/* ============================================================
   PAGE
   ============================================================ */

export default function CartPage() {
    const { cart, removeFromCart, updateQuantity, clearCart, cartCount, cartTotal, user } =
        useCart();
    const headerRef = useReveal("up");
    const [lastShoppingPage, setLastShoppingPage] = useState("/nam");

    useEffect(() => {
        window.scrollTo(0, 0);
        const saved = localStorage.getItem("lastShoppingPage");
        // eslint-disable-next-line react-hooks/set-state-in-effect
        if (saved) setLastShoppingPage(saved);
    }, []);

    return (
        <>
            <section
                className="section"
                style={{
                    paddingTop: "calc(var(--header-height) + var(--space-2xl))",
                    minHeight: "70vh",
                }}
            >
                <div className="container">
                    {/* Page header */}
                    <div
                        ref={headerRef}
                        style={{
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "space-between",
                            marginBottom: "var(--space-2xl)",
                            flexWrap: "wrap",
                            gap: "var(--space-md)",
                        }}
                    >
                        <h1
                            style={{
                                fontSize: "clamp(1.5rem, 3vw, 2rem)",
                                fontWeight: 800,
                                color: "var(--text-primary)",
                                display: "flex",
                                alignItems: "center",
                                gap: "var(--space-md)",
                            }}
                        >
                            Giỏ Hàng
                            {user && cartCount > 0 && (
                                <span
                                    style={{
                                        fontSize: "0.8rem",
                                        fontWeight: 600,
                                        padding: "4px 14px",
                                        borderRadius: "var(--radius-full)",
                                        background: "rgba(139,92,246,0.1)",
                                        color: "var(--color-accent)",
                                        border: "1px solid rgba(139,92,246,0.2)",
                                    }}
                                >
                                    {cartCount} sản phẩm
                                </span>
                            )}
                        </h1>

                        {user && cartCount > 0 && (
                            <button
                                onClick={clearCart}
                                style={{
                                    display: "flex",
                                    alignItems: "center",
                                    gap: "6px",
                                    padding: "8px 18px",
                                    borderRadius: "var(--radius-md)",
                                    border: "1px solid rgba(239,68,68,0.3)",
                                    background: "rgba(239,68,68,0.06)",
                                    color: "#ef4444",
                                    fontSize: "0.8rem",
                                    fontWeight: 600,
                                    cursor: "pointer",
                                    transition: "all 0.2s ease",
                                }}
                                onMouseEnter={(e) => {
                                    e.currentTarget.style.background = "rgba(239,68,68,0.12)";
                                    e.currentTarget.style.borderColor = "rgba(239,68,68,0.5)";
                                }}
                                onMouseLeave={(e) => {
                                    e.currentTarget.style.background = "rgba(239,68,68,0.06)";
                                    e.currentTarget.style.borderColor = "rgba(239,68,68,0.3)";
                                }}
                            >
                                <svg
                                    width="14"
                                    height="14"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    strokeWidth="2"
                                >
                                    <polyline points="3 6 5 6 21 6" />
                                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                                </svg>
                                Xóa tất cả
                            </button>
                        )}
                    </div>

                    {/* Content */}
                    {!user ? (
                        <LoginPrompt />
                    ) : cartCount === 0 ? (
                        <EmptyState />
                    ) : (
                        <div style={{ borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)", background: "var(--bg-card)", padding: "20px" }}>
                        <div
                            className="cart-layout"
                            style={{
                                display: "grid",
                                gridTemplateColumns: "1fr 360px",
                                gap: "var(--space-xl)",
                                alignItems: "start",
                            }}
                        >
                            {/* Cart items */}
                            <div>
                                {cart.map((item, i) => (
                                    <CartItemRow
                                        key={`${item.productId}-${item.size}-${item.color}`}
                                        item={item}
                                        onRemove={() =>
                                            removeFromCart(item.productId, item.size, item.color)
                                        }
                                        onUpdateQty={(qty) =>
                                            updateQuantity(
                                                item.productId,
                                                item.size,
                                                item.color,
                                                qty
                                            )
                                        }
                                    />
                                ))}
                                </div>

                            {/* Order summary */}
                            <div
                                style={{
                                    position: "sticky",
                                    top: "calc(var(--header-height) + var(--space-xl))",
                                    paddingLeft: "var(--space-xl)",
                                    borderLeft: "1px solid var(--border-color)",
                                }}
                            >
                                <h3
                                    style={{
                                        fontSize: "1.1rem",
                                        fontWeight: 700,
                                        color: "var(--text-primary)",
                                        marginBottom: "var(--space-lg)",
                                        paddingBottom: "var(--space-md)",
                                        borderBottom: "1px solid var(--border-color)",
                                    }}
                                >
                                    Tóm tắt đơn hàng
                                </h3>

                                <div
                                    style={{
                                        display: "flex",
                                        flexDirection: "column",
                                        gap: "var(--space-md)",
                                        marginBottom: "var(--space-lg)",
                                    }}
                                >
                                    <div
                                        style={{
                                            display: "flex",
                                            justifyContent: "space-between",
                                            fontSize: "0.85rem",
                                        }}
                                    >
                                        <span style={{ color: "var(--text-muted)" }}>
                                            Tạm tính ({cartCount} sản phẩm)
                                        </span>
                                        <span style={{ color: "var(--text-primary)", fontWeight: 600 }}>
                                            {formatPrice(cartTotal)}
                                        </span>
                                    </div>
                                    <div
                                        style={{
                                            display: "flex",
                                            justifyContent: "space-between",
                                            fontSize: "0.85rem",
                                        }}
                                    >
                                        <span style={{ color: "var(--text-muted)" }}>
                                            Phí vận chuyển
                                        </span>
                                        <span style={{ color: "var(--color-accent)", fontWeight: 500 }}>
                                            Miễn phí
                                        </span>
                                    </div>
                                </div>

                                <div
                                    style={{
                                        display: "flex",
                                        justifyContent: "space-between",
                                        paddingTop: "var(--space-md)",
                                        borderTop: "1px solid var(--border-color)",
                                        marginBottom: "var(--space-xl)",
                                    }}
                                >
                                    <span
                                        style={{
                                            fontSize: "1rem",
                                            fontWeight: 700,
                                            color: "var(--text-primary)",
                                        }}
                                    >
                                        Tổng cộng
                                    </span>
                                    <span
                                        style={{
                                            fontSize: "1.2rem",
                                            fontWeight: 800,
                                            color: "var(--color-accent)",
                                        }}
                                    >
                                        {formatPrice(cartTotal)}
                                    </span>
                                </div>

                                <Link
                                    href="/thanh-toan"
                                    style={{
                                        display: "block",
                                        width: "100%",
                                        padding: "14px",
                                        borderRadius: "var(--radius-full)",
                                        background:
                                            "linear-gradient(135deg, var(--color-accent) 0%, #6366f1 100%)",
                                        color: "#fff",
                                        fontSize: "0.9rem",
                                        fontWeight: 700,
                                        cursor: "pointer",
                                        transition: "all 0.3s ease",
                                        boxShadow: "0 4px 20px rgba(139,92,246,0.3)",
                                        border: "none",
                                        letterSpacing: "0.02em",
                                        textAlign: "center",
                                        textDecoration: "none",
                                    }}
                                    onMouseEnter={(e) => {
                                        e.currentTarget.style.transform = "translateY(-2px)";
                                        e.currentTarget.style.boxShadow =
                                            "0 8px 30px rgba(139,92,246,0.4)";
                                    }}
                                    onMouseLeave={(e) => {
                                        e.currentTarget.style.transform = "translateY(0)";
                                        e.currentTarget.style.boxShadow =
                                            "0 4px 20px rgba(139,92,246,0.3)";
                                    }}
                                >
                                    Tiến Hành Thanh Toán
                                </Link>

                                <Link
                                    href={lastShoppingPage}
                                    style={{
                                        display: "block",
                                        textAlign: "center",
                                        marginTop: "var(--space-md)",
                                        fontSize: "0.8rem",
                                        color: "var(--text-muted)",
                                        transition: "color 0.2s",
                                    }}
                                    onMouseEnter={(e) =>
                                        (e.currentTarget.style.color = "var(--color-accent)")
                                    }
                                    onMouseLeave={(e) =>
                                        (e.currentTarget.style.color = "var(--text-muted)")
                                    }
                                >
                                    ← Tiếp tục mua sắm
                                </Link>
                            </div>
                        </div>
                        </div>
                    )}
                </div>
            </section>

            {/* Scoped styles */}
            <style jsx global>{`
                @media (max-width: 900px) {
                    .cart-layout {
                        grid-template-columns: 1fr !important;
                    }
                }
            `}</style>
        </>
    );
}
