"use client";

import Link from "next/link";

export default function GenderPickerModal({ onClose }: { onClose: () => void }) {
    return (
        <div
            style={{
                position: "fixed",
                inset: 0,
                zIndex: 1000,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                padding: "var(--space-md)",
            }}
        >
            {/* Backdrop */}
            <div
                style={{
                    position: "absolute",
                    inset: 0,
                    background: "rgba(0,0,0,0.7)",
                    backdropFilter: "blur(6px)",
                }}
                onClick={onClose}
            />

            {/* Modal */}
            <div
                style={{
                    position: "relative",
                    background: "var(--bg-card)",
                    border: "1px solid var(--border-color)",
                    borderRadius: "var(--radius-xl)",
                    padding: "var(--space-2xl) var(--space-xl)",
                    maxWidth: "420px",
                    width: "100%",
                    textAlign: "center",
                    animation: "modal-in 0.3s cubic-bezier(0.16, 1, 0.3, 1)",
                }}
            >
                {/* Close button */}
                <button
                    onClick={onClose}
                    style={{
                        position: "absolute",
                        top: "12px",
                        right: "12px",
                        width: "30px",
                        height: "30px",
                        borderRadius: "50%",
                        border: "1px solid var(--border-color)",
                        background: "var(--bg-surface)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        cursor: "pointer",
                        color: "var(--text-muted)",
                        transition: "all 0.2s",
                    }}
                    onMouseEnter={(e) => {
                        e.currentTarget.style.borderColor = "var(--text-primary)";
                        e.currentTarget.style.color = "var(--text-primary)";
                    }}
                    onMouseLeave={(e) => {
                        e.currentTarget.style.borderColor = "var(--border-color)";
                        e.currentTarget.style.color = "var(--text-muted)";
                    }}
                >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                        <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                </button>

                <p
                    style={{
                        fontSize: "0.75rem",
                        fontWeight: 600,
                        letterSpacing: "0.12em",
                        textTransform: "uppercase",
                        color: "var(--color-accent)",
                        marginBottom: "var(--space-sm)",
                    }}
                >
                    Bạn muốn xem
                </p>
                <h3
                    style={{
                        fontSize: "1.3rem",
                        fontWeight: 700,
                        color: "var(--text-primary)",
                        marginBottom: "var(--space-xl)",
                    }}
                >
                    Thời trang dành cho?
                </h3>

                {/* Gender cards */}
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-md)" }}>
                    {/* Male */}
                    <Link
                        href="/nam"
                        onClick={onClose}
                        style={{
                            display: "flex",
                            flexDirection: "column",
                            alignItems: "center",
                            gap: "var(--space-md)",
                            padding: "var(--space-xl) var(--space-md)",
                            borderRadius: "var(--radius-lg)",
                            border: "1.5px solid var(--border-color)",
                            background: "var(--bg-surface)",
                            textDecoration: "none",
                            transition: "all 0.3s ease",
                            cursor: "pointer",
                        }}
                        onMouseEnter={(e) => {
                            e.currentTarget.style.borderColor = "rgba(99,102,241,0.5)";
                            e.currentTarget.style.background = "rgba(99,102,241,0.06)";
                            e.currentTarget.style.transform = "translateY(-4px)";
                            e.currentTarget.style.boxShadow = "0 12px 28px rgba(99,102,241,0.15)";
                        }}
                        onMouseLeave={(e) => {
                            e.currentTarget.style.borderColor = "var(--border-color)";
                            e.currentTarget.style.background = "var(--bg-surface)";
                            e.currentTarget.style.transform = "translateY(0)";
                            e.currentTarget.style.boxShadow = "none";
                        }}
                    >
                        {/* Male icon */}
                        <div
                            style={{
                                width: "56px",
                                height: "56px",
                                borderRadius: "50%",
                                background: "rgba(99,102,241,0.1)",
                                border: "1px solid rgba(99,102,241,0.2)",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                            }}
                        >
                            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#6366f1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <circle cx="10" cy="14" r="5" />
                                <line x1="19" y1="5" x2="13.6" y2="10.4" />
                                <polyline points="19 5 19 11" /><polyline points="19 5 13 5" />
                            </svg>
                        </div>
                        <span style={{ fontSize: "0.95rem", fontWeight: 700, color: "var(--text-primary)" }}>Nam</span>
                    </Link>

                    {/* Female */}
                    <Link
                        href="/nu"
                        onClick={onClose}
                        style={{
                            display: "flex",
                            flexDirection: "column",
                            alignItems: "center",
                            gap: "var(--space-md)",
                            padding: "var(--space-xl) var(--space-md)",
                            borderRadius: "var(--radius-lg)",
                            border: "1.5px solid var(--border-color)",
                            background: "var(--bg-surface)",
                            textDecoration: "none",
                            transition: "all 0.3s ease",
                            cursor: "pointer",
                        }}
                        onMouseEnter={(e) => {
                            e.currentTarget.style.borderColor = "rgba(236,72,153,0.5)";
                            e.currentTarget.style.background = "rgba(236,72,153,0.06)";
                            e.currentTarget.style.transform = "translateY(-4px)";
                            e.currentTarget.style.boxShadow = "0 12px 28px rgba(236,72,153,0.15)";
                        }}
                        onMouseLeave={(e) => {
                            e.currentTarget.style.borderColor = "var(--border-color)";
                            e.currentTarget.style.background = "var(--bg-surface)";
                            e.currentTarget.style.transform = "translateY(0)";
                            e.currentTarget.style.boxShadow = "none";
                        }}
                    >
                        {/* Female icon */}
                        <div
                            style={{
                                width: "56px",
                                height: "56px",
                                borderRadius: "50%",
                                background: "rgba(236,72,153,0.1)",
                                border: "1px solid rgba(236,72,153,0.2)",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                            }}
                        >
                            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#ec4899" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <circle cx="12" cy="8" r="5" />
                                <line x1="12" y1="13" x2="12" y2="21" />
                                <line x1="9" y1="18" x2="15" y2="18" />
                            </svg>
                        </div>
                        <span style={{ fontSize: "0.95rem", fontWeight: 700, color: "var(--text-primary)" }}>Nữ</span>
                    </Link>
                </div>

                <style>{`
                    @keyframes modal-in {
                        from { opacity: 0; transform: translateY(16px) scale(0.96); }
                        to { opacity: 1; transform: translateY(0) scale(1); }
                    }
                `}</style>
            </div>
        </div>
    );
}
