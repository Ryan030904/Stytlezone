import { db } from "@/lib/firebase";
import {
    collection,
    query,
    where,
    getDocs,
    doc,
    getDoc,
    updateDoc,
    Timestamp,
} from "firebase/firestore";
import { addNotification } from "./notifications";

/* ─── Rank Definitions ─── */
export const RANKS = [
    { key: "member", label: "Thành Viên", min: 0, max: 999999, color: "#71717a", icon: "🏷️" },
    { key: "silver", label: "Bạc", min: 1000000, max: 4999999, color: "#94a3b8", icon: "🥈" },
    { key: "gold", label: "Vàng", min: 5000000, max: 14999999, color: "#f59e0b", icon: "🥇" },
    { key: "diamond", label: "Kim Cương", min: 15000000, max: Infinity, color: "#8B5CF6", icon: "💎" },
] as const;

const INACTIVITY_MONTHS = 6;

function getRankBySpending(totalSpent: number) {
    for (let i = RANKS.length - 1; i >= 0; i--) {
        if (totalSpent >= RANKS[i].min) return { rank: RANKS[i], index: i };
    }
    return { rank: RANKS[0], index: 0 };
}

function getRankByKey(key: string) {
    return RANKS.find((r) => r.key === key) ?? RANKS[0];
}

function formatPrice(n: number) {
    return new Intl.NumberFormat("vi-VN").format(n) + "đ";
}

/* ─── Get total spent from delivered orders ─── */
async function getTotalSpent(email: string) {
    const q = query(
        collection(db, "orders"),
        where("customerEmail", "==", email),
        where("status", "==", "delivered"),
    );
    const snap = await getDocs(q);
    let total = 0;
    let lastPurchaseDate: Date | null = null;
    snap.docs.forEach((d) => {
        const data = d.data();
        total += Number(data.total || 0);
        const createdAt = data.createdAt?.toDate?.();
        if (createdAt && (!lastPurchaseDate || createdAt > lastPurchaseDate)) {
            lastPurchaseDate = createdAt;
        }
    });
    return { total, lastPurchaseDate, orderCount: snap.size };
}

/* ─── Check and update rank (call when user loads their account) ─── */
export async function checkAndUpdateRank(uid: string, email: string): Promise<{
    changed: boolean;
    oldRank: string;
    newRank: string;
    totalSpent: number;
    lastPurchaseDate: Date | null;
}> {
    const { total, lastPurchaseDate } = await getTotalSpent(email);
    const { rank: calculatedRank } = getRankBySpending(total);

    // Get current stored rank
    const userRef = doc(db, "users", uid);
    const userSnap = await getDoc(userRef);
    const currentRankKey = userSnap.exists() ? (userSnap.data().rankKey as string ?? "member") : "member";
    const currentRank = getRankByKey(currentRankKey);

    const result = {
        changed: false,
        oldRank: currentRankKey,
        newRank: calculatedRank.key,
        totalSpent: total,
        lastPurchaseDate,
    };

    // Only upgrade (not downgrade via this function — downgrade is via inactivity reset)
    if (RANKS.findIndex(r => r.key === calculatedRank.key) > RANKS.findIndex(r => r.key === currentRankKey)) {
        await updateDoc(userRef, {
            rankKey: calculatedRank.key,
            rankUpdatedAt: Timestamp.now(),
        });

        // Send rank-up notification
        await addNotification(uid, {
            type: "rank_up",
            title: `Chúc mừng! Bạn đã lên hạng ${calculatedRank.label} ${calculatedRank.icon}`,
            message: `Tổng chi tiêu ${formatPrice(total)} — Bạn từ hạng ${currentRank.label} lên ${calculatedRank.label}. Hãy khám phá các ưu đãi mới!`,
            link: "/tai-khoan",
        });

        result.changed = true;
    } else if (currentRankKey === "member" && calculatedRank.key === "member") {
        // Ensure rankKey is stored if not yet
        if (!userSnap.exists() || !userSnap.data().rankKey) {
            await updateDoc(userRef, { rankKey: "member" });
        }
    }

    return result;
}

/* ─── Check 6-month inactivity and reset rank ─── */
export async function checkInactivityReset(uid: string, email: string): Promise<{
    wasReset: boolean;
    daysUntilReset: number | null;
    lastPurchaseDate: Date | null;
}> {
    const { lastPurchaseDate } = await getTotalSpent(email);
    const now = new Date();

    // Get current rank
    const userRef = doc(db, "users", uid);
    const userSnap = await getDoc(userRef);
    if (!userSnap.exists()) return { wasReset: false, daysUntilReset: null, lastPurchaseDate };

    const data = userSnap.data();
    const currentRankKey = (data.rankKey as string) ?? "member";

    // If already member, nothing to reset
    if (currentRankKey === "member") {
        return { wasReset: false, daysUntilReset: null, lastPurchaseDate };
    }

    // If no purchases at all, calculate from account creation
    const referenceDate = lastPurchaseDate ?? (data.createdAt?.toDate?.() as Date | null) ?? now;
    const sixMonthsLater = new Date(referenceDate);
    sixMonthsLater.setMonth(sixMonthsLater.getMonth() + INACTIVITY_MONTHS);

    const daysUntilReset = Math.ceil((sixMonthsLater.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));

    // Check if already reset recently (prevent duplicate resets)
    const lastResetAt = data.lastRankResetAt?.toDate?.() as Date | null;
    if (lastResetAt && (now.getTime() - lastResetAt.getTime()) < 1000 * 60 * 60 * 24) {
        // Already reset within last 24h
        return { wasReset: false, daysUntilReset: Math.max(0, daysUntilReset), lastPurchaseDate };
    }

    if (daysUntilReset <= 0) {
        // Reset rank to member
        const oldRank = getRankByKey(currentRankKey);
        await updateDoc(userRef, {
            rankKey: "member",
            rankUpdatedAt: Timestamp.now(),
            lastRankResetAt: Timestamp.now(),
        });

        await addNotification(uid, {
            type: "rank_reset",
            title: "Hạng thành viên đã được đặt lại",
            message: `Hạng ${oldRank.label} đã bị reset về Thành Viên do không có đơn hàng trong ${INACTIVITY_MONTHS} tháng. Hãy mua sắm để lên hạng lại nhé!`,
            link: "/tai-khoan",
        });

        return { wasReset: true, daysUntilReset: 0, lastPurchaseDate };
    }

    // Send warning notification if <= 30 days left (once per week)
    if (daysUntilReset <= 30) {
        const lastWarningAt = data.lastRankWarningAt?.toDate?.() as Date | null;
        const weekMs = 7 * 24 * 60 * 60 * 1000;
        if (!lastWarningAt || (now.getTime() - lastWarningAt.getTime()) >= weekMs) {
            const currentRank = getRankByKey(currentRankKey);
            await addNotification(uid, {
                type: "rank_reset_warning",
                title: `Cảnh báo: Hạng ${currentRank.label} sắp bị reset!`,
                message: `Còn ${daysUntilReset} ngày trước khi hạng ${currentRank.label} bị reset về Thành Viên. Hãy đặt đơn để giữ hạng!`,
                link: "/san-pham",
            });
            await updateDoc(userRef, { lastRankWarningAt: Timestamp.now() });
        }
    }

    return { wasReset: false, daysUntilReset: Math.max(0, daysUntilReset), lastPurchaseDate };
}
