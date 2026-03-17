"use client";

import { usePathname } from "next/navigation";
import { useEffect, useState, useRef } from "react";

const MIN_DISPLAY_MS = 1200; // Minimum time to show loader (enough to see dots animation)

export default function NavigationLoader() {
    const pathname = usePathname();
    const [isLoading, setIsLoading] = useState(false);
    const showTimeRef = useRef<number>(0);
    const [dots, setDots] = useState("");

    // Hide the initial page loader when page is fully loaded
    useEffect(() => {
        const loader = document.getElementById("initial-loader");
        if (!loader) return;

        const MIN_DISPLAY = 800; // minimum ms to show loader
        const startTime = Date.now();

        const hideLoader = () => {
            const elapsed = Date.now() - startTime;
            const remaining = Math.max(0, MIN_DISPLAY - elapsed);

            setTimeout(() => {
                loader.style.opacity = "0";
                loader.style.pointerEvents = "none";
                setTimeout(() => {
                    loader.style.display = "none";
                    document.documentElement.style.background = "";
                }, 400);
            }, remaining);
        };

        // Wait for full page load (images, fonts, etc.)
        if (document.readyState === "complete") {
            hideLoader();
        } else {
            window.addEventListener("load", hideLoader, { once: true });
        }

        return () => window.removeEventListener("load", hideLoader);
    }, []);

    // Animate dots: . → .. → ... → (repeat)
    useEffect(() => {
        if (!isLoading) return;
        const timer = setInterval(() => {
            setDots((prev) => (prev.length >= 3 ? "" : prev + "."));
        }, 350);
        return () => clearInterval(timer);
    }, [isLoading]);

    // When pathname changes, wait minimum display time then hide
    useEffect(() => {
        if (!isLoading) return;
        const elapsed = Date.now() - showTimeRef.current;
        const remaining = Math.max(0, MIN_DISPLAY_MS - elapsed);

        const timer = setTimeout(() => {
            setIsLoading(false);
            setDots("");
        }, remaining);

        return () => clearTimeout(timer);
    }, [pathname]); // eslint-disable-line react-hooks/exhaustive-deps

    // Intercept all link clicks
    useEffect(() => {
        const handleClick = (e: MouseEvent) => {
            const anchor = (e.target as HTMLElement).closest("a");
            if (!anchor) return;

            const href = anchor.getAttribute("href");
            if (!href) return;

            // Skip external links, hash links, same page, new tab
            if (
                href.startsWith("http") ||
                href.startsWith("#") ||
                href === pathname ||
                anchor.target === "_blank"
            ) {
                return;
            }

            showTimeRef.current = Date.now();
            setIsLoading(true);
        };

        document.addEventListener("click", handleClick, true);
        return () => document.removeEventListener("click", handleClick, true);
    }, [pathname]);

    if (!isLoading) return null;

    return (
        <div
            style={{
                position: "fixed",
                inset: 0,
                zIndex: 99999,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                gap: "24px",
                background: "var(--bg-primary, #ffffff)",
            }}
        >
            {/* Background glow */}
            <div
                style={{
                    position: "absolute",
                    width: "160px",
                    height: "160px",
                    borderRadius: "50%",
                    background: "radial-gradient(circle, rgba(139,92,246,0.08) 0%, transparent 70%)",
                    animation: "loader-pulse 2s ease-in-out infinite",
                }}
            />

            {/* Spinner container */}
            <div style={{ position: "relative", width: "60px", height: "60px", display: "flex", alignItems: "center", justifyContent: "center" }}>
                {/* Outer ring (static) */}
                <div
                    style={{
                        position: "absolute",
                        width: "60px",
                        height: "60px",
                        borderRadius: "50%",
                        border: "2px solid rgba(139,92,246,0.1)",
                    }}
                />

                {/* Spinning ring */}
                <div
                    style={{
                        width: "60px",
                        height: "60px",
                        borderRadius: "50%",
                        border: "2.5px solid transparent",
                        borderTopColor: "#8B5CF6",
                        borderRightColor: "rgba(139,92,246,0.25)",
                        animation: "loader-spin 0.7s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite",
                        filter: "drop-shadow(0 0 8px rgba(139,92,246,0.3))",
                    }}
                />

                {/* Center dot */}
                <div
                    style={{
                        position: "absolute",
                        width: "6px",
                        height: "6px",
                        borderRadius: "50%",
                        background: "#8B5CF6",
                        boxShadow: "0 0 12px rgba(139,92,246,0.5)",
                        animation: "loader-pulse 1.4s ease-in-out infinite",
                    }}
                />
            </div>

            {/* Loading text with animated dots */}
            <div
                style={{
                    fontSize: "0.9rem",
                    fontWeight: 700,
                    letterSpacing: "0.15em",
                    textTransform: "uppercase" as const,
                    color: "#8B5CF6",
                    fontFamily: "var(--font-sans, Inter, sans-serif)",
                    minWidth: "110px",
                    textAlign: "center",
                }}
            >
                Loading{dots}
            </div>

            <style>{`
                @keyframes loader-spin {
                    to { transform: rotate(360deg); }
                }
                @keyframes loader-pulse {
                    0%, 100% { opacity: 0.4; transform: scale(0.95); }
                    50% { opacity: 1; transform: scale(1.05); }
                }
            `}</style>
        </div>
    );
}
