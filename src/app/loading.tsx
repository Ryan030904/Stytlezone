export default function Loading() {
    return (
        <div
            style={{
                position: "fixed",
                inset: 0,
                zIndex: 9999,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                background: "var(--bg-primary)",
            }}
        >
            {/* Outer glow ring */}
            <div
                style={{
                    position: "absolute",
                    width: "80px",
                    height: "80px",
                    borderRadius: "50%",
                    border: "3px solid rgba(139,92,246,0.08)",
                }}
            />
            {/* Spinning ring */}
            <div
                style={{
                    width: "80px",
                    height: "80px",
                    borderRadius: "50%",
                    border: "3px solid transparent",
                    borderTopColor: "#8B5CF6",
                    borderRightColor: "rgba(139,92,246,0.3)",
                    animation: "spin 0.8s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite",
                    boxShadow: "0 0 24px rgba(139,92,246,0.15)",
                }}
            />
            {/* Center dot */}
            <div
                style={{
                    position: "absolute",
                    width: "8px",
                    height: "8px",
                    borderRadius: "50%",
                    background: "#8B5CF6",
                    animation: "pulse-glow 1.5s ease infinite",
                }}
            />

            <style>{`
                @keyframes spin {
                    to { transform: rotate(360deg); }
                }
            `}</style>
        </div>
    );
}
