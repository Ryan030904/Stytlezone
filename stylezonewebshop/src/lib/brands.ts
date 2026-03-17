import {
    collection,
    query,
    orderBy,
    getDocs,
    Timestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import type { Brand } from "@/lib/types";

const BRANDS_COLLECTION = "brands";

function docToBrand(doc: { id: string; data: () => Record<string, unknown> }): Brand {
    const d = doc.data();
    return {
        id: doc.id,
        name: (d.name as string) ?? "",
        logo: (d.logo as string) ?? "",
        description: (d.description as string) ?? "",
        country: (d.country as string) ?? "",
        isActive: (d.isActive as boolean) ?? true,
        productCount: Number(d.productCount ?? 0),
        createdAt: d.createdAt instanceof Timestamp ? d.createdAt.toDate() : new Date(),
    };
}

/** Fetch active brands */
export async function getBrands(): Promise<Brand[]> {
    const q = query(
        collection(db, BRANDS_COLLECTION),
        orderBy("name", "asc"),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((doc) => docToBrand(doc))
        .filter((b) => b.isActive);
}
