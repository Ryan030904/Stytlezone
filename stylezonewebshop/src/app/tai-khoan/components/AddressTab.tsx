"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { getAddresses, addAddress, updateAddress, deleteAddress, setDefaultAddress } from "@/lib/addresses";
import type { UserAddress } from "@/lib/types";
import { toast } from "sonner";

/* ─── Province API types ─── */
interface Province { code: number; name: string; }
interface District { code: number; name: string; }
interface Ward { code: number; name: string; }

/* ─── Reusable Custom Dropdown ─── */
function CascadeDropdown({ label, required, placeholder, value, options, disabled, onChange }: {
    label: string; required?: boolean; placeholder: string;
    value: number; options: { code: number; name: string }[];
    disabled?: boolean; onChange: (code: number, name: string) => void;
}) {
    const [open, setOpen] = useState(false);
    const [search, setSearch] = useState("");
    const ref = useRef<HTMLDivElement>(null);
    const searchRef = useRef<HTMLInputElement>(null);
    const selectedName = options.find(o => o.code === value)?.name || "";

    const filtered = search
        ? options.filter(o => o.name.toLowerCase().includes(search.toLowerCase()))
        : options;

    useEffect(() => {
        const handler = (e: MouseEvent) => {
            if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
        };
        document.addEventListener("mousedown", handler);
        return () => document.removeEventListener("mousedown", handler);
    }, []);

    useEffect(() => {
        if (open && searchRef.current) setTimeout(() => searchRef.current?.focus(), 50);
    }, [open]);

    return (
        <div ref={ref} style={{ position: "relative" }}>
            <label style={{
                fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)",
                marginBottom: "4px", display: "block",
            }}>
                {label} {required && <span style={{ color: "#ef4444" }}>*</span>}
            </label>
            <button
                type="button"
                disabled={disabled}
                onClick={() => !disabled && setOpen(!open)}
                style={{
                    width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
                    border: open ? "1.5px solid var(--color-accent)" : "1.5px solid var(--border-color)",
                    background: disabled ? "var(--bg-surface)" : "var(--bg-primary)",
                    color: selectedName ? "var(--text-primary)" : "var(--text-muted)",
                    fontSize: "0.83rem", textAlign: "left", outline: "none",
                    cursor: disabled ? "not-allowed" : "pointer",
                    transition: "border-color 0.2s, box-shadow 0.2s",
                    display: "flex", alignItems: "center", justifyContent: "space-between",
                    boxShadow: open ? "0 0 0 3px rgba(139,92,246,0.1)" : "none",
                    opacity: disabled ? 0.5 : 1,
                }}
            >
                <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {selectedName || placeholder}
                </span>
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"
                    style={{ flexShrink: 0, transition: "transform 0.2s", transform: open ? "rotate(180deg)" : "rotate(0deg)", opacity: 0.4 }}>
                    <polyline points="6 9 12 15 18 9" />
                </svg>
            </button>

            {open && (
                <div style={{
                    position: "absolute", top: "calc(100% + 4px)", left: 0, right: 0, zIndex: 999,
                    borderRadius: "var(--radius-lg)", border: "1px solid var(--border-color)",
                    background: "var(--bg-card)", boxShadow: "0 12px 36px rgba(0,0,0,0.25)",
                    overflow: "hidden", animation: "cascadeDdIn 0.15s ease",
                }}>
                    {options.length > 8 && (
                        <div style={{ padding: "8px", borderBottom: "1px solid var(--border-color)" }}>
                            <div style={{ position: "relative" }}>
                                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="var(--text-muted)" strokeWidth="2"
                                    style={{ position: "absolute", left: "8px", top: "50%", transform: "translateY(-50%)" }}>
                                    <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
                                </svg>
                                <input ref={searchRef} type="text" placeholder="Tìm kiếm..."
                                    value={search} onChange={e => setSearch(e.target.value)}
                                    style={{
                                        width: "100%", padding: "6px 10px 6px 28px",
                                        borderRadius: "var(--radius-sm)", border: "1px solid var(--border-color)",
                                        background: "var(--bg-surface)", color: "var(--text-primary)",
                                        fontSize: "0.8rem", outline: "none",
                                    }}
                                    onFocus={e => e.currentTarget.style.borderColor = "var(--color-accent)"}
                                    onBlur={e => e.currentTarget.style.borderColor = "var(--border-color)"}
                                />
                            </div>
                        </div>
                    )}
                    <div style={{ maxHeight: "200px", overflowY: "auto", padding: "4px 0" }}>
                        {filtered.length === 0 ? (
                            <div style={{ padding: "12px", textAlign: "center", color: "var(--text-muted)", fontSize: "0.8rem" }}>
                                Không tìm thấy
                            </div>
                        ) : filtered.map(o => {
                            const isSelected = o.code === value;
                            return (
                                <button key={o.code} type="button"
                                    onClick={() => { onChange(o.code, o.name); setOpen(false); setSearch(""); }}
                                    style={{
                                        display: "flex", alignItems: "center", justifyContent: "space-between",
                                        width: "100%", padding: "8px 12px", border: "none",
                                        fontSize: "0.82rem", textAlign: "left", cursor: "pointer",
                                        fontWeight: isSelected ? 600 : 400,
                                        color: isSelected ? "var(--color-accent)" : "var(--text-secondary)",
                                        background: isSelected ? "rgba(139,92,246,0.06)" : "transparent",
                                        transition: "all 0.12s",
                                    }}
                                    onMouseEnter={e => { if (!isSelected) { e.currentTarget.style.background = "rgba(255,255,255,0.04)"; e.currentTarget.style.color = "var(--text-primary)"; } }}
                                    onMouseLeave={e => { if (!isSelected) { e.currentTarget.style.background = "transparent"; e.currentTarget.style.color = "var(--text-secondary)"; } }}
                                >
                                    {o.name}
                                    {isSelected && (
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" strokeWidth="2.5">
                                            <polyline points="20 6 9 17 4 12" />
                                        </svg>
                                    )}
                                </button>
                            );
                        })}
                    </div>
                </div>
            )}
        </div>
    );
}

