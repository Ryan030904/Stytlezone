"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useState, useRef, useCallback } from "react";
import { getCombos, getComboTotalOriginalPrice, getComboEffectivePrice, isComboPromotionActive, getComboSavedPercent } from "@/lib/combos";
import { getProductsByIds } from "@/lib/products";
import type { Combo } from "@/lib/combos";
import type { Product, ProductVariant } from "@/lib/types";
import { useCart } from "@/components/CartProvider";
import { toast } from "sonner";

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

const LOOKBOOK_ITEMS = [
    { src: "/images/collection/lookbook-main.png", alt: "Summer Muse — Look chính", span: true },
    { src: "/images/collection/lookbook-secondary.png", alt: "Summer Muse — Phong cách nữ", span: false },
    { src: "/images/collection/lookbook-detail.png", alt: "Summer Muse — Chi tiết chất liệu", span: false },
];

/* ============================================================
   SUB-COMPONENTS
   ============================================================ */

function HeroSection() {
    const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
    const handleMouseMove = useCallback((e: React.MouseEvent) => {
        const { clientX, clientY } = e;
        const { innerWidth, innerHeight } = window;
        setMousePos({ x: (clientX / innerWidth - 0.5) * 20, y: (clientY / innerHeight - 0.5) * 20 });
    }, []);

    return (
        <section
            onMouseMove={handleMouseMove}
            style={{
                position: "relative",
                minHeight: "100vh",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                overflow: "hidden",
            }}
        >
            {/* Parallax BG Image */}
            <div
                style={{
                    position: "absolute",
                    inset: "-20px",
                    transform: `translate(${mousePos.x}px, ${mousePos.y}px)`,
                    transition: "transform 0.3s ease-out",
                }}
            >
                <Image
                    src="/images/collection/hero.png"
                    alt="Summer Muse 2026"
                    fill
                    style={{ objectFit: "cover" }}
                    priority
                />
                <div
                    style={{
                        position: "absolute",
                        inset: 0,
                        background: "linear-gradient(135deg, rgba(10,10,10,0.75) 0%, rgba(10,10,10,0.3) 50%, rgba(10,10,10,0.65) 100%)",
                    }}
                />
            </div>

            {/* Floating orbs */}
            <div style={{ position: "absolute", top: "10%", right: "12%", width: "300px", height: "300px", borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.15) 0%, transparent 70%)", animation: "float 6s ease-in-out infinite", pointerEvents: "none" }} />
            <div style={{ position: "absolute", bottom: "15%", left: "8%", width: "200px", height: "200px", borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.1) 0%, transparent 70%)", animation: "float 8s ease-in-out infinite reverse", pointerEvents: "none" }} />

            {/* Content */}
            <div
                className="container"
                style={{ position: "relative", zIndex: 2, textAlign: "center", paddingTop: "var(--header-height)" }}
            >
                <div
                    className="animate-fade-in"
                    style={{
                        display: "inline-flex",
                        alignItems: "center",
                        gap: "var(--space-sm)",
                        padding: "6px 16px",
                        borderRadius: "var(--radius-full)",
                        background: "rgba(139,92,246,0.1)",
                        border: "1px solid rgba(139,92,246,0.2)",
                        marginBottom: "var(--space-xl)",
                        fontSize: "0.8rem",
                        fontWeight: 600,
                        letterSpacing: "0.15em",
                        color: "var(--color-accent)",
                        textTransform: "uppercase",
                    }}
                >
                    <span style={{ width: "6px", height: "6px", borderRadius: "50%", background: "var(--color-accent)", animation: "pulse-glow 2s ease infinite" }} />
                    Summer Collection 2026
                </div>

                <h1
                    className="animate-slide-up stagger-1"
                    style={{
                        fontSize: "clamp(2.8rem, 7vw, 5rem)",
                        fontWeight: 800,
                        lineHeight: 1.05,
                        letterSpacing: "-0.04em",
                        color: "var(--hero-text)",
                        marginBottom: "var(--space-lg)",
                    }}
                >
                    Summer{" "}
                    <span className="gradient-text" style={{ fontStyle: "italic" }}>Muse</span>
                    <br />
                    <span style={{ fontSize: "0.6em", fontWeight: 400, letterSpacing: "0.1em", opacity: 0.7 }}>
                        2026
                    </span>
                </h1>

                <p
                    className="animate-slide-up stagger-2"
                    style={{
                        color: "var(--hero-subtitle)",
                        fontSize: "clamp(1rem, 2vw, 1.15rem)",
                        maxWidth: "560px",
                        margin: "0 auto var(--space-2xl)",
                        lineHeight: 1.8,
                    }}
                >
                    Lấy cảm hứng từ ánh nắng Địa Trung Hải — phóng khoáng, nữ tính và hiện đại.
                </p>

                <div className="animate-slide-up stagger-3" style={{ display: "flex", gap: "var(--space-md)", justifyContent: "center", flexWrap: "wrap" }}>
                    <Link href="#lookbook" className="btn btn-primary" style={{ padding: "1rem 2.5rem", fontSize: "0.95rem" }}>
                        Khám Phá Ngay →
                    </Link>
                    <Link href="#products" className="btn btn-outline" style={{ padding: "1rem 2.5rem", fontSize: "0.95rem" }}>
                        Xem Sản Phẩm
                    </Link>
                </div>
            </div>

            {/* Scroll indicator */}
            <div className="animate-fade-in stagger-5" style={{ position: "absolute", bottom: "2.5rem", left: "50%", transform: "translateX(-50%)", display: "flex", flexDirection: "column", alignItems: "center" }}>
                <div style={{ width: "24px", height: "40px", borderRadius: "var(--radius-full)", border: "2px solid rgba(255,255,255,0.2)", display: "flex", justifyContent: "center", paddingTop: "8px" }}>
                    <div style={{ width: "3px", height: "8px", borderRadius: "var(--radius-full)", background: "var(--color-accent)", animation: "bounce-subtle 2s ease infinite" }} />
                </div>
            </div>
        </section>
    );
}

