"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useState, useCallback, useRef } from "react";
import { getParentCategories } from "@/lib/categories";
import { getHeroBanners } from "@/lib/banners";
import { getFlashSale } from "@/lib/promotions";
import { getBrands } from "@/lib/brands";
import type { Category, Banner, Promotion, Brand } from "@/lib/types";

/* ================ HOOKS ================ */

type RevealDirection = "up" | "down" | "left" | "right" | "scale";

/** Intersection Observer hook for multi-directional scroll animations */
function useReveal(direction: RevealDirection = "up", { threshold = 0.12, delay = 0 }: { threshold?: number; delay?: number } = {}) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    // Set initial CSS class based on direction
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

/** Animated number counter */
function useCounter(target: number, duration = 2000) {
  const [count, setCount] = useState(0);
  const [started, setStarted] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setStarted(true);
          obs.unobserve(el);
        }
      },
      { threshold: 0.3 }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, []);

  useEffect(() => {
    if (!started) return;
    const steps = 60;
    const increment = target / steps;
    let current = 0;
    const timer = setInterval(() => {
      current += increment;
      if (current >= target) {
        setCount(target);
        clearInterval(timer);
      } else {
        setCount(Math.floor(current));
      }
    }, duration / steps);
    return () => clearInterval(timer);
  }, [started, target, duration]);

  return { count, ref };
}

/* ================ HELPERS ================ */

function formatPrice(price: number): string {
  return new Intl.NumberFormat("vi-VN").format(price) + "đ";
}

function getTimeRemaining(endDate: Date) {
  const total = endDate.getTime() - Date.now();
  if (total <= 0) return { days: 0, hours: 0, minutes: 0, seconds: 0, expired: true };
  return {
    days: Math.floor(total / (1000 * 60 * 60 * 24)),
    hours: Math.floor((total / (1000 * 60 * 60)) % 24),
    minutes: Math.floor((total / (1000 * 60)) % 60),
    seconds: Math.floor((total / 1000) % 60),
    expired: false,
  };
}

const USP_ITEMS = [
  {
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
        <rect x="1" y="3" width="15" height="13" /><polygon points="16 8 20 8 23 11 23 16 16 16 16 8" /><circle cx="5.5" cy="18.5" r="2.5" /><circle cx="18.5" cy="18.5" r="2.5" />
      </svg>
    ),
    title: "Miễn phí giao hàng",
    desc: "Đơn hàng từ 500K",
  },
  {
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="23 4 23 10 17 10" /><polyline points="1 20 1 14 7 14" /><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
      </svg>
    ),
    title: "Đổi trả 30 ngày",
    desc: "Hoàn tiền nếu không hài lòng",
  },
  {
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
      </svg>
    ),
    title: "Cam kết chính hãng",
    desc: "100% hàng authentic",
  },
  {
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
      </svg>
    ),
    title: "Hỗ trợ 24/7",
    desc: "Tư vấn tận tâm",
  },
];

/* ================ COMPONENTS ================ */

