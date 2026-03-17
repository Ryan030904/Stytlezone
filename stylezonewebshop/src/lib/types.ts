// ─── Product Variant ──────────────────────────────────────────
export interface ProductVariant {
    color: string;
    colorHex?: string;
    colorImage?: string;
    size: string;
    price: number;
    stock: number;
    sku: string;
}

// ─── Product ──────────────────────────────────────────────────
export interface Product {
    id: string;
    name: string;
    description: string;
    price: number;
    salePrice: number;
    categoryId: string;
    categoryName: string;
    brandId: string;
    brandName: string;
    gender: "all" | "male" | "female";
    images: string[];
    sizes: string[];
    colors: string[];
    stock: number;
    isActive: boolean;
    sortOrder: number;
    variants: ProductVariant[];
    createdAt: Date;
    updatedAt: Date;
}

// ─── Category ─────────────────────────────────────────────────
export interface Category {
    id: string;
    name: string;
    description: string;
    imageUrl: string;
    gender: "all" | "male" | "female";
    parentId: string | null;
    isActive: boolean;
    sortOrder: number;
    createdAt: Date;
    updatedAt: Date;
}

// ─── Brand ────────────────────────────────────────────────────
export interface Brand {
    id: string;
    name: string;
    logo: string;
    description: string;
    country: string;
    isActive: boolean;
    productCount: number;
    createdAt: Date;
}

// ─── Banner ───────────────────────────────────────────────────
export interface Banner {
    id: string;
    title: string;
    subtitle: string;
    imageUrl: string;
    linkUrl: string;
    position: "hero" | "promo" | "sidebar";
    isActive: boolean;
    sortOrder: number;
    targetRank: string;
    startDate: Date;
    endDate: Date;
    createdAt: Date;
}

// ─── Promotion ────────────────────────────────────────────────
export interface Promotion {
    id: string;
    name: string;
    description: string;
    discountType: "percent" | "fixed";
    discountValue: number;
    scope: "product" | "category" | "store";
    productIds: string[];
    categoryIds: string[];
    isFlashSale: boolean;
    isActive: boolean;
    priority: number;
    targetRank: string;
    startDate: Date;
    endDate: Date;
    createdAt: Date;
}

// ─── Review ───────────────────────────────────────────────────
export interface Review {
    id: string;
    productId: string;
    productName: string;
    productImage: string;
    customerId: string;
    customerName: string;
    customerAvatar: string;
    rating: number; // 1-5
    comment: string;
    images: string[];
    status: "visible" | "hidden";
    adminReply: string;
    adminReplyAt: Date | null;
    createdAt: Date;
}

// ─── User Address ─────────────────────────────────────────────
export interface UserAddress {
    id: string;
    fullName: string;
    phone: string;
    province: string;
    provinceCode: number;
    district: string;
    districtCode: number;
    ward: string;
    wardCode: number;
    street: string;
    note: string;
    isDefault: boolean;
    createdAt: Date;
}
