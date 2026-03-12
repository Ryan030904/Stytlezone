"use client";

import Link from "next/link";
import { useState, useEffect } from "react";

export default function NotFound() {
    const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    const handleMouseMove = (e: React.MouseEvent) => {
        const { clientX, clientY } = e;
        const { innerWidth, innerHeight } = window;
        setMousePos({
            x: (clientX / innerWidth - 0.5) * 15,
            y: (clientY / innerHeight - 0.5) * 15,
        });
    };

    if (!mounted) return null;

    return (
        <section
            onMouseMove={handleMouseMove}
            style={{
                minHeight: "100vh",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                position: "relative",
                overflow: "hidden",
                background: "var(--bg-primary)",
            }}
        >
            {/* Floating orbs */}
            <div
                style={{
                    position: "absolute",
                    top: "15%",
                    left: "10%",
                    width: "300px",
                    height: "300px",
                    borderRadius: "50%",
                    background: "radial-gradient(circle, rgba(139,92,246,0.12) 0%, transparent 70%)",
                    animation: "float 6s ease-in-out infinite",
                    pointerEvents: "none",
                    transform: `translate(${mousePos.x * 0.5}px, ${mousePos.y * 0.5}px)`,
                    transition: "transform 0.3s ease-out",
                }}
            />
            <div
                style={{
                    position: "absolute",
                    bottom: "10%",
                    right: "15%",
                    width: "220px",
                    height: "220px",
                    borderRadius: "50%",
                    background: "radial-gradient(circle, rgba(139,92,246,0.08) 0%, transparent 70%)",
                    animation: "float 8s ease-in-out infinite reverse",
                    pointerEvents: "none",
                    transform: `translate(${mousePos.x * -0.3}px, ${mousePos.y * -0.3}px)`,
                    transition: "transform 0.3s ease-out",
                }}
            />
            <div
                style={{
                    position: "absolute",
                    top: "50%",
                    left: "50%",
                    width: "600px",
                    height: "600px",
                    borderRadius: "50%",
                    border: "1px solid rgba(139,92,246,0.05)",
                    animation: "rotate-slow 80s linear infinite",
                    pointerEvents: "none",
                    transform: "translate(-50%, -50%)",
                }}
            />

            {/* Content */}
            <div
                style={{
                    position: "relative",
                    zIndex: 2,
                    textAlign: "center",
                    padding: "var(--space-xl)",
                    maxWidth: "540px",
                }}
            >
                {/* 404 Number */}
                <div
                    className="animate-fade-in"
                    style={{
                        fontSize: "clamp(7rem, 18vw, 12rem)",
                        fontWeight: 900,
                        lineHeight: 1,
                        letterSpacing: "-0.06em",
                        background: "linear-gradient(135deg, var(--color-accent) 0%, #a78bfa 40%, #c084fc 70%, rgba(139,92,246,0.3) 100%)",
                        backgroundClip: "text",
                        WebkitBackgroundClip: "text",
                        WebkitTextFillColor: "transparent",
                        marginBottom: "var(--space-md)",
                        userSelect: "none",
                    }}
                >
                    404
                </div>

                {/* Title */}
                <h1
                    className="animate-slide-up stagger-1"
                    style={{
                        fontSize: "clamp(1.4rem, 3vw, 2rem)",
                        fontWeight: 700,
                        color: "var(--text-primary)",
                        marginBottom: "var(--space-md)",
                        letterSpacing: "-0.02em",
                    }}
                >
                    Trang không tồn tại
                </h1>

                {/* Description */}
                <p
                    className="animate-slide-up stagger-2"
                    style={{
                        color: "var(--text-muted)",
                        fontSize: "1rem",
                        lineHeight: 1.7,
                        marginBottom: "var(--space-2xl)",
                        maxWidth: "400px",
                        margin: "0 auto var(--space-2xl)",
                    }}
                >
                    Xin lỗi, trang bạn đang tìm kiếm không tồn tại hoặc đã bị di chuyển.
                </p>

                {/* Buttons */}
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
                        href="/"
                        className="btn btn-primary"
                        style={{
                            padding: "0.85rem 2rem",
                            fontSize: "0.9rem",
                            display: "inline-flex",
                            alignItems: "center",
                            gap: "var(--space-sm)",
                        }}
                    >
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                            <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                            <polyline points="9 22 9 12 15 12 15 22" />
                        </svg>
                        Về Trang Chủ
                    </Link>
                    <Link
                        href="/bo-suu-tap"
                        className="btn btn-outline"
                        style={{
                            padding: "0.85rem 2rem",
                            fontSize: "0.9rem",
                        }}
                    >
                        Khám Phá Sản Phẩm
                    </Link>
                </div>
            </div>
        </section>
    );
}
