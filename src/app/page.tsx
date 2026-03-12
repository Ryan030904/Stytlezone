"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useState, useCallback, useRef } from "react";
import { getFeaturedProducts, getNewArrivals } from "@/lib/products";
import { getParentCategories } from "@/lib/categories";
import { getHeroBanners } from "@/lib/banners";
import { getFlashSale } from "@/lib/promotions";
import { getBrands } from "@/lib/brands";
import type { Product, Category, Banner, Promotion, Brand } from "@/lib/types";

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

  const banner = banners[currentSlide];

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
      {/* Parallax Background */}
      <div
        style={{
          position: "absolute",
          inset: "-20px",
          transform: `translate(${mousePos.x}px, ${mousePos.y}px)`,
          transition: "transform 0.3s ease-out",
        }}
      >
        <Image
          src={banner?.imageUrl || "/images/homepage-hero.png"}
          alt={banner?.title || "StyleZone — Thời Trang Hiện Đại"}
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

      {/* Floating decorative orbs */}
      <div
        style={{
          position: "absolute",
          top: "10%",
          right: "15%",
          width: "300px",
          height: "300px",
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(139,92,246,0.15) 0%, transparent 70%)",
          animation: "float 6s ease-in-out infinite",
          pointerEvents: "none",
        }}
      />
      <div
        style={{
          position: "absolute",
          bottom: "15%",
          left: "10%",
          width: "200px",
          height: "200px",
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(139,92,246,0.1) 0%, transparent 70%)",
          animation: "float 8s ease-in-out infinite reverse",
          pointerEvents: "none",
        }}
      />
      <div
        style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          width: "500px",
          height: "500px",
          borderRadius: "50%",
          border: "1px solid rgba(139,92,246,0.06)",
          animation: "rotate-slow 60s linear infinite",
          pointerEvents: "none",
          transform: "translate(-50%, -50%)",
        }}
      />

      {/* Content */}
      <div
        className="container"
        style={{
          position: "relative",
          zIndex: 2,
          textAlign: "center",
          paddingTop: "var(--header-height)",
        }}
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
          <span style={{
            width: "6px",
            height: "6px",
            borderRadius: "50%",
            background: "var(--color-accent)",
            animation: "pulse-glow 2s ease infinite",
          }} />
          {banner?.subtitle || "New Collection 2026"}
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
          {banner?.title ? (
            <span>{banner.title}</span>
          ) : (
            <>
              Khẳng Định
              <br />
              <span className="gradient-text" style={{ fontStyle: "italic" }}>Phong Cách</span>{" "}
              <span>Của Bạn</span>
            </>
          )}
        </h1>

        <p
          className="animate-slide-up stagger-2"
          style={{
            color: "var(--hero-subtitle)",
            fontSize: "clamp(1rem, 2vw, 1.2rem)",
            maxWidth: "560px",
            margin: "0 auto var(--space-2xl)",
            lineHeight: 1.8,
          }}
        >
          Khám phá bộ sưu tập thời trang nam nữ mới nhất — thiết kế hiện đại, chất liệu cao cấp, giá tốt nhất thị trường.
        </p>

        <div
          className="animate-slide-up stagger-3"
          style={{
            display: "flex",
            gap: "var(--space-md)",
            justifyContent: "center",
            flexWrap: "wrap",
          }}
        >
          <Link
            href={banner?.linkUrl || "/bo-suu-tap"}
            className="btn btn-primary"
            style={{ padding: "1rem 2.5rem", fontSize: "0.95rem" }}
          >
            Khám Phá Ngay →
          </Link>
          <Link href="/sale" className="btn btn-outline" style={{ padding: "1rem 2.5rem", fontSize: "0.95rem" }}>
            Ưu Đãi Hot 🔥
          </Link>
        </div>

        {/* Slide dots */}
        {banners.length > 1 && (
          <div
            className="animate-fade-in stagger-4"
            style={{
              display: "flex",
              justifyContent: "center",
              gap: "8px",
              marginTop: "var(--space-3xl)",
            }}
          >
            {banners.map((_, i) => (
              <button
                key={i}
                onClick={() => setCurrentSlide(i)}
                style={{
                  width: i === currentSlide ? "32px" : "8px",
                  height: "8px",
                  borderRadius: "var(--radius-full)",
                  background: i === currentSlide ? "var(--color-accent)" : "rgba(255,255,255,0.25)",
                  transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
                  boxShadow: i === currentSlide ? "0 0 12px rgba(139,92,246,0.5)" : "none",
                }}
                aria-label={`Slide ${i + 1}`}
              />
            ))}
          </div>
        )}
      </div>

      {/* Scroll indicator */}
      <div
        className="animate-fade-in stagger-5"
        style={{
          position: "absolute",
          bottom: "2.5rem",
          left: "50%",
          transform: "translateX(-50%)",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: "var(--space-sm)",
        }}
      >
        <div
          style={{
            width: "24px",
            height: "40px",
            borderRadius: "var(--radius-full)",
            border: "2px solid rgba(255,255,255,0.2)",
            display: "flex",
            justifyContent: "center",
            paddingTop: "8px",
          }}
        >
          <div
            style={{
              width: "3px",
              height: "8px",
              borderRadius: "var(--radius-full)",
              background: "var(--color-accent)",
              animation: "bounce-subtle 2s ease infinite",
            }}
          />
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

  return (
    <section
      style={{
        background: "linear-gradient(90deg, var(--color-primary), var(--color-primary-light), var(--color-primary))",
        borderTop: "1px solid var(--border-color)",
        borderBottom: "1px solid var(--border-color)",
      }}
    >
      <div
        className="container"
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: "var(--space-md)",
          padding: "var(--space-2xl) var(--space-lg)",
          textAlign: "center",
        }}
      >
        {[
          { ref: stat1.ref, count: stat1.count, suffix: "+", label: "Sản phẩm" },
          { ref: stat2.ref, count: stat2.count, suffix: "+", label: "Thương hiệu" },
          { ref: stat3.ref, count: stat3.count, suffix: "+", label: "Khách hàng" },
          { ref: stat4.ref, count: stat4.count, suffix: "%", label: "Hài lòng" },
        ].map((item) => (
          <div key={item.label} ref={item.ref}>
            <div
              style={{
                fontSize: "clamp(1.5rem, 3vw, 2.2rem)",
                fontWeight: 800,
                color: "var(--color-white)",
                letterSpacing: "-0.03em",
              }}
            >
              {item.count.toLocaleString()}{item.suffix}
            </div>
            <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "2px" }}>
              {item.label}
            </div>
          </div>
        ))}
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
        <div
          style={{
            display: "grid",
            gridTemplateColumns: `repeat(${Math.min(categories.length, 4)}, 1fr)`,
            gap: "var(--space-lg)",
          }}
          className="categories-grid"
        >
          {categories.map((cat, i) => {
            const ItemWrapper = ({ children }: { children: React.ReactNode }) => {
              const direction: RevealDirection = i % 2 === 0 ? "left" : "right";
              const itemRef = useReveal(direction, { threshold: 0.1, delay: i * 0.12 });
              return (
                <div ref={itemRef}>
                  {children}
                </div>
              );
            };
            return (
              <ItemWrapper key={cat.id}>
                <Link
                  href={`/danh-muc/${cat.id}`}
                  style={{
                    position: "relative",
                    borderRadius: "var(--radius-xl)",
                    overflow: "hidden",
                    aspectRatio: "3/4",
                    display: "flex",
                    alignItems: "flex-end",
                    transition: "transform 0.5s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.5s ease",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.transform = "translateY(-8px) scale(1.02)";
                    e.currentTarget.style.boxShadow = "0 20px 40px rgba(139,92,246,0.15)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.transform = "translateY(0) scale(1)";
                    e.currentTarget.style.boxShadow = "none";
                  }}
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
                      <p style={{ color: "rgba(255,255,255,0.6)", fontSize: "0.8rem", marginTop: "4px" }}>{cat.description}</p>
                    )}
                    <div style={{
                      display: "inline-flex",
                      alignItems: "center",
                      gap: "6px",
                      marginTop: "var(--space-md)",
                      fontSize: "0.8rem",
                      fontWeight: 600,
                      color: "var(--color-accent)",
                    }}>
                      Xem thêm
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                        <path d="M5 12h14M12 5l7 7-7 7" />
                      </svg>
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

/* ─── Product Card ─── */
function ProductCard({ product, index = 0 }: { product: Product; index?: number }) {
  const badge = getBadge(product);
  const displayPrice = product.salePrice > 0 && product.salePrice < product.price ? product.salePrice : product.price;
  const originalPrice = product.salePrice > 0 && product.salePrice < product.price ? product.price : null;
  const imageUrl = product.images.length > 0 ? product.images[0] : null;
  const secondImage = product.images.length > 1 ? product.images[1] : null;
  const cardRef = useReveal("up", { threshold: 0.05, delay: index * 0.08 });

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
          transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
          textDecoration: "none",
          color: "inherit",
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.borderColor = "rgba(255,255,255,0.15)";
          e.currentTarget.style.transform = "translateY(-6px)";
          e.currentTarget.style.boxShadow = "0 20px 40px rgba(0,0,0,0.5), 0 0 20px rgba(139,92,246,0.08), 0 1px 0 rgba(255,255,255,0.06) inset";
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.borderColor = "var(--border-color)";
          e.currentTarget.style.transform = "translateY(0)";
          e.currentTarget.style.boxShadow = "none";
        }}
      >
        {/* Image with hover-swap + zoom */}
        <div
          className="product-img-wrap"
          style={{
            aspectRatio: "3/4",
            background: "linear-gradient(135deg, var(--bg-surface), var(--bg-elevated))",
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
                transition: "opacity 0.4s ease, transform 0.5s cubic-bezier(0.16, 1, 0.3, 1)",
              }}
              sizes="(max-width: 768px) 50vw, 25vw"
              className="product-img-primary"
            />
          )}
          {secondImage && (
            <Image
              src={secondImage}
              alt={`${product.name} - 2`}
              fill
              style={{
                objectFit: "cover",
                opacity: 0,
                transition: "opacity 0.4s ease",
              }}
              sizes="(max-width: 768px) 50vw, 25vw"
              className="product-img-secondary"
            />
          )}
          {/* Badge — top left */}
          {badge && (
            <span
              style={{
                position: "absolute",
                top: "var(--space-md)",
                left: "var(--space-md)",
                padding: "5px 12px",
                borderRadius: "var(--radius-sm)",
                background: badge === "MỚI" ? "var(--color-accent)" : "var(--color-success)",
                color: "var(--color-white)",
                fontSize: "0.7rem",
                fontWeight: 700,
                letterSpacing: "0.05em",
                zIndex: 2,
              }}
            >
              {badge}
            </span>
          )}
          {/* Action buttons — top right */}
          <div
            className="product-actions"
            style={{
              position: "absolute",
              top: "var(--space-sm)",
              right: "var(--space-sm)",
              display: "flex",
              flexDirection: "column",
              gap: "6px",
              opacity: 0,
              transform: "translateX(8px)",
              transition: "all 0.3s ease",
              zIndex: 3,
            }}
          >
            <button
              onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}
              style={{
                width: "34px",
                height: "34px",
                borderRadius: "var(--radius-md)",
                background: "rgba(0,0,0,0.5)",
                backdropFilter: "blur(8px)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "var(--color-white)",
                transition: "all 0.2s ease",
              }}
              onMouseEnter={(e) => { e.currentTarget.style.background = "var(--color-accent)"; }}
              onMouseLeave={(e) => { e.currentTarget.style.background = "rgba(0,0,0,0.5)"; }}
              aria-label="Yêu thích"
              title="Yêu thích"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
              </svg>
            </button>
            <button
              onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}
              style={{
                width: "34px",
                height: "34px",
                borderRadius: "var(--radius-md)",
                background: "rgba(0,0,0,0.5)",
                backdropFilter: "blur(8px)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "var(--color-white)",
                transition: "all 0.2s ease",
              }}
              onMouseEnter={(e) => { e.currentTarget.style.background = "var(--color-accent)"; }}
              onMouseLeave={(e) => { e.currentTarget.style.background = "rgba(0,0,0,0.5)"; }}
              aria-label="Thêm giỏ hàng"
              title="Thêm giỏ hàng"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" /><line x1="3" y1="6" x2="21" y2="6" /><path d="M16 10a4 4 0 0 1-8 0" />
              </svg>
            </button>
          </div>
        </div>
        {/* Info */}
        <div style={{ padding: "var(--space-lg)" }}>
          <p style={{ fontSize: "0.7rem", color: "var(--text-muted)", marginBottom: "4px", textTransform: "uppercase", letterSpacing: "0.08em" }}>
            {product.brandName || product.categoryName}
          </p>
          <h4 style={{
            fontSize: "0.9rem",
            fontWeight: 500,
            color: "var(--text-primary)",
            marginBottom: "var(--space-sm)",
            lineHeight: 1.4,
            display: "-webkit-box",
            WebkitLineClamp: 2,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
          }}>
            {product.name}
          </h4>
          {/* Colors */}
          {product.colors.length > 0 && (
            <div style={{ display: "flex", gap: "4px", marginBottom: "var(--space-sm)" }}>
              {product.colors.slice(0, 5).map((color, i) => (
                <span
                  key={i}
                  style={{
                    width: "14px",
                    height: "14px",
                    borderRadius: "var(--radius-full)",
                    border: "1.5px solid var(--border-light)",
                    background: color.startsWith("#") ? color : "var(--bg-elevated)",
                  }}
                  title={color}
                />
              ))}
              {product.colors.length > 5 && (
                <span style={{ fontSize: "0.65rem", color: "var(--text-muted)", alignSelf: "center" }}>+{product.colors.length - 5}</span>
              )}
            </div>
          )}
          <div style={{ display: "flex", alignItems: "center", gap: "var(--space-sm)" }}>
            <span style={{ fontSize: "1rem", fontWeight: 700, color: "var(--color-accent)" }}>
              {formatPrice(displayPrice)}
            </span>
            {originalPrice && (
              <span style={{ fontSize: "0.8rem", color: "var(--text-muted)", textDecoration: "line-through" }}>
                {formatPrice(originalPrice)}
              </span>
            )}
          </div>
        </div>
      </Link>
    </div>
  );
}

