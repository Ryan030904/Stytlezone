"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";
import { db } from "@/lib/firebase";
import { collection, addDoc, Timestamp } from "firebase/firestore";

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
   DATA
   ============================================================ */

const CONTACT_INFO = [
    {
        icon: (
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" />
            </svg>
        ),
        title: "Địa chỉ",
        text: "Hẻm 66A Nguyễn Văn Cư, Cần Thơ",
    },
    {
        icon: (
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" />
            </svg>
        ),
        title: "Hotline",
        text: "0867 642 831",
    },
    {
        icon: (
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" /><polyline points="22,6 12,13 2,6" />
            </svg>
        ),
        title: "Email",
        text: "stylezone13579@gmail.com",
    },
    {
        icon: (
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" />
            </svg>
        ),
        title: "Giờ mở cửa",
        text: "T2–T7: 9h–21h · CN: 10h–18h",
    },
];

/* ============================================================
   CONTACT INFO CARD (extracted to satisfy Rules of Hooks)
   ============================================================ */

function ContactInfoCard({ info, index }: { info: typeof CONTACT_INFO[number]; index: number }) {
    const cardRef = useReveal("left", { delay: index * 0.1 });
    return (
        <div
            ref={cardRef}
            className="contact-card"
            style={{
                display: "flex",
                alignItems: "flex-start",
                gap: "16px",
                cursor: "default",
                transition: "transform 0.3s ease",
            }}
            onMouseEnter={(e) => {
                e.currentTarget.style.transform = "translateX(8px)";
            }}
            onMouseLeave={(e) => {
                e.currentTarget.style.transform = "translateX(0)";
            }}
        >
            <div style={{
                width: "38px",
                height: "38px",
                borderRadius: "50%",
                background: "rgba(255,255,255,0.08)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "rgba(255,255,255,0.85)",
                flexShrink: 0,
                marginTop: "2px",
            }}>
                {info.icon}
            </div>
            <div>
                <p style={{ fontSize: "0.68rem", fontWeight: 600, color: "rgba(255,255,255,0.65)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "4px" }}>{info.title}</p>
                <p style={{ fontSize: "0.88rem", fontWeight: 500, color: "#fff", lineHeight: 1.5 }}>{info.text}</p>
            </div>
        </div>
    );
}

/* ============================================================
   HERO BANNER
   ============================================================ */

function HeroBanner() {
    return (
        <section
            style={{
                position: "relative",
                minHeight: "50vh",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                overflow: "hidden",
            }}
        >
            {/* Background image */}
            <Image
                src="/images/contact/liên hệ.png"
                alt="Liên hệ StyleZone"
                fill
                style={{
                    objectFit: "cover", objectPosition: "center",
                    zIndex: 0,
                }}
                priority
            />
            {/* Dark overlay for text readability */}
            <div style={{
                position: "absolute", inset: 0, zIndex: 1,
                background: "linear-gradient(180deg, rgba(0,0,0,0.55) 0%, rgba(0,0,0,0.65) 100%)",
            }} />

            <div className="container animate-slide-up" style={{ position: "relative", zIndex: 2, textAlign: "center", padding: "var(--space-4xl) var(--space-lg) var(--space-2xl)", paddingTop: "calc(var(--header-height) + var(--space-3xl))" }}>
                <div style={{ display: "inline-flex", alignItems: "center", gap: "var(--space-sm)", padding: "5px 14px", borderRadius: "var(--radius-full)", background: "rgba(139,92,246,0.15)", border: "1px solid rgba(139,92,246,0.3)", marginBottom: "var(--space-lg)", fontSize: "0.72rem", fontWeight: 600, letterSpacing: "0.15em", color: "#c4b5fd", textTransform: "uppercase" }}>
                    <span style={{ width: "6px", height: "6px", borderRadius: "50%", background: "#a78bfa", animation: "pulse-glow 2s ease infinite" }} />
                    Kết Nối Với Chúng Tôi
                </div>
                <h1 style={{ fontSize: "clamp(1.8rem, 4.5vw, 3rem)", fontWeight: 800, lineHeight: 1.1, letterSpacing: "-0.04em", color: "#fff", marginBottom: "var(--space-md)", textShadow: "0 2px 8px rgba(0,0,0,0.3)" }}>
                    Liên Hệ <span className="gradient-text" style={{ fontStyle: "italic" }}>StyleZone</span>
                </h1>
                <p style={{ color: "rgba(255,255,255,0.75)", fontSize: "clamp(0.85rem, 1.4vw, 1rem)", maxWidth: "520px", margin: "0 auto", lineHeight: 1.7 }}>
                    Chúng tôi luôn sẵn sàng lắng nghe. Hãy để lại lời nhắn hoặc ghé thăm cửa hàng.
                </p>
            </div>
        </section>
    );
}

/* ============================================================
   MAIN CONTACT SECTION
   Layout: [Info Cards (vertical)] + [Form + Image (stacked)]
   ============================================================ */

function ContactSection() {
    const wrapperRef = useReveal();
    const [submitted, setSubmitted] = useState(false);
    const [sending, setSending] = useState(false);
    const [formName, setFormName] = useState("");
    const [formEmail, setFormEmail] = useState("");
    const [formPhone, setFormPhone] = useState("");
    const [formSubject, setFormSubject] = useState("");
    const [formMessage, setFormMessage] = useState("");

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (sending) return;
        setSending(true);
        try {
            await addDoc(collection(db, "feedbacks"), {
                name: formName.trim(),
                email: formEmail.trim(),
                phone: formPhone.trim(),
                subject: formSubject || "other",
                message: formMessage.trim(),
                status: "pending",
                adminReply: "",
                adminReplyAt: null,
                createdAt: Timestamp.now(),
            });
            setSubmitted(true);
            setFormName(""); setFormEmail(""); setFormPhone(""); setFormSubject(""); setFormMessage("");
            setTimeout(() => setSubmitted(false), 3000);
        } catch (err) {
            console.error("Submit feedback error:", err);
            alert("Gửi thất bại, vui lòng thử lại!");
        } finally {
            setSending(false);
        }
    };

    const inputStyle: React.CSSProperties = {
        width: "100%",
        padding: "14px 16px",
        background: "var(--bg-surface)",
        border: "1px solid var(--border-color)",
        borderRadius: "var(--radius-md)",
        color: "var(--text-primary)",
        fontSize: "0.88rem",
        transition: "border-color 0.25s, box-shadow 0.25s",
        outline: "none",
    };

    const focusHandler = (e: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
        e.currentTarget.style.borderColor = "var(--color-accent)";
        e.currentTarget.style.boxShadow = "0 0 0 3px rgba(139,92,246,0.12)";
    };
    const blurHandler = (e: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
        e.currentTarget.style.borderColor = "var(--border-color)";
        e.currentTarget.style.boxShadow = "none";
    };

    return (
        <section className="section">
            <div className="container">
                {/* PREMIUM WRAPPER */}
                <div
                    ref={wrapperRef}
                    style={{
                        borderRadius: "20px",
                        overflow: "hidden",
                        boxShadow: "0 8px 40px rgba(0,0,0,0.12), 0 2px 12px rgba(139,92,246,0.08)",
                    }}
                >
                    <div
                        style={{
                            display: "grid",
                            gridTemplateColumns: "320px 1fr",
                        }}
                        className="contact-inner-grid"
                    >
                        {/* LEFT SIDEBAR — Dark gradient */}
                        <div
                            style={{
                                background: "linear-gradient(170deg, #2d1b69 0%, #1a103f 40%, #140d2e 100%)",
                                padding: "40px 32px",
                                display: "flex",
                                flexDirection: "column",
                                position: "relative",
                                overflow: "hidden",
                            }}
                        >
                            {/* Decorative circles */}
                            <div style={{ position: "absolute", bottom: "-30px", right: "-30px", width: "140px", height: "140px", borderRadius: "50%", background: "rgba(139,92,246,0.12)", pointerEvents: "none" }} />
                            <div style={{ position: "absolute", top: "40%", right: "10%", width: "80px", height: "80px", borderRadius: "50%", background: "rgba(139,92,246,0.06)", pointerEvents: "none" }} />

                            <h3 style={{ fontSize: "1.25rem", fontWeight: 700, color: "#fff", marginBottom: "6px", letterSpacing: "-0.01em" }}>
                                Thông Tin Liên Hệ
                            </h3>
                            <p style={{ fontSize: "0.8rem", color: "rgba(255,255,255,0.75)", lineHeight: 1.6, marginBottom: "36px" }}>
                                Hãy liên hệ với chúng tôi qua bất kỳ kênh nào bên dưới
                            </p>

                            {/* Contact items */}
                            <div style={{ display: "flex", flexDirection: "column", gap: "28px", flex: 1, position: "relative", zIndex: 1 }}>
                                {CONTACT_INFO.map((info, i) => (
                                    <ContactInfoCard key={info.title} info={info} index={i} />
                                ))}
                            </div>


                        </div>

                        {/* RIGHT — Contact Form */}
                        <div
                            style={{
                                padding: "40px 48px",
                                display: "flex",
                                flexDirection: "column",
                                background: "var(--bg-card)",
                            }}
                        >
                            <h2 style={{ fontSize: "1.4rem", fontWeight: 700, lineHeight: 1.3, marginBottom: "6px", color: "var(--text-primary)" }}>
                                Gửi Lời Nhắn <span className="gradient-text">Cho Chúng Tôi</span>
                            </h2>
                            <p style={{ color: "var(--text-muted)", fontSize: "0.85rem", lineHeight: 1.6, marginBottom: "32px" }}>
                                Bạn có câu hỏi về đơn hàng, sản phẩm hay hợp tác? Điền form bên dưới, chúng tôi sẽ phản hồi trong vòng 24 giờ.
                            </p>

                            <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", gap: "18px", flex: 1 }}>
                                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
                                    <div>
                                        <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "6px", textTransform: "uppercase", letterSpacing: "0.05em" }}>Họ và tên *</label>
                                        <input type="text" placeholder="Nhập họ và tên" required style={inputStyle}
                                            value={formName} onChange={(e) => setFormName(e.target.value)}
                                            onFocus={focusHandler} onBlur={blurHandler} />
                                    </div>
                                    <div>
                                        <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "6px", textTransform: "uppercase", letterSpacing: "0.05em" }}>Email *</label>
                                        <input type="email" placeholder="email@example.com" required style={inputStyle}
                                            value={formEmail} onChange={(e) => setFormEmail(e.target.value)}
                                            onFocus={focusHandler} onBlur={blurHandler} />
                                    </div>
                                </div>
                                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
                                    <div>
                                        <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "6px", textTransform: "uppercase", letterSpacing: "0.05em" }}>Số điện thoại</label>
                                        <input type="tel" placeholder="0xxx xxx xxx" style={inputStyle}
                                            value={formPhone} onChange={(e) => setFormPhone(e.target.value)}
                                            onFocus={focusHandler} onBlur={blurHandler} />
                                    </div>
                                    <div>
                                        <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "6px", textTransform: "uppercase", letterSpacing: "0.05em" }}>Chủ đề</label>
                                        <select style={{ ...inputStyle, cursor: "pointer" }}
                                            value={formSubject} onChange={(e) => setFormSubject(e.target.value)}
                                            onFocus={focusHandler as React.FocusEventHandler<HTMLSelectElement>}
                                            onBlur={blurHandler as React.FocusEventHandler<HTMLSelectElement>}
                                        >
                                            <option value="">Chọn chủ đề</option>
                                            <option value="order">Đơn hàng</option>
                                            <option value="product">Sản phẩm</option>
                                            <option value="return">Đổi trả</option>
                                            <option value="business">Hợp tác kinh doanh</option>
                                            <option value="other">Khác</option>
                                        </select>
                                    </div>
                                </div>
                                <div>
                                    <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "6px", textTransform: "uppercase", letterSpacing: "0.05em" }}>Nội dung *</label>
                                    <textarea
                                        placeholder="Viết nội dung tin nhắn của bạn..."
                                        required
                                        rows={6}
                                        value={formMessage}
                                        onChange={(e) => setFormMessage(e.target.value)}
                                        style={{ ...inputStyle, resize: "vertical", minHeight: "140px" }}
                                        onFocus={focusHandler as React.FocusEventHandler<HTMLTextAreaElement>}
                                        onBlur={blurHandler as React.FocusEventHandler<HTMLTextAreaElement>}
                                    />
                                </div>
                                <button
                                    type="submit"
                                    className="btn btn-primary"
                                    style={{
                                        padding: "14px 44px",
                                        alignSelf: "flex-end",
                                        fontSize: "0.9rem",
                                        marginTop: "4px",
                                        borderRadius: "var(--radius-md)",
                                        background: "linear-gradient(135deg, #7c3aed 0%, #a855f7 100%)",
                                        border: "none",
                                        transition: "all 0.3s ease",
                                    }}
                                    onMouseEnter={(e) => { e.currentTarget.style.boxShadow = "0 6px 24px rgba(139,92,246,0.35)"; e.currentTarget.style.transform = "translateY(-2px)"; }}
                                    onMouseLeave={(e) => { e.currentTarget.style.boxShadow = "none"; e.currentTarget.style.transform = "translateY(0)"; }}
                                >
                                    {submitted ? "✓ Đã gửi thành công!" : "Gửi Tin Nhắn →"}
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>

            <style jsx global>{`
                @media (max-width: 900px) {
                    .contact-inner-grid {
                        grid-template-columns: 1fr !important;
                    }
                    .contact-inner-grid > div:first-child {
                        padding: 32px 28px !important;
                    }
                    .contact-inner-grid > div:last-child {
                        padding: 28px 24px !important;
                    }
                }
            `}</style>
        </section>
    );
}

