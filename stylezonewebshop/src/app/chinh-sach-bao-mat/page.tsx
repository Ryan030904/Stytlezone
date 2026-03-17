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
   DATA — Privacy Policy Sections
   ============================================================ */

const SECTIONS = [
    {
        id: "thu-thap",
        title: "1. Thông Tin Thu Thập",
        paragraphs: [
            "Khi bạn truy cập, đăng ký tài khoản, đặt hàng hoặc tương tác với bất kỳ dịch vụ nào của StyleZone, chúng tôi có thể thu thập các loại thông tin cá nhân sau đây: họ và tên đầy đủ, địa chỉ email, số điện thoại liên hệ, địa chỉ giao hàng và địa chỉ thanh toán, ngày tháng năm sinh, giới tính, cùng với thông tin tài khoản thanh toán (số thẻ ngân hàng, ví điện tử — được mã hóa và xử lý bởi bên thứ ba đáng tin cậy).",
            "Ngoài các thông tin bạn chủ động cung cấp, hệ thống của chúng tôi cũng tự động thu thập một số dữ liệu kỹ thuật bao gồm: địa chỉ IP, loại và phiên bản trình duyệt, hệ điều hành, thiết bị sử dụng (desktop, mobile, tablet), thời gian truy cập, thời lượng phiên, các trang và sản phẩm bạn đã xem, nguồn truy cập (referral URL), và hành vi tương tác trên website (nhấp chuột, cuộn trang, thêm giỏ hàng). Dữ liệu này được thu thập thông qua cookies, pixel tracking và các công nghệ tương tự nhằm mục đích phân tích và cải thiện trải nghiệm người dùng.",
            "Trong trường hợp bạn liên hệ với bộ phận chăm sóc khách hàng qua email, điện thoại hoặc mạng xã hội, nội dung trao đổi cũng sẽ được ghi nhận và lưu trữ để đảm bảo chất lượng dịch vụ và giải quyết khiếu nại nếu phát sinh.",
        ],
    },
    {
        id: "su-dung",
        title: "2. Mục Đích Sử Dụng Thông Tin",
        paragraphs: [
            "Thông tin cá nhân của bạn được StyleZone sử dụng cho các mục đích cụ thể sau: (a) Xử lý, xác nhận và giao đơn hàng — bao gồm xác minh thanh toán, liên hệ khi có vấn đề với đơn hàng và cập nhật trạng thái giao hàng; (b) Quản lý tài khoản người dùng — duy trì thông tin đăng nhập, lịch sử mua hàng, danh sách yêu thích và địa chỉ đã lưu; (c) Cung cấp dịch vụ chăm sóc khách hàng — xử lý yêu cầu đổi trả, giải đáp thắc mắc và hỗ trợ kỹ thuật.",
            "Ngoài ra, chúng tôi sử dụng dữ liệu phân tích để: cá nhân hóa trải nghiệm mua sắm, gợi ý sản phẩm phù hợp dựa trên lịch sử duyệt web và mua hàng, tối ưu hóa giao diện website và cải thiện hiệu suất hệ thống. Chúng tôi cũng có thể gửi thông báo về chương trình khuyến mãi, voucher ưu đãi, sản phẩm mới và các sự kiện đặc biệt — tuy nhiên, bạn hoàn toàn có quyền từ chối nhận các thông tin marketing này bất kỳ lúc nào bằng cách nhấn nút \"Hủy đăng ký\" trong email hoặc điều chỉnh trong cài đặt tài khoản.",
            "StyleZone cam kết không sử dụng thông tin cá nhân của bạn cho bất kỳ mục đích nào ngoài những mục đích đã nêu trên mà không có sự đồng ý rõ ràng từ phía bạn.",
        ],
    },
    {
        id: "bao-ve",
        title: "3. Bảo Vệ Thông Tin",
        paragraphs: [
            "StyleZone áp dụng các biện pháp bảo mật kỹ thuật và tổ chức ở mức cao nhất theo tiêu chuẩn ngành để bảo vệ thông tin cá nhân của bạn khỏi truy cập trái phép, mất mát, lạm dụng hoặc tiết lộ. Các biện pháp bao gồm: mã hóa SSL/TLS 256-bit cho toàn bộ dữ liệu truyền tải giữa trình duyệt và máy chủ, hệ thống tường lửa (firewall) nhiều lớp, cơ chế phát hiện và ngăn chặn xâm nhập (IDS/IPS), kiểm soát quyền truy cập dựa trên vai trò (RBAC), và sao lưu dữ liệu định kỳ tại các trung tâm dữ liệu an toàn.",
            "Chúng tôi cam kết tuyệt đối không bán, cho thuê, trao đổi hoặc chia sẻ thông tin cá nhân của bạn cho bất kỳ bên thứ ba nào vì mục đích thương mại. Thông tin chỉ được chia sẻ với các đối tác tin cậy trực tiếp tham gia vào quy trình cung cấp dịch vụ, bao gồm: đơn vị vận chuyển (GHN, GHTK, J&T Express, Viettel Post) để giao đơn hàng, cổng thanh toán (MoMo, VNPay, Stripe) để xử lý giao dịch, và nhà cung cấp dịch vụ email để gửi thông báo đơn hàng. Tất cả đối tác đều phải ký kết thỏa thuận bảo mật dữ liệu (DPA) và tuân thủ các tiêu chuẩn bảo mật tương đương.",
            "Nhân viên StyleZone chỉ được phép truy cập thông tin khách hàng khi cần thiết để thực hiện nhiệm vụ công việc và đều phải tuân thủ nghĩa vụ bảo mật nghiêm ngặt. Mọi vi phạm sẽ bị xử lý kỷ luật theo quy định nội bộ và pháp luật hiện hành.",
        ],
    },
    {
        id: "cookies",
        title: "4. Cookies và Công Nghệ Theo Dõi",
        paragraphs: [
            "Website StyleZone sử dụng cookies — các tệp văn bản nhỏ được lưu trữ trên thiết bị của bạn — để nâng cao trải nghiệm duyệt web. Chúng tôi sử dụng ba loại cookies chính: (a) Cookies cần thiết — đảm bảo các chức năng cơ bản như duy trì phiên đăng nhập, lưu giỏ hàng và ghi nhớ tùy chọn ngôn ngữ/theme; (b) Cookies phân tích — thu thập dữ liệu ẩn danh về cách người dùng tương tác với website thông qua Google Analytics, giúp chúng tôi hiểu trang nào được truy cập nhiều nhất, thời gian ở lại trung bình và tỷ lệ thoát; (c) Cookies tùy chọn — ghi nhớ các thiết lập cá nhân như sản phẩm đã xem gần đây, kích cỡ ưa thích và vị trí giao hàng.",
            "Bạn hoàn toàn có quyền quản lý cookies thông qua cài đặt trình duyệt: có thể chấp nhận tất cả, từ chối tất cả, hoặc chọn lọc từng loại cookies. Tuy nhiên, xin lưu ý rằng việc tắt cookies cần thiết có thể ảnh hưởng đến một số tính năng quan trọng như duy trì giỏ hàng giữa các phiên truy cập, trạng thái đăng nhập và quy trình thanh toán. StyleZone không sử dụng cookies cho mục đích quảng cáo từ bên thứ ba hoặc theo dõi hành vi trên các website khác.",
        ],
    },
    {
        id: "quyen",
        title: "5. Quyền Của Người Dùng",
        paragraphs: [
            "Theo quy định pháp luật về bảo vệ dữ liệu cá nhân, bạn có các quyền sau đối với thông tin cá nhân đã cung cấp cho StyleZone: (a) Quyền truy cập — yêu cầu xem toàn bộ dữ liệu cá nhân mà chúng tôi đang lưu trữ về bạn; (b) Quyền chỉnh sửa — yêu cầu cập nhật hoặc sửa đổi thông tin không chính xác hoặc đã lỗi thời; (c) Quyền xóa — yêu cầu xóa vĩnh viễn dữ liệu cá nhân khỏi hệ thống của chúng tôi (trừ trường hợp dữ liệu cần thiết để tuân thủ nghĩa vụ pháp lý hoặc giải quyết tranh chấp); (d) Quyền hạn chế xử lý — yêu cầu tạm ngừng sử dụng dữ liệu trong khi chờ xác minh hoặc xử lý khiếu nại.",
            "Bạn cũng có quyền yêu cầu xuất toàn bộ dữ liệu đã lưu trữ ở định dạng có thể đọc được (JSON hoặc CSV), cũng như quyền rút lại sự đồng ý đã cho phép xử lý dữ liệu bất kỳ lúc nào. Để thực hiện bất kỳ quyền nào kể trên, vui lòng gửi yêu cầu qua email stylezone13579@gmail.com hoặc thông qua trang Liên hệ, kèm theo thông tin xác minh danh tính. Chúng tôi cam kết phản hồi và xử lý trong vòng 48 giờ làm việc kể từ khi nhận được yêu cầu hợp lệ.",
        ],
    },
    {
        id: "luu-tru",
        title: "6. Thời Gian Lưu Trữ Dữ Liệu",
        paragraphs: [
            "Thông tin cá nhân của bạn sẽ được lưu trữ trong suốt thời gian tài khoản còn hoạt động hoặc trong thời gian cần thiết để cung cấp dịch vụ. Sau khi tài khoản bị xóa theo yêu cầu, chúng tôi sẽ tiến hành xóa hoặc ẩn danh hóa dữ liệu trong vòng 30 ngày, ngoại trừ các dữ liệu cần thiết để tuân thủ nghĩa vụ pháp lý (ví dụ: hóa đơn, chứng từ giao dịch theo quy định kế toán — lưu trữ tối thiểu 5 năm).",
            "Dữ liệu phân tích ẩn danh (không chứa thông tin nhận dạng cá nhân) có thể được lưu trữ vô thời hạn nhằm phục vụ mục đích nghiên cứu, thống kê và cải thiện dịch vụ. Chúng tôi thực hiện kiểm tra và dọn dẹp dữ liệu định kỳ mỗi quý để đảm bảo không lưu trữ thông tin không cần thiết.",
        ],
    },
    {
        id: "cap-nhat",
        title: "7. Cập Nhật Chính Sách",
        paragraphs: [
            "Chính sách bảo mật này có thể được cập nhật, bổ sung hoặc sửa đổi định kỳ để phản ánh các thay đổi trong hoạt động kinh doanh, công nghệ bảo mật hoặc quy định pháp luật liên quan. Phiên bản mới nhất sẽ luôn được đăng tải trên trang này với ngày cập nhật rõ ràng ở cuối trang.",
            "Trong trường hợp có thay đổi quan trọng ảnh hưởng đến quyền lợi của bạn, chúng tôi sẽ thông báo qua email hoặc thông qua banner trên website trước khi thay đổi có hiệu lực. Việc bạn tiếp tục sử dụng dịch vụ sau ngày thay đổi có hiệu lực đồng nghĩa với việc bạn chấp nhận chính sách mới. Chúng tôi khuyến khích bạn kiểm tra trang này định kỳ để nắm bắt các cập nhật mới nhất. Cập nhật lần cuối: Tháng 3, 2026.",
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
                    Chính Sách Bảo Mật
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

    /* Scroll spy — track which section is in view */
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
                <div ref={contentRef} className="privacy-layout" style={{ display: "grid", gridTemplateColumns: "220px 1fr", gap: "var(--space-3xl)", alignItems: "start" }}>

                    {/* Sidebar TOC — sticky */}
                    <nav className="privacy-sidebar" style={{
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
                    /* Also set the reveal ref */
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

export default function PrivacyPolicyPage() {
    return (
        <>
            <HeroBanner />
            <DocumentSection />

            <style jsx global>{`
                @media (max-width: 768px) {
                    .privacy-layout {
                        grid-template-columns: 1fr !important;
                        gap: var(--space-xl) !important;
                    }
                    .privacy-sidebar {
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
                    .privacy-sidebar > p:first-child {
                        width: 100% !important;
                    }
                }
            `}</style>
        </>
    );
}
