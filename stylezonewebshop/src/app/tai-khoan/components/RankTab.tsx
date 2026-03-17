"use client";

import { useState, useEffect } from "react";
import { collection, query, where, getDocs } from "firebase/firestore";
import { db } from "@/lib/firebase";

const RANKS = [
    { key: "member", label: "Thành Viên", min: 0, max: 999999, color: "#71717a", icon: "🏷️", benefits: ["Tích điểm cơ bản", "Ưu đãi sinh nhật"] },
    { key: "silver", label: "Bạc", min: 1000000, max: 4999999, color: "#94a3b8", icon: "🥈", benefits: ["Freeship đơn từ 300K", "Ưu đãi 5% ngày thứ 2", "Voucher sinh nhật 50K"] },
    { key: "gold", label: "Vàng", min: 5000000, max: 14999999, color: "#f59e0b", icon: "🥇", benefits: ["Freeship mọi đơn", "Ưu đãi 10% thứ 2 & 6", "Voucher sinh nhật 150K", "Early access sale"] },
    { key: "diamond", label: "Kim Cương", min: 15000000, max: Infinity, color: "#8B5CF6", icon: "💎", benefits: ["Freeship + hoàn tiền 2%", "Ưu đãi 15% mọi ngày", "Voucher sinh nhật 500K", "Early access sale", "Tư vấn stylist riêng"] },
];

function formatPrice(n: number) { return new Intl.NumberFormat("vi-VN").format(n) + "đ"; }

function getRank(totalSpent: number) {
    for (let i = RANKS.length - 1; i >= 0; i--) {
        if (totalSpent >= RANKS[i].min) return { rank: RANKS[i], index: i };
    }
    return { rank: RANKS[0], index: 0 };
}