/* ============================================================
   MAP SECTION
   ============================================================ */

function MapSection() {
    const ref = useReveal();
    return (
        <section className="section">
            <div className="container">
                <div ref={ref} style={{ textAlign: "center", marginBottom: "var(--space-xl)" }}>
                    <div className="accent-line" style={{ margin: "0 auto var(--space-md)" }} />
                    <h2 className="section-title" style={{ fontSize: "clamp(1.2rem, 2.5vw, 1.6rem)" }}>Tìm Cửa Hàng</h2>
                    <p className="section-subtitle" style={{ fontSize: "0.88rem" }}>Ghé thăm trực tiếp để trải nghiệm sản phẩm</p>
                </div>
                <div style={{ borderRadius: "var(--radius-xl)", overflow: "hidden", border: "1px solid var(--border-color)", aspectRatio: "21/9" }}>
                    <iframe
                        src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d1962.5!2d105.768655!3d10.0506386!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zMTDCsDAzJzAyLjMiTiAxMDXCsDQ2JzA3LjIiRQ!5e0!3m2!1svi!2svn!4v1709568000000!5m2!1svi!2svn"
                        width="100%"
                        height="100%"
                        style={{ border: 0 }}
                        allowFullScreen
                        loading="lazy"
                        referrerPolicy="no-referrer-when-downgrade"
                        title="StyleZone Store Location"
                    />
                </div>
            </div>
        </section>
    );
}

/* ============================================================
   MAIN PAGE
   ============================================================ */

export default function ContactPage() {
    return (
        <>
            <HeroBanner />
            <ContactSection />
            <MapSection />
        </>
    );
}