/* ─── Storytelling Section ─── */
function StorySection() {
    const leftRef = useReveal("left");
    const rightRef = useReveal("right", { delay: 0.15 });

    return (
        <section className="section" style={{ overflow: "hidden" }}>
            <div className="container" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-4xl)", alignItems: "center" }} id="story">
                <div ref={leftRef}>
                    <p style={{ fontSize: "0.75rem", fontWeight: 600, letterSpacing: "0.15em", textTransform: "uppercase", color: "var(--color-accent)", marginBottom: "var(--space-md)" }}>
                        Về Bộ Sưu Tập
                    </p>
                    <h2 style={{ fontSize: "clamp(1.8rem, 3vw, 2.5rem)", fontWeight: 700, lineHeight: 1.2, letterSpacing: "-0.03em", marginBottom: "var(--space-lg)" }}>
                        Nơi Ánh Nắng <br />
                        <span className="gradient-text">Gặp Phong Cách</span>
                    </h2>
                    <p style={{ color: "var(--text-secondary)", fontSize: "0.95rem", lineHeight: 1.8, marginBottom: "var(--space-lg)" }}>
                        Lấy cảm hứng từ ánh nắng Địa Trung Hải, bộ sưu tập <strong>Summer Muse 2026</strong> mang đến sự phóng khoáng, nữ tính và hiện đại. Chất liệu linen cao cấp, cotton hữu cơ và palette màu pastel tạo nên một mùa hè thật riêng.
                    </p>
                    <div style={{ display: "flex", gap: "var(--space-2xl)" }}>
                        {[
                            { num: "24", label: "Thiết kế" },
                            { num: "6", label: "Chất liệu" },
                            { num: "4", label: "Bộ Look" },
                        ].map((s) => (
                            <div key={s.label}>
                                <div style={{ fontSize: "1.8rem", fontWeight: 800, color: "var(--color-accent)" }}>{s.num}</div>
                                <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "2px" }}>{s.label}</div>
                            </div>
                        ))}
                    </div>
                </div>
                <div ref={rightRef} style={{ position: "relative", borderRadius: "var(--radius-xl)", overflow: "hidden", aspectRatio: "3/4" }}>
                    <Image src="/images/collection/lookbook-main.png" alt="Summer Muse concept" fill style={{ objectFit: "cover" }} sizes="(max-width: 768px) 100vw, 50vw" />
                    <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.4) 0%, transparent 50%)" }} />
                    <div style={{ position: "absolute", bottom: "var(--space-xl)", left: "var(--space-xl)", zIndex: 2 }}>
                        <span style={{ padding: "6px 14px", borderRadius: "var(--radius-full)", background: "rgba(139,92,246,0.2)", border: "1px solid rgba(139,92,246,0.3)", color: "var(--color-accent)", fontSize: "0.75rem", fontWeight: 600, letterSpacing: "0.1em", textTransform: "uppercase" }}>
                            Premium Linen
                        </span>
                    </div>
                </div>
            </div>

            <style jsx>{`
                @media (max-width: 768px) {
                    #story { grid-template-columns: 1fr !important; gap: var(--space-2xl) !important; }
                }
            `}</style>
        </section>
    );
}