export default function RankTab({ userEmail }: { userEmail: string }) {
    const [totalSpent, setTotalSpent] = useState(0);
    const [orderCount, setOrderCount] = useState(0);
    const [loading, setLoading] = useState(true);
    const [lastPurchaseDate, setLastPurchaseDate] = useState<Date | null>(null);
    const [daysUntilReset, setDaysUntilReset] = useState<number | null>(null);

    useEffect(() => {
        if (!userEmail) return;
        (async () => {
            try {
                const q = query(
                    collection(db, "orders"),
                    where("customerEmail", "==", userEmail),
                    where("status", "==", "delivered"),
                );
                const snap = await getDocs(q);
                let sum = 0;
                let latestDate: Date | null = null;
                snap.docs.forEach((d) => {
                    const data = d.data();
                    sum += Number(data.total || 0);
                    const date = data.createdAt?.toDate?.();
                    if (date && (!latestDate || date > latestDate)) {
                        latestDate = date;
                    }
                });
                setTotalSpent(sum);
                setOrderCount(snap.size);
                setLastPurchaseDate(latestDate);

                // Calculate days until rank reset (6 months from last purchase)
                if (latestDate) {
                    const sixMonthsLater = new Date(latestDate);
                    sixMonthsLater.setMonth(sixMonthsLater.getMonth() + 6);
                    const days = Math.ceil((sixMonthsLater.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
                    setDaysUntilReset(days);
                }
            } catch (err) {
                console.error("Failed to calc rank:", err);
            } finally {
                setLoading(false);
            }
        })();
    }, [userEmail]);

    const { rank: currentRank, index: rankIndex } = getRank(totalSpent);
    const nextRank = rankIndex < RANKS.length - 1 ? RANKS[rankIndex + 1] : null;
    const progressPercent = nextRank
        ? Math.min(100, ((totalSpent - currentRank.min) / (nextRank.min - currentRank.min)) * 100)
        : 100;
    const amountToNext = nextRank ? Math.max(0, nextRank.min - totalSpent) : 0;

    if (loading) {
        return (
            <div style={{ textAlign: "center", padding: "var(--space-4xl)", color: "var(--text-muted)" }}>
                <div style={{ width: "32px", height: "32px", border: "3px solid var(--border-color)", borderTopColor: "var(--color-accent)", borderRadius: "50%", animation: "spin 0.8s linear infinite", margin: "0 auto var(--space-md)" }} />
                Đang tải...
            </div>
        );
    }

    return (
        <div>
            <h2 style={{ fontSize: "1.2rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "4px" }}>Hạng Thành Viên</h2>
            <p style={{ fontSize: "0.82rem", color: "var(--text-muted)", marginBottom: "var(--space-xl)" }}>Xem hạng và quyền lợi thành viên của bạn</p>

            {/* Inactivity Warning */}
            {currentRank.key !== "member" && daysUntilReset !== null && daysUntilReset <= 60 && (
                <div style={{
                    borderRadius: "var(--radius-lg)",
                    padding: "var(--space-lg)",
                    marginBottom: "var(--space-xl)",
                    background: daysUntilReset <= 0
                        ? "rgba(239,68,68,0.08)"
                        : daysUntilReset <= 30
                            ? "rgba(245,158,11,0.08)"
                            : "rgba(59,130,246,0.06)",
                    border: `1px solid ${daysUntilReset <= 0 ? "rgba(239,68,68,0.25)" : daysUntilReset <= 30 ? "rgba(245,158,11,0.25)" : "rgba(59,130,246,0.15)"}`,
                    display: "flex", alignItems: "flex-start", gap: "12px",
                }}>
                    <span style={{ fontSize: "1.3rem", flexShrink: 0 }}>
                        {daysUntilReset <= 0 ? "🚨" : daysUntilReset <= 30 ? "⚠️" : "ℹ️"}
                    </span>
                    <div>
                        <p style={{
                            fontSize: "0.82rem", fontWeight: 700, marginBottom: "4px",
                            color: daysUntilReset <= 0 ? "#ef4444" : daysUntilReset <= 30 ? "#f59e0b" : "var(--text-primary)",
                        }}>
                            {daysUntilReset <= 0
                                ? "Hạng thành viên đã bị reset!"
                                : `Còn ${daysUntilReset} ngày trước khi bị reset hạng`
                            }
                        </p>
                        <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", lineHeight: 1.5 }}>
                            {daysUntilReset <= 0
                                ? `Hạng ${currentRank.label} đã bị reset về Thành Viên do không có đơn hàng trong 6 tháng.`
                                : `Hạng ${currentRank.label} sẽ bị reset về Thành Viên nếu bạn không mua hàng trước ngày ${lastPurchaseDate ? (() => { const d = new Date(lastPurchaseDate); d.setMonth(d.getMonth() + 6); return d.toLocaleDateString("vi-VN"); })() : "N/A"}. Hãy mua sắm để giữ hạng!`
                            }
                        </p>
                    </div>
                </div>
            )}

            {/* Current rank card */}
            <div style={{
                borderRadius: "var(--radius-xl)", overflow: "hidden",
                background: `linear-gradient(135deg, ${currentRank.color}18, ${currentRank.color}08)`,
                border: `1px solid ${currentRank.color}30`,
                padding: "var(--space-2xl)", marginBottom: "var(--space-xl)",
            }}>
                <div style={{ display: "flex", alignItems: "center", gap: "var(--space-lg)", marginBottom: "var(--space-xl)" }}>
                    <div style={{ fontSize: "2.5rem" }}>{currentRank.icon}</div>
                    <div>
                        <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", fontWeight: 500, letterSpacing: "0.08em", textTransform: "uppercase", marginBottom: "2px" }}>Hạng hiện tại</p>
                        <h3 style={{ fontSize: "1.5rem", fontWeight: 800, color: currentRank.color }}>{currentRank.label}</h3>
                    </div>
                </div>

                {/* Stats */}
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "var(--space-md)", marginBottom: "var(--space-xl)" }}>
                    <div style={{ padding: "var(--space-lg)", borderRadius: "var(--radius-lg)", background: "var(--bg-card)", border: "1px solid var(--border-color)" }}>
                        <p style={{ fontSize: "0.72rem", color: "var(--text-muted)", marginBottom: "4px" }}>Tổng chi tiêu</p>
                        <p style={{ fontSize: "1.1rem", fontWeight: 800, color: "var(--color-accent)" }}>{formatPrice(totalSpent)}</p>
                    </div>
                    <div style={{ padding: "var(--space-lg)", borderRadius: "var(--radius-lg)", background: "var(--bg-card)", border: "1px solid var(--border-color)" }}>
                        <p style={{ fontSize: "0.72rem", color: "var(--text-muted)", marginBottom: "4px" }}>Đơn hoàn thành</p>
                        <p style={{ fontSize: "1.1rem", fontWeight: 800, color: "var(--text-primary)" }}>{orderCount}</p>
                    </div>
                    <div style={{ padding: "var(--space-lg)", borderRadius: "var(--radius-lg)", background: "var(--bg-card)", border: "1px solid var(--border-color)" }}>
                        <p style={{ fontSize: "0.72rem", color: "var(--text-muted)", marginBottom: "4px" }}>Mua gần nhất</p>
                        <p style={{ fontSize: "0.82rem", fontWeight: 700, color: "var(--text-primary)" }}>
                            {lastPurchaseDate ? lastPurchaseDate.toLocaleDateString("vi-VN") : "Chưa có"}
                        </p>
                    </div>
                </div>

                {/* Progress to next rank */}
                {nextRank && (
                    <div>
                        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "6px" }}>
                            <span style={{ fontSize: "0.78rem", color: "var(--text-secondary)" }}>Tiến độ lên <strong style={{ color: nextRank.color }}>{nextRank.label}</strong></span>
                            <span style={{ fontSize: "0.78rem", fontWeight: 600, color: "var(--text-muted)" }}>{Math.round(progressPercent)}%</span>
                        </div>
                        <div style={{ height: "8px", borderRadius: "4px", background: "var(--bg-elevated)", overflow: "hidden" }}>
                            <div style={{ height: "100%", width: `${progressPercent}%`, borderRadius: "4px", background: `linear-gradient(90deg, ${currentRank.color}, ${nextRank.color})`, transition: "width 1s ease" }} />
                        </div>
                        <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: "6px" }}>
                            Cần thêm <strong style={{ color: "var(--color-accent)" }}>{formatPrice(amountToNext)}</strong> để lên hạng {nextRank.label}
                        </p>
                    </div>
                )}
                {!nextRank && (
                    <p style={{ fontSize: "0.82rem", color: currentRank.color, fontWeight: 600 }}>🎉 Bạn đã đạt hạng cao nhất!</p>
                )}
            </div>

            {/* Rank reset policy notice */}
            <div style={{
                borderRadius: "var(--radius-lg)",
                padding: "var(--space-md) var(--space-lg)",
                marginBottom: "var(--space-xl)",
                background: "rgba(139,92,246,0.04)",
                border: "1px solid rgba(139,92,246,0.1)",
                display: "flex", alignItems: "center", gap: "10px",
            }}>
                <span style={{ fontSize: "1rem" }}>📋</span>
                <p style={{ fontSize: "0.72rem", color: "var(--text-muted)", lineHeight: 1.5 }}>
                    <strong style={{ color: "var(--text-secondary)" }}>Chính sách:</strong> Hạng thành viên sẽ được reset về Thành Viên nếu không có đơn hàng hoàn thành trong vòng <strong>6 tháng</strong>. Hãy duy trì mua sắm để giữ và nâng hạng!
                </p>
            </div>

            {/* Rank tiers — compact */}
            <h3 style={{ fontSize: "1rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "var(--space-md)" }}>Bảng Hạng Thành Viên</h3>
            <div style={{ borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)", overflow: "hidden" }}>
                {RANKS.map((r, i) => {
                    const isCurrent = r.key === currentRank.key;
                    return (
                        <div key={r.key} style={{
                            display: "flex", alignItems: "center", gap: "var(--space-sm)",
                            padding: "10px 14px",
                            background: isCurrent ? `${r.color}0a` : "var(--bg-card)",
                            borderBottom: i < RANKS.length - 1 ? "1px solid var(--border-color)" : "none",
                            borderLeft: isCurrent ? `3px solid ${r.color}` : "3px solid transparent",
                        }}>
                            <span style={{ fontSize: "1rem", width: "24px", textAlign: "center", flexShrink: 0 }}>{r.icon}</span>
                            <span style={{ fontWeight: 700, fontSize: "0.82rem", color: r.color, minWidth: "70px" }}>{r.label}</span>
                            {isCurrent && <span style={{ fontSize: "0.6rem", fontWeight: 600, background: `${r.color}20`, color: r.color, padding: "1px 6px", borderRadius: "var(--radius-full)" }}>Hiện tại</span>}
                            <span style={{ fontSize: "0.7rem", color: "var(--text-muted)", marginLeft: "auto", flexShrink: 0 }}>
                                {r.max === Infinity ? `Từ ${formatPrice(r.min)}` : `${formatPrice(r.min)} — ${formatPrice(r.max)}`}
                            </span>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}

