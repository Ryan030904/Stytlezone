"use client";

import { useState, useEffect, useRef, useCallback, useMemo } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter, useSearchParams } from "next/navigation";
import { useCart, type CartItem } from "@/components/CartProvider";
import { createOrder } from "@/lib/orders";
import { type Coupon, fetchActiveCoupons, validateCoupon, markCouponUsed } from "@/lib/coupons";
import { getSavedVouchers, type SavedVoucher } from "@/lib/savedVouchers";
import { toast } from "sonner";

/* ─── Helpers ─── */
function formatPrice(price: number) {
    return new Intl.NumberFormat("vi-VN").format(price) + "đ";
}

function useReveal(direction: "up" | "left" | "right" | "scale" = "up", delay = 0) {
    const ref = useRef<HTMLDivElement>(null);
    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        el.classList.add(`reveal-${direction}`);
        if (delay > 0) el.style.transitionDelay = `${delay}s`;
        const obs = new IntersectionObserver(
            ([entry]) => { if (entry.isIntersecting) { el.classList.add("visible"); obs.unobserve(el); } },
            { threshold: 0.05 }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, [direction, delay]);
    return ref;
}

/* ─── Types ─── */
interface ShippingInfo {
    fullName: string;
    phone: string;
    email: string;
    province: string;
    district: string;
    ward: string;
    address: string;
    note: string;
}

type PaymentMethod = "cod" | "bank" | "momo";

/* ─── VietQR Config ─── */
const VIETQR_BANK_ID = "VCB";
const VIETQR_ACCOUNT = "1035238323";
const VIETQR_ACCOUNT_NAME = "NGUYEN TRONG QUI";

function buildVietQRUrl(amount: number, orderCode: string) {
    const params = new URLSearchParams({
        amount: String(amount),
        addInfo: `Thanh toan don hang ${orderCode}`,
        accountName: VIETQR_ACCOUNT_NAME,
    });
    return `https://img.vietqr.io/image/${VIETQR_BANK_ID}-${VIETQR_ACCOUNT}-compact2.png?${params.toString()}`;
}

const PROVINCES = [
    "Hà Nội", "TP. Hồ Chí Minh", "Đà Nẵng", "Hải Phòng", "Cần Thơ",
    "An Giang", "Bà Rịa - Vũng Tàu", "Bắc Giang", "Bắc Kạn", "Bạc Liêu",
    "Bắc Ninh", "Bến Tre", "Bình Định", "Bình Dương", "Bình Phước",
    "Bình Thuận", "Cà Mau", "Cao Bằng", "Đắk Lắk", "Đắk Nông",
    "Điện Biên", "Đồng Nai", "Đồng Tháp", "Gia Lai", "Hà Giang",
    "Hà Nam", "Hà Tĩnh", "Hải Dương", "Hậu Giang", "Hòa Bình",
    "Hưng Yên", "Khánh Hòa", "Kiên Giang", "Kon Tum", "Lai Châu",
    "Lâm Đồng", "Lạng Sơn", "Lào Cai", "Long An", "Nam Định",
    "Nghệ An", "Ninh Bình", "Ninh Thuận", "Phú Thọ", "Phú Yên",
    "Quảng Bình", "Quảng Nam", "Quảng Ngãi", "Quảng Ninh", "Quảng Trị",
    "Sóc Trăng", "Sơn La", "Tây Ninh", "Thái Bình", "Thái Nguyên",
    "Thanh Hóa", "Thừa Thiên Huế", "Tiền Giang", "Trà Vinh", "Tuyên Quang",
    "Vĩnh Long", "Vĩnh Phúc", "Yên Bái",
];

/* ─── Step Indicator ─── */
function StepIndicator({ current }: { current: number }) {
    const steps = [
        { num: 1, label: "Thông tin" },
        { num: 2, label: "Thanh toán" },
        { num: 3, label: "Xác nhận" },
    ];
    return (
        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "0", marginBottom: "var(--space-xl)" }}>
            {steps.map((step, i) => (
                <div key={step.num} style={{ display: "flex", alignItems: "center" }}>
                    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "4px" }}>
                        <div style={{
                            width: "32px", height: "32px", borderRadius: "50%",
                            display: "flex", alignItems: "center", justifyContent: "center",
                            fontSize: "0.75rem", fontWeight: 700,
                            background: current >= step.num ? "linear-gradient(135deg, var(--color-accent), #6366f1)" : "var(--bg-surface)",
                            color: current >= step.num ? "#fff" : "var(--text-muted)",
                            border: current >= step.num ? "none" : "1.5px solid var(--border-color)",
                            transition: "all 0.3s ease",
                            boxShadow: current >= step.num ? "0 2px 10px rgba(139,92,246,0.25)" : "none",
                        }}>
                            {current > step.num ? (
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><polyline points="20 6 9 17 4 12" /></svg>
                            ) : step.num}
                        </div>
                        <span style={{ fontSize: "0.65rem", fontWeight: 600, color: current >= step.num ? "var(--color-accent)" : "var(--text-muted)", whiteSpace: "nowrap" }}>{step.label}</span>
                    </div>
                    {i < steps.length - 1 && (
                        <div style={{
                            width: "48px", height: "2px", margin: "0 var(--space-sm)", marginBottom: "18px",
                            background: current > step.num ? "var(--color-accent)" : "var(--border-color)",
                            borderRadius: "1px", transition: "all 0.3s ease",
                        }} />
                    )}
                </div>
            ))}
        </div>
    );
}

/* ─── Input Field ─── */
function Field({ label, required, error, children }: { label: string; required?: boolean; error?: string; children: React.ReactNode }) {
    return (
        <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
            <label style={{ fontSize: "0.74rem", fontWeight: 600, color: "var(--text-secondary)" }}>
                {label} {required && <span style={{ color: "#ef4444" }}>*</span>}
            </label>
            {children}
            {error && <span style={{ fontSize: "0.68rem", color: "#ef4444", fontWeight: 500 }}>{error}</span>}
        </div>
    );
}

const inputStyle: React.CSSProperties = {
    padding: "10px 14px",
    borderRadius: "var(--radius-md)",
    border: "1px solid var(--border-color)",
    background: "var(--bg-surface)",
    color: "var(--text-primary)",
    fontSize: "0.84rem",
    fontWeight: 500,
    outline: "none",
    transition: "border-color 0.2s, box-shadow 0.2s",
    width: "100%",
};

const inputErrorStyle: React.CSSProperties = {
    ...inputStyle,
    borderColor: "#ef4444",
    boxShadow: "0 0 0 3px rgba(239,68,68,0.1)",
};

