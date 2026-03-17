"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useState, useCallback, useRef, useMemo } from "react";
import { useSearchParams } from "next/navigation";
import { getMaleProducts } from "@/lib/products";
import { getMaleCategories } from "@/lib/categories";
import { getBrands } from "@/lib/brands";
import type { Product, Category, Brand } from "@/lib/types";
import { useCart } from "@/components/CartProvider";
import { useWishlist } from "@/components/WishlistProvider";

/* ============================================================
   HOOKS
   ============================================================ */

type RevealDirection = "up" | "down" | "left" | "right" | "scale";

function useReveal(
    direction: RevealDirection = "up",
    { threshold = 0.12, delay = 0 }: { threshold?: number; delay?: number } = {}
) {
    const ref = useRef<HTMLDivElement>(null);
    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        el.classList.add(`reveal-${direction}`);
        if (delay > 0) el.style.transitionDelay = `${delay}s`;
        const obs = new IntersectionObserver(
            ([entry]) => {
                if (entry.isIntersecting) {
                    el.classList.add("visible");
                    obs.unobserve(el);
                }
            },
            { threshold, rootMargin: "0px 0px -40px 0px" }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, [direction, threshold, delay]);
    return ref;
}

/* ============================================================
   HELPERS
   ============================================================ */

function formatPrice(price: number): string {
    return new Intl.NumberFormat("vi-VN").format(price) + "đ";
}

function isNew(product: Product): boolean {
    const twoWeeksAgo = new Date();
    twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);
    return product.createdAt >= twoWeeksAgo;
}

function getBadge(product: Product): string | null {
    if (product.salePrice > 0 && product.salePrice < product.price) {
        const percent = Math.round((1 - product.salePrice / product.price) * 100);
        return `-${percent}%`;
    }
    if (isNew(product)) return "MỚI";
    return null;
}

type SortOption = "default" | "price-asc" | "price-desc" | "newest";

const SORT_OPTIONS: { value: SortOption; label: string }[] = [
    { value: "default", label: "Mặc định" },
    { value: "price-asc", label: "Giá tăng dần" },
    { value: "price-desc", label: "Giá giảm dần" },
    { value: "newest", label: "Mới nhất" },
];

const PRICE_RANGES = [
    { label: "Dưới 1 triệu", min: 0, max: 1000000 },
    { label: "1 — 3 triệu", min: 1000000, max: 3000000 },
    { label: "3 — 5 triệu", min: 3000000, max: 5000000 },
    { label: "5 — 15 triệu", min: 5000000, max: 15000000 },
    { label: "Trên 15 triệu", min: 15000000, max: Infinity },
];

const CLOTHING_SIZES = ["S", "M", "L", "XL", "XXL"];
const SHOE_SIZES = ["36", "37", "38", "39", "40", "41", "42", "43", "44", "45"];

const ITEMS_PER_PAGE = 12;

/* ============================================================
   SUB-COMPONENTS
   ============================================================ */

