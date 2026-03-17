"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import Link from "next/link";
import Image from "next/image";
import { useWishlist } from "@/components/WishlistProvider";
import { Product } from "@/lib/types";
import { doc, getDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
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

/* ─── Fetch products by IDs ─── */
async function getProductsByIds(ids: string[]): Promise<Product[]> {
    if (ids.length === 0) return [];
    const results: Product[] = [];
    // Fetch in parallel, max 10 concurrent
    const chunks: string[][] = [];
    for (let i = 0; i < ids.length; i += 10) {
        chunks.push(ids.slice(i, i + 10));
    }
    for (const chunk of chunks) {
        const docs = await Promise.all(
            chunk.map((id) => getDoc(doc(db, "products", id)))
        );
        docs.forEach((snap) => {
            if (snap.exists()) {
                const data = snap.data();
                results.push({
                    id: snap.id,
                    ...data,
                    createdAt: data.createdAt?.toDate?.() ?? new Date(),
                    updatedAt: data.updatedAt?.toDate?.() ?? new Date(),
                } as Product);
            }
        });
    }
    return results;
}

/* ─── Product Card ─── */
function WishlistCard({
    product,
    index,
    onRemove,
}: {
    product: Product;
    index: number;
    onRemove: (id: string) => void;
}) {
    const saleActive = product.salePrice > 0 && product.salePrice < product.price;
    const discount = saleActive
        ? Math.round(((product.price - product.salePrice) / product.price) * 100)
        : 0;
    const isNew =
        (new Date().getTime() - new Date(product.createdAt).getTime()) /
            (1000 * 60 * 60 * 24) <
        30;

    return (
        <div
            className="product-card"
            style={{
                position: "relative",
                borderRadius: "var(--radius-lg)",
                overflow: "hidden",
                background: "var(--bg-card)",
                border: "1px solid var(--border-color)",
                transition: "all 0.35s ease",
                animation: `fadeIn 0.5s ease ${index * 0.08}s both`,
            }}
            onMouseEnter={(e) => {
                e.currentTarget.style.transform = "translateY(-4px)";
                e.currentTarget.style.boxShadow = "0 16px 40px rgba(0,0,0,0.2)";
                e.currentTarget.style.borderColor = "rgba(139,92,246,0.3)";
            }}
            onMouseLeave={(e) => {
                e.currentTarget.style.transform = "translateY(0)";
                e.currentTarget.style.boxShadow = "none";
                e.currentTarget.style.borderColor = "var(--border-color)";
            }}
        >
            {/* Image */}
            <Link
                href={`/san-pham/${product.id}`}
                style={{ display: "block", position: "relative" }}
            >
                <div
                    className="product-img-wrap"
                    style={{
                        position: "relative",
                        aspectRatio: "3/4",
                        overflow: "hidden",
                        background: "var(--bg-tertiary)",
                    }}
                >
                    {product.images?.[0] && (
                        <Image
                            src={product.images[0]}
                            alt={product.name}
                            fill
                            sizes="(max-width: 768px) 50vw, 25vw"
                            style={{
                                objectFit: "cover",
                                transition: "transform 0.5s ease",
                            }}
                            className="product-img-primary"
                        />
                    )}
                    {product.images?.[1] && (
                        <Image
                            src={product.images[1]}
                            alt={product.name}
                            fill
                            sizes="(max-width: 768px) 50vw, 25vw"
                            style={{
                                objectFit: "cover",
                                opacity: 0,
                                transition: "opacity 0.5s ease",
                            }}
                            className="product-img-secondary"
                        />
                    )}
                </div>

                {/* Badges */}
                <div
                    style={{
                        position: "absolute",
                        top: "10px",
                        left: "10px",
                        display: "flex",
                        flexDirection: "column",
                        gap: "6px",
                    }}
                >
                    {saleActive && (
                        <span
                            style={{
                                padding: "3px 10px",
                                borderRadius: "var(--radius-full)",
                                background:
                                    "linear-gradient(135deg, #ef4444 0%, #dc2626 100%)",
                                color: "#fff",
                                fontSize: "0.7rem",
                                fontWeight: 700,
                            }}
                        >
                            -{discount}%
                        </span>
                    )}
                    {isNew && (
                        <span
                            style={{
                                padding: "3px 10px",
                                borderRadius: "var(--radius-full)",
                                background:
                                    "linear-gradient(135deg, var(--color-accent) 0%, #6366f1 100%)",
                                color: "#fff",
                                fontSize: "0.7rem",
                                fontWeight: 700,
                            }}
                        >
                            MỚI
                        </span>
                    )}
                </div>
            </Link>

            {/* Remove button */}
            <button
                onClick={() => onRemove(product.id)}
                title="Bỏ yêu thích"
                style={{
                    position: "absolute",
                    top: "10px",
                    right: "10px",
                    width: "36px",
                    height: "36px",
                    borderRadius: "var(--radius-full)",
                    background: "rgba(0,0,0,0.5)",
                    backdropFilter: "blur(8px)",
                    border: "1px solid rgba(255,255,255,0.1)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    cursor: "pointer",
                    color: "#ef4444",
                    transition: "all 0.2s ease",
                    zIndex: 5,
                }}
                onMouseEnter={(e) => {
                    e.currentTarget.style.background = "rgba(239,68,68,0.2)";
                    e.currentTarget.style.transform = "scale(1.1)";
                }}
                onMouseLeave={(e) => {
                    e.currentTarget.style.background = "rgba(0,0,0,0.5)";
                    e.currentTarget.style.transform = "scale(1)";
                }}
            >
                <svg
                    width="18"
                    height="18"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    stroke="currentColor"
                    strokeWidth="1"
                >
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                </svg>
            </button>

            {/* Info */}
            <div style={{ padding: "14px 16px 18px" }}>
                <p
                    style={{
                        fontSize: "0.7rem",
                        fontWeight: 600,
                        color: "var(--text-muted)",
                        textTransform: "uppercase",
                        letterSpacing: "0.08em",
                        marginBottom: "6px",
                    }}
                >
                    {product.brandName}
                </p>
                <Link
                    href={`/san-pham/${product.id}`}
                    style={{
                        fontSize: "0.9rem",
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
                    {product.name}
                </Link>

                {/* Colors */}
                {product.colors?.length > 0 && (
                    <div
                        style={{
                            display: "flex",
                            gap: "4px",
                            marginBottom: "10px",
                        }}
                    >
                        {product.colors.slice(0, 4).map((color) => (
                            <span
                                key={color}
                                title={color}
                                style={{
                                    width: "14px",
                                    height: "14px",
                                    borderRadius: "50%",
                                    border: "1.5px solid var(--border-color)",
                                    background: color.toLowerCase(),
                                }}
                            />
                        ))}
                        {product.colors.length > 4 && (
                            <span
                                style={{
                                    fontSize: "0.65rem",
                                    color: "var(--text-muted)",
                                    lineHeight: "14px",
                                }}
                            >
                                +{product.colors.length - 4}
                            </span>
                        )}
                    </div>
                )}

                {/* Price */}
                <div
                    style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "var(--space-sm)",
                    }}
                >
                    <span
                        style={{
                            fontSize: "1rem",
                            fontWeight: 700,
                            color: saleActive
                                ? "var(--color-accent)"
                                : "var(--text-primary)",
                        }}
                    >
                        {formatPrice(saleActive ? product.salePrice : product.price)}
                    </span>
                    {saleActive && (
                        <span
                            style={{
                                fontSize: "0.8rem",
                                color: "var(--text-muted)",
                                textDecoration: "line-through",
                            }}
                        >
                            {formatPrice(product.price)}
                        </span>
                    )}
                </div>
            </div>
        </div>
    );
}

/* ─── Skeleton Card ─── */
function SkeletonCard() {
    return (
        <div
            style={{
                borderRadius: "var(--radius-lg)",
                overflow: "hidden",
                background: "var(--bg-card)",
                border: "1px solid var(--border-color)",
            }}
        >
            <div
                style={{
                    aspectRatio: "3/4",
                    background:
                        "linear-gradient(90deg, var(--bg-tertiary) 25%, rgba(255,255,255,0.05) 50%, var(--bg-tertiary) 75%)",
                    backgroundSize: "200% 100%",
                    animation: "shimmer 1.5s infinite",
                }}
            />
            <div style={{ padding: "14px 16px 18px" }}>
                <div
                    style={{
                        height: "10px",
                        width: "50px",
                        borderRadius: "4px",
                        background: "var(--bg-tertiary)",
                        marginBottom: "10px",
                    }}
                />
                <div
                    style={{
                        height: "14px",
                        width: "80%",
                        borderRadius: "4px",
                        background: "var(--bg-tertiary)",
                        marginBottom: "8px",
                    }}
                />
                <div
                    style={{
                        height: "16px",
                        width: "60px",
                        borderRadius: "4px",
                        background: "var(--bg-tertiary)",
                    }}
                />
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
                padding: "var(--space-4xl) var(--space-lg)",
                maxWidth: "480px",
                margin: "0 auto",
            }}
        >
            {/* Heart icon */}
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
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
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
                Chưa có sản phẩm yêu thích
            </h2>
            <p
                style={{
                    color: "var(--text-muted)",
                    fontSize: "0.9rem",
                    lineHeight: 1.7,
                    marginBottom: "var(--space-xl)",
                }}
            >
                Hãy khám phá bộ sưu tập và bấm vào biểu tượng trái tim để lưu những sản
                phẩm bạn yêu thích.
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
                Khám Phá Sản Phẩm
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

/* ─── Not Logged In State ─── */
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
                Đăng nhập để xem Yêu thích
            </h2>
            <p
                style={{
                    color: "var(--text-muted)",
                    fontSize: "0.9rem",
                    lineHeight: 1.7,
                    marginBottom: "var(--space-xl)",
                }}
            >
                Bạn cần đăng nhập để lưu và quản lý danh sách sản phẩm yêu thích của mình.
            </p>

            <div style={{ display: "flex", gap: "var(--space-md)", justifyContent: "center", flexWrap: "wrap" }}>
                <Link
                    href="/dang-nhap"
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

export default function WishlistPage() {
    const { wishlist, removeFromWishlist, clearWishlist, wishlistCount, user } =
        useWishlist();
    const [products, setProducts] = useState<Product[]>([]);
    const [loading, setLoading] = useState(true);
    const headerRef = useReveal("up");

    const fetchWishlistProducts = useCallback(async () => {
        if (!user) {
            setLoading(false);
            return;
        }
        if (wishlist.length === 0) {
            setProducts([]);
            setLoading(false);
            return;
        }
        try {
            setLoading(true);
            const fetched = await getProductsByIds(wishlist);
            // Maintain wishlist order
            const ordered = wishlist
                .map((id) => fetched.find((p) => p.id === id))
                .filter(Boolean) as Product[];
            setProducts(ordered);
        } catch (err) {
            console.error("Failed to fetch wishlist products:", err);
        } finally {
            setLoading(false);
        }
    }, [wishlist, user]);

    useEffect(() => {
        fetchWishlistProducts();
    }, [fetchWishlistProducts]);

    useEffect(() => {
        window.scrollTo(0, 0);
    }, []);

    const handleRemove = (id: string) => {
        removeFromWishlist(id);
        setProducts((prev) => prev.filter((p) => p.id !== id));
    };

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
                        <div>
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
                                Sản Phẩm Yêu Thích
                                {user && wishlistCount > 0 && (
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
                                        {wishlistCount} sản phẩm
                                    </span>
                                )}
                            </h1>
                        </div>

                        {user && wishlistCount > 0 && (
                            <button
                                onClick={clearWishlist}
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
                    ) : loading ? (
                        <div
                            className="wishlist-grid"
                            style={{
                                display: "grid",
                                gridTemplateColumns: "repeat(4, 1fr)",
                                gap: "var(--space-lg)",
                            }}
                        >
                            {[...Array(4)].map((_, i) => (
                                <SkeletonCard key={i} />
                            ))}
                        </div>
                    ) : wishlistCount === 0 ? (
                        <EmptyState />
                    ) : (
                        <div
                            style={{
                                borderRadius: "var(--radius-lg)",
                                border: "1px solid var(--border-color)",
                                background: "var(--bg-card)",
                                padding: "20px",
                            }}
                        >
                            <div
                                className="wishlist-grid"
                                style={{
                                    display: "grid",
                                    gridTemplateColumns: "repeat(4, 1fr)",
                                    gap: "var(--space-lg)",
                                }}
                            >
                                {products.map((product, i) => (
                                    <WishlistCard
                                        key={product.id}
                                        product={product}
                                        index={i}
                                        onRemove={handleRemove}
                                    />
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            </section>

            {/* Scoped styles */}
            <style jsx global>{`
                .product-card:hover .product-img-primary {
                    opacity: 0 !important;
                }
                .product-card:hover .product-img-secondary {
                    opacity: 1 !important;
                }
                .product-card:hover .product-img-wrap img {
                    transform: scale(1.06);
                }

                @media (max-width: 1024px) {
                    .wishlist-grid {
                        grid-template-columns: repeat(3, 1fr) !important;
                    }
                }
                @media (max-width: 768px) {
                    .wishlist-grid {
                        grid-template-columns: repeat(2, 1fr) !important;
                        gap: var(--space-md) !important;
                    }
                }
            `}</style>
        </>
    );
}
