"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useState, useRef } from "react";
import { getCombos, getComboTotalOriginalPrice, getComboEffectivePrice, isComboPromotionActive, getComboSavedPercent } from "@/lib/combos";
import { getProductsByIds } from "@/lib/products";
import type { Combo } from "@/lib/combos";
import type { Product } from "@/lib/types";
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

/* ============================================================
   SUB-COMPONENTS
   ============================================================ */

function HeroSection() {
    return (
        <section
            style={{
                position: "relative",
                minHeight: "50vh",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                overflow: "hidden",
                background: "linear-gradient(160deg, #000000 0%, #0a0a12 30%, #1a1040 60%, #0d0d18 100%)",
            }}
        >
            {/* Background Image */}
            <div style={{ position: "absolute", inset: 0 }}>
                <Image src="/images/collection/collection-hero.png" alt="Bộ Sưu Tập" fill style={{ objectFit: "cover" }} priority />
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(160deg, rgba(0,0,0,0.7) 0%, rgba(10,10,18,0.5) 40%, rgba(26,16,64,0.6) 70%, rgba(13,13,24,0.75) 100%)" }} />
            </div>

            {/* Floating orbs */}
            <div style={{ position: "absolute", top: "10%", right: "12%", width: "250px", height: "250px", borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.12) 0%, transparent 70%)", animation: "float 6s ease-in-out infinite", pointerEvents: "none" }} />
            <div style={{ position: "absolute", bottom: "5%", left: "8%", width: "180px", height: "180px", borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.08) 0%, transparent 70%)", animation: "float 8s ease-in-out infinite reverse", pointerEvents: "none" }} />

            {/* Content */}
            <div className="container animate-slide-up" style={{ position: "relative", zIndex: 2, textAlign: "center", padding: "var(--space-4xl) var(--space-lg) var(--space-2xl)" }}>
                <div style={{ display: "inline-flex", alignItems: "center", gap: "var(--space-sm)", padding: "5px 14px", borderRadius: "var(--radius-full)", background: "rgba(139,92,246,0.1)", border: "1px solid rgba(139,92,246,0.2)", marginBottom: "var(--space-lg)", fontSize: "0.75rem", fontWeight: 600, letterSpacing: "0.15em", color: "var(--color-accent)", textTransform: "uppercase" }}>
                    <span style={{ width: "6px", height: "6px", borderRadius: "50%", background: "var(--color-accent)", animation: "pulse-glow 2s ease infinite" }} />
                    Bộ Sưu Tập StyleZone
                </div>

                <h1 style={{ fontSize: "clamp(2rem, 5vw, 3.5rem)", fontWeight: 800, lineHeight: 1.3, letterSpacing: "-0.04em", color: "#ffffff", marginBottom: "var(--space-md)", textShadow: "0 2px 12px rgba(0,0,0,0.5)" }}>
                    Bộ Sưu{" "}
                    <span style={{ fontStyle: "italic", color: "#a78bfa" }}>Tập</span>
                </h1>

                <p style={{ color: "rgba(255,255,255,0.75)", fontSize: "clamp(0.9rem, 1.5vw, 1.05rem)", maxWidth: "560px", margin: "0 auto", lineHeight: 1.7, textShadow: "0 1px 6px rgba(0,0,0,0.4)" }}>
                    Khẳng định phong cách cá nhân — nơi sự tự tin gặp gỡ thời trang đẳng cấp.
                </p>
            </div>
        </section>
    );
}

