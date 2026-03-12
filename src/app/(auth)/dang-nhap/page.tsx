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
            toast.success("Đăng nhập thành công! 🎉");
            router.push(redirectUrl);
        } catch (err: unknown) {
            const firebaseErr = err as { code?: string };
            setError(getErrorMessage(firebaseErr.code || ""));
        } finally {
            setLoading(false);
        }
    };

    return (
        <AuthLayout imageAlt="StyleZone Login">
            <h1 style={{ fontSize: "1.35rem", fontWeight: 700, marginBottom: "2px", color: "#111827" }}>Đăng Nhập</h1>
            <p style={{ fontSize: "0.82rem", color: "#6b7280", marginBottom: "1.2rem" }}>Chào mừng trở lại! Đăng nhập để tiếp tục mua sắm.</p>

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
    );
}