/* ─── Lookbook Grid ─── */
function LookbookSection() {
    const sectionRef = useReveal();

    return (
        <section className="section" style={{ background: "var(--bg-secondary)" }} id="lookbook">
            <div className="container">
                <div ref={sectionRef} style={{ textAlign: "center", marginBottom: "var(--space-2xl)" }}>

                    <h2 className="section-title">Lookbook</h2>
                    <p className="section-subtitle">Campaign Summer Muse 2026</p>
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gridTemplateRows: "1fr 1fr", gap: "var(--space-md)" }} className="lookbook-grid">
                    {LOOKBOOK_ITEMS.map((item, i) => {
                        const ItemInner = () => {
                            const itemRef = useReveal("scale", { delay: i * 0.12 });
                            return (
                                <div
                                    ref={itemRef}
                                    className="product-img-wrap"
                                    style={{
                                        position: "relative",
                                        borderRadius: "var(--radius-lg)",
                                        overflow: "hidden",
                                        ...(item.span ? { gridRow: "1 / 3" } : {}),
                                        height: "100%",
                                        minHeight: item.span ? "500px" : "240px",
                                    }}
                                >
                                    <Image src={item.src} alt={item.alt} fill style={{ objectFit: "cover" }} sizes={item.span ? "(max-width: 768px) 100vw, 50vw" : "(max-width: 768px) 100vw, 25vw"} />
                                    <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.35) 0%, transparent 50%)", transition: "opacity 0.3s", opacity: 0 }} className="lookbook-overlay" />
                                </div>
                            );
                        };
                        return <ItemInner key={i} />;
                    })}
                </div>
            </div>
            <style jsx global>{`
                .lookbook-grid { grid-template-columns: 1fr 1fr; }
                .product-img-wrap:hover .lookbook-overlay { opacity: 1 !important; }
                @media (max-width: 768px) {
                    .lookbook-grid { grid-template-columns: 1fr !important; grid-template-rows: auto !important; }
                    .lookbook-grid > div { grid-row: auto !important; min-height: 280px !important; }
                }
            `}</style>
        </section>
    );
}

