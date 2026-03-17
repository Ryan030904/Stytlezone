"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import Link from "next/link";
import { getProducts } from "@/lib/products";
import type { Product } from "@/lib/types";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { saveVoucher, getSavedVouchers } from "@/lib/savedVouchers";
import "./sale.css";

/* ─── Helpers ─── */
function formatPrice(price: number) {
    return new Intl.NumberFormat("vi-VN").format(price) + "đ";
}

function useReveal(direction: "up" | "left" | "right" | "scale" | "fade" = "up", delay = 0) {
    const ref = useRef<HTMLDivElement>(null);
    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        el.classList.add(`reveal-${direction}`);
        if (delay > 0) el.style.transitionDelay = `${delay}s`;
        const obs = new IntersectionObserver(
            ([entry]) => { if (entry.isIntersecting) { el.classList.add("visible"); obs.unobserve(el); } },
            { threshold: 0.1 }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, [direction, delay]);
    return ref;
}

/* ─── Countdown Timer ─── */
function CountdownTimer() {
    const [time, setTime] = useState({ d: 2, h: 14, m: 59, s: 23 });

    useEffect(() => {
        const timer = setInterval(() => {
            setTime(prev => {
                let { d, h, m, s } = prev;
                s--;
                if (s < 0) { s = 59; m--; }
                if (m < 0) { m = 59; h--; }
                if (h < 0) { h = 23; d--; }
                if (d < 0) return { d: 0, h: 0, m: 0, s: 0 };
                return { d, h, m, s };
            });
        }, 1000);
        return () => clearInterval(timer);
    }, []);

    const units = [
        { label: "Ngày", val: String(time.d).padStart(2, "0") },
        { label: "Giờ", val: String(time.h).padStart(2, "0") },
        { label: "Phút", val: String(time.m).padStart(2, "0") },
        { label: "Giây", val: String(time.s).padStart(2, "0") },
    ];

    return (
        <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
            {units.map((unit, i) => (
                <div key={i} style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
                        <div style={{
                            width: "44px", height: "44px",
                            background: "var(--text-primary)", color: "var(--bg-primary)",
                            borderRadius: "8px",
                            display: "flex", alignItems: "center", justifyContent: "center",
                            fontSize: "1.1rem", fontWeight: 800,
                            fontVariantNumeric: "tabular-nums",
                        }}>
                            {unit.val}
                        </div>
                        <span style={{ fontSize: "0.65rem", marginTop: "4px", fontWeight: 600, textTransform: "uppercase", color: "var(--text-muted)", letterSpacing: "0.05em" }}>
                            {unit.label}
                        </span>
                    </div>
                    {i < 3 && <span style={{ fontSize: "1.1rem", fontWeight: 800, color: "var(--text-muted)", marginBottom: "16px" }}>:</span>}
                </div>
            ))}
        </div>
    );
}

