"use client";

import { usePathname } from "next/navigation";
import Header from "@/components/layout/Header";
import Footer from "@/components/layout/Footer";

const AUTH_ROUTES = ["/dang-nhap", "/dang-ky", "/quen-mat-khau"];
const MINIMAL_FOOTER_ROUTES = ["/thanh-toan", "/yeu-thich", "/gio-hang"];

export default function LayoutWrapper({ children }: { children: React.ReactNode }) {
    const pathname = usePathname();
    const isAuthPage = AUTH_ROUTES.some((route) => pathname.startsWith(route));

    if (isAuthPage) {
        return <>{children}</>;
    }

    const isMinimalFooter = MINIMAL_FOOTER_ROUTES.some((route) => pathname.startsWith(route));

    return (
        <>
            <Header />
            <main>{children}</main>
            {isMinimalFooter ? (
                <footer style={{
                    padding: "var(--space-lg) 0",
                    textAlign: "center",
                    borderTop: "1px solid var(--border-color)",
                    background: "var(--bg-primary)",
                }}>
                    <p style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>© 2026 StyleZone. All rights reserved.</p>
                </footer>
            ) : (
                <Footer />
            )}
        </>
    );
}
