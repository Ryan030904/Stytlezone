import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "StyleZone — Tài Khoản",
    description: "Đăng nhập hoặc đăng ký tài khoản StyleZone",
};

export default function AuthLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return <>{children}</>;
}