/* ─── Voucher Strip ─── */
function VoucherStrip({ onCopy }: { onCopy: (msg: string) => void }) {
    const ref = useReveal("up", 0.1);
    const [savedCodes, setSavedCodes] = useState<string[]>([]);
    const [savingCode, setSavingCode] = useState<string | null>(null);
    const vouchers = [
        { label: "Freeship", desc: "Đơn từ 200K", code: "FREESHIP50", color: "#10b981", minOrderAmount: 200000, discountType: "fixed" as const, discountValue: 50000 },
        { label: "Giảm 100K", desc: "Đơn từ 500K", code: "MEGA100K", color: "#f43f5e", minOrderAmount: 500000, discountType: "fixed" as const, discountValue: 100000 },
        { label: "15% OFF", desc: "Thành viên mới", code: "NEW15", color: "#8B5CF6", minOrderAmount: 0, discountType: "percent" as const, discountValue: 15 },
    ];

    // Load saved state from Firestore
    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (user) => {
            if (!user) return;
            try {
                const saved = await getSavedVouchers(user.uid);
                setSavedCodes(saved.map(s => s.code));
            } catch { /* ignore */ }
        });
        return () => unsubscribe();
    }, []);

    const handleSave = async (v: typeof vouchers[number]) => {
        const user = auth.currentUser;
        if (!user) {
            onCopy("Vui lòng đăng nhập để lưu voucher");
            return;
        }
        if (savedCodes.includes(v.code)) return;
        setSavingCode(v.code);
        try {
            await saveVoucher(user.uid, {
                code: v.code,
                label: v.label,
                description: v.desc,
                minOrderAmount: v.minOrderAmount,
                discountType: v.discountType,
                discountValue: v.discountValue,
                color: v.color,
            });
            setSavedCodes(prev => [...prev, v.code]);
            onCopy(`Đã lưu mã ${v.code} vào kho voucher`);
        } catch {
            onCopy("Lưu voucher thất bại, thử lại sau");
        } finally {
            setSavingCode(null);
        }
    };

    return (
        <div ref={ref} className="sale-voucher-grid" style={{
            display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "12px",
            marginBottom: "var(--space-3xl)",
        }}>
            {vouchers.map((v, i) => {
                const isSaved = savedCodes.includes(v.code);
                const isSaving = savingCode === v.code;
                return (
                    <div
                        key={i}
                        style={{
                            display: "flex", alignItems: "center", gap: "12px",
                            padding: "16px 20px",
                            background: "var(--bg-card)", border: "1px solid var(--border-color)",
                            borderRadius: "12px",
                            transition: "all 0.2s", textAlign: "left",
                        }}
                        onMouseEnter={e => { e.currentTarget.style.borderColor = v.color; e.currentTarget.style.transform = "translateY(-2px)"; }}
                        onMouseLeave={e => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.transform = "translateY(0)"; }}
                    >
                        <div style={{
                            width: "40px", height: "40px", borderRadius: "10px",
                            background: `${v.color}12`, color: v.color,
                            display: "flex", alignItems: "center", justifyContent: "center",
                            fontSize: "1.1rem", fontWeight: 900, flexShrink: 0,
                        }}>%</div>
                        <div style={{ flex: 1 }}>
                            <div style={{ fontSize: "0.85rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "2px" }}>{v.label}</div>
                            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>{v.desc} · <span style={{ color: v.color, fontWeight: 700 }}>{v.code}</span></div>
                        </div>
                        <button
                            onClick={() => handleSave(v)}
                            disabled={isSaved || isSaving}
                            style={{
                                padding: "6px 14px", borderRadius: "6px",
                                background: isSaved ? "var(--bg-surface)" : `${v.color}15`,
                                border: `1px solid ${isSaved ? "var(--border-color)" : `${v.color}30`}`,
                                color: isSaved ? "var(--text-muted)" : v.color,
                                fontSize: "0.72rem", fontWeight: 600,
                                cursor: isSaved || isSaving ? "default" : "pointer",
                                opacity: isSaved ? 0.5 : 1,
                                transition: "all 0.3s ease",
                                flexShrink: 0,
                            }}
                        >
                            {isSaving ? "..." : isSaved ? "Đã lưu ✓" : "Lưu"}
                        </button>
                    </div>
                );
            })}
        </div>
    );
}

/* ─── Product Card ─── */
function SaleProductCard({ product, index }: { product: Product; index: number }) {
    const cardRef = useReveal("scale", index * 0.04);
    const discountPercent = Math.round(((product.price - product.salePrice) / product.price) * 100);

    return (
        <div ref={cardRef} className="sale-card" style={{ display: "flex", flexDirection: "column", height: "100%" }}>
            <Link href={`/san-pham/${product.id}`} style={{ textDecoration: "none", display: "contents" }}>
                <div className="sale-card-img" style={{
                    position: "relative", aspectRatio: "3/4", borderRadius: "12px",
                    overflow: "hidden", background: "var(--bg-surface)", marginBottom: "12px",
                }}>
                    {product.images[0] ? (
                        <img src={product.images[0]} alt={product.name} className="sale-img-main" style={{ width: "100%", height: "100%", objectFit: "cover", transition: "transform 0.5s ease" }} />
                    ) : (
                        <div style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--text-muted)", fontSize: "0.8rem" }}>No image</div>
                    )}
                    {product.images[1] && (
                        <img src={product.images[1]} alt={product.name} className="sale-img-hover" style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", opacity: 0, transition: "opacity 0.4s ease" }} />
                    )}
                    <span style={{
                        position: "absolute", top: "10px", left: "10px",
                        background: "#FF416C", color: "#fff",
                        padding: "4px 8px", borderRadius: "6px",
                        fontSize: "0.72rem", fontWeight: 800, zIndex: 2,
                    }}>
                        -{discountPercent}%
                    </span>
                    {product.sizes.length > 0 && (
                        <div className="sale-quick-sizes" style={{
                            position: "absolute", bottom: 0, left: 0, right: 0,
                            padding: "12px", display: "flex", justifyContent: "center", gap: "4px",
                            background: "linear-gradient(transparent, rgba(0,0,0,0.5))",
                            opacity: 0, transition: "opacity 0.3s", zIndex: 2,
                        }}>
                            {product.sizes.slice(0, 5).map(s => (
                                <span key={s} style={{
                                    width: "28px", height: "28px", borderRadius: "4px",
                                    background: "rgba(255,255,255,0.9)", color: "#000",
                                    fontSize: "0.68rem", fontWeight: 700,
                                    display: "flex", alignItems: "center", justifyContent: "center",
                                }}>{s}</span>
                            ))}
                        </div>
                    )}
                </div>
                <div style={{ flex: 1, display: "flex", flexDirection: "column" }}>
                    <p style={{ fontSize: "0.72rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", fontWeight: 700, marginBottom: "4px" }}>
                        {product.brandName || "StyleZone"}
                    </p>
                    <h3 className="sale-card-title" style={{
                        fontSize: "0.9rem", fontWeight: 600, color: "var(--text-primary)",
                        marginBottom: "8px", lineHeight: 1.4,
                        display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden",
                        transition: "color 0.2s",
                    }}>
                        {product.name}
                    </h3>
                    <div style={{ marginTop: "auto", display: "flex", alignItems: "center", gap: "8px" }}>
                        <span style={{ fontSize: "1rem", fontWeight: 800, color: "var(--text-primary)" }}>
                            {formatPrice(product.salePrice)}
                        </span>
                        <span style={{ fontSize: "0.82rem", color: "var(--text-muted)", textDecoration: "line-through", fontWeight: 400 }}>
                            {formatPrice(product.price)}
                        </span>
                    </div>
                </div>
            </Link>
        </div>
    );
}

