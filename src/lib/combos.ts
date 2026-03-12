import { db } from "./firebase";
import {
    collection,
    query,
    where,
    orderBy,
    getDocs,
    Timestamp,
} from "firebase/firestore";

export interface ComboItem {
    productId: string;
    productName: string;
    productImage: string;
    originalPrice: number;
    quantity: number;
}

export interface Combo {
    id: string;
    name: string;
    description: string;
    imageUrl: string;
    items: ComboItem[];
    comboPrice: number;
    salePrice: number;
    hasPromotion: boolean;
    promotionStart: Date | null;
    promotionEnd: Date | null;
    isActive: boolean;
    sortOrder: number;
    createdAt: Date;
}

/** Computed helpers */
export function getComboTotalOriginalPrice(combo: Combo): number {
    return combo.items.reduce(
        (sum, item) => sum + item.originalPrice * item.quantity,
        0
    );
}

export function isComboPromotionActive(combo: Combo): boolean {
    if (!combo.hasPromotion || combo.salePrice <= 0) return false;
    const now = new Date();
    if (combo.promotionStart && now < combo.promotionStart) return false;
    if (combo.promotionEnd && now > combo.promotionEnd) return false;
    return true;
}

export function getComboEffectivePrice(combo: Combo): number {
    if (isComboPromotionActive(combo) && combo.salePrice > 0)
        return combo.salePrice;
    return getComboTotalOriginalPrice(combo);
}

export function getComboSavedPercent(combo: Combo): number {
    const total = getComboTotalOriginalPrice(combo);
    const effective = getComboEffectivePrice(combo);
    return total > 0 ? ((total - effective) / total) * 100 : 0;
}

/** Fetch active combos from Firestore */
export async function getCombos(): Promise<Combo[]> {
    const q = query(
        collection(db, "combos"),
        where("isActive", "==", true)
    );

    const snapshot = await getDocs(q);
    const combos = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
            id: doc.id,
            name: data.name ?? "",
            description: data.description ?? "",
            imageUrl: data.imageUrl ?? "",
            items: (data.items as ComboItem[]) ?? [],
            comboPrice: data.comboPrice ?? 0,
            salePrice: data.salePrice ?? 0,
            hasPromotion: data.hasPromotion ?? false,
            promotionStart: data.promotionStart
                ? (data.promotionStart as Timestamp).toDate()
                : null,
            promotionEnd: data.promotionEnd
                ? (data.promotionEnd as Timestamp).toDate()
                : null,
            isActive: data.isActive ?? true,
            sortOrder: data.sortOrder ?? 0,
            createdAt: data.createdAt
                ? (data.createdAt as Timestamp).toDate()
                : new Date(),
        };
    });
    return combos.sort((a, b) => a.sortOrder - b.sortOrder);
}
