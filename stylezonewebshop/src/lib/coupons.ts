import { db } from "@/lib/firebase";
import {
    collection,
    query,
    where,
    getDocs,
    doc,
    updateDoc,
    increment,
    Timestamp,
} from "firebase/firestore";

/* ─── Types ─── */
export interface Coupon {
    id: string;
    code: string;
    name: string;
    description: string;
    discountType: "percent" | "fixed";
    discountValue: number;
    minOrderAmount: number;
    maxUses: number;       // 0 = unlimited
    usedCount: number;
    isActive: boolean;
    startDate: Date;
    endDate: Date;
}

export interface CouponValidationResult {
    isValid: boolean;
    message: string;
    coupon: Coupon | null;
    discountAmount: number;
}

/* ─── Parse Firestore doc → Coupon ─── */
function parseCoupon(docSnap: { id: string; data: () => Record<string, unknown> }): Coupon {
    const d = docSnap.data() as Record<string, unknown>;
    return {
        id: docSnap.id,
        code: (d.code as string) ?? "",
        name: (d.name as string) ?? "",
        description: (d.description as string) ?? "",
        discountType: (d.discountType as "percent" | "fixed") ?? "percent",
        discountValue: Number(d.discountValue ?? 0),
        minOrderAmount: Number(d.minOrderAmount ?? 0),
        maxUses: Number(d.maxUses ?? 0),
        usedCount: Number(d.usedCount ?? 0),
        isActive: (d.isActive as boolean) ?? true,
        startDate: d.startDate instanceof Timestamp ? d.startDate.toDate() : new Date(),
        endDate: d.endDate instanceof Timestamp ? d.endDate.toDate() : new Date(),
    };
}

/**
 * Fetch all active promotions from Firestore `promotions` collection.
 * Filters: isActive, not deleted, within date range, and not exhausted.
 */
export async function fetchActiveCoupons(): Promise<Coupon[]> {
    const q = query(
        collection(db, "promotions"),
        where("isActive", "==", true),
    );
    const snap = await getDocs(q);
    const now = new Date();

    return snap.docs
        .map((d) => parseCoupon(d))
        .filter((c) => {
            // Skip soft-deleted
            const raw = snap.docs.find((dd) => dd.id === c.id)?.data();
            if (raw && raw.isDeleted === true) return false;
            // Must be within date range
            if (now < c.startDate || now > c.endDate) return false;
            // Must not be exhausted (0 = unlimited)
            if (c.maxUses > 0 && c.usedCount >= c.maxUses) return false;
            return true;
        });
}

/**
 * Validate a coupon/promotion code against the order total.
 * Checks: active, date range, usage limit, min order amount.
 * Calculates discount correctly for both percent and fixed types.
 */
export function validateCoupon(
    coupon: Coupon,
    orderTotal: number,
): CouponValidationResult {
    const now = new Date();

    if (!coupon.isActive) {
        return { isValid: false, message: "Mã giảm giá đã tắt", coupon: null, discountAmount: 0 };
    }
    if (now < coupon.startDate) {
        return { isValid: false, message: "Mã chưa tới thời gian áp dụng", coupon: null, discountAmount: 0 };
    }
    if (now > coupon.endDate) {
        return { isValid: false, message: "Mã giảm giá đã hết hạn", coupon: null, discountAmount: 0 };
    }
    if (coupon.maxUses > 0 && coupon.usedCount >= coupon.maxUses) {
        return { isValid: false, message: "Mã đã hết lượt sử dụng", coupon: null, discountAmount: 0 };
    }
    if (orderTotal < coupon.minOrderAmount) {
        return {
            isValid: false,
            message: `Đơn tối thiểu ${formatVND(coupon.minOrderAmount)}`,
            coupon,
            discountAmount: 0,
        };
    }

    // Calculate discount
    let discount = 0;
    if (coupon.discountType === "percent") {
        // Percent: e.g. 50% of 200,000đ = 100,000đ
        discount = orderTotal * (coupon.discountValue / 100);
    } else {
        // Fixed: e.g. reduce exactly 50,000đ
        discount = coupon.discountValue;
    }

    // Discount cannot exceed order total
    if (discount > orderTotal) discount = orderTotal;

    return {
        isValid: true,
        message: "Áp dụng mã thành công!",
        coupon,
        discountAmount: Math.round(discount),
    };
}

/**
 * Mark a promotion as used — increment usedCount by 1.
 * Uses atomic Firestore increment to prevent race conditions.
 */
export async function markCouponUsed(couponId: string): Promise<void> {
    const ref = doc(db, "promotions", couponId);
    await updateDoc(ref, {
        usedCount: increment(1),
        updatedAt: Timestamp.now(),
    });
}

function formatVND(n: number): string {
    return n.toLocaleString("vi-VN") + "đ";
}
