"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";

/* ============================================================
   HOOKS
   ============================================================ */

type RevealDirection = "up" | "down" | "left" | "right" | "scale";

function useReveal(
    direction: RevealDirection = "up",
    { threshold = 0.12, delay = 0 }: { threshold?: number; delay?: number } = {}
) {
    const ref = useRef<HTMLDivElement>(null);
    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        el.classList.add(`reveal-${direction}`);
        if (delay > 0) el.style.transitionDelay = `${delay}s`;
        const obs = new IntersectionObserver(
            ([entry]) => {
                if (entry.isIntersecting) {
                    el.classList.add("visible");
                    obs.unobserve(el);
                }
            },
            { threshold, rootMargin: "0px 0px -40px 0px" }
        );
        obs.observe(el);
        return () => obs.disconnect();
    }, [direction, threshold, delay]);
    return ref;
}

/* ============================================================
   DATA — Return Policy Sections
   ============================================================ */

const SECTIONS = [
    {
        id: "dieu-kien",
        title: "1. Điều Kiện Đổi Trả",
        paragraphs: [
            "Sản phẩm được chấp nhận đổi trả trong vòng 7 ngày kể từ ngày bạn nhận hàng thành công (theo xác nhận của đơn vị vận chuyển). Sản phẩm phải đáp ứng đầy đủ các điều kiện: còn nguyên tem mác và nhãn hiệu, chưa qua sử dụng hoặc mặc thử quá mức cần thiết, chưa giặt ủi hoặc tẩy rửa, không có mùi nước hoa hoặc mùi lạ, không có vết bẩn hoặc hư hại do người dùng gây ra, và còn trong tình trạng ban đầu kèm đầy đủ bao bì đóng gói, phụ kiện đi kèm (nếu có).",
            "Sản phẩm đổi trả cần được gửi kèm hóa đơn mua hàng hoặc mã đơn hàng để xác minh giao dịch. Trong trường hợp không còn hóa đơn, chúng tôi sẽ xác minh thông qua hệ thống quản lý đơn hàng nội bộ dựa trên email, số điện thoại hoặc tên người nhận hàng. Việc cung cấp thông tin chính xác sẽ giúp đẩy nhanh quy trình xử lý.",
        ],
    },
    {
        id: "khong-ap-dung",
        title: "2. Sản Phẩm Không Áp Dụng",
        paragraphs: [
            "Một số loại sản phẩm không nằm trong chính sách đổi trả bao gồm: đồ lót (bra, underwear, đồ bơi), tất/vớ, phụ kiện cá nhân (khẩu trang, khăn tay, mũ), trang sức thời trang, sản phẩm đã được cá nhân hóa hoặc thiết kế theo yêu cầu riêng, và các sản phẩm trong chương trình flash sale, clearance hoặc giảm giá đặc biệt có ghi rõ \"Không đổi trả\" trên trang sản phẩm.",
            "Ngoài ra, sản phẩm bị hư hỏng, biến dạng, bẩn hoặc có dấu hiệu đã sử dụng do lỗi từ phía người mua cũng sẽ không được chấp nhận đổi trả. Chúng tôi sẽ thông báo chi tiết về tình trạng kiểm tra sản phẩm nếu yêu cầu đổi trả bị từ chối, kèm theo hình ảnh minh chứng.",
        ],
    },
    {
        id: "quy-trinh",
        title: "3. Quy Trình Đổi Trả",
        paragraphs: [
            "Bước 1 — Gửi yêu cầu: Liên hệ đội ngũ hỗ trợ qua email stylezone13579@gmail.com hoặc trang Liên hệ, cung cấp mã đơn hàng, tên sản phẩm cần đổi trả, lý do cụ thể và hình ảnh sản phẩm (nếu có). Bước 2 — Xác nhận: Chúng tôi sẽ xem xét yêu cầu và phản hồi trong vòng 24 giờ làm việc. Nếu yêu cầu hợp lệ, bạn sẽ nhận được hướng dẫn gửi trả và mã vận đơn trả hàng (nếu được hỗ trợ ship miễn phí).",
            "Bước 3 — Gửi sản phẩm: Bạn đóng gói sản phẩm cẩn thận trong bao bì chống sốc và gửi về địa chỉ kho hàng theo hướng dẫn. Khuyến khích chụp ảnh sản phẩm và biên nhận gửi hàng làm bằng chứng. Bước 4 — Kiểm tra và xử lý: Sau khi nhận sản phẩm, đội ngũ QC sẽ kiểm tra trong 1–2 ngày làm việc. Nếu đạt điều kiện, chúng tôi tiến hành đổi sản phẩm mới hoặc hoàn tiền theo yêu cầu của bạn.",
        ],
    },
    {
        id: "hoan-tien",
        title: "4. Chính Sách Hoàn Tiền",
        paragraphs: [
            "Hoàn tiền được xử lý trong vòng 5–10 ngày làm việc kể từ khi sản phẩm trả lại đã được kiểm tra và xác nhận đạt điều kiện. Tiền hoàn sẽ được chuyển về đúng phương thức thanh toán ban đầu: thẻ ngân hàng (Visa, Mastercard) — 5–7 ngày làm việc, ví điện tử (MoMo, VNPay) — 1–3 ngày làm việc, chuyển khoản ngân hàng — 3–5 ngày làm việc.",
            "Đối với đơn hàng thanh toán khi nhận hàng (COD), tiền hoàn sẽ được chuyển khoản vào tài khoản ngân hàng do bạn cung cấp. Bạn cần cung cấp đầy đủ thông tin: tên chủ tài khoản, số tài khoản, tên ngân hàng và chi nhánh. Lưu ý: Trong trường hợp sản phẩm đã được áp dụng voucher giảm giá, số tiền hoàn sẽ là số tiền thực tế bạn đã thanh toán (sau khi trừ giảm giá). Voucher đã sử dụng sẽ không được hoàn lại.",
        ],
    },
    {
        id: "doi-size",
        title: "5. Đổi Size & Màu Sắc",
        paragraphs: [
            "StyleZone hỗ trợ đổi size hoặc màu sắc miễn phí (bao gồm cả phí vận chuyển hai chiều) cho lần đổi đầu tiên của mỗi sản phẩm trong đơn hàng. Từ lần đổi thứ hai trở đi, bạn sẽ chịu phí vận chuyển một chiều (từ 15.000đ đến 35.000đ tùy khu vực). Quy trình đổi size/màu tương tự quy trình đổi trả chuẩn.",
            "Việc đổi size hoặc màu sắc phụ thuộc vào tình trạng tồn kho tại thời điểm xử lý. Trong trường hợp size/màu bạn mong muốn đã hết hàng, chúng tôi sẽ chủ động liên hệ để tư vấn lựa chọn thay thế phù hợp hoặc hoàn tiền đầy đủ theo yêu cầu của bạn. Để chọn size chính xác, vui lòng tham khảo bảng hướng dẫn size chi tiết trên mỗi trang sản phẩm.",
        ],
    },
    {
        id: "loi-san-xuat",
        title: "6. Sản Phẩm Lỗi Sản Xuất",
        paragraphs: [
            "Trong trường hợp sản phẩm bị lỗi do nhà sản xuất (chỉ bị tuột, nút hỏng hoặc cài không chặt, in ấn bị lệch/nhòe/sai màu, vải bị rách sẵn hoặc có lỗ thủng, khóa kéo bị kẹt hoặc hỏng, màu sắc bị loang hoặc khác biệt đáng kể so với mô tả), StyleZone cam kết chấp nhận đổi trả không giới hạn thời gian (trong phạm vi hợp lý) và chịu toàn bộ phí vận chuyển hai chiều.",
            "Để được xử lý nhanh nhất, vui lòng chụp ảnh rõ nét hoặc quay video ngắn thể hiện lỗi sản phẩm và gửi kèm yêu cầu đổi trả qua email hoặc trang Liên hệ. Chúng tôi sẽ xác nhận lỗi và xử lý trong vòng 24 giờ. Bạn có thể lựa chọn đổi sản phẩm mới cùng loại, chọn sản phẩm khác có giá trị tương đương, hoặc nhận hoàn tiền đầy đủ.",
        ],
    },
];

