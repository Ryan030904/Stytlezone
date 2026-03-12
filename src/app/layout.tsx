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

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi" data-scroll-behavior="smooth" suppressHydrationWarning>
      <body className={`${inter.variable} antialiased`} suppressHydrationWarning>
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

