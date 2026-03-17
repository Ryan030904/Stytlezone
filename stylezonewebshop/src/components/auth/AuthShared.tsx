"use client";

import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { signInWithGoogle } from "@/lib/auth";
import { toast } from "sonner";

export function AuthLayout({ children }: { children: React.ReactNode }) {
    return (
        <div style={{ display: "flex", minHeight: "100vh", overflow: "hidden" }}>
            {/* Left 60% — Video Background */}
            <div className="auth-bg-panel" style={{ flex: "0 0 60%", position: "relative", overflow: "hidden", background: "#0a0a0a" }}>
                {/* Video */}
                <video
                    autoPlay
                    muted
                    loop
                    playsInline
                    style={{
                        position: "absolute",
                        inset: 0,
                        width: "100%",
                        height: "100%",
                        objectFit: "cover",
                    }}
                >
                    <source src="/videos/auth-bg.mp4" type="video/mp4" />
                </video>

                {/* Dark overlay for readability */}
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(180deg, rgba(0,0,0,0.3) 0%, rgba(0,0,0,0.1) 40%, rgba(0,0,0,0.5) 100%)" }} />
                <div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse at 40% 50%, rgba(139,92,246,0.10), transparent 65%)" }} />

                {/* ← Trang chủ */}
                <Link href="/" style={{ position: "absolute", top: "var(--space-lg)", left: "var(--space-lg)", display: "flex", alignItems: "center", gap: "6px", color: "rgba(255,255,255,0.7)", fontSize: "0.8rem", fontWeight: 500, padding: "8px 16px", borderRadius: "var(--radius-full)", border: "1px solid rgba(255,255,255,0.12)", background: "rgba(0,0,0,0.3)", backdropFilter: "blur(8px)", transition: "all 0.2s ease", zIndex: 10, textDecoration: "none" }}
                    onMouseEnter={(e) => { e.currentTarget.style.color = "#fff"; e.currentTarget.style.borderColor = "rgba(139,92,246,0.5)"; e.currentTarget.style.background = "rgba(139,92,246,0.2)"; }}
                    onMouseLeave={(e) => { e.currentTarget.style.color = "rgba(255,255,255,0.7)"; e.currentTarget.style.borderColor = "rgba(255,255,255,0.12)"; e.currentTarget.style.background = "rgba(0,0,0,0.3)"; }}
                >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M19 12H5" /><path d="M12 19l-7-7 7-7" /></svg>
                    Trang chủ
                </Link>



            </div>

            {/* Right 40% — White form panel */}
            <div className="auth-form-panel" style={{ flex: "0 0 40%", display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", padding: "1.5rem 2.5rem", background: "#fff", position: "relative", overflowY: "auto" }}>
                <div style={{ width: "100%", maxWidth: "360px" }}>
                    {children}
                </div>
            </div>

            <style jsx global>{`
                @media (max-width: 768px) {
                    .auth-bg-panel { display: none !important; }
                    .auth-form-panel { flex: 1 1 100% !important; }
                }
            `}</style>
            <style jsx global>{`
                ::selection {
                    background: rgba(124, 58, 237, 0.35);
                    color: #1a1a2e;
                }
                ::-moz-selection {
                    background: rgba(124, 58, 237, 0.35);
                    color: #1a1a2e;
                }
            `}</style>
        </div>
    );
}



export function InputField({ label, type = "text", placeholder, value, onChange, autoComplete }: { label: string; type?: string; placeholder: string; value: string; onChange: (v: string) => void; autoComplete?: string }) {
    const [focused, setFocused] = useState(false);
    return (
        <div style={{ marginBottom: "0.5rem" }}>
            <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "#374151", marginBottom: "4px", letterSpacing: "0.03em" }}>{label}</label>
            <input type={type} placeholder={placeholder} value={value} onChange={(e) => onChange(e.target.value)} autoComplete={autoComplete} onFocus={() => setFocused(true)} onBlur={() => setFocused(false)}
                style={{ width: "100%", padding: "0.5rem 0.8rem", borderRadius: "var(--radius-md)", background: "#f9fafb", border: `1.5px solid ${focused ? "#7C3AED" : "#e5e7eb"}`, color: "#111827", fontSize: "0.83rem", transition: "border-color 0.2s, box-shadow 0.2s", boxShadow: focused ? "0 0 0 3px rgba(124,58,237,0.25)" : "none", outline: "none" }}
            />
        </div>
    );
}

