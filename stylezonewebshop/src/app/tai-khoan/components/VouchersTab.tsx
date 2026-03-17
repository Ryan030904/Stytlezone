"use client";

import { useState, useEffect } from "react";
import { getSavedVouchers, removeSavedVoucher, type SavedVoucher } from "@/lib/savedVouchers";
import { toast } from "sonner";

function formatPrice(n: number) { return new Intl.NumberFormat("vi-VN").format(n) + "đ"; }

export default function VouchersTab({ uid }: { uid: string }) {
    const [vouchers, setVouchers] = useState<SavedVoucher[]>([]);
    const [loading, setLoading] = useState(true);
    const [removingId, setRemovingId] = useState<string | null>(null);

    useEffect(() => {
        if (!uid) return;
        getSavedVouchers(uid)
            .then(setVouchers)
            .catch((err) => console.error("Failed to fetch saved vouchers:", err))
            .finally(() => setLoading(false));
    }, [uid]);

    const handleRemove = async (id: string) => {
        setRemovingId(id);
        try {
            await removeSavedVoucher(uid, id);
            setVouchers((prev) => prev.filter((v) => v.id !== id));
            toast.success("Đã xoá voucher");
        } catch {
            toast.error("Xoá thất bại, thử lại sau");
        } finally {
            setRemovingId(null);
        }
    };

    const copyCode = (code: string) => {
        navigator.clipboard.writeText(code);
        toast.success(`Đã sao chép mã: ${code}`);
    };

    if (loading) {
        return (
            <div style={{ textAlign: "center", padding: "var(--space-4xl)", color: "var(--text-muted)" }}>
                <div style={{ width: "32px", height: "32px", border: "3px solid var(--border-color)", borderTopColor: "var(--color-accent)", borderRadius: "50%", animation: "spin 0.8s linear infinite", margin: "0 auto var(--space-md)" }} />
                Đang tải voucher...
            </div>
        );
    }

    return (
        <div>
            <h2 style={{ fontSize: "1.2rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "4px" }}>Kho Voucher</h2>
            <p style={{ fontSize: "0.82rem", color: "var(--text-muted)", marginBottom: "var(--space-xl)" }}>Các mã giảm giá bạn đã lưu</p>

            {vouchers.length === 0 ? (
                <div style={{ textAlign: "center", padding: "var(--space-4xl)", color: "var(--text-muted)" }}>
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2" style={{ margin: "0 auto var(--space-md)", opacity: 0.4 }}>
                        <rect x="1" y="4" width="22" height="16" rx="2" ry="2" /><line x1="1" y1="10" x2="23" y2="10" />
                    </svg>
                    <p style={{ fontSize: "0.9rem", marginBottom: "8px" }}>Chưa có voucher nào được lưu</p>
                    <p style={{ fontSize: "0.78rem", color: "var(--text-muted)" }}>Lưu voucher từ trang Sale để sử dụng khi thanh toán</p>
                </div>
            ) : (
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-md)" }}>
                    {vouchers.map((voucher) => {
                        const discountText = voucher.discountType === "percent"
                            ? `Giảm ${voucher.discountValue}%`
                            : `Giảm ${formatPrice(voucher.discountValue)}`;
                        const isRemoving = removingId === voucher.id;
                        return (
                            <div key={voucher.id} style={{
                                borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)",
                                background: "var(--bg-card)", overflow: "hidden",
                                display: "flex", flexDirection: "column",
                            }}>
                                <div style={{ padding: "var(--space-lg)", borderLeft: `4px solid ${voucher.color}` }}>
                                    <p style={{ fontSize: "1rem", fontWeight: 700, color: voucher.color, marginBottom: "4px" }}>{discountText}</p>
                                    <p style={{ fontSize: "0.8rem", color: "var(--text-primary)", fontWeight: 500, marginBottom: "6px" }}>{voucher.label}</p>
                                    {voucher.minOrderAmount > 0 && (
                                        <p style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>Đơn tối thiểu {formatPrice(voucher.minOrderAmount)}</p>
                                    )}
                                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "var(--space-sm)" }}>
                                        <button onClick={() => copyCode(voucher.code)}
                                            style={{
                                                padding: "4px 12px", borderRadius: "var(--radius-sm)",
                                                background: `${voucher.color}15`, border: `1px solid ${voucher.color}30`,
                                                color: voucher.color, fontSize: "0.72rem", fontWeight: 600,
                                                cursor: "pointer", transition: "all 0.15s",
                                            }}
                                            onMouseEnter={(e) => { e.currentTarget.style.background = `${voucher.color}25`; }}
                                            onMouseLeave={(e) => { e.currentTarget.style.background = `${voucher.color}15`; }}>
                                            {voucher.code}
                                        </button>
                                        <button
                                            onClick={() => handleRemove(voucher.id)}
                                            disabled={isRemoving}
                                            style={{
                                                padding: "4px 10px", borderRadius: "var(--radius-sm)",
                                                background: "rgba(239,68,68,0.06)", border: "1px solid rgba(239,68,68,0.2)",
                                                color: "#ef4444", fontSize: "0.68rem", fontWeight: 600,
                                                cursor: isRemoving ? "not-allowed" : "pointer",
                                                opacity: isRemoving ? 0.5 : 1,
                                                transition: "all 0.15s",
                                            }}
                                            onMouseEnter={(e) => { if (!isRemoving) e.currentTarget.style.background = "rgba(239,68,68,0.12)"; }}
                                            onMouseLeave={(e) => { e.currentTarget.style.background = "rgba(239,68,68,0.06)"; }}
                                        >
                                            {isRemoving ? "..." : "Xoá"}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
