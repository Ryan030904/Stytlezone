"use client";

import { useState, useEffect, useRef } from "react";
import { onAuthStateChanged, User } from "firebase/auth";
import { doc, getDoc, setDoc, serverTimestamp } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { auth, db, storage } from "@/lib/firebase";
import { signOutUser } from "@/lib/auth";
import { toast } from "sonner";
import { useRouter } from "next/navigation";
import Image from "next/image";

interface UserProfile {
    displayName: string;
    email: string;
    phone: string;
    address: string;
    gender: string;
    birthday: string;
    photoURL: string;
}

const DEFAULT_PROFILE: UserProfile = {
    displayName: "",
    email: "",
    phone: "",
    address: "",
    gender: "",
    birthday: "",
    photoURL: "",
};

export default function ProfilePage() {
    const router = useRouter();
    const [user, setUser] = useState<User | null>(null);
    const [profile, setProfile] = useState<UserProfile>(DEFAULT_PROFILE);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [saved, setSaved] = useState(false);
    const [uploadingAvatar, setUploadingAvatar] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    // Listen for auth state
    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
            if (!firebaseUser) {
                router.push("/dang-nhap");
                return;
            }
            setUser(firebaseUser);

            // Fetch profile from Firestore
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
                        phone: "",
                        address: "",
                        gender: "",
                        birthday: "",
                        photoURL: firebaseUser.photoURL || "",
                    });
                }
            } catch {
                // Fallback to Firebase Auth data
                setProfile({
                    displayName: firebaseUser.displayName || "",
                    email: firebaseUser.email || "",
                    phone: "",
                    address: "",
                    gender: "",
                    birthday: "",
                    photoURL: firebaseUser.photoURL || "",
                });
            }
            setLoading(false);
        });
        return () => unsubscribe();
    }, [router]);

    const handleSave = async () => {
        if (!user) return;
        try {
            setSaving(true);
            const userRef = doc(db, "users", user.uid);
            await setDoc(
                userRef,
                {
                    displayName: profile.displayName,
                    phone: profile.phone,
                    address: profile.address,
                    gender: profile.gender,
                    birthday: profile.birthday,
                    updatedAt: serverTimestamp(),
                },
                { merge: true }
            );
            toast.success("Đã lưu thông tin thành công! ✓");
            setSaved(true);
            setTimeout(() => setSaved(false), 2500);
        } catch {
            toast.error("Lưu thất bại. Vui lòng thử lại.");
        } finally {
            setSaving(false);
        }
    };

    const handleLogout = async () => {
        await signOutUser();
        toast.success("Đã đăng xuất thành công!");
        router.push("/");
    };

    const updateField = (field: keyof UserProfile, value: string) => {
        setProfile((prev) => ({ ...prev, [field]: value }));
        setSaved(false);
    };

    const handleAvatarUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file || !user) return;

        // Validate file
        if (!file.type.startsWith("image/")) {
            toast.error("Vui lòng chọn file ảnh.");
            return;
        }
        if (file.size > 5 * 1024 * 1024) {
            toast.error("Ảnh không được lớn hơn 5MB.");
            return;
        }

        try {
            setUploadingAvatar(true);
            const storageRef = ref(storage, `avatars/${user.uid}`);
            await uploadBytes(storageRef, file);
            const downloadURL = await getDownloadURL(storageRef);

            // Update Firestore
            const userRef = doc(db, "users", user.uid);
            await setDoc(userRef, { photoURL: downloadURL, updatedAt: serverTimestamp() }, { merge: true });

            // Update local state
            setProfile((prev) => ({ ...prev, photoURL: downloadURL }));
            toast.success("Cập nhật ảnh đại diện thành công!");
        } catch {
            toast.error("Upload ảnh thất bại. Vui lòng thử lại.");
        } finally {
            setUploadingAvatar(false);
            // Reset input so the same file can be selected again
            if (fileInputRef.current) fileInputRef.current.value = "";
        }
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

    return (
        <div style={{ maxWidth: "720px", margin: "0 auto", padding: "calc(var(--header-height, 70px) + var(--space-2xl)) var(--space-lg) var(--space-2xl)" }}>
            {/* Header */}
            <div style={{ marginBottom: "var(--space-2xl)" }}>
                <h1 style={{ fontSize: "1.5rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "4px" }}>Tài Khoản</h1>
                <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>Quản lý thông tin cá nhân của bạn</p>
            </div>

            {/* Profile card */}
            <div style={{ borderRadius: "var(--radius-xl)", border: "1px solid var(--border-color)", background: "var(--bg-card)", overflow: "hidden" }}>
                {/* Avatar section */}
                <div style={{ padding: "var(--space-xl)", borderBottom: "1px solid var(--border-color)", display: "flex", alignItems: "center", gap: "var(--space-lg)" }}>
                    {/* Avatar with upload overlay */}
                    <div
                        onClick={() => !uploadingAvatar && fileInputRef.current?.click()}
                        style={{ width: "72px", height: "72px", borderRadius: "50%", overflow: "hidden", position: "relative", flexShrink: 0, background: "var(--bg-tertiary)", border: "3px solid var(--color-accent)", cursor: "pointer" }}
                    >
                        {profile.photoURL ? (
                            <Image src={profile.photoURL} alt="Avatar" fill sizes="72px" style={{ objectFit: "cover" }} />
                        ) : (
                            <div style={{ width: "100%", height: "100%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "1.5rem", fontWeight: 700, color: "var(--color-accent)", background: "rgba(139,92,246,0.1)" }}>
                                {profile.displayName?.charAt(0)?.toUpperCase() || "U"}
                            </div>
                        )}
                        {/* Camera overlay */}
                        <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.4)", display: "flex", alignItems: "center", justifyContent: "center", opacity: uploadingAvatar ? 1 : 0, transition: "opacity 0.2s ease" }}
                            onMouseEnter={(e) => { if (!uploadingAvatar) e.currentTarget.style.opacity = "1"; }}
                            onMouseLeave={(e) => { if (!uploadingAvatar) e.currentTarget.style.opacity = "0"; }}
                        >
                            {uploadingAvatar ? (
                                <div style={{ width: "20px", height: "20px", border: "2px solid rgba(255,255,255,0.3)", borderTopColor: "#fff", borderRadius: "50%", animation: "spin 0.8s linear infinite" }} />
                            ) : (
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
                                    <circle cx="12" cy="13" r="4" />
                                </svg>
                            )}
                        </div>
                        <input ref={fileInputRef} type="file" accept="image/*" onChange={handleAvatarUpload} style={{ display: "none" }} />
                    </div>
                    <div>
                        <h2 style={{ fontSize: "1.1rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "2px" }}>{profile.displayName || "Người dùng"}</h2>
                        <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>{profile.email}</p>
                        <p style={{ fontSize: "0.72rem", color: "var(--color-accent)", marginTop: "4px", cursor: "pointer" }} onClick={() => fileInputRef.current?.click()}>Đổi ảnh đại diện</p>
                    </div>
                </div>

                {/* Form fields */}
                <div style={{ padding: "var(--space-xl)" }}>
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-lg)" }}>
                        {/* Display Name */}
                        <FormField label="Họ và tên" value={profile.displayName} onChange={(v) => updateField("displayName", v)} placeholder="Nguyễn Văn A" />

                        {/* Email (readonly) */}
                        <FormField label="Email" value={profile.email} onChange={() => {}} placeholder="" disabled helperText="Email không thể thay đổi" />

                        {/* Phone */}
                        <FormField label="Số điện thoại" value={profile.phone} onChange={(v) => updateField("phone", v)} placeholder="0912 345 678" type="tel" />

                        {/* Gender */}
                        <div style={{ marginBottom: "0.5rem" }}>
                            <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "6px", letterSpacing: "0.03em" }}>Giới tính</label>
                            <select
                                value={profile.gender}
                                onChange={(e) => updateField("gender", e.target.value)}
                                style={{
                                    width: "100%",
                                    padding: "0.6rem 0.85rem",
                                    borderRadius: "var(--radius-md)",
                                    background: "var(--bg-elevated)",
                                    border: "1.5px solid var(--border-color)",
                                    color: profile.gender ? "var(--text-primary)" : "var(--text-muted)",
                                    fontSize: "0.85rem",
                                    outline: "none",
                                    cursor: "pointer",
                                    appearance: "none",
                                    WebkitAppearance: "none",
                                    backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`,
                                    backgroundPosition: "right 0.6rem center",
                                    backgroundRepeat: "no-repeat",
                                    backgroundSize: "1.2em 1.2em",
                                }}
                            >
                                <option value="">Chọn giới tính</option>
                                <option value="male">Nam</option>
                                <option value="female">Nữ</option>
                                <option value="other">Khác</option>
                            </select>
                        </div>

                        {/* Birthday */}
                        <FormField label="Ngày sinh" value={profile.birthday} onChange={(v) => updateField("birthday", v)} placeholder="" type="date" />

                        {/* Address — full width */}
                        <div style={{ gridColumn: "1 / -1" }}>
                            <FormField label="Địa chỉ" value={profile.address} onChange={(v) => updateField("address", v)} placeholder="Số nhà, đường, quận/huyện, thành phố" />
                        </div>
                    </div>

                    {/* Actions */}
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: "var(--space-xl)", paddingTop: "var(--space-lg)", borderTop: "1px solid var(--border-color)" }}>
                        <button
                            onClick={handleLogout}
                            style={{
                                padding: "0.55rem 1.2rem",
                                borderRadius: "var(--radius-md)",
                                background: "transparent",
                                border: "1.5px solid rgba(239,68,68,0.3)",
                                color: "#ef4444",
                                fontWeight: 600,
                                fontSize: "0.82rem",
                                cursor: "pointer",
                                transition: "all 0.2s ease",
                            }}
                            onMouseEnter={(e) => {
                                e.currentTarget.style.background = "rgba(239,68,68,0.08)";
                                e.currentTarget.style.borderColor = "#ef4444";
                            }}
                            onMouseLeave={(e) => {
                                e.currentTarget.style.background = "transparent";
                                e.currentTarget.style.borderColor = "rgba(239,68,68,0.3)";
                            }}
                        >
                            Đăng xuất
                        </button>

                        <div style={{ display: "flex", alignItems: "center", gap: "var(--space-md)" }}>
                            {saved && (
                                <span style={{ fontSize: "0.8rem", color: "#22c55e", fontWeight: 500, display: "flex", alignItems: "center", gap: "4px" }}>
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="20 6 9 17 4 12" /></svg>
                                    Đã lưu
                                </span>
                            )}
                            <button
                                onClick={handleSave}
                                disabled={saving}
                                style={{
                                    padding: "0.55rem 1.6rem",
                                    borderRadius: "var(--radius-md)",
                                    background: "var(--color-accent)",
                                    border: "none",
                                    color: "#fff",
                                    fontWeight: 700,
                                    fontSize: "0.85rem",
                                    cursor: saving ? "not-allowed" : "pointer",
                                    transition: "all 0.2s ease",
                                    opacity: saving ? 0.7 : 1,
                                }}
                                onMouseEnter={(e) => {
                                    if (!saving) {
                                        e.currentTarget.style.background = "var(--color-accent-hover)";
                                        e.currentTarget.style.transform = "translateY(-1px)";
                                        e.currentTarget.style.boxShadow = "var(--shadow-glow)";
                                    }
                                }}
                                onMouseLeave={(e) => {
                                    e.currentTarget.style.background = "var(--color-accent)";
                                    e.currentTarget.style.transform = "translateY(0)";
                                    e.currentTarget.style.boxShadow = "none";
                                }}
                            >
                                {saving ? "Đang lưu..." : "Lưu thay đổi"}
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <style jsx global>{`
                @keyframes spin {
                    to { transform: rotate(360deg); }
                }
                @media (max-width: 640px) {
                    div[style*="grid-template-columns: 1fr 1fr"] {
                        grid-template-columns: 1fr !important;
                    }
                }
            `}</style>
        </div>
    );
}

function FormField({
    label,
    value,
    onChange,
    placeholder,
    type = "text",
    disabled = false,
    helperText,
}: {
    label: string;
    value: string;
    onChange: (v: string) => void;
    placeholder: string;
    type?: string;
    disabled?: boolean;
    helperText?: string;
}) {
    const [focused, setFocused] = useState(false);
    return (
        <div style={{ marginBottom: "0.5rem" }}>
            <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "6px", letterSpacing: "0.03em" }}>{label}</label>
            <input
                type={type}
                value={value}
                onChange={(e) => onChange(e.target.value)}
                placeholder={placeholder}
                disabled={disabled}
                onFocus={() => setFocused(true)}
                onBlur={() => setFocused(false)}
                style={{
                    width: "100%",
                    padding: "0.6rem 0.85rem",
                    borderRadius: "var(--radius-md)",
                    background: disabled ? "var(--bg-tertiary)" : "var(--bg-elevated)",
                    border: `1.5px solid ${focused ? "var(--color-accent)" : "var(--border-color)"}`,
                    color: disabled ? "var(--text-muted)" : "var(--text-primary)",
                    fontSize: "0.85rem",
                    transition: "border-color 0.2s, box-shadow 0.2s",
                    boxShadow: focused ? "0 0 0 3px rgba(139,92,246,0.10)" : "none",
                    outline: "none",
                    cursor: disabled ? "not-allowed" : "text",
                    opacity: disabled ? 0.7 : 1,
                }}
            />
            {helperText && (
                <p style={{ fontSize: "0.7rem", color: "var(--text-muted)", marginTop: "4px" }}>{helperText}</p>
            )}
        </div>
    );
}
