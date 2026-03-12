"use client";

import Link from "next/link";
import { useState } from "react";
import { AuthLayout, InputField, SubmitButton } from "@/components/auth/AuthShared";

export default function ForgotPasswordPage() {
    const [email, setEmail] = useState("");
    const [submitted, setSubmitted] = useState(false);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitted(true);
    };

    return (
        <AuthLayout imageAlt="StyleZone Forgot Password">
            {/* Lock icon */}
            <div style={{ textAlign: "center", marginBottom: "1.2rem" }}>
                <div style={{ width: "56px", height: "56px", borderRadius: "50%", background: "rgba(139,92,246,0.10)", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto" }}>
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                        <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                    </svg>
                </div>
            </div>

            <h1 style={{ fontSize: "1.35rem", fontWeight: 700, marginBottom: "6px", color: "#111827", textAlign: "center" }}>Quên Mật Khẩu</h1>
            <p style={{ fontSize: "0.82rem", color: "#6b7280", marginBottom: "1.8rem", textAlign: "center", lineHeight: 1.5 }}>Nhập email đã đăng ký để nhận liên kết đặt lại mật khẩu của bạn.</p>

            {submitted ? (
                <div style={{ textAlign: "center" }}>
                    <div style={{ width: "56px", height: "56px", borderRadius: "50%", background: "rgba(34,197,94,0.12)", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 1rem" }}>
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></svg>
                    </div>
                    <h2 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#111827", marginBottom: "0.5rem" }}>Email đã được gửi!</h2>
                    <p style={{ fontSize: "0.82rem", color: "#6b7280", marginBottom: "1.5rem", lineHeight: 1.6 }}>
                        Liên kết đặt lại đã gửi đến <strong style={{ color: "var(--color-accent)" }}>{email}</strong>. Vui lòng kiểm tra hộp thư.
                    </p>
                    <Link href="/dang-nhap" style={{ display: "inline-flex", alignItems: "center", gap: "6px", padding: "0.65rem 1.4rem", borderRadius: "var(--radius-md)", background: "var(--color-accent)", color: "#fff", fontWeight: 600, fontSize: "0.85rem" }}>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M19 12H5" /><path d="M12 19l-7-7 7-7" /></svg>
                        Quay lại đăng nhập
                    </Link>
                </div>
            ) : (
                <>
                    <form onSubmit={handleSubmit}>
                        <InputField label="Email" type="email" placeholder="you@example.com" value={email} onChange={setEmail} autoComplete="email" />
                        <div style={{ marginTop: "1rem" }} />
                        <SubmitButton>Gửi Liên Kết Đặt Lại</SubmitButton>
                    </form>
                    <p style={{ textAlign: "center", marginTop: "1.5rem", fontSize: "0.8rem", color: "#6b7280" }}>
                        Nhớ mật khẩu?{" "}
                        <Link href="/dang-nhap" style={{ color: "var(--color-accent)", fontWeight: 600 }}>Đăng nhập</Link>
                    </p>
                </>
            )}
        </AuthLayout>
    );
}
