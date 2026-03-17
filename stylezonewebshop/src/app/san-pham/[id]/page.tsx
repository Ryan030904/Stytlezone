"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useState, useCallback, useMemo } from "react";
import { useParams, useRouter } from "next/navigation";
import { getProductById, getRelatedProducts } from "@/lib/products";
import { useCart, CartItem } from "@/components/CartProvider";
import { useWishlist } from "@/components/WishlistProvider";
import type { Product, ProductVariant, Review } from "@/lib/types";
import { toast } from "sonner";
import {
    getProductReviews,
    getRemainingReviews,
    submitReview,
    computeRatingStats,
} from "@/lib/reviews";

/* ═══════════════════════════════════════════════
   HELPERS
   ═══════════════════════════════════════════════ */

function formatPrice(price: number): string {
    return new Intl.NumberFormat("vi-VN").format(price) + "đ";
}

function isNew(product: Product): boolean {
    const twoWeeksAgo = new Date();
    twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);
    return product.createdAt >= twoWeeksAgo;
}

function getDiscountPercent(product: Product): number | null {
    if (product.salePrice > 0 && product.salePrice < product.price) {
        return Math.round((1 - product.salePrice / product.price) * 100);
    }
    return null;
}

/* ═══════════════════════════════════════════════
   SIZE CHART DATA
   ═══════════════════════════════════════════════ */

const SIZE_CHART_MEN = {
    headers: ["Size", "Ngực (cm)", "Eo (cm)", "Hông (cm)", "Vai (cm)"],
    rows: [
        ["S", "86–90", "72–76", "86–90", "42–44"],
        ["M", "90–94", "76–80", "90–94", "44–46"],
        ["L", "94–98", "80–84", "94–98", "46–48"],
        ["XL", "98–102", "84–88", "98–102", "48–50"],
        ["XXL", "102–108", "88–94", "102–108", "50–52"],
    ],
};

const SIZE_CHART_WOMEN = {
    headers: ["Size", "Ngực (cm)", "Eo (cm)", "Hông (cm)", "Vai (cm)"],
    rows: [
        ["S", "80–84", "62–66", "86–90", "36–38"],
        ["M", "84–88", "66–70", "90–94", "38–40"],
        ["L", "88–92", "70–74", "94–98", "40–42"],
        ["XL", "92–96", "74–78", "98–102", "42–44"],
        ["XXL", "96–102", "78–84", "102–108", "44–46"],
    ],
};

/* ═══════════════════════════════════════════════
   IMAGE GALLERY
   ═══════════════════════════════════════════════ */

function ImageGallery({ images, name }: { images: string[]; name: string }) {
    const [activeIndex, setActiveIndex] = useState(0);
    const [isZoomed, setIsZoomed] = useState(false);
    const [zoomPos, setZoomPos] = useState({ x: 50, y: 50 });

    // Reset to first image when images array changes (e.g. color switch)
    useEffect(() => {
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setActiveIndex(0);
         
        setIsZoomed(false);
    }, [images]);

    const handleMouseMove = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
        const rect = e.currentTarget.getBoundingClientRect();
        const x = ((e.clientX - rect.left) / rect.width) * 100;
        const y = ((e.clientY - rect.top) / rect.height) * 100;
        setZoomPos({ x, y });
    }, []);

    if (images.length === 0) {
        return (
            <div style={{
                aspectRatio: "3/4",
                background: "var(--bg-elevated)",
                borderRadius: "var(--radius-lg)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "var(--text-muted)",
                fontSize: "1rem",
            }}>
                Chưa có hình ảnh
            </div>
        );
    }

    return (
        <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
            {/* Main Image */}
            <div
                style={{
                    position: "relative",
                    flex: 1,
                    minHeight: "400px",
                    borderRadius: "var(--radius-lg)",
                    overflow: "hidden",
                    background: "var(--bg-elevated)",
                    cursor: isZoomed ? "zoom-out" : "zoom-in",
                    border: "1px solid var(--border-color)",
                }}
                onClick={() => setIsZoomed(!isZoomed)}
                onMouseMove={handleMouseMove}
                onMouseLeave={() => setIsZoomed(false)}
            >
                <Image
                    src={images[activeIndex]}
                    alt={`${name} - ${activeIndex + 1}`}
                    fill
                    style={{
                        objectFit: "cover",
                        transform: isZoomed ? "scale(2)" : "scale(1)",
                        transformOrigin: `${zoomPos.x}% ${zoomPos.y}%`,
                        transition: isZoomed ? "none" : "transform 0.3s ease",
                    }}
                    sizes="(max-width: 768px) 100vw, 50vw"
                    priority
                />
                {/* Discount badge */}
                {activeIndex === 0 && (
                    <div style={{
                        position: "absolute",
                        top: "var(--space-md)",
                        left: "var(--space-md)",
                        display: "flex",
                        gap: "6px",
                        zIndex: 2,
                    }}>
                        {/* Badges will be passed externally if needed */}
                    </div>
                )}
            </div>

            {/* Thumbnails */}
            {images.length > 1 && (
                <div style={{
                    display: "flex",
                    gap: "var(--space-sm)",
                    marginTop: "var(--space-md)",
                    overflowX: "auto",
                    paddingBottom: "4px",
                }}>
                    {images.map((img, i) => (
                        <button
                            key={i}
                            onClick={() => setActiveIndex(i)}
                            style={{
                                width: "72px",
                                height: "96px",
                                borderRadius: "var(--radius-md)",
                                overflow: "hidden",
                                border: i === activeIndex
                                    ? "2px solid var(--color-accent)"
                                    : "2px solid var(--border-color)",
                                opacity: i === activeIndex ? 1 : 0.6,
                                transition: "all 0.2s ease",
                                cursor: "pointer",
                                flexShrink: 0,
                                position: "relative",
                            }}
                            onMouseEnter={(e) => { if (i !== activeIndex) e.currentTarget.style.opacity = "0.85"; }}
                            onMouseLeave={(e) => { if (i !== activeIndex) e.currentTarget.style.opacity = "0.6"; }}
                        >
                            <Image
                                src={img}
                                alt={`${name} - thumb ${i + 1}`}
                                fill
                                style={{ objectFit: "cover" }}
                                sizes="72px"
                            />
                        </button>
                    ))}
                </div>
            )}
        </div>
    );
}

/* ═══════════════════════════════════════════════
   PRODUCT CARD (for related products)
   ═══════════════════════════════════════════════ */

