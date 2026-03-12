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
    description: string;
    discountType: "percent" | "fixed";
    discountValue: number;
    minOrderAmount: number;
    maxDiscountAmount: number;
    usageLimit: number;
    usedCount: number;
    isActive: boolean;
    startDate: Date;
    endDate: Date;
    requiredRank: string;
}

export interface CouponValidationResult {
    isValid: boolean;
    message: string;
    coupon: Coupon | null;
    discountAmount: number;
}

/* ─── Helpers ─── */
function parseCoupon(docSnap: { id: string; data: () => Record<string, unknown> }): Coupon {
    const d = docSnap.data() as Record<string, unknown>;
    return {
        id: docSnap.id,
        code: (d.code as string) ?? "",
        description: (d.description as string) ?? "",
        discountType: (d.discountType as "percent" | "fixed") ?? "percent",
        discountValue: Number(d.discountValue ?? 0),
        minOrderAmount: Number(d.minOrderAmount ?? 0),
        maxDiscountAmount: Number(d.maxDiscountAmount ?? 0),
        usageLimit: Number(d.usageLimit ?? 0),
        usedCount: Number(d.usedCount ?? 0),
        isActive: (d.isActive as boolean) ?? true,
        startDate: d.startDate instanceof Timestamp ? d.startDate.toDate() : new Date(),
        endDate: d.endDate instanceof Timestamp ? d.endDate.toDate() : new Date(),
        requiredRank: (d.requiredRank as string) ?? "member",
    };
}

const RANK_ORDER = ["member", "silver", "gold", "platinum"];

function meetsRank(customerRank: string, requiredRank: string): boolean {
    const ci = RANK_ORDER.indexOf(customerRank || "member");
    const ri = RANK_ORDER.indexOf(requiredRank || "member");
    return ci >= ri;
}

/* ─── Fetch all active coupons ─── */
export async function fetchActiveCoupons(): Promise<Coupon[]> {
    const q = query(collection(db, "coupons"), where("isActive", "==", true));
    const snap = await getDocs(q);
    const now = new Date();
    return snap.docs
        .map((d) => parseCoupon(d))
        .filter((c) => c.isActive && now >= c.startDate && now <= c.endDate && !(c.usageLimit > 0 && c.usedCount >= c.usageLimit));
}

/* ─── Validate a coupon against order ─── */
export function validateCoupon(
    coupon: Coupon,
    orderTotal: number,
    customerRank: string = "member"
): CouponValidationResult {
    const now = new Date();

    if (!coupon.isActive)
        return { isValid: false, message: "Mã giảm giá đã tắt", coupon: null, discountAmount: 0 };
    if (now < coupon.startDate)
        return { isValid: false, message: "Mã chưa tới thời gian áp dụng", coupon: null, discountAmount: 0 };
    if (now > coupon.endDate)
        return { isValid: false, message: "Mã giảm giá đã hết hạn", coupon: null, discountAmount: 0 };
    if (coupon.usageLimit > 0 && coupon.usedCount >= coupon.usageLimit)
        return { isValid: false, message: "Mã đã hết lượt sử dụng", coupon: null, discountAmount: 0 };
    if (orderTotal < coupon.minOrderAmount)
        return {
            isValid: false,
            message: `Đơn tối thiểu ${formatVND(coupon.minOrderAmount)}`,
            coupon,
            discountAmount: 0,
        };
    if (!meetsRank(customerRank, coupon.requiredRank))
        return {
            isValid: false,
            message: `Chỉ áp dụng từ hạng ${coupon.requiredRank}`,
            coupon,
            discountAmount: 0,
        };

    let discount = 0;
    if (coupon.discountType === "percent") {
        discount = orderTotal * (coupon.discountValue / 100);
        if (coupon.maxDiscountAmount > 0 && discount > coupon.maxDiscountAmount) {
            discount = coupon.maxDiscountAmount;
        }
    } else {
        discount = coupon.discountValue;
    }
    if (discount > orderTotal) discount = orderTotal;

    return { isValid: true, message: "Áp dụng mã thành công!", coupon, discountAmount: Math.round(discount) };
}

/* ─── Mark coupon as used (increment usedCount) ─── */
export async function markCouponUsed(couponId: string): Promise<void> {
    const ref = doc(db, "coupons", couponId);
    await updateDoc(ref, {
        usedCount: increment(1),
        updatedAt: Timestamp.now(),
    });
}

function formatVND(n: number): string {
    return n.toLocaleString("vi-VN") + "đ";
}
