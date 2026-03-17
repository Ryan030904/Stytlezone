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
    const [showOverlay, setShowOverlay] = useState(false);
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
            setShowOverlay(true);
            setTimeout(() => {
                router.push("/tai-khoan");
                setTimeout(() => setShowOverlay(false), 500);
            }, 1500);
        } catch (err: unknown) {
            const firebaseErr = err as { code?: string };
            setError(getErrorMessage(firebaseErr.code || ""));
            setLoading(false);
        }
    };

    const clearError = () => setError("");

    return (
        <>
            {/* Registration Success Loading Overlay */}
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
                <p style={{ color: "#fff", fontSize: "1rem", fontWeight: 600, marginBottom: "8px" }}>Tạo tài khoản thành công! 🎉</p>
                <p style={{ color: "rgba(255,255,255,0.6)", fontSize: "0.85rem", fontWeight: 400 }}>Đang chuyển đến trang thông tin...</p>
            </div>

            <AuthLayout>
                <h1 style={{ fontSize: "1.25rem", fontWeight: 700, marginBottom: "2px", color: "#111827" }}>Tạo Tài Khoản</h1>
                <p style={{ fontSize: "0.8rem", color: "#6b7280", marginBottom: "0.8rem" }}>Đăng ký để khám phá thời trang StyleZone.</p>

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
                    <SubmitButton loading={loading}>Đăng Ký</SubmitButton>
                </form>

                <Divider />
                <GoogleButton label="Đăng ký với Google" />

                <p style={{ textAlign: "center", marginTop: "0.5rem", fontSize: "0.8rem", color: "#6b7280" }}>
                    Đã có tài khoản?{" "}
                    <Link href="/dang-nhap" style={{ color: "var(--color-accent)", fontWeight: 600 }}>Đăng nhập</Link>
                </p>
            </AuthLayout>
        </>
    );
}
