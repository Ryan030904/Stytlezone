import {
    collection,
    query,
    orderBy,
    getDocs,
    Timestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import type { Promotion } from "@/lib/types";

const PROMOTIONS_COLLECTION = "promotions";

function docToPromotion(doc: { id: string; data: () => Record<string, unknown> }): Promotion {
    const d = doc.data();
    return {
        id: doc.id,
        name: (d.name as string) ?? "",
        description: (d.description as string) ?? "",
        discountType: (d.discountType as Promotion["discountType"]) ?? "percent",
        discountValue: Number(d.discountValue ?? 0),
        scope: (d.scope as Promotion["scope"]) ?? "store",
        productIds: (d.productIds as string[]) ?? [],
        categoryIds: (d.categoryIds as string[]) ?? [],
        isFlashSale: (d.isFlashSale as boolean) ?? false,
        isActive: (d.isActive as boolean) ?? true,
        priority: Number(d.priority ?? 0),
        targetRank: (d.targetRank as string) ?? "member",
        startDate: d.startDate instanceof Timestamp ? d.startDate.toDate() : new Date(),
        endDate: d.endDate instanceof Timestamp ? d.endDate.toDate() : new Date(),
        createdAt: d.createdAt instanceof Timestamp ? d.createdAt.toDate() : new Date(),
    };
}

/** Check if promotion is currently running */
function isPromotionRunning(promo: Promotion): boolean {
    const now = new Date();
    return promo.isActive && now >= promo.startDate && now <= promo.endDate;
}

/** Fetch all active promotions */
export async function getActivePromotions(): Promise<Promotion[]> {
    const q = query(
        collection(db, PROMOTIONS_COLLECTION),
        orderBy("priority", "desc"),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((doc) => docToPromotion(doc))
        .filter(isPromotionRunning);
}

/** Fetch active flash sale (first one found) */
export async function getFlashSale(): Promise<Promotion | null> {
    const promos = await getActivePromotions();
    return promos.find((p) => p.isFlashSale) ?? null;
}
