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
   DATA — Shipping Policy Sections
   ============================================================ */

const SECTIONS = [
    {
        id: "pham-vi",
        title: "1. Phạm Vi Giao Hàng",
        paragraphs: [
            "StyleZone hỗ trợ giao hàng trên toàn bộ 63 tỉnh thành của Việt Nam, bao gồm cả khu vực nội thành, ngoại thành, vùng nông thôn và các huyện đảo có đường bưu chính. Đối với khu vực nội thành các thành phố lớn (TP.HCM, Hà Nội, Đà Nẵng, Cần Thơ), thời gian giao hàng thường nhanh hơn và có thể áp dụng dịch vụ giao hàng nhanh trong ngày (same-day delivery) cho các đơn hàng đặt trước 14h.",
            "Hiện tại StyleZone chưa hỗ trợ giao hàng quốc tế. Nếu bạn đang sinh sống ở nước ngoài và có nhu cầu mua hàng, vui lòng liên hệ trực tiếp qua email stylezone13579@gmail.com để được tư vấn phương án giao hàng phù hợp thông qua đối tác logistics quốc tế.",
        ],
    },
    {
        id: "thoi-gian",
        title: "2. Thời Gian Giao Hàng",
        paragraphs: [
            "Thời gian giao hàng dự kiến tùy thuộc vào khu vực nhận hàng: Nội thành TP.HCM và Hà Nội — 1–2 ngày làm việc. Các tỉnh thành lân cận (Bình Dương, Đồng Nai, Long An, Bắc Ninh, Hải Phòng...) — 2–3 ngày làm việc. Các tỉnh thành miền Trung — 3–4 ngày làm việc. Khu vực miền núi, hải đảo, vùng sâu vùng xa (Hà Giang, Lai Châu, Côn Đảo, Phú Quốc...) — 4–7 ngày làm việc.",
            "Thời gian giao hàng được tính từ khi đơn hàng đã được xác nhận, đóng gói và bàn giao cho đơn vị vận chuyển (thường trong vòng 24 giờ làm việc kể từ khi đặt hàng thành công). Trong các dịp cao điểm như Tết Nguyên Đán, Black Friday, 11/11, 12/12 hoặc các chương trình khuyến mãi lớn, thời gian xử lý và giao hàng có thể kéo dài thêm 1–3 ngày so với bình thường. Chúng tôi sẽ thông báo trước trên website nếu có ảnh hưởng đáng kể đến lịch giao hàng.",
        ],
    },
    {
        id: "phi-van-chuyen",
        title: "3. Phí Vận Chuyển",
        paragraphs: [
            "Miễn phí vận chuyển cho tất cả đơn hàng có giá trị từ 500.000đ trở lên (áp dụng toàn quốc, không giới hạn trọng lượng). Đối với đơn hàng có giá trị dưới 500.000đ, phí vận chuyển được tính dựa trên khu vực giao hàng: Nội thành TP.HCM, Hà Nội — 15.000đ. Các tỉnh thành lân cận — 20.000đ. Khu vực miền Trung, Tây Nguyên — 25.000đ. Vùng sâu, vùng xa, hải đảo — 30.000đ – 35.000đ.",
            "Phí vận chuyển sẽ được hiển thị rõ ràng và minh bạch tại bước thanh toán trước khi bạn xác nhận đơn hàng, không phát sinh thêm bất kỳ phụ phí nào. Một số chương trình khuyến mãi đặc biệt hoặc voucher freeship có thể áp dụng miễn phí vận chuyển không điều kiện — thông tin chi tiết sẽ được ghi rõ trên trang khuyến mãi hoặc mã voucher.",
        ],
    },
    {
        id: "doi-tac",
        title: "4. Đối Tác Vận Chuyển",
        paragraphs: [
            "StyleZone hợp tác với các đơn vị vận chuyển uy tín hàng đầu Việt Nam nhằm đảm bảo sản phẩm được giao đến tay bạn nhanh chóng và an toàn, bao gồm: GHN (Giao Hàng Nhanh), GHTK (Giao Hàng Tiết Kiệm), J&T Express và Viettel Post. Tùy vào khu vực và loại hình dịch vụ, hệ thống sẽ tự động chọn đơn vị vận chuyển tối ưu nhất cho đơn hàng của bạn.",
            "Ngay sau khi đơn hàng được bàn giao cho đơn vị vận chuyển, bạn sẽ nhận được mã vận đơn (tracking number) qua email hoặc SMS. Bạn có thể sử dụng mã này để theo dõi trạng thái giao hàng trực tiếp trên website của đơn vị vận chuyển hoặc ngay trên trang Lịch sử đơn hàng tại StyleZone. Nhân viên giao hàng sẽ liên hệ trước khi đến để đảm bảo bạn có mặt nhận hàng.",
        ],
    },
    {
        id: "kiem-tra",
        title: "5. Kiểm Tra Khi Nhận Hàng",
        paragraphs: [
            "Bạn có quyền và được khuyến khích kiểm tra sản phẩm tại chỗ trước khi ký nhận và thanh toán (đối với đơn COD). Vui lòng kiểm tra kỹ các nội dung sau: tình trạng bao bì đóng gói (nguyên vẹn, không bị méo, rách hoặc ướt), số lượng sản phẩm đúng với đơn hàng, đúng size/màu sắc/mẫu mã như đã đặt, và chất lượng sản phẩm không có lỗi rõ ràng.",
            "Nếu phát hiện sản phẩm bị hư hỏng do vận chuyển, sai mẫu mã, thiếu hàng hoặc bất kỳ vấn đề nào khác, bạn có quyền từ chối nhận toàn bộ hoặc một phần đơn hàng. Hãy ghi chú lý do từ chối cho nhân viên giao hàng và liên hệ ngay với chúng tôi qua email hoặc hotline 0867 642 831 để được xử lý trong thời gian sớm nhất. Chúng tôi cam kết giao lại đơn hàng đúng trong vòng 2–3 ngày làm việc.",
        ],
    },
    {
        id: "giao-that-bai",
        title: "6. Giao Hàng Không Thành Công",
        paragraphs: [
            "Trong trường hợp giao hàng không thành công do không liên lạc được với người nhận, không có người tại địa chỉ giao hàng, hoặc địa chỉ không chính xác, đơn vị vận chuyển sẽ tự động sắp xếp giao lại vào ngày làm việc tiếp theo, tối đa 2 lần giao lại. Sau 3 lần giao không thành công liên tiếp, đơn hàng sẽ được hoàn trả về kho StyleZone.",
            "Trong trường hợp đơn hàng bị hoàn do lỗi từ phía người nhận, bạn sẽ chịu phí vận chuyển hai chiều (giao đi + hoàn về). Phí hoàn hàng sẽ được trừ vào số tiền hoàn lại (nếu đã thanh toán trước) hoặc được thông báo rõ ràng trước khi gửi lại. Để tránh tình trạng giao hàng thất bại, vui lòng đảm bảo: số điện thoại liên lạc luôn mở, địa chỉ nhận hàng đầy đủ và chính xác (bao gồm tên tòa nhà, tầng, số phòng nếu ở chung cư), và có người nhận tại địa chỉ trong khung giờ giao hàng.",
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
                    Chính Sách Vận Chuyển
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
                <div ref={contentRef} className="shipping-layout" style={{ display: "grid", gridTemplateColumns: "220px 1fr", gap: "var(--space-3xl)", alignItems: "start" }}>
                    <nav className="shipping-sidebar" style={{ position: "sticky", top: "calc(var(--header-height) + 24px)", display: "flex", flexDirection: "column", gap: "2px", borderRight: "1px solid var(--border-color)", paddingRight: "var(--space-xl)" }}>
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



export default function ShippingPolicyPage() {
    return (
        <>
            <HeroBanner />
            <DocumentSection />
            <style jsx global>{`
                @media (max-width: 768px) {
                    .shipping-layout { grid-template-columns: 1fr !important; gap: var(--space-xl) !important; }
                    .shipping-sidebar { position: relative !important; top: 0 !important; border-right: none !important; border-bottom: 1px solid var(--border-color) !important; padding-right: 0 !important; padding-bottom: var(--space-lg) !important; flex-direction: row !important; flex-wrap: wrap !important; gap: var(--space-xs) !important; }
                    .shipping-sidebar > p:first-child { width: 100% !important; }
                }
            `}</style>
        </>
    );
}