/* ─── Empty form data ─── */
const EMPTY_FORM = {
    fullName: "", phone: "", province: "", provinceCode: 0,
    district: "", districtCode: 0, ward: "", wardCode: 0,
    street: "", note: "", isDefault: false,
};

/* ─── Component ─── */
export default function AddressTab({ uid }: { uid: string }) {
    const [addresses, setAddresses] = useState<UserAddress[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [form, setForm] = useState(EMPTY_FORM);
    const [saving, setSaving] = useState(false);
    const [deletingId, setDeletingId] = useState<string | null>(null);

    const [provinces, setProvinces] = useState<Province[]>([]);
    const [districts, setDistricts] = useState<District[]>([]);
    const [wards, setWards] = useState<Ward[]>([]);

    const fetchAddresses = useCallback(async () => {
        try {
            const list = await getAddresses(uid);
            setAddresses(list);
        } catch {
            toast.error("Không thể tải danh sách địa chỉ");
        } finally {
            setLoading(false);
        }
    }, [uid]);

    useEffect(() => { fetchAddresses(); }, [fetchAddresses]);

    useEffect(() => {
        fetch("https://provinces.open-api.vn/api/p/")
            .then(r => r.json())
            .then((data: Province[]) => setProvinces(data))
            .catch(() => {});
    }, []);

    useEffect(() => {
        if (!form.provinceCode) { setDistricts([]); return; }
        setDistricts([]); setWards([]);
        fetch(`https://provinces.open-api.vn/api/p/${form.provinceCode}?depth=2`)
            .then(r => r.json())
            .then((data: { districts: District[] }) => setDistricts(data.districts || []))
            .catch(() => {});
    }, [form.provinceCode]);

    useEffect(() => {
        if (!form.districtCode) { setWards([]); return; }
        setWards([]);
        fetch(`https://provinces.open-api.vn/api/d/${form.districtCode}?depth=2`)
            .then(r => r.json())
            .then((data: { wards: Ward[] }) => setWards(data.wards || []))
            .catch(() => {});
    }, [form.districtCode]);

    const openAddModal = () => {
        setEditingId(null);
        setForm({ ...EMPTY_FORM, isDefault: addresses.length === 0 });
        setDistricts([]); setWards([]);
        setShowModal(true);
    };

    const openEditModal = (addr: UserAddress) => {
        setEditingId(addr.id);
        setForm({
            fullName: addr.fullName, phone: addr.phone,
            province: addr.province, provinceCode: addr.provinceCode,
            district: addr.district, districtCode: addr.districtCode,
            ward: addr.ward, wardCode: addr.wardCode,
            street: addr.street, note: addr.note, isDefault: addr.isDefault,
        });
        setShowModal(true);
    };

    const handleSave = async () => {
        if (!form.fullName.trim()) { toast.error("Vui lòng nhập họ tên"); return; }
        if (!form.phone.trim()) { toast.error("Vui lòng nhập số điện thoại"); return; }
        if (!form.province) { toast.error("Vui lòng chọn tỉnh/thành phố"); return; }
        if (!form.district) { toast.error("Vui lòng chọn quận/huyện"); return; }
        if (!form.ward) { toast.error("Vui lòng chọn phường/xã"); return; }
        if (!form.street.trim()) { toast.error("Vui lòng nhập địa chỉ cụ thể"); return; }
        try {
            setSaving(true);
            if (editingId) {
                await updateAddress(uid, editingId, form);
                toast.success("Cập nhật địa chỉ thành công!");
            } else {
                await addAddress(uid, form);
                toast.success("Thêm địa chỉ mới thành công!");
            }
            setShowModal(false);
            await fetchAddresses();
        } catch {
            toast.error("Có lỗi xảy ra. Vui lòng thử lại.");
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async (id: string) => {
        try {
            setDeletingId(id);
            await deleteAddress(uid, id);
            toast.success("Đã xóa địa chỉ");
            await fetchAddresses();
        } catch {
            toast.error("Không thể xóa địa chỉ");
        } finally {
            setDeletingId(null);
        }
    };

    const handleSetDefault = async (id: string) => {
        try {
            await setDefaultAddress(uid, id);
            toast.success("Đã đặt làm địa chỉ mặc định");
            await fetchAddresses();
        } catch {
            toast.error("Có lỗi xảy ra");
        }
    };

    const formatFullAddress = (addr: UserAddress) =>
        [addr.street, addr.ward, addr.district, addr.province].filter(Boolean).join(", ");

    const cardStyle: React.CSSProperties = {
        borderRadius: "var(--radius-xl)", border: "1px solid var(--border-color)",
        background: "var(--bg-card)", padding: "var(--space-xl)",
        transition: "border-color 0.2s, box-shadow 0.2s",
    };
    const inputStyle: React.CSSProperties = {
        width: "100%", padding: "8px 12px", borderRadius: "var(--radius-md)",
        border: "1.5px solid var(--border-color)", background: "var(--bg-primary)",
        color: "var(--text-primary)", fontSize: "0.83rem", outline: "none",
        transition: "border-color 0.2s",
    };
    const btnPrimary: React.CSSProperties = {
        padding: "8px 20px", borderRadius: "var(--radius-md)", background: "var(--color-accent)",
        border: "none", color: "#fff", fontWeight: 600, fontSize: "0.83rem",
        cursor: "pointer", transition: "all 0.2s",
    };
    const btnOutline: React.CSSProperties = {
        padding: "8px 20px", borderRadius: "var(--radius-md)", background: "transparent",
        border: "1.5px solid var(--border-color)", color: "var(--text-primary)",
        fontWeight: 500, fontSize: "0.83rem", cursor: "pointer", transition: "all 0.2s",
    };

    if (loading) {
        return (
            <div style={{ textAlign: "center", padding: "var(--space-4xl)", color: "var(--text-muted)" }}>
                <div style={{ width: "32px", height: "32px", border: "3px solid var(--border-color)", borderTopColor: "var(--color-accent)", borderRadius: "50%", animation: "spin 0.8s linear infinite", margin: "0 auto var(--space-md)" }} />
                Đang tải...
            </div>
        );
    }

    return (
        <div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "var(--space-xl)" }}>
                <div>
                    <h2 style={{ fontSize: "1.2rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "4px" }}>Địa Chỉ Của Tôi</h2>
                    <p style={{ fontSize: "0.82rem", color: "var(--text-muted)" }}>Quản lý địa chỉ giao hàng</p>
                </div>
                <button onClick={openAddModal} style={btnPrimary}
                    onMouseEnter={(e) => { e.currentTarget.style.opacity = "0.85"; e.currentTarget.style.transform = "translateY(-1px)"; }}
                    onMouseLeave={(e) => { e.currentTarget.style.opacity = "1"; e.currentTarget.style.transform = "translateY(0)"; }}
                >
                    + Thêm Địa Chỉ Mới
                </button>
            </div>

            {addresses.length === 0 ? (
                <div style={{ ...cardStyle, textAlign: "center", padding: "var(--space-4xl)" }}>
                    <svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" style={{ margin: "0 auto var(--space-lg)", opacity: 0.25, color: "var(--text-muted)" }}>
                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" />
                    </svg>
                    <p style={{ fontSize: "0.95rem", color: "var(--text-muted)" }}>Bạn chưa có địa chỉ nào</p>
                    <p style={{ fontSize: "0.82rem", color: "var(--text-muted)", marginTop: "4px" }}>Bấm nút ở trên để thêm địa chỉ giao hàng</p>
                </div>
            ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-md)" }}>
                    {addresses.map((addr) => (
                        <div key={addr.id} style={{
                            ...cardStyle,
                            borderColor: addr.isDefault ? "var(--color-accent)" : "var(--border-color)",
                            position: "relative",
                        }}
                            onMouseEnter={(e) => { if (!addr.isDefault) e.currentTarget.style.borderColor = "rgba(139,92,246,0.3)"; }}
                            onMouseLeave={(e) => { if (!addr.isDefault) e.currentTarget.style.borderColor = "var(--border-color)"; }}
                        >
                            {addr.isDefault && (
                                <span style={{
                                    position: "absolute", top: "12px", right: "12px",
                                    padding: "3px 10px", borderRadius: "var(--radius-sm)",
                                    background: "rgba(139,92,246,0.1)", color: "var(--color-accent)",
                                    fontSize: "0.72rem", fontWeight: 600, border: "1px solid rgba(139,92,246,0.2)",
                                }}>
                                    Mặc định
                                </span>
                            )}
                            <div style={{ display: "flex", gap: "var(--space-md)", marginBottom: "var(--space-md)" }}>
                                <div style={{ display: "flex", alignItems: "center", gap: "var(--space-sm)" }}>
                                    <span style={{ fontWeight: 600, color: "var(--text-primary)", fontSize: "0.9rem" }}>{addr.fullName}</span>
                                    <span style={{ color: "var(--border-color)" }}>|</span>
                                    <span style={{ color: "var(--text-secondary)", fontSize: "0.85rem" }}>{addr.phone}</span>
                                </div>
                            </div>
                            <p style={{ fontSize: "0.85rem", color: "var(--text-secondary)", lineHeight: 1.6, marginBottom: "var(--space-sm)" }}>
                                {formatFullAddress(addr)}
                            </p>
                            {addr.note && (
                                <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", fontStyle: "italic" }}>
                                    Ghi chú: {addr.note}
                                </p>
                            )}
                            <div style={{ display: "flex", gap: "var(--space-md)", marginTop: "var(--space-md)", paddingTop: "var(--space-md)", borderTop: "1px solid var(--border-color)" }}>
                                <button onClick={() => openEditModal(addr)}
                                    style={{ background: "none", border: "none", color: "var(--color-accent)", fontSize: "0.82rem", fontWeight: 500, cursor: "pointer", padding: 0 }}
                                    onMouseEnter={(e) => e.currentTarget.style.textDecoration = "underline"}
                                    onMouseLeave={(e) => e.currentTarget.style.textDecoration = "none"}
                                >Chỉnh sửa</button>
                                {!addr.isDefault && (
                                    <>
                                        <button onClick={() => handleDelete(addr.id)} disabled={deletingId === addr.id}
                                            style={{ background: "none", border: "none", color: "#ef4444", fontSize: "0.82rem", fontWeight: 500, cursor: "pointer", padding: 0, opacity: deletingId === addr.id ? 0.5 : 1 }}
                                            onMouseEnter={(e) => e.currentTarget.style.textDecoration = "underline"}
                                            onMouseLeave={(e) => e.currentTarget.style.textDecoration = "none"}
                                        >{deletingId === addr.id ? "Đang xóa..." : "Xóa"}</button>
                                        <button onClick={() => handleSetDefault(addr.id)}
                                            style={{ background: "none", border: "none", color: "var(--text-secondary)", fontSize: "0.82rem", fontWeight: 500, cursor: "pointer", padding: 0 }}
                                            onMouseEnter={(e) => e.currentTarget.style.textDecoration = "underline"}
                                            onMouseLeave={(e) => e.currentTarget.style.textDecoration = "none"}
                                        >Đặt mặc định</button>
                                    </>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {showModal && (
                <div style={{
                    position: "fixed", inset: 0, zIndex: 9999,
                    display: "flex", alignItems: "center", justifyContent: "center",
                    background: "rgba(0,0,0,0.5)", backdropFilter: "blur(4px)",
                    animation: "fadeIn 0.2s ease",
                }}
                    onClick={(e) => { if (e.target === e.currentTarget) setShowModal(false); }}
                >
                    <div style={{
                        background: "var(--bg-card)", borderRadius: "var(--radius-2xl)",
                        width: "100%", maxWidth: "620px",
                        padding: "24px 28px 20px", boxShadow: "0 25px 60px rgba(0,0,0,0.3)",
                        animation: "slideUp 0.3s ease",
                    }}>
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
                            <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "var(--text-primary)" }}>
                                {editingId ? "Chỉnh Sửa Địa Chỉ" : "Thêm Địa Chỉ Mới"}
                            </h3>
                            <button onClick={() => setShowModal(false)} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--text-muted)", padding: "4px" }}>
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
                            </button>
                        </div>

                        <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px" }}>
                                <div>
                                    <label style={{ fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "4px", display: "block" }}>Họ và tên <span style={{ color: "#ef4444" }}>*</span></label>
                                    <input value={form.fullName} onChange={(e) => setForm(f => ({ ...f, fullName: e.target.value }))}
                                        placeholder="Nguyễn Văn A" style={inputStyle}
                                        onFocus={(e) => e.currentTarget.style.borderColor = "var(--color-accent)"}
                                        onBlur={(e) => e.currentTarget.style.borderColor = "var(--border-color)"} />
                                </div>
                                <div>
                                    <label style={{ fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "4px", display: "block" }}>Số điện thoại <span style={{ color: "#ef4444" }}>*</span></label>
                                    <input value={form.phone} onChange={(e) => setForm(f => ({ ...f, phone: e.target.value }))}
                                        placeholder="0912 345 678" style={inputStyle}
                                        onFocus={(e) => e.currentTarget.style.borderColor = "var(--color-accent)"}
                                        onBlur={(e) => e.currentTarget.style.borderColor = "var(--border-color)"} />
                                </div>
                            </div>

                            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "12px" }}>
                                <CascadeDropdown
                                    label="Tỉnh/TP" required placeholder="Chọn Tỉnh/TP"
                                    value={form.provinceCode} options={provinces}
                                    onChange={(code, name) => setForm(f => ({ ...f, provinceCode: code, province: name, districtCode: 0, district: "", wardCode: 0, ward: "" }))}
                                />
                                <CascadeDropdown
                                    label="Quận/Huyện" required placeholder="Chọn Quận/Huyện"
                                    value={form.districtCode} options={districts}
                                    disabled={!form.provinceCode}
                                    onChange={(code, name) => setForm(f => ({ ...f, districtCode: code, district: name, wardCode: 0, ward: "" }))}
                                />
                                <CascadeDropdown
                                    label="Phường/Xã" required placeholder="Chọn Phường/Xã"
                                    value={form.wardCode} options={wards}
                                    disabled={!form.districtCode}
                                    onChange={(code, name) => setForm(f => ({ ...f, wardCode: code, ward: name }))}
                                />
                            </div>

                            <div style={{ display: "grid", gridTemplateColumns: "1.2fr 0.8fr", gap: "12px" }}>
                                <div>
                                    <label style={{ fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "4px", display: "block" }}>Địa chỉ cụ thể <span style={{ color: "#ef4444" }}>*</span></label>
                                    <input value={form.street} onChange={(e) => setForm(f => ({ ...f, street: e.target.value }))}
                                        placeholder="Số nhà, tên đường..." style={inputStyle}
                                        onFocus={(e) => e.currentTarget.style.borderColor = "var(--color-accent)"}
                                        onBlur={(e) => e.currentTarget.style.borderColor = "var(--border-color)"} />
                                </div>
                                <div>
                                    <label style={{ fontSize: "0.75rem", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "4px", display: "block" }}>Ghi chú</label>
                                    <input value={form.note} onChange={(e) => setForm(f => ({ ...f, note: e.target.value }))}
                                        placeholder="VD: Giao giờ hành chính..." style={inputStyle}
                                        onFocus={(e) => e.currentTarget.style.borderColor = "var(--color-accent)"}
                                        onBlur={(e) => e.currentTarget.style.borderColor = "var(--border-color)"} />
                                </div>
                            </div>

                            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "4px", paddingTop: "12px", borderTop: "1px solid var(--border-color)" }}>
                                <label style={{ display: "flex", alignItems: "center", gap: "6px", cursor: "pointer", fontSize: "0.83rem", color: "var(--text-primary)" }}>
                                    <input type="checkbox" checked={form.isDefault}
                                        onChange={(e) => setForm(f => ({ ...f, isDefault: e.target.checked }))}
                                        style={{ width: "15px", height: "15px", accentColor: "var(--color-accent)" }} />
                                    Đặt làm mặc định
                                </label>
                                <div style={{ display: "flex", gap: "10px" }}>
                                    <button onClick={() => setShowModal(false)} style={btnOutline}
                                        onMouseEnter={(e) => e.currentTarget.style.borderColor = "var(--text-muted)"}
                                        onMouseLeave={(e) => e.currentTarget.style.borderColor = "var(--border-color)"}
                                    >Hủy</button>
                                    <button onClick={handleSave} disabled={saving} style={{ ...btnPrimary, opacity: saving ? 0.7 : 1, cursor: saving ? "not-allowed" : "pointer" }}>
                                        {saving ? "Đang lưu..." : (editingId ? "Cập Nhật" : "Thêm Địa Chỉ")}
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            <style jsx>{`
                @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
                @keyframes slideUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
                @keyframes cascadeDdIn { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
            `}</style>
        </div>
    );
}
