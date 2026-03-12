import {
    collection,
    query,
    orderBy,
    getDocs,
    Timestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import type { Category } from "@/lib/types";

const CATEGORIES_COLLECTION = "categories";

function docToCategory(doc: { id: string; data: () => Record<string, unknown> }): Category {
    const d = doc.data();
    return {
        id: doc.id,
        name: (d.name as string) ?? "",
        description: (d.description as string) ?? "",
        imageUrl: (d.imageUrl as string) ?? "",
        gender: (d.gender as Category["gender"]) ?? "all",
        parentId: (d.parentId as string | null) ?? null,
        isActive: (d.isActive as boolean) ?? true,
        sortOrder: Number(d.sortOrder ?? 0),
        createdAt: d.createdAt instanceof Timestamp ? d.createdAt.toDate() : new Date(),
        updatedAt: d.updatedAt instanceof Timestamp ? d.updatedAt.toDate() : new Date(),
    };
}

/** Fetch active parent categories */
export async function getCategories(): Promise<Category[]> {
    const q = query(
        collection(db, CATEGORIES_COLLECTION),
        orderBy("sortOrder", "asc"),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((doc) => docToCategory(doc))
        .filter((c) => c.isActive);
}

/** Fetch active parent-only categories */
export async function getParentCategories(): Promise<Category[]> {
    const categories = await getCategories();
    return categories.filter((c) => !c.parentId || c.parentId === "");
}

/** Fetch active male categories (gender = "male" or "all") */
export async function getMaleCategories(): Promise<Category[]> {
    const categories = await getCategories();
    return categories.filter((c) => c.gender === "male" || c.gender === "all");
}

/** Fetch active female categories (gender = "female" or "all") */
export async function getFemaleCategories(): Promise<Category[]> {
    const categories = await getCategories();
    return categories.filter((c) => c.gender === "female" || c.gender === "all");
}