function HeroSection({ banners }: { banners: Banner[] }) {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  const [imageLoaded, setImageLoaded] = useState(false);

  const banner = banners[currentSlide];
  const heroUrl = banner?.imageUrl || "";

  // Reset imageLoaded when slide or URL changes
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setImageLoaded(false);
  }, [heroUrl]);

  useEffect(() => {
    if (banners.length <= 1) return;
    const timer = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % banners.length);
    }, 5000);
    return () => clearInterval(timer);
  }, [banners.length]);

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    const { clientX, clientY } = e;
    const { innerWidth, innerHeight } = window;
    setMousePos({
      x: (clientX / innerWidth - 0.5) * 20,
      y: (clientY / innerHeight - 0.5) * 20,
    });
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
        background: "#0a0a0a",
      }}
    >
      {/* Parallax Background */}
      <div
        style={{
          position: "absolute",
          inset: "-20px",
          transform: `translate(${mousePos.x}px, ${mousePos.y}px)`,
          transition: "transform 0.3s ease-out",
        }}
      >
        {heroUrl && (
          <Image
            src={heroUrl}
            alt={banner?.title || "StyleZone — Thời Trang Hiện Đại"}
            fill
            style={{
              objectFit: "cover",
              opacity: imageLoaded ? 1 : 0,
              transition: "opacity 0.5s ease",
            }}
            priority
            onLoad={() => setImageLoaded(true)}
          />
        )}
        <div
          style={{
            position: "absolute",
            inset: 0,
            background: "linear-gradient(135deg, rgba(10,10,10,0.75) 0%, rgba(10,10,10,0.3) 50%, rgba(10,10,10,0.65) 100%)",
          }}
        />
      </div>

      {/* Floating decorative orbs */}
      <div style={{ position: "absolute", top: "10%", right: "15%", width: "300px", height: "300px", borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.15) 0%, transparent 70%)", animation: "float 6s ease-in-out infinite", pointerEvents: "none" }} />
      <div style={{ position: "absolute", bottom: "15%", left: "10%", width: "200px", height: "200px", borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.1) 0%, transparent 70%)", animation: "float 8s ease-in-out infinite reverse", pointerEvents: "none" }} />
      <div style={{ position: "absolute", top: "50%", left: "50%", width: "500px", height: "500px", borderRadius: "50%", border: "1px solid rgba(139,92,246,0.06)", animation: "rotate-slow 60s linear infinite", pointerEvents: "none", transform: "translate(-50%, -50%)" }} />

      {/* Content */}
      <div className="container" style={{ position: "relative", zIndex: 2, textAlign: "center", paddingTop: "var(--header-height)" }}>
        {/* Badge */}
        <div className="animate-fade-in" style={{ display: "inline-flex", alignItems: "center", gap: "8px", padding: "7px 18px", borderRadius: "var(--radius-full)", background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.12)", marginBottom: "var(--space-2xl)", backdropFilter: "blur(12px)" }}>
          <span style={{ width: "6px", height: "6px", borderRadius: "50%", background: "#8B5CF6", animation: "pulse-glow 2s ease infinite" }} />
          <span style={{ fontSize: "0.7rem", fontWeight: 600, letterSpacing: "0.2em", color: "rgba(255,255,255,0.7)", textTransform: "uppercase" }}>Spring / Summer 2026</span>
        </div>

        {/* Heading */}
        <h1 className="animate-slide-up stagger-1" style={{ fontSize: "clamp(2.5rem, 6.5vw, 4.5rem)", fontWeight: 800, lineHeight: 1.08, letterSpacing: "-0.035em", color: "#ffffff", marginBottom: "var(--space-xl)", overflow: "visible" }}>
          <span style={{ display: "block", fontWeight: 500, fontSize: "0.5em", letterSpacing: "0.25em", textTransform: "uppercase", color: "rgba(255,255,255,0.85)", marginBottom: "12px", textShadow: "0 2px 8px rgba(0,0,0,0.4)" }}>Khẳng Định Phong Cách</span>
          Style<span className="gradient-text" style={{ fontStyle: "italic", fontWeight: 800, paddingRight: "0.08em" }}>Zone</span>
        </h1>

        {/* Subtitle */}
        <p className="animate-slide-up stagger-2" style={{ color: "rgba(255,255,255,0.75)", fontSize: "clamp(0.95rem, 1.6vw, 1.1rem)", maxWidth: "500px", margin: "0 auto var(--space-2xl)", lineHeight: 1.8, letterSpacing: "0.015em", fontWeight: 400, textShadow: "0 1px 6px rgba(0,0,0,0.35)" }}>
          Bộ sưu tập thời trang cao cấp dành cho phái mạnh & phái đẹp — nơi phong cách gặp gỡ chất lượng.
        </p>

        {/* CTA Buttons */}
        <div className="animate-slide-up stagger-3" style={{ display: "flex", gap: "var(--space-lg)", justifyContent: "center", flexWrap: "wrap", marginBottom: "var(--space-xl)" }}>
          <Link
            href={banner?.linkUrl || "/bo-suu-tap"}
            className="btn"
            style={{ padding: "16px 40px", fontSize: "0.9rem", fontWeight: 600, letterSpacing: "0.04em", background: "var(--color-accent)", color: "#fff", borderRadius: "var(--radius-md)", border: "none", boxShadow: "0 0 30px rgba(139,92,246,0.4), 0 8px 24px rgba(139,92,246,0.25)", transition: "all 0.3s ease" }}
            onMouseEnter={(e) => { e.currentTarget.style.boxShadow = "0 0 50px rgba(139,92,246,0.5), 0 12px 32px rgba(139,92,246,0.35)"; e.currentTarget.style.transform = "translateY(-2px)"; }}
            onMouseLeave={(e) => { e.currentTarget.style.boxShadow = "0 0 30px rgba(139,92,246,0.4), 0 8px 24px rgba(139,92,246,0.25)"; e.currentTarget.style.transform = "translateY(0)"; }}
          >
            Khám Phá Bộ Sưu Tập
          </Link>
          <Link
            href="/sale"
            className="btn"
            style={{ padding: "16px 40px", fontSize: "0.9rem", fontWeight: 600, letterSpacing: "0.04em", background: "rgba(255,255,255,0.08)", color: "#ffffff", borderRadius: "var(--radius-md)", border: "1px solid rgba(255,255,255,0.18)", backdropFilter: "blur(12px)", transition: "all 0.3s ease" }}
            onMouseEnter={(e) => { e.currentTarget.style.background = "rgba(255,255,255,0.15)"; e.currentTarget.style.borderColor = "rgba(255,255,255,0.35)"; e.currentTarget.style.transform = "translateY(-2px)"; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = "rgba(255,255,255,0.08)"; e.currentTarget.style.borderColor = "rgba(255,255,255,0.18)"; e.currentTarget.style.transform = "translateY(0)"; }}
          >
            Xem Ưu Đãi Hot
          </Link>
        </div>

        {/* Slide dots */}
        {banners.length > 1 && (
          <div className="animate-fade-in stagger-4" style={{ display: "flex", justifyContent: "center", gap: "8px", marginTop: "var(--space-2xl)" }}>
            {banners.map((_, i) => (
              <button
                key={i}
                onClick={() => setCurrentSlide(i)}
                style={{ width: i === currentSlide ? "28px" : "8px", height: "8px", borderRadius: "var(--radius-full)", background: i === currentSlide ? "var(--color-accent)" : "rgba(255,255,255,0.2)", transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)", boxShadow: i === currentSlide ? "0 0 10px rgba(139,92,246,0.4)" : "none" }}
                aria-label={`Slide ${i + 1}`}
              />
            ))}
          </div>
        )}
      </div>

      {/* Scroll indicator */}
      <div className="animate-fade-in stagger-5" style={{ position: "absolute", bottom: "2rem", left: "50%", transform: "translateX(-50%)", display: "flex", flexDirection: "column", alignItems: "center", gap: "var(--space-xs)" }}>
        <div style={{ width: "22px", height: "36px", borderRadius: "var(--radius-full)", border: "1.5px solid rgba(255,255,255,0.15)", display: "flex", justifyContent: "center", paddingTop: "7px" }}>
          <div style={{ width: "2.5px", height: "7px", borderRadius: "var(--radius-full)", background: "rgba(255,255,255,0.5)", animation: "bounce-subtle 2s ease infinite" }} />
        </div>
      </div>
    </section>
  );
}

