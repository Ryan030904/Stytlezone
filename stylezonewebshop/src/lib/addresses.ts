import { collection, doc, getDocs, addDoc, updateDoc, deleteDoc, query, orderBy, writeBatch, Timestamp } from "firebase/firestore";
import { db } from "./firebase";
import type { UserAddress } from "./types";

const getAddressesRef = (uid: string) => collection(db, "users", uid, "addresses");

/** Get all addresses for a user, sorted by isDefault desc then createdAt desc */
export async function getAddresses(uid: string): Promise<UserAddress[]> {
    const q = query(getAddressesRef(uid), orderBy("createdAt", "desc"));
    const snap = await getDocs(q);
    const addresses: UserAddress[] = snap.docs.map((d) => {
        const data = d.data();
        return {
            id: d.id,
            fullName: data.fullName || "",
            phone: data.phone || "",
            province: data.province || "",
            provinceCode: data.provinceCode || 0,
            district: data.district || "",
            districtCode: data.districtCode || 0,
            ward: data.ward || "",
            wardCode: data.wardCode || 0,
            street: data.street || "",
            note: data.note || "",
            isDefault: data.isDefault || false,
            createdAt: data.createdAt?.toDate?.() || new Date(),
        };
    });
    // Sort: default first, then by createdAt desc
    return addresses.sort((a, b) => {
        if (a.isDefault !== b.isDefault) return a.isDefault ? -1 : 1;
        return b.createdAt.getTime() - a.createdAt.getTime();
    });
}

/** Add a new address. If isDefault, unset other defaults first. */
export async function addAddress(uid: string, data: Omit<UserAddress, "id" | "createdAt">): Promise<string> {
    if (data.isDefault) {
        await clearDefaultAddresses(uid);
    }
    const docRef = await addDoc(getAddressesRef(uid), {
        ...data,
        createdAt: Timestamp.now(),
    });
    return docRef.id;
}

/** Update an existing address */
export async function updateAddress(uid: string, addressId: string, data: Partial<Omit<UserAddress, "id" | "createdAt">>): Promise<void> {
    if (data.isDefault) {
        await clearDefaultAddresses(uid, addressId);
    }
    const ref = doc(db, "users", uid, "addresses", addressId);
    await updateDoc(ref, data);
}

/** Delete an address */
export async function deleteAddress(uid: string, addressId: string): Promise<void> {
    const ref = doc(db, "users", uid, "addresses", addressId);
    await deleteDoc(ref);
}

/** Set a specific address as default, unset all others */
export async function setDefaultAddress(uid: string, addressId: string): Promise<void> {
    await clearDefaultAddresses(uid, addressId);
    const ref = doc(db, "users", uid, "addresses", addressId);
    await updateDoc(ref, { isDefault: true });
}

/** Helper: clear isDefault on all addresses except excludeId */
async function clearDefaultAddresses(uid: string, excludeId?: string): Promise<void> {
    const snap = await getDocs(getAddressesRef(uid));
    const batch = writeBatch(db);
    snap.docs.forEach((d) => {
        if (d.data().isDefault && d.id !== excludeId) {
            batch.update(d.ref, { isDefault: false });
        }
    });
    await batch.commit();
}
