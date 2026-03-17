import { db, storage } from "@/lib/firebase";
import {
    collection,
    query,
    where,
    getDocs,
    addDoc,
    Timestamp,
} from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import type { Review } from "@/lib/types";

/* ─── Fetch visible reviews for a product ─── */
export async function getProductReviews(productId: string): Promise<Review[]> {
    const q = query(
        collection(db, "reviews"),
        where("productId", "==", productId)
    );
    const snap = await getDocs(q);
    const all = snap.docs.map((doc) => {
        const d = doc.data();
        return {
            id: doc.id,
            productId: d.productId ?? "",
            productName: d.productName ?? "",
            productImage: d.productImage ?? "",
            customerId: d.customerId ?? "",
            customerName: d.customerName ?? "",
            customerAvatar: d.customerAvatar ?? "",
            rating: d.rating ?? 5,
            comment: d.comment ?? "",
            images: d.images ?? [],
            status: d.status ?? "visible",
            adminReply: d.adminReply ?? "",
            adminReplyAt: d.adminReplyAt?.toDate?.() ?? null,
            createdAt: d.createdAt?.toDate?.() ?? new Date(),
        } as Review;
    });
    // Filter visible + sort newest first (client-side to avoid composite index)
    return all
        .filter((r) => r.status === "visible")
        .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
}

/* ─── Count how many times user purchased a specific product (delivered orders) ─── */
export async function countUserPurchases(
    userEmail: string,
    productId: string
): Promise<number> {
    // Query orders by customer email
    const q = query(
        collection(db, "orders"),
        where("customerEmail", "==", userEmail)
    );
    const snap = await getDocs(q);

    let purchaseCount = 0;
    snap.docs.forEach((doc) => {
        const data = doc.data();
        // Only count delivered orders
        if (data.status !== "delivered") return;
        const items = data.items ?? [];
        items.forEach((item: { productId: string; quantity: number }) => {
            if (item.productId === productId) {
                purchaseCount += item.quantity;
            }
        });
    });
    return purchaseCount;
}

/* ─── Count how many reviews user already submitted for a product ─── */
export async function countUserReviews(
    userId: string,
    productId: string
): Promise<number> {
    const q = query(
        collection(db, "reviews"),
        where("customerId", "==", userId),
        where("productId", "==", productId)
    );
    const snap = await getDocs(q);
    return snap.size;
}

/* ─── Check how many more reviews user can write ─── */
const FREE_REVIEW_QUOTA = 5;

export async function getRemainingReviews(
    userEmail: string,
    userId: string,
    productId: string
): Promise<number> {
    const [purchases, existingReviews] = await Promise.all([
        countUserPurchases(userEmail, productId),
        countUserReviews(userId, productId),
    ]);
    // 5 free reviews + 1 per delivered purchase
    const totalAllowed = FREE_REVIEW_QUOTA + purchases;
    return Math.max(0, totalAllowed - existingReviews);
}

/* ─── Upload review images to Firebase Storage ─── */
async function uploadReviewImages(
    userId: string,
    files: File[]
): Promise<string[]> {
    const urls: string[] = [];
    for (const file of files) {
        const path = `reviews/${userId}/${Date.now()}_${file.name}`;
        const storageRef = ref(storage, path);
        await uploadBytes(storageRef, file);
        const url = await getDownloadURL(storageRef);
        urls.push(url);
    }
    return urls;
}

/* ─── Submit a new review ─── */
export async function submitReview(data: {
    productId: string;
    productName: string;
    productImage: string;
    customerId: string;
    customerName: string;
    customerAvatar: string;
    rating: number;
    comment: string;
    imageFiles: File[];
}): Promise<string> {
    // Upload images first
    const imageUrls =
        data.imageFiles.length > 0
            ? await uploadReviewImages(data.customerId, data.imageFiles)
            : [];

    const docRef = await addDoc(collection(db, "reviews"), {
        productId: data.productId,
        productName: data.productName,
        productImage: data.productImage,
        customerId: data.customerId,
        customerName: data.customerName,
        customerAvatar: data.customerAvatar,
        rating: data.rating,
        comment: data.comment,
        images: imageUrls,
        status: "visible",
        adminReply: "",
        adminReplyAt: null,
        createdAt: Timestamp.now(),
    });

    return docRef.id;
}

/* ─── Compute rating statistics ─── */
export function computeRatingStats(reviews: Review[]) {
    if (reviews.length === 0) {
        return { average: 0, total: 0, distribution: [0, 0, 0, 0, 0] };
    }
    const distribution = [0, 0, 0, 0, 0]; // index 0 = 1 star, index 4 = 5 star
    let sum = 0;
    for (const r of reviews) {
        sum += r.rating;
        distribution[r.rating - 1]++;
    }
    return {
        average: sum / reviews.length,
        total: reviews.length,
        distribution,
    };
}