/* ─── Storytelling Section ─── */
function StorySection() {
    const leftRef = useReveal("left");
    const rightRef = useReveal("right", { delay: 0.15 });

    const HIGHLIGHTS = [
        { icon: "✦", title: "Chất liệu cao cấp", desc: "Linen & cotton organic cao cấp, thoáng mát cho mùa hè." },
        { icon: "◈", title: "Palette đa dạng", desc: "Tông neutral, earth tone & pastel — phù hợp cả nam lẫn nữ." },
        { icon: "✧", title: "Thiết kế giới hạn", desc: "Chỉ 24 mẫu thiết kế, mỗi mẫu giới hạn 200 sản phẩm." },
    ];

    return (
        <section className="section" style={{ overflow: "hidden" }}>
            <div className="container" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-4xl)", alignItems: "center" }} id="story">
                <div ref={leftRef}>
                    <p style={{ fontSize: "0.7rem", fontWeight: 600, letterSpacing: "0.2em", textTransform: "uppercase", color: "var(--color-accent)", marginBottom: "var(--space-lg)" }}>
                        Câu Chuyện Thiết Kế
                    </p>
                    <h2 style={{ fontSize: "clamp(1.8rem, 3vw, 2.5rem)", fontWeight: 700, lineHeight: 1.2, letterSpacing: "-0.03em", marginBottom: "var(--space-lg)" }}>
                        Nơi Ánh Nắng <br />
                        <span className="gradient-text">Gặp Phong Cách</span>
                    </h2>
                    <p style={{ color: "var(--text-secondary)", fontSize: "0.95rem", lineHeight: 1.8, marginBottom: "var(--space-2xl)" }}>
                        Bộ sưu tập <strong>Summer Muse 2026</strong> dành cho những ai muốn khẳng định phong cách riêng — kết hợp sự thoải mái với nét tinh tế, phù hợp cho cả nam và nữ.
                    </p>

                    {/* Highlight cards */}
                    <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-md)" }}>
                        {HIGHLIGHTS.map((h, i) => {
                            const HItem = () => {
                                const hRef = useReveal("left", { delay: 0.2 + i * 0.12 });
                                return (
                                    <div ref={hRef} style={{ display: "flex", alignItems: "flex-start", gap: "var(--space-md)", padding: "var(--space-md) var(--space-lg)", borderRadius: "var(--radius-lg)", background: "var(--bg-card)", border: "1px solid var(--border-color)", transition: "all 0.3s ease" }}
                                        onMouseEnter={(e) => { e.currentTarget.style.borderColor = "rgba(139,92,246,0.25)"; e.currentTarget.style.transform = "translateX(4px)"; }}
                                        onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.transform = "translateX(0)"; }}
                                    >
                                        <div style={{ width: "36px", height: "36px", borderRadius: "var(--radius-md)", background: "rgba(139,92,246,0.1)", color: "var(--color-accent)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, fontSize: "1rem" }}>
                                            {h.icon}
                                        </div>
                                        <div>
                                            <h4 style={{ fontSize: "0.88rem", fontWeight: 600, color: "var(--text-primary)", marginBottom: "2px" }}>{h.title}</h4>
                                            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", lineHeight: 1.5 }}>{h.desc}</p>
                                        </div>
                                    </div>
                                );
                            };
                            return <HItem key={h.title} />;
                        })}
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