function ProductCard({ product }: { product: Product }) {
    const displayPrice = product.salePrice > 0 && product.salePrice < product.price ? product.salePrice : product.price;
    const originalPrice = product.salePrice > 0 && product.salePrice < product.price ? product.price : null;
    const imageUrl = product.images.length > 0 ? product.images[0] : null;

    return (
        <Link
            href={`/san-pham/${product.id}`}
            className="product-card"
            style={{
                display: "block",
                borderRadius: "var(--radius-lg)",
                overflow: "hidden",
                background: "var(--bg-card)",
                border: "1px solid var(--border-color)",
                transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
                textDecoration: "none",
                color: "inherit",
            }}
            onMouseEnter={(e) => {
                e.currentTarget.style.transform = "translateY(-4px)";
                e.currentTarget.style.boxShadow = "0 12px 28px rgba(0,0,0,0.4), 0 0 12px rgba(139,92,246,0.06)";
            }}
            onMouseLeave={(e) => {
                e.currentTarget.style.transform = "translateY(0)";
                e.currentTarget.style.boxShadow = "none";
            }}
        >
            <div style={{ aspectRatio: "3/4", position: "relative", overflow: "hidden", background: "var(--bg-elevated)" }}>
                {imageUrl && (
                    <Image src={imageUrl} alt={product.name} fill style={{ objectFit: "cover" }} sizes="(max-width: 768px) 50vw, 25vw" />
                )}
                {/* Out of stock badge + overlay */}
                {product.stock <= 0 && (
                    <>
                        <span style={{
                            position: "absolute", top: "var(--space-md)", left: "var(--space-md)",
                            padding: "5px 12px", borderRadius: "var(--radius-sm)",
                            background: "var(--color-error, #EF4444)", color: "#fff",
                            fontSize: "0.7rem", fontWeight: 700, letterSpacing: "0.05em", zIndex: 2,
                        }}>
                            HẾT HÀNG
                        </span>
                        <div style={{
                            position: "absolute", inset: 0, background: "rgba(0,0,0,0.45)", zIndex: 1,
                            display: "flex", alignItems: "center", justifyContent: "center",
                        }}>
                            <span style={{
                                padding: "8px 20px", borderRadius: "var(--radius-md)",
                                background: "rgba(0,0,0,0.7)", backdropFilter: "blur(4px)",
                                color: "#fff", fontSize: "0.85rem", fontWeight: 700,
                                letterSpacing: "0.1em", textTransform: "uppercase",
                            }}>
                                Hết hàng
                            </span>
                        </div>
                    </>
                )}
            </div>
            <div style={{ padding: "var(--space-lg)" }}>
                <p style={{ fontSize: "0.7rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: "4px" }}>
                    {product.brandName || product.categoryName}
                </p>
                <h4 style={{ fontSize: "0.9rem", fontWeight: 500, color: "var(--text-primary)", marginBottom: "var(--space-sm)", lineHeight: 1.4, display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
                    {product.name}
                </h4>
                <div style={{ display: "flex", alignItems: "center", gap: "var(--space-sm)" }}>
                    <span style={{ fontSize: "1rem", fontWeight: 700, color: product.stock <= 0 ? "var(--text-muted)" : "var(--color-accent)" }}>{formatPrice(displayPrice)}</span>
                    {originalPrice && <span style={{ fontSize: "0.8rem", color: "var(--text-muted)", textDecoration: "line-through" }}>{formatPrice(originalPrice)}</span>}
                </div>
                {/* Stock info */}
                <p style={{
                    fontSize: "0.72rem", fontWeight: 600, marginTop: "4px",
                    color: product.stock <= 0 ? "var(--color-error, #EF4444)" : product.stock <= 5 ? "#F59E0B" : "var(--color-success, #10B981)",
                }}>
                    {product.stock <= 0 ? "Hết hàng" : product.stock <= 5 ? `Chỉ còn ${product.stock} sản phẩm` : `Còn ${product.stock} sản phẩm`}
                </p>
            </div>
        </Link>
    );
}

/* ═══════════════════════════════════════════════
   REVIEWS SECTION
   ═══════════════════════════════════════════════ */

function ReviewsSection({ product }: { product: Product }) {
    const { user } = useCart();
    const [reviews, setReviews] = useState<Review[]>([]);
    const [loading, setLoading] = useState(true);
    const [remaining, setRemaining] = useState(0);
    const [rating, setRating] = useState(5);
    const [hoverRating, setHoverRating] = useState(0);
    const [comment, setComment] = useState("");
    const [imageFiles, setImageFiles] = useState<File[]>([]);
    const [imagePreviews, setImagePreviews] = useState<string[]>([]);
    const [submitting, setSubmitting] = useState(false);
    const [cooldown, setCooldown] = useState(false);

    // Fetch reviews + check remaining review quota
    useEffect(() => {
        let cancelled = false;
        (async () => {
            try {
                setLoading(true);
                const fetched = await getProductReviews(product.id);
                if (!cancelled) setReviews(fetched);
                if (user?.email) {
                    const rem = await getRemainingReviews(
                        user.email,
                        user.uid,
                        product.id
                    );
                    if (!cancelled) setRemaining(rem);
                }
            } catch (err) {
                console.error("Failed to load reviews:", err);
            } finally {
                if (!cancelled) setLoading(false);
            }
        })();
        return () => { cancelled = true; };
    }, [product.id, user]);

    const stats = useMemo(() => computeRatingStats(reviews), [reviews]);

    const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = Array.from(e.target.files ?? []);
        const newFiles = [...imageFiles, ...files].slice(0, 3);
        setImageFiles(newFiles);
        setImagePreviews(newFiles.map((f) => URL.createObjectURL(f)));
    };

    const removeImage = (index: number) => {
        setImageFiles((prev) => prev.filter((_, i) => i !== index));
        setImagePreviews((prev) => prev.filter((_, i) => i !== index));
    };

    const handleSubmit = async () => {
        if (!user) return;
        if (comment.trim().length < 50) {
            toast.error("Bình luận phải có ít nhất 50 ký tự");
            return;
        }
        if (remaining <= 0) {
            toast.error("Bạn đã hết lượt đánh giá cho sản phẩm này");
            return;
        }

        setSubmitting(true);
        try {
            await submitReview({
                productId: product.id,
                productName: product.name,
                productImage: product.images?.[0] ?? "",
                customerId: user.uid,
                customerName: user.displayName || user.email || "Ẩn danh",
                customerAvatar: user.photoURL || "",
                rating,
                comment: comment.trim(),
                imageFiles,
            });

            toast.success("Đánh giá thành công! 🎉");
            setComment("");
            setRating(5);
            setImageFiles([]);
            setImagePreviews([]);
            setRemaining((prev) => prev - 1);

            // Refresh reviews
            const updated = await getProductReviews(product.id);
            setReviews(updated);

            // Cooldown 30s
            setCooldown(true);
            setTimeout(() => setCooldown(false), 30000);
        } catch (err) {
            console.error("Submit review error:", err);
            toast.error("Gửi đánh giá thất bại, vui lòng thử lại");
        } finally {
            setSubmitting(false);
        }
    };

    const renderStars = (value: number, size = 16) => (
        <div style={{ display: "flex", gap: "2px" }}>
            {[1, 2, 3, 4, 5].map((s) => (
                <svg key={s} width={size} height={size} viewBox="0 0 24 24"
                    fill={s <= value ? "#FFC107" : "none"}
                    stroke={s <= value ? "#FFC107" : "var(--text-muted)"}
                    strokeWidth="1.5"
                >
                    <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                </svg>
            ))}
        </div>
    );

    if (loading) {
        return (
            <div style={{ textAlign: "center", padding: "var(--space-3xl)", color: "var(--text-muted)" }}>
                Đang tải đánh giá...
            </div>
        );
    }

    return (
        <div style={{ animation: "fadeIn 0.3s ease" }}>
            {/* ─── Rating Overview (Shopee-style compact bar) ─── */}
            <div style={{
                display: "flex",
                alignItems: "center",
                gap: "var(--space-xl)",
                padding: "20px 24px",
                background: "rgba(139,92,246,0.03)",
                border: "1px solid rgba(139,92,246,0.1)",
                borderRadius: "var(--radius-lg)",
                marginBottom: "var(--space-xl)",
            }}>
                {/* Score */}
                <div style={{ textAlign: "center", minWidth: "100px" }}>
                    <div style={{ display: "flex", alignItems: "baseline", justifyContent: "center", gap: "4px" }}>
                        <span style={{ fontSize: "2.2rem", fontWeight: 800, color: "var(--color-accent)", lineHeight: 1 }}>
                            {stats.total > 0 ? stats.average.toFixed(1) : "0"}
                        </span>
                        <span style={{ fontSize: "1rem", color: "var(--text-muted)", fontWeight: 500 }}>/5</span>
                    </div>
                    <div style={{ margin: "6px 0 2px" }}>{renderStars(stats.total > 0 ? Math.round(stats.average) : 0, 16)}</div>
                    <p style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>{stats.total} đánh giá</p>
                </div>

                {/* Distribution bars */}
                {stats.total > 0 && (
                    <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: "3px", maxWidth: "300px" }}>
                        {[5, 4, 3, 2, 1].map((star) => {
                            const count = stats.distribution[star - 1];
                            const pct = stats.total > 0 ? (count / stats.total) * 100 : 0;
                            return (
                                <div key={star} style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                                    <span style={{ fontSize: "0.68rem", color: "var(--text-muted)", width: "8px" }}>{star}</span>
                                    <svg width="10" height="10" viewBox="0 0 24 24" fill="#FFC107" stroke="none">
                                        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                                    </svg>
                                    <div style={{ flex: 1, height: "6px", borderRadius: "3px", background: "var(--bg-tertiary)", overflow: "hidden" }}>
                                        <div style={{ height: "100%", width: `${pct}%`, borderRadius: "3px", background: "#FFC107", transition: "width 0.4s ease" }} />
                                    </div>
                                    <span style={{ fontSize: "0.65rem", color: "var(--text-muted)", width: "18px", textAlign: "right" }}>{count}</span>
                                </div>
                            );
                        })}
                    </div>
                )}

                {/* Write review CTA (if no form shown inline) */}
                {stats.total === 0 && (
                    <div style={{ flex: 1, textAlign: "center" }}>
                        <p style={{ fontSize: "0.85rem", color: "var(--text-muted)", marginBottom: "0" }}>
                            Chưa có đánh giá — Hãy là người đầu tiên!
                        </p>
                    </div>
                )}
            </div>

            {/* ─── Write Review Section ─── */}
            <div style={{
                padding: "16px 20px",
                borderRadius: "var(--radius-lg)",
                border: "1px solid var(--border-color)",
                background: "var(--bg-card)",
                marginBottom: "var(--space-xl)",
            }}>
                {!user ? (
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                        <span style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>Đăng nhập để đánh giá sản phẩm</span>
                        <a href="/dang-nhap" style={{
                            padding: "8px 20px",
                            borderRadius: "var(--radius-full)",
                            background: "var(--color-accent)",
                            color: "#fff",
                            fontSize: "0.8rem",
                            fontWeight: 600,
                            textDecoration: "none",
                            transition: "opacity 0.2s",
                        }}>
                            Đăng nhập
                        </a>
                    </div>
                ) : remaining <= 0 ? (
                    <div style={{ display: "flex", alignItems: "center", gap: "8px", color: "var(--text-muted)", fontSize: "0.85rem" }}>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                            <circle cx="12" cy="12" r="10" /><path d="M12 8v4M12 16h.01" />
                        </svg>
                        Bạn đã hết lượt đánh giá. Mua hàng để có thêm lượt.
                    </div>
                ) : (
                    <>
                        {/* Header row: title + star selector inline */}
                        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "12px" }}>
                            <span style={{ fontSize: "0.9rem", fontWeight: 700, color: "var(--text-primary)" }}>Viết đánh giá</span>
                            <div style={{ display: "flex", alignItems: "center", gap: "2px" }}>
                                {[1, 2, 3, 4, 5].map((s) => (
                                    <button
                                        key={s}
                                        type="button"
                                        onClick={() => setRating(s)}
                                        onMouseEnter={() => setHoverRating(s)}
                                        onMouseLeave={() => setHoverRating(0)}
                                        style={{
                                            background: "none", border: "none", cursor: "pointer", padding: "2px",
                                            transition: "transform 0.15s",
                                            transform: s <= (hoverRating || rating) ? "scale(1.15)" : "scale(1)",
                                        }}
                                    >
                                        <svg width="22" height="22" viewBox="0 0 24 24"
                                            fill={s <= (hoverRating || rating) ? "#FFC107" : "none"}
                                            stroke={s <= (hoverRating || rating) ? "#FFC107" : "var(--text-muted)"}
                                            strokeWidth="1.5"
                                        >
                                            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                                        </svg>
                                    </button>
                                ))}
                                <span style={{ fontSize: "0.78rem", fontWeight: 600, color: "var(--text-primary)", marginLeft: "6px" }}>
                                    {hoverRating || rating}/5
                                </span>
                            </div>
                        </div>

                        {/* Comment textarea */}
                        <textarea
                            value={comment}
                            onChange={(e) => setComment(e.target.value)}
                            placeholder="Chia sẻ trải nghiệm của bạn về sản phẩm này... (tối thiểu 50 ký tự)"
                            rows={3}
                            style={{
                                width: "100%",
                                padding: "10px 12px",
                                borderRadius: "var(--radius-md)",
                                border: "1px solid var(--border-color)",
                                background: "var(--bg-surface)",
                                color: "var(--text-primary)",
                                fontSize: "0.85rem",
                                resize: "vertical",
                                outline: "none",
                                transition: "border-color 0.2s",
                                minHeight: "80px",
                            }}
                            onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; }}
                            onBlur={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; }}
                        />

                        {/* Bottom row: char count + images + submit */}
                        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: "10px", flexWrap: "wrap", gap: "8px" }}>
                            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                                {/* Image previews */}
                                {imagePreviews.map((src, i) => (
                                    <div key={i} style={{ position: "relative", width: "40px", height: "40px", borderRadius: "6px", overflow: "hidden", border: "1px solid var(--border-color)" }}>
                                        <Image src={src} alt="" fill style={{ objectFit: "cover" }} />
                                        <button
                                            onClick={() => removeImage(i)}
                                            style={{
                                                position: "absolute", top: "1px", right: "1px",
                                                width: "16px", height: "16px", borderRadius: "50%",
                                                background: "rgba(0,0,0,0.6)", border: "none",
                                                color: "#fff", cursor: "pointer", fontSize: "10px",
                                                display: "flex", alignItems: "center", justifyContent: "center",
                                                lineHeight: 1,
                                            }}
                                        >×</button>
                                    </div>
                                ))}
                                {/* Upload button */}
                                {imageFiles.length < 3 && (
                                    <label style={{
                                        display: "flex", alignItems: "center", gap: "4px",
                                        cursor: "pointer", color: "var(--text-muted)", fontSize: "0.78rem",
                                        padding: "6px 10px", borderRadius: "6px",
                                        border: "1px dashed var(--border-color)",
                                        transition: "border-color 0.2s, color 0.2s",
                                    }}
                                        onMouseEnter={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.color = "var(--color-accent)"; }}
                                        onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.color = "var(--text-muted)"; }}
                                    >
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                            <rect x="3" y="3" width="18" height="18" rx="2" ry="2" /><circle cx="8.5" cy="8.5" r="1.5" /><path d="M21 15l-5-5L5 21" />
                                        </svg>
                                        Ảnh ({imageFiles.length}/3)
                                        <input type="file" accept="image/*" multiple hidden onChange={handleImageSelect} />
                                    </label>
                                )}
                                <span style={{ fontSize: "0.7rem", color: comment.length >= 50 ? "var(--color-success)" : "var(--text-muted)" }}>
                                    {comment.length}/50
                                </span>
                            </div>

                            <button
                                onClick={handleSubmit}
                                disabled={submitting || cooldown || comment.trim().length < 50}
                                style={{
                                    padding: "8px 24px",
                                    borderRadius: "var(--radius-full)",
                                    background: (submitting || cooldown || comment.trim().length < 50)
                                        ? "var(--bg-tertiary)"
                                        : "var(--color-accent)",
                                    color: (submitting || cooldown || comment.trim().length < 50) ? "var(--text-muted)" : "#fff",
                                    fontSize: "0.82rem",
                                    fontWeight: 600,
                                    border: "none",
                                    cursor: (submitting || cooldown || comment.trim().length < 50) ? "not-allowed" : "pointer",
                                    transition: "all 0.2s ease",
                                }}
                            >
                                {submitting ? "Đang gửi..." : cooldown ? "Chờ 30s..." : "Gửi đánh giá"}
                            </button>
                        </div>
                    </>
                )}
            </div>

            {/* ─── Reviews List ─── */}
            {reviews.length > 0 && (
                <div>
                    {reviews.map((review, idx) => (
                        <div key={review.id} style={{
                            padding: "16px 0",
                            borderBottom: idx < reviews.length - 1 ? "1px solid var(--border-color)" : "none",
                        }}>
                            {/* Top: Avatar + Name + Stars + Date */}
                            <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "8px" }}>
                                <div style={{
                                    width: "32px", height: "32px", borderRadius: "50%",
                                    background: review.customerAvatar ? "transparent" : "rgba(139,92,246,0.1)",
                                    display: "flex", alignItems: "center", justifyContent: "center",
                                    overflow: "hidden", flexShrink: 0,
                                }}>
                                    {review.customerAvatar ? (
                                        <Image src={review.customerAvatar} alt="" width={32} height={32} style={{ objectFit: "cover", borderRadius: "50%" }} />
                                    ) : (
                                        <span style={{ fontSize: "0.75rem", fontWeight: 700, color: "var(--color-accent)" }}>
                                            {review.customerName?.charAt(0)?.toUpperCase() || "?"}
                                        </span>
                                    )}
                                </div>
                                <div style={{ flex: 1, minWidth: 0 }}>
                                    <div style={{ display: "flex", alignItems: "center", gap: "8px", flexWrap: "wrap" }}>
                                        <span style={{ fontSize: "0.82rem", fontWeight: 600, color: "var(--text-primary)" }}>{review.customerName}</span>
                                        {renderStars(review.rating, 12)}
                                    </div>
                                    <span style={{ fontSize: "0.68rem", color: "var(--text-muted)" }}>
                                        {new Date(review.createdAt).toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit", year: "numeric" })}
                                    </span>
                                </div>
                            </div>

                            {/* Comment */}
                            <p style={{ fontSize: "0.85rem", color: "var(--text-secondary)", lineHeight: 1.65, margin: "0 0 0 42px" }}>
                                {review.comment}
                            </p>

                            {/* Review images */}
                            {review.images.length > 0 && (
                                <div style={{ display: "flex", gap: "6px", margin: "8px 0 0 42px" }}>
                                    {review.images.map((img, i) => (
                                        <div key={i} style={{ width: "56px", height: "56px", borderRadius: "6px", overflow: "hidden", border: "1px solid var(--border-color)", cursor: "pointer" }}>
                                            <Image src={img} alt="" width={56} height={56} style={{ objectFit: "cover" }} />
                                        </div>
                                    ))}
                                </div>
                            )}

                            {/* Admin reply */}
                            {review.adminReply && (
                                <div style={{
                                    margin: "10px 0 0 42px",
                                    padding: "10px 12px",
                                    borderRadius: "8px",
                                    background: "rgba(139,92,246,0.04)",
                                    borderLeft: "2px solid var(--color-accent)",
                                }}>
                                    <div style={{ display: "flex", alignItems: "center", gap: "4px", marginBottom: "3px" }}>
                                        <span style={{ fontSize: "0.72rem", fontWeight: 700, color: "var(--color-accent)" }}>Phản hồi từ cửa hàng</span>
                                        {review.adminReplyAt && (
                                            <span style={{ fontSize: "0.65rem", color: "var(--text-muted)" }}>
                                                · {new Date(review.adminReplyAt).toLocaleDateString("vi-VN")}
                                            </span>
                                        )}
                                    </div>
                                    <p style={{ fontSize: "0.82rem", color: "var(--text-secondary)", lineHeight: 1.55, margin: 0 }}>
                                        {review.adminReply}
                                    </p>
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}

/* ═══════════════════════════════════════════════
   TABS COMPONENT
   ═══════════════════════════════════════════════ */

type TabKey = "description" | "size-guide" | "reviews";

function ProductTabs({ product }: { product: Product }) {
    const [activeTab, setActiveTab] = useState<TabKey>("description");

    const tabs: { key: TabKey; label: string }[] = [
        { key: "description", label: "Mô Tả" },
        { key: "size-guide", label: "Hướng Dẫn Chọn Size" },
        { key: "reviews", label: "Đánh Giá" },
    ];

    const sizeChart = product.gender === "female" ? SIZE_CHART_WOMEN : SIZE_CHART_MEN;

    return (
        <div>
            {/* Tab Headers */}
            <div style={{
                display: "flex",
                gap: "var(--space-sm)",
                borderBottom: "1px solid var(--border-color)",
                marginBottom: "var(--space-xl)",
                overflowX: "auto",
                overflowY: "hidden",
            }}>
                {tabs.map((tab) => (
                    <button
                        key={tab.key}
                        onClick={() => setActiveTab(tab.key)}
                        style={{
                            display: "inline-flex",
                            alignItems: "center",
                            gap: "var(--space-sm)",
                            padding: "var(--space-md) var(--space-lg)",
                            fontSize: "0.88rem",
                            fontWeight: activeTab === tab.key ? 700 : 500,
                            color: activeTab === tab.key ? "var(--color-accent)" : "var(--text-secondary)",
                            borderBottom: activeTab === tab.key ? "2px solid var(--color-accent)" : "2px solid transparent",
                            transition: "all 0.2s ease",
                            whiteSpace: "nowrap",
                            background: "transparent",
                            cursor: "pointer",
                            marginBottom: "-1px",
                        }}
                        onMouseEnter={(e) => { if (activeTab !== tab.key) e.currentTarget.style.color = "var(--text-primary)"; }}
                        onMouseLeave={(e) => { if (activeTab !== tab.key) e.currentTarget.style.color = "var(--text-secondary)"; }}
                    >
                        {tab.label}
                    </button>
                ))}
            </div>

            {/* Tab Content */}
            <div style={{ minHeight: "200px" }}>
                {/* ─── Mô Tả ─── */}
                {activeTab === "description" && (
                    <div style={{ animation: "fadeIn 0.3s ease" }}>
                        {product.description ? (
                            <div style={{
                                color: "var(--text-secondary)",
                                fontSize: "0.95rem",
                                lineHeight: 1.8,
                                whiteSpace: "pre-line",
                            }}>
                                {product.description}
                            </div>
                        ) : (
                            <p style={{ color: "var(--text-muted)", fontStyle: "italic" }}>
                                Chưa có mô tả cho sản phẩm này.
                            </p>
                        )}

                        {/* Product specs */}
                        <div style={{
                            display: "grid",
                            gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
                            gap: "var(--space-md)",
                            marginTop: "var(--space-xl)",
                            padding: "var(--space-xl)",
                            background: "var(--bg-elevated)",
                            borderRadius: "var(--radius-lg)",
                            border: "1px solid var(--border-color)",
                        }}>
                            {product.brandName && (
                                <div>
                                    <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.08em" }}>Thương hiệu</span>
                                    <p style={{ fontSize: "0.95rem", color: "var(--text-primary)", fontWeight: 600, marginTop: "4px" }}>{product.brandName}</p>
                                </div>
                            )}
                            {product.categoryName && (
                                <div>
                                    <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.08em" }}>Danh mục</span>
                                    <p style={{ fontSize: "0.95rem", color: "var(--text-primary)", fontWeight: 600, marginTop: "4px" }}>{product.categoryName}</p>
                                </div>
                            )}
                            <div>
                                <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.08em" }}>Giới tính</span>
                                <p style={{ fontSize: "0.95rem", color: "var(--text-primary)", fontWeight: 600, marginTop: "4px" }}>
                                    {product.gender === "male" ? "Nam" : product.gender === "female" ? "Nữ" : "Unisex"}
                                </p>
                            </div>
                            <div>
                                <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.08em" }}>Tình trạng</span>
                                <p style={{
                                    fontSize: "0.95rem", fontWeight: 600, marginTop: "4px",
                                    color: product.stock <= 0
                                        ? "var(--color-error)"
                                        : product.stock <= 5
                                            ? "#F59E0B"
                                            : "var(--color-success)",
                                }}>
                                    {product.stock <= 0
                                        ? "Hết hàng"
                                        : product.stock <= 5
                                            ? `Sắp hết hàng (còn ${product.stock})`
                                            : `Còn hàng (${product.stock})`}
                                </p>
                            </div>
                        </div>
                    </div>
                )}

                {/* ─── Hướng Dẫn Size ─── */}
                {activeTab === "size-guide" && (
                    <div style={{ animation: "fadeIn 0.3s ease" }}>
                        <p style={{ color: "var(--text-secondary)", fontSize: "0.9rem", marginBottom: "var(--space-lg)", lineHeight: 1.7 }}>
                            Bảng size tham khảo cho {product.gender === "female" ? "nữ" : "nam"}. Để chọn size chính xác, vui lòng đo số đo cơ thể và so sánh với bảng dưới đây.
                        </p>
                        <div style={{ overflowX: "auto" }}>
                            <table style={{
                                width: "100%",
                                borderCollapse: "collapse",
                                fontSize: "0.88rem",
                            }}>
                                <thead>
                                    <tr>
                                        {sizeChart.headers.map((h) => (
                                            <th key={h} style={{
                                                padding: "12px 16px",
                                                textAlign: "left",
                                                fontWeight: 700,
                                                fontSize: "0.8rem",
                                                letterSpacing: "0.05em",
                                                textTransform: "uppercase",
                                                color: "var(--color-accent)",
                                                borderBottom: "2px solid var(--color-accent)",
                                                background: "rgba(139,92,246,0.05)",
                                                whiteSpace: "nowrap",
                                            }}>
                                                {h}
                                            </th>
                                        ))}
                                    </tr>
                                </thead>
                                <tbody>
                                    {sizeChart.rows.map((row, i) => (
                                        <tr key={i} style={{ background: i % 2 === 0 ? "transparent" : "var(--bg-elevated)" }}>
                                            {row.map((cell, j) => (
                                                <td key={j} style={{
                                                    padding: "12px 16px",
                                                    borderBottom: "1px solid var(--border-color)",
                                                    color: j === 0 ? "var(--text-primary)" : "var(--text-secondary)",
                                                    fontWeight: j === 0 ? 700 : 400,
                                                    whiteSpace: "nowrap",
                                                }}>
                                                    {cell}
                                                </td>
                                            ))}
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>

                        {/* Measurement tips */}
                        <div style={{
                            marginTop: "var(--space-xl)",
                            padding: "var(--space-lg)",
                            background: "rgba(139,92,246,0.05)",
                            border: "1px solid rgba(139,92,246,0.1)",
                            borderRadius: "var(--radius-lg)",
                        }}>
                            <h4 style={{ fontSize: "0.88rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "var(--space-md)" }}>
                                Mẹo chọn size
                            </h4>
                            <ul style={{ color: "var(--text-secondary)", fontSize: "0.88rem", lineHeight: 1.8, paddingLeft: "var(--space-lg)", listStyleType: "disc" }}>
                                <li>Nếu bạn nằm giữa hai size, nên chọn size lớn hơn để thoải mái hơn.</li>
                                <li>Đo cơ thể khi mặc đồ lót mỏng để có kết quả chính xác nhất.</li>
                                <li>Mỗi thương hiệu có thể có sai lệch 1-2 cm, đây là bảng size tham khảo.</li>
                                <li>Nếu không chắc chắn, hãy liên hệ hotline để được tư vấn.</li>
                            </ul>
                        </div>
                    </div>
                )}

                {/* ─── Đánh Giá ─── */}
                {activeTab === "reviews" && (
                    <ReviewsSection product={product} />
                )}
            </div>
        </div>
    );
}

/* ═══════════════════════════════════════════════
   MAIN PAGE COMPONENT
   ═══════════════════════════════════════════════ */

export default function ProductDetailPage() {
    const params = useParams();
    const router = useRouter();
    const { addToCart, user } = useCart();
    const { toggleWishlist, isInWishlist } = useWishlist();

    const [product, setProduct] = useState<Product | null>(null);
    const [relatedProducts, setRelatedProducts] = useState<Product[]>([]);
    const [loading, setLoading] = useState(true);

    // Selection state
    const [selectedColor, setSelectedColor] = useState<string>("");
    const [selectedSize, setSelectedSize] = useState<string>("");
    const [quantity, setQuantity] = useState(1);
    const [addedToCart, setAddedToCart] = useState(false);

    const productId = typeof params.id === "string" ? params.id : "";

    // Reset state when navigating to a different product
    useEffect(() => {
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setProduct(null);
         
        setRelatedProducts([]);
         
        setSelectedColor("");
         
        setSelectedSize("");
         
        setQuantity(1);
         
        setAddedToCart(false);
         
        setLoading(true);

        if (!productId) return;
        getProductById(productId).then((p) => {
            if (!p) {
                router.replace("/404");
                return;
            }
            setProduct(p);
            if (p.colors.length > 0) setSelectedColor(p.colors[0]);
            if (p.sizes.length > 0) setSelectedSize(p.sizes[0]);
            setLoading(false);
            getRelatedProducts(p).then(setRelatedProducts);
        });
    }, [productId, router]);

    // Unique colors/sizes from variants
    const availableColors = useMemo(() => {
        if (!product) return [];
        if (product.variants.length > 0) {
            const colorMap = new Map<string, { color: string; colorHex?: string }>();
            product.variants.forEach((v) => {
                if (v.color && !colorMap.has(v.color)) {
                    colorMap.set(v.color, { color: v.color, colorHex: v.colorHex });
                }
            });
            return Array.from(colorMap.values());
        }
        return product.colors.map((c) => ({ color: c, colorHex: c.startsWith("#") ? c : undefined }));
    }, [product]);

    const availableSizes = useMemo(() => {
        if (!product) return [];
        if (product.variants.length > 0 && selectedColor) {
            const sizes = product.variants
                .filter((v) => v.color === selectedColor)
                .map((v) => ({ size: v.size, stock: v.stock }));
            return sizes;
        }
        return product.sizes.map((s) => ({ size: s, stock: product.stock }));
    }, [product, selectedColor]);

    // Get current variant stock
    const currentVariant = useMemo<ProductVariant | undefined>(() => {
        if (!product || product.variants.length === 0) return undefined;
        return product.variants.find(
            (v) => v.color === selectedColor && v.size === selectedSize
        );
    }, [product, selectedColor, selectedSize]);

    // Images for the selected color
    const displayImages = useMemo(() => {
        if (!product) return [];
        if (product.variants.length > 0 && selectedColor) {
            const colorImages = product.variants
                .filter((v) => v.color === selectedColor && v.colorImage)
                .map((v) => v.colorImage as string);
            // Deduplicate
            const unique = [...new Set(colorImages)];
            if (unique.length > 0) return unique;
        }
        return product.images;
    }, [product, selectedColor]);

    const currentStock = currentVariant?.stock ?? product?.stock ?? 0;
    const displayPrice = product
        ? product.salePrice > 0 && product.salePrice < product.price
            ? product.salePrice
            : product.price
        : 0;
    const originalPrice = product && product.salePrice > 0 && product.salePrice < product.price
        ? product.price
        : null;
    const discount = product ? getDiscountPercent(product) : null;
    const inWishlist = isInWishlist(productId);

    const handleAddToCart = useCallback(() => {
        if (!product || !selectedSize || !selectedColor) return;
        if (!user) {
            router.push("/dang-nhap");
            return;
        }
        const item: CartItem = {
            productId: product.id,
            name: product.name,
            image: product.images[0] || "",
            price: product.price,
            salePrice: product.salePrice,
            brandName: product.brandName,
            size: selectedSize,
            color: selectedColor,
            quantity,
        };
        addToCart(item);
        toast.success(`Đã thêm ${product.name} vào giỏ hàng!`);
        setAddedToCart(true);
        setTimeout(() => setAddedToCart(false), 2000);
    }, [product, selectedSize, selectedColor, quantity, user, router, addToCart]);

    // ─── Loading skeleton ───
    if (loading) {
        return (
            <div style={{ minHeight: "100vh", paddingTop: "calc(var(--header-height) + var(--space-xl))" }}>
                <div className="container" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-3xl)", maxWidth: "1200px", margin: "0 auto", padding: "var(--space-xl)" }}>
                    <div style={{ aspectRatio: "3/4", borderRadius: "var(--radius-lg)", background: "var(--bg-elevated)", animation: "shimmer 1.5s infinite" }} />
                    <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-lg)" }}>
                        <div style={{ height: "16px", width: "40%", borderRadius: "var(--radius-sm)", background: "var(--bg-elevated)", animation: "shimmer 1.5s infinite" }} />
                        <div style={{ height: "32px", width: "80%", borderRadius: "var(--radius-sm)", background: "var(--bg-elevated)", animation: "shimmer 1.5s infinite" }} />
                        <div style={{ height: "28px", width: "30%", borderRadius: "var(--radius-sm)", background: "var(--bg-elevated)", animation: "shimmer 1.5s infinite" }} />
                        <div style={{ height: "100px", width: "100%", borderRadius: "var(--radius-sm)", background: "var(--bg-elevated)", animation: "shimmer 1.5s infinite", marginTop: "var(--space-xl)" }} />
                    </div>
                </div>
            </div>
        );
    }

    if (!product) return null;

    return (
        <div style={{ minHeight: "100vh", paddingTop: "calc(var(--header-height) + var(--space-lg))" }}>


            {/* ═══ Main Product Section ═══ */}
            <div className="container product-detail-grid" style={{ maxWidth: "1200px", margin: "0 auto", padding: "var(--space-lg)", display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-3xl)" }}>
                {/* LEFT — Image Gallery */}
                <div>
                    <ImageGallery images={displayImages} name={product.name} />
                </div>

                {/* RIGHT — Product Info */}
                <div style={{ display: "flex", flexDirection: "column" }}>
                    {/* Brand */}
                    {product.brandName && (
                        <p style={{
                            fontSize: "0.78rem",
                            fontWeight: 600,
                            letterSpacing: "0.12em",
                            textTransform: "uppercase",
                            color: "var(--color-accent)",
                            marginBottom: "var(--space-sm)",
                        }}>
                            {product.brandName}
                        </p>
                    )}

                    {/* Name */}
                    <h1 style={{
                        fontSize: "clamp(1.4rem, 3vw, 2rem)",
                        fontWeight: 700,
                        color: "var(--text-primary)",
                        lineHeight: 1.3,
                        marginBottom: "var(--space-lg)",
                        letterSpacing: "-0.02em",
                    }}>
                        {product.name}
                    </h1>

                    {/* Badges */}
                    <div style={{ display: "flex", gap: "var(--space-sm)", marginBottom: "var(--space-lg)" }}>
                        {discount && (
                            <span style={{
                                padding: "4px 12px",
                                borderRadius: "var(--radius-sm)",
                                background: "var(--color-success)",
                                color: "#fff",
                                fontSize: "0.75rem",
                                fontWeight: 700,
                            }}>
                                -{discount}%
                            </span>
                        )}
                        {isNew(product) && (
                            <span style={{
                                padding: "4px 12px",
                                borderRadius: "var(--radius-sm)",
                                background: "var(--color-accent)",
                                color: "#fff",
                                fontSize: "0.75rem",
                                fontWeight: 700,
                            }}>
                                MỚI
                            </span>
                        )}
                        {currentStock > 0 ? (
                            <span style={{
                                padding: "4px 12px",
                                borderRadius: "var(--radius-sm)",
                                background: "rgba(16,185,129,0.1)",
                                color: "var(--color-success)",
                                fontSize: "0.75rem",
                                fontWeight: 600,
                                border: "1px solid rgba(16,185,129,0.2)",
                            }}>
                                Còn hàng ({currentStock})
                            </span>
                        ) : (
                            <span style={{
                                padding: "4px 12px",
                                borderRadius: "var(--radius-sm)",
                                background: "rgba(239,68,68,0.1)",
                                color: "var(--color-error)",
                                fontSize: "0.75rem",
                                fontWeight: 600,
                                border: "1px solid rgba(239,68,68,0.2)",
                            }}>
                                Hết hàng
                            </span>
                        )}
                    </div>

                    {/* Price */}
                    <div style={{
                        display: "flex",
                        alignItems: "baseline",
                        gap: "var(--space-md)",
                        marginBottom: "var(--space-xl)",
                        paddingBottom: "var(--space-xl)",
                        borderBottom: "1px solid var(--border-color)",
                    }}>
                        <span style={{ fontSize: "1.8rem", fontWeight: 800, color: "var(--color-accent)" }}>
                            {formatPrice(displayPrice)}
                        </span>
                        {originalPrice && (
                            <span style={{ fontSize: "1.1rem", color: "var(--text-muted)", textDecoration: "line-through" }}>
                                {formatPrice(originalPrice)}
                            </span>
                        )}
                    </div>

                    {/* Color Selection */}
                    {availableColors.length > 0 && (
                        <div style={{ marginBottom: "var(--space-xl)" }}>
                            <p style={{ fontSize: "0.82rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "var(--space-md)", textTransform: "uppercase", letterSpacing: "0.06em" }}>
                                Màu sắc: <span style={{ color: "var(--text-primary)", textTransform: "none" }}>{selectedColor}</span>
                            </p>
                            <div style={{ display: "flex", gap: "var(--space-sm)", flexWrap: "wrap" }}>
                                {availableColors.map(({ color }) => {
                                    const isActive = selectedColor === color;
                                    return (
                                        <button
                                            key={color}
                                            onClick={() => {
                                                setSelectedColor(color);
                                                setSelectedSize("");
                                            }}
                                            style={{
                                                padding: "8px 18px",
                                                borderRadius: "var(--radius-md)",
                                                border: `1.5px solid ${isActive ? "var(--color-accent)" : "var(--border-light)"}`,
                                                background: isActive ? "rgba(139,92,246,0.12)" : "transparent",
                                                color: isActive ? "var(--color-accent)" : "var(--text-secondary)",
                                                fontSize: "0.88rem",
                                                fontWeight: 600,
                                                cursor: "pointer",
                                                transition: "all 0.2s ease",
                                            }}
                                        >
                                            {color}
                                        </button>
                                    );
                                })}
                            </div>
                        </div>
                    )}

                    {/* Size Selection */}
                    {availableSizes.length > 0 && (
                        <div style={{ marginBottom: "var(--space-xl)" }}>
                            <p style={{ fontSize: "0.82rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "var(--space-md)", textTransform: "uppercase", letterSpacing: "0.06em" }}>
                                Kích cỡ: <span style={{ color: "var(--text-primary)", textTransform: "none" }}>{selectedSize || "Chọn size"}</span>
                            </p>
                            <div style={{ display: "flex", gap: "var(--space-sm)", flexWrap: "wrap" }}>
                                {availableSizes.map(({ size, stock }) => {
                                    const isActive = selectedSize === size;
                                    const isOutOfStock = stock <= 0;
                                    return (
                                        <button
                                            key={size}
                                            onClick={() => !isOutOfStock && setSelectedSize(size)}
                                            disabled={isOutOfStock}
                                            style={{
                                                padding: "8px 18px",
                                                borderRadius: "var(--radius-md)",
                                                border: `1.5px solid ${isActive ? "var(--color-accent)" : isOutOfStock ? "var(--border-color)" : "var(--border-light)"}`,
                                                background: isActive ? "rgba(139,92,246,0.12)" : "transparent",
                                                color: isOutOfStock ? "var(--text-muted)" : isActive ? "var(--color-accent)" : "var(--text-secondary)",
                                                fontSize: "0.88rem",
                                                fontWeight: 600,
                                                cursor: isOutOfStock ? "not-allowed" : "pointer",
                                                transition: "all 0.2s ease",
                                                opacity: isOutOfStock ? 0.4 : 1,
                                                textDecoration: isOutOfStock ? "line-through" : "none",
                                                position: "relative",
                                            }}
                                        >
                                            {size}
                                            {!isOutOfStock && stock <= 10 && (
                                                <span style={{ fontSize: "0.65rem", opacity: 0.7, marginLeft: "2px" }}>({stock})</span>
                                            )}
                                        </button>
                                    );
                                })}
                            </div>
                        </div>
                    )}

                    {/* Quantity */}
                    <div style={{ marginBottom: "var(--space-xl)" }}>
                        <p style={{ fontSize: "0.82rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "var(--space-md)", textTransform: "uppercase", letterSpacing: "0.06em" }}>
                            Số lượng
                        </p>
                        <div style={{ display: "inline-flex", alignItems: "center", border: "1.5px solid var(--border-color)", borderRadius: "var(--radius-md)", overflow: "hidden" }}>
                            <button
                                onClick={() => setQuantity(Math.max(1, quantity - 1))}
                                style={{
                                    width: "40px",
                                    height: "40px",
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    background: "var(--bg-elevated)",
                                    color: "var(--text-primary)",
                                    fontSize: "1.1rem",
                                    cursor: "pointer",
                                    transition: "background 0.2s",
                                }}
                                onMouseEnter={(e) => e.currentTarget.style.background = "var(--bg-surface)"}
                                onMouseLeave={(e) => e.currentTarget.style.background = "var(--bg-elevated)"}
                            >−</button>
                            <span style={{ width: "50px", textAlign: "center", fontSize: "0.95rem", fontWeight: 600, color: "var(--text-primary)" }}>
                                {quantity}
                            </span>
                            <button
                                onClick={() => setQuantity(Math.min(currentStock, quantity + 1))}
                                style={{
                                    width: "40px",
                                    height: "40px",
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    background: "var(--bg-elevated)",
                                    color: "var(--text-primary)",
                                    fontSize: "1.1rem",
                                    cursor: "pointer",
                                    transition: "background 0.2s",
                                }}
                                onMouseEnter={(e) => e.currentTarget.style.background = "var(--bg-surface)"}
                                onMouseLeave={(e) => e.currentTarget.style.background = "var(--bg-elevated)"}
                            >+</button>
                        </div>
                    </div>

                    {/* Action Buttons */}
                    <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-md)", marginBottom: "var(--space-xl)" }}>
                        <div style={{ display: "flex", gap: "var(--space-md)" }}>
                            <button
                                onClick={handleAddToCart}
                                disabled={currentStock <= 0 || !selectedSize}
                                className="btn btn-primary"
                                style={{
                                    flex: 1,
                                    padding: "0.9rem 1.5rem",
                                    fontSize: "0.95rem",
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    gap: "var(--space-sm)",
                                    opacity: currentStock <= 0 || !selectedSize ? 0.5 : 1,
                                    cursor: currentStock <= 0 || !selectedSize ? "not-allowed" : "pointer",
                                }}
                            >
                                {addedToCart ? (
                                    <>
                                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>
                                        Đã Thêm!
                                    </>
                                ) : (
                                    <>
                                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" /><line x1="3" y1="6" x2="21" y2="6" /><path d="M16 10a4 4 0 0 1-8 0" /></svg>
                                        Thêm Vào Giỏ Hàng
                                    </>
                                )}
                            </button>
                            <button
                                onClick={() => toggleWishlist(productId)}
                                style={{
                                    width: "52px",
                                    height: "52px",
                                    borderRadius: "var(--radius-md)",
                                    border: inWishlist ? "1.5px solid var(--color-accent)" : "1.5px solid var(--border-color)",
                                    background: inWishlist ? "rgba(139,92,246,0.1)" : "transparent",
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    color: inWishlist ? "var(--color-accent)" : "var(--text-secondary)",
                                    cursor: "pointer",
                                    transition: "all 0.2s ease",
                                    flexShrink: 0,
                                }}
                                onMouseEnter={(e) => {
                                    e.currentTarget.style.borderColor = "var(--color-accent)";
                                    e.currentTarget.style.color = "var(--color-accent)";
                                }}
                                onMouseLeave={(e) => {
                                    e.currentTarget.style.borderColor = inWishlist ? "var(--color-accent)" : "var(--border-color)";
                                    e.currentTarget.style.color = inWishlist ? "var(--color-accent)" : "var(--text-secondary)";
                                }}
                                title={inWishlist ? "Bỏ yêu thích" : "Thêm yêu thích"}
                            >
                                <svg width="20" height="20" viewBox="0 0 24 24" fill={inWishlist ? "currentColor" : "none"} stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                                </svg>
                            </button>
                        </div>
                        <button
                            onClick={() => {
                                if (!product || !selectedSize || !selectedColor) return;
                                if (!user) { router.push("/dang-nhap"); return; }
                                const unitPrice = product.salePrice > 0 && product.salePrice < product.price ? product.salePrice : product.price;
                                const buyNowItem = {
                                    productId: product.id,
                                    name: product.name,
                                    image: product.images[0] || "",
                                    price: product.price,
                                    salePrice: product.salePrice,
                                    brandName: product.brandName,
                                    size: selectedSize,
                                    color: selectedColor,
                                    quantity,
                                    unitPrice,
                                };
                                sessionStorage.setItem("sz-buy-now", JSON.stringify(buyNowItem));
                                router.push("/thanh-toan?buyNow=1");
                            }}
                            disabled={currentStock <= 0 || !selectedSize}
                            className="btn btn-outline"
                            style={{
                                width: "100%",
                                padding: "0.9rem 1.5rem",
                                fontSize: "0.95rem",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                gap: "var(--space-sm)",
                                opacity: currentStock <= 0 || !selectedSize ? 0.5 : 1,
                                cursor: currentStock <= 0 || !selectedSize ? "not-allowed" : "pointer",
                            }}
                        >
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></svg>
                            Mua Ngay
                        </button>
                    </div>

                    {/* USP mini */}
                    <div style={{
                        display: "grid",
                        gridTemplateColumns: "repeat(3, 1fr)",
                        gap: "var(--space-md)",
                    }}>
                        {[
                            { icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><rect x="1" y="3" width="15" height="13" /><polygon points="16 8 20 8 23 11 23 16 16 16 16 8" /><circle cx="5.5" cy="18.5" r="2.5" /><circle cx="18.5" cy="18.5" r="2.5" /></svg>, text: "Giao hàng miễn phí" },
                            { icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><polyline points="23 4 23 10 17 10" /><polyline points="1 20 1 14 7 14" /><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" /></svg>, text: "Đổi trả 30 ngày" },
                            { icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>, text: "Chính hãng 100%" },
                        ].map((item, i) => (
                            <div
                                key={i}
                                style={{
                                    display: "flex",
                                    flexDirection: "column",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    gap: "8px",
                                    textAlign: "center",
                                    padding: "var(--space-lg) var(--space-sm)",
                                    background: "var(--bg-elevated)",
                                    borderRadius: "var(--radius-lg)",
                                    border: "1px solid var(--border-color)",
                                    transition: "all 0.3s cubic-bezier(0.16, 1, 0.3, 1)",
                                    cursor: "default",
                                }}
                                onMouseEnter={(e) => {
                                    e.currentTarget.style.borderColor = "var(--color-accent)";
                                }}
                                onMouseLeave={(e) => {
                                    e.currentTarget.style.borderColor = "var(--border-color)";
                                }}
                            >
                                <div style={{ color: "var(--color-accent)" }}>{item.icon}</div>
                                <span style={{ fontSize: "0.75rem", color: "var(--text-muted)", fontWeight: 500, lineHeight: 1.3 }}>{item.text}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            {/* ═══ Tabs Section ═══ */}
            <div className="container" style={{ maxWidth: "1200px", margin: "0 auto", padding: "var(--space-3xl) var(--space-lg)" }}>
                <ProductTabs product={product} />
            </div>

            {/* ═══ Related Products ═══ */}
            {relatedProducts.length > 0 && (
                <div className="container" style={{ maxWidth: "1200px", margin: "0 auto", padding: "0 var(--space-lg) var(--space-3xl)" }}>
                    <div style={{ textAlign: "center", marginBottom: "var(--space-2xl)" }}>
                        <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
                        <h2 className="section-title" style={{ fontSize: "1.5rem" }}>Sản Phẩm Liên Quan</h2>
                    </div>
                    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(240px, 1fr))", gap: "var(--space-lg)" }}>
                        {relatedProducts.map((p) => (
                            <ProductCard key={p.id} product={p} />
                        ))}
                    </div>
                </div>
            )}

            {/* ═══ Responsive Styles ═══ */}
            <style jsx global>{`
                @media (max-width: 768px) {
                    .product-detail-grid {
                        grid-template-columns: 1fr !important;
                        gap: var(--space-xl) !important;
                    }
                }
            `}</style>
        </div>
    );
}