/* ─── Stats Bar ─── */
function StatsBar() {
  const stat1 = useCounter(500);
  const stat2 = useCounter(50);
  const stat3 = useCounter(10000);
  const stat4 = useCounter(99);
  const sectionRef = useReveal("up");

  const stats = [
    { ref: stat1.ref, count: stat1.count, suffix: "+", label: "Sản phẩm", icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" /><line x1="3" y1="6" x2="21" y2="6" /><path d="M16 10a4 4 0 0 1-8 0" /></svg> },
    { ref: stat2.ref, count: stat2.count, suffix: "+", label: "Thương hiệu", icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg> },
    { ref: stat3.ref, count: stat3.count, suffix: "+", label: "Khách hàng", icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg> },
    { ref: stat4.ref, count: stat4.count, suffix: "%", label: "Hài lòng", icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3" /></svg> },
  ];

  return (
    <section ref={sectionRef}>
      <div className="container" style={{ padding: "var(--space-2xl) var(--space-lg)" }}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "var(--space-md)" }} className="stats-grid">
          {stats.map((item) => (
            <div
              key={item.label}
              ref={item.ref}
              style={{
                display: "flex", alignItems: "center", gap: "var(--space-md)",
                padding: "var(--space-lg) var(--space-xl)",
                borderRadius: "var(--radius-lg)",
                background: "var(--bg-card)",
                border: "1px solid var(--border-color)",
                transition: "all 0.3s ease",
                cursor: "default",
              }}
              onMouseEnter={(e) => { e.currentTarget.style.transform = "translateY(-3px)"; e.currentTarget.style.boxShadow = "0 8px 24px rgba(0,0,0,0.12)"; e.currentTarget.style.borderColor = "rgba(139,92,246,0.25)"; }}
              onMouseLeave={(e) => { e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "none"; e.currentTarget.style.borderColor = "var(--border-color)"; }}
            >
              <div style={{ width: "44px", height: "44px", borderRadius: "var(--radius-md)", background: "rgba(139,92,246,0.1)", color: "var(--color-accent)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                {item.icon}
              </div>
              <div>
                <div style={{ fontSize: "1.4rem", fontWeight: 800, color: "var(--text-primary)", letterSpacing: "-0.03em", lineHeight: 1.1 }}>
                  {item.count.toLocaleString()}{item.suffix}
                </div>
                <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: "2px" }}>
                  {item.label}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ─── Categories ─── */
function CategoriesSection({ categories }: { categories: Category[] }) {
  const sectionRef = useReveal();
  const gradients = [
    "linear-gradient(135deg, #2d1b69, #1a1a2e)",
    "linear-gradient(135deg, #1a1a2e, #0f3460)",
    "linear-gradient(135deg, #0f3460, #2d1b69)",
    "linear-gradient(135deg, #1b2838, #2d1b69)",
  ];

  if (categories.length === 0) return null;

  return (
    <section className="section">
      <div className="container">
        <div ref={sectionRef} style={{ textAlign: "center", marginBottom: "var(--space-2xl)" }}>
          <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
          <h2 className="section-title">Danh Mục</h2>
          <p className="section-subtitle">Phong cách cho mọi cá tính</p>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: `repeat(${Math.min(categories.length, 4)}, 1fr)`, gap: "var(--space-lg)" }} className="categories-grid">
          {categories.map((cat, i) => {
            const ItemWrapper = ({ children }: { children: React.ReactNode }) => {
              const direction: RevealDirection = i % 2 === 0 ? "left" : "right";
              const itemRef = useReveal(direction, { threshold: 0.1, delay: i * 0.12 });
              return <div ref={itemRef}>{children}</div>;
            };
            return (
              <ItemWrapper key={cat.id}>
                <Link
                  href={`/san-pham?danh-muc=${cat.id}`}
                  style={{ position: "relative", borderRadius: "var(--radius-xl)", overflow: "hidden", aspectRatio: "3/4", display: "flex", alignItems: "flex-end", transition: "transform 0.5s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.5s ease" }}
                  onMouseEnter={(e) => { e.currentTarget.style.transform = "translateY(-8px) scale(1.02)"; e.currentTarget.style.boxShadow = "0 20px 40px rgba(139,92,246,0.15)"; }}
                  onMouseLeave={(e) => { e.currentTarget.style.transform = "translateY(0) scale(1)"; e.currentTarget.style.boxShadow = "none"; }}
                >
                  {cat.imageUrl ? (
                    <>
                      <Image src={cat.imageUrl} alt={cat.name} fill style={{ objectFit: "cover", transition: "transform 0.6s ease" }} sizes="(max-width: 768px) 100vw, 25vw" />
                      <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.8) 0%, rgba(0,0,0,0.1) 50%, transparent 100%)" }} />
                    </>
                  ) : (
                    <div style={{ position: "absolute", inset: 0, background: gradients[i % gradients.length] }} />
                  )}
                  <div style={{ position: "relative", zIndex: 2, padding: "var(--space-xl)", width: "100%" }}>
                    {cat.gender !== "all" && (
                      <p style={{ color: "var(--color-accent)", fontSize: "0.7rem", fontWeight: 600, letterSpacing: "0.15em", textTransform: "uppercase", marginBottom: "var(--space-xs)" }}>
                        {cat.gender === "male" ? "Nam" : "Nữ"}
                      </p>
                    )}
                    <h3 style={{ fontSize: "1.5rem", fontWeight: 700, color: "var(--color-white)" }}>{cat.name}</h3>
                    {cat.description && (
                      <p style={{ color: "rgba(255,255,255,0.8)", fontSize: "0.8rem", marginTop: "4px" }}>{cat.description}</p>
                    )}
                    <div style={{ display: "inline-flex", alignItems: "center", gap: "6px", marginTop: "var(--space-md)", fontSize: "0.8rem", fontWeight: 600, color: "var(--color-accent)" }}>
                      Xem thêm
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
                    </div>
                  </div>
                </Link>
              </ItemWrapper>
            );
          })}
        </div>
      </div>
    </section>
  );
}

/* ─── Shop By Gender ─── */
function ShopByGender() {
  const titleRef = useReveal("down");
  const GENDER_ITEMS = [
    { title: "Thời Trang Nam", subtitle: "Lịch lãm — Cá tính — Phong cách", href: "/nam", image: "/images/trang-chu/nam.png", gradient: "linear-gradient(135deg, rgba(26,26,46,0.75) 0%, rgba(22,33,62,0.7) 50%, rgba(15,52,96,0.65) 100%)" },
    { title: "Thời Trang Nữ", subtitle: "Thanh lịch — Hiện đại — Quyến rũ", href: "/nu", image: "/images/trang-chu/nữ.png", gradient: "linear-gradient(135deg, rgba(45,27,105,0.75) 0%, rgba(68,24,122,0.7) 50%, rgba(107,33,168,0.65) 100%)" },
  ];

  return (
    <section className="section">
      <div className="container">
        <div ref={titleRef} style={{ textAlign: "center", marginBottom: "var(--space-2xl)" }}>
          <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
          <h2 className="section-title">Mua Sắm Theo Phong Cách</h2>
          <p className="section-subtitle">Khám phá bộ sưu tập dành riêng cho bạn</p>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: "var(--space-xl)" }} className="gender-grid">
          {GENDER_ITEMS.map((item, i) => {
            const ItemWrapper = ({ children }: { children: React.ReactNode }) => {
              const dir: RevealDirection = i === 0 ? "left" : "right";
              const itemRef = useReveal(dir, { threshold: 0.1, delay: i * 0.15 });
              return <div ref={itemRef}>{children}</div>;
            };
            return (
              <ItemWrapper key={item.title}>
                <Link
                  href={item.href}
                  style={{ display: "flex", flexDirection: "column", justifyContent: "flex-end", position: "relative", borderRadius: "var(--radius-xl)", overflow: "hidden", aspectRatio: "16/9", minHeight: "320px", border: "1px solid var(--border-color)", transition: "all 0.5s cubic-bezier(0.16, 1, 0.3, 1)", textDecoration: "none", color: "inherit" }}
                  onMouseEnter={(e) => { e.currentTarget.style.transform = "translateY(-3px)"; e.currentTarget.style.boxShadow = "0 16px 40px rgba(0,0,0,0.4), 0 0 20px rgba(139,92,246,0.1)"; e.currentTarget.style.borderColor = "rgba(139,92,246,0.3)"; }}
                  onMouseLeave={(e) => { e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "none"; e.currentTarget.style.borderColor = "var(--border-color)"; }}
                >
                  {/* Background image */}
                  <Image src={item.image} alt={item.title} fill style={{ objectFit: "cover" }} sizes="(max-width: 768px) 100vw, 50vw" />
                  {/* Gradient overlay */}
                  <div style={{ position: "absolute", inset: 0, background: item.gradient, zIndex: 1 }} />
                  <div style={{ position: "absolute", top: "-20%", right: "-10%", width: "250px", height: "250px", borderRadius: "50%", background: "rgba(255,255,255,0.03)", pointerEvents: "none", zIndex: 2 }} />
                  <div style={{ position: "absolute", bottom: "-15%", left: "-8%", width: "200px", height: "200px", borderRadius: "50%", background: "rgba(139,92,246,0.06)", pointerEvents: "none", zIndex: 2 }} />
                  <div style={{ position: "relative", zIndex: 3, padding: "var(--space-2xl) var(--space-xl)" }}>
                    <div style={{ width: "56px", height: "56px", borderRadius: "var(--radius-lg)", background: "rgba(139,92,246,0.15)", color: "var(--color-accent)", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: "var(--space-lg)" }}>
                      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>
                    </div>
                    <h3 style={{ fontSize: "1.8rem", fontWeight: 700, color: "var(--color-white)", marginBottom: "var(--space-sm)", letterSpacing: "-0.02em" }}>{item.title}</h3>
                    <p style={{ color: "rgba(255,255,255,0.8)", fontSize: "0.9rem", marginBottom: "var(--space-lg)", lineHeight: 1.6 }}>{item.subtitle}</p>
                    <div style={{ display: "inline-flex", alignItems: "center", gap: "8px", padding: "10px 20px", borderRadius: "var(--radius-md)", background: "rgba(255,255,255,0.1)", backdropFilter: "blur(8px)", border: "1px solid rgba(255,255,255,0.1)", color: "var(--color-white)", fontSize: "0.85rem", fontWeight: 600 }}>
                      Khám Phá
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
                    </div>
                  </div>
                </Link>
              </ItemWrapper>
            );
          })}
        </div>
      </div>
    </section>
  );
}