export function SubmitButton({ children, loading = false }: { children: React.ReactNode; loading?: boolean }) {
    return (
        <button type="submit" disabled={loading} style={{ width: "100%", padding: "0.55rem", borderRadius: "var(--radius-md)", background: loading ? "#a78bfa" : "var(--color-accent)", color: "#fff", fontWeight: 700, fontSize: "0.85rem", letterSpacing: "0.03em", transition: "all 0.25s ease", cursor: loading ? "not-allowed" : "pointer", border: "none", opacity: loading ? 0.8 : 1 }}
            onMouseEnter={(e) => { if (!loading) { e.currentTarget.style.background = "var(--color-accent-hover)"; e.currentTarget.style.boxShadow = "var(--shadow-glow)"; e.currentTarget.style.transform = "translateY(-1px)"; } }}
            onMouseLeave={(e) => { e.currentTarget.style.background = loading ? "#a78bfa" : "var(--color-accent)"; e.currentTarget.style.boxShadow = "none"; e.currentTarget.style.transform = "translateY(0)"; }}
        >{loading ? "Đang xử lý..." : children}</button>
    );
}

export function GoogleButton({ label = "Đăng nhập với Google", redirectUrl = "/" }: { label?: string; redirectUrl?: string }) {
    const [loading, setLoading] = useState(false);
    const [showOverlay, setShowOverlay] = useState(false);
    const router = useRouter();

    const handleGoogleSignIn = async () => {
        try {
            setLoading(true);
            await signInWithGoogle();
            setShowOverlay(true);
            setTimeout(() => {
                router.push(redirectUrl);
                setTimeout(() => setShowOverlay(false), 500);
            }, 1200);
        } catch (error: unknown) {
            // User closed popup or other error
            const firebaseError = error as { code?: string };
            if (firebaseError.code !== "auth/popup-closed-by-user") {
                toast.error("Đăng nhập thất bại. Vui lòng thử lại.");
            }
            setLoading(false);
        }
    };

    return (
        <>
            {/* Login Loading Overlay */}
            <div style={{
                position: "fixed", inset: 0, zIndex: 99999,
                background: "linear-gradient(135deg, #0f0720 0%, #1a103f 40%, #2d1b69 70%, #1a103f 100%)",
                display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
                opacity: showOverlay ? 1 : 0, pointerEvents: showOverlay ? "all" : "none",
                transition: "opacity 0.4s ease",
            }}>
                <style>{`@keyframes authSpin { to { transform: rotate(360deg); } }`}</style>
                <div style={{ width: "44px", height: "44px", borderRadius: "50%", border: "3px solid rgba(255,255,255,0.15)", borderTopColor: "#8B5CF6", animation: "authSpin 0.8s linear infinite", marginBottom: "24px" }} />
                <p style={{ color: "rgba(255,255,255,0.7)", fontSize: "0.9rem", fontWeight: 500 }}>Đang đăng nhập...</p>
            </div>
            <button type="button" onClick={handleGoogleSignIn} disabled={loading} style={{ width: "100%", padding: "0.6rem", borderRadius: "var(--radius-md)", background: "#fff", border: "1.5px solid #e5e7eb", color: "#374151", fontWeight: 600, fontSize: "0.83rem", display: "flex", alignItems: "center", justifyContent: "center", gap: "var(--space-sm)", cursor: loading ? "not-allowed" : "pointer", transition: "all 0.25s ease", opacity: loading ? 0.7 : 1 }}
                onMouseEnter={(e) => { if (!loading) { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.transform = "translateY(-1px)"; } }}
                onMouseLeave={(e) => { e.currentTarget.style.borderColor = "#e5e7eb"; e.currentTarget.style.transform = "translateY(0)"; }}
            >
                {loading ? (
                    <span>Đang xử lý...</span>
                ) : (
                    <>
                        <svg width="16" height="16" viewBox="0 0 24 24"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4" /><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" /><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" /><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" /></svg>
                        {label}
                    </>
                )}
            </button>
        </>
    );
}

export function Divider() {
    return (
        <div style={{ display: "flex", alignItems: "center", gap: "var(--space-sm)", margin: "0.5rem 0" }}>
            <div style={{ flex: 1, height: "1px", background: "#e5e7eb" }} />
            <span style={{ fontSize: "0.72rem", color: "#9ca3af", fontWeight: 500 }}>hoặc</span>
            <div style={{ flex: 1, height: "1px", background: "#e5e7eb" }} />
        </div>
    );
}

export function PasswordToggle({ show, onToggle }: { show: boolean; onToggle: () => void }) {
    return (
        <button type="button" onClick={onToggle} style={{ position: "absolute", right: "12px", bottom: "10px", color: "#9ca3af", padding: "2px", transition: "color 0.2s", lineHeight: 0, background: "transparent", border: "none", cursor: "pointer" }}
            onMouseEnter={(e) => (e.currentTarget.style.color = "#374151")}
            onMouseLeave={(e) => (e.currentTarget.style.color = "#9ca3af")}
        >
            {show ? (
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" /><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" /><line x1="1" y1="1" x2="23" y2="23" /></svg>
            ) : (
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>
            )}
        </button>
    );
}