/* ─── Toast ─── */
function Toast({ message, visible }: { message: string; visible: boolean }) {
    return (
        <div style={{
            position: "fixed", bottom: "32px", left: "50%",
            transform: visible ? "translate(-50%, 0)" : "translate(-50%, 20px)",
            opacity: visible ? 1 : 0, pointerEvents: "none", zIndex: 10000,
            background: "var(--text-primary)", color: "var(--bg-primary)",
            padding: "12px 24px", borderRadius: "100px",
            fontSize: "0.9rem", fontWeight: 600,
            boxShadow: "0 10px 30px rgba(0,0,0,0.2)",
            transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
            display: "flex", alignItems: "center", gap: "8px",
        }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="3"><polyline points="20 6 9 17 4 12" /></svg>
            {message}
        </div>
    );
}

/* ============================================================
   MAIN PAGE
   ============================================================ */
export default function SalePage() {
    const [loading, setLoading] = useState(true);
    const [allSaleProducts, setAllSaleProducts] = useState<Product[]>([]);
    const [activeTab, setActiveTab] = useState<"all" | "male" | "female">("all");
    const [toastMessage, setToastMessage] = useState("");
    const [showToast, setShowToast] = useState(false);
    const heroRef = useReveal("fade");

    useEffect(() => {
        getProducts(200)
            .then(products => {
                const sales = products.filter(p => p.isActive && p.salePrice > 0 && p.salePrice < p.price);
                sales.sort((a, b) => {
                    const da = (a.price - a.salePrice) / a.price;
                    const db = (b.price - b.salePrice) / b.price;
                    return db - da;
                });
                setAllSaleProducts(sales);
                setLoading(false);
            })
            .catch(() => setLoading(false));
    }, []);

    const showToastMsg = useCallback((msg: string) => {
        setToastMessage(msg);
        setShowToast(true);
        setTimeout(() => setShowToast(false), 3000);
    }, []);

    const filteredProducts = allSaleProducts.filter(p => {
        if (activeTab === "all") return true;
        return p.gender === activeTab || p.gender === "all";
    });

    const flashSaleItems = allSaleProducts.slice(0, 4);

    return (
        <div style={{ background: "var(--bg-primary)", minHeight: "100vh" }}>
            <Toast message={toastMessage} visible={showToast} />

            {/* ─── Hero Banner (full-bleed behind header) ─── */}
            <div ref={heroRef} style={{
                position: "relative", overflow: "hidden",
                minHeight: "420px",
                display: "flex", alignItems: "center",
                background: "linear-gradient(135deg, #0f172a 0%, #1e293b 100%)",
                paddingTop: "var(--header-height)",
            }}>
                <div style={{ position: "absolute", right: "-5%", top: "-30%", width: "400px", height: "400px", background: "radial-gradient(circle, rgba(255,65,108,0.15), transparent 70%)", pointerEvents: "none" }} />
                <div style={{ position: "absolute", left: "20%", bottom: "-20%", width: "300px", height: "300px", background: "radial-gradient(circle, rgba(139,92,246,0.1), transparent 70%)", pointerEvents: "none" }} />

                <div className="container" style={{ maxWidth: "1200px", position: "relative", zIndex: 2 }}>
                    <div style={{ padding: "clamp(2rem, 4vw, 3.5rem) 0", maxWidth: "560px" }}>
                        <div style={{
                            display: "inline-flex", alignItems: "center", gap: "8px",
                            background: "rgba(255,65,108,0.15)", border: "1px solid rgba(255,65,108,0.25)",
                            padding: "6px 14px", borderRadius: "100px", marginBottom: "20px",
                        }}>
                            <span style={{ width: "6px", height: "6px", borderRadius: "50%", background: "#FF416C", boxShadow: "0 0 8px #FF416C", animation: "pulse-glow 2s infinite" }} />
                            <span style={{ color: "#FF416C", fontSize: "0.72rem", fontWeight: 700, letterSpacing: "0.15em", textTransform: "uppercase" }}>Limited Time</span>
                        </div>

                        <h1 style={{
                            fontSize: "clamp(2rem, 5vw, 3.5rem)", fontWeight: 900,
                            lineHeight: 1.1, color: "#fff", marginBottom: "16px", letterSpacing: "-0.03em",
                        }}>
                            Ưu Đãi <br />
                            <span style={{ background: "linear-gradient(135deg, #FF416C, #FF4B2B)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Cuối Mùa</span>
                        </h1>

                        <p style={{ fontSize: "clamp(0.9rem, 1.5vw, 1.05rem)", color: "rgba(255,255,255,0.8)", lineHeight: 1.6, marginBottom: "28px", maxWidth: "400px" }}>
                            Giảm đến 50% cho toàn bộ sản phẩm cao cấp. Nâng cấp phong cách với mức giá không tưởng.
                        </p>

                        <CountdownTimer />
                    </div>
                </div>

                <div style={{
                    position: "absolute", right: "clamp(2rem, 5vw, 4rem)", top: "50%", transform: "translateY(-50%)",
                    fontSize: "clamp(6rem, 12vw, 10rem)", fontWeight: 900, color: "rgba(255,255,255,0.03)",
                    letterSpacing: "-0.05em", lineHeight: 0.9, zIndex: 1, pointerEvents: "none",
                    textAlign: "right",
                }}>
                    SALE<br />50%
                </div>
            </div>

            {/* ─── Content below hero ─── */}
            <section style={{ paddingTop: "var(--space-3xl)", paddingBottom: "80px" }}>
                <div className="container" style={{ maxWidth: "1200px" }}>

                    <VoucherStrip onCopy={showToastMsg} />

                    {flashSaleItems.length > 0 && (
                        <div style={{ marginBottom: "var(--space-3xl)" }}>
                            <div style={{ display: "flex", alignItems: "center", gap: "12px", marginBottom: "var(--space-xl)" }}>
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#FF416C" strokeWidth="2.5"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" /></svg>
                                <h2 style={{ fontSize: "1.25rem", fontWeight: 800, color: "var(--text-primary)", letterSpacing: "-0.01em" }}>Flash Sale</h2>
                                <div style={{ height: "1px", flex: 1, background: "var(--border-color)" }} />
                                <Link href="#all-products" style={{ fontSize: "0.82rem", fontWeight: 600, color: "var(--text-muted)", textDecoration: "none", transition: "color 0.2s" }}>Xem tất cả →</Link>
                            </div>
                            <div className="sale-flash-grid" style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "20px" }}>
                                {flashSaleItems.map((product, i) => (
                                    <SaleProductCard key={`fs-${product.id}`} product={product} index={i} />
                                ))}
                            </div>
                        </div>
                    )}

                    <div id="all-products">
                        <div style={{
                            display: "flex", alignItems: "center", justifyContent: "space-between",
                            marginBottom: "var(--space-xl)", flexWrap: "wrap", gap: "16px",
                        }}>
                            <h2 style={{ fontSize: "1.25rem", fontWeight: 800, color: "var(--text-primary)", letterSpacing: "-0.01em" }}>
                                Tất Cả Sản Phẩm Sale
                            </h2>
                            <div style={{
                                display: "flex", gap: "4px", padding: "4px",
                                background: "var(--bg-surface)", borderRadius: "10px",
                                border: "1px solid var(--border-color)",
                            }}>
                                {[
                                    { id: "all", label: "Tất cả" },
                                    { id: "male", label: "Nam" },
                                    { id: "female", label: "Nữ" },
                                ].map(tab => {
                                    const active = activeTab === tab.id;
                                    return (
                                        <button
                                            key={tab.id}
                                            onClick={() => setActiveTab(tab.id as typeof activeTab)}
                                            style={{
                                                padding: "8px 20px", borderRadius: "8px",
                                                background: active ? "var(--text-primary)" : "transparent",
                                                color: active ? "var(--bg-primary)" : "var(--text-secondary)",
                                                fontSize: "0.82rem", fontWeight: 600,
                                                border: "none", cursor: "pointer", transition: "all 0.2s",
                                            }}
                                        >
                                            {tab.label}
                                        </button>
                                    );
                                })}
                            </div>
                        </div>

                        {loading ? (
                            <div style={{ textAlign: "center", padding: "80px 0" }}>
                                <div className="sale-spinner" style={{
                                    width: "40px", height: "40px", borderRadius: "50%",
                                    border: "3px solid var(--border-color)", borderTopColor: "var(--text-primary)",
                                    margin: "0 auto 16px",
                                }} />
                                <p style={{ color: "var(--text-muted)", fontSize: "0.9rem" }}>Đang tải sản phẩm...</p>
                            </div>
                        ) : filteredProducts.length > 0 ? (
                            <div className="sale-grid" style={{
                                display: "grid",
                                gridTemplateColumns: "repeat(4, 1fr)",
                                gap: "32px 20px",
                            }}>
                                {filteredProducts.map((product, i) => (
                                    <SaleProductCard key={product.id} product={product} index={i} />
                                ))}
                            </div>
                        ) : (
                            <div style={{
                                textAlign: "center", padding: "60px 24px",
                                background: "var(--bg-card)", borderRadius: "16px",
                                border: "1px dashed var(--border-color)",
                            }}>
                                <p style={{ color: "var(--text-secondary)", fontSize: "1rem", marginBottom: "16px" }}>
                                    Không có sản phẩm Sale trong danh mục này.
                                </p>
                                <button
                                    onClick={() => setActiveTab("all")}
                                    style={{
                                        background: "var(--bg-surface)", color: "var(--text-primary)",
                                        border: "1px solid var(--border-color)",
                                        padding: "10px 28px", borderRadius: "100px",
                                        fontSize: "0.85rem", fontWeight: 700, cursor: "pointer",
                                    }}
                                >
                                    Xem tất cả
                                </button>
                            </div>
                        )}
                    </div>

                    {/* ─── CTA Banner ─── */}
                    <div style={{
                        position: "relative", borderRadius: "16px", overflow: "hidden",
                        marginTop: "var(--space-3xl)", padding: "48px 32px",
                        display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center",
                        background: "linear-gradient(135deg, #0f172a 0%, #1e293b 100%)", color: "#fff",
                    }}>
                        <div style={{ position: "absolute", right: "-5%", top: "-20%", width: "250px", height: "250px", background: "#FF416C", filter: "blur(100px)", opacity: 0.15 }} />

                        <h2 style={{ position: "relative", zIndex: 2, fontSize: "clamp(1.5rem, 3vw, 2rem)", fontWeight: 800, marginBottom: "12px", letterSpacing: "-0.02em" }}>
                            Đăng ký thành viên — Mở khoá ưu đãi ẩn
                        </h2>
                        <p style={{ position: "relative", zIndex: 2, fontSize: "0.95rem", color: "rgba(255,255,255,0.8)", marginBottom: "24px", maxWidth: "480px", lineHeight: 1.6 }}>
                            Nhận voucher độc quyền và ưu đãi sinh nhật lên đến 500.000đ khi trở thành StyleZone Member.
                        </p>
                        <Link href="/dang-ky" style={{
                            position: "relative", zIndex: 2,
                            display: "inline-flex", alignItems: "center", gap: "6px",
                            padding: "12px 32px", borderRadius: "100px",
                            background: "#fff", color: "#0f172a",
                            fontSize: "0.85rem", fontWeight: 700, textDecoration: "none",
                            transition: "transform 0.2s",
                        }}
                            onMouseEnter={e => e.currentTarget.style.transform = "translateY(-2px)"}
                            onMouseLeave={e => e.currentTarget.style.transform = "translateY(0)"}
                        >
                            Tham gia miễn phí
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
                        </Link>
                    </div>

                </div>
            </section>
        </div>
    );
}
