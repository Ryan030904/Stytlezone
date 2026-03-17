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
   DATA — Terms of Service Sections
   ============================================================ */

const SECTIONS = [
    {
        id: "chap-nhan",
        title: "1. Chấp Nhận Điều Khoản",
        paragraphs: [
            "Khi truy cập, duyệt web, đăng ký tài khoản hoặc thực hiện bất kỳ giao dịch nào trên website StyleZone (stylezone.vn), bạn mặc nhiên đồng ý tuân thủ đầy đủ các điều khoản và điều kiện được nêu trong tài liệu này. Các điều khoản này tạo thành một thỏa thuận ràng buộc pháp lý giữa bạn (\"Người dùng\") và Công ty TNHH StyleZone (\"Chúng tôi\"). Nếu bạn không đồng ý với bất kỳ điều khoản nào, vui lòng ngừng sử dụng website và các dịch vụ liên quan ngay lập tức.",
            "Các điều khoản này áp dụng cho tất cả người dùng, bao gồm nhưng không giới hạn: khách truy cập chưa đăng ký, thành viên đã có tài khoản, người mua hàng, và bất kỳ ai tương tác với nội dung hoặc dịch vụ của StyleZone thông qua website, ứng dụng di động hoặc các kênh trực tuyến khác. Chúng tôi khuyến khích bạn đọc kỹ toàn bộ điều khoản trước khi sử dụng dịch vụ.",
        ],
    },
    {
        id: "tai-khoan",
        title: "2. Tài Khoản Người Dùng",
        paragraphs: [
            "Khi đăng ký tài khoản tại StyleZone, bạn cam kết cung cấp thông tin chính xác, đầy đủ và cập nhật. Bạn chịu hoàn toàn trách nhiệm về việc bảo mật thông tin đăng nhập, bao gồm địa chỉ email, mật khẩu và mọi hoạt động diễn ra dưới tài khoản của mình. Trong trường hợp phát hiện truy cập trái phép hoặc nghi ngờ tài khoản bị xâm nhập, bạn phải thông báo cho chúng tôi ngay lập tức qua email hoặc hotline.",
            "StyleZone bảo lưu quyền tạm khóa, hạn chế hoặc xóa vĩnh viễn tài khoản trong các trường hợp sau: vi phạm điều khoản sử dụng, cung cấp thông tin sai lệch, hành vi gian lận hoặc lạm dụng dịch vụ, sử dụng tài khoản cho mục đích phi pháp, hoặc tài khoản không hoạt động trong thời gian dài (trên 24 tháng). Quyết định khóa tài khoản sẽ được thông báo qua email đăng ký kèm theo lý do cụ thể.",
            "Mỗi cá nhân chỉ được phép sở hữu một tài khoản duy nhất. Việc tạo nhiều tài khoản để lợi dụng chương trình khuyến mãi, voucher hoặc ưu đãi thành viên mới là vi phạm nghiêm trọng và có thể dẫn đến hủy bỏ toàn bộ các tài khoản liên quan.",
        ],
    },
    {
        id: "dat-hang",
        title: "3. Đặt Hàng & Thanh Toán",
        paragraphs: [
            "Khi đặt hàng tại StyleZone, bạn cam kết cung cấp thông tin giao hàng và thanh toán chính xác. Đơn hàng chỉ được xác nhận sau khi hệ thống gửi email/SMS xác nhận đơn hàng thành công. Giá sản phẩm hiển thị trên website đã bao gồm thuế VAT nhưng chưa bao gồm phí vận chuyển (nếu có). Giá sản phẩm có thể thay đổi theo chương trình khuyến mãi hoặc điều kiện thị trường mà không cần thông báo trước, tuy nhiên giá tại thời điểm bạn hoàn tất đơn hàng sẽ là giá được áp dụng.",
            "Chúng tôi bảo lưu quyền từ chối, hủy hoặc giới hạn số lượng đơn hàng trong các trường hợp: lỗi hệ thống dẫn đến hiển thị giá sai, sản phẩm hết hàng sau khi đặt, nghi ngờ giao dịch gian lận, hoặc đơn hàng vi phạm giới hạn mua (nếu có). Trong trường hợp hủy đơn hàng đã thanh toán, chúng tôi cam kết hoàn tiền đầy đủ trong vòng 5–10 ngày làm việc.",
            "Thanh toán được xử lý thông qua các cổng thanh toán bảo mật đã được chứng nhận PCI-DSS, bao gồm: thanh toán khi nhận hàng (COD), chuyển khoản ngân hàng, thẻ tín dụng/ghi nợ quốc tế (Visa, Mastercard), và ví điện tử (MoMo, VNPay, ZaloPay). StyleZone tuyệt đối không lưu trữ thông tin thẻ tín dụng hoặc thông tin thanh toán nhạy cảm trên hệ thống.",
        ],
    },
    {
        id: "doi-tra",
        title: "4. Đổi Trả & Hoàn Tiền",
        paragraphs: [
            "Sản phẩm được chấp nhận đổi trả trong vòng 7 ngày kể từ ngày bạn nhận hàng, với các điều kiện bắt buộc: còn nguyên tem mác, chưa qua sử dụng, chưa giặt ủi, chưa tẩy rửa, và còn trong tình trạng ban đầu kèm bao bì đóng gói. Sản phẩm trong các chương trình flash sale, clearance, hoặc giảm giá đặc biệt (từ 50% trở lên) có thể không áp dụng chính sách đổi trả — thông tin cụ thể sẽ được ghi rõ trên trang sản phẩm.",
            "Hoàn tiền sẽ được xử lý trong vòng 5–10 ngày làm việc sau khi sản phẩm trả lại đã được kiểm tra và xác nhận đạt điều kiện. Tiền hoàn sẽ được chuyển về phương thức thanh toán ban đầu hoặc tài khoản ngân hàng do bạn chỉ định. Chi tiết đầy đủ về quy trình đổi trả được quy định tại trang Chính Sách Đổi Trả.",
        ],
    },
    {
        id: "so-huu",
        title: "5. Sở Hữu Trí Tuệ",
        paragraphs: [
            "Toàn bộ nội dung hiển thị trên website StyleZone — bao gồm nhưng không giới hạn: logo, nhãn hiệu, thiết kế giao diện, hình ảnh sản phẩm, video, bài viết, bố cục trang, mã nguồn (HTML, CSS, JavaScript), cơ sở dữ liệu sản phẩm và nội dung marketing — là tài sản trí tuệ thuộc sở hữu của StyleZone hoặc các đối tác đã cấp phép sử dụng hợp pháp.",
            "Nghiêm cấm mọi hành vi sao chép, tải xuống hàng loạt, trích xuất dữ liệu (scraping), phân phối, chỉnh sửa, tái sử dụng, hoặc khai thác thương mại bất kỳ nội dung nào từ website mà không có sự đồng ý bằng văn bản của StyleZone. Vi phạm quyền sở hữu trí tuệ sẽ bị xử lý theo quy định pháp luật Việt Nam về Luật Sở hữu trí tuệ và các quy định quốc tế liên quan.",
            "Người dùng được phép chia sẻ liên kết (link) đến các trang sản phẩm hoặc bài viết trên website cho mục đích cá nhân, phi thương mại, miễn là không gây hiểu lầm về mối quan hệ với StyleZone.",
        ],
    },
    {
        id: "gioi-han",
        title: "6. Giới Hạn Trách Nhiệm",
        paragraphs: [
            "StyleZone nỗ lực tối đa để đảm bảo thông tin sản phẩm (mô tả, hình ảnh, giá cả, tình trạng tồn kho) trên website luôn chính xác và cập nhật. Tuy nhiên, do tính chất của thương mại điện tử, chúng tôi không thể đảm bảo tuyệt đối rằng mọi thông tin đều không có sai sót. Màu sắc sản phẩm hiển thị trên website có thể khác biệt nhỏ so với thực tế do sự khác nhau giữa các thiết bị hiển thị.",
            "StyleZone không chịu trách nhiệm cho các thiệt hại trực tiếp, gián tiếp, ngẫu nhiên hoặc hệ quả phát sinh từ: lỗi kỹ thuật hoặc gián đoạn hệ thống, truy cập trái phép từ bên thứ ba, mất dữ liệu do sự cố ngoài tầm kiểm soát, hoặc việc sử dụng thông tin trên website cho mục đích không phù hợp. Tổng trách nhiệm bồi thường của StyleZone trong mọi trường hợp sẽ không vượt quá giá trị đơn hàng liên quan.",
        ],
    },
    {
        id: "tranh-chap",
        title: "7. Giải Quyết Tranh Chấp",
        paragraphs: [
            "Mọi tranh chấp phát sinh từ hoặc liên quan đến việc sử dụng dịch vụ của StyleZone sẽ được ưu tiên giải quyết thông qua thương lượng trực tiếp giữa hai bên. Bạn có thể gửi khiếu nại qua email stylezone13579@gmail.com hoặc hotline 0867 642 831 trong giờ làm việc. Chúng tôi cam kết phản hồi khiếu nại trong vòng 48 giờ và nỗ lực giải quyết trong thời gian sớm nhất.",
            "Trong trường hợp không thể giải quyết qua thương lượng, tranh chấp sẽ được đưa ra cơ quan có thẩm quyền tại Thành phố Cần Thơ để giải quyết theo quy định pháp luật Việt Nam hiện hành. Các điều khoản này được điều chỉnh và giải thích theo pháp luật nước Cộng hòa Xã hội Chủ nghĩa Việt Nam.",
        ],
    },
    {
        id: "thay-doi",
        title: "8. Thay Đổi Điều Khoản",
        paragraphs: [
            "StyleZone bảo lưu quyền thay đổi, bổ sung hoặc cập nhật bất kỳ điều khoản nào trong tài liệu này vào bất kỳ thời điểm nào. Phiên bản mới nhất sẽ luôn được đăng tải trên trang này với ngày cập nhật rõ ràng. Trong trường hợp có thay đổi quan trọng ảnh hưởng đến quyền và nghĩa vụ của người dùng, chúng tôi sẽ thông báo qua email hoặc banner trên website trước ít nhất 7 ngày.",
            "Việc bạn tiếp tục sử dụng dịch vụ sau ngày các điều khoản mới có hiệu lực đồng nghĩa với việc bạn chấp nhận và đồng ý tuân thủ các thay đổi đó. Nếu không đồng ý với điều khoản mới, bạn có quyền ngừng sử dụng dịch vụ và yêu cầu xóa tài khoản. Chúng tôi khuyến khích bạn kiểm tra trang này định kỳ để cập nhật thông tin. Cập nhật lần cuối: Tháng 3, 2026.",
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
                    Điều Khoản Sử Dụng
                </h1>
            </div>
        </section>
    );
}

/* Sidebar Table of Contents + Content — document-style layout */
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
        if (el) {
            el.scrollIntoView({ behavior: "smooth", block: "start" });
        }
    };

    return (
        <section className="section">
            <div className="container">
                <div ref={contentRef} className="terms-layout" style={{ display: "grid", gridTemplateColumns: "220px 1fr", gap: "var(--space-3xl)", alignItems: "start" }}>

                    {/* Sidebar TOC */}
                    <nav className="terms-sidebar" style={{
                        position: "sticky",
                        top: "calc(var(--header-height) + 24px)",
                        display: "flex",
                        flexDirection: "column",
                        gap: "2px",
                        borderRight: "1px solid var(--border-color)",
                        paddingRight: "var(--space-xl)",
                    }}>
                        <p style={{ fontSize: "0.68rem", fontWeight: 700, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--text-muted)", marginBottom: "var(--space-md)" }}>
                            Mục lục
                        </p>
                        {SECTIONS.map((s) => (
                            <button
                                key={s.id}
                                onClick={() => scrollToSection(s.id)}
                                style={{
                                    textAlign: "left",
                                    padding: "8px 12px",
                                    borderRadius: "var(--radius-md)",
                                    fontSize: "0.82rem",
                                    fontWeight: activeId === s.id ? 600 : 400,
                                    color: activeId === s.id ? "var(--color-accent)" : "var(--text-secondary)",
                                    background: activeId === s.id ? "rgba(139,92,246,0.08)" : "transparent",
                                    transition: "all 0.2s ease",
                                    cursor: "pointer",
                                    lineHeight: 1.4,
                                }}
                            >
                                {s.title}
                            </button>
                        ))}
                    </nav>

                    {/* Content */}
                    <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-3xl)" }}>

                        {SECTIONS.map((section, index) => (
                            <ContentBlock
                                key={section.id}
                                section={section}
                                index={index}
                                sectionRefs={sectionRefs}
                            />
                        ))}
                    </div>
                </div>
            </div>
        </section>
    );
}