/* ─── Flash Sale Banner ─── */
function FlashSaleBanner({ promotion }: { promotion: Promotion }) {
  const [time, setTime] = useState(getTimeRemaining(promotion.endDate));
  const sectionRef = useReveal("scale");

  useEffect(() => {
    const timer = setInterval(() => setTime(getTimeRemaining(promotion.endDate)), 1000);
    return () => clearInterval(timer);
  }, [promotion.endDate]);

  if (time.expired) return null;

  const discountText = promotion.discountType === "percent"
    ? `${promotion.discountValue}%`
    : formatPrice(promotion.discountValue);

  const timeBlocks = [
    { value: String(time.days).padStart(2, "0"), label: "Ngày" },
    { value: String(time.hours).padStart(2, "0"), label: "Giờ" },
    { value: String(time.minutes).padStart(2, "0"), label: "Phút" },
    { value: String(time.seconds).padStart(2, "0"), label: "Giây" },
  ];

  return (
    <section style={{ position: "relative", overflow: "hidden", background: "linear-gradient(135deg, #1a1a2e 0%, #2d1b69 50%, #8B5CF6 100%)" }}>
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
        <div style={{ position: "absolute", top: "-30%", right: "-5%", width: "400px", height: "400px", borderRadius: "50%", background: "rgba(255,255,255,0.03)", animation: "float 8s ease-in-out infinite" }} />
        <div style={{ position: "absolute", bottom: "-20%", left: "10%", width: "300px", height: "300px", borderRadius: "50%", background: "rgba(255,255,255,0.02)", animation: "float 10s ease-in-out infinite reverse" }} />
      </div>
      <div ref={sectionRef} className="container reveal" style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: "var(--space-2xl)", padding: "var(--space-4xl) var(--space-lg)", position: "relative", zIndex: 2 }}>
        <div style={{ maxWidth: "520px" }}>
          <p style={{ display: "inline-flex", alignItems: "center", gap: "8px", padding: "6px 14px", borderRadius: "var(--radius-full)", background: "rgba(255,255,255,0.1)", backdropFilter: "blur(8px)", color: "#fbbf24", fontSize: "0.8rem", fontWeight: 700, letterSpacing: "0.1em", textTransform: "uppercase", marginBottom: "var(--space-lg)" }}>
            ⚡ Flash Sale
          </p>
          <h2 style={{ fontSize: "clamp(2rem, 4vw, 3.2rem)", fontWeight: 800, color: "var(--color-white)", lineHeight: 1.1, marginBottom: "var(--space-md)" }}>
            Giảm đến <span style={{ color: "#fbbf24" }}>{discountText}</span>
            <br />{promotion.name}
          </h2>
          <p style={{ color: "rgba(255,255,255,0.7)", fontSize: "1rem", lineHeight: 1.7, marginBottom: "var(--space-xl)" }}>
            {promotion.description || "Nhanh tay sở hữu những item hot nhất với mức giá không thể tốt hơn."}
          </p>
          <Link href="/sale" className="btn" style={{ background: "var(--color-white)", color: "var(--color-primary)", padding: "1rem 2.5rem", fontWeight: 700, fontSize: "0.95rem", borderRadius: "var(--radius-md)" }}>
            Mua Ngay →
          </Link>
        </div>
        <div style={{ display: "flex", gap: "var(--space-md)" }}>
          {timeBlocks.map((item) => (
            <div key={item.label} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "var(--space-xs)" }}>
              <div style={{ width: "76px", height: "76px", borderRadius: "var(--radius-lg)", background: "rgba(255,255,255,0.08)", backdropFilter: "blur(12px)", border: "1px solid rgba(255,255,255,0.12)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "1.8rem", fontWeight: 800, color: "var(--color-white)" }}>
                {item.value}
              </div>
              <span style={{ fontSize: "0.7rem", fontWeight: 500, color: "rgba(255,255,255,0.75)", textTransform: "uppercase", letterSpacing: "0.1em" }}>{item.label}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function StaticPromoBanner() {
  const sectionRef = useReveal("scale");
  return (
    <section style={{ position: "relative", overflow: "hidden", background: "linear-gradient(135deg, #1a1a2e 0%, #2d1b69 50%, #8B5CF6 100%)" }}>
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
        <div style={{ position: "absolute", top: "-30%", right: "-5%", width: "400px", height: "400px", borderRadius: "50%", background: "rgba(255,255,255,0.03)", animation: "float 8s ease-in-out infinite" }} />
      </div>
      <div ref={sectionRef} className="container reveal" style={{ padding: "var(--space-4xl) var(--space-lg)", position: "relative", zIndex: 2, maxWidth: "600px" }}>
        <p style={{ color: "rgba(255,255,255,0.7)", fontSize: "0.85rem", fontWeight: 600, letterSpacing: "0.15em", textTransform: "uppercase", marginBottom: "var(--space-md)" }}>
          Ưu đãi đặc biệt
        </p>
        <h2 style={{ fontSize: "clamp(2rem, 4vw, 3rem)", fontWeight: 800, color: "var(--color-white)", lineHeight: 1.15, marginBottom: "var(--space-md)" }}>
          Giảm đến <span style={{ color: "#fbbf24" }}>50%</span><br />Bộ sưu tập mùa mới
        </h2>
        <p style={{ color: "rgba(255,255,255,0.7)", fontSize: "1rem", lineHeight: 1.7, marginBottom: "var(--space-xl)" }}>
          Nhanh tay sở hữu những item hot nhất mùa này.
        </p>
        <Link href="/sale" className="btn" style={{ background: "var(--color-white)", color: "var(--color-primary)", padding: "1rem 2.5rem", fontWeight: 700, borderRadius: "var(--radius-md)" }}>
          Mua Ngay →
        </Link>
      </div>
    </section>
  );
}

/* ─── Lookbook ─── */
function Lookbook() {
  const titleRef = useReveal("down");
  const item1Ref = useReveal("left", { threshold: 0.1, delay: 0 });
  const item2Ref = useReveal("right", { threshold: 0.1, delay: 0.15 });
  const item3Ref = useReveal("up", { threshold: 0.1, delay: 0.3 });
  const LOOKBOOK_ITEMS = [
    { image: "/images/lookbook/lifestyle-1.png", label: "Street Style", caption: "Phong cách đường phố hiện đại" },
    { image: "/images/lookbook/lifestyle-2.png", label: "Elegant", caption: "Thanh lịch trong từng khoảnh khắc" },
    { image: "/images/lookbook/lifestyle-3.png", label: "Accessories", caption: "Phụ kiện tạo nên sự khác biệt" },
  ];

  return (
    <section className="section">
      <div className="container">
        <div ref={titleRef} style={{ textAlign: "center", marginBottom: "var(--space-2xl)" }}>
          <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
          <h2 className="section-title">Lookbook</h2>
          <p className="section-subtitle">Cảm hứng phong cách — Mùa Xuân Hè 2026</p>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gridTemplateRows: "380px 280px", gap: "var(--space-md)" }} className="lookbook-grid">
          {/* Large left image */}
          <div
            ref={item1Ref}
            className="lookbook-item"
            style={{ gridRow: "1 / 3", gridColumn: "1", position: "relative", borderRadius: "var(--radius-xl)", overflow: "hidden", cursor: "default" }}
            onMouseEnter={(e) => { const img = e.currentTarget.querySelector("img"); if (img) img.style.transform = "scale(1.05)"; }}
            onMouseLeave={(e) => { const img = e.currentTarget.querySelector("img"); if (img) img.style.transform = "scale(1)"; }}
          >
            <Image src={LOOKBOOK_ITEMS[0].image} alt={LOOKBOOK_ITEMS[0].label} fill style={{ objectFit: "cover", transition: "transform 0.6s cubic-bezier(0.16, 1, 0.3, 1)" }} sizes="(max-width: 768px) 100vw, 33vw" />
            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 50%)" }} />
            <div style={{ position: "absolute", bottom: 0, left: 0, padding: "var(--space-xl)", zIndex: 2 }}>
              <span style={{ display: "inline-block", padding: "4px 12px", borderRadius: "var(--radius-sm)", background: "rgba(139,92,246,0.8)", color: "var(--color-white)", fontSize: "0.65rem", fontWeight: 700, letterSpacing: "0.1em", marginBottom: "var(--space-sm)" }}>{LOOKBOOK_ITEMS[0].label.toUpperCase()}</span>
              <p style={{ color: "rgba(255,255,255,0.85)", fontSize: "0.9rem", fontWeight: 500 }}>{LOOKBOOK_ITEMS[0].caption}</p>
            </div>
          </div>
          {/* Top right */}
          <div
            ref={item2Ref}
            className="lookbook-item"
            style={{ gridRow: "1", gridColumn: "2 / 4", position: "relative", borderRadius: "var(--radius-xl)", overflow: "hidden", cursor: "default" }}
            onMouseEnter={(e) => { const img = e.currentTarget.querySelector("img"); if (img) img.style.transform = "scale(1.05)"; }}
            onMouseLeave={(e) => { const img = e.currentTarget.querySelector("img"); if (img) img.style.transform = "scale(1)"; }}
          >
            <Image src={LOOKBOOK_ITEMS[1].image} alt={LOOKBOOK_ITEMS[1].label} fill style={{ objectFit: "cover", objectPosition: "center 25%", transition: "transform 0.6s cubic-bezier(0.16, 1, 0.3, 1)" }} sizes="(max-width: 768px) 100vw, 66vw" />
            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 50%)" }} />
            <div style={{ position: "absolute", bottom: 0, left: 0, padding: "var(--space-xl)", zIndex: 2 }}>
              <span style={{ display: "inline-block", padding: "4px 12px", borderRadius: "var(--radius-sm)", background: "rgba(139,92,246,0.8)", color: "var(--color-white)", fontSize: "0.65rem", fontWeight: 700, letterSpacing: "0.1em", marginBottom: "var(--space-sm)" }}>{LOOKBOOK_ITEMS[1].label.toUpperCase()}</span>
              <p style={{ color: "rgba(255,255,255,0.85)", fontSize: "0.9rem", fontWeight: 500 }}>{LOOKBOOK_ITEMS[1].caption}</p>
            </div>
          </div>
          {/* Bottom right */}
          <div
            ref={item3Ref}
            className="lookbook-item"
            style={{ gridRow: "2", gridColumn: "2 / 4", position: "relative", borderRadius: "var(--radius-xl)", overflow: "hidden", cursor: "default" }}
            onMouseEnter={(e) => { const img = e.currentTarget.querySelector("img"); if (img) img.style.transform = "scale(1.05)"; }}
            onMouseLeave={(e) => { const img = e.currentTarget.querySelector("img"); if (img) img.style.transform = "scale(1)"; }}
          >
            <Image src={LOOKBOOK_ITEMS[2].image} alt={LOOKBOOK_ITEMS[2].label} fill style={{ objectFit: "cover", transition: "transform 0.6s cubic-bezier(0.16, 1, 0.3, 1)" }} sizes="(max-width: 768px) 100vw, 66vw" />
            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 50%)" }} />
            <div style={{ position: "absolute", bottom: 0, left: 0, padding: "var(--space-xl)", zIndex: 2 }}>
              <span style={{ display: "inline-block", padding: "4px 12px", borderRadius: "var(--radius-sm)", background: "rgba(139,92,246,0.8)", color: "var(--color-white)", fontSize: "0.65rem", fontWeight: 700, letterSpacing: "0.1em", marginBottom: "var(--space-sm)" }}>{LOOKBOOK_ITEMS[2].label.toUpperCase()}</span>
              <p style={{ color: "rgba(255,255,255,0.85)", fontSize: "0.9rem", fontWeight: 500 }}>{LOOKBOOK_ITEMS[2].caption}</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ─── Brands Marquee ─── */
