
/* ─── Settings Tab ─── */
export function SettingsTab({ onLogout }: { onLogout: () => void }) {
    return (
        <div>
            <h2 style={{ fontSize: "1.2rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: "4px" }}>Cài Đặt</h2>
            <p style={{ fontSize: "0.82rem", color: "var(--text-muted)", marginBottom: "var(--space-xl)" }}>Quản lý cài đặt tài khoản</p>
            <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-md)" }}>
                {/* Logout */}
                <div style={{ borderRadius: "var(--radius-xl)", border: "1px solid var(--border-color)", background: "var(--bg-card)", padding: "var(--space-xl)" }}>
                    <h3 style={{ fontSize: "0.9rem", fontWeight: 600, color: "var(--text-primary)", marginBottom: "var(--space-sm)" }}>Đăng xuất</h3>
                    <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginBottom: "var(--space-md)" }}>Đăng xuất khỏi tài khoản trên thiết bị này</p>
                    <button onClick={onLogout}
                        style={{ padding: "8px 20px", borderRadius: "var(--radius-md)", background: "transparent", border: "1.5px solid rgba(239,68,68,0.3)", color: "#ef4444", fontWeight: 600, fontSize: "0.82rem", cursor: "pointer", transition: "all 0.2s" }}
                        onMouseEnter={(e) => { e.currentTarget.style.background = "rgba(239,68,68,0.08)"; e.currentTarget.style.borderColor = "#ef4444"; }}
                        onMouseLeave={(e) => { e.currentTarget.style.background = "transparent"; e.currentTarget.style.borderColor = "rgba(239,68,68,0.3)"; }}>
                        Đăng xuất
                    </button>
                </div>
            </div>
        </div>
    );
}