/* ─── Filter Sidebar ─── */
function FilterSidebar({
    categories,
    brands,
    selectedCategories,
    selectedBrands,
    selectedPriceRange,
    selectedSizes,
    onToggleCategory,
    onToggleBrand,
    onSetPriceRange,
    onToggleSize,
    onClearAll,
    totalResults,
}: {
    categories: Category[];
    brands: Brand[];
    selectedCategories: string[];
    selectedBrands: string[];
    selectedPriceRange: number | null;
    selectedSizes: string[];
    onToggleCategory: (id: string) => void;
    onToggleBrand: (id: string) => void;
    onSetPriceRange: (index: number | null) => void;
    onToggleSize: (size: string) => void;
    onClearAll: () => void;
    totalResults: number;
}) {
    const parentCategories = categories.filter(
        (c) => !c.parentId || c.parentId === ""
    );
    const hasActiveFilter =
        selectedCategories.length > 0 ||
        selectedBrands.length > 0 ||
        selectedPriceRange !== null ||
        selectedSizes.length > 0;

    return (
        <aside
            style={{
                background: "var(--bg-card)",
                border: "1px solid var(--border-color)",
                borderRadius: "var(--radius-lg)",
                padding: "var(--space-xl)",
                userSelect: "none",
            }}
        >
            {/* Sidebar Header */}
            <div
                style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "var(--space-sm)",
                    marginBottom: "var(--space-lg)",
                    paddingBottom: "var(--space-lg)",
                    borderBottom: "1px solid var(--border-color)",
                }}
            >
                <svg
                    width="18"
                    height="18"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="var(--color-accent)"
                    strokeWidth="2"
                >
                    <line x1="4" y1="6" x2="20" y2="6" />
                    <line x1="4" y1="12" x2="16" y2="12" />
                    <line x1="4" y1="18" x2="12" y2="18" />
                </svg>
                <span
                    style={{
                        fontSize: "0.95rem",
                        fontWeight: 700,
                        color: "var(--text-primary)",
                        letterSpacing: "-0.01em",
                    }}
                >
                    Bộ Lọc
                </span>
            </div>
            {/* Result count + Clear */}
            <div
                style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    marginBottom: "var(--space-xl)",
                }}
            >
                <span
                    style={{
                        fontSize: "0.8rem",
                        color: "var(--text-muted)",
                    }}
                >
                    {totalResults} sản phẩm
                </span>
                {hasActiveFilter && (
                    <button
                        onClick={onClearAll}
                        style={{
                            fontSize: "0.75rem",
                            color: "var(--color-accent)",
                            fontWeight: 600,
                            transition: "opacity 0.2s",
                        }}
                        onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.7")}
                        onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
                    >
                        Xóa bộ lọc
                    </button>
                )}
            </div>

            {/* Category Tree */}
            <FilterGroup title="Danh mục">
                {parentCategories.map((parent) => {
                    const children = categories.filter(
                        (c) => c.parentId === parent.id
                    );
                    return (
                        <div key={parent.id}>
                            <FilterCheckbox
                                label={parent.name}
                                checked={selectedCategories.includes(parent.id)}
                                onChange={() => onToggleCategory(parent.id)}
                            />
                            {children.length > 0 && (
                                <div style={{ paddingLeft: "var(--space-lg)" }}>
                                    {children.map((child) => (
                                        <FilterCheckbox
                                            key={child.id}
                                            label={child.name}
                                            checked={selectedCategories.includes(child.id)}
                                            onChange={() => onToggleCategory(child.id)}
                                        />
                                    ))}
                                </div>
                            )}
                        </div>
                    );
                })}
            </FilterGroup>

            {/* Brands — Compact chip layout */}
            <FilterGroup title="Thương hiệu">
                <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                    {brands.map((brand) => {
                        const isActive = selectedBrands.includes(brand.id);
                        return (
                            <button
                                key={brand.id}
                                onClick={() => onToggleBrand(brand.id)}
                                style={{
                                    padding: "5px 12px",
                                    borderRadius: "var(--radius-full)",
                                    border: `1.5px solid ${isActive ? "var(--color-accent)" : "var(--border-color)"}`,
                                    background: isActive ? "rgba(139,92,246,0.12)" : "transparent",
                                    color: isActive ? "var(--color-accent)" : "var(--text-secondary)",
                                    fontSize: "0.78rem",
                                    fontWeight: 600,
                                    cursor: "pointer",
                                    transition: "all 0.2s ease",
                                    whiteSpace: "nowrap",
                                }}
                                onMouseEnter={(e) => {
                                    if (!isActive) {
                                        e.currentTarget.style.borderColor = "rgba(139,92,246,0.3)";
                                        e.currentTarget.style.color = "var(--text-primary)";
                                    }
                                }}
                                onMouseLeave={(e) => {
                                    if (!isActive) {
                                        e.currentTarget.style.borderColor = "var(--border-color)";
                                        e.currentTarget.style.color = "var(--text-secondary)";
                                    }
                                }}
                            >
                                {brand.name}
                            </button>
                        );
                    })}
                </div>
            </FilterGroup>

            {/* Price Range */}
            <FilterGroup title="Khoảng giá">
                {PRICE_RANGES.map((range, i) => (
                    <FilterCheckbox
                        key={range.label}
                        label={range.label}
                        checked={selectedPriceRange === i}
                        onChange={() =>
                            onSetPriceRange(selectedPriceRange === i ? null : i)
                        }
                    />
                ))}
            </FilterGroup>

            {/* Sizes */}
            <FilterGroup title="Kích cỡ">
                <div style={{ marginBottom: "var(--space-sm)" }}>
                    <span style={{ fontSize: "0.7rem", color: "var(--text-muted)", fontWeight: 600, letterSpacing: "0.05em", textTransform: "uppercase" }}>Quần áo</span>
                    <div style={{ display: "flex", flexWrap: "wrap", gap: "var(--space-sm)", marginTop: "6px" }}>
                        {CLOTHING_SIZES.map((size) => {
                            const isActive = selectedSizes.includes(size);
                            return (
                                <button
                                    key={size}
                                    onClick={() => onToggleSize(size)}
                                    style={{
                                        padding: "6px 14px",
                                        borderRadius: "var(--radius-md)",
                                        border: `1.5px solid ${isActive ? "var(--color-accent)" : "var(--border-color)"}`,
                                        background: isActive ? "rgba(139,92,246,0.12)" : "transparent",
                                        color: isActive ? "var(--color-accent)" : "var(--text-secondary)",
                                        fontSize: "0.8rem",
                                        fontWeight: 600,
                                        transition: "all 0.2s ease",
                                        cursor: "pointer",
                                    }}
                                >
                                    {size}
                                </button>
                            );
                        })}
                    </div>
                </div>
                <div>
                    <span style={{ fontSize: "0.7rem", color: "var(--text-muted)", fontWeight: 600, letterSpacing: "0.05em", textTransform: "uppercase" }}>Giày dép</span>
                    <div style={{ display: "flex", flexWrap: "wrap", gap: "var(--space-sm)", marginTop: "6px" }}>
                        {SHOE_SIZES.map((size) => {
                            const isActive = selectedSizes.includes(size);
                            return (
                                <button
                                    key={size}
                                    onClick={() => onToggleSize(size)}
                                    style={{
                                        padding: "6px 14px",
                                        borderRadius: "var(--radius-md)",
                                        border: `1.5px solid ${isActive ? "var(--color-accent)" : "var(--border-color)"}`,
                                        background: isActive ? "rgba(139,92,246,0.12)" : "transparent",
                                        color: isActive ? "var(--color-accent)" : "var(--text-secondary)",
                                        fontSize: "0.8rem",
                                        fontWeight: 600,
                                        transition: "all 0.2s ease",
                                        cursor: "pointer",
                                    }}
                                >
                                    {size}
                                </button>
                            );
                        })}
                    </div>
                </div>
            </FilterGroup>
        </aside>
    );
}