/* ─── Custom Province Dropdown ─── */
function ProvinceDropdown({ value, onChange, error }: { value: string; onChange: (v: string) => void; error?: string }) {
    const [open, setOpen] = useState(false);
    const [search, setSearch] = useState("");
    const dropdownRef = useRef<HTMLDivElement>(null);
    const searchRef = useRef<HTMLInputElement>(null);

    const filtered = search
        ? PROVINCES.filter((p) => p.toLowerCase().includes(search.toLowerCase()))
        : PROVINCES;

    useEffect(() => {
        const handler = (e: MouseEvent) => {
            if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) setOpen(false);
        };
        document.addEventListener("mousedown", handler);
        return () => document.removeEventListener("mousedown", handler);
    }, []);

    useEffect(() => {
        if (open && searchRef.current) searchRef.current.focus();
    }, [open]);

    return (
        <div ref={dropdownRef} style={{ position: "relative" }}>
            <button
                type="button"
                onClick={() => setOpen(!open)}
                style={{
                    ...(error ? inputErrorStyle : inputStyle),
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    cursor: "pointer",
                    color: value ? "var(--text-primary)" : "var(--text-muted)",
                    textAlign: "left",
                }}
            >
                {value || "Chọn tỉnh/thành phố"}
                <svg
                    width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"
                    style={{ transition: "transform 0.2s", transform: open ? "rotate(180deg)" : "rotate(0deg)", flexShrink: 0, opacity: 0.5 }}
                >
                    <polyline points="6 9 12 15 18 9" />
                </svg>
            </button>

            {open && (
                <div
                    style={{
                        position: "absolute",
                        top: "calc(100% + 6px)",
                        left: 0,
                        right: 0,
                        zIndex: 50,
                        borderRadius: "var(--radius-lg)",
                        border: "1px solid var(--border-color)",
                        background: "var(--bg-card)",
                        boxShadow: "0 16px 40px rgba(0,0,0,0.4)",
                        overflow: "hidden",
                        animation: "modal-in 0.2s ease",
                    }}
                >
                    {/* Search */}
                    <div style={{ padding: "10px 12px", borderBottom: "1px solid var(--border-color)" }}>
                        <div style={{ position: "relative" }}>
                            <svg
                                width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--text-muted)" strokeWidth="2"
                                style={{ position: "absolute", left: "10px", top: "50%", transform: "translateY(-50%)" }}
                            >
                                <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
                            </svg>
                            <input
                                ref={searchRef}
                                type="text"
                                placeholder="Tìm tỉnh/thành phố..."
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                style={{
                                    ...inputStyle,
                                    paddingLeft: "32px",
                                    padding: "8px 12px 8px 32px",
                                    fontSize: "0.82rem",
                                    background: "var(--bg-surface)",
                                }}
                                onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.boxShadow = "0 0 0 3px rgba(139,92,246,0.15)"; }}
                                onBlur={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.boxShadow = "none"; }}
                            />
                        </div>
                    </div>

                    {/* Options list */}
                    <div style={{ maxHeight: "240px", overflowY: "auto", padding: "4px 0" }}>
                        {filtered.length === 0 ? (
                            <div style={{ padding: "16px", textAlign: "center", color: "var(--text-muted)", fontSize: "0.82rem" }}>
                                Không tìm thấy kết quả
                            </div>
                        ) : (
                            filtered.map((province) => (
                                <button
                                    key={province}
                                    type="button"
                                    onClick={() => {
                                        onChange(province);
                                        setOpen(false);
                                        setSearch("");
                                    }}
                                    style={{
                                        display: "flex",
                                        alignItems: "center",
                                        justifyContent: "space-between",
                                        width: "100%",
                                        padding: "10px 14px",
                                        fontSize: "0.85rem",
                                        fontWeight: province === value ? 600 : 400,
                                        color: province === value ? "var(--color-accent)" : "var(--text-secondary)",
                                        background: province === value ? "rgba(139,92,246,0.06)" : "transparent",
                                        textAlign: "left",
                                        cursor: "pointer",
                                        transition: "all 0.15s ease",
                                        border: "none",
                                    }}
                                    onMouseEnter={(e) => {
                                        if (province !== value) {
                                            e.currentTarget.style.background = "rgba(255,255,255,0.04)";
                                            e.currentTarget.style.color = "var(--text-primary)";
                                        }
                                    }}
                                    onMouseLeave={(e) => {
                                        if (province !== value) {
                                            e.currentTarget.style.background = "transparent";
                                            e.currentTarget.style.color = "var(--text-secondary)";
                                        }
                                    }}
                                >
                                    {province}
                                    {province === value && (
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2.5">
                                            <polyline points="20 6 9 17 4 12" />
                                        </svg>
                                    )}
                                </button>
                            ))
                        )}
                    </div>
                </div>
            )}

            <style>{`
                @keyframes modal-in {
                    from { opacity: 0; transform: translateY(-6px); }
                    to { opacity: 1; transform: translateY(0); }
                }
            `}</style>
        </div>
    );
}

/* ─── Payment Method Card ─── */
function PaymentCard({ method, selected, onSelect, icon, title, desc }: {
    method: PaymentMethod; selected: boolean;
    onSelect: () => void; icon: React.ReactNode; title: string; desc: string;
}) {
    return (
        <div
            onClick={onSelect}
            style={{
                padding: "12px 16px",
                borderRadius: "var(--radius-lg)",
                border: selected ? "1.5px solid var(--color-accent)" : "1px solid var(--border-color)",
                background: selected ? "rgba(139,92,246,0.04)" : "var(--bg-card)",
                cursor: "pointer",
                transition: "all 0.2s ease",
                display: "flex", alignItems: "center", gap: "12px",
            }}
            onMouseEnter={(e) => { if (!selected) e.currentTarget.style.borderColor = "rgba(139,92,246,0.3)"; }}
            onMouseLeave={(e) => { if (!selected) e.currentTarget.style.borderColor = "var(--border-color)"; }}
        >
            <div style={{
                width: "36px", height: "36px", borderRadius: "var(--radius-md)",
                background: selected ? "rgba(139,92,246,0.12)" : "var(--bg-surface)",
                display: "flex", alignItems: "center", justifyContent: "center",
                flexShrink: 0, transition: "all 0.2s",
            }}>
                {icon}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ fontSize: "0.82rem", fontWeight: 600, color: "var(--text-primary)", marginBottom: "1px" }}>{title}</p>
                <p style={{ fontSize: "0.7rem", color: "var(--text-muted)" }}>{desc}</p>
            </div>
            <div style={{
                width: "18px", height: "18px", borderRadius: "50%",
                border: selected ? "5px solid var(--color-accent)" : "2px solid var(--border-color)",
                transition: "all 0.2s ease", flexShrink: 0,
            }} />
        </div>
    );
}

/* ─── Order Success ─── */
function OrderSuccess({ orderId }: { orderId: string }) {
    const ref = useReveal("scale");
    return (
        <div ref={ref} style={{ textAlign: "center", padding: "var(--space-3xl) var(--space-2xl)", maxWidth: "560px", margin: "0 auto" }}>
            <div style={{
                width: "100px", height: "100px", borderRadius: "50%",
                background: "rgba(34,197,94,0.1)", border: "1px solid rgba(34,197,94,0.2)",
                display: "flex", alignItems: "center", justifyContent: "center",
                margin: "0 auto var(--space-xl)",
                animation: "pulse-glow 2s ease infinite",
            }}>
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="20 6 9 17 4 12" />
                </svg>
            </div>
            <h2 style={{ fontSize: "1.6rem", fontWeight: 800, color: "var(--text-primary)", marginBottom: "var(--space-md)" }}>
                Đặt hàng thành công!
            </h2>
            <p style={{ color: "var(--text-muted)", fontSize: "0.9rem", lineHeight: 1.7, marginBottom: "var(--space-sm)" }}>
                Cảm ơn bạn đã mua hàng tại StyleZone.
            </p>
            <p style={{ color: "var(--text-secondary)", fontSize: "0.85rem", marginBottom: "var(--space-2xl)" }}>
                Mã đơn hàng: <strong style={{ color: "var(--color-accent)" }}>{orderId}</strong>
            </p>
            <div style={{ display: "flex", gap: "var(--space-md)", justifyContent: "center", flexWrap: "wrap" }}>
                <Link href="/" className="btn btn-primary" style={{ padding: "12px 28px" }}>
                    Về Trang Chủ
                </Link>
                <Link href="/nam" className="btn btn-outline" style={{ padding: "12px 28px" }}>
                    Tiếp Tục Mua Sắm
                </Link>
            </div>
        </div>
    );
}

/* ============================================================
   PAGE
   ============================================================ */
