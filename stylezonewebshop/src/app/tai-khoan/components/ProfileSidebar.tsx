"use client";

import Image from "next/image";
import type { ReactNode } from "react";

export type MainTab = "account" | "orders" | "vouchers";
export type SubTab = "profile" | "address" | "settings" | "rank";

interface ProfileSidebarProps {
    mainTab: MainTab;
    subTab: SubTab;
    onMainTabChange: (tab: MainTab) => void;
    onSubTabChange: (tab: SubTab) => void;
    userName: string;
    userEmail: string;
    photoURL: string;
    onAvatarClick: () => void;
}

const ACCOUNT_SUBTABS: { key: SubTab; label: string; icon: ReactNode }[] = [
    {
        key: "profile", label: "Hồ Sơ",
        icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>,
    },
    {
        key: "address", label: "Địa Chỉ",
        icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>,
    },

    {
        key: "rank", label: "Hạng Thành Viên",
        icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>,
    },
];

export default function ProfileSidebar({
    mainTab, subTab, onMainTabChange, onSubTabChange,
    userName, userEmail, photoURL, onAvatarClick,
}: ProfileSidebarProps) {

    return (
        <aside style={{
            width: "260px", flexShrink: 0,
            display: "flex", flexDirection: "column", gap: "var(--space-sm)",
        }}>
            {/* User card */}
            <div style={{
                display: "flex", alignItems: "center", gap: "var(--space-md)",
                padding: "var(--space-lg)", marginBottom: "var(--space-sm)",
            }}>
                <div
                    onClick={onAvatarClick}
                    style={{
                        width: "48px", height: "48px", borderRadius: "50%",
                        overflow: "hidden", flexShrink: 0, cursor: "pointer",
                        border: "2px solid var(--color-accent)",
                        position: "relative",
                    }}
                >
                    {photoURL ? (
                        <Image src={photoURL} alt="Avatar" fill sizes="48px" style={{ objectFit: "cover" }} />
                    ) : (
                        <div style={{
                            width: "100%", height: "100%",
                            display: "flex", alignItems: "center", justifyContent: "center",
                            fontSize: "1.1rem", fontWeight: 700,
                            color: "var(--color-accent)", background: "rgba(139,92,246,0.1)",
                        }}>
                            {userName?.charAt(0)?.toUpperCase() || "U"}
                        </div>
                    )}
                </div>
                <div style={{ minWidth: 0, flex: 1 }}>
                    <p style={{ fontSize: "0.9rem", fontWeight: 700, color: "var(--text-primary)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                        {userName || "Người dùng"}
                    </p>
                    <p title={userEmail} style={{ fontSize: "0.58rem", color: "var(--text-muted)", whiteSpace: "nowrap" }}>
                        {userEmail}
                    </p>
                </div>
            </div>

            {/* Account section label */}
            <p style={{
                display: "flex", alignItems: "center", gap: "var(--space-sm)",
                padding: "10px 14px",
                color: "var(--text-primary)",
                fontSize: "0.88rem", fontWeight: 600,
            }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>
                Tài Khoản Của Tôi
            </p>
            <div style={{ paddingLeft: "16px" }}>
                {ACCOUNT_SUBTABS.map((tab) => (
                    <SidebarSubItem
                        key={tab.key}
                        label={tab.label}
                        icon={tab.icon}
                        isActive={mainTab === "account" && subTab === tab.key}
                        onClick={() => { onMainTabChange("account"); onSubTabChange(tab.key); }}
                    />
                ))}
            </div>

            {/* Orders */}
            <SidebarMainItem
                label="Đơn Mua"
                isActive={mainTab === "orders"}
                onClick={() => onMainTabChange("orders")}
                icon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" /><line x1="3" y1="6" x2="21" y2="6" /><path d="M16 10a4 4 0 0 1-8 0" /></svg>}
            />

            {/* Vouchers */}
            <SidebarMainItem
                label="Kho Voucher"
                isActive={mainTab === "vouchers"}
                onClick={() => onMainTabChange("vouchers")}
                icon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="1" y="4" width="22" height="16" rx="2" ry="2" /><line x1="1" y1="10" x2="23" y2="10" /></svg>}
            />
        </aside>
    );
}

function SidebarMainItem({ label, isActive, onClick, icon }: {
    label: string; isActive: boolean; onClick: () => void; icon: ReactNode;
}) {
    return (
        <button
            onClick={onClick}
            style={{
                display: "flex", alignItems: "center", gap: "var(--space-sm)",
                padding: "10px 14px", width: "100%",
                borderRadius: "var(--radius-md)",
                background: isActive ? "rgba(139,92,246,0.08)" : "transparent",
                border: "none", cursor: "pointer",
                color: isActive ? "var(--color-accent)" : "var(--text-primary)",
                fontSize: "0.88rem", fontWeight: isActive ? 600 : 500,
                transition: "all 0.15s ease", textAlign: "left",
            }}
            onMouseEnter={(e) => { if (!isActive) e.currentTarget.style.background = "var(--bg-elevated)"; }}
            onMouseLeave={(e) => { if (!isActive) e.currentTarget.style.background = "transparent"; }}
        >
            {icon}
            <span style={{ flex: 1 }}>{label}</span>
        </button>
    );
}

function SidebarSubItem({ label, icon, isActive, onClick }: {
    label: string; icon: ReactNode; isActive: boolean; onClick: () => void;
}) {
    return (
        <button
            onClick={onClick}
            style={{
                display: "flex", alignItems: "center", gap: "var(--space-sm)",
                padding: "8px 12px", width: "100%",
                borderRadius: "var(--radius-md)",
                background: isActive ? "rgba(139,92,246,0.06)" : "transparent",
                border: "none", cursor: "pointer",
                color: isActive ? "var(--color-accent)" : "var(--text-secondary)",
                fontSize: "0.82rem", fontWeight: isActive ? 600 : 400,
                transition: "all 0.15s ease", textAlign: "left",
            }}
            onMouseEnter={(e) => { if (!isActive) e.currentTarget.style.background = "var(--bg-elevated)"; }}
            onMouseLeave={(e) => { if (!isActive) e.currentTarget.style.background = "transparent"; }}
        >
            {icon}
            {label}
        </button>
    );
}
