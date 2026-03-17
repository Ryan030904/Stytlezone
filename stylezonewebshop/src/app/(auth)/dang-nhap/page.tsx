"use client";

import Link from "next/link";
import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { signInWithEmail } from "@/lib/auth";
import { toast } from "sonner";
import { AuthLayout, InputField, SubmitButton, GoogleButton, Divider, PasswordToggle } from "@/components/auth/AuthShared";

function getErrorMessage(code: string): string {
    switch (code) {
        case "auth/user-not-found":
        case "auth/invalid-credential":
            return "Email hoặc mật khẩu không đúng.";
        case "auth/wrong-password":
            return "Mật khẩu không đúng.";
        case "auth/invalid-email":
            return "Email không hợp lệ.";
        case "auth/user-disabled":
            return "Tài khoản đã bị vô hiệu hóa.";
        case "auth/too-many-requests":
            return "Quá nhiều lần thử. Vui lòng thử lại sau.";
        default:
            return "Đăng nhập thất bại. Vui lòng thử lại.";
    }
}

export default function LoginPage() {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [showPassword, setShowPassword] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [showOverlay, setShowOverlay] = useState(false);
    const router = useRouter();
    const searchParams = useSearchParams();
    const redirectUrl = searchParams.get("redirect") || "/";

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError("");

        if (!email.trim() || !password.trim()) {
            setError("Vui lòng nhập email và mật khẩu.");
            return;
        }

        try {
            setLoading(true);
            await signInWithEmail(email, password);
            setShowOverlay(true);
            setTimeout(() => {
                router.push(redirectUrl);
                setTimeout(() => setShowOverlay(false), 500);
            }, 1200);
        } catch (err: unknown) {
            const firebaseErr = err as { code?: string };
            setError(getErrorMessage(firebaseErr.code || ""));
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
                <div style={{ marginBottom: "32px" }}>
                    <span style={{ fontSize: "2rem", fontWeight: 800, letterSpacing: "0.12em", color: "#fff", textTransform: "uppercase" }}>Style</span>
                    <span style={{ fontSize: "2rem", fontWeight: 800, letterSpacing: "0.12em", color: "#8B5CF6", textTransform: "uppercase" }}>Zone</span>
                </div>
                <div style={{ width: "44px", height: "44px", borderRadius: "50%", border: "3px solid rgba(255,255,255,0.15)", borderTopColor: "#8B5CF6", animation: "authSpin 0.8s linear infinite", marginBottom: "24px" }} />
                <p style={{ color: "rgba(255,255,255,0.7)", fontSize: "0.9rem", fontWeight: 500 }}>Đang đăng nhập...</p>
            </div>

            <AuthLayout>
                <h1 style={{ fontSize: "1.25rem", fontWeight: 700, marginBottom: "2px", color: "#111827" }}>Đăng Nhập</h1>
                <p style={{ fontSize: "0.8rem", color: "#6b7280", marginBottom: "0.8rem" }}>Chào mừng trở lại! Đăng nhập để tiếp tục mua sắm.</p>

                {error && (
                    <div style={{
                        padding: "10px 14px",
                        borderRadius: "var(--radius-md)",
                        background: "rgba(239,68,68,0.08)",
                        border: "1px solid rgba(239,68,68,0.25)",
                        color: "#dc2626",
                        fontSize: "0.82rem",
                        marginBottom: "0.8rem",
                        display: "flex",
                        alignItems: "center",
                        gap: "8px",
                    }}>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                            <circle cx="12" cy="12" r="10" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" />
                        </svg>
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit}>
                    <InputField label="Email" type="email" placeholder="you@example.com" value={email} onChange={(v) => { setEmail(v); setError(""); }} autoComplete="email" />
                    <div style={{ position: "relative" }}>
                        <InputField label="Mật khẩu" type={showPassword ? "text" : "password"} placeholder="••••••••" value={password} onChange={(v) => { setPassword(v); setError(""); }} autoComplete="current-password" />
                        <PasswordToggle show={showPassword} onToggle={() => setShowPassword(!showPassword)} />
                    </div>
                    <div style={{ textAlign: "right", marginBottom: "0.8rem" }}>
                        <Link href="/quen-mat-khau" style={{ fontSize: "0.78rem", color: "var(--color-accent)", fontWeight: 500 }}>Quên mật khẩu?</Link>
                    </div>
                    <SubmitButton loading={loading}>Đăng Nhập</SubmitButton>
                </form>

                <Divider />
                <GoogleButton redirectUrl={redirectUrl} />

                <p style={{ textAlign: "center", marginTop: "0.8rem", fontSize: "0.8rem", color: "#6b7280" }}>
                    Chưa có tài khoản?{" "}
                    <Link href="/dang-ky" style={{ color: "var(--color-accent)", fontWeight: 600 }}>Đăng ký ngay</Link>
                </p>
            </AuthLayout>
        </>
    );
}