function FilterGroup({
    title,
    children,
}: {
    title: string;
    children: React.ReactNode;
}) {
    const [open, setOpen] = useState(true);
    return (
        <div
            style={{
                marginBottom: "var(--space-lg)",
                paddingBottom: "var(--space-lg)",
                borderBottom: "1px solid rgba(255,255,255,0.06)",
            }}
        >
            <button
                onClick={() => setOpen(!open)}
                style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    width: "100%",
                    fontSize: "0.8rem",
                    fontWeight: 700,
                    letterSpacing: "0.08em",
                    textTransform: "uppercase",
                    color: "var(--text-primary)",
                    marginBottom: open ? "var(--space-md)" : 0,
                    transition: "margin 0.2s",
                }}
            >
                {title}
                <svg
                    width="14"
                    height="14"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.5"
                    style={{
                        transition: "transform 0.25s ease",
                        transform: open ? "rotate(180deg)" : "rotate(0deg)",
                    }}
                >
                    <polyline points="6 9 12 15 18 9" />
                </svg>
            </button>
            <div
                style={{
                    overflow: "hidden",
                    maxHeight: open ? "600px" : "0px",
                    opacity: open ? 1 : 0,
                    transition: "max-height 0.35s ease, opacity 0.25s ease",
                }}
            >
                {children}
            </div>
        </div>
    );
}

function FilterCheckbox({
    label,
    checked,
    onChange,
}: {
    label: string;
    checked: boolean;
    onChange: () => void;
}) {
    return (
        <label
            style={{
                display: "flex",
                alignItems: "center",
                gap: "10px",
                padding: "7px 0",
                cursor: "pointer",
                fontSize: "0.88rem",
                lineHeight: 1.5,
                color: checked ? "var(--text-primary)" : "var(--text-secondary)",
                transition: "color 0.15s",
                userSelect: "none",
            }}
            onMouseEnter={(e) =>
                (e.currentTarget.style.color = "var(--text-primary)")
            }
            onMouseLeave={(e) =>
            (e.currentTarget.style.color = checked
                ? "var(--text-primary)"
                : "var(--text-secondary)")
            }
        >
            <div
                style={{
                    width: "16px",
                    height: "16px",
                    borderRadius: "4px",
                    border: `1.5px solid ${checked ? "var(--color-accent)" : "var(--border-light)"}`,
                    background: checked ? "var(--color-accent)" : "transparent",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    transition: "all 0.2s ease",
                    flexShrink: 0,
                }}
            >
                {checked && (
                    <svg
                        width="10"
                        height="10"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="white"
                        strokeWidth="3.5"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                    >
                        <polyline points="20 6 9 17 4 12" />
                    </svg>
                )}
            </div>
            <input
                type="checkbox"
                checked={checked}
                onChange={onChange}
                style={{ display: "none" }}
            />
            {label}
        </label>
    );
}