/* ============================================================
   COMPONENTS
   ============================================================ */

function HeroBanner() {
    return (
        <section
            style={{
                position: "relative",
                minHeight: "38vh",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                overflow: "hidden",
                background: "linear-gradient(160deg, #0f0720 0%, #1a103f 40%, #2d1b69 70%, #1a103f 100%)",
            }}
        >
            <div style={{ position: "absolute", top: "10%", left: "10%", width: "260px", height: "260px", borderRadius: "50%", background: "radial-gradient(circle, rgba(139,92,246,0.18) 0%, transparent 70%)", animation: "float 7s ease-in-out infinite", pointerEvents: "none" }} />
            <div style={{ position: "absolute", bottom: "5%", right: "8%", width: "200px", height: "200px", borderRadius: "50%", background: "radial-gradient(circle, rgba(168,85,247,0.12) 0%, transparent 70%)", animation: "float 9s ease-in-out infinite reverse", pointerEvents: "none" }} />

            <div className="container animate-slide-up" style={{ position: "relative", zIndex: 2, textAlign: "center", paddingTop: "calc(var(--header-height) + var(--space-2xl))", paddingBottom: "var(--space-2xl)" }}>
                <h1 style={{
                    fontSize: "clamp(2.2rem, 5vw, 3.5rem)",
                    fontWeight: 900,
                    lineHeight: 1.1,
                    letterSpacing: "-0.03em",
                    color: "#ffffff",
                    textShadow: "0 2px 16px rgba(139,92,246,0.4), 0 4px 32px rgba(0,0,0,0.3)",
                }}>
                    Chính Sách Đổi Trả
                </h1>
            </div>
        </section>
    );
}