/* ─── Combo Purchase Modal ─── */
function ComboPurchaseModal({ combo, onClose }: { combo: Combo; onClose: () => void }) {
    const { addToCart } = useCart();
    const [products, setProducts] = useState<Product[]>([]);
    const [loading, setLoading] = useState(true);
    
    // State lưu chọn lựa màu, size cho từng productId
    const [selections, setSelections] = useState<Record<string, { color: string; size: string }>>({});

    useEffect(() => {
        const fetchProducts = async () => {
            const ids = combo.items.map(i => i.productId);
            const prods = await getProductsByIds(ids);
            
            // Auto select đầu tiên nếu có màu/size
            const initialSelections: Record<string, { color: string; size: string }> = {};
            prods.forEach(p => {
                initialSelections[p.id] = {
                    color: p.colors.length > 0 ? p.colors[0] : "",
                    size: p.sizes.length > 0 ? p.sizes[0] : ""
                };
            });
            setSelections(initialSelections);
            setProducts(prods);
            setLoading(false);
        };
        fetchProducts();
    }, [combo]);

    const handleSelect = (productId: string, type: "color" | "size", value: string) => {
        setSelections(prev => ({
            ...prev,
            [productId]: { ...prev[productId], [type]: value }
        }));
    };

    // Calculate dynamic pricing
    const savedPercent = getComboSavedPercent(combo); // Tỉ lệ giảm gốc (cố định)
    
    let totalSelectedOriginalPrice = 0;
    const canCheckout = products.every(p => {
        const sel = selections[p.id];
        if (!sel) return false;
        if (p.colors.length > 0 && !sel.color) return false;
        if (p.sizes.length > 0 && !sel.size) return false;
        
        // Find price of selected variant, fallback to base price
        let itemPrice = p.price;
        if (sel.color && sel.size && p.variants.length > 0) {
            const v = p.variants.find(v => v.color === sel.color && v.size === sel.size);
            if (v && v.price > 0) itemPrice = v.price;
        }
        totalSelectedOriginalPrice += itemPrice;
        return true;
    });

    const finalComboPrice = totalSelectedOriginalPrice * (1 - savedPercent / 100);

    const handleAddToCart = () => {
        if (!canCheckout) return;
        products.forEach(p => {
            const sel = selections[p.id];
            // Find variant price to determine the individual discounted price
            let basePrice = p.price;
            let img = p.images[0];
            if (sel.color && sel.size && p.variants.length > 0) {
                const v = p.variants.find(v => v.color === sel.color && v.size === sel.size);
                if (v && v.price > 0) basePrice = v.price;
                if (v && v.colorImage) img = v.colorImage;
            }
            
            // Chia tỉ lệ chiết khấu cho từng item đều nhau
            const discountedPrice = basePrice * (1 - savedPercent / 100);
            
            addToCart({
                productId: p.id,
                name: p.name,
                image: img,
                price: basePrice,
                salePrice: Math.round(discountedPrice),
                brandName: p.brandName,
                size: sel.size,
                color: sel.color,
                quantity: 1 // Trong combo mặc định là mua 1 set
            });
        });
        onClose();
        toast.success("Đã thêm toàn bộ sản phẩm trong Combo vào Giỏ! 🎉");
    };

    return (
        <div style={{ position: "fixed", inset: 0, zIndex: 1000, display: "flex", alignItems: "center", justifyContent: "center", padding: "var(--space-md)" }}>
            <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.8)", backdropFilter: "blur(6px)" }} onClick={onClose} />
            <div style={{ position: "relative", width: "100%", maxWidth: "600px", maxHeight: "90vh", background: "var(--bg-card)", borderRadius: "var(--radius-xl)", border: "1px solid var(--border-color)", display: "flex", flexDirection: "column", overflow: "hidden", animation: "modal-in 0.3s cubic-bezier(0.16, 1, 0.3, 1)" }}>
                {/* Header */}
                <div style={{ padding: "var(--space-lg)", borderBottom: "1px solid var(--border-color)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                    <div>
                        <h3 style={{ fontSize: "1.2rem", fontWeight: 700, color: "var(--text-primary)" }}>Thêm Set Vào Giỏ</h3>
                        <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>{combo.name}</p>
                    </div>
                    <button onClick={onClose} style={{ width: "32px", height: "32px", borderRadius: "50%", background: "var(--bg-surface)", border: "1px solid var(--border-color)", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", transition: "all 0.2s" }} onMouseEnter={(e) => e.currentTarget.style.borderColor = "var(--text-primary)"} onMouseLeave={(e) => e.currentTarget.style.borderColor = "var(--border-color)"}>
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--text-primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    </button>
                </div>
                
                {/* Body */}
                <div style={{ padding: "var(--space-lg)", overflowY: "auto", flex: 1, overscrollBehavior: "contain" }}>
                    {loading ? (
                        <div style={{ textAlign: "center", padding: "var(--space-2xl) 0", color: "var(--text-muted)" }}>
                            <div style={{ width: "30px", height: "30px", borderRadius: "50%", border: "2px solid var(--border-color)", borderTopColor: "var(--color-accent)", animation: "rotate-slow 0.8s linear infinite", margin: "0 auto var(--space-md)" }} />
                            Đang tải thông tin sản phẩm...
                        </div>
                    ) : (
                        <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-xl)" }}>
                            {products.map(p => {
                                const sel = selections[p.id] || { color: "", size: "" };
                                let vPrice = p.price;
                                if (sel.color && sel.size && p.variants.length > 0) {
                                    const v = p.variants.find(v => v.color === sel.color && v.size === sel.size);
                                    if (v && v.price > 0) vPrice = v.price;
                                }

                                return (
                                    <div key={p.id} style={{ display: "flex", gap: "var(--space-lg)" }}>
                                        <div style={{ width: "80px", height: "100px", borderRadius: "var(--radius-md)", overflow: "hidden", flexShrink: 0, position: "relative", border: "1px solid var(--border-color)" }}>
                                            <Image src={p.images[0]} alt={p.name} fill style={{ objectFit: "cover" }} sizes="80px" />
                                        </div>
                                        <div style={{ flex: 1, minWidth: 0 }}>
                                            <h4 style={{ fontSize: "0.95rem", fontWeight: 600, color: "var(--text-primary)", marginBottom: "4px" }}>{p.name}</h4>
                                            <p style={{ fontSize: "0.85rem", color: "var(--text-secondary)", marginBottom: "var(--space-md)" }}>{formatPrice(vPrice)}</p>
                                            
                                            {/* Colors */}
                                            {p.colors.length > 0 && (
                                                <div style={{ marginBottom: "var(--space-sm)" }}>
                                                    <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginBottom: "4px" }}>Màu sắc</p>
                                                    <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                                                        {p.colors.map(c => (
                                                            <button
                                                                type="button"
                                                                key={c}
                                                                onClick={() => handleSelect(p.id, "color", c)}
                                                                style={{ padding: "4px 10px", fontSize: "0.75rem", borderRadius: "var(--radius-sm)", border: `1px solid ${sel.color === c ? 'var(--color-accent)' : 'var(--border-color)'}`, background: sel.color === c ? 'rgba(139,92,246,0.1)' : 'var(--bg-surface)', color: sel.color === c ? 'var(--color-accent)' : 'var(--text-secondary)', cursor: "pointer", outline: "none", userSelect: "none" }}
                                                            >
                                                                {c}
                                                            </button>
                                                        ))}
                                                    </div>
                                                </div>
                                            )}

                                            {/* Sizes */}
                                            {p.sizes.length > 0 && (
                                                <div>
                                                    <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginBottom: "4px" }}>Kích thước</p>
                                                    <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                                                        {p.sizes.map(s => (
                                                            <button
                                                                type="button"
                                                                key={s}
                                                                onClick={() => handleSelect(p.id, "size", s)}
                                                                style={{ padding: "4px 10px", fontSize: "0.75rem", borderRadius: "var(--radius-sm)", border: `1px solid ${sel.size === s ? 'var(--color-accent)' : 'var(--border-color)'}`, background: sel.size === s ? 'rgba(139,92,246,0.1)' : 'var(--bg-surface)', color: sel.size === s ? 'var(--color-accent)' : 'var(--text-secondary)', cursor: "pointer", outline: "none", userSelect: "none" }}
                                                            >
                                                                {s}
                                                            </button>
                                                        ))}
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    )}
                </div>

                {/* Footer - Checkout */}
                {!loading && (
                    <div style={{ padding: "var(--space-lg)", borderTop: "1px solid var(--border-color)", background: "var(--bg-surface)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                        <div>
                            <div style={{ display: "flex", alignItems: "center", gap: "6px", marginBottom: "2px" }}>
                                <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", textDecoration: "line-through" }}>{formatPrice(totalSelectedOriginalPrice)}</p>
                                <span style={{ padding: "2px 6px", borderRadius: "4px", background: "rgba(239,68,68,0.15)", color: "#ff6b6b", fontSize: "0.7rem", fontWeight: 700 }}>-{Math.round(savedPercent)}%</span>
                            </div>
                            <p style={{ fontSize: "1.3rem", fontWeight: 800, color: "var(--color-accent)" }}>{formatPrice(finalComboPrice)}</p>
                        </div>
                        <button
                            disabled={!canCheckout}
                            onClick={handleAddToCart}
                            style={{ 
                                padding: "12px 32px", 
                                borderRadius: "var(--radius-md)", 
                                background: canCheckout ? "var(--color-accent)" : "var(--bg-elevated)", 
                                color: canCheckout ? "#fff" : "var(--text-muted)", 
                                fontWeight: 600, 
                                border: "none", 
                                cursor: canCheckout ? "pointer" : "not-allowed",
                                opacity: canCheckout ? 1 : 0.7,
                                transition: "all 0.2s"
                            }}
                        >
                            Thêm Vào Giỏ
                        </button>
                    </div>
                )}
            </div>
            <style jsx>{`
                @keyframes modal-in {
                    from { opacity: 0; transform: translateY(20px) scale(0.95); }
                    to { opacity: 1; transform: translateY(0) scale(1); }
                }
            `}</style>
        </div>
    );
}

/* ─── Combo Set Cards ─── */
function ComboSection({ combos }: { combos: Combo[] }) {
    const sectionRef = useReveal();
    const [selectedCombo, setSelectedCombo] = useState<Combo | null>(null);

    if (combos.length === 0) return null;

    return (
        <section className="section" id="combo-sets">
            <div className="container">
                <div ref={sectionRef} style={{ textAlign: "center", marginBottom: "var(--space-3xl)" }}>
                    <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
                    <h2 className="section-title">Set Combo</h2>
                    <p className="section-subtitle">Mua cả set — tiết kiệm hơn mua lẻ</p>
                </div>

                <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(340px, 1fr))", gap: "var(--space-xl)" }} className="combo-grid">
                    {combos.map((combo, i) => {
                        const ComboCard = () => {
                            const cardRef = useReveal("up", { delay: i * 0.1 });
                            const totalOriginal = getComboTotalOriginalPrice(combo);
                            const effectivePrice = getComboEffectivePrice(combo);
                            const hasPromo = isComboPromotionActive(combo);
                            const savedPercent = getComboSavedPercent(combo);
                            const firstImage = combo.imageUrl || (combo.items[0]?.productImage) || "";

                            return (
                                <div ref={cardRef}>
                                    <div
                                        className="combo-card"
                                        style={{
                                            borderRadius: "var(--radius-xl)",
                                            overflow: "hidden",
                                            background: "var(--bg-card)",
                                            border: "1px solid var(--border-color)",
                                            transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
                                            cursor: "pointer",
                                        }}
                                        onMouseEnter={(e) => {
                                            e.currentTarget.style.borderColor = "rgba(139,92,246,0.3)";
                                            e.currentTarget.style.transform = "translateY(-8px)";
                                            e.currentTarget.style.boxShadow = "0 24px 48px rgba(0,0,0,0.5), 0 0 30px rgba(139,92,246,0.1)";
                                        }}
                                        onMouseLeave={(e) => {
                                            e.currentTarget.style.borderColor = "var(--border-color)";
                                            e.currentTarget.style.transform = "translateY(0)";
                                            e.currentTarget.style.boxShadow = "none";
                                        }}
                                    >
                                        {/* Hero image */}
                                        <div style={{ position: "relative", aspectRatio: "16/9", overflow: "hidden" }}>
                                            {firstImage ? (
                                                <Image src={firstImage} alt={combo.name} fill style={{ objectFit: "cover", transition: "transform 0.5s ease" }} sizes="(max-width: 768px) 100vw, 400px" />
                                            ) : (
                                                <div style={{ width: "100%", height: "100%", background: "linear-gradient(135deg, #1a0a30, #2d1b69)" }} />
                                            )}
                                            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.7) 0%, rgba(0,0,0,0.1) 50%, transparent 100%)" }} />

                                            {/* Badges */}
                                            <div style={{ position: "absolute", top: "var(--space-md)", left: "var(--space-md)", display: "flex", gap: "6px" }}>
                                                <span style={{
                                                    padding: "5px 12px",
                                                    borderRadius: "var(--radius-full)",
                                                    background: "rgba(139,92,246,0.2)",
                                                    backdropFilter: "blur(8px)",
                                                    border: "1px solid rgba(139,92,246,0.3)",
                                                    color: "#fff",
                                                    fontSize: "0.7rem",
                                                    fontWeight: 700,
                                                    letterSpacing: "0.08em",
                                                    textTransform: "uppercase",
                                                }}>
                                                    {combo.items.length} sản phẩm
                                                </span>
                                                {hasPromo && (
                                                    <span style={{
                                                        padding: "5px 12px",
                                                        borderRadius: "var(--radius-full)",
                                                        background: "rgba(239,68,68,0.2)",
                                                        backdropFilter: "blur(8px)",
                                                        border: "1px solid rgba(239,68,68,0.3)",
                                                        color: "#ff6b6b",
                                                        fontSize: "0.7rem",
                                                        fontWeight: 700,
                                                        letterSpacing: "0.08em",
                                                    }}>
                                                        ƯU ĐÃI -{Math.round(savedPercent)}%
                                                    </span>
                                                )}
                                            </div>

                                            {/* Combo name overlay */}
                                            <div style={{ position: "absolute", bottom: "var(--space-lg)", left: "var(--space-lg)", right: "var(--space-lg)", zIndex: 2 }}>
                                                <h3 style={{ fontSize: "1.2rem", fontWeight: 700, color: "#fff", letterSpacing: "-0.01em", marginBottom: "4px" }}>
                                                    {combo.name}
                                                </h3>
                                                {combo.description && (
                                                    <p style={{ fontSize: "0.8rem", color: "rgba(255,255,255,0.6)", lineHeight: 1.4, display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
                                                        {combo.description}
                                                    </p>
                                                )}
                                            </div>
                                        </div>

                                        {/* Product items list */}
                                        <div style={{ padding: "var(--space-lg)" }}>
                                            <div style={{ display: "flex", flexDirection: "column", gap: "8px", marginBottom: "var(--space-lg)" }}>
                                                {combo.items.map((item) => (
                                                    <Link
                                                        href={`/san-pham/${item.productId}`}
                                                        key={item.productId}
                                                        style={{
                                                            display: "flex",
                                                            alignItems: "center",
                                                            gap: "var(--space-md)",
                                                            padding: "8px 12px",
                                                            borderRadius: "var(--radius-md)",
                                                            background: "var(--bg-surface)",
                                                            border: "1px solid var(--border-color)",
                                                            textDecoration: "none",
                                                            transition: "all 0.2s ease",
                                                        }}
                                                        onMouseEnter={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.background = "var(--bg-elevated)"; }}
                                                        onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.background = "var(--bg-surface)"; }}
                                                    >
                                                        {item.productImage && (
                                                            <div style={{ width: "36px", height: "36px", borderRadius: "var(--radius-sm)", overflow: "hidden", flexShrink: 0, position: "relative" }}>
                                                                <Image src={item.productImage} alt={item.productName} fill style={{ objectFit: "cover" }} sizes="36px" />
                                                            </div>
                                                        )}
                                                        <div style={{ flex: 1, minWidth: 0 }}>
                                                            <p style={{ fontSize: "0.82rem", fontWeight: 500, color: "var(--text-primary)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                                                                {item.productName}
                                                            </p>
                                                            {item.quantity > 1 && (
                                                                <p style={{ fontSize: "0.7rem", color: "var(--text-muted)" }}>x{item.quantity}</p>
                                                            )}
                                                        </div>
                                                        <span style={{ fontSize: "0.82rem", fontWeight: 600, color: "var(--text-secondary)", flexShrink: 0 }}>
                                                            {formatPrice(item.originalPrice * item.quantity)}
                                                        </span>
                                                    </Link>
                                                ))}
                                            </div>

                                            {/* Price section */}
                                            <div style={{
                                                display: "flex",
                                                alignItems: "center",
                                                justifyContent: "space-between",
                                                paddingTop: "var(--space-md)",
                                                borderTop: "1px solid var(--border-color)",
                                            }}>
                                                <div>
                                                    {hasPromo && (
                                                        <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", textDecoration: "line-through", marginBottom: "2px" }}>
                                                            {formatPrice(totalOriginal)}
                                                        </p>
                                                    )}
                                                    <p style={{
                                                        fontSize: "1.2rem",
                                                        fontWeight: 800,
                                                        color: hasPromo ? "#ff6b6b" : "var(--color-accent)",
                                                    }}>
                                                        {formatPrice(effectivePrice)}
                                                    </p>
                                                </div>
                                                <button
                                                    className="btn btn-primary"
                                                    style={{ padding: "10px 24px", fontSize: "0.85rem" }}
                                                    onMouseEnter={(e) => { e.currentTarget.style.boxShadow = "var(--shadow-glow)"; e.currentTarget.style.transform = "translateY(-2px)"; }}
                                                    onMouseLeave={(e) => { e.currentTarget.style.boxShadow = "none"; e.currentTarget.style.transform = "translateY(0)"; }}
                                                    onClick={() => setSelectedCombo(combo)}
                                                >
                                                    Mua Set →
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            );
                        };
                        return <ComboCard key={combo.id} />;
                    })}
                </div>
            </div>
            
            {/* Modal */}
            {selectedCombo && <ComboPurchaseModal combo={selectedCombo} onClose={() => setSelectedCombo(null)} />}
            
            <style jsx global>{`
                @media (max-width: 768px) {
                    .combo-grid { grid-template-columns: 1fr !important; }
                }
            `}</style>
        </section>
    );
}


/* ============================================================
   MAIN PAGE
   ============================================================ */

export default function CollectionPage() {
    const [combos, setCombos] = useState<Combo[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        getCombos().then((combosData) => {
            setCombos(combosData);
            setLoading(false);
        }).catch(() => setLoading(false));
    }, []);

    return (
        <>
            <HeroSection />
            <StorySection />
            <LookbookSection />
            {loading ? (
                <section className="section">
                    <div className="container" style={{ textAlign: "center", padding: "var(--space-4xl) 0" }}>
                        <div style={{ width: "40px", height: "40px", borderRadius: "50%", border: "3px solid var(--border-color)", borderTopColor: "var(--color-accent)", animation: "rotate-slow 1s linear infinite", margin: "0 auto var(--space-lg)" }} />
                        <p style={{ color: "var(--text-muted)" }}>Đang tải...</p>
                    </div>
                </section>
            ) : (
                <ComboSection combos={combos} />
            )}

        </>
    );
}
