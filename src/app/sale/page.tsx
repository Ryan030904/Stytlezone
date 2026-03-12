"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import Link from "next/link";
import { getProducts } from "@/lib/products";
import type { Product } from "@/lib/types";

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

/* ─── Shared UI Components ─── */
function CountdownTimer() {
    return (
        <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
            {[
                { label: "Ngày", val: "02" },
                { label: "Giờ", val: "14" },
                { label: "Phút", val: "59" },
                { label: "Giây", val: "23" }
            ].map((unit, i) => (
                <div key={i} style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
                    <div style={{
                        width: "48px", height: "48px",
                        background: "rgba(0,0,0,0.6)", backdropFilter: "blur(8px)",
                        border: "1px solid rgba(255,255,255,0.15)",
                        borderRadius: "8px",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        fontSize: "1.2rem", fontWeight: 800, color: "#fff",
                        boxShadow: "inset 0 2px 4px rgba(255,255,255,0.2), 0 4px 12px rgba(0,0,0,0.4)"
                    }}>
                        {unit.val}
                    </div>
                    <span style={{ fontSize: "0.7rem", marginTop: "6px", fontWeight: 700, textTransform: "uppercase", color: "var(--text-secondary)", letterSpacing: "0.05em" }}>
                        {unit.label}
                    </span>
                </div>
            ))}
        </div>
    );
}