function DocumentSection() {
    const [activeId, setActiveId] = useState(SECTIONS[0].id);
    const sectionRefs = useRef<Map<string, HTMLDivElement>>(new Map());
    const contentRef = useReveal("up");

    useEffect(() => {
        const observers: IntersectionObserver[] = [];
        sectionRefs.current.forEach((el, id) => {
            const obs = new IntersectionObserver(
                ([entry]) => {
                    if (entry.isIntersecting) setActiveId(id);
                },
                { threshold: 0.3, rootMargin: "-100px 0px -50% 0px" }
            );
            obs.observe(el);
            observers.push(obs);
        });
        return () => observers.forEach((o) => o.disconnect());
    }, []);

    const scrollToSection = (id: string) => {
        const el = sectionRefs.current.get(id);
        if (el) el.scrollIntoView({ behavior: "smooth", block: "start" });
    };

    return (
        <section className="section">
            <div className="container">
                <div ref={contentRef} className="return-layout" style={{ display: "grid", gridTemplateColumns: "220px 1fr", gap: "var(--space-3xl)", alignItems: "start" }}>
                    <nav className="return-sidebar" style={{ position: "sticky", top: "calc(var(--header-height) + 24px)", display: "flex", flexDirection: "column", gap: "2px", borderRight: "1px solid var(--border-color)", paddingRight: "var(--space-xl)" }}>
                        <p style={{ fontSize: "0.68rem", fontWeight: 700, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--text-muted)", marginBottom: "var(--space-md)" }}>Mục lục</p>
                        {SECTIONS.map((s) => (
                            <button key={s.id} onClick={() => scrollToSection(s.id)} style={{ textAlign: "left", padding: "8px 12px", borderRadius: "var(--radius-md)", fontSize: "0.82rem", fontWeight: activeId === s.id ? 600 : 400, color: activeId === s.id ? "var(--color-accent)" : "var(--text-secondary)", background: activeId === s.id ? "rgba(139,92,246,0.08)" : "transparent", transition: "all 0.2s ease", cursor: "pointer", lineHeight: 1.4 }}>
                                {s.title}
                            </button>
                        ))}
                    </nav>
                    <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-3xl)" }}>
                        {SECTIONS.map((section, index) => (
                            <ContentBlock key={section.id} section={section} index={index} sectionRefs={sectionRefs} />
                        ))}
                    </div>
                </div>
            </div>
        </section>
    );
}

function ContentBlock({ section, index, sectionRefs }: { section: typeof SECTIONS[number]; index: number; sectionRefs: React.MutableRefObject<Map<string, HTMLDivElement>> }) {
    const blockRef = useReveal("up", { delay: index * 0.05 });
    return (
        <div ref={(el) => { if (el) { sectionRefs.current.set(section.id, el); if (blockRef.current === null) (blockRef as React.MutableRefObject<HTMLDivElement | null>).current = el; } }} id={section.id} style={{ scrollMarginTop: "calc(var(--header-height) + 24px)" }}>
            <h2 style={{ fontSize: "1.2rem", fontWeight: 700, letterSpacing: "-0.02em", color: "var(--text-primary)", marginBottom: "var(--space-lg)", paddingBottom: "var(--space-sm)", borderBottom: "1px solid var(--border-color)" }}>{section.title}</h2>
            <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-md)" }}>
                {section.paragraphs.map((p, i) => (
                    <p key={i} style={{ fontSize: "0.9rem", lineHeight: 1.85, color: "var(--text-secondary)" }}>{p}</p>
                ))}
            </div>
        </div>
    );
}



export default function ReturnPolicyPage() {
    return (
        <>
            <HeroBanner />
            <DocumentSection />
            <style jsx global>{`
                @media (max-width: 768px) {
                    .return-layout { grid-template-columns: 1fr !important; gap: var(--space-xl) !important; }
                    .return-sidebar { position: relative !important; top: 0 !important; border-right: none !important; border-bottom: 1px solid var(--border-color) !important; padding-right: 0 !important; padding-bottom: var(--space-lg) !important; flex-direction: row !important; flex-wrap: wrap !important; gap: var(--space-xs) !important; }
                    .return-sidebar > p:first-child { width: 100% !important; }
                }
            `}</style>
        </>
    );
}