/* ─── Products Section ─── */
function ProductsSection({ title, subtitle, products, loading }: {
  title: string; subtitle: string; products: Product[]; loading?: boolean;
}) {
  const titleRef = useReveal("down");
  return (
    <section className="section">
      <div className="container">
        <div ref={titleRef} style={{ textAlign: "center", marginBottom: "var(--space-2xl)" }}>
          <div className="accent-line" style={{ margin: "0 auto var(--space-lg)" }} />
          <h2 className="section-title">{title}</h2>
          <p className="section-subtitle">{subtitle}</p>
        </div>
        {loading ? (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "var(--space-lg)" }} className="products-grid">
            {[...Array(4)].map((_, i) => (
              <div key={i} style={{ borderRadius: "var(--radius-lg)", overflow: "hidden", background: "var(--bg-card)", border: "1px solid var(--border-color)" }}>
                <div style={{ aspectRatio: "3/4", background: "linear-gradient(90deg, var(--bg-surface) 25%, var(--bg-elevated) 50%, var(--bg-surface) 75%)", backgroundSize: "200% 100%", animation: "shimmer 1.5s infinite" }} />
                <div style={{ padding: "var(--space-lg)" }}>
                  <div style={{ height: "12px", background: "var(--bg-surface)", borderRadius: "4px", marginBottom: "8px", width: "60%" }} />
                  <div style={{ height: "16px", background: "var(--bg-surface)", borderRadius: "4px", marginBottom: "8px" }} />
                  <div style={{ height: "14px", background: "var(--bg-surface)", borderRadius: "4px", width: "40%" }} />
                </div>
              </div>
            ))}
          </div>
        ) : products.length === 0 ? (
          <div style={{ textAlign: "center", padding: "var(--space-3xl) 0", color: "var(--text-muted)" }}>
            <p>Chưa có sản phẩm nào</p>
          </div>
        ) : (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "var(--space-lg)" }} className="products-grid">
            {products.map((product, i) => (
              <ProductCard key={product.id} product={product} index={i} />
            ))}
          </div>
        )}
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
    <section
      style={{
        position: "relative",
        overflow: "hidden",
        background: "linear-gradient(135deg, #1a1a2e 0%, #2d1b69 50%, #8B5CF6 100%)",
      }}
    >
      {/* Animated background particles */}
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
        <div style={{ position: "absolute", top: "-30%", right: "-5%", width: "400px", height: "400px", borderRadius: "50%", background: "rgba(255,255,255,0.03)", animation: "float 8s ease-in-out infinite" }} />
        <div style={{ position: "absolute", bottom: "-20%", left: "10%", width: "300px", height: "300px", borderRadius: "50%", background: "rgba(255,255,255,0.02)", animation: "float 10s ease-in-out infinite reverse" }} />
      </div>

      <div
        ref={sectionRef}
        className="container reveal"
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap",
          gap: "var(--space-2xl)",
          padding: "var(--space-4xl) var(--space-lg)",
          position: "relative",
          zIndex: 2,
        }}
      >
        <div style={{ maxWidth: "520px" }}>
          <p style={{
            display: "inline-flex",
            alignItems: "center",
            gap: "8px",
            padding: "6px 14px",
            borderRadius: "var(--radius-full)",
            background: "rgba(255,255,255,0.1)",
            backdropFilter: "blur(8px)",
            color: "#fbbf24",
            fontSize: "0.8rem",
            fontWeight: 700,
            letterSpacing: "0.1em",
            textTransform: "uppercase",
            marginBottom: "var(--space-lg)",
          }}>
            ⚡ Flash Sale
          </p>
          <h2 style={{
            fontSize: "clamp(2rem, 4vw, 3.2rem)",
            fontWeight: 800,
            color: "var(--color-white)",
            lineHeight: 1.1,
            marginBottom: "var(--space-md)",
          }}>
            Giảm đến <span style={{ color: "#fbbf24" }}>{discountText}</span>
            <br />{promotion.name}
          </h2>
          <p style={{ color: "rgba(255,255,255,0.7)", fontSize: "1rem", lineHeight: 1.7, marginBottom: "var(--space-xl)" }}>
            {promotion.description || "Nhanh tay sở hữu những item hot nhất với mức giá không thể tốt hơn."}
          </p>
          <Link
            href="/sale"
            className="btn"
            style={{
              background: "var(--color-white)",
              color: "var(--color-primary)",
              padding: "1rem 2.5rem",
              fontWeight: 700,
              fontSize: "0.95rem",
              borderRadius: "var(--radius-md)",
            }}
          >
            Mua Ngay →
          </Link>
        </div>

        {/* Countdown */}
        <div style={{ display: "flex", gap: "var(--space-md)" }}>
          {timeBlocks.map((item) => (
            <div key={item.label} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "var(--space-xs)" }}>
              <div style={{
                width: "76px",
                height: "76px",
                borderRadius: "var(--radius-lg)",
                background: "rgba(255,255,255,0.08)",
                backdropFilter: "blur(12px)",
                border: "1px solid rgba(255,255,255,0.12)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "1.8rem",
                fontWeight: 800,
                color: "var(--color-white)",
                transition: "transform 0.2s ease",
              }}>
                {item.value}
              </div>
              <span style={{ fontSize: "0.7rem", fontWeight: 500, color: "rgba(255,255,255,0.5)", textTransform: "uppercase", letterSpacing: "0.1em" }}>
                {item.label}
              </span>
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
    <section style={{
      position: "relative",
      overflow: "hidden",
      background: "linear-gradient(135deg, #1a1a2e 0%, #2d1b69 50%, #8B5CF6 100%)",
    }}>
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
        <div style={{ position: "absolute", top: "-30%", right: "-5%", width: "400px", height: "400px", borderRadius: "50%", background: "rgba(255,255,255,0.03)", animation: "float 8s ease-in-out infinite" }} />
      </div>
      <div ref={sectionRef} className="container reveal" style={{
        padding: "var(--space-4xl) var(--space-lg)",
        position: "relative",
        zIndex: 2,
        maxWidth: "600px",
      }}>
        <p style={{ color: "rgba(255,255,255,0.7)", fontSize: "0.85rem", fontWeight: 600, letterSpacing: "0.15em", textTransform: "uppercase", marginBottom: "var(--space-md)" }}>
          Ưu đãi đặc biệt
        </p>
        <h2 style={{ fontSize: "clamp(2rem, 4vw, 3rem)", fontWeight: 800, color: "var(--color-white)", lineHeight: 1.15, marginBottom: "var(--space-md)" }}>
          Giảm đến <span style={{ color: "#fbbf24" }}>50%</span><br />Bộ sưu tập mùa mới
        </h2>
        <p style={{ color: "rgba(255,255,255,0.7)", fontSize: "1rem", lineHeight: 1.7, marginBottom: "var(--space-xl)" }}>
          Nhanh tay sở hữu những item hot nhất mùa này.
        </p>
        <Link href="/sale" className="btn" style={{
          background: "var(--color-white)",
          color: "var(--color-primary)",
          padding: "1rem 2.5rem",
          fontWeight: 700,
          borderRadius: "var(--radius-md)",
        }}>
          Mua Ngay →
        </Link>
      </div>
    </section>
  );
}

