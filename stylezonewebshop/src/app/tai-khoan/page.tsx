"use client";

import { useState, useEffect, useRef } from "react";
import { onAuthStateChanged, User } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";
import { signOutUser } from "@/lib/auth";
import { toast } from "sonner";
import { useRouter } from "next/navigation";

import ProfileSidebar, { type MainTab, type SubTab } from "./components/ProfileSidebar";
import ProfileTab, { type UserProfile } from "./components/ProfileTab";
import OrdersTab from "./components/OrdersTab";
import VouchersTab from "./components/VouchersTab";
import RankTab from "./components/RankTab";

import AddressTab from "./components/AddressTab";

const DEFAULT_PROFILE: UserProfile = {
    displayName: "", email: "", phone: "", address: "", gender: "", birthday: "", photoURL: "",
};

export default function ProfilePage() {
    const router = useRouter();
    const [user, setUser] = useState<User | null>(null);
    const [profile, setProfile] = useState<UserProfile>(DEFAULT_PROFILE);
    const [loading, setLoading] = useState(true);
    const [mainTab, setMainTab] = useState<MainTab>("account");
    const [subTab, setSubTab] = useState<SubTab>("profile");
    const fileInputRef = useRef<HTMLInputElement>(null);
    const isLoggingOutRef = useRef(false);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
            // Skip redirect during intentional logout — NavigationLoader handles it
            if (!firebaseUser) {
                if (!isLoggingOutRef.current) {
                    router.push("/dang-nhap");
                }
                return;
            }
            setUser(firebaseUser);
            try {
                const userRef = doc(db, "users", firebaseUser.uid);
                const snap = await getDoc(userRef);
                if (snap.exists()) {
                    const data = snap.data();
                    setProfile({
                        displayName: data.displayName || firebaseUser.displayName || "",
                        email: data.email || firebaseUser.email || "",
                        phone: data.phone || "",
                        address: data.address || "",
                        gender: data.gender || "",
                        birthday: data.birthday || "",
                        photoURL: data.photoURL || firebaseUser.photoURL || "",
                    });
                } else {
                    setProfile({
                        displayName: firebaseUser.displayName || "",
                        email: firebaseUser.email || "",
                        phone: "", address: "", gender: "", birthday: "",
                        photoURL: firebaseUser.photoURL || "",
                    });
                }
            } catch {
                setProfile({
                    displayName: firebaseUser.displayName || "",
                    email: firebaseUser.email || "",
                    phone: "", address: "", gender: "", birthday: "",
                    photoURL: firebaseUser.photoURL || "",
                });
            }
            setLoading(false);
        });
        return () => unsubscribe();
    }, [router]);

    const _handleLogout = async () => {
        isLoggingOutRef.current = true;
        await signOutUser();
        toast.success("Đã đăng xuất thành công!");
        router.push("/");
    };

    if (loading) {
        return (
            <div style={{ minHeight: "60vh", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <div style={{ textAlign: "center", color: "var(--text-muted)" }}>
                    <div style={{ width: "32px", height: "32px", border: "3px solid var(--border-color)", borderTopColor: "var(--color-accent)", borderRadius: "50%", animation: "spin 0.8s linear infinite", margin: "0 auto var(--space-md)" }} />
                    Đang tải...
                </div>
            </div>
        );
    }

    const renderContent = () => {
        if (mainTab === "orders") return <OrdersTab userEmail={profile.email} />;
        if (mainTab === "vouchers") return <VouchersTab uid={user?.uid || ""} />;
        // Account subtabs
        switch (subTab) {
            case "profile": return <ProfileTab uid={user?.uid || ""} profile={profile} setProfile={setProfile} />;
            case "address": return <AddressTab uid={user?.uid || ""} />;

            case "rank": return <RankTab userEmail={profile.email} />;
            default: return <ProfileTab uid={user?.uid || ""} profile={profile} setProfile={setProfile} />;
        }
    };

    return (
        <div style={{ maxWidth: "1100px", margin: "0 auto", padding: "calc(var(--header-height, 70px) + var(--space-2xl)) var(--space-lg) var(--space-2xl)" }}>
            <div style={{ display: "flex", gap: "var(--space-2xl)", alignItems: "flex-start" }}>
                {/* Sidebar */}
                <ProfileSidebar
                    mainTab={mainTab} subTab={subTab}
                    onMainTabChange={(tab) => { setMainTab(tab); if (tab === "account") setSubTab("profile"); }}
                    onSubTabChange={setSubTab}
                    userName={profile.displayName}
                    userEmail={profile.email}
                    photoURL={profile.photoURL}
                    onAvatarClick={() => fileInputRef.current?.click()}
                />
                {/* Content */}
                <div style={{ flex: 1, minWidth: 0 }}>
                    {renderContent()}
                </div>
            </div>

            <style jsx global>{`
                @keyframes spin { to { transform: rotate(360deg); } }
                @media (max-width: 768px) {
                    div[style*="display: flex"][style*="gap: var(--space-2xl)"] {
                        flex-direction: column !important;
                    }
                    aside[style*="width: 260px"] {
                        width: 100% !important;
                        flex-direction: row !important;
                        overflow-x: auto !important;
                    }
                }
            `}</style>
        </div>
    );
}