function ContentBlock({
    section,
    index,
    sectionRefs,
}: {
    section: typeof SECTIONS[number];
    index: number;
    sectionRefs: React.MutableRefObject<Map<string, HTMLDivElement>>;
}) {
    const blockRef = useReveal("up", { delay: index * 0.05 });

    return (
        <div
            ref={(el) => {
                if (el) {
                    sectionRefs.current.set(section.id, el);
                    if (blockRef.current === null) {
                        (blockRef as React.MutableRefObject<HTMLDivElement | null>).current = el;
                    }
                }
            }}
            id={section.id}
            style={{ scrollMarginTop: "calc(var(--header-height) + 24px)" }}
        >
            <h2 style={{
                fontSize: "1.2rem",
                fontWeight: 700,
                letterSpacing: "-0.02em",
                color: "var(--text-primary)",
                marginBottom: "var(--space-lg)",
                paddingBottom: "var(--space-sm)",
                borderBottom: "1px solid var(--border-color)",
            }}>
                {section.title}
            </h2>
            <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-md)" }}>
                {section.paragraphs.map((p, i) => (
                    <p key={i} style={{
                        fontSize: "0.9rem",
                        lineHeight: 1.85,
                        color: "var(--text-secondary)",
                    }}>
                        {p}
                    </p>
                ))}
            </div>
        </div>
    );
}



/* ============================================================
   MAIN PAGE
   ============================================================ */

export default function TermsOfServicePage() {
    return (
        <>
            <HeroBanner />
            <DocumentSection />

            <style jsx global>{`
                @media (max-width: 768px) {
                    .terms-layout {
                        grid-template-columns: 1fr !important;
                        gap: var(--space-xl) !important;
                    }
                    .terms-sidebar {
                        position: relative !important;
                        top: 0 !important;
                        border-right: none !important;
                        border-bottom: 1px solid var(--border-color) !important;
                        padding-right: 0 !important;
                        padding-bottom: var(--space-lg) !important;
                        flex-direction: row !important;
                        flex-wrap: wrap !important;
                        gap: var(--space-xs) !important;
                    }
                    .terms-sidebar > p:first-child {
                        width: 100% !important;
                    }
                }
            `}</style>
        </>
    );
}