/* ─── Brands Marquee ─── */
function BrandsSection({ brands }: { brands: Brand[] }) {
  const titleRef = useReveal("up");
  if (brands.length === 0) return null;

  // Double brands for seamless loop
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
      {/* Seamless infinite marquee */}
      <div style={{ overflow: "hidden", padding: "var(--space-lg) 0" }}>
        <div className="marquee-track">
          {doubled.map((brand, i) => (
            <div
              key={`${brand.id}-${i}`}
              style={{
                flexShrink: 0,
                width: "180px",
                height: "88px",
                borderRadius: "var(--radius-lg)",
                border: "1px solid var(--border-color)",
                background: "var(--bg-card)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                padding: "var(--space-md) var(--space-lg)",
                marginRight: "var(--space-lg)",
                transition: "all 0.3s ease",
                cursor: "pointer",
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = "var(--color-accent)";
                e.currentTarget.style.transform = "translateY(-3px) scale(1.05)";
                e.currentTarget.style.boxShadow = "0 8px 24px rgba(139,92,246,0.12)";
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = "var(--border-color)";
                e.currentTarget.style.transform = "translateY(0) scale(1)";
                e.currentTarget.style.boxShadow = "none";
              }}
              title={brand.name}
            >
              {brand.logo ? (
                <Image src={brand.logo} alt={brand.name} width={120} height={44} style={{ objectFit: "contain", maxHeight: "44px" }} />
              ) : (
                <span style={{ fontSize: "0.9rem", fontWeight: 700, color: "var(--text-secondary)", letterSpacing: "0.08em", textTransform: "uppercase" }}>
                  {brand.name}
                </span>
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
        <div
          style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "var(--space-xl)" }}
          className="usp-grid"
        >
          {USP_ITEMS.map((item, i) => {
            const ItemWrapper = ({ children }: { children: React.ReactNode }) => {
              const itemRef = useReveal("scale", { threshold: 0.1, delay: i * 0.12 });
              return <div ref={itemRef}>{children}</div>;
            };
            return (
              <ItemWrapper key={item.title}>
                <div
                  style={{
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    textAlign: "center",
                    padding: "var(--space-2xl) var(--space-xl)",
                    borderRadius: "var(--radius-xl)",
                    border: "1px solid var(--border-color)",
                    background: "var(--bg-card)",
                    transition: "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = "rgba(139,92,246,0.3)";
                    e.currentTarget.style.transform = "translateY(-6px)";
                    e.currentTarget.style.boxShadow = "0 12px 32px rgba(0,0,0,0.2), 0 0 16px rgba(139,92,246,0.08)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = "var(--border-color)";
                    e.currentTarget.style.transform = "translateY(0)";
                    e.currentTarget.style.boxShadow = "none";
                  }}
                >
                  <div style={{
                    width: "60px",
                    height: "60px",
                    borderRadius: "var(--radius-lg)",
                    background: "rgba(139, 92, 246, 0.1)",
                    color: "var(--color-accent)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    marginBottom: "var(--space-lg)",
                    transition: "transform 0.3s ease",
                  }}>
                    {item.icon}
                  </div>
                  <h4 style={{ fontSize: "0.95rem", fontWeight: 600, color: "var(--text-primary)", marginBottom: "var(--space-sm)" }}>
                    {item.title}
                  </h4>
                  <p style={{ fontSize: "0.85rem", color: "var(--text-muted)", lineHeight: 1.6 }}>
                    {item.desc}
                  </p>
                </div>
              </ItemWrapper>
            );
          })}
        </div>
      </div>
    </section>
  );
}



/* ================ PAGE ================ */

export default function Home() {
  const [featured, setFeatured] = useState<Product[]>([]);
  const [newArrivals, setNewArrivals] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [banners, setBanners] = useState<Banner[]>([]);
  const [flashSale, setFlashSale] = useState<Promotion | null>(null);
  const [brands, setBrands] = useState<Brand[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchData = useCallback(async () => {
    try {
      const [feat, arrivals, cats, bannerList, sale, brandList] = await Promise.all([
        getFeaturedProducts(8),
        getNewArrivals(8),
        getParentCategories(),
        getHeroBanners(),
        getFlashSale(),
        getBrands(),
      ]);
      setFeatured(feat);
      setNewArrivals(arrivals);
      setCategories(cats);
      setBanners(bannerList);
      setFlashSale(sale);
      setBrands(brandList);
    } catch (err) {
      console.error("Failed to fetch data:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    window.history.scrollRestoration = "manual";
    window.scrollTo(0, 0);
    fetchData();
  }, [fetchData]);

  return (
    <>
      <HeroSection banners={banners} />
      <StatsBar />
      <CategoriesSection categories={categories} />
      <ProductsSection title="Sản Phẩm Nổi Bật" subtitle="Được yêu thích nhất tuần này" products={featured} loading={loading} />
      {flashSale ? <FlashSaleBanner promotion={flashSale} /> : <StaticPromoBanner />}
      <ProductsSection title="Hàng Mới Về" subtitle="Cập nhật xu hướng mới nhất" products={newArrivals} loading={loading} />
      <BrandsSection brands={brands} />
      <WhyChooseUs />


      {/* Styles for hover image swap + actions */}
      <style jsx global>{`
        .product-card:hover .product-img-primary { opacity: 0 !important; }
        .product-card:hover .product-img-secondary { opacity: 1 !important; }
        .product-card:hover .product-actions { opacity: 1 !important; transform: translateX(0) !important; }
        .product-card:hover .product-img-wrap img { transform: scale(1.06); }

        @media (max-width: 1024px) {
          .products-grid { grid-template-columns: repeat(3, 1fr) !important; }
          .usp-grid { grid-template-columns: repeat(2, 1fr) !important; }
          .categories-grid { grid-template-columns: repeat(2, 1fr) !important; }
        }
        @media (max-width: 768px) {
          .categories-grid { grid-template-columns: 1fr !important; }
          .products-grid { grid-template-columns: repeat(2, 1fr) !important; gap: var(--space-md) !important; }
          .usp-grid { grid-template-columns: 1fr !important; }
          .section { padding: var(--space-2xl) 0 !important; }
        }
      `}</style>
    </>
  );
}