/* ─── Product Card ─── */
function ProductCard({
    product,
    index = 0,
}: {
    product: Product;
    index?: number;
}) {
    const badge = getBadge(product);
    const displayPrice =
        product.salePrice > 0 && product.salePrice < product.price
            ? product.salePrice
            : product.price;
    const originalPrice =
        product.salePrice > 0 && product.salePrice < product.price
            ? product.price
            : null;
    const imageUrl = product.images.length > 0 ? product.images[0] : null;
    const secondImage = product.images.length > 1 ? product.images[1] : null;
    const cardRef = useReveal("up", { threshold: 0.05, delay: index * 0.06 });
    const { addToCart: _addToCart } = useCart();
    const { toggleWishlist: _toggleWishlist, isInWishlist } = useWishlist();
    const _liked = isInWishlist(product.id);

    return (
        <div ref={cardRef}>
            <Link
                href={`/san-pham/${product.id}`}
                className="product-card"
                style={{
                    display: "block",
                    borderRadius: "var(--radius-lg)",
                    overflow: "hidden",
                    background: "var(--bg-card)",
                    border: "1px solid var(--border-color)",
                    transition: "transform 0.35s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.35s cubic-bezier(0.16, 1, 0.3, 1), border-color 0.3s ease",
                    willChange: "transform",
                    textDecoration: "none",
                    color: "inherit",
                }}
                onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = "rgba(255,255,255,0.12)";
                    e.currentTarget.style.transform = "translateY(-2px)";
                    e.currentTarget.style.boxShadow =
                        "0 6px 16px rgba(0,0,0,0.25)";
                }}
                onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = "var(--border-color)";
                    e.currentTarget.style.transform = "translateY(0)";
                    e.currentTarget.style.boxShadow = "none";
                }}
            >
                {/* Image */}
                <div
                    className="product-img-wrap"
                    style={{
                        aspectRatio: "3/4",
                        background:
                            "linear-gradient(135deg, var(--bg-surface), var(--bg-elevated))",
                        position: "relative",
                        overflow: "hidden",
                    }}
                >
                    {imageUrl && (
                        <Image
                            src={imageUrl}
                            alt={product.name}
                            fill
                            style={{
                                objectFit: "cover",
                                opacity: 1,
                                transition:
                                    "opacity 0.4s ease, transform 0.5s cubic-bezier(0.16, 1, 0.3, 1)",
                            }}
                            sizes="(max-width: 768px) 50vw, (max-width: 1024px) 33vw, 25vw"
                            className="product-img-primary"
                        />
                    )}
                    {secondImage && (
                        <Image
                            src={secondImage}
                            alt={`${product.name} - 2`}
                            fill
                            style={{ objectFit: "cover", opacity: 0, transition: "opacity 0.4s ease" }}
                            sizes="(max-width: 768px) 50vw, (max-width: 1024px) 33vw, 25vw"
                            className="product-img-secondary"
                        />
                    )}
                    {/* Badges */}
                    <div style={{ position: "absolute", top: "var(--space-md)", left: "var(--space-md)", display: "flex", flexDirection: "column", gap: "6px", zIndex: 2 }}>
                        {product.stock <= 0 && (
                            <span style={{
                                padding: "5px 12px",
                                borderRadius: "var(--radius-sm)",
                                background: "var(--color-error, #EF4444)",
                                color: "#fff",
                                fontSize: "0.7rem",
                                fontWeight: 700,
                                letterSpacing: "0.05em",
                            }}>
                                HẾT HÀNG
                            </span>
                        )}
                        {badge && product.stock > 0 && (
                            <span style={{
                                padding: "5px 12px",
                                borderRadius: "var(--radius-sm)",
                                background: badge === "MỚI" ? "var(--color-accent)" : "var(--color-success)",
                                color: "var(--color-white)",
                                fontSize: "0.7rem",
                                fontWeight: 700,
                                letterSpacing: "0.05em",
                            }}>
                                {badge}
                            </span>
                        )}
                    </div>
                    {/* Out of stock overlay */}
                    {product.stock <= 0 && (
                        <div style={{
                            position: "absolute",
                            inset: 0,
                            background: "rgba(0,0,0,0.45)",
                            zIndex: 1,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                        }}>
                            <span style={{
                                padding: "8px 20px",
                                borderRadius: "var(--radius-md)",
                                background: "rgba(0,0,0,0.7)",
                                backdropFilter: "blur(4px)",
                                color: "#fff",
                                fontSize: "0.85rem",
                                fontWeight: 700,
                                letterSpacing: "0.1em",
                                textTransform: "uppercase",
                            }}>
                                Hết hàng
                            </span>
                        </div>
                    )}

                </div>
                <div style={{ padding: "var(--space-lg)" }}>
                    <p
                        style={{
                            fontSize: "0.72rem",
                            color: "rgba(156,163,175,0.9)",
                            marginBottom: "5px",
                            textTransform: "uppercase",
                            letterSpacing: "0.1em",
                            fontWeight: 500,
                        }}
                    >
                        {product.brandName || product.categoryName}
                    </p>
                    <h4
                        style={{
                            fontSize: "0.95rem",
                            fontWeight: 600,
                            color: "var(--text-primary)",
                            marginBottom: "var(--space-sm)",
                            lineHeight: 1.45,
                            display: "-webkit-box",
                            WebkitLineClamp: 2,
                            WebkitBoxOrient: "vertical",
                            overflow: "hidden",
                        }}
                    >
                        {product.name}
                    </h4>
                    <div
                        style={{
                            display: "flex",
                            alignItems: "baseline",
                            gap: "var(--space-sm)",
                        }}
                    >
                        <span
                            style={{
                                fontSize: "1.05rem",
                                fontWeight: 700,
                                color: product.stock <= 0 ? "var(--text-muted)" : "var(--color-accent)",
                            }}
                        >
                            {formatPrice(displayPrice)}
                        </span>
                        {originalPrice && (
                            <span
                                style={{
                                    fontSize: "0.78rem",
                                    color: "rgba(107,114,128,0.7)",
                                    textDecoration: "line-through",
                                }}
                            >
                                {formatPrice(originalPrice)}
                            </span>
                        )}
                    </div>
                    {/* Stock info */}
                    <p style={{
                        fontSize: "0.72rem",
                        fontWeight: 600,
                        marginTop: "4px",
                        color: product.stock <= 0
                            ? "var(--color-error, #EF4444)"
                            : product.stock <= 5
                                ? "#F59E0B"
                                : "var(--color-success, #10B981)",
                    }}>
                        {product.stock <= 0
                            ? "Hết hàng"
                            : product.stock <= 5
                                ? `Chỉ còn ${product.stock} sản phẩm`
                                : `Còn ${product.stock} sản phẩm`}
                    </p>
                </div>
            </Link>
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
                        "linear-gradient(90deg, var(--bg-surface) 25%, var(--bg-elevated) 50%, var(--bg-surface) 75%)",
                    backgroundSize: "200% 100%",
                    animation: "shimmer 1.5s infinite",
                }}
            />
            <div style={{ padding: "var(--space-lg)" }}>
                <div
                    style={{
                        height: "12px",
                        background: "var(--bg-surface)",
                        borderRadius: "4px",
                        marginBottom: "8px",
                        width: "60%",
                    }}
                />
                <div
                    style={{
                        height: "16px",
                        background: "var(--bg-surface)",
                        borderRadius: "4px",
                        marginBottom: "8px",
                    }}
                />
                <div
                    style={{
                        height: "14px",
                        background: "var(--bg-surface)",
                        borderRadius: "4px",
                        width: "40%",
                    }}
                />
            </div>
        </div>
    );
}

