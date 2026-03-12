"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useRef } from "react";

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

const VALUES = [
    {
        icon: (
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
            </svg>
        ),
        title: "Chất Lượng",
        desc: "Chất liệu cao cấp, tỉ mỉ trong từng đường kim mũi chỉ. Mỗi sản phẩm là một cam kết về sự hoàn hảo.",
    },
    {
        icon: (
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" />
            </svg>
        ),
        title: "Xu Hướng",
        desc: "Luôn cập nhật xu hướng thời trang quốc tế, kết hợp bản sắc văn hóa Việt Nam trong từng thiết kế.",
    },
    {
        icon: (
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
            </svg>
        ),
        title: "Bền Vững",
        desc: "Cam kết thời trang có trách nhiệm — chất liệu thân thiện môi trường, sản xuất có đạo đức.",
    },
    {
        icon: (
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
            </svg>
        ),
        title: "Cộng Đồng",
        desc: "Xây dựng cộng đồng yêu thời trang — nơi mỗi cá nhân đều tỏa sáng theo cách riêng.",
    },
];

const MILESTONES = [
    { year: "2020", title: "Khởi nguồn", desc: "StyleZone ra đời từ niềm đam mê thời trang và mong muốn mang phong cách hiện đại đến gần hơn." },
    { year: "2022", title: "Mở rộng", desc: "Ra mắt cửa hàng flagship đầu tiên tại TP.HCM, phục vụ hơn 10.000 khách hàng." },
    { year: "2024", title: "Bền vững", desc: "Chuyển đổi 60% dây chuyền sang chất liệu thân thiện môi trường." },
    { year: "2026", title: "Tầm nhìn", desc: "Trở thành thương hiệu thời trang hàng đầu Đông Nam Á với mạng lưới 20+ cửa hàng." },
];