/* ─── Collection Features ─── */
function CollectionFeatures() {
    const titleRef = useReveal("down");

    const FEATURES = [
        {
            image: "/images/collection/lookbook-secondary.png",
            title: "Phong Cách Nữ Tính",
            desc: "Đầm midi, áo blouse và phụ kiện mùa hè — thanh lịch nhưng không kém phần tự do.",
        },
        {
            image: "/images/collection/lookbook-detail.png",
            title: "Chi Tiết Tinh Tế",
            desc: "Từ đường may đến chất liệu, mỗi sản phẩm đều trải qua 12 công đoạn kiểm tra chất lượng.",
        },
        {
            image: "/images/collection/Phong Cách Đường Phố.png",
            title: "Phong Cách Đường Phố",
            desc: "Mix & match linh hoạt — từ outfit đi biển đến set đồ đường phố cá tính.",
        },
    ];

    return (
        <section className="section" style={{ background: "var(--bg-secondary)" }}>
            <div className="container">
                <div ref={titleRef} style={{ textAlign: "center", marginBottom: "var(--space-3xl)" }}>
                    <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
                    <h2 className="section-title">Điểm Nhấn Bộ Sưu Tập</h2>
                    <p className="section-subtitle">Khám phá những phong cách đa dạng trong Summer Muse</p>
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "var(--space-xl)" }} className="features-grid">
                    {FEATURES.map((f, i) => {
                        const FeatureCard = () => {
                            const dir: RevealDirection = i === 0 ? "left" : i === 2 ? "right" : "up";
                            const cardRef = useReveal(dir, { delay: i * 0.12 });
                            return (
                                <div
                                    ref={cardRef}
                                    style={{
                                        borderRadius: "var(--radius-xl)",
                                        overflow: "hidden",
                                        background: "var(--bg-card)",
                                        border: "1px solid var(--border-color)",
                                        transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
                                    }}
                                    onMouseEnter={(e) => { e.currentTarget.style.borderColor = "rgba(139,92,246,0.25)"; e.currentTarget.style.transform = "translateY(-6px)"; e.currentTarget.style.boxShadow = "0 16px 40px rgba(0,0,0,0.15), 0 0 20px rgba(139,92,246,0.06)"; }}
                                    onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "none"; }}
                                >
                                    {/* Image */}
                                    <div style={{ position: "relative", aspectRatio: "4/3", overflow: "hidden" }}>
                                        <Image src={f.image} alt={f.title} fill style={{ objectFit: "cover", transition: "transform 0.5s ease" }} sizes="(max-width: 768px) 100vw, 33vw" />
                                        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.4) 0%, transparent 60%)" }} />
                                    </div>
                                    {/* Content */}
                                    <div style={{ padding: "var(--space-xl)" }}>
                                        <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "var(--space-sm)", letterSpacing: "-0.01em" }}>{f.title}</h3>
                                        <p style={{ fontSize: "0.85rem", color: "var(--text-muted)", lineHeight: 1.7 }}>{f.desc}</p>
                                    </div>
                                </div>
                            );
                        };
                        return <FeatureCard key={f.title} />;
                    })}
                </div>
            </div>
            <style jsx global>{`
                @media (max-width: 1024px) {
                    .features-grid { grid-template-columns: repeat(2, 1fr) !important; }
                }
                @media (max-width: 768px) {
                    .features-grid { grid-template-columns: 1fr !important; }
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
    const [selections, setSelections] = useState<Record<string, { color: string; size: string }>>({});

    useEffect(() => {
        const fetchProducts = async () => {
            const ids = combo.items.map(i => i.productId);
            const prods = await getProductsByIds(ids);
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
        setSelections(prev => ({ ...prev, [productId]: { ...prev[productId], [type]: value } }));
    };

    const savedPercent = getComboSavedPercent(combo);
    const canCheckout = products.every(p => {
        const sel = selections[p.id];
        if (!sel) return false;
        if (p.colors.length > 0 && !sel.color) return false;
        if (p.sizes.length > 0 && !sel.size) return false;
        return true;
    });
    const totalSelectedOriginalPrice = products.reduce((sum, p) => {
        const sel = selections[p.id];
        if (!sel) return sum;
        let itemPrice = p.price;
        if (sel.color && sel.size && p.variants.length > 0) {
            const v = p.variants.find(v => v.color === sel.color && v.size === sel.size);
            if (v && v.price > 0) itemPrice = v.price;
        }
        return sum + itemPrice;
    }, 0);
    const finalComboPrice = totalSelectedOriginalPrice * (1 - savedPercent / 100);

    const handleAddToCart = () => {
        if (!canCheckout) return;
        products.forEach(p => {
            const sel = selections[p.id];
            let basePrice = p.price;
            let img = p.images[0];
            if (sel.color && sel.size && p.variants.length > 0) {
                const v = p.variants.find(v => v.color === sel.color && v.size === sel.size);
                if (v && v.price > 0) basePrice = v.price;
                if (v && v.colorImage) img = v.colorImage;
            }
            const discountedPrice = basePrice * (1 - savedPercent / 100);
            addToCart({
                productId: p.id, name: p.name, image: img, price: basePrice,
                salePrice: Math.round(discountedPrice), brandName: p.brandName,
                size: sel.size, color: sel.color, quantity: 1
            });
        });
        onClose();
        toast.success("Đã thêm toàn bộ sản phẩm trong Combo vào Giỏ! 🎉");
    };

    return (
        <div style={{ position: "fixed", inset: 0, zIndex: 1000, display: "flex", alignItems: "center", justifyContent: "center", padding: "var(--space-md)" }}>
            <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.8)", backdropFilter: "blur(6px)" }} onClick={onClose} />
            <div style={{ position: "relative", width: "100%", maxWidth: "600px", maxHeight: "90vh", background: "var(--bg-card)", borderRadius: "var(--radius-xl)", border: "1px solid var(--border-color)", display: "flex", flexDirection: "column", overflow: "hidden", animation: "modal-in 0.3s cubic-bezier(0.16, 1, 0.3, 1)" }}>
                <div style={{ padding: "var(--space-lg)", borderBottom: "1px solid var(--border-color)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                    <div>
                        <h3 style={{ fontSize: "1.2rem", fontWeight: 700, color: "var(--text-primary)" }}>Thêm Set Vào Giỏ</h3>
                        <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>{combo.name}</p>
                    </div>
                    <button onClick={onClose} style={{ width: "32px", height: "32px", borderRadius: "50%", background: "var(--bg-surface)", border: "1px solid var(--border-color)", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", transition: "all 0.2s" }} onMouseEnter={(e) => e.currentTarget.style.borderColor = "var(--text-primary)"} onMouseLeave={(e) => e.currentTarget.style.borderColor = "var(--border-color)"}>
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--text-primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    </button>
                </div>
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
                                            {p.colors.length > 0 && (
                                                <div style={{ marginBottom: "var(--space-sm)" }}>
                                                    <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginBottom: "4px" }}>Màu sắc</p>
                                                    <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                                                        {p.colors.map(c => (
                                                            <button type="button" key={c} onClick={() => handleSelect(p.id, "color", c)}
                                                                style={{ padding: "4px 10px", fontSize: "0.75rem", borderRadius: "var(--radius-sm)", border: `1px solid ${sel.color === c ? 'var(--color-accent)' : 'var(--border-color)'}`, background: sel.color === c ? 'rgba(139,92,246,0.1)' : 'var(--bg-surface)', color: sel.color === c ? 'var(--color-accent)' : 'var(--text-secondary)', cursor: "pointer", outline: "none", userSelect: "none" }}
                                                            >{c}</button>
                                                        ))}
                                                    </div>
                                                </div>
                                            )}
                                            {p.sizes.length > 0 && (
                                                <div>
                                                    <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginBottom: "4px" }}>Kích thước</p>
                                                    <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                                                        {p.sizes.map(s => (
                                                            <button type="button" key={s} onClick={() => handleSelect(p.id, "size", s)}
                                                                style={{ padding: "4px 10px", fontSize: "0.75rem", borderRadius: "var(--radius-sm)", border: `1px solid ${sel.size === s ? 'var(--color-accent)' : 'var(--border-color)'}`, background: sel.size === s ? 'rgba(139,92,246,0.1)' : 'var(--bg-surface)', color: sel.size === s ? 'var(--color-accent)' : 'var(--text-secondary)', cursor: "pointer", outline: "none", userSelect: "none" }}
                                                            >{s}</button>
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
                {!loading && (
                    <div style={{ padding: "var(--space-lg)", borderTop: "1px solid var(--border-color)", background: "var(--bg-surface)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                        <div>
                            <div style={{ display: "flex", alignItems: "center", gap: "6px", marginBottom: "2px" }}>
                                <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", textDecoration: "line-through" }}>{formatPrice(totalSelectedOriginalPrice)}</p>
                                <span style={{ padding: "2px 6px", borderRadius: "4px", background: "rgba(239,68,68,0.15)", color: "#ff6b6b", fontSize: "0.7rem", fontWeight: 700 }}>-{Math.round(savedPercent)}%</span>
                            </div>
                            <p style={{ fontSize: "1.3rem", fontWeight: 800, color: "var(--color-accent)" }}>{formatPrice(finalComboPrice)}</p>
                        </div>
                        <button disabled={!canCheckout} onClick={handleAddToCart}
                            style={{ padding: "12px 32px", borderRadius: "var(--radius-md)", background: canCheckout ? "var(--color-accent)" : "var(--bg-elevated)", color: canCheckout ? "#fff" : "var(--text-muted)", fontWeight: 600, border: "none", cursor: canCheckout ? "pointer" : "not-allowed", opacity: canCheckout ? 1 : 0.7, transition: "all 0.2s" }}
                        >Thêm Vào Giỏ</button>
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
                                    <div className="combo-card"
                                        style={{ borderRadius: "var(--radius-xl)", overflow: "hidden", background: "var(--bg-card)", border: "1px solid var(--border-color)", transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)", cursor: "pointer" }}
                                        onMouseEnter={(e) => { e.currentTarget.style.borderColor = "rgba(139,92,246,0.3)"; e.currentTarget.style.transform = "translateY(-8px)"; e.currentTarget.style.boxShadow = "0 24px 48px rgba(0,0,0,0.5), 0 0 30px rgba(139,92,246,0.1)"; }}
                                        onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "none"; }}
                                    >
                                        <div style={{ position: "relative", aspectRatio: "16/9", overflow: "hidden" }}>
                                            {firstImage ? (
                                                <Image src={firstImage} alt={combo.name} fill style={{ objectFit: "cover", transition: "transform 0.5s ease" }} sizes="(max-width: 768px) 100vw, 400px" />
                                            ) : (
                                                <div style={{ width: "100%", height: "100%", background: "linear-gradient(135deg, #1a0a30, #2d1b69)" }} />
                                            )}
                                            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.7) 0%, rgba(0,0,0,0.1) 50%, transparent 100%)" }} />
                                            <div style={{ position: "absolute", top: "var(--space-md)", left: "var(--space-md)", display: "flex", gap: "6px" }}>
                                                <span style={{ padding: "5px 12px", borderRadius: "var(--radius-full)", background: "rgba(139,92,246,0.2)", backdropFilter: "blur(8px)", border: "1px solid rgba(139,92,246,0.3)", color: "#fff", fontSize: "0.7rem", fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase" }}>
                                                    {combo.items.length} sản phẩm
                                                </span>
                                                {hasPromo && (
                                                    <span style={{ padding: "5px 12px", borderRadius: "var(--radius-full)", background: "rgba(239,68,68,0.2)", backdropFilter: "blur(8px)", border: "1px solid rgba(239,68,68,0.3)", color: "#ff6b6b", fontSize: "0.7rem", fontWeight: 700, letterSpacing: "0.08em" }}>
                                                        ƯU ĐÃI -{Math.round(savedPercent)}%
                                                    </span>
                                                )}
                                            </div>
                                            <div style={{ position: "absolute", bottom: "var(--space-lg)", left: "var(--space-lg)", right: "var(--space-lg)", zIndex: 2 }}>
                                                <h3 style={{ fontSize: "1.2rem", fontWeight: 700, color: "#fff", letterSpacing: "-0.01em", marginBottom: "4px" }}>{combo.name}</h3>
                                                {combo.description && (
                                                    <p style={{ fontSize: "0.8rem", color: "rgba(255,255,255,0.8)", lineHeight: 1.4, display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>{combo.description}</p>
                                                )}
                                            </div>
                                        </div>
                                        <div style={{ padding: "var(--space-lg)" }}>
                                            <div style={{ display: "flex", flexDirection: "column", gap: "8px", marginBottom: "var(--space-lg)" }}>
                                                {combo.items.map((item) => (
                                                    <Link href={`/san-pham/${item.productId}`} key={item.productId}
                                                        style={{ display: "flex", alignItems: "center", gap: "var(--space-md)", padding: "8px 12px", borderRadius: "var(--radius-md)", background: "var(--bg-surface)", border: "1px solid var(--border-color)", textDecoration: "none", transition: "all 0.2s ease" }}
                                                        onMouseEnter={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.background = "var(--bg-elevated)"; }}
                                                        onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.background = "var(--bg-surface)"; }}
                                                    >
                                                        {item.productImage && (
                                                            <div style={{ width: "36px", height: "36px", borderRadius: "var(--radius-sm)", overflow: "hidden", flexShrink: 0, position: "relative" }}>
                                                                <Image src={item.productImage} alt={item.productName} fill style={{ objectFit: "cover" }} sizes="36px" />
                                                            </div>
                                                        )}
                                                        <div style={{ flex: 1, minWidth: 0 }}>
                                                            <p style={{ fontSize: "0.82rem", fontWeight: 500, color: "var(--text-primary)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{item.productName}</p>
                                                            {item.quantity > 1 && <p style={{ fontSize: "0.7rem", color: "var(--text-muted)" }}>x{item.quantity}</p>}
                                                        </div>
                                                        <span style={{ fontSize: "0.82rem", fontWeight: 600, color: "var(--text-secondary)", flexShrink: 0 }}>{formatPrice(item.originalPrice * item.quantity)}</span>
                                                    </Link>
                                                ))}
                                            </div>
                                            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", paddingTop: "var(--space-md)", borderTop: "1px solid var(--border-color)" }}>
                                                <div>
                                                    {hasPromo && <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", textDecoration: "line-through", marginBottom: "2px" }}>{formatPrice(totalOriginal)}</p>}
                                                    <p style={{ fontSize: "1.2rem", fontWeight: 800, color: hasPromo ? "#ff6b6b" : "var(--color-accent)" }}>{formatPrice(effectivePrice)}</p>
                                                </div>
                                                <button className="btn btn-primary" style={{ padding: "10px 24px", fontSize: "0.85rem" }}
                                                    onMouseEnter={(e) => { e.currentTarget.style.boxShadow = "var(--shadow-glow)"; e.currentTarget.style.transform = "translateY(-2px)"; }}
                                                    onMouseLeave={(e) => { e.currentTarget.style.boxShadow = "none"; e.currentTarget.style.transform = "translateY(0)"; }}
                                                    onClick={() => setSelectedCombo(combo)}
                                                >Mua Set →</button>
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
            {selectedCombo && <ComboPurchaseModal combo={selectedCombo} onClose={() => setSelectedCombo(null)} />}
            <style jsx global>{`
                @media (max-width: 768px) {
                    .combo-grid { grid-template-columns: 1fr !important; }
                }
            `}</style>
        </section>
    );
}


/* ─── Season Timeline ─── */
function SeasonTimeline() {
    const titleRef = useReveal("up");

    const SEASONS = [
        { season: "XUÂN 2025", name: "Bloom", desc: "Sắc hoa và họa tiết nhẹ nhàng — mở đầu cho dòng thiết kế hữu cơ.", color: "#ec4899" },
        { season: "HÈ 2025", name: "Drift", desc: "Phong cách biển cả — linen thoáng mát, tông xanh dịu và trắng ngà.", color: "#06b6d4" },
        { season: "THU 2025", name: "Ember", desc: "Tông ấm, chất liệu dày dặn — layer outfit cho ngày se lạnh.", color: "#f59e0b" },
        { season: "HÈ 2026", name: "Muse", desc: "Phong cách tự do, chất liệu cao cấp — tôn vinh cá tính cho cả nam và nữ.", color: "#8b5cf6", active: true },
    ];

    return (
        <section className="section">
            <div className="container">
                <div ref={titleRef} style={{ textAlign: "center", marginBottom: "var(--space-3xl)" }}>
                    <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
                    <h2 className="section-title">Hành Trình Bộ Sưu Tập</h2>
                    <p className="section-subtitle">Mỗi mùa, một câu chuyện thời trang mới</p>
                </div>

                <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "var(--space-lg)", position: "relative", alignItems: "stretch" }} className="timeline-grid">
                    {/* Connecting line - centered through all dots */}
                    <div className="timeline-line" style={{ position: "absolute", top: "11px", left: "12.5%", right: "12.5%", height: "2px", background: "linear-gradient(to right, rgba(139,92,246,0.1) 0%, rgba(139,92,246,0.3) 50%, rgba(139,92,246,0.5) 100%)", zIndex: 0 }} />

                    {SEASONS.map((s, i) => {
                        const TimelineCard = () => {
                            const cardRef = useReveal("up", { delay: i * 0.15 });
                            return (
                                <div ref={cardRef} style={{ position: "relative", zIndex: 1, textAlign: "center", display: "flex", flexDirection: "column" }}>
                                    {/* Dot container - fixed height so all dots align on same center line */}
                                    <div style={{
                                        height: "24px",
                                        display: "flex",
                                        alignItems: "center",
                                        justifyContent: "center",
                                        marginBottom: "var(--space-md)",
                                        flexShrink: 0,
                                    }}>
                                        <div style={{
                                            width: s.active ? "20px" : "12px",
                                            height: s.active ? "20px" : "12px",
                                            borderRadius: "50%",
                                            background: s.active ? s.color : "var(--bg-card)",
                                            border: `2px solid ${s.color}`,
                                            boxShadow: s.active ? `0 0 20px ${s.color}60` : "none",
                                            transition: "all 0.3s ease",
                                        }} />
                                    </div>

                                    {/* Card */}
                                    <div style={{
                                        padding: "var(--space-xl)",
                                        borderRadius: "var(--radius-lg)",
                                        background: "var(--bg-card)",
                                        border: `1px solid ${s.active ? `${s.color}40` : "var(--border-color)"}`,
                                        transition: "all 0.3s ease",
                                        flex: 1,
                                        display: "flex",
                                        flexDirection: "column",
                                    }}
                                        onMouseEnter={(e) => { e.currentTarget.style.borderColor = `${s.color}50`; e.currentTarget.style.transform = "translateY(-4px)"; }}
                                        onMouseLeave={(e) => { e.currentTarget.style.borderColor = s.active ? `${s.color}40` : "var(--border-color)"; e.currentTarget.style.transform = "translateY(0)"; }}
                                    >
                                        <p style={{ fontSize: "0.65rem", fontWeight: 700, letterSpacing: "0.15em", color: s.color, marginBottom: "var(--space-sm)", textTransform: "uppercase" }}>{s.season}</p>
                                        <h3 style={{ fontSize: "1.3rem", fontWeight: 800, color: "var(--text-primary)", marginBottom: "var(--space-sm)", fontStyle: "italic", letterSpacing: "-0.02em" }}>{s.name}</h3>
                                        <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", lineHeight: 1.6, flex: 1 }}>{s.desc}</p>
                                        {s.active && (
                                            <span style={{ display: "inline-block", marginTop: "var(--space-md)", padding: "4px 12px", borderRadius: "var(--radius-full)", background: `${s.color}15`, color: s.color, fontSize: "0.68rem", fontWeight: 600, letterSpacing: "0.05em" }}>
                                                ĐANG HIỆN HÀNH
                                            </span>
                                        )}
                                    </div>
                                </div>
                            );
                        };
                        return <TimelineCard key={s.name} />;
                    })}
                </div>
            </div>
            <style jsx global>{`
                @media (max-width: 1024px) {
                    .timeline-grid { grid-template-columns: repeat(2, 1fr) !important; }
                    .timeline-line { display: none !important; }
                }
                @media (max-width: 600px) {
                    .timeline-grid { grid-template-columns: 1fr !important; }
                }
            `}</style>
        </section>
    );
}


/* ─── Style Guide: Outfit Suggestions ─── */
function StyleGuide() {
    const titleRef = useReveal("up");

    const OUTFITS = [
        {
            num: "01",
            title: "Beach Escape",
            items: ["Áo linen oversized tông trắng ngà", "Quần short chất đũi xanh biển", "Sandal dây buộc + mũ cói rộng vành"],
            mood: "Thoải mái, phóng khoáng",
            accent: "#f59e0b",
            accentBg: "rgba(245,158,11,0.06)",
            accentBorder: "rgba(245,158,11,0.35)",
        },
        {
            num: "02",
            title: "Urban Sunset",
            items: ["Đầm midi wrap tông terracotta", "Túi xách da thủ công nhỏ gọn", "Bông tai statement hình học"],
            mood: "Sang trọng, hiện đại",
            accent: "#f43f5e",
            accentBg: "rgba(244,63,94,0.06)",
            accentBorder: "rgba(244,63,94,0.35)",
        },
        {
            num: "03",
            title: "Garden Party",
            items: ["Áo blouse hoa nhí pastel", "Chân váy midi xếp ly", "Giày mule gót thấp + kính mắt mèo"],
            mood: "Nữ tính, thanh lịch",
            accent: "#10b981",
            accentBg: "rgba(16,185,129,0.06)",
            accentBorder: "rgba(16,185,129,0.35)",
        },
        {
            num: "04",
            title: "Evening Breeze",
            items: ["Set co-ord linen tông đen", "Blazer mỏng không cổ", "Clutch ánh kim + giày loafer"],
            mood: "Tối giản, tinh tế",
            accent: "#8B5CF6",
            accentBg: "rgba(139,92,246,0.06)",
            accentBorder: "rgba(139,92,246,0.35)",
        },
    ];

    return (
        <section className="section">
            <div className="container">
                <div ref={titleRef} style={{ textAlign: "center", marginBottom: "var(--space-3xl)" }}>
                    <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
                    <h2 className="section-title">Gợi Ý Phong Cách</h2>
                    <p className="section-subtitle">4 cách mix outfit từ bộ sưu tập Summer Muse cho mọi dịp</p>
                </div>

                <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: "var(--space-xl)" }} className="style-guide-grid">
                    {OUTFITS.map((o, i) => {
                        const OutfitCard = () => {
                            const dir: RevealDirection = i % 2 === 0 ? "left" : "right";
                            const cardRef = useReveal(dir, { delay: i * 0.1 });
                            return (
                                <div ref={cardRef} style={{
                                    padding: "var(--space-xl) var(--space-2xl)",
                                    borderRadius: "var(--radius-xl)",
                                    background: `linear-gradient(135deg, ${o.accentBg} 0%, var(--bg-card) 40%)`,
                                    border: "1px solid var(--border-color)",
                                    borderLeft: `3px solid ${o.accentBorder}`,
                                    transition: "all 0.3s ease",
                                    display: "flex",
                                    gap: "var(--space-xl)",
                                    alignItems: "flex-start",
                                    position: "relative",
                                    overflow: "hidden",
                                }}
                                    onMouseEnter={(e) => { e.currentTarget.style.borderColor = o.accentBorder; e.currentTarget.style.borderLeftColor = o.accent; e.currentTarget.style.boxShadow = `0 8px 32px rgba(0,0,0,0.12), 0 0 20px ${o.accentBg}`; e.currentTarget.style.transform = "translateY(-2px)"; }}
                                    onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.borderLeftColor = o.accentBorder; e.currentTarget.style.boxShadow = "none"; e.currentTarget.style.transform = "translateY(0)"; }}
                                >
                                    {/* Decorative corner glow */}
                                    <div style={{ position: "absolute", top: "-20px", right: "-20px", width: "80px", height: "80px", borderRadius: "50%", background: o.accentBg, pointerEvents: "none", filter: "blur(20px)" }} />

                                    {/* Number label */}
                                    <div style={{
                                        width: "48px", height: "48px", borderRadius: "12px",
                                        background: `${o.accent}14`, border: `1.5px solid ${o.accent}30`,
                                        display: "flex", alignItems: "center",
                                        justifyContent: "center", flexShrink: 0,
                                    }}>
                                        <span style={{ fontSize: "1.1rem", fontWeight: 800, color: o.accent, fontVariantNumeric: "tabular-nums", letterSpacing: "-0.02em" }}>{o.num}</span>
                                    </div>
                                    <div style={{ flex: 1 }}>
                                        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "var(--space-md)" }}>
                                            <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "var(--text-primary)", letterSpacing: "-0.01em" }}>{o.title}</h3>
                                            <span style={{ fontSize: "0.68rem", padding: "3px 10px", borderRadius: "var(--radius-full)", background: `${o.accent}12`, color: o.accent, fontWeight: 600, letterSpacing: "0.03em", whiteSpace: "nowrap", fontStyle: "italic" }}>{o.mood}</span>
                                        </div>
                                        <ul style={{ listStyle: "none", padding: 0, margin: 0, display: "flex", flexDirection: "column", gap: "6px" }}>
                                            {o.items.map((item, idx) => (
                                                <li key={idx} style={{ display: "flex", alignItems: "center", gap: "8px", fontSize: "0.85rem", color: "var(--text-secondary)", lineHeight: 1.5 }}>
                                                    <span style={{ width: "5px", height: "5px", borderRadius: "50%", background: o.accent, flexShrink: 0, opacity: 0.7 }} />
                                                    {item}
                                                </li>
                                            ))}
                                        </ul>
                                    </div>
                                </div>
                            );
                        };
                        return <OutfitCard key={o.title} />;
                    })}
                </div>
            </div>
            <style jsx global>{`
                @media (max-width: 768px) {
                    .style-guide-grid { grid-template-columns: 1fr !important; }
                }
            `}</style>
        </section>
    );
}

/* ─── Collection CTA ─── */
function CollectionCTA() {
    const ref = useReveal("up");
    return (
        <section className="section" style={{ background: "var(--bg-secondary)" }}>
            <div ref={ref} className="container" style={{ maxWidth: "800px", textAlign: "center" }}>
                <div style={{
                    padding: "var(--space-3xl) var(--space-2xl)",
                    borderRadius: "var(--radius-xl)",
                    background: "linear-gradient(135deg, rgba(139,92,246,0.08) 0%, rgba(99,102,241,0.04) 50%, rgba(139,92,246,0.08) 100%)",
                    border: "1px solid rgba(139,92,246,0.15)",
                    position: "relative",
                    overflow: "hidden",
                }}>
                    {/* Decorative orbs */}
                    <div style={{ position: "absolute", top: "-30px", right: "-30px", width: "120px", height: "120px", borderRadius: "50%", background: "rgba(139,92,246,0.08)", pointerEvents: "none" }} />
                    <div style={{ position: "absolute", bottom: "-20px", left: "-20px", width: "80px", height: "80px", borderRadius: "50%", background: "rgba(139,92,246,0.06)", pointerEvents: "none" }} />

                    <h3 style={{ fontSize: "clamp(1.2rem, 2.5vw, 1.6rem)", fontWeight: 700, marginBottom: "var(--space-md)", color: "var(--text-primary)", position: "relative", zIndex: 1 }}>
                        Sẵn Sàng Khám Phá <span className="gradient-text">Summer Muse?</span>
                    </h3>
                    <p style={{ color: "var(--text-muted)", fontSize: "0.9rem", lineHeight: 1.7, maxWidth: "520px", margin: "0 auto var(--space-xl)", position: "relative", zIndex: 1 }}>
                        Bộ sưu tập giới hạn — chỉ 24 thiết kế, mỗi mẫu 200 sản phẩm. Đặt hàng sớm để sở hữu phong cách độc quyền.
                    </p>
                    <div style={{ display: "flex", gap: "var(--space-md)", justifyContent: "center", flexWrap: "wrap", position: "relative", zIndex: 1 }}>
                        <Link href="/nam" className="btn btn-primary" style={{ padding: "14px 36px", fontSize: "0.9rem", borderRadius: "var(--radius-full)" }}>
                            Thời Trang Nam →
                        </Link>
                        <Link href="/nu" className="btn btn-outline" style={{ padding: "14px 36px", fontSize: "0.9rem", borderRadius: "var(--radius-full)" }}>
                            Thời Trang Nữ →
                        </Link>
                    </div>
                </div>
            </div>
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
            <CollectionFeatures />
            <SeasonTimeline />
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
            <StyleGuide />
            <CollectionCTA />
        </>
    );
}