/* ─── Pagination ─── */
function Pagination({
    currentPage,
    totalPages,
    onPageChange,
}: {
    currentPage: number;
    totalPages: number;
    onPageChange: (page: number) => void;
}) {
    const ref = useReveal("up");
    if (totalPages <= 1) return null;

    const pages: (number | "...")[] = [];
    if (totalPages <= 7) {
        for (let i = 1; i <= totalPages; i++) pages.push(i);
    } else {
        pages.push(1);
        if (currentPage > 3) pages.push("...");
        for (
            let i = Math.max(2, currentPage - 1);
            i <= Math.min(totalPages - 1, currentPage + 1);
            i++
        ) {
            pages.push(i);
        }
        if (currentPage < totalPages - 2) pages.push("...");
        pages.push(totalPages);
    }

    const btnBase: React.CSSProperties = {
        minWidth: "40px",
        height: "40px",
        borderRadius: "var(--radius-md)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: "0.85rem",
        fontWeight: 600,
        transition: "all 0.25s ease",
        cursor: "pointer",
    };

    return (
        <div
            ref={ref}
            style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "var(--space-sm)",
                marginTop: "var(--space-3xl)",
            }}
        >
            {/* Prev */}
            <button
                disabled={currentPage === 1}
                onClick={() => onPageChange(currentPage - 1)}
                style={{
                    ...btnBase,
                    border: "1px solid var(--border-color)",
                    color:
                        currentPage === 1 ? "var(--text-muted)" : "var(--text-primary)",
                    opacity: currentPage === 1 ? 0.4 : 1,
                    cursor: currentPage === 1 ? "not-allowed" : "pointer",
                }}
                aria-label="Trang trước"
            >
                <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.5"
                >
                    <polyline points="15 18 9 12 15 6" />
                </svg>
            </button>

            {pages.map((page, i) =>
                page === "..." ? (
                    <span
                        key={`dots-${i}`}
                        style={{
                            ...btnBase,
                            color: "var(--text-muted)",
                            cursor: "default",
                        }}
                    >
                        …
                    </span>
                ) : (
                    <button
                        key={page}
                        onClick={() => onPageChange(page)}
                        style={{
                            ...btnBase,
                            border:
                                page === currentPage
                                    ? "1px solid var(--color-accent)"
                                    : "1px solid var(--border-color)",
                            background:
                                page === currentPage
                                    ? "var(--color-accent)"
                                    : "transparent",
                            color:
                                page === currentPage
                                    ? "var(--color-white)"
                                    : "var(--text-secondary)",
                            boxShadow:
                                page === currentPage
                                    ? "0 0 16px rgba(139,92,246,0.3)"
                                    : "none",
                        }}
                        onMouseEnter={(e) => {
                            if (page !== currentPage) {
                                e.currentTarget.style.borderColor = "var(--color-accent)";
                                e.currentTarget.style.color = "var(--color-accent)";
                            }
                        }}
                        onMouseLeave={(e) => {
                            if (page !== currentPage) {
                                e.currentTarget.style.borderColor = "var(--border-color)";
                                e.currentTarget.style.color = "var(--text-secondary)";
                            }
                        }}
                    >
                        {page}
                    </button>
                )
            )}

            {/* Next */}
            <button
                disabled={currentPage === totalPages}
                onClick={() => onPageChange(currentPage + 1)}
                style={{
                    ...btnBase,
                    border: "1px solid var(--border-color)",
                    color:
                        currentPage === totalPages
                            ? "var(--text-muted)"
                            : "var(--text-primary)",
                    opacity: currentPage === totalPages ? 0.4 : 1,
                    cursor: currentPage === totalPages ? "not-allowed" : "pointer",
                }}
                aria-label="Trang sau"
            >
                <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.5"
                >
                    <polyline points="9 18 15 12 9 6" />
                </svg>
            </button>
        </div>
    );
}

/* ─── Mobile Filter Drawer ─── */
function MobileFilterButton({
    isOpen,
    onToggle,
    activeCount,
}: {
    isOpen: boolean;
    onToggle: () => void;
    activeCount: number;
}) {
    return (
        <button
            onClick={onToggle}
            className="mobile-filter-btn"
            style={{
                display: "none",
                alignItems: "center",
                gap: "var(--space-sm)",
                padding: "10px 18px",
                borderRadius: "var(--radius-md)",
                border: "1px solid var(--border-color)",
                background: "var(--bg-card)",
                color: "var(--text-primary)",
                fontSize: "0.85rem",
                fontWeight: 600,
                transition: "all 0.2s",
            }}
        >
            <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
            >
                <line x1="4" y1="6" x2="20" y2="6" />
                <line x1="4" y1="12" x2="16" y2="12" />
                <line x1="4" y1="18" x2="12" y2="18" />
            </svg>
            {isOpen ? "Đóng bộ lọc" : "Bộ lọc"}
            {activeCount > 0 && (
                <span
                    style={{
                        width: "20px",
                        height: "20px",
                        borderRadius: "var(--radius-full)",
                        background: "var(--color-accent)",
                        color: "var(--color-white)",
                        fontSize: "0.65rem",
                        fontWeight: 700,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                    }}
                >
                    {activeCount}
                </span>
            )}
        </button>
    );
}

/* ─── Custom Sort Dropdown ─── */
function SortDropdown({
    value,
    onChange,
}: {
    value: SortOption;
    onChange: (v: SortOption) => void;
}) {
    const [open, setOpen] = useState(false);
    const dropdownRef = useRef<HTMLDivElement>(null);
    const currentLabel = SORT_OPTIONS.find((o) => o.value === value)?.label ?? "Mặc định";

    useEffect(() => {
        const handleClickOutside = (e: MouseEvent) => {
            if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
                setOpen(false);
            }
        };
        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
    }, []);

    return (
        <div ref={dropdownRef} style={{ position: "relative", zIndex: 10 }}>
            <button
                onClick={() => setOpen(!open)}
                style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "8px",
                    padding: "8px 14px",
                    borderRadius: "var(--radius-md)",
                    border: `1px solid ${open ? "var(--color-accent)" : "var(--border-color)"}`,
                    background: "var(--bg-card)",
                    color: "var(--text-primary)",
                    fontSize: "0.85rem",
                    fontWeight: 500,
                    cursor: "pointer",
                    transition: "border-color 0.2s",
                    whiteSpace: "nowrap",
                }}
                onMouseEnter={(e) => {
                    if (!open) e.currentTarget.style.borderColor = "rgba(139,92,246,0.4)";
                }}
                onMouseLeave={(e) => {
                    if (!open) e.currentTarget.style.borderColor = "var(--border-color)";
                }}
            >
                {currentLabel}
                <svg
                    width="14"
                    height="14"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.5"
                    style={{
                        transition: "transform 0.25s ease",
                        transform: open ? "rotate(180deg)" : "rotate(0deg)",
                        color: "var(--text-muted)",
                    }}
                >
                    <polyline points="6 9 12 15 18 9" />
                </svg>
            </button>

            {open && (
                <div
                    style={{
                        position: "absolute",
                        top: "calc(100% + 6px)",
                        right: 0,
                        minWidth: "160px",
                        borderRadius: "var(--radius-md)",
                        border: "1px solid var(--border-color)",
                        background: "var(--bg-card)",
                        boxShadow: "0 12px 32px rgba(0,0,0,0.4)",
                        overflow: "hidden",
                        animation: "fadeIn 0.15s ease",
                    }}
                >
                    {SORT_OPTIONS.map((opt) => (
                        <button
                            key={opt.value}
                            onClick={() => {
                                onChange(opt.value);
                                setOpen(false);
                            }}
                            style={{
                                display: "block",
                                width: "100%",
                                padding: "10px 16px",
                                fontSize: "0.85rem",
                                fontWeight: opt.value === value ? 600 : 400,
                                color: opt.value === value ? "var(--color-accent)" : "var(--text-secondary)",
                                background: opt.value === value ? "rgba(139,92,246,0.08)" : "transparent",
                                textAlign: "left",
                                cursor: "pointer",
                                transition: "all 0.15s ease",
                                borderBottom: "1px solid rgba(255,255,255,0.04)",
                            }}
                            onMouseEnter={(e) => {
                                if (opt.value !== value) {
                                    e.currentTarget.style.background = "rgba(255,255,255,0.04)";
                                    e.currentTarget.style.color = "var(--text-primary)";
                                }
                            }}
                            onMouseLeave={(e) => {
                                if (opt.value !== value) {
                                    e.currentTarget.style.background = "transparent";
                                    e.currentTarget.style.color = "var(--text-secondary)";
                                }
                            }}
                        >
                            {opt.label}
                        </button>
                    ))}
                </div>
            )}
        </div>
    );
}