/* ============================================================
   COMPONENTS
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
                background: "linear-gradient(160deg, #000000 0%, #0a0a12 30%, #1a1040 60%, #0d0d18 100%)",
            }}
        >
            <div style={{ position: "absolute", top: "10%", right: "12%", width: "250px", height: "250px", borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.12) 0%, transparent 70%)", animation: "float 6s ease-in-out infinite", pointerEvents: "none" }} />
            <div style={{ position: "absolute", bottom: "5%", left: "8%", width: "180px", height: "180px", borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.08) 0%, transparent 70%)", animation: "float 8s ease-in-out infinite reverse", pointerEvents: "none" }} />

            <div className="container animate-slide-up" style={{ position: "relative", zIndex: 2, textAlign: "center", padding: "var(--space-4xl) var(--space-lg) var(--space-2xl)" }}>
                <div style={{ display: "inline-flex", alignItems: "center", gap: "var(--space-sm)", padding: "5px 14px", borderRadius: "var(--radius-full)", background: "rgba(139,92,246,0.1)", border: "1px solid rgba(139,92,246,0.2)", marginBottom: "var(--space-lg)", fontSize: "0.75rem", fontWeight: 600, letterSpacing: "0.15em", color: "var(--color-accent)", textTransform: "uppercase" }}>
                    <span style={{ width: "6px", height: "6px", borderRadius: "50%", background: "var(--color-accent)", animation: "pulse-glow 2s ease infinite" }} />
                    Câu Chuyện Của Chúng Tôi
                </div>
                <h1 style={{ fontSize: "clamp(2rem, 5vw, 3.5rem)", fontWeight: 800, lineHeight: 1.1, letterSpacing: "-0.04em", color: "var(--hero-text)", marginBottom: "var(--space-md)" }}>
                    Về <span className="gradient-text" style={{ fontStyle: "italic" }}>StyleZone</span>
                </h1>
                <p style={{ color: "var(--hero-subtitle)", fontSize: "clamp(0.9rem, 1.5vw, 1.05rem)", maxWidth: "560px", margin: "0 auto", lineHeight: 1.7 }}>
                    Nơi phong cách gặp đam mê — kiến tạo thời trang hiện đại cho thế hệ mới.
                </p>
                <div style={{ marginTop: "var(--space-xl)", display: "flex", alignItems: "center", justifyContent: "center", gap: "var(--space-sm)", fontSize: "0.8rem", color: "var(--text-muted)" }}>
                    <Link href="/" style={{ color: "var(--text-muted)", transition: "color 0.2s" }} onMouseEnter={(e) => (e.currentTarget.style.color = "var(--color-accent)")} onMouseLeave={(e) => (e.currentTarget.style.color = "var(--text-muted)")}>Trang chủ</Link>
                    <span style={{ opacity: 0.4 }}>/</span>
                    <span style={{ color: "var(--text-primary)" }}>Về Chúng Tôi</span>
                </div>
            </div>
        </section>
    );
}

function StorySection() {
    const leftRef = useReveal("left");
    const rightRef = useReveal("right", { delay: 0.15 });

    return (
        <section className="section" style={{ overflow: "hidden" }}>
            <div className="container" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-4xl)", alignItems: "center" }} className-grid="about-grid">
                <div ref={leftRef}>
                    <div className="accent-line" />
                    <h2 style={{ fontSize: "clamp(1.6rem, 3vw, 2.2rem)", fontWeight: 700, lineHeight: 1.2, letterSpacing: "-0.03em", marginBottom: "var(--space-lg)" }}>
                        Từ Đam Mê <br /><span className="gradient-text">Đến Phong Cách</span>
                    </h2>
                    <p style={{ color: "var(--text-secondary)", fontSize: "0.95rem", lineHeight: 1.8, marginBottom: "var(--space-lg)" }}>
                        StyleZone khởi đầu từ một ý tưởng đơn giản: mang thời trang cao cấp đến gần hơn với mọi người. Chúng tôi tin rằng phong cách không phải là đặc quyền — nó là cách mỗi người thể hiện bản thân.
                    </p>
                    <p style={{ color: "var(--text-secondary)", fontSize: "0.95rem", lineHeight: 1.8 }}>
                        Với đội ngũ thiết kế trẻ, đầy nhiệt huyết và am hiểu xu hướng quốc tế, chúng tôi không ngừng sáng tạo những bộ sưu tập mang tính thời đại — kết hợp giữa sự tinh tế phương Tây và bản sắc Việt.
                    </p>
                </div>
                <div ref={rightRef} style={{ position: "relative", borderRadius: "var(--radius-xl)", overflow: "hidden", aspectRatio: "4/3" }}>
                    <Image src="/images/about/team.png" alt="Đội ngũ StyleZone" fill style={{ objectFit: "cover" }} sizes="(max-width: 768px) 100vw, 50vw" />
                    <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.3) 0%, transparent 50%)" }} />
                </div>
            </div>
            <style jsx>{`
                @media (max-width: 768px) {
                    .container { grid-template-columns: 1fr !important; gap: var(--space-2xl) !important; }
                }
            `}</style>
        </section>
    );
}

function ValuesSection() {
    const sectionRef = useReveal();

    return (
        <section className="section" style={{ background: "var(--bg-secondary)" }}>
            <div className="container">
                <div ref={sectionRef} style={{ textAlign: "center", marginBottom: "var(--space-2xl)" }}>
                    <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
                    <h2 className="section-title">Giá Trị Cốt Lõi</h2>
                    <p className="section-subtitle">Những giá trị định hình mọi thiết kế của chúng tôi</p>
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "var(--space-lg)" }} className="values-grid">
                    {VALUES.map((v, i) => {
                        const ItemInner = () => {
                            const itemRef = useReveal("up", { delay: i * 0.1 });
                            return (
                                <div
                                    ref={itemRef}
                                    style={{
                                        padding: "var(--space-xl)",
                                        borderRadius: "var(--radius-lg)",
                                        border: "1px solid var(--border-color)",
                                        background: "var(--bg-card)",
                                        textAlign: "center",
                                        transition: "all 0.3s ease",
                                    }}
                                    onMouseEnter={(e) => { e.currentTarget.style.borderColor = "rgba(139,92,246,0.3)"; e.currentTarget.style.transform = "translateY(-4px)"; }}
                                    onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.transform = "translateY(0)"; }}
                                >
                                    <div style={{ color: "var(--color-accent)", marginBottom: "var(--space-lg)", display: "flex", justifyContent: "center" }}>{v.icon}</div>
                                    <h3 style={{ fontSize: "1.05rem", fontWeight: 700, marginBottom: "var(--space-sm)", letterSpacing: "-0.01em" }}>{v.title}</h3>
                                    <p style={{ color: "var(--text-muted)", fontSize: "0.85rem", lineHeight: 1.7 }}>{v.desc}</p>
                                </div>
                            );
                        };
                        return <ItemInner key={v.title} />;
                    })}
                </div>
            </div>
            <style jsx global>{`
                @media (max-width: 1024px) { .values-grid { grid-template-columns: repeat(2, 1fr) !important; } }
                @media (max-width: 640px) { .values-grid { grid-template-columns: 1fr !important; } }
            `}</style>
        </section>
    );
}

function CraftsmanshipSection() {
    const leftRef = useReveal("left");
    const rightRef = useReveal("right", { delay: 0.15 });

    return (
        <section className="section" style={{ overflow: "hidden" }}>
            <div className="container" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-4xl)", alignItems: "center" }}>
                <div ref={leftRef} style={{ position: "relative", borderRadius: "var(--radius-xl)", overflow: "hidden", aspectRatio: "4/3" }}>
                    <Image src="/images/about/workshop.png" alt="Xưởng thiết kế StyleZone" fill style={{ objectFit: "cover" }} sizes="(max-width: 768px) 100vw, 50vw" />
                </div>
                <div ref={rightRef}>
                    <div className="accent-line" />
                    <h2 style={{ fontSize: "clamp(1.6rem, 3vw, 2.2rem)", fontWeight: 700, lineHeight: 1.2, letterSpacing: "-0.03em", marginBottom: "var(--space-lg)" }}>
                        Tỉ Mỉ Trong <br /><span className="gradient-text">Từng Chi Tiết</span>
                    </h2>
                    <p style={{ color: "var(--text-secondary)", fontSize: "0.95rem", lineHeight: 1.8, marginBottom: "var(--space-xl)" }}>
                        Mỗi sản phẩm StyleZone đều trải qua quy trình kiểm soát chất lượng nghiêm ngặt — từ khâu chọn vải, cắt may đến hoàn thiện. Chúng tôi hợp tác với các xưởng sản xuất uy tín, sử dụng chất liệu nhập khẩu và công nghệ may tiên tiến.
                    </p>
                    <div style={{ display: "flex", gap: "var(--space-2xl)" }}>
                        {[
                            { num: "100%", label: "Chất liệu cao cấp" },
                            { num: "50+", label: "Nhà cung cấp" },
                            { num: "3x", label: "Kiểm tra chất lượng" },
                        ].map((s) => (
                            <div key={s.label}>
                                <div style={{ fontSize: "1.5rem", fontWeight: 800, color: "var(--color-accent)" }}>{s.num}</div>
                                <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: "2px" }}>{s.label}</div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </section>
    );
}

function TimelineSection() {
    const sectionRef = useReveal();

    return (
        <section className="section" style={{ background: "var(--bg-secondary)" }}>
            <div className="container">
                <div ref={sectionRef} style={{ textAlign: "center", marginBottom: "var(--space-2xl)" }}>
                    <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
                    <h2 className="section-title">Hành Trình</h2>
                    <p className="section-subtitle">Những cột mốc quan trọng trong câu chuyện StyleZone</p>
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "var(--space-lg)", position: "relative" }} className="timeline-grid">
                    <div style={{ position: "absolute", top: "28px", left: "12.5%", right: "12.5%", height: "2px", background: "var(--border-color)", zIndex: 0 }} className="timeline-line" />
                    {MILESTONES.map((m, i) => {
                        const ItemInner = () => {
                            const itemRef = useReveal("up", { delay: i * 0.12 });
                            return (
                                <div ref={itemRef} style={{ textAlign: "center", position: "relative", zIndex: 1 }}>
                                    <div style={{ width: "56px", height: "56px", borderRadius: "50%", background: "var(--bg-card)", border: "2px solid var(--color-accent)", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto var(--space-lg)", fontSize: "0.8rem", fontWeight: 800, color: "var(--color-accent)" }}>
                                        {m.year}
                                    </div>
                                    <h3 style={{ fontSize: "1rem", fontWeight: 700, marginBottom: "var(--space-sm)" }}>{m.title}</h3>
                                    <p style={{ color: "var(--text-muted)", fontSize: "0.85rem", lineHeight: 1.6 }}>{m.desc}</p>
                                </div>
                            );
                        };
                        return <ItemInner key={m.year} />;
                    })}
                </div>
            </div>
            <style jsx global>{`
                @media (max-width: 768px) {
                    .timeline-grid { grid-template-columns: repeat(2, 1fr) !important; gap: var(--space-xl) !important; }
                    .timeline-line { display: none !important; }
                }
                @media (max-width: 480px) { .timeline-grid { grid-template-columns: 1fr !important; } }
            `}</style>
        </section>
    );
}

function CTASection() {
    const ref = useReveal("scale");
    return (
        <section style={{ padding: "var(--space-4xl) 0", position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, #0a0012 0%, #1a0a30 50%, #0a0012 100%)" }} />
            <div ref={ref} className="container" style={{ position: "relative", zIndex: 2, textAlign: "center" }}>
                <h2 style={{ fontSize: "clamp(1.8rem, 4vw, 2.5rem)", fontWeight: 800, lineHeight: 1.15, letterSpacing: "-0.03em", color: "var(--color-white)", marginBottom: "var(--space-lg)" }}>
                    Sẵn Sàng Khám Phá <br /><span className="gradient-text">Phong Cách Của Bạn?</span>
                </h2>
                <p style={{ color: "rgba(255,255,255,0.5)", maxWidth: "480px", margin: "0 auto var(--space-2xl)", lineHeight: 1.7 }}>
                    Hàng ngàn sản phẩm đang chờ bạn. Bắt đầu hành trình thời trang cùng StyleZone ngay hôm nay.
                </p>
                <div style={{ display: "flex", gap: "var(--space-md)", justifyContent: "center", flexWrap: "wrap" }}>
                    <Link href="/bo-suu-tap" className="btn btn-primary" style={{ padding: "14px 36px" }}>Khám Phá Bộ Sưu Tập →</Link>
                    <Link href="/lien-he" className="btn btn-outline" style={{ padding: "14px 36px" }}>Liên Hệ Với Chúng Tôi</Link>
                </div>
            </div>
        </section>
    );
}

/* ============================================================
   MAIN PAGE
   ============================================================ */

export default function AboutPage() {
    return (
        <>
            <HeroBanner />
            <StorySection />
            <ValuesSection />
            <CraftsmanshipSection />
            <TimelineSection />
            <CTASection />
        </>
    );
}
