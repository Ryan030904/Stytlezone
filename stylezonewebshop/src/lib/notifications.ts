import { db } from "@/lib/firebase";
import {
    collection,
    doc,
    addDoc,
    getDocs,
    updateDoc,
    deleteDoc,
    query,
    orderBy,
    where,
    writeBatch,
    Timestamp,
} from "firebase/firestore";

/* ─── Types ─── */
export type NotificationType =
    | "rank_up"
    | "rank_reset_warning"
    | "rank_reset"
    | "order_status"
    | "promotion"
    | "system";

export interface AppNotification {
    id: string;
    type: NotificationType;
    title: string;
    message: string;
    icon: string;
    color: string;
    isRead: boolean;
    link?: string;
    createdAt: Date;
}

const NOTIFICATION_ICONS: Record<NotificationType, { icon: string; color: string }> = {
    rank_up: { icon: "🎉", color: "#22c55e" },
    rank_reset_warning: { icon: "⚠️", color: "#f59e0b" },
    rank_reset: { icon: "📉", color: "#ef4444" },
    order_status: { icon: "📦", color: "#3b82f6" },
    promotion: { icon: "🎁", color: "#8B5CF6" },
    system: { icon: "🔔", color: "#71717a" },
};

function getNotificationsRef(uid: string) {
    return collection(db, "users", uid, "notifications");
}

/* ─── Get all notifications, newest first ─── */
export async function getNotifications(uid: string): Promise<AppNotification[]> {
    const q = query(getNotificationsRef(uid), orderBy("createdAt", "desc"));
    const snap = await getDocs(q);
    return snap.docs.map((d) => {
        const data = d.data();
        return {
            id: d.id,
            type: (data.type as NotificationType) ?? "system",
            title: (data.title as string) ?? "",
            message: (data.message as string) ?? "",
            icon: (data.icon as string) ?? "🔔",
            color: (data.color as string) ?? "#71717a",
            isRead: (data.isRead as boolean) ?? false,
            link: (data.link as string) || undefined,
            createdAt: data.createdAt?.toDate?.() ?? new Date(),
        };
    });
}

/* ─── Add a notification ─── */
export async function addNotification(
    uid: string,
    data: {
        type: NotificationType;
        title: string;
        message: string;
        link?: string;
    }
): Promise<string> {
    const meta = NOTIFICATION_ICONS[data.type] ?? NOTIFICATION_ICONS.system;
    const docRef = await addDoc(getNotificationsRef(uid), {
        type: data.type,
        title: data.title,
        message: data.message,
        icon: meta.icon,
        color: meta.color,
        isRead: false,
        link: data.link ?? "",
        createdAt: Timestamp.now(),
    });
    return docRef.id;
}

/* ─── Mark one notification as read ─── */
export async function markAsRead(uid: string, notificationId: string): Promise<void> {
    const ref = doc(db, "users", uid, "notifications", notificationId);
    await updateDoc(ref, { isRead: true });
}

/* ─── Mark all as read ─── */
export async function markAllAsRead(uid: string): Promise<void> {
    const q = query(getNotificationsRef(uid), where("isRead", "==", false));
    const snap = await getDocs(q);
    if (snap.empty) return;
    const batch = writeBatch(db);
    snap.docs.forEach((d) => batch.update(d.ref, { isRead: true }));
    await batch.commit();
}

/* ─── Delete a notification ─── */
export async function deleteNotification(uid: string, notificationId: string): Promise<void> {
    await deleteDoc(doc(db, "users", uid, "notifications", notificationId));
}

/* ─── Get unread count ─── */
export async function getUnreadCount(uid: string): Promise<number> {
    const q = query(getNotificationsRef(uid), where("isRead", "==", false));
    const snap = await getDocs(q);
    return snap.size;
}