/* ============================================================
   PAGE
   ============================================================ */

export default function MenPage() {
    /* ── State ── */
    const [allProducts, setAllProducts] = useState<Product[]>([]);
    const [categories, setCategories] = useState<Category[]>([]);
    const [brands, setBrands] = useState<Brand[]>([]);
    const [loading, setLoading] = useState(true);

    // Filters
    const [selectedCategories, setSelectedCategories] = useState<string[]>([]);
    const [selectedBrands, setSelectedBrands] = useState<string[]>([]);
    const [selectedPriceRange, setSelectedPriceRange] = useState<number | null>(
        null
    );
    const [selectedSizes, setSelectedSizes] = useState<string[]>([]);
    const [sortBy, setSortBy] = useState<SortOption>("default");
    const [currentPage, setCurrentPage] = useState(1);
    const [mobileFilterOpen, setMobileFilterOpen] = useState(false);

    const searchParams = useSearchParams();
    const danhMucParam = searchParams.get("danh-muc");

    const contentRef = useRef<HTMLDivElement>(null);

    /* ── Data fetch ── */
    const fetchData = useCallback(async () => {
        try {
            const [products, cats, brandList] = await Promise.all([
                getMaleProducts(),
                getMaleCategories(),
                getBrands(),
            ]);
            setAllProducts(products);
            setCategories(cats);
            setBrands(brandList);
        } catch (err) {
            console.error("Failed to fetch men's products:", err);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        window.scrollTo(0, 0);
        fetchData();
    }, [fetchData]);

    // Auto-select category from URL query param
    useEffect(() => {
        if (!danhMucParam) {
            setSelectedCategories([]);
            return;
        }
        if (categories.length === 0) return;
        const cat = categories.find((c) => c.id === danhMucParam);
        if (!cat) return;
        const isParent = !cat.parentId || cat.parentId === "";
        if (isParent) {
            const childIds = categories.filter((c) => c.parentId === danhMucParam).map((c) => c.id);
            setSelectedCategories([danhMucParam, ...childIds]);
        } else {
            setSelectedCategories([danhMucParam]);
        }
    }, [danhMucParam, categories]);

    /* ── Filter logic ── */
    const filteredProducts = useMemo(() => {
        let result = [...allProducts];

        // Category filter
        if (selectedCategories.length > 0) {
            // Expand parent categories to include their children
            const expandedCategoryIds = new Set<string>(selectedCategories);
            selectedCategories.forEach((catId) => {
                categories.forEach((c) => {
                    if (c.parentId === catId) {
                        expandedCategoryIds.add(c.id);
                    }
                });
            });
            result = result.filter((p) =>
                expandedCategoryIds.has(p.categoryId)
            );
        }

        // Brand filter
        if (selectedBrands.length > 0) {
            result = result.filter((p) => selectedBrands.includes(p.brandId));
        }

        // Price range filter
        if (selectedPriceRange !== null) {
            const range = PRICE_RANGES[selectedPriceRange];
            result = result.filter((p) => {
                const price =
                    p.salePrice > 0 && p.salePrice < p.price ? p.salePrice : p.price;
                return price >= range.min && price < range.max;
            });
        }

        // Size filter
        if (selectedSizes.length > 0) {
            result = result.filter((p) =>
                p.sizes.some((s) => selectedSizes.includes(s))
            );
        }

        // Sort
        switch (sortBy) {
            case "price-asc":
                result.sort((a, b) => {
                    const pa =
                        a.salePrice > 0 && a.salePrice < a.price
                            ? a.salePrice
                            : a.price;
                    const pb =
                        b.salePrice > 0 && b.salePrice < b.price
                            ? b.salePrice
                            : b.price;
                    return pa - pb;
                });
                break;
            case "price-desc":
                result.sort((a, b) => {
                    const pa =
                        a.salePrice > 0 && a.salePrice < a.price
                            ? a.salePrice
                            : a.price;
                    const pb =
                        b.salePrice > 0 && b.salePrice < b.price
                            ? b.salePrice
                            : b.price;
                    return pb - pa;
                });
                break;
            case "newest":
                result.sort(
                    (a, b) => b.createdAt.getTime() - a.createdAt.getTime()
                );
                break;
        }

        return result;
    }, [
        allProducts,
        categories,
        selectedCategories,
        selectedBrands,
        selectedPriceRange,
        selectedSizes,
        sortBy,
    ]);

    const totalPages = Math.ceil(filteredProducts.length / ITEMS_PER_PAGE);
    const paginatedProducts = filteredProducts.slice(
        (currentPage - 1) * ITEMS_PER_PAGE,
        currentPage * ITEMS_PER_PAGE
    );

    const toggleFilter = <T,>(
        arr: T[],
        value: T,
        setter: React.Dispatch<React.SetStateAction<T[]>>
    ) => {
        setter((prev) =>
            prev.includes(value)
                ? prev.filter((v) => v !== value)
                : [...prev, value]
        );
        setCurrentPage(1);
    };

    const toggleCategory = (id: string) => {
        const cat = categories.find((c) => c.id === id);
        if (!cat) return;

        const isParent = !cat.parentId || cat.parentId === "";
        setSelectedCategories((prev) => {
            let next = [...prev];

            if (isParent) {
                const childIds = categories.filter((c) => c.parentId === id).map((c) => c.id);
                const isSelected = prev.includes(id);
                if (isSelected) {
                    next = next.filter((cid) => cid !== id && !childIds.includes(cid));
                } else {
                    next = [...next, id, ...childIds.filter((cid) => !next.includes(cid))];
                }
            } else {
                const isSelected = prev.includes(id);
                if (isSelected) {
                    next = next.filter((cid) => cid !== id);
                    if (cat.parentId) {
                        next = next.filter((cid) => cid !== cat.parentId);
                    }
                } else {
                    next = [...next, id];
                    if (cat.parentId) {
                        const siblings = categories.filter((c) => c.parentId === cat.parentId);
                        const allSiblingsSelected = siblings.every((s) => s.id === id || next.includes(s.id));
                        if (allSiblingsSelected && !next.includes(cat.parentId)) {
                            next = [...next, cat.parentId];
                        }
                    }
                }
            }

            return next;
        });
        setCurrentPage(1);
    };

    const handlePageChange = (page: number) => {
        setCurrentPage(page);
        contentRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
    };

    const clearAllFilters = () => {
        setSelectedCategories([]);
        setSelectedBrands([]);
        setSelectedPriceRange(null);
        setSelectedSizes([]);
        setCurrentPage(1);
    };

    const activeFilterCount =
        selectedCategories.length +
        selectedBrands.length +
        (selectedPriceRange !== null ? 1 : 0) +
        selectedSizes.length;

    // Lock body scroll for mobile filter
    useEffect(() => {
        if (mobileFilterOpen) {
            document.body.style.overflow = "hidden";
        } else {
            document.body.style.overflow = "";
        }
        return () => {
            document.body.style.overflow = "";
        };
    }, [mobileFilterOpen]);

    return (
        <>
            <section
                ref={contentRef}
                id="products"
                className="section"
                style={{ paddingTop: "calc(var(--header-height) + var(--space-2xl))" }}
            >
                <div className="container">
                    {/* Mobile filter toggle */}
                    <MobileFilterButton
                        isOpen={mobileFilterOpen}
                        onToggle={() => setMobileFilterOpen(!mobileFilterOpen)}
                        activeCount={activeFilterCount}
                    />

                    <div
                        style={{
                            display: "grid",
                            gridTemplateColumns: "260px 1fr",
                            gap: "var(--space-2xl)",
                            alignItems: "start",
                        }}
                        className="men-layout"
                    >
                        {/* Sidebar */}
                        <div
                            className="filter-sidebar"
                            style={{
                                position: "sticky",
                                top: "calc(var(--header-height) + var(--space-lg))",
                            }}
                        >
                            <FilterSidebar
                                categories={categories}
                                brands={brands}
                                selectedCategories={selectedCategories}
                                selectedBrands={selectedBrands}
                                selectedPriceRange={selectedPriceRange}
                                selectedSizes={selectedSizes}
                                onToggleCategory={toggleCategory}
                                onToggleBrand={(id) =>
                                    toggleFilter(selectedBrands, id, setSelectedBrands)
                                }
                                onSetPriceRange={(idx) => {
                                    setSelectedPriceRange(idx);
                                    setCurrentPage(1);
                                }}
                                onToggleSize={(s) =>
                                    toggleFilter(selectedSizes, s, setSelectedSizes)
                                }
                                onClearAll={clearAllFilters}
                                totalResults={filteredProducts.length}
                            />
                        </div>

                        {/* Main content */}
                        <div>
                            {/* Sort bar */}
                            <div
                                style={{
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "space-between",
                                    marginBottom: "var(--space-xl)",
                                    flexWrap: "wrap",
                                    gap: "var(--space-md)",
                                }}
                            >
                                <p
                                    style={{
                                        fontSize: "0.85rem",
                                        color: "var(--text-muted)",
                                    }}
                                >
                                    Hiển thị{" "}
                                    <strong style={{ color: "var(--text-primary)" }}>
                                        {paginatedProducts.length}
                                    </strong>{" "}
                                    / {filteredProducts.length} sản phẩm
                                </p>
                                <SortDropdown
                                        value={sortBy}
                                        onChange={(v) => {
                                            setSortBy(v);
                                            setCurrentPage(1);
                                        }}
                                    />
                            </div>

                            {/* Products grid */}
                            {loading ? (
                                <div
                                    className="men-products-grid"
                                    style={{
                                        display: "grid",
                                        gridTemplateColumns: "repeat(3, 1fr)",
                                        gap: "var(--space-lg)",
                                    }}
                                >
                                    {[...Array(6)].map((_, i) => (
                                        <SkeletonCard key={i} />
                                    ))}
                                </div>
                            ) : paginatedProducts.length === 0 ? (
                                <div
                                    style={{
                                        textAlign: "center",
                                        padding: "var(--space-4xl) 0",
                                        color: "var(--text-muted)",
                                    }}
                                >
                                    <svg
                                        width="48"
                                        height="48"
                                        viewBox="0 0 24 24"
                                        fill="none"
                                        stroke="currentColor"
                                        strokeWidth="1.5"
                                        style={{ margin: "0 auto var(--space-lg)", opacity: 0.4 }}
                                    >
                                        <circle cx="11" cy="11" r="8" />
                                        <path d="M21 21l-4.35-4.35" />
                                    </svg>
                                    <p style={{ fontSize: "1rem", marginBottom: "var(--space-sm)" }}>
                                        Không tìm thấy sản phẩm phù hợp
                                    </p>
                                    <p style={{ fontSize: "0.85rem" }}>
                                        Hãy thử thay đổi bộ lọc hoặc{" "}
                                        <button
                                            onClick={clearAllFilters}
                                            style={{
                                                color: "var(--color-accent)",
                                                fontWeight: 600,
                                                textDecoration: "underline",
                                                cursor: "pointer",
                                            }}
                                        >
                                            xóa tất cả bộ lọc
                                        </button>
                                    </p>
                                </div>
                            ) : (
                                <div
                                    className="men-products-grid"
                                    style={{
                                        display: "grid",
                                        gridTemplateColumns: "repeat(3, 1fr)",
                                        gap: "var(--space-lg)",
                                    }}
                                >
                                    {paginatedProducts.map((product, i) => (
                                        <ProductCard
                                            key={product.id}
                                            product={product}
                                            index={i}
                                        />
                                    ))}
                                </div>
                            )}

                            {/* Pagination */}
                            {!loading && (
                                <Pagination
                                    currentPage={currentPage}
                                    totalPages={totalPages}
                                    onPageChange={handlePageChange}
                                />
                            )}
                        </div>
                    </div>
                </div>
            </section>

            {/* Mobile filter overlay */}
            {mobileFilterOpen && (
                <div
                    style={{
                        position: "fixed",
                        inset: 0,
                        zIndex: 998,
                        background: "rgba(0,0,0,0.6)",
                    }}
                    onClick={() => setMobileFilterOpen(false)}
                />
            )}

            {/* Mobile filter drawer */}
            <div
                className="mobile-filter-drawer"
                style={{
                    position: "fixed",
                    top: 0,
                    left: 0,
                    bottom: 0,
                    width: "300px",
                    zIndex: 999,
                    background: "var(--bg-secondary)",
                    borderRight: "1px solid var(--border-color)",
                    transform: mobileFilterOpen
                        ? "translateX(0)"
                        : "translateX(-100%)",
                    transition: "transform var(--transition-slow)",
                    padding: "var(--space-2xl) var(--space-lg)",
                    overflowY: "auto",
                }}
            >
                <div
                    style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        marginBottom: "var(--space-xl)",
                    }}
                >
                    <h3
                        style={{
                            fontSize: "1rem",
                            fontWeight: 700,
                            color: "var(--text-primary)",
                        }}
                    >
                        Bộ lọc
                    </h3>
                    <button
                        onClick={() => setMobileFilterOpen(false)}
                        style={{ color: "var(--text-secondary)", padding: "4px" }}
                    >
                        <svg
                            width="20"
                            height="20"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="2"
                        >
                            <line x1="18" y1="6" x2="6" y2="18" />
                            <line x1="6" y1="6" x2="18" y2="18" />
                        </svg>
                    </button>
                </div>
                <FilterSidebar
                    categories={categories}
                    brands={brands}
                    selectedCategories={selectedCategories}
                    selectedBrands={selectedBrands}
                    selectedPriceRange={selectedPriceRange}
                    selectedSizes={selectedSizes}
                    onToggleCategory={toggleCategory}
                    onToggleBrand={(id) =>
                        toggleFilter(selectedBrands, id, setSelectedBrands)
                    }
                    onSetPriceRange={(idx) => {
                        setSelectedPriceRange(idx);
                        setCurrentPage(1);
                    }}
                    onToggleSize={(s) =>
                        toggleFilter(selectedSizes, s, setSelectedSizes)
                    }
                    onClearAll={clearAllFilters}
                    totalResults={filteredProducts.length}
                />
            </div>

            {/* Scoped styles */}
            <style jsx global>{`
        .product-card:hover .product-img-primary {
          opacity: 0 !important;
        }
        .product-card:hover .product-img-secondary {
          opacity: 1 !important;
        }
        .product-card:hover .product-actions {
          opacity: 1 !important;
          transform: translateX(0) !important;
        }
        .product-card:hover .product-img-wrap img {
          transform: scale(1.06);
        }

        /* ── Responsive ── */
        @media (max-width: 1024px) {
          .men-products-grid {
            grid-template-columns: repeat(2, 1fr) !important;
          }
        }

        @media (max-width: 768px) {
          .men-layout {
            grid-template-columns: 1fr !important;
          }
          .filter-sidebar {
            display: none !important;
          }
          .mobile-filter-btn {
            display: inline-flex !important;
            margin-bottom: var(--space-lg);
          }
          .men-products-grid {
            grid-template-columns: repeat(2, 1fr) !important;
            gap: var(--space-md) !important;
          }
        }
      `}</style>
        </>
    );
}