function BrandsSection({ brands }: { brands: Brand[] }) {
  const titleRef = useReveal("up");
  if (brands.length === 0) return null;
  const doubled = [...brands, ...brands];

  return (
    <section className="section">
      <div className="container">
        <div ref={titleRef} style={{ textAlign: "center", marginBottom: "var(--space-2xl)" }}>
          <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
          <h2 className="section-title">Thương Hiệu Nổi Bật</h2>
          <p className="section-subtitle">Hợp tác cùng các thương hiệu hàng đầu thế giới</p>
        </div>
      </div>
      <div style={{ overflow: "hidden", padding: "var(--space-lg) 0" }}>
        <div className="marquee-track">
          {doubled.map((brand, i) => (
            <div
              key={`${brand.id}-${i}`}
              style={{ flexShrink: 0, width: "180px", height: "88px", borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)", background: "var(--bg-card)", display: "flex", alignItems: "center", justifyContent: "center", padding: "var(--space-md) var(--space-lg)", marginRight: "var(--space-lg)", transition: "all 0.3s ease", cursor: "pointer" }}
              onMouseEnter={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.transform = "translateY(-3px) scale(1.05)"; e.currentTarget.style.boxShadow = "0 8px 24px rgba(139,92,246,0.12)"; }}
              onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.transform = "translateY(0) scale(1)"; e.currentTarget.style.boxShadow = "none"; }}
              title={brand.name}
            >
              {brand.logo ? (
                <Image src={brand.logo} alt={brand.name} width={120} height={44} style={{ objectFit: "contain", maxHeight: "44px" }} />
              ) : (
                <span style={{ fontSize: "0.9rem", fontWeight: 700, color: "var(--text-secondary)", letterSpacing: "0.08em", textTransform: "uppercase" }}>{brand.name}</span>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ─── Why Choose Us ─── */
function WhyChooseUs() {
  const titleRef = useReveal("down");
  return (
    <section className="section" style={{ background: "var(--bg-secondary)" }}>
      <div className="container">
        <div ref={titleRef} style={{ textAlign: "center", marginBottom: "var(--space-2xl)" }}>
          <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
          <h2 className="section-title">Tại Sao Chọn StyleZone?</h2>
          <p className="section-subtitle">Cam kết chất lượng, dịch vụ tận tâm</p>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "var(--space-xl)" }} className="usp-grid">
          {USP_ITEMS.map((item, i) => {
            const ItemWrapper = ({ children }: { children: React.ReactNode }) => {
              const itemRef = useReveal("scale", { threshold: 0.1, delay: i * 0.12 });
              return <div ref={itemRef}>{children}</div>;
            };
            return (
              <ItemWrapper key={item.title}>
                <div
                  style={{ display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center", padding: "var(--space-2xl) var(--space-xl)", borderRadius: "var(--radius-xl)", border: "1px solid var(--border-color)", background: "var(--bg-card)", transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)" }}
                  onMouseEnter={(e) => { e.currentTarget.style.borderColor = "rgba(139,92,246,0.3)"; e.currentTarget.style.transform = "translateY(-3px)"; e.currentTarget.style.boxShadow = "0 8px 24px rgba(0,0,0,0.15), 0 0 12px rgba(139,92,246,0.06)"; }}
                  onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "none"; }}
                >
                  <div style={{ width: "60px", height: "60px", borderRadius: "var(--radius-lg)", background: "rgba(139, 92, 246, 0.1)", color: "var(--color-accent)", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: "var(--space-lg)", transition: "transform 0.3s ease" }}>
                    {item.icon}
                  </div>
                  <h4 style={{ fontSize: "0.95rem", fontWeight: 600, color: "var(--text-primary)", marginBottom: "var(--space-sm)" }}>{item.title}</h4>
                  <p style={{ fontSize: "0.85rem", color: "var(--text-muted)", lineHeight: 1.6 }}>{item.desc}</p>
                </div>
              </ItemWrapper>
            );
          })}
        </div>
      </div>
    </section>
  );
}

/* ─── Newsletter ─── */
function Newsletter() {
  const sectionRef = useReveal("up");
  return (
    <section className="section">
      <div className="container">
        <div
          ref={sectionRef}
          style={{
            textAlign: "center",
            padding: "var(--space-4xl) var(--space-2xl)",
            borderRadius: "var(--radius-2xl)",
            background: "linear-gradient(135deg, rgba(139,92,246,0.08) 0%, rgba(139,92,246,0.02) 100%)",
            border: "1px solid var(--border-color)",
          }}
        >
          <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
          <h2 className="section-title">Đăng Ký Nhận Tin</h2>
          <p style={{ color: "var(--text-secondary)", fontSize: "1rem", maxWidth: "480px", margin: "0 auto var(--space-2xl)", lineHeight: 1.7 }}>
            Nhận thông tin khuyến mãi và bộ sưu tập mới nhất từ StyleZone
          </p>
          <div style={{ display: "flex", gap: "var(--space-sm)", justifyContent: "center", maxWidth: "480px", margin: "0 auto" }}>
            <input
              type="email"
              placeholder="Nhập email của bạn..."
              style={{
                flex: 1,
                padding: "14px 20px",
                borderRadius: "var(--radius-md)",
                border: "1px solid var(--border-color)",
                background: "var(--bg-card)",
                color: "var(--text-primary)",
                fontSize: "0.9rem",
                outline: "none",
                transition: "border-color 0.3s ease",
              }}
              onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; }}
              onBlur={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; }}
            />
            <button className="btn btn-primary" style={{ padding: "14px 28px", whiteSpace: "nowrap" }}>
              Đăng Ký
            </button>
          </div>
          <p style={{ color: "var(--text-muted)", fontSize: "0.75rem", marginTop: "var(--space-md)" }}>
            Chúng tôi tôn trọng quyền riêng tư của bạn. Hủy đăng ký bất cứ lúc nào.
          </p>
        </div>
      </div>
    </section>
  );
}

