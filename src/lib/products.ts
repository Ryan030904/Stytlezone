import {
    collection,
    query,
    orderBy,
    limit,
    getDocs,
    getDoc,
    doc,
    where,
    Timestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import type { Product, ProductVariant } from "@/lib/types";

const PRODUCTS_COLLECTION = "products";

function docToProduct(doc: { id: string; data: () => Record<string, unknown> }): Product {
    const d = doc.data();
    return {
        id: doc.id,
        name: (d.name as string) ?? "",
        description: (d.description as string) ?? "",
        price: Number(d.price ?? 0),
        salePrice: Number(d.salePrice ?? 0),
        categoryId: (d.categoryId as string) ?? "",
        categoryName: (d.categoryName as string) ?? "",
        brandId: (d.brandId as string) ?? "",
        brandName: (d.brandName as string) ?? "",
        gender: (d.gender as Product["gender"]) ?? "all",
        images: (d.images as string[]) ?? [],
        sizes: (d.sizes as string[]) ?? [],
        colors: (d.colors as string[]) ?? [],
        stock: Number(d.stock ?? 0),
        isActive: (d.isActive as boolean) ?? true,
        sortOrder: Number(d.sortOrder ?? 0),
        variants: ((d.variants as Record<string, unknown>[]) ?? []).map(
            (v): ProductVariant => ({
                color: (v.color as string) ?? "",
                colorHex: v.colorHex as string | undefined,
                colorImage: v.colorImage as string | undefined,
                size: (v.size as string) ?? "",
                price: Number(v.price ?? 0),
                stock: Number(v.stock ?? 0),
                sku: (v.sku as string) ?? "",
            })
        ),
        createdAt: d.createdAt instanceof Timestamp ? d.createdAt.toDate() : new Date(),
        updatedAt: d.updatedAt instanceof Timestamp ? d.updatedAt.toDate() : new Date(),
    };
}

/** Fetch all active products, sorted by sortOrder */
export async function getProducts(maxItems = 50): Promise<Product[]> {
    const q = query(
        collection(db, PRODUCTS_COLLECTION),
        orderBy("sortOrder", "asc"),
        limit(maxItems * 2),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((doc) => docToProduct(doc))
        .filter((p) => p.isActive)
        .slice(0, maxItems);
}

/** Fetch featured products (on sale) */
export async function getFeaturedProducts(maxItems = 8): Promise<Product[]> {
    const q = query(
        collection(db, PRODUCTS_COLLECTION),
        orderBy("sortOrder", "asc"),
        limit(100),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((doc) => docToProduct(doc))
        .filter((p) => p.isActive && p.salePrice > 0 && p.salePrice < p.price)
        .slice(0, maxItems);
}

/** Fetch newest products */
export async function getNewArrivals(maxItems = 8): Promise<Product[]> {
    const q = query(
        collection(db, PRODUCTS_COLLECTION),
        orderBy("createdAt", "desc"),
        limit(maxItems * 2),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((doc) => docToProduct(doc))
        .filter((p) => p.isActive)
        .slice(0, maxItems);
}

/** Fetch all active male products (gender = "male" or "all") */
export async function getMaleProducts(): Promise<Product[]> {
    const q = query(
        collection(db, PRODUCTS_COLLECTION),
        orderBy("sortOrder", "asc"),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((doc) => docToProduct(doc))
        .filter((p) => p.isActive && (p.gender === "male" || p.gender === "all"));
}

/** Fetch all active female products (gender = "female" or "all") */
export async function getFemaleProducts(): Promise<Product[]> {
    const q = query(
        collection(db, PRODUCTS_COLLECTION),
        orderBy("sortOrder", "asc"),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((doc) => docToProduct(doc))
        .filter((p) => p.isActive && (p.gender === "female" || p.gender === "all"));
}

/** Fetch a single product by its Firestore document ID */
export async function getProductById(id: string): Promise<Product | null> {
    try {
        const docRef = doc(db, PRODUCTS_COLLECTION, id);
        const snap = await getDoc(docRef);
        if (!snap.exists()) return null;
        const product = docToProduct(snap);
        return product.isActive ? product : null;
    } catch {
        return null;
    }
}

/** Fetch related products in the same category, excluding the current product */
export async function getRelatedProducts(
    product: Product,
    maxItems = 4
): Promise<Product[]> {
    const q = query(
        collection(db, PRODUCTS_COLLECTION),
        orderBy("sortOrder", "asc"),
        limit(maxItems * 4),
    );
    const snap = await getDocs(q);
    return snap.docs
        .map((d) => docToProduct(d))
        .filter(
            (p) =>
                p.isActive &&
                p.id !== product.id &&
                p.categoryId === product.categoryId
        )
        .slice(0, maxItems);
}

/** Fetch multiple products by arrays of IDs */
export async function getProductsByIds(ids: string[]): Promise<Product[]> {
    if (!ids.length) return [];
    
    // Firestore "in" queries support max 10 items.
    // For combos with < 10 items, this is fine.
    const chunks = [];
    for (let i = 0; i < ids.length; i += 10) {
        chunks.push(ids.slice(i, i + 10));
    }
    
    let allProducts: Product[] = [];
    for (const chunk of chunks) {
        const q = query(
            collection(db, PRODUCTS_COLLECTION),
            where("__name__", "in", chunk)
        );
        const snap = await getDocs(q);
        const products = snap.docs.map(docToProduct).filter(p => p.isActive);
        allProducts = [...allProducts, ...products];
    }
    return allProducts;
}