function Toast({ message, visible }: { message: string; visible: boolean }) {
    return (
        <div style={{
            position: "fixed", bottom: "40px", left: "50%", transform: visible ? "translate(-50%, 0)" : "translate(-50%, 30px)",
            opacity: visible ? 1 : 0, pointerEvents: "none", zIndex: 10000,
            background: "var(--text-primary)", color: "var(--bg-primary)",
            padding: "12px 24px", borderRadius: "100px",
            fontSize: "0.95rem", fontWeight: 600,
            boxShadow: "0 10px 30px rgba(0,0,0,0.2)",
            transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
            display: "flex", alignItems: "center", gap: "8px"
        }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
            {message}
        </div>
    );
}

/* ─── Advertisement Popup ─── */
function PromoPopup({ onClose }: { onClose: () => void }) {
    const [isVisible, setIsVisible] = useState(false);
    
    useEffect(() => {
        setIsVisible(true);
        document.body.style.overflow = "hidden";
        return () => { document.body.style.overflow = ""; };
    }, []);

    const handleClose = () => {
        setIsVisible(false);
        setTimeout(onClose, 300);
    };

    return (
        <div style={{
            position: "fixed", inset: 0, zIndex: 9999,
            display: "flex", alignItems: "center", justifyContent: "center",
            padding: "var(--space-md)",
            background: isVisible ? "rgba(0,0,0,0.85)" : "rgba(0,0,0,0)",
            backdropFilter: isVisible ? "blur(12px)" : "none",
            transition: "all 0.3s ease", opacity: isVisible ? 1 : 0,
            pointerEvents: isVisible ? "auto" : "none",
        }}>
            <div style={{ position: "absolute", inset: 0, cursor: "pointer" }} onClick={handleClose} />

            <div style={{
                position: "relative", width: "100%", maxWidth: "480px",
                background: "var(--bg-card)",
                borderRadius: "24px", overflow: "hidden",
                boxShadow: "0 30px 80px rgba(0,0,0,0.5)",
                transform: isVisible ? "scale(1) translateY(0)" : "scale(0.9) translateY(40px)",
                transition: "all 0.5s cubic-bezier(0.16, 1, 0.3, 1)",
                zIndex: 2,
            }}>
                <button
                    onClick={handleClose}
                    style={{
                        position: "absolute", top: "16px", right: "16px", zIndex: 10,
                        width: "36px", height: "36px", borderRadius: "50%",
                        background: "rgba(255,255,255,0.1)", backdropFilter: "blur(4px)",
                        border: "1px solid rgba(255,255,255,0.2)",
                        color: "#fff", display: "flex", alignItems: "center", justifyContent: "center",
                        cursor: "pointer", transition: "all 0.2s",
                    }}
                    onMouseEnter={e => { e.currentTarget.style.background = "rgba(255,255,255,0.2)"; e.currentTarget.style.transform = "rotate(90deg)"; }}
                    onMouseLeave={e => { e.currentTarget.style.background = "rgba(255,255,255,0.1)"; e.currentTarget.style.transform = "rotate(0deg)"; }}
                >
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
                </button>

                <div style={{ position: "relative", aspectRatio: "4/3", width: "100%", overflow: "hidden", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
                    <img src="/images/sale/popup-bg.png" alt="Sale" onError={(e) => { e.currentTarget.style.display = 'none'; }} style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", mixBlendMode: "overlay", opacity: 0.5 }} />
                    <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, #1A1A2E 0%, #E94057 100%)", zIndex: -1 }} />
                    
                    <div style={{ position: "relative", zIndex: 2, textAlign: "center", color: "#fff", padding: "0 24px" }}>
                        <span style={{ fontSize: "0.8rem", fontWeight: 800, letterSpacing: "0.2em", textTransform: "uppercase", background: "rgba(0,0,0,0.3)", padding: "6px 16px", borderRadius: "100px", border: "1px solid rgba(255,255,255,0.1)", marginBottom: "16px", display: "inline-block" }}>
                            VIP Exclusive
                        </span>
                        <h2 style={{ fontSize: "3rem", fontWeight: 900, lineHeight: 1.1, letterSpacing: "-0.03em", marginBottom: "8px", textShadow: "0 10px 30px rgba(0,0,0,0.5)" }}>
                            Siêu Sale <br/><span style={{ color: "#FFD700" }}>50% OFF</span>
                        </h2>
                    </div>
                </div>
                
                <div style={{ padding: "32px 24px", textAlign: "center", background: "var(--bg-secondary)" }}>
                    <p style={{ fontSize: "0.95rem", color: "var(--text-secondary)", marginBottom: "24px", lineHeight: 1.6, maxWidth: "340px", margin: "0 auto 24px" }}>
                        Hàng ngàn sản phẩm giới hạn đang giảm giá cực sâu. Nhanh tay săn deal trước khi cháy hàng!
                    </p>
                    <button
                        onClick={handleClose}
                        style={{
                            width: "100%", padding: "16px", borderRadius: "16px",
                            background: "linear-gradient(135deg, #FF416C 0%, #FF4B2B 100%)", color: "#fff",
                            fontSize: "1.05rem", fontWeight: 800, textTransform: "uppercase", letterSpacing: "0.05em",
                            border: "none", cursor: "pointer", transition: "all 0.3s",
                            boxShadow: "0 10px 25px rgba(255, 65, 108, 0.4)",
                        }}
                        onMouseEnter={e => { e.currentTarget.style.transform = "translateY(-3px)"; e.currentTarget.style.boxShadow = "0 15px 35px rgba(255, 65, 108, 0.5)"; }}
                        onMouseLeave={e => { e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "0 10px 25px rgba(255, 65, 108, 0.4)"; }}
                    >
                        Khám Phá Ngay
                    </button>
                    <button
                        onClick={handleClose}
                        style={{
                            marginTop: "16px", background: "transparent", border: "none",
                            color: "var(--text-muted)", fontSize: "0.85rem", fontWeight: 600,
                            cursor: "pointer", padding: "8px"
                        }}
                        onMouseEnter={e => e.currentTarget.style.color = "var(--text-primary)"}
                        onMouseLeave={e => e.currentTarget.style.color = "var(--text-muted)"}
                    >
                        Bỏ qua lần này
                    </button>
                </div>
            </div>
        </div>
    );
}

/* ─── Premium Hero Banner ─── */
function PremiumHeroBanner() {
    const ref = useReveal("fade");
    return (
        <div ref={ref} style={{
            position: "relative",
            width: "100%",
            borderRadius: "24px",
            overflow: "hidden",
            marginBottom: "var(--space-2xl)",
            minHeight: "440px",
            display: "flex", alignItems: "center",
            boxShadow: "0 24px 60px rgba(0,0,0,0.1)",
        }}>
            {/* Background elements */}
            <div style={{ position: "absolute", inset: 0, background: "var(--bg-elevated)", zIndex: 0 }} />
            <img src="/images/sale/hero.webp" alt="" onError={(e) => { e.currentTarget.style.display = 'none'; }} style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", zIndex: 1, opacity: 0.7 }} />
            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(90deg, #0f172a 0%, rgba(15, 23, 42, 0.8) 50%, rgba(15, 23, 42, 0) 100%)", zIndex: 2 }} />
            <div style={{ position: "absolute", left: "-20%", top: "-50%", width: "80%", height: "200%", background: "radial-gradient(circle, rgba(255, 65, 108, 0.15) 0%, transparent 70%)", zIndex: 2, pointerEvents: "none" }} />
            
            <div style={{ position: "relative", zIndex: 3, padding: "clamp(2rem, 5vw, 4rem)", maxWidth: "600px" }}>
                <div style={{ display: "inline-flex", alignItems: "center", gap: "8px", background: "rgba(255,255,255,0.1)", backdropFilter: "blur(8px)", padding: "8px 16px", borderRadius: "100px", border: "1px solid rgba(255,255,255,0.2)", marginBottom: "24px", animation: "pulse-glow 2s infinite" }}>
                    <span style={{ width: "8px", height: "8px", borderRadius: "50%", background: "#FF416C", boxShadow: "0 0 10px #FF416C" }} />
                    <span style={{ color: "#fff", fontSize: "0.8rem", fontWeight: 700, letterSpacing: "0.15em", textTransform: "uppercase" }}>Limited Time Sale</span>
                </div>
                
                <h1 style={{ fontSize: "clamp(2.5rem, 6vw, 4.5rem)", fontWeight: 900, lineHeight: 1.05, color: "#fff", marginBottom: "24px", letterSpacing: "-0.03em" }}>
                    Summer <br />
                    <span style={{ background: "linear-gradient(135deg, #FF416C 0%, #FF4B2B 100%)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Clearance</span>
                </h1>
                
                <p style={{ fontSize: "clamp(1rem, 2vw, 1.15rem)", color: "rgba(255,255,255,0.8)", lineHeight: 1.6, marginBottom: "32px", maxWidth: "420px" }}>
                    Nâng cấp phong cách với mức giá không tưởng. Giảm đến 50% cho toàn bộ các sản phẩm cao cấp thiết yếu.
                </p>
                
                <CountdownTimer />
            </div>
            
            <style jsx>{`
                @keyframes pulse-glow {
                    0% { box-shadow: 0 0 0 0 rgba(255, 65, 108, 0.4); }
                    70% { box-shadow: 0 0 0 10px rgba(255, 65, 108, 0); }
                    100% { box-shadow: 0 0 0 0 rgba(255, 65, 108, 0); }
                }
                @media (max-width: 768px) {
                    div[style*="minHeight: 440px"] { min-height: 500px !important; background-position: center !important; }
                    div[style*="linear-gradient(90deg"] { background: linear-gradient(0deg, #0f172a 0%, rgba(15, 23, 42, 0.6) 100%) !important; }
                }
            `}</style>
        </div>
    );
}

/* ─── Voucher Ticket Components ─── */
function VoucherCards({ onCopy }: { onCopy: (msg: string) => void }) {
    const ref = useReveal("up", 0.1);
    const vouchers = [
        {
            type: "Freeship", amount: "MAX 50K", desc: "Đơn từ 200K", code: "FREESHIP50", color: "#10b981",
            bg: "linear-gradient(135deg, #059669 0%, #10b981 100%)"
        },
        {
            type: "Giảm Giá", amount: "100K OFF", desc: "Đơn từ 500K", code: "MEGA100K", color: "#f43f5e",
            bg: "linear-gradient(135deg, #e11d48 0%, #f43f5e 100%)"
        },
        {
            type: "Thành Viên mới", amount: "15% OFF", desc: "Đơn đầu tiên", code: "NEW15", color: "#6366f1",
            bg: "linear-gradient(135deg, #4f46e5 0%, #6366f1 100%)"
        }
    ];

    return (
        <div ref={ref} style={{ marginBottom: "var(--space-3xl)" }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "var(--space-md)" }}>
                <h2 style={{ fontSize: "1.5rem", fontWeight: 800, color: "var(--text-primary)", letterSpacing: "-0.02em" }}>Mã Ưu Đãi</h2>
                <span style={{ fontSize: "0.85rem", color: "var(--text-secondary)", fontWeight: 500 }}>Sử dụng tại bước Thanh toán</span>
            </div>
            
            <div style={{ display: "flex", gap: "16px", overflowX: "auto", paddingBottom: "16px", scrollbarWidth: "none", msOverflowStyle: "none" }} className="hide-scrollbar">
                {vouchers.map((v, i) => (
                    <div key={i} style={{
                        flex: "0 0 auto", width: "320px", height: "120px",
                        background: "var(--bg-card)",
                        borderRadius: "16px",
                        display: "flex", border: "1px solid var(--border-color)",
                        boxShadow: "0 10px 30px rgba(0,0,0,0.05)",
                        cursor: "pointer", transition: "transform 0.2s, box-shadow 0.2s",
                    }}
                    onMouseEnter={(e) => { e.currentTarget.style.transform = "translateY(-4px)"; e.currentTarget.style.boxShadow = "0 15px 40px rgba(0,0,0,0.08)"; e.currentTarget.style.borderColor = v.color; }}
                    onMouseLeave={(e) => { e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "0 10px 30px rgba(0,0,0,0.05)"; e.currentTarget.style.borderColor = "var(--border-color)"; }}
                    onClick={() => { navigator.clipboard.writeText(v.code); onCopy(`Đã sao chép mã ${v.code}`); }}
                    title="Nhấn để lưu mã"
                    >
                        {/* Left edge dent */}
                        <div style={{ width: "12px", background: "var(--bg-primary)", borderRight: "1px dashed var(--border-color)", clipPath: "polygon(100% 0, 100% 100%, 0 100%, 0 90%, 50% 85%, 50% 15%, 0 10%, 0 0)" }} />
                        
                        {/* Content Left */}
                        <div style={{ flex: 1, padding: "16px", display: "flex", flexDirection: "column", justifyContent: "center" }}>
                            <span style={{ color: v.color, fontSize: "0.75rem", fontWeight: 700, textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "4px" }}>{v.type}</span>
                            <span style={{ fontSize: "1.4rem", fontWeight: 900, color: "var(--text-primary)", lineHeight: 1.1, marginBottom: "4px" }}>{v.amount}</span>
                            <span style={{ fontSize: "0.85rem", color: "var(--text-secondary)" }}>{v.desc}</span>
                        </div>
                        
                        {/* Divider */}
                        <div style={{ width: "0px", borderLeft: "2px dashed var(--border-color)", margin: "16px 0", position: "relative" }}>
                            <div style={{ position: "absolute", top: "-17px", left: "-8px", width: "16px", height: "16px", borderRadius: "50%", background: "var(--bg-primary)", borderBottom: "1px solid var(--border-color)" }} />
                            <div style={{ position: "absolute", bottom: "-17px", left: "-8px", width: "16px", height: "16px", borderRadius: "50%", background: "var(--bg-primary)", borderTop: "1px solid var(--border-color)" }} />
                        </div>
                        
                        {/* Content Right */}
                        <div style={{ width: "100px", padding: "16px", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", borderTopRightRadius: "16px", borderBottomRightRadius: "16px", background: `linear-gradient(to right, rgba(255,255,255,0) 0%, ${v.color}15 100%)` }}>
                            <span style={{ fontSize: "0.85rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "8px" }}>{v.code}</span>
                            <button style={{
                                width: "100%", padding: "6px 0", borderRadius: "100px",
                                background: v.bg, color: "#fff",
                                border: "none", fontSize: "0.75rem", fontWeight: 700,
                                cursor: "pointer", pointerEvents: "none"
                            }}>Lưu</button>
                        </div>
                    </div>
                ))}
            </div>
            <style jsx>{`
                .hide-scrollbar::-webkit-scrollbar { display: none; }
            `}</style>
        </div>
    );
}

/* ─── Flash Sale Scarcity Cards ─── */
function FlashSaleProductCard({ product, index }: { product: Product; index: number }) {
    const cardRef = useReveal("scale", index * 0.1);
    const discountPercent = Math.round(((product.price - product.salePrice) / product.price) * 100);
    // Fake progress
    const soldPercent = 50 + (product.id.charCodeAt(0) % 40); 

    return (
        <div ref={cardRef} className="fs-card" style={{ display: "flex", flexDirection: "column", background: "var(--bg-card)", borderRadius: "16px", overflow: "hidden", border: "1px solid var(--border-color)", cursor: "pointer", transition: "all 0.3s" }}>
            <Link href={`/san-pham/${product.id}`} style={{ textDecoration: "none", display: "contents" }}>
                <div style={{ position: "relative", aspectRatio: "1/1", overflow: "hidden", background: "var(--bg-surface)" }}>
                    {product.images[0] ? (
                        <img src={product.images[0]} alt={product.name} style={{ width: "100%", height: "100%", objectFit: "cover", transition: "transform 0.7s" }} className="fs-img" />
                    ) : (
                        <div style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center" }}>No image</div>
                    )}
                    <div style={{ position: "absolute", top: "12px", right: "12px", background: "#FF416C", color: "#fff", padding: "6px 12px", borderRadius: "100px", fontSize: "0.8rem", fontWeight: 900, boxShadow: "0 4px 12px rgba(255,65,108,0.4)", zIndex: 2 }}>
                        -{discountPercent}%
                    </div>
                </div>
                
                <div style={{ padding: "16px", display: "flex", flexDirection: "column", flex: 1 }}>
                    <h3 style={{ fontSize: "0.95rem", fontWeight: 600, color: "var(--text-primary)", marginBottom: "8px", lineHeight: 1.4, display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
                        {product.name}
                    </h3>
                    <div style={{ display: "flex", alignItems: "end", gap: "8px", marginBottom: "16px" }}>
                        <span style={{ fontSize: "1.2rem", fontWeight: 800, color: "#FF416C", lineHeight: 1 }}>{formatPrice(product.salePrice)}</span>
                        <span style={{ fontSize: "0.85rem", color: "var(--text-muted)", textDecoration: "line-through", fontWeight: 500, lineHeight: 1.2 }}>{formatPrice(product.price)}</span>
                    </div>
                    
                    {/* Progress Bar */}
                    <div style={{ marginTop: "auto" }}>
                        <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.75rem", color: "var(--text-secondary)", marginBottom: "6px", fontWeight: 600 }}>
                            <span>Đã bán: <span style={{ color: "var(--text-primary)" }}>{soldPercent}%</span></span>
                        </div>
                        <div style={{ height: "6px", background: "var(--bg-surface)", borderRadius: "100px", overflow: "hidden", position: "relative" }}>
                            <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: `${soldPercent}%`, background: "linear-gradient(90deg, #FF4B2B 0%, #FF416C 100%)", borderRadius: "100px" }} />
                        </div>
                    </div>
                </div>
            </Link>
            <style jsx>{`
                .fs-card:hover { transform: translateY(-5px); box-shadow: 0 15px 40px rgba(0,0,0,0.08); border-color: var(--color-accent); }
                .fs-card:hover .fs-img { transform: scale(1.08); }
            `}</style>
        </div>
    );
}

/* ─── Production Standard Product Card ─── */
function StandardSaleProductCard({ product, index }: { product: Product; index: number }) {
    const cardRef = useReveal("scale", index * 0.05);
    const discountPercent = Math.round(((product.price - product.salePrice) / product.price) * 100);

    return (
        <div ref={cardRef} className="product-card" style={{ height: "100%", display: "flex", flexDirection: "column" }}>
            <Link href={`/san-pham/${product.id}`} style={{ textDecoration: "none", display: "contents" }}>
                <div className="product-img-wrap" style={{ position: "relative", borderRadius: "16px", overflow: "hidden", aspectRatio: "3/4", background: "var(--bg-card)", marginBottom: "16px" }}>
                    {product.images[0] ? (
                        <img src={product.images[0]} alt={product.name} style={{ width: "100%", height: "100%", objectFit: "cover", transition: "transform 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94)" }} className="main-img" />
                    ) : (
                        <div style={{ width: "100%", height: "100%", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--text-muted)", fontSize: "0.8rem", background: "var(--bg-secondary)" }}>No image</div>
                    )}
                    {product.images[1] && (
                        <img src={product.images[1]} alt={product.name} style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", objectFit: "cover", transition: "opacity 0.4s ease", opacity: 0 }} className="hover-img" />
                    )}

                    <span style={{ position: "absolute", top: "12px", right: "12px", background: "rgba(255, 255, 255, 0.9)", color: "#FF416C", padding: "4px 8px", borderRadius: "6px", fontSize: "0.75rem", fontWeight: 800, zIndex: 2, backdropFilter: "blur(4px)", boxShadow: "0 4px 10px rgba(0,0,0,0.1)" }}>
                        -{discountPercent}%
                    </span>
                    {/* Size Overlay preview hint */}
                    <div className="quick-add-overlay" style={{ position: "absolute", bottom: 0, left: 0, right: 0, padding: "16px", background: "linear-gradient(0deg, rgba(0,0,0,0.6) 0%, transparent 100%)", opacity: 0, transition: "opacity 0.3s", display: "flex", justifyContent: "center", gap: "6px", zIndex: 2 }}>
                        {product.sizes.slice(0, 4).map(s => (
                            <span key={s} style={{ width: "24px", height: "24px", borderRadius: "4px", background: "#fff", color: "#000", fontSize: "0.7rem", fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center" }}>{s}</span>
                        ))}
                    </div>
                </div>
            </Link>

            <Link href={`/san-pham/${product.id}`} style={{ textDecoration: "none", flex: 1, display: "flex", flexDirection: "column" }}>
                <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.05em", fontWeight: 700, marginBottom: "6px" }}>
                    {product.brandName || "StyleZone"}
                </p>
                <h3 className="product-title" style={{ fontSize: "1rem", fontWeight: 600, color: "var(--text-primary)", marginBottom: "8px", lineHeight: 1.4, display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
                    {product.name}
                </h3>
                <div style={{ marginTop: "auto", display: "flex", alignItems: "center", gap: "10px", flexWrap: "wrap" }}>
                    <span style={{ fontSize: "1.1rem", fontWeight: 800, color: "var(--text-primary)" }}>
                        {formatPrice(product.salePrice)}
                    </span>
                    <span style={{ fontSize: "0.85rem", color: "var(--text-muted)", textDecoration: "line-through", fontWeight: 500 }}>
                        {formatPrice(product.price)}
                    </span>
                </div>
            </Link>
            
            <style jsx>{`
                .product-card:hover .main-img { transform: scale(1.05); }
                .product-card:hover .hover-img { opacity: 1; }
                .product-title { transition: color 0.2s; }
                .product-card:hover .product-title { color: var(--color-accent); }
                .product-card:hover .quick-add-overlay { opacity: 1; }
            `}</style>
        </div>
    );
}

/* ─── Bottom CTA Banner ─── */
function StylishFooterBanner() {
    const ref = useReveal("up", 0.1);
    return (
        <div ref={ref} style={{
            position: "relative", width: "100%", borderRadius: "24px", overflow: "hidden",
            marginTop: "60px", padding: "60px 32px",
            display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center",
            background: "linear-gradient(135deg, #1A1A2E 0%, #16213E 100%)",
            color: "#fff",
        }}>
            <div style={{ position: "absolute", inset: 0, opacity: 0.1, background: "url('/images/sale/pattern.png') center/cover" }} />
            <div style={{ position: "absolute", right: "-10%", top: "-10%", width: "300px", height: "300px", background: "#FF416C", filter: "blur(100px)", opacity: 0.3 }} />
            
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#FF416C" strokeWidth="1.5" style={{ marginBottom: "24px", position: "relative", zIndex: 2 }}>
                <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line>
            </svg>
            
            <h2 style={{ position: "relative", zIndex: 2, fontSize: "clamp(2rem, 4vw, 3rem)", fontWeight: 900, marginBottom: "16px", letterSpacing: "-0.02em" }}>
                Khám phá thế giới thời trang dành riêng cho bạn
            </h2>
            <p style={{ position: "relative", zIndex: 2, fontSize: "1.1rem", color: "rgba(255,255,255,0.7)", marginBottom: "32px", maxWidth: "600px", lineHeight: 1.6 }}>
                Trở thành StyleZone Member để mở khóa Vouchers ẩn và nhận Ưu đãi sinh nhật trị giá lên đến 500.000đ.
            </p>
            
            <Link href="/dang-ky" style={{
                position: "relative", zIndex: 2,
                display: "inline-flex", alignItems: "center", gap: "8px",
                padding: "16px 40px", borderRadius: "100px",
                background: "#fff", color: "#1A1A2E",
                fontSize: "1rem", fontWeight: 800, textTransform: "uppercase", letterSpacing: "0.05em", textDecoration: "none",
                transition: "all 0.3s",
                boxShadow: "0 10px 30px rgba(255,255,255,0.2)"
            }}
            onMouseEnter={e => e.currentTarget.style.transform = "translateY(-4px)"}
            onMouseLeave={e => e.currentTarget.style.transform = "translateY(0)"}
            >
                Tham Gia Miễn Phí <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
            </Link>
        </div>
    );
}

/* ============================================================
   MAIN PAGE EXPORT
   ============================================================ */
export default function SalePage() {
    const [loading, setLoading] = useState(true);
    const [allSaleProducts, setAllSaleProducts] = useState<Product[]>([]);
    
    // UI State
    const [showPopup, setShowPopup] = useState(true);
    const [activeTab, setActiveTab] = useState<"all" | "male" | "female">("all");
    const [toastMessage, setToastMessage] = useState("");
    const [showToast, setShowToast] = useState(false);

    // Fetch products
    useEffect(() => {
        getProducts(200) // fetch
            .then(products => {
                const sales = products.filter(p => p.isActive && p.salePrice > 0 && p.salePrice < p.price);
                // Sắp xếp tự động cho Flash Sale (Giảm giá sâu nhất lên đầu)
                sales.sort((a,b) => {
                    const da = (a.price - a.salePrice) / a.price;
                    const db = (b.price - b.salePrice) / b.price;
                    return db - da; // Descending
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

    // Tabs logic
    const filteredProducts = allSaleProducts.filter(p => {
        if (activeTab === "all") return true;
        return p.gender === activeTab || p.gender === "all";
    });

    const flashSaleItems = allSaleProducts.slice(0, 4); // First 4 items with deep discount
    const mainGridItems = filteredProducts;

    return (
        <div style={{ background: "var(--bg-primary)", minHeight: "100vh" }}>
            {showPopup && <PromoPopup onClose={() => setShowPopup(false)} />}
            <Toast message={toastMessage} visible={showToast} />

            <section style={{ paddingTop: "calc(var(--header-height) + 24px)", paddingBottom: "60px" }}>
                <div className="container" style={{ maxWidth: "1280px" }}>
                    
                    {/* Hero */}
                    <PremiumHeroBanner />

                    {/* Vouchers Line */}
                    <VoucherCards onCopy={showToastMsg} />

                    {/* Flash Sale Banner Section */}
                    {flashSaleItems.length > 0 && (
                        <div style={{ marginBottom: "60px" }}>
                            <div style={{ display: "flex", alignItems: "center", gap: "16px", marginBottom: "24px" }}>
                                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#FF416C" strokeWidth="2.5"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg>
                                <h2 style={{ fontSize: "1.8rem", fontWeight: 900, color: "var(--text-primary)", letterSpacing: "-0.02em" }}>Săn Nhanh Kẻo Lỡ</h2>
                                <div style={{ height: "1px", flex: 1, background: "var(--border-color)", marginLeft: "16px" }} />
                            </div>
                            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))", gap: "24px" }}>
                                {flashSaleItems.map((product, i) => (
                                    <FlashSaleProductCard key={`fs-${product.id}`} product={product} index={i} />
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Main Sale Products */}
                    <div style={{ marginBottom: "40px" }}>
                        <h2 style={{ fontSize: "2rem", fontWeight: 900, color: "var(--text-primary)", letterSpacing: "-0.02em", marginBottom: "24px", textAlign: "center" }}>Ưu Đãi Đặc Biệt</h2>
                        
                        {/* Premium Tabs */}
                        <div style={{ display: "flex", justifyContent: "center", gap: "12px", marginBottom: "40px", flexWrap: "wrap", padding: "8px", background: "var(--bg-surface)", width: "fit-content", margin: "0 auto 40px", borderRadius: "100px", border: "1px solid var(--border-color)" }}>
                            {[
                                { id: "all", label: "Tất Cả Sản Phẩm" },
                                { id: "male", label: "Cho Nam" },
                                { id: "female", label: "Cho Nữ" }
                            ].map(tab => {
                                const active = activeTab === tab.id;
                                return (
                                    <button
                                        key={tab.id}
                                        onClick={() => setActiveTab(tab.id as typeof activeTab)}
                                        style={{
                                            padding: "12px 32px", borderRadius: "100px",
                                            background: active ? "var(--text-primary)" : "transparent",
                                            color: active ? "var(--bg-primary)" : "var(--text-secondary)",
                                            fontSize: "0.95rem", fontWeight: 700,
                                            border: "none", cursor: "pointer", transition: "all 0.3s",
                                            boxShadow: active ? "0 4px 12px rgba(0,0,0,0.1)" : "none"
                                        }}
                                        onMouseEnter={e => { if (!active) e.currentTarget.style.color = "var(--text-primary)"; }}
                                        onMouseLeave={e => { if (!active) e.currentTarget.style.color = "var(--text-secondary)"; }}
                                    >
                                        {tab.label}
                                    </button>
                                );
                            })}
                        </div>

                        {/* Product Grid */}
                        {loading ? (
                            <div style={{ textAlign: "center", padding: "80px 0" }}>
                                <div style={{ width: "48px", height: "48px", borderRadius: "50%", border: "4px solid var(--border-color)", borderTopColor: "var(--text-primary)", animation: "rotate-slow 1s linear infinite", margin: "0 auto 24px" }} />
                                <p style={{ color: "var(--text-muted)", fontSize: "1.05rem", fontWeight: 500 }}>Đang chuẩn bị các siêu phẩm...</p>
                            </div>
                        ) : mainGridItems.length > 0 ? (
                            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))", gap: "40px 24px" }} className="products-grid">
                                {mainGridItems.map((product, i) => (
                                    <StandardSaleProductCard key={product.id} product={product} index={i} />
                                ))}
                            </div>
                        ) : (
                            <div style={{ textAlign: "center", padding: "80px 0", background: "var(--bg-card)", borderRadius: "24px", border: "1px dashed var(--border-color)" }}>
                                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="var(--text-muted)" strokeWidth="1.5" style={{ marginBottom: "16px" }}><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><line x1="9" y1="3" x2="9" y2="21"></line></svg>
                                <p style={{ color: "var(--text-secondary)", fontSize: "1.05rem", marginBottom: "24px" }}>
                                    Danh mục này hiện chưa có sản phẩm Sale.
                                </p>
                                <button onClick={() => setActiveTab("all")} style={{ background: "var(--bg-surface)", color: "var(--text-primary)", border: "1px solid var(--border-color)", padding: "12px 32px", borderRadius: "100px", fontSize: "0.95rem", fontWeight: 700, cursor: "pointer", transition: "all 0.2s" }} onMouseEnter={e => e.currentTarget.style.borderColor = "var(--text-primary)"} onMouseLeave={e => e.currentTarget.style.borderColor = "var(--border-color)"}>
                                    Xem Tất Cả Menu
                                </button>
                            </div>
                        )}
                    </div>

                    <StylishFooterBanner />

                </div>
            </section>
            
            <style jsx global>{`
                @media (max-width: 500px) {
                    .products-grid { grid-template-columns: repeat(2, 1fr) !important; gap: 24px 12px !important; }
                }
            `}</style>
        </div>
    );
}
