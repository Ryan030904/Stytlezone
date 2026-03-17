"use client";

import { useState, useEffect } from "react";
import { collection, query, where, getDocs, Timestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";
import Image from "next/image";

interface OrderItem {
    productId: string;
    productName: string;
    imageUrl: string;
    price: number;
    quantity: number;
    size: string;
    color: string;
}

interface Order {
    id: string;
    items: OrderItem[];
    total: number;
    status: string;
    paymentMethod: string;
    createdAt: Date;
    shippingAddress: string;
}

const STATUS_MAP: Record<string, { label: string; color: string; bg: string }> = {
    pending: { label: "Chờ xác nhận", color: "#f59e0b", bg: "rgba(245,158,11,0.1)" },
    confirmed: { label: "Đã xác nhận", color: "#3b82f6", bg: "rgba(59,130,246,0.1)" },
    shipping: { label: "Đang giao", color: "#8B5CF6", bg: "rgba(139,92,246,0.1)" },
    delivered: { label: "Đã giao", color: "#22c55e", bg: "rgba(34,197,94,0.1)" },
    cancelled: { label: "Đã hủy", color: "#ef4444", bg: "rgba(239,68,68,0.1)" },
};

const STATUS_FILTERS = [
    { key: "all", label: "Tất cả" },
    { key: "pending", label: "Chờ xác nhận" },
    { key: "confirmed", label: "Đã xác nhận" },
    { key: "shipping", label: "Đang giao" },
    { key: "delivered", label: "Đã giao" },
    { key: "cancelled", label: "Đã hủy" },
];

function formatPrice(n: number) { return new Intl.NumberFormat("vi-VN").format(n) + "đ"; }

export default function OrdersTab({ userEmail }: { userEmail: string }) {
    const [orders, setOrders] = useState<Order[]>([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState("all");

    useEffect(() => {
        if (!userEmail) return;
        (async () => {
            try {
                const q = query(
                    collection(db, "orders"),
                    where("customerEmail", "==", userEmail),
                );
                const snap = await getDocs(q);
                setOrders(snap.docs.map((d) => {
                    const data = d.data();
                    return {
                        id: d.id,
                        items: (data.items || []) as OrderItem[],
                        total: Number(data.total || 0),
                        status: (data.status as string) || "pending",
                        paymentMethod: (data.paymentMethod as string) || "cod",
                        createdAt: data.createdAt instanceof Timestamp ? data.createdAt.toDate() : new Date(),
                        shippingAddress: (data.shippingAddress as string) || "",
                    };
                }));
                // Sort client-side (newest first)
                setOrders((prev) => [...prev].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime()));
            } catch (err) {
                console.error("Failed to fetch orders:", err);
            } finally {
                setLoading(false);
            }
        })();
    }, [userEmail]);

    const filtered = filter === "all" ? orders : orders.filter((o) => o.status === filter);

    return (
        <div>
            <h2 style={{ fontSize: "1.2rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "var(--space-lg)" }}>Đơn Mua</h2>

            {/* Status filter tabs */}
            <div style={{ display: "flex", gap: "4px", marginBottom: "var(--space-xl)", overflowX: "auto", borderBottom: "1px solid var(--border-color)", paddingBottom: "0" }}>
                {STATUS_FILTERS.map((f) => (
                    <button key={f.key} onClick={() => setFilter(f.key)}
                        style={{
                            padding: "8px 16px", border: "none", background: "transparent", cursor: "pointer",
                            fontSize: "0.82rem", fontWeight: filter === f.key ? 600 : 400,
                            color: filter === f.key ? "var(--color-accent)" : "var(--text-secondary)",
                            borderBottom: filter === f.key ? "2px solid var(--color-accent)" : "2px solid transparent",
                            transition: "all 0.15s", whiteSpace: "nowrap",
                        }}>
                        {f.label}
                    </button>
                ))}
            </div>

            {loading ? (
                <div style={{ textAlign: "center", padding: "var(--space-3xl)", color: "var(--text-muted)" }}>
                    <div style={{ width: "32px", height: "32px", border: "3px solid var(--border-color)", borderTopColor: "var(--color-accent)", borderRadius: "50%", animation: "spin 0.8s linear infinite", margin: "0 auto var(--space-md)" }} />
                    Đang tải đơn hàng...
                </div>
            ) : filtered.length === 0 ? (
                <div style={{ textAlign: "center", padding: "var(--space-4xl)", color: "var(--text-muted)" }}>
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2" style={{ margin: "0 auto var(--space-md)", opacity: 0.4 }}>
                        <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" /><line x1="3" y1="6" x2="21" y2="6" /><path d="M16 10a4 4 0 0 1-8 0" />
                    </svg>
                    <p style={{ fontSize: "0.9rem" }}>Chưa có đơn hàng nào</p>
                </div>
            ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-md)" }}>
                    {filtered.map((order) => {
                        const st = STATUS_MAP[order.status] || STATUS_MAP.pending;
                        return (
                            <div key={order.id} style={{ borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)", background: "var(--bg-card)", overflow: "hidden" }}>
                                {/* Order header */}
                                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px var(--space-lg)", borderBottom: "1px solid var(--border-color)", background: "var(--bg-elevated)" }}>
                                    <span style={{ fontSize: "0.78rem", color: "var(--text-muted)" }}>
                                        {order.createdAt.toLocaleDateString("vi-VN")} • #{order.id.slice(-8).toUpperCase()}
                                    </span>
                                    <span style={{ fontSize: "0.75rem", fontWeight: 600, color: st.color, background: st.bg, padding: "3px 10px", borderRadius: "var(--radius-full)" }}>
                                        {st.label}
                                    </span>
                                </div>
                                {/* Items */}
                                <div style={{ padding: "var(--space-md) var(--space-lg)" }}>
                                    {order.items.map((item, i) => (
                                        <div key={i} style={{ display: "flex", gap: "var(--space-md)", padding: "8px 0", borderBottom: i < order.items.length - 1 ? "1px solid var(--border-color)" : "none" }}>
                                            <div style={{ width: "60px", height: "60px", borderRadius: "var(--radius-md)", overflow: "hidden", flexShrink: 0, position: "relative", background: "var(--bg-elevated)" }}>
                                                {item.imageUrl && <Image src={item.imageUrl} alt={item.productName} fill sizes="60px" style={{ objectFit: "cover" }} />}
                                            </div>
                                            <div style={{ flex: 1, minWidth: 0 }}>
                                                <p style={{ fontSize: "0.85rem", fontWeight: 500, color: "var(--text-primary)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{item.productName}</p>
                                                <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: "2px" }}>
                                                    {item.color && `${item.color}`}{item.size && ` • ${item.size}`} • x{item.quantity}
                                                </p>
                                            </div>
                                            <p style={{ fontSize: "0.85rem", fontWeight: 600, color: "var(--color-accent)", flexShrink: 0 }}>{formatPrice(item.price)}</p>
                                        </div>
                                    ))}
                                </div>
                                {/* Total */}
                                <div style={{ display: "flex", justifyContent: "flex-end", alignItems: "center", gap: "var(--space-sm)", padding: "12px var(--space-lg)", borderTop: "1px solid var(--border-color)" }}>
                                    <span style={{ fontSize: "0.82rem", color: "var(--text-secondary)" }}>Tổng:</span>
                                    <span style={{ fontSize: "1.05rem", fontWeight: 700, color: "var(--color-accent)" }}>{formatPrice(order.total)}</span>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
