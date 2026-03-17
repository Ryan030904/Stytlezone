import { db } from "@/lib/firebase";
import {
    collection,
    doc,
    setDoc,
    getDocs,
    deleteDoc,
    query,
    where,
    serverTimestamp,
} from "firebase/firestore";

/* ─── Types ─── */
export interface SavedVoucher {
    id: string;
    code: string;
    label: string;
    description: string;
    minOrderAmount: number;
    discountType: "percent" | "fixed";
    discountValue: number;
    color: string;
    savedAt: Date;
}

/* ─── Save a voucher to user's collection ─── */
export async function saveVoucher(
    uid: string,
    voucher: Omit<SavedVoucher, "id" | "savedAt">
): Promise<void> {
    const ref = doc(collection(db, "users", uid, "savedVouchers"));
    await setDoc(ref, {
        ...voucher,
        savedAt: serverTimestamp(),
    });
}

/* ─── Get all saved vouchers for a user ─── */
export async function getSavedVouchers(uid: string): Promise<SavedVoucher[]> {
    const snap = await getDocs(collection(db, "users", uid, "savedVouchers"));
    return snap.docs.map((d) => {
        const data = d.data();
        return {
            id: d.id,
            code: (data.code as string) ?? "",
            label: (data.label as string) ?? "",
            description: (data.description as string) ?? "",
            minOrderAmount: Number(data.minOrderAmount ?? 0),
            discountType: (data.discountType as "percent" | "fixed") ?? "percent",
            discountValue: Number(data.discountValue ?? 0),
            color: (data.color as string) ?? "#8B5CF6",
            savedAt: data.savedAt?.toDate?.() ?? new Date(),
        };
    });
}

/* ─── Remove a saved voucher ─── */
export async function removeSavedVoucher(
    uid: string,
    voucherId: string
): Promise<void> {
    await deleteDoc(doc(db, "users", uid, "savedVouchers", voucherId));
}

/* ─── Check if a voucher code is already saved ─── */
export async function isVoucherSaved(
    uid: string,
    code: string
): Promise<boolean> {
    const q = query(
        collection(db, "users", uid, "savedVouchers"),
        where("code", "==", code)
    );
    const snap = await getDocs(q);
    return !snap.empty;
}
