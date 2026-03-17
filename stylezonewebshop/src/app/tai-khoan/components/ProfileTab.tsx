"use client";

import { useState, useRef, useEffect, useCallback } from "react";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { db, storage } from "@/lib/firebase";
import { toast } from "sonner";
import Image from "next/image";

export interface UserProfile {
    displayName: string;
    email: string;
    phone: string;
    address: string;
    gender: string;
    birthday: string;
    photoURL: string;
}

const GENDER_OPTIONS = [
    { value: "", label: "Chọn giới tính" },
    { value: "male", label: "Nam" },
    { value: "female", label: "Nữ" },
    { value: "other", label: "Khác" },
];

export default function ProfileTab({ uid, profile, setProfile }: {
    uid: string;
    profile: UserProfile;
    setProfile: React.Dispatch<React.SetStateAction<UserProfile>>;
}) {
    const [saving, setSaving] = useState(false);
    const [saved, setSaved] = useState(false);
    const [uploadingAvatar, setUploadingAvatar] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const updateField = (field: keyof UserProfile, value: string) => {
        setProfile((prev) => ({ ...prev, [field]: value }));
        setSaved(false);
    };

    const handleSave = async () => {
        try {
            setSaving(true);
            const userRef = doc(db, "users", uid);
            await setDoc(userRef, {
                displayName: profile.displayName,
                phone: profile.phone,
                gender: profile.gender,
                birthday: profile.birthday,
                updatedAt: serverTimestamp(),
            }, { merge: true });
            toast.success("Đã lưu thông tin thành công! ✓");
            setSaved(true);
            setTimeout(() => setSaved(false), 2500);
        } catch {
            toast.error("Lưu thất bại. Vui lòng thử lại.");
        } finally {
            setSaving(false);
        }
    };

    const handleAvatarUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        if (!file.type.startsWith("image/")) { toast.error("Vui lòng chọn file ảnh."); return; }
        if (file.size > 5 * 1024 * 1024) { toast.error("Ảnh không được lớn hơn 5MB."); return; }
        try {
            setUploadingAvatar(true);
            const storageRef = ref(storage, `avatars/${uid}`);
            await uploadBytes(storageRef, file);
            const downloadURL = await getDownloadURL(storageRef);
            const userRef = doc(db, "users", uid);
            await setDoc(userRef, { photoURL: downloadURL, updatedAt: serverTimestamp() }, { merge: true });
            setProfile((prev) => ({ ...prev, photoURL: downloadURL }));
            toast.success("Cập nhật ảnh đại diện thành công!");
        } catch {
            toast.error("Upload ảnh thất bại.");
        } finally {
            setUploadingAvatar(false);
            if (fileInputRef.current) fileInputRef.current.value = "";
        }
    };

    return (
        <div>
            <h2 style={{ fontSize: "1.2rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "4px" }}>Hồ Sơ Của Tôi</h2>
            <p style={{ fontSize: "0.82rem", color: "var(--text-muted)", marginBottom: "var(--space-xl)" }}>Quản lý thông tin cá nhân để bảo mật tài khoản</p>

            <div style={{ borderRadius: "var(--radius-xl)", border: "1px solid var(--border-color)", background: "var(--bg-card)", overflow: "hidden" }}>
                {/* Avatar */}
                <div style={{ padding: "var(--space-xl)", borderBottom: "1px solid var(--border-color)", display: "flex", alignItems: "center", gap: "var(--space-lg)" }}>
                    <div onClick={() => !uploadingAvatar && fileInputRef.current?.click()}
                        style={{ width: "72px", height: "72px", borderRadius: "50%", overflow: "hidden", position: "relative", flexShrink: 0, border: "3px solid var(--color-accent)", cursor: "pointer" }}>
                        {profile.photoURL ? (
                            <Image src={profile.photoURL} alt="Avatar" fill sizes="72px" style={{ objectFit: "cover" }} />
                        ) : (
                            <div style={{ width: "100%", height: "100%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "1.5rem", fontWeight: 700, color: "var(--color-accent)", background: "rgba(139,92,246,0.1)" }}>
                                {profile.displayName?.charAt(0)?.toUpperCase() || "U"}
                            </div>
                        )}
                        <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.4)", display: "flex", alignItems: "center", justifyContent: "center", opacity: uploadingAvatar ? 1 : 0, transition: "opacity 0.2s" }}
                            onMouseEnter={(e) => { if (!uploadingAvatar) e.currentTarget.style.opacity = "1"; }}
                            onMouseLeave={(e) => { if (!uploadingAvatar) e.currentTarget.style.opacity = "0"; }}>
                            {uploadingAvatar ? (
                                <div style={{ width: "20px", height: "20px", border: "2px solid rgba(255,255,255,0.3)", borderTopColor: "#fff", borderRadius: "50%", animation: "spin 0.8s linear infinite" }} />
                            ) : (
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" /><circle cx="12" cy="13" r="4" /></svg>
                            )}
                        </div>
                        <input ref={fileInputRef} type="file" accept="image/*" onChange={handleAvatarUpload} style={{ display: "none" }} />
                    </div>
                    <div>
                        <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "2px" }}>{profile.displayName || "Người dùng"}</h3>
                        <p style={{ fontSize: "0.78rem", color: "var(--text-muted)" }}>{profile.email}</p>
                        <p style={{ fontSize: "0.72rem", color: "var(--color-accent)", marginTop: "4px", cursor: "pointer" }} onClick={() => fileInputRef.current?.click()}>Đổi ảnh đại diện</p>
                    </div>
                </div>

                {/* Form */}
                <div style={{ padding: "var(--space-xl)" }}>
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-lg)" }}>
                        <FormField label="Họ và tên" value={profile.displayName} onChange={(v) => updateField("displayName", v)} placeholder="Nguyễn Văn A" />
                        <FormField label="Email" value={profile.email} onChange={() => {}} disabled helperText="Email không thể thay đổi" />
                        <FormField label="Số điện thoại" value={profile.phone} onChange={(v) => updateField("phone", v)} placeholder="0912 345 678" type="tel" />
                        <GenderDropdown value={profile.gender} onChange={(v) => updateField("gender", v)} />
                        <FormField label="Ngày sinh" value={profile.birthday} onChange={(v) => updateField("birthday", v)} type="date" />
                    </div>

                    {/* Save */}
                    <div style={{ display: "flex", justifyContent: "flex-end", marginTop: "var(--space-xl)", paddingTop: "var(--space-lg)", borderTop: "1px solid var(--border-color)", gap: "var(--space-md)", alignItems: "center" }}>
                        {saved && (
                            <span style={{ fontSize: "0.8rem", color: "#22c55e", fontWeight: 500, display: "flex", alignItems: "center", gap: "4px" }}>
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="20 6 9 17 4 12" /></svg>
                                Đã lưu
                            </span>
                        )}
                        <button onClick={handleSave} disabled={saving}
                            style={{ padding: "0.55rem 1.6rem", borderRadius: "var(--radius-md)", background: "var(--color-accent)", border: "none", color: "#fff", fontWeight: 700, fontSize: "0.85rem", cursor: saving ? "not-allowed" : "pointer", opacity: saving ? 0.7 : 1 }}
                            onMouseEnter={(e) => { if (!saving) { e.currentTarget.style.background = "var(--color-accent-hover)"; e.currentTarget.style.transform = "translateY(-1px)"; } }}
                            onMouseLeave={(e) => { e.currentTarget.style.background = "var(--color-accent)"; e.currentTarget.style.transform = "translateY(0)"; }}>
                            {saving ? "Đang lưu..." : "Lưu thay đổi"}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}

