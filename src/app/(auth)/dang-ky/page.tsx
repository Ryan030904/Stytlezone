"use client";

import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { registerWithEmail } from "@/lib/auth";
import { toast } from "sonner";
import { AuthLayout, InputField, SubmitButton, GoogleButton, Divider, PasswordToggle } from "@/components/auth/AuthShared";

function getErrorMessage(code: string): string {
    switch (code) {
        case "auth/email-already-in-use":
            return "Email này đã được đăng ký. Vui lòng đăng nhập.";
        case "auth/invalid-email":
            return "Email không hợp lệ.";
        case "auth/weak-password":
            return "Mật khẩu phải có ít nhất 6 ký tự.";
        case "auth/operation-not-allowed":
            return "Đăng ký bằng email chưa được bật.";
        default:
            return "Đăng ký thất bại. Vui lòng thử lại.";
    }
}

export default function RegisterPage() {
    const [fullName, setFullName] = useState("");
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [showPassword, setShowPassword] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [success, setSuccess] = useState(false);
    const router = useRouter();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError("");

        if (!fullName.trim()) {
            setError("Vui lòng nhập họ và tên.");
            return;
        }
        if (!email.trim()) {
            setError("Vui lòng nhập email.");
            return;
        }
        if (password.length < 6) {
            setError("Mật khẩu phải có ít nhất 6 ký tự.");
            return;
        }
        if (password !== confirmPassword) {
            setError("Mật khẩu xác nhận không khớp.");
            return;
        }

        try {
            setLoading(true);
            await registerWithEmail(email, password, fullName.trim());
            toast.success("Tạo tài khoản thành công! 🎉");
            setSuccess(true);
            // Redirect to home after 2s
            setTimeout(() => router.push("/"), 2000);
        } catch (err: unknown) {
            const firebaseErr = err as { code?: string };
            setError(getErrorMessage(firebaseErr.code || ""));
        } finally {
            setLoading(false);
        }
    };

    const clearError = () => setError("");

    return (
        <AuthLayout imageAlt="StyleZone Register">
            <h1 style={{ fontSize: "1.35rem", fontWeight: 700, marginBottom: "2px", color: "#111827" }}>Tạo Tài Khoản</h1>
            <p style={{ fontSize: "0.82rem", color: "#6b7280", marginBottom: "1rem" }}>Đăng ký để khám phá thời trang StyleZone.</p>

            {success && (
                <div style={{
                    padding: "12px 14px",
                    borderRadius: "var(--radius-md)",
                    background: "rgba(34,197,94,0.08)",
                    border: "1px solid rgba(34,197,94,0.3)",
                    color: "#16a34a",
                    fontSize: "0.82rem",
                    marginBottom: "0.8rem",
                    display: "flex",
                    alignItems: "center",
                    gap: "8px",
                }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                        <polyline points="20 6 9 17 4 12" />
                    </svg>
                    Tạo tài khoản thành công! Đang chuyển hướng...
                </div>
            )}

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
                <InputField label="Họ và tên" placeholder="Nguyễn Văn A" value={fullName} onChange={(v) => { setFullName(v); clearError(); }} autoComplete="name" />
                <InputField label="Email" type="email" placeholder="you@example.com" value={email} onChange={(v) => { setEmail(v); clearError(); }} autoComplete="email" />
                <div style={{ position: "relative" }}>
                    <InputField label="Mật khẩu" type={showPassword ? "text" : "password"} placeholder="Tối thiểu 6 ký tự" value={password} onChange={(v) => { setPassword(v); clearError(); }} autoComplete="new-password" />
                    <PasswordToggle show={showPassword} onToggle={() => setShowPassword(!showPassword)} />
                </div>
                <InputField label="Xác nhận mật khẩu" type={showPassword ? "text" : "password"} placeholder="Nhập lại mật khẩu" value={confirmPassword} onChange={(v) => { setConfirmPassword(v); clearError(); }} autoComplete="new-password" />
                <div style={{ marginTop: "0.3rem" }} />
                <SubmitButton loading={loading}>{success ? "Đã đăng ký ✓" : "Đăng Ký"}</SubmitButton>
            </form>

            <Divider />
            <GoogleButton label="Đăng ký với Google" />

            <p style={{ textAlign: "center", marginTop: "0.8rem", fontSize: "0.8rem", color: "#6b7280" }}>
                Đã có tài khoản?{" "}
                <Link href="/dang-nhap" style={{ color: "var(--color-accent)", fontWeight: 600 }}>Đăng nhập</Link>
            </p>
        </AuthLayout>
    );
}
