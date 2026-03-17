import { db } from "@/lib/firebase";
import { collection, addDoc, Timestamp } from "firebase/firestore";

/* ─── Types ─── */
export interface OrderItem {
    productId: string;
    productName: string;
    imageUrl: string;
    price: number;
    quantity: number;
    size: string;
    color: string;
}

export interface CreateOrderPayload {
    customerName: string;
    customerEmail: string;
    customerPhone: string;
    shippingAddress: string;
    items: OrderItem[];
    subtotal: number;
    shippingFee: number;
    discount: number;
    total: number;
    paymentMethod: "cod" | "bank" | "momo";
    note: string;
}

/**
 * Create a new order in Firestore `orders` collection.
 * Follows the exact same schema as the admin Order model.
 * Returns the generated document ID.
 */
export async function createOrder(payload: CreateOrderPayload): Promise<string> {
    const now = Timestamp.now();

    const docRef = await addDoc(collection(db, "orders"), {
        customerName: payload.customerName,
        customerEmail: payload.customerEmail,
        customerPhone: payload.customerPhone,
        shippingAddress: payload.shippingAddress,
        items: payload.items.map((item) => ({
            productId: item.productId,
            productName: item.productName,
            imageUrl: item.imageUrl,
            price: item.price,
            quantity: item.quantity,
            size: item.size,
            color: item.color,
        })),
        subtotal: payload.subtotal,
        shippingFee: payload.shippingFee,
        discount: payload.discount,
        total: payload.total,
        status: "pending",
        paymentMethod: payload.paymentMethod,
        note: payload.note,
        createdAt: now,
        updatedAt: now,
    });

    return docRef.id;
}
