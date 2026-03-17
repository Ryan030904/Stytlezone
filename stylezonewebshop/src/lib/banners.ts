import {
    collection,
    query,
    orderBy,
    getDocs,
    Timestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import type { Banner } from "@/lib/types";

const BANNERS_COLLECTION = "banners";

function docToBanner(doc: { id: string; data: () => Record<string, unknown> }): Banner {
    const d = doc.data();
    return {
        id: doc.id,
        title: (d.title as string) ?? "",
        subtitle: (d.subtitle as string) ?? "",
        imageUrl: (d.imageUrl as string) ?? "",
        linkUrl: (d.linkUrl as string) ?? "",
        position: (d.position as Banner["position"]) ?? "hero",
        isActive: (d.isActive as boolean) ?? true,
        sortOrder: Number(d.sortOrder ?? 0),
        targetRank: (d.targetRank as string) ?? "member",
        startDate: d.startDate instanceof Timestamp ? d.startDate.toDate() : new Date(),
        endDate: d.endDate instanceof Timestamp ? d.endDate.toDate() : new Date(),
        createdAt: d.createdAt instanceof Timestamp ? d.createdAt.toDate() : new Date(),
    };
}

/** Check if banner is currently running */
function isBannerRunning(banner: Banner): boolean {
    const now = new Date();
    return banner.isActive && now >= banner.startDate && now <= banner.endDate;
}

/** Fetch active hero banners */
export async function getHeroBanners(): Promise<Banner[]> {
    const q = query(
        collection(db, BANNERS_COLLECTION),
        orderBy("sortOrder", "asc"),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((doc) => docToBanner(doc))
        .filter((b) => b.position === "hero" && isBannerRunning(b));
}

/** Fetch active promo banners */
export async function getPromoBanners(): Promise<Banner[]> {
    const q = query(
        collection(db, BANNERS_COLLECTION),
        orderBy("sortOrder", "asc"),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((doc) => docToBanner(doc))
        .filter((b) => b.position === "promo" && isBannerRunning(b));
}