/* ================ PAGE ================ */

export default function Home() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [banners, setBanners] = useState<Banner[]>([]);
  const [flashSale, setFlashSale] = useState<Promotion | null>(null);
  const [brands, setBrands] = useState<Brand[]>([]);

  const fetchData = useCallback(async () => {
    try {
      const [cats, bannerList, sale, brandList] = await Promise.all([
        getParentCategories(),
        getHeroBanners(),
        getFlashSale(),
        getBrands(),
      ]);
      setCategories(cats);
      setBanners(bannerList);
      setFlashSale(sale);
      setBrands(brandList);
    } catch (err) {
      console.error("Failed to fetch data:", err);
    }
  }, []);

  useEffect(() => {
    window.history.scrollRestoration = "manual";
    window.scrollTo(0, 0);
    // eslint-disable-next-line react-hooks/set-state-in-effect
    fetchData();
  }, [fetchData]);

  return (
    <>
      <HeroSection banners={banners} />
      <ShopByGender />
      {flashSale ? <FlashSaleBanner promotion={flashSale} /> : <StaticPromoBanner />}
      <Lookbook />
      <BrandsSection brands={brands} />
      <StatsBar />
      <WhyChooseUs />
      <Newsletter />

      <style jsx global>{`
        @media (max-width: 1024px) {
          .usp-grid { grid-template-columns: repeat(2, 1fr) !important; }
          .categories-grid { grid-template-columns: repeat(2, 1fr) !important; }
          .stats-grid { grid-template-columns: repeat(2, 1fr) !important; }
          .lookbook-grid { grid-template-columns: 1fr 1fr !important; grid-template-rows: 240px 240px 240px !important; }
        }
        @media (max-width: 768px) {
          .categories-grid { grid-template-columns: 1fr !important; }
          .usp-grid { grid-template-columns: 1fr !important; }
          .gender-grid { grid-template-columns: 1fr !important; }
          .stats-grid { grid-template-columns: repeat(2, 1fr) !important; }
          .lookbook-grid { grid-template-columns: 1fr !important; grid-template-rows: 280px 220px 220px !important; }
          .lookbook-grid > div { grid-row: auto !important; grid-column: auto !important; }
          .section { padding: var(--space-2xl) 0 !important; }
        }
      `}</style>
    </>
  );
}