/* ─── Custom Gender Dropdown ─── */
function GenderDropdown({ value, onChange }: { value: string; onChange: (v: string) => void }) {
    const [isOpen, setIsOpen] = useState(false);
    const dropdownRef = useRef<HTMLDivElement>(null);
    const selected = GENDER_OPTIONS.find((o) => o.value === value) || GENDER_OPTIONS[0];

    const handleClose = useCallback((e: MouseEvent) => {
        if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
            setIsOpen(false);
        }
    }, []);

    useEffect(() => {
        document.addEventListener("mousedown", handleClose);
        return () => document.removeEventListener("mousedown", handleClose);
    }, [handleClose]);

    return (
        <div style={{ marginBottom: "0.5rem" }}>
            <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "6px" }}>Giới tính</label>
            <div ref={dropdownRef} style={{ position: "relative" }}>
                {/* Trigger */}
                <button
                    type="button"
                    onClick={() => setIsOpen(!isOpen)}
                    style={{
                        width: "100%", padding: "0.6rem 0.85rem", borderRadius: "var(--radius-md)",
                        background: "var(--bg-elevated)", border: `1.5px solid ${isOpen ? "var(--color-accent)" : "var(--border-color)"}`,
                        color: value ? "var(--text-primary)" : "var(--text-muted)", fontSize: "0.85rem",
                        textAlign: "left", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "space-between",
                        transition: "border-color 0.2s, box-shadow 0.2s",
                        boxShadow: isOpen ? "0 0 0 3px rgba(139,92,246,0.10)" : "none",
                    }}
                >
                    {selected.label}
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
                        style={{ transition: "transform 0.2s", transform: isOpen ? "rotate(180deg)" : "rotate(0)", flexShrink: 0, opacity: 0.5 }}>
                        <polyline points="6 9 12 15 18 9" />
                    </svg>
                </button>

                {/* Dropdown menu */}
                {isOpen && (
                    <div style={{
                        position: "absolute", top: "calc(100% + 6px)", left: 0, right: 0, zIndex: 50,
                        background: "var(--bg-card)", border: "1px solid var(--border-color)",
                        borderRadius: "var(--radius-md)", boxShadow: "0 8px 24px rgba(0,0,0,0.12)",
                        overflow: "hidden", animation: "fadeInDown 0.15s ease",
                    }}>
                        {GENDER_OPTIONS.map((option) => (
                            <button
                                key={option.value}
                                type="button"
                                onClick={() => { onChange(option.value); setIsOpen(false); }}
                                style={{
                                    width: "100%", padding: "10px 14px", border: "none", textAlign: "left",
                                    fontSize: "0.84rem", cursor: "pointer", display: "flex", alignItems: "center", gap: "8px",
                                    background: option.value === value ? "rgba(139,92,246,0.08)" : "transparent",
                                    color: option.value === value ? "var(--color-accent)" : "var(--text-primary)",
                                    fontWeight: option.value === value ? 600 : 400,
                                    transition: "background 0.12s",
                                }}
                                onMouseEnter={(e) => { if (option.value !== value) e.currentTarget.style.background = "var(--bg-elevated)"; }}
                                onMouseLeave={(e) => { if (option.value !== value) e.currentTarget.style.background = "transparent"; }}
                            >
                                {option.value === value && (
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2.5"><polyline points="20 6 9 17 4 12" /></svg>
                                )}
                                {option.label}
                            </button>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}

function FormField({ label, value, onChange, placeholder = "", type = "text", disabled = false, helperText }: {
    label: string; value: string; onChange: (v: string) => void; placeholder?: string; type?: string; disabled?: boolean; helperText?: string;
}) {
    const [focused, setFocused] = useState(false);
    return (
        <div style={{ marginBottom: "0.5rem" }}>
            <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "6px" }}>{label}</label>
            <input type={type} value={value} onChange={(e) => onChange(e.target.value)} placeholder={placeholder} disabled={disabled}
                onFocus={() => setFocused(true)} onBlur={() => setFocused(false)}
                style={{ width: "100%", padding: "0.6rem 0.85rem", borderRadius: "var(--radius-md)", background: disabled ? "var(--bg-tertiary)" : "var(--bg-elevated)", border: `1.5px solid ${focused ? "var(--color-accent)" : "var(--border-color)"}`, color: disabled ? "var(--text-muted)" : "var(--text-primary)", fontSize: "0.85rem", transition: "border-color 0.2s, box-shadow 0.2s", boxShadow: focused ? "0 0 0 3px rgba(139,92,246,0.10)" : "none", outline: "none", cursor: disabled ? "not-allowed" : "text", opacity: disabled ? 0.7 : 1 }} />
            {helperText && <p style={{ fontSize: "0.7rem", color: "var(--text-muted)", marginTop: "4px" }}>{helperText}</p>}
        </div>
    );
}