export default function CheckoutPage() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const isBuyNow = searchParams.get("buyNow") === "1";
    const { cart, cartTotal, cartCount, clearCart, user } = useCart();
    const headerRef = useReveal("up");
    const formRef = useReveal("up", 0.1);
    const summaryRef = useReveal("up", 0.2);

    const [step, setStep] = useState(1);
    const [shipping, setShipping] = useState<ShippingInfo>({
        fullName: "", phone: "", email: "", province: "", district: "", ward: "", address: "", note: "",
    });
    const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("cod");
    const [errors, setErrors] = useState<Partial<Record<keyof ShippingInfo, string>>>({});
    const [submitting, setSubmitting] = useState(false);
    const [orderId, setOrderId] = useState("");
    const [locating, setLocating] = useState(false);
    const [buyNowItem, setBuyNowItem] = useState<CartItem | null>(null);

    // Coupon state
    const [coupons, setCoupons] = useState<Coupon[]>([]);
    const [appliedCoupon, setAppliedCoupon] = useState<Coupon | null>(null);
    const [discount, setDiscount] = useState(0);
    const [couponCode, setCouponCode] = useState("");
    const [loadingCoupons, setLoadingCoupons] = useState(false);
    const [savedVouchers, setSavedVouchers] = useState<SavedVoucher[]>([]);

    // Read buy-now item from sessionStorage
    useEffect(() => {
        if (isBuyNow) {
            try {
                const raw = sessionStorage.getItem("sz-buy-now");
                if (raw) setBuyNowItem(JSON.parse(raw));
            } catch { /* ignore */ }
        }
    }, [isBuyNow]);

    // Computed: which items to checkout
    const checkoutItems: CartItem[] = isBuyNow && buyNowItem ? [buyNowItem] : cart;
    const checkoutTotal = checkoutItems.reduce((sum, i) => {
        const p = i.salePrice > 0 && i.salePrice < i.price ? i.salePrice : i.price;
        return sum + p * i.quantity;
    }, 0);
    const checkoutCount = checkoutItems.reduce((sum, i) => sum + i.quantity, 0);

    // Fetch coupons + saved vouchers on mount
    useEffect(() => {
        setLoadingCoupons(true);
        fetchActiveCoupons()
            .then(setCoupons)
            .catch(() => {})
            .finally(() => setLoadingCoupons(false));
        if (user?.uid) {
            getSavedVouchers(user.uid).then(setSavedVouchers).catch(() => {});
        }
    }, [user?.uid]);

    // Pre-fill from user
    useEffect(() => {
        if (user) {
            setShipping((prev) => ({
                ...prev,
                fullName: user.displayName || prev.fullName,
                email: user.email || prev.email,
            }));
        }
    }, [user]);

    // Redirect if no items / not logged in
    useEffect(() => {
        if (!user) { router.push("/dang-nhap"); return; }
        if (!isBuyNow && cartCount === 0 && step < 3) { router.push("/gio-hang"); }
    }, [user, cartCount, step, router, isBuyNow]);

    useEffect(() => { window.scrollTo({ top: 0, behavior: "smooth" }); }, [step]);

    const SHIPPING_FEE = 0; // free shipping
    const total = checkoutTotal + SHIPPING_FEE - discount;

    // Apply / remove coupon
    const handleApplyCoupon = useCallback((coupon: Coupon) => {
        const result = validateCoupon(coupon, checkoutTotal);
        if (result.isValid) {
            setAppliedCoupon(coupon);
            setDiscount(result.discountAmount);
            setCouponCode(coupon.code);
            toast.success(`Áp dụng mã ${coupon.code} thành công! Giảm ${formatPrice(result.discountAmount)}`);
        } else {
            toast.error(result.message);
        }
    }, [checkoutTotal]);

    const handleRemoveCoupon = useCallback(() => {
        setAppliedCoupon(null);
        setDiscount(0);
        setCouponCode("");
        toast.info("Đã bỏ mã giảm giá");
    }, []);

    // Stable transfer code for bank QR (generated once per session)
    const transferCode = useMemo(() => "SZ" + Date.now().toString(36).toUpperCase(), []);

    // Validate step 1
    const validateShipping = useCallback((): boolean => {
        const newErrors: Partial<Record<keyof ShippingInfo, string>> = {};
        if (!shipping.fullName.trim()) newErrors.fullName = "Vui lòng nhập họ tên";
        if (!shipping.phone.trim()) newErrors.phone = "Vui lòng nhập số điện thoại";
        else if (!/^(0|\+84)\d{9,10}$/.test(shipping.phone.replace(/\s/g, "")))
            newErrors.phone = "Số điện thoại không hợp lệ";
        if (!shipping.email.trim()) newErrors.email = "Vui lòng nhập email";
        else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(shipping.email))
            newErrors.email = "Email không hợp lệ";
        if (!shipping.province) newErrors.province = "Vui lòng chọn tỉnh/thành phố";
        if (!shipping.district.trim()) newErrors.district = "Vui lòng nhập quận/huyện";
        if (!shipping.ward.trim()) newErrors.ward = "Vui lòng nhập phường/xã";
        if (!shipping.address.trim()) newErrors.address = "Vui lòng nhập địa chỉ";
        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    }, [shipping]);

    const handleNextStep = useCallback(async () => {
        if (step === 1 && validateShipping()) setStep(2);
        if (step === 2) {
            setSubmitting(true);
            try {
                const fullAddress = `${shipping.address}, ${shipping.ward}, ${shipping.district}, ${shipping.province}`;
                const id = await createOrder({
                    customerName: shipping.fullName,
                    customerEmail: shipping.email,
                    customerPhone: shipping.phone,
                    shippingAddress: fullAddress,
                    items: checkoutItems.map((item) => {
                        const unitPrice = item.salePrice > 0 && item.salePrice < item.price ? item.salePrice : item.price;
                        return {
                            productId: item.productId,
                            productName: item.name,
                            imageUrl: item.image,
                            price: unitPrice,
                            quantity: item.quantity,
                            size: item.size,
                            color: item.color,
                        };
                    }),
                    subtotal: checkoutTotal,
                    shippingFee: SHIPPING_FEE,
                    discount,
                    total,
                    paymentMethod,
                    note: shipping.note,
                });

                setOrderId(id);
                if (!isBuyNow) clearCart();
                sessionStorage.removeItem("sz-buy-now");
                if (appliedCoupon) {
                    try { await markCouponUsed(appliedCoupon.id); } catch { /* ok */ }
                }
                toast.success("Đặt hàng thành công! 🎉");
                setStep(3);
                setSubmitting(false);
            } catch (error) {
                console.error("Create order failed:", error);
                toast.error("Đặt hàng thất bại. Vui lòng thử lại.");
                setSubmitting(false);
            }
        }
    }, [step, validateShipping, clearCart, paymentMethod, shipping, checkoutItems, checkoutTotal, total, discount, SHIPPING_FEE, isBuyNow, appliedCoupon]);

    const updateField = useCallback((field: keyof ShippingInfo, value: string) => {
        setShipping((prev) => ({ ...prev, [field]: value }));
        if (errors[field]) setErrors((prev) => ({ ...prev, [field]: undefined }));
    }, [errors]);

    // Geolocation: detect user position and reverse geocode
    const detectLocation = useCallback(async () => {
        if (!navigator.geolocation) {
            toast.error("Trình duyệt không hỗ trợ định vị.");
            return;
        }
        setLocating(true);
        try {
            const pos = await new Promise<GeolocationPosition>((resolve, reject) => {
                navigator.geolocation.getCurrentPosition(resolve, reject, {
                    enableHighAccuracy: true,
                    timeout: 10000,
                    maximumAge: 0,
                });
            });
            const { latitude, longitude } = pos.coords;

            const res = await fetch(
                `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json&accept-language=vi&addressdetails=1&zoom=18`,
                { headers: { "User-Agent": "StyleZone-WebShop/1.0" } }
            );
            const data = await res.json();
            const addr = data.address || {};
            const displayName: string = data.display_name || "";
            const displayParts = displayName.split(",").map((s: string) => s.trim());

            // Helper: check if a string looks like province/district/ward/country
            const isAdminLevel = (s: string) =>
                /^(ph\u01b0\u1eddng|x\u00e3|th\u1ecb tr\u1ea5n|qu\u1eadn|huy\u1ec7n|th\u1ecb x\u00e3|t\u1ec9nh|th\u00e0nh ph\u1ed1|tp\.?|vi\u1ec7t nam|vietnam)/i.test(s) ||
                PROVINCES.some((p) => s.toLowerCase().includes(p.toLowerCase()));

            // Extract all possible fields from address object
            const rawProvince = addr.city || addr.state || addr.province || addr.county || "";
            const district = addr.city_district || addr.suburb || addr.town || addr.district || "";
            const ward = addr.quarter || addr.village || addr.neighbourhood || addr.hamlet || "";
            const road = addr.road || addr.pedestrian || addr.street || "";
            const houseNumber = addr.house_number || "";
            const alley = addr.alley || addr.path || "";
            const building = addr.building || addr.amenity || addr.shop || "";

            // Build detailed address: "Số nhà, Hẻm/Ngõ, Đường"
            const addressParts = [building, houseNumber, alley, road].filter(Boolean);
            let addressDetail = addressParts.length > 0
                ? addressParts.join(", ")
                : "";

            // Fallback: parse from display_name (most specific parts first)
            if (!addressDetail && displayParts.length >= 3) {
                // Take parts that are NOT admin levels (province/district/ward/country)
                const specificParts = displayParts.filter((p) => !isAdminLevel(p));
                addressDetail = specificParts.slice(0, 2).join(", ");
            }
            // If address is only a road name, try to prepend house number from display_name
            if (addressDetail && !houseNumber && displayParts.length > 0) {
                const firstPart = displayParts[0];
                if (/^\d/.test(firstPart) && !addressDetail.includes(firstPart)) {
                    addressDetail = firstPart + ", " + addressDetail;
                }
            }

            // If ward is empty, try parsing from display_name
            let finalWard = ward;
            if (!finalWard && displayName) {
                const parts = displayName.split(",").map((s: string) => s.trim());
                // Look for "Phường" or "Xã" in display_name parts
                const wardPart = parts.find((p: string) =>
                    /^(phường|xã|thị trấn)/i.test(p)
                );
                if (wardPart) finalWard = wardPart;
            }

            // If district is empty, try parsing from display_name
            let finalDistrict = district;
            if (!finalDistrict && displayName) {
                const parts = displayName.split(",").map((s: string) => s.trim());
                const distPart = parts.find((p: string) =>
                    /^(quận|huyện|thị xã|thành phố)/i.test(p)
                );
                if (distPart) finalDistrict = distPart;
            }

            // Match province to PROVINCES list (try multiple strategies)
            const normalize = (s: string) => s.toLowerCase().replace(/^(tỉnh|thành phố|tp\.?\s*)/i, "").trim();
            const normalizedRaw = normalize(rawProvince);
            const matchedProvince = PROVINCES.find(
                (p) => normalize(p) === normalizedRaw
            ) || PROVINCES.find(
                (p) => normalizedRaw && (normalize(p).includes(normalizedRaw) || normalizedRaw.includes(normalize(p)))
            ) || "";

            // If province still not matched, try from display_name
            let finalProvince = matchedProvince;
            if (!finalProvince && displayName) {
                const parts = displayName.split(",").map((s: string) => s.trim());
                for (const part of parts) {
                    const match = PROVINCES.find(
                        (p) => normalize(p) === normalize(part) ||
                            normalize(p).includes(normalize(part)) ||
                            normalize(part).includes(normalize(p))
                    );
                    if (match) { finalProvince = match; break; }
                }
            }

            setShipping((prev) => ({
                ...prev,
                province: finalProvince || prev.province,
                district: finalDistrict || prev.district,
                ward: finalWard || prev.ward,
                address: addressDetail || prev.address,
            }));
            // Clear related errors
            setErrors((prev) => ({
                ...prev,
                province: undefined,
                district: undefined,
                ward: undefined,
                address: undefined,
            }));
            toast.success("Đã xác định vị trí của bạn! 📍");
        } catch (err) {
            const geoErr = err as GeolocationPositionError;
            if (geoErr?.code === 1) {
                toast.error("Bạn đã từ chối quyền truy cập vị trí.");
            } else {
                toast.error("Không thể xác định vị trí. Vui lòng nhập thủ công.");
            }
        } finally {
            setLocating(false);
        }
    }, []);

    // Success screen
    if (step === 3 && orderId) {
        return (
            <section className="section" style={{ paddingTop: "calc(var(--header-height) + var(--space-lg))", minHeight: "70vh" }}>
                <div className="container">
                    <StepIndicator current={3} />
                    <OrderSuccess orderId={orderId} />
                </div>
            </section>
        );
    }

    if (!user || (checkoutCount === 0 && step < 3)) return null;

    return (
        <>
            <section className="section" style={{ paddingTop: "calc(var(--header-height) + var(--space-lg))", minHeight: "70vh" }}>
                <div className="container">
                    {/* Header */}
                    <div ref={headerRef} style={{ marginBottom: "var(--space-lg)" }}>
                        <h1 style={{ fontSize: "clamp(1.4rem, 3vw, 1.8rem)", fontWeight: 800, color: "var(--text-primary)" }}>
                            Thanh Toán
                        </h1>
                    </div>

                    <StepIndicator current={step} />

                    {/* Main layout */}
                    <div className="checkout-layout" style={{ display: "grid", gridTemplateColumns: "1fr 360px", gap: "var(--space-lg)", alignItems: "start" }}>
                        {/* Left column */}
                        <div ref={formRef}>
                            {step === 1 && (
                                <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                                    {/* Section 1: Contact Info */}
                                    <div style={{ borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)", background: "var(--bg-card)", padding: "20px" }}>
                                        <h2 style={{ fontSize: "0.92rem", fontWeight: 700, color: "var(--text-primary)", display: "flex", alignItems: "center", gap: "8px", margin: "0 0 16px 0" }}>
                                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
                                            </svg>
                                            Thông tin liên hệ
                                        </h2>
                                        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }} className="checkout-form-grid">
                                            <Field label="Họ và tên" required error={errors.fullName}>
                                                <input style={errors.fullName ? inputErrorStyle : inputStyle} placeholder="Nguyễn Văn A"
                                                    value={shipping.fullName} onChange={(e) => updateField("fullName", e.target.value)}
                                                    onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.boxShadow = "0 0 0 3px rgba(139,92,246,0.25)"; }}
                                                    onBlur={(e) => { if (!errors.fullName) { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.boxShadow = "none"; } }}
                                                />
                                            </Field>
                                            <Field label="Số điện thoại" required error={errors.phone}>
                                                <input style={errors.phone ? inputErrorStyle : inputStyle} placeholder="0912 345 678" type="tel"
                                                    value={shipping.phone} onChange={(e) => updateField("phone", e.target.value)}
                                                    onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.boxShadow = "0 0 0 3px rgba(139,92,246,0.25)"; }}
                                                    onBlur={(e) => { if (!errors.phone) { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.boxShadow = "none"; } }}
                                                />
                                            </Field>
                                            <div style={{ gridColumn: "1 / -1" }}>
                                                <Field label="Email" required error={errors.email}>
                                                    <input style={errors.email ? inputErrorStyle : inputStyle} placeholder="email@example.com" type="email"
                                                        value={shipping.email} onChange={(e) => updateField("email", e.target.value)}
                                                        onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.boxShadow = "0 0 0 3px rgba(139,92,246,0.25)"; }}
                                                        onBlur={(e) => { if (!errors.email) { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.boxShadow = "none"; } }}
                                                    />
                                                </Field>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Section 2: Shipping Address */}
                                    <div style={{ borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)", background: "var(--bg-card)", padding: "20px" }}>
                                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
                                            <h2 style={{ fontSize: "0.92rem", fontWeight: 700, color: "var(--text-primary)", display: "flex", alignItems: "center", gap: "8px", margin: 0 }}>
                                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" />
                                                </svg>
                                                Địa chỉ giao hàng
                                            </h2>
                                            <button
                                                type="button"
                                                onClick={detectLocation}
                                                disabled={locating}
                                                style={{
                                                    display: "flex", alignItems: "center", gap: "5px",
                                                    padding: "6px 14px", borderRadius: "var(--radius-full)",
                                                    border: "1px solid rgba(139,92,246,0.25)",
                                                    background: "rgba(139,92,246,0.04)",
                                                    color: "var(--color-accent)", fontSize: "0.72rem", fontWeight: 600,
                                                    cursor: locating ? "not-allowed" : "pointer",
                                                    transition: "all 0.2s", opacity: locating ? 0.7 : 1,
                                                }}
                                                onMouseEnter={(e) => { if (!locating) { e.currentTarget.style.background = "rgba(139,92,246,0.1)"; e.currentTarget.style.borderColor = "var(--color-accent)"; } }}
                                                onMouseLeave={(e) => { e.currentTarget.style.background = "rgba(139,92,246,0.04)"; e.currentTarget.style.borderColor = "rgba(139,92,246,0.25)"; }}
                                            >
                                                {locating ? (
                                                    <>
                                                        <div style={{ width: "12px", height: "12px", borderRadius: "50%", border: "2px solid rgba(139,92,246,0.3)", borderTopColor: "var(--color-accent)", animation: "rotate-slow 0.8s linear infinite" }} />
                                                        Đang định vị...
                                                    </>
                                                ) : (
                                                    <>
                                                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><circle cx="12" cy="12" r="10" /><path d="M12 2v4M12 18v4M2 12h4M18 12h4" /></svg>
                                                        Tự động điền
                                                    </>
                                                )}
                                            </button>
                                        </div>
                                        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }} className="checkout-form-grid">
                                            <Field label="Tỉnh/Thành phố" required error={errors.province}>
                                                <ProvinceDropdown
                                                    value={shipping.province}
                                                    onChange={(v) => updateField("province", v)}
                                                    error={errors.province}
                                                />
                                            </Field>
                                            <Field label="Quận/Huyện" required error={errors.district}>
                                                <input style={errors.district ? inputErrorStyle : inputStyle} placeholder="Quận 1"
                                                    value={shipping.district} onChange={(e) => updateField("district", e.target.value)}
                                                    onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.boxShadow = "0 0 0 3px rgba(139,92,246,0.25)"; }}
                                                    onBlur={(e) => { if (!errors.district) { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.boxShadow = "none"; } }}
                                                />
                                            </Field>
                                            <Field label="Phường/Xã" required error={errors.ward}>
                                                <input style={errors.ward ? inputErrorStyle : inputStyle} placeholder="Phường Bến Nghé"
                                                    value={shipping.ward} onChange={(e) => updateField("ward", e.target.value)}
                                                    onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.boxShadow = "0 0 0 3px rgba(139,92,246,0.25)"; }}
                                                    onBlur={(e) => { if (!errors.ward) { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.boxShadow = "none"; } }}
                                                />
                                            </Field>
                                            <div style={{ gridColumn: "1 / -1" }}>
                                                <Field label="Số nhà, tên đường" required error={errors.address}>
                                                    <input style={errors.address ? inputErrorStyle : inputStyle} placeholder="VD: 12 Nguyễn Văn Bảo, Hẻm 3..."
                                                        value={shipping.address} onChange={(e) => updateField("address", e.target.value)}
                                                        onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.boxShadow = "0 0 0 3px rgba(139,92,246,0.25)"; }}
                                                        onBlur={(e) => { if (!errors.address) { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.boxShadow = "none"; } }}
                                                    />
                                                </Field>
                                            </div>
                                            <div style={{ gridColumn: "1 / -1" }}>
                                                <Field label="Ghi chú đơn hàng">
                                                    <textarea style={{ ...inputStyle, resize: "vertical", minHeight: "70px" }} placeholder="Giao giờ hành chính, gọi trước khi giao..."
                                                        value={shipping.note} onChange={(e) => updateField("note", e.target.value)}
                                                        onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.boxShadow = "0 0 0 3px rgba(139,92,246,0.25)"; }}
                                                        onBlur={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.boxShadow = "none"; }}
                                                    />
                                                </Field>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            )}

                            {step === 2 && (
                                <div>
                                    {/* Shipping summary */}
                                    <div style={{
                                        borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)",
                                        background: "var(--bg-card)", padding: "16px", marginBottom: "12px",
                                    }}>
                                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "8px" }}>
                                            <h3 style={{ fontSize: "0.82rem", fontWeight: 700, color: "var(--text-primary)", display: "flex", alignItems: "center", gap: "6px" }}>
                                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>
                                                Giao tới
                                            </h3>
                                            <button onClick={() => setStep(1)} style={{
                                                fontSize: "0.72rem", fontWeight: 600, color: "var(--color-accent)",
                                                background: "transparent", cursor: "pointer", padding: "3px 10px",
                                                borderRadius: "var(--radius-sm)", border: "1px solid rgba(139,92,246,0.2)",
                                                transition: "all 0.2s",
                                            }}
                                                onMouseEnter={(e) => { e.currentTarget.style.background = "rgba(139,92,246,0.06)"; }}
                                                onMouseLeave={(e) => { e.currentTarget.style.background = "transparent"; }}
                                            >Thay đổi</button>
                                        </div>
                                        <p style={{ fontSize: "0.82rem", fontWeight: 600, color: "var(--text-primary)", marginBottom: "2px" }}>
                                            {shipping.fullName} · {shipping.phone}
                                        </p>
                                        <p style={{ fontSize: "0.76rem", color: "var(--text-muted)", lineHeight: 1.4 }}>
                                            {shipping.address}, {shipping.ward}, {shipping.district}, {shipping.province}
                                        </p>
                                    </div>

                                    {/* Payment methods */}
                                    <div style={{
                                        borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)",
                                        background: "var(--bg-card)", padding: "16px",
                                    }}>
                                        <h2 style={{ fontSize: "0.95rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "12px", display: "flex", alignItems: "center", gap: "8px" }}>
                                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                <rect x="1" y="4" width="22" height="16" rx="2" ry="2" /><line x1="1" y1="10" x2="23" y2="10" />
                                            </svg>
                                            Phương thức thanh toán
                                        </h2>
                                        <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                                            <PaymentCard method="cod" selected={paymentMethod === "cod"} onSelect={() => setPaymentMethod("cod")}
                                                icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={paymentMethod === "cod" ? "var(--color-accent)" : "var(--text-muted)"} strokeWidth="2"><rect x="2" y="4" width="20" height="16" rx="2" /><path d="M12 12h.01" /><path d="M17 12h.01" /><path d="M7 12h.01" /></svg>}
                                                title="Thanh toán khi nhận hàng (COD)"
                                                desc="Thanh toán bằng tiền mặt khi nhận hàng"
                                            />
                                            <PaymentCard method="bank" selected={paymentMethod === "bank"} onSelect={() => setPaymentMethod("bank")}
                                                icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={paymentMethod === "bank" ? "var(--color-accent)" : "var(--text-muted)"} strokeWidth="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" /><polyline points="9 22 9 12 15 12 15 22" /></svg>}
                                                title="Chuyển khoản ngân hàng"
                                                desc="Chuyển khoản qua internet banking hoặc ATM"
                                            />
                                            <PaymentCard method="momo" selected={paymentMethod === "momo"} onSelect={() => setPaymentMethod("momo")}
                                                icon={<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={paymentMethod === "momo" ? "var(--color-accent)" : "var(--text-muted)"} strokeWidth="2"><rect x="5" y="2" width="14" height="20" rx="2" /><line x1="12" y1="18" x2="12.01" y2="18" /></svg>}
                                                title="Ví MoMo"
                                                desc="Thanh toán qua ví điện tử MoMo"
                                            />
                                        </div>
                                    </div>

                                    {/* Voucher / Coupon section */}
                                    <div style={{
                                        borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)",
                                        background: "var(--bg-card)", padding: "16px", marginTop: "12px",
                                    }}>
                                        <h2 style={{ fontSize: "0.95rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "12px", display: "flex", alignItems: "center", gap: "8px" }}>
                                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                <path d="M20 12v6a2 2 0 01-2 2H6a2 2 0 01-2-2v-6" /><path d="M2 8h20v4H2z" /><path d="M12 2v6" /><path d="M12 14v6" />
                                            </svg>
                                            Mã giảm giá
                                        </h2>

                                        {/* Manual code input */}
                                        <div style={{ display: "flex", gap: "8px", marginBottom: "12px" }}>
                                            <input
                                                style={{ ...inputStyle, flex: 1, textTransform: "uppercase", letterSpacing: "0.05em", fontWeight: 600, fontSize: "0.8rem" }}
                                                placeholder="Nhập mã giảm giá..."
                                                value={couponCode}
                                                onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                                                onFocus={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.boxShadow = "0 0 0 3px rgba(139,92,246,0.25)"; }}
                                                onBlur={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.boxShadow = "none"; }}
                                                disabled={!!appliedCoupon}
                                            />
                                            {appliedCoupon ? (
                                                <button onClick={handleRemoveCoupon} type="button" style={{
                                                    padding: "10px 16px", borderRadius: "var(--radius-md)",
                                                    border: "1px solid rgba(239,68,68,0.3)", background: "rgba(239,68,68,0.06)",
                                                    color: "#ef4444", fontSize: "0.78rem", fontWeight: 600, cursor: "pointer",
                                                    whiteSpace: "nowrap", transition: "all 0.2s",
                                                }}>Bỏ</button>
                                            ) : (
                                                <button onClick={() => {
                                                    const found = coupons.find((c) => c.code === couponCode.trim().toUpperCase());
                                                    if (found) handleApplyCoupon(found);
                                                    else toast.error("Mã giảm giá không tồn tại");
                                                }} type="button" disabled={!couponCode.trim()} style={{
                                                    padding: "10px 16px", borderRadius: "var(--radius-md)",
                                                    border: "none", background: couponCode.trim() ? "linear-gradient(135deg, var(--color-accent), #6366f1)" : "var(--bg-surface)",
                                                    color: couponCode.trim() ? "#fff" : "var(--text-muted)", fontSize: "0.78rem", fontWeight: 600,
                                                    cursor: couponCode.trim() ? "pointer" : "not-allowed", whiteSpace: "nowrap", transition: "all 0.2s",
                                                }}>Áp dụng</button>
                                            )}
                                        </div>

                                        {/* Applied coupon badge */}
                                        {appliedCoupon && (
                                            <div style={{
                                                padding: "10px 14px", borderRadius: "var(--radius-md)",
                                                background: "rgba(34,197,94,0.06)", border: "1px solid rgba(34,197,94,0.2)",
                                                display: "flex", justifyContent: "space-between", alignItems: "center",
                                                marginBottom: "12px",
                                            }}>
                                                <div>
                                                    <p style={{ fontSize: "0.78rem", fontWeight: 700, color: "#22c55e" }}>✓ {appliedCoupon.code}</p>
                                                    <p style={{ fontSize: "0.68rem", color: "var(--text-muted)" }}>{appliedCoupon.name || appliedCoupon.description}</p>
                                                </div>
                                                <span style={{ fontSize: "0.85rem", fontWeight: 700, color: "#22c55e" }}>-{formatPrice(discount)}</span>
                                            </div>
                                        )}

                                        {/* Saved vouchers */}
                                        {savedVouchers.length > 0 && (
                                            <div style={{ marginBottom: "12px" }}>
                                                <p style={{ fontSize: "0.68rem", fontWeight: 600, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: "6px" }}>Voucher đã lưu</p>
                                                <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                                                    {savedVouchers.map((sv) => {
                                                        const matchedCoupon = coupons.find((c) => c.code === sv.code);
                                                        const isEligible = matchedCoupon ? checkoutTotal >= (matchedCoupon.minOrderAmount || 0) : checkoutTotal >= sv.minOrderAmount;
                                                        const isApplied = appliedCoupon?.code === sv.code;
                                                        const canApply = isEligible && !isApplied && !appliedCoupon;
                                                        return (
                                                            <button
                                                                key={sv.id}
                                                                type="button"
                                                                onClick={() => {
                                                                    if (!canApply) return;
                                                                    if (matchedCoupon) { handleApplyCoupon(matchedCoupon); }
                                                                    else { toast.error("Voucher không còn khả dụng"); }
                                                                }}
                                                                disabled={!canApply}
                                                                style={{
                                                                    display: "flex", alignItems: "center", gap: "10px",
                                                                    padding: "10px 12px", borderRadius: "var(--radius-md)",
                                                                    border: isApplied ? "1px solid rgba(34,197,94,0.3)" : "1px solid var(--border-color)",
                                                                    background: isApplied ? "rgba(34,197,94,0.04)" : "var(--bg-surface)",
                                                                    opacity: !isEligible ? 0.4 : 1,
                                                                    cursor: canApply ? "pointer" : "not-allowed",
                                                                    transition: "all 0.2s", textAlign: "left", width: "100%",
                                                                    filter: !isEligible ? "grayscale(0.5)" : "none",
                                                                }}
                                                                onMouseEnter={(e) => { if (canApply) e.currentTarget.style.borderColor = sv.color; }}
                                                                onMouseLeave={(e) => { if (canApply) e.currentTarget.style.borderColor = "var(--border-color)"; }}
                                                            >
                                                                <div style={{
                                                                    flexShrink: 0, padding: "4px 8px", borderRadius: "var(--radius-sm)",
                                                                    background: isApplied ? "rgba(34,197,94,0.1)" : `${sv.color}15`,
                                                                    fontSize: "0.72rem", fontWeight: 700,
                                                                    color: isApplied ? "#22c55e" : sv.color,
                                                                    whiteSpace: "nowrap",
                                                                }}>
                                                                    {sv.discountType === "percent" ? `-${sv.discountValue}%` : `-${formatPrice(sv.discountValue)}`}
                                                                </div>
                                                                <div style={{ flex: 1, minWidth: 0 }}>
                                                                    <p style={{ fontSize: "0.75rem", fontWeight: 600, color: !isEligible ? "var(--text-muted)" : "var(--text-primary)", marginBottom: "1px" }}>{sv.code}</p>
                                                                    <p style={{ fontSize: "0.65rem", color: "var(--text-muted)", lineHeight: 1.3 }}>
                                                                        {sv.label}
                                                                        {!isEligible && sv.minOrderAmount > 0 ? ` · Đơn tối thiểu ${formatPrice(sv.minOrderAmount)}` : ""}
                                                                    </p>
                                                                </div>
                                                                {isApplied && (
                                                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2.5"><polyline points="20 6 9 17 4 12" /></svg>
                                                                )}
                                                                {!isEligible && (
                                                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--text-muted)" strokeWidth="2" style={{ flexShrink: 0, opacity: 0.5 }}><circle cx="12" cy="12" r="10" /><line x1="4.93" y1="4.93" x2="19.07" y2="19.07" /></svg>
                                                                )}
                                                            </button>
                                                        );
                                                    })}
                                                </div>
                                            </div>
                                        )}

                                        {/* Available coupons */}
                                        {!loadingCoupons && coupons.length > 0 && (
                                            <div>
                                                <p style={{ fontSize: "0.68rem", fontWeight: 600, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: "6px" }}>Voucher có sẵn</p>
                                                <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                                                    {coupons.map((c) => {
                                                        const validation = validateCoupon(c, checkoutTotal);
                                                        const isApplied = appliedCoupon?.id === c.id;
                                                        const canApply = validation.isValid && !isApplied;
                                                        const isDisabled = !validation.isValid && !isApplied;
                                                        return (
                                                            <button
                                                                key={c.id}
                                                                type="button"
                                                                onClick={() => canApply && handleApplyCoupon(c)}
                                                                disabled={isDisabled}
                                                                style={{
                                                                    display: "flex", alignItems: "center", gap: "10px",
                                                                    padding: "10px 12px", borderRadius: "var(--radius-md)",
                                                                    border: isApplied ? "1px solid rgba(34,197,94,0.3)" : "1px solid var(--border-color)",
                                                                    background: isApplied ? "rgba(34,197,94,0.04)" : "var(--bg-surface)",
                                                                    opacity: isDisabled ? 0.4 : 1,
                                                                    cursor: isDisabled ? "not-allowed" : "pointer",
                                                                    transition: "all 0.2s", textAlign: "left", width: "100%",
                                                                    filter: isDisabled ? "grayscale(0.5)" : "none",
                                                                }}
                                                                onMouseEnter={(e) => { if (!isDisabled && !isApplied) e.currentTarget.style.borderColor = "var(--color-accent)"; }}
                                                                onMouseLeave={(e) => { if (!isDisabled && !isApplied) e.currentTarget.style.borderColor = "var(--border-color)"; }}
                                                            >
                                                                {/* Discount badge */}
                                                                <div style={{
                                                                    flexShrink: 0, padding: "4px 8px", borderRadius: "var(--radius-sm)",
                                                                    background: isApplied ? "rgba(34,197,94,0.1)" : "rgba(139,92,246,0.08)",
                                                                    fontSize: "0.72rem", fontWeight: 700,
                                                                    color: isApplied ? "#22c55e" : "var(--color-accent)",
                                                                    whiteSpace: "nowrap",
                                                                }}>
                                                                    {c.discountType === "percent" ? `-${c.discountValue}%` : `-${formatPrice(c.discountValue)}`}
                                                                </div>
                                                                {/* Info */}
                                                                <div style={{ flex: 1, minWidth: 0 }}>
                                                                    <p style={{ fontSize: "0.75rem", fontWeight: 600, color: isDisabled ? "var(--text-muted)" : "var(--text-primary)", marginBottom: "1px" }}>{c.code}</p>
                                                                    <p style={{ fontSize: "0.65rem", color: "var(--text-muted)", lineHeight: 1.3 }}>
                                                                        {c.name || c.description}
                                                                        {isDisabled && validation.message ? ` · ${validation.message}` : ""}
                                                                    </p>
                                                                </div>
                                                                {/* Status */}
                                                                {isApplied && (
                                                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2.5"><polyline points="20 6 9 17 4 12" /></svg>
                                                                )}
                                                            </button>
                                                        );
                                                    })}
                                                </div>
                                            </div>
                                        )}
                                    </div>

                                    {/* VietQR inline when bank selected */}
                                    {paymentMethod === "bank" && (
                                        <div style={{
                                            borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)",
                                            background: "var(--bg-card)", padding: "16px", marginTop: "12px",
                                        }}>
                                            <h2 style={{ fontSize: "0.95rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "12px", display: "flex", alignItems: "center", gap: "8px" }}>
                                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                    <rect x="3" y="3" width="18" height="18" rx="2" /><path d="M7 7h.01M7 12h.01M12 7h.01M17 7h.01M12 12h.01M17 12h.01M7 17h.01M12 17h.01M17 17h.01" />
                                                </svg>
                                                Quét mã QR thanh toán
                                            </h2>
                                            <div style={{ display: "flex", gap: "16px", alignItems: "flex-start", flexWrap: "wrap" }}>
                                                <div style={{
                                                    borderRadius: "var(--radius-md)", overflow: "hidden",
                                                    border: "1px solid var(--border-color)", background: "#fff",
                                                    padding: "6px", flexShrink: 0,
                                                }}>
                                                    <img
                                                        src={buildVietQRUrl(total, transferCode)}
                                                        alt="VietQR Payment"
                                                        width={220}
                                                        height={300}
                                                        style={{ display: "block", borderRadius: "var(--radius-sm)" }}
                                                    />
                                                </div>
                                                <div style={{ flex: 1, minWidth: "200px" }}>
                                                    <div style={{
                                                        padding: "14px", borderRadius: "var(--radius-md)",
                                                        background: "var(--bg-surface)", border: "1px solid var(--border-color)",
                                                        marginBottom: "12px",
                                                    }}>
                                                        <p style={{ fontSize: "0.68rem", fontWeight: 600, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: "8px" }}>Thông tin chuyển khoản</p>
                                                        {[
                                                            { label: "Ngân hàng", value: "Vietcombank (VCB)" },
                                                            { label: "Số tài khoản", value: VIETQR_ACCOUNT },
                                                            { label: "Chủ tài khoản", value: VIETQR_ACCOUNT_NAME },
                                                            { label: "Số tiền", value: formatPrice(total), accent: true },
                                                            { label: "Nội dung CK", value: `Thanh toan don hang ${transferCode}`, accent: true },
                                                        ].map((row) => (
                                                            <div key={row.label} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "6px 0", borderBottom: "1px solid var(--border-color)" }}>
                                                                <span style={{ fontSize: "0.74rem", color: "var(--text-muted)" }}>{row.label}</span>
                                                                <span style={{ fontSize: "0.78rem", fontWeight: 600, color: row.accent ? "var(--color-accent)" : "var(--text-primary)" }}>{row.value}</span>
                                                            </div>
                                                        ))}
                                                    </div>
                                                    <div style={{
                                                        padding: "10px 14px", borderRadius: "var(--radius-sm)",
                                                        background: "rgba(139,92,246,0.06)", border: "1px solid rgba(139,92,246,0.15)",
                                                    }}>
                                                        <p style={{ fontSize: "0.72rem", color: "var(--text-secondary)", lineHeight: 1.5 }}>
                                                            💡 Mở app ngân hàng → Quét mã QR → Xác nhận thanh toán.
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            )}


                            {/* Navigation buttons */}
                            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "16px", gap: "12px" }}>
                                {step === 2 && (
                                    <button onClick={() => setStep(1)} style={{
                                        display: "flex", alignItems: "center", gap: "6px",
                                        padding: "10px 20px", borderRadius: "var(--radius-full)",
                                        border: "1px solid var(--border-color)", background: "transparent",
                                        color: "var(--text-primary)", fontSize: "0.82rem", fontWeight: 600,
                                        cursor: "pointer", transition: "all 0.2s",
                                    }}
                                        onMouseEnter={(e) => { e.currentTarget.style.borderColor = "var(--color-accent)"; e.currentTarget.style.color = "var(--color-accent)"; }}
                                        onMouseLeave={(e) => { e.currentTarget.style.borderColor = "var(--border-color)"; e.currentTarget.style.color = "var(--text-primary)"; }}
                                    >
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M19 12H5M12 19l-7-7 7-7" /></svg>
                                        Quay lại
                                    </button>
                                )}
                                <button
                                    onClick={handleNextStep}
                                    disabled={submitting}
                                    style={{
                                        marginLeft: step === 1 ? "auto" : "0",
                                        display: "flex", alignItems: "center", gap: "8px",
                                        padding: "12px 28px", borderRadius: "var(--radius-full)",
                                        background: submitting ? "var(--text-muted)" : "linear-gradient(135deg, var(--color-accent) 0%, #6366f1 100%)",
                                        color: "#fff", fontSize: "0.85rem", fontWeight: 700,
                                        cursor: submitting ? "not-allowed" : "pointer",
                                        border: "none", transition: "all 0.3s ease",
                                        boxShadow: submitting ? "none" : "0 4px 16px rgba(139,92,246,0.3)",
                                        opacity: submitting ? 0.7 : 1,
                                    }}
                                    onMouseEnter={(e) => { if (!submitting) { e.currentTarget.style.transform = "translateY(-1px)"; e.currentTarget.style.boxShadow = "0 6px 24px rgba(139,92,246,0.35)"; } }}
                                    onMouseLeave={(e) => { e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "0 4px 16px rgba(139,92,246,0.3)"; }}
                                >
                                    {submitting ? (
                                        <>
                                            <div style={{ width: "16px", height: "16px", borderRadius: "50%", border: "2px solid rgba(255,255,255,0.3)", borderTopColor: "#fff", animation: "rotate-slow 0.8s linear infinite" }} />
                                            Đang xử lý...
                                        </>
                                    ) : step === 1 ? (
                                        <>
                                            Tiếp tục
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
                                        </>
                                    ) : (
                                        <>
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>
                                            Đặt hàng
                                        </>
                                    )}
                                </button>
                            </div>
                        </div>

                        {/* Right column — Order summary */}
                        <div ref={summaryRef} style={{
                            position: "sticky", top: "calc(var(--header-height) + 16px)",
                            borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)",
                            background: "var(--bg-card)", overflow: "hidden",
                        }}>
                            <div style={{ padding: "16px 20px", borderBottom: "1px solid var(--border-color)" }}>
                                <h3 style={{ fontSize: "0.9rem", fontWeight: 700, color: "var(--text-primary)", display: "flex", alignItems: "center", gap: "8px" }}>
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2"><path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" /><line x1="3" y1="6" x2="21" y2="6" /><path d="M16 10a4 4 0 01-8 0" /></svg>
                                    Đơn hàng ({checkoutCount} sản phẩm)
                                </h3>
                            </div>

                            {/* Items list */}
                            <div style={{ maxHeight: "260px", overflowY: "auto", padding: "10px 20px" }}>
                                {checkoutItems.map((item) => {
                                    const unitPrice = item.salePrice > 0 && item.salePrice < item.price ? item.salePrice : item.price;
                                    return (
                                        <div key={`${item.productId}-${item.size}-${item.color}`} style={{
                                            display: "flex", gap: "10px", padding: "8px 0",
                                            borderBottom: "1px solid var(--border-color)",
                                        }}>
                                            <div style={{ width: "48px", height: "58px", borderRadius: "var(--radius-sm)", overflow: "hidden", position: "relative", flexShrink: 0, background: "var(--bg-surface)" }}>
                                                {item.image && <Image src={item.image} alt={item.name} fill sizes="48px" style={{ objectFit: "cover" }} />}
                                            </div>
                                            <div style={{ flex: 1, minWidth: 0 }}>
                                                <p style={{ fontSize: "0.74rem", fontWeight: 600, color: "var(--text-primary)", lineHeight: 1.3, marginBottom: "2px",
                                                    display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
                                                    {item.name}
                                                </p>
                                                <p style={{ fontSize: "0.65rem", color: "var(--text-muted)" }}>
                                                    {item.size} / {item.color} · SL: {item.quantity}
                                                </p>
                                            </div>
                                            <div style={{ flexShrink: 0, textAlign: "right" }}>
                                                <span style={{ fontSize: "0.76rem", fontWeight: 600, color: "var(--text-primary)", display: "block" }}>
                                                    {formatPrice(unitPrice * item.quantity)}
                                                </span>
                                                {item.quantity > 1 && (
                                                    <span style={{ fontSize: "0.62rem", color: "var(--text-muted)" }}>
                                                        {formatPrice(unitPrice)} × {item.quantity}
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>

                            {/* Totals */}
                            <div style={{ padding: "16px 20px", borderTop: "1px solid var(--border-color)" }}>
                                <div style={{ display: "flex", flexDirection: "column", gap: "6px", marginBottom: "12px" }}>
                                    <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.8rem" }}>
                                        <span style={{ color: "var(--text-muted)" }}>Tạm tính</span>
                                        <span style={{ color: "var(--text-primary)", fontWeight: 600 }}>{formatPrice(checkoutTotal)}</span>
                                    </div>
                                    <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.8rem" }}>
                                        <span style={{ color: "var(--text-muted)" }}>Phí vận chuyển</span>
                                        <span style={{ color: "var(--color-accent)", fontWeight: 500 }}>Miễn phí</span>
                                    </div>
                                    {discount > 0 && (
                                        <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.8rem" }}>
                                            <span style={{ color: "var(--text-muted)" }}>Giảm giá {appliedCoupon ? `(${appliedCoupon.code})` : ""}</span>
                                            <span style={{ color: "#22c55e", fontWeight: 600 }}>-{formatPrice(discount)}</span>
                                        </div>
                                    )}
                                </div>
                                <div style={{ display: "flex", justifyContent: "space-between", paddingTop: "10px", borderTop: "1px solid var(--border-color)" }}>
                                    <span style={{ fontSize: "0.92rem", fontWeight: 700, color: "var(--text-primary)" }}>Tổng cộng</span>
                                    <span style={{ fontSize: "1.1rem", fontWeight: 800, color: "var(--color-accent)" }}>{formatPrice(total)}</span>
                                </div>
                            </div>

                            {/* Security badge */}
                            <div style={{ padding: "10px 20px", background: "var(--bg-surface)", borderTop: "1px solid var(--border-color)", display: "flex", alignItems: "center", justifyContent: "center", gap: "6px" }}>
                                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>
                                <span style={{ fontSize: "0.68rem", color: "var(--text-muted)", fontWeight: 500 }}>Thanh toán an toàn & bảo mật</span>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <style jsx global>{`
                @media (max-width: 900px) {
                    .checkout-layout { grid-template-columns: 1fr !important; }
                    .checkout-form-grid { grid-template-columns: 1fr !important; }
                    .checkout-form-grid > div[style*="grid-column"] { grid-column: 1 !important; }
                }
            `}</style>

            {/* Full-screen locating spinner */}
            {locating && (
                <div
                    style={{
                        position: "fixed",
                        inset: 0,
                        zIndex: 9999,
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        justifyContent: "center",
                        gap: "var(--space-lg)",
                        background: "rgba(0,0,0,0.6)",
                        backdropFilter: "blur(8px)",
                    }}
                >
                    <div
                        style={{
                            width: "52px",
                            height: "52px",
                            borderRadius: "50%",
                            border: "4px solid rgba(139,92,246,0.15)",
                            borderTopColor: "var(--color-accent)",
                            animation: "rotate-slow 0.8s linear infinite",
                            boxShadow: "0 0 30px rgba(139,92,246,0.3)",
                        }}
                    />
                    <p style={{
                        fontSize: "0.95rem",
                        fontWeight: 600,
                        color: "#fff",
                        letterSpacing: "0.02em",
                    }}>
                        Đang xác định vị trí...
                    </p>
                </div>
            )}
        </>
    );
}
