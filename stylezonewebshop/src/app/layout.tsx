import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Toaster } from "sonner";

import ThemeProvider from "@/components/ThemeProvider";
import WishlistProvider from "@/components/WishlistProvider";
import CartProvider from "@/components/CartProvider";
import LayoutWrapper from "@/components/layout/LayoutWrapper";
import NavigationLoader from "@/components/NavigationLoader";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin", "vietnamese"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "StyleZone — Thời Trang Nam Nữ Hiện Đại",
  description:
    "Khám phá bộ sưu tập thời trang nam nữ mới nhất tại StyleZone. Phong cách hiện đại, chất lượng cao, giá tốt nhất.",
  keywords: ["thời trang", "quần áo", "nam", "nữ", "stylezone", "fashion"],
};

/**
 * CSS-only initial loader — embedded in <head> so it renders
 * BEFORE body paint. No JS needed = no white flash.
 * The loader is removed by NavigationLoader once React hydrates.
 */
const LOADER_CSS = `
#initial-loader {
  position: fixed; inset: 0; z-index: 999999;
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 24px;
  background: #ffffff;
  transition: opacity 0.4s ease;
}
#initial-loader .il-ring {
  width: 60px; height: 60px; border-radius: 50%;
  border: 2.5px solid transparent;
  border-top-color: #8B5CF6;
  border-right-color: rgba(139,92,246,0.25);
  animation: il-spin 0.7s cubic-bezier(0.45,0.05,0.55,0.95) infinite;
  filter: drop-shadow(0 0 8px rgba(139,92,246,0.3));
}
#initial-loader .il-dot {
  position: absolute; width: 6px; height: 6px; border-radius: 50%;
  background: #8B5CF6; box-shadow: 0 0 12px rgba(139,92,246,0.5);
}
#initial-loader .il-text {
  font-size: 0.9rem; font-weight: 700; letter-spacing: 0.15em;
  text-transform: uppercase; color: #8B5CF6;
  font-family: Inter, system-ui, sans-serif;
  min-width: 130px; text-align: center;
}
#initial-loader .il-dots::after {
  content: '';
  animation: il-dots 0.9s steps(1) infinite;
}
@keyframes il-spin { to { transform: rotate(360deg); } }
@keyframes il-dots {
  0%   { content: ''; }
  25%  { content: '.'; }
  50%  { content: '..'; }
  75%  { content: '...'; }
}
`;

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi" data-theme="light" data-scroll-behavior="smooth" style={{ background: "#ffffff" }} suppressHydrationWarning>
      <head>
        <style dangerouslySetInnerHTML={{ __html: LOADER_CSS }} />
      </head>
      <body className={`${inter.variable} antialiased`} suppressHydrationWarning>
        {/* Initial loader — server-rendered HTML, visible immediately */}
        <div id="initial-loader" suppressHydrationWarning>
          <div style={{ position: "relative", width: "60px", height: "60px", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <div style={{ position: "absolute", width: "60px", height: "60px", borderRadius: "50%", border: "2px solid rgba(139,92,246,0.1)" }} />
            <div className="il-ring" />
            <div className="il-dot" />
          </div>
          <div className="il-text">Loading<span className="il-dots" /></div>
        </div>

        <NavigationLoader />
        <ThemeProvider>
          <WishlistProvider>
            <CartProvider>
              <LayoutWrapper>{children}</LayoutWrapper>
            </CartProvider>
          </WishlistProvider>
        </ThemeProvider>
        <Toaster
          position="top-right"
          richColors
          visibleToasts={1}
          duration={3000}
          toastOptions={{
            style: {
              fontFamily: "var(--font-inter), Inter, sans-serif",
            },
          }}
        />
      </body>
    </html>
  );
}
