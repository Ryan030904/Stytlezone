# Các trang chưa hoàn thiện — Mô tả thiết kế & chức năng

> **Trạng thái hiện tại:** 8 trang đang sử dụng **static mock data**, chưa có Firestore backend (model / service / provider).
> 
> **Các trang ĐÃ hoàn thiện:** Tổng quan, Sản phẩm, Danh mục, Tồn kho, Đơn hàng, Vận chuyển, Khuyến mãi.

---

## 1. 💳 Thanh toán / Đối soát (`payment_content.dart`)

### Mô tả
Trang quản lý tất cả giao dịch thanh toán từ các đơn hàng. Hỗ trợ đối soát tiền về tài khoản, xác nhận thanh toán thủ công (COD, Banking), và theo dõi trạng thái tiền.

### Backend cần tạo
- **Model:** `Payment` — id, orderId, orderCode, amount, method (COD / VietQR / Banking / Momo), status (Chờ xác nhận / Đã thanh toán / Hoàn tiền / Thất bại), transactionId, paidAt, createdAt
- **Service:** `PaymentService` — Firestore collection `payments`
- **Provider:** `PaymentProvider`

### Bố cục giao diện

#### Header
| Thành phần | Chức năng |
|---|---|
| Tiêu đề "Thanh toán / Đối soát" | — |
| Nút **"Xuất báo cáo"** | Xuất danh sách giao dịch ra CSV/Excel |

#### Hàng thống kê (4 cards)
| Card | Dữ liệu | Icon |
|---|---|---|
| Tổng giao dịch | Tổng số lượng giao dịch | `receipt_long` |
| Đã thanh toán | Số giao dịch thành công | `check_circle` |
| Chờ xác nhận | Số giao dịch chờ | `hourglass_empty` |
| Tổng doanh thu | Tổng tiền đã nhận | `attach_money` |

#### Thanh lọc
| Thành phần | Chức năng |
|---|---|
| Ô tìm kiếm | Tìm theo mã đơn, mã giao dịch |
| Dropdown phương thức | Lọc: Tất cả / COD / VietQR / Banking / Momo |
| Date range picker | Lọc theo khoảng thời gian |

#### Tabs trạng thái
`Tất cả` · `Chờ xác nhận` · `Đã thanh toán` · `Hoàn tiền` · `Thất bại`

#### Bảng dữ liệu
| Cột | Mô tả |
|---|---|
| Mã giao dịch | Hiển thị dạng badge tím, click → chi tiết |
| Mã đơn hàng | Link tới đơn hàng tương ứng |
| Khách hàng | Tên người thanh toán |
| Số tiền | Format VND (đ) |
| Phương thức | Badge: COD / VietQR / Banking / Momo |
| Trạng thái | Badge màu theo trạng thái |
| Ngày TT | Ngày thanh toán |
| Thao tác | Nút ✅ Xác nhận · 🔄 Hoàn tiền |

#### Các nút & chức năng
| Nút | Khi ấn |
|---|---|
| **Xác nhận thanh toán** | Dialog xác nhận → cập nhật status = "Đã thanh toán", ghi paidAt |
| **Hoàn tiền** | Dialog nhập lý do → cập nhật status = "Hoàn tiền", ghi note |
| **Xuất báo cáo** | Download file CSV với tất cả giao dịch đã lọc |
| **Row click** | Mở panel chi tiết: thông tin giao dịch + đơn hàng liên kết |

---

## 2. 👥 Khách hàng (`customer_content.dart`)

### Mô tả
Trang quản lý danh sách khách hàng, xem lịch sử mua hàng, phân khúc khách hàng (mới / thường xuyên / VIP).

### Backend cần tạo
- **Model:** `Customer` — id, name, phone, email, address, totalOrders, totalSpent, tier (Mới / Thường / VIP), note, createdAt, lastOrderAt
- **Service:** `CustomerService` — Firestore collection `customers`
- **Provider:** `CustomerProvider`

### Bố cục giao diện

#### Header
| Thành phần | Chức năng |
|---|---|
| Tiêu đề "Quản lý khách hàng" | — |
| Nút **"+ Thêm khách hàng"** | Mở dialog tạo khách hàng mới |

#### Hàng thống kê (4 cards)
| Card | Dữ liệu |
|---|---|
| Tổng khách hàng | Count tất cả |
| Khách mới (tháng này) | Count khách createdAt trong tháng |
| Khách VIP | Count tier = "VIP" |
| Doanh thu trung bình | Tổng spent / tổng khách |

#### Thanh lọc
| Thành phần | Chức năng |
|---|---|
| Ô tìm kiếm | Tìm theo tên, SĐT, email |
| Dropdown phân khúc | Tất cả / Mới / Thường / VIP |

#### Bảng dữ liệu
| Cột | Mô tả |
|---|---|
| Tên khách hàng | Click → mở chi tiết |
| SĐT | Số điện thoại |
| Email | — |
| Số đơn | Tổng đơn hàng |
| Tổng chi tiêu | Format VND |
| Phân khúc | Badge: Mới (xanh) / Thường (xám) / VIP (vàng) |
| Đơn gần nhất | Ngày mua gần nhất |
| Thao tác | ✏️ Sửa · 🗑️ Xóa |

#### Các nút & chức năng
| Nút | Khi ấn |
|---|---|
| **+ Thêm khách hàng** | Dialog: nhập tên, SĐT, email, địa chỉ, ghi chú → tạo doc trong Firestore |
| **✏️ Sửa** | Dialog edit thông tin khách → update Firestore |
| **🗑️ Xóa** | Dialog xác nhận → delete doc |
| **Row click** | Mở panel chi tiết: thông tin KH + lịch sử đơn hàng (query orders by customerPhone) + thống kê cá nhân |

#### Chi tiết khách hàng (Detail Panel)
- **Thông tin cá nhân**: tên, SĐT, email, địa chỉ
- **Thống kê**: tổng đơn, tổng chi tiêu, đơn gần nhất, phân khúc
- **Lịch sử đơn hàng**: bảng mini hiển thị các đơn của khách (mã đơn, ngày, tổng tiền, trạng thái)

---

## 3. 📰 CMS / Nội dung (`cms_content.dart`)

### Mô tả
Quản lý nội dung hiển thị trên website shop: banners trang chủ, bài viết blog/tin tức, và các trang tĩnh (about, chính sách, hướng dẫn).

### Backend cần tạo
- **Model:** `CmsItem` — id, type (banner / article / page), title, slug, content, imageUrl, position (thứ tự hiển thị), isPublished, createdAt, updatedAt
- **Service:** `CmsService` — Firestore collection `cms`
- **Provider:** `CmsProvider`

### Bố cục giao diện

#### Header
| Thành phần | Chức năng |
|---|---|
| Tiêu đề "CMS / Nội dung" | — |
| Nút **"+ Thêm mới"** | Mở dialog tạo CMS item (dạng khác nhau tùy tab) |

#### Tabs
`Banners` · `Bài viết` · `Trang tĩnh`

#### Tab "Banners"
| Cột | Mô tả |
|---|---|
| Hình ảnh | Thumbnail banner |
| Tiêu đề | Tên banner |
| Vị trí | Số thứ tự (1, 2, 3...) |
| Trạng thái | Badge: Đang hiển thị (xanh) / Ẩn (xám) |
| Thao tác | ✏️ Sửa · 🗑️ Xóa · ↕️ Đổi vị trí |

#### Tab "Bài viết"
| Cột | Mô tả |
|---|---|
| Tiêu đề | Tên bài viết |
| Slug | URL path |
| Ngày tạo | — |
| Trạng thái | Xuất bản / Bản nháp |
| Thao tác | ✏️ Sửa · 🗑️ Xóa · 👁️ Xem trước |

#### Tab "Trang tĩnh"
| Cột | Mô tả |
|---|---|
| Tên trang | Ví dụ: Về chúng tôi, Chính sách đổi trả |
| Slug | URL path |
| Cập nhật | Lần sửa gần nhất |
| Thao tác | ✏️ Sửa |

#### Các nút & chức năng
| Nút | Khi ấn |
|---|---|
| **+ Thêm mới** | Dialog: nhập tiêu đề, nội dung (textarea), hình ảnh (upload), slug (auto-generate từ tiêu đề), toggle xuất bản/ẩn |
| **✏️ Sửa** | Dialog edit nội dung hiện tại |
| **🗑️ Xóa** | Dialog xác nhận xóa |
| **↕️ Đổi vị trí** | Dropdown đổi position (chỉ cho banners) |
| **👁️ Xem trước** | Mở preview nội dung bài viết |

---

## 4. 📊 Báo cáo (`report_content.dart`)

### Mô tả
Trang hiển thị các báo cáo phân tích kinh doanh. Mỗi báo cáo là một thẻ card, click vào sẽ mở trang báo cáo chi tiết với biểu đồ và bảng dữ liệu.

### Backend cần tạo
- **Không cần model/service riêng** — dữ liệu được **aggregate từ orders, products, customers, shipments** đã có sẵn.
- **Provider:** `ReportProvider` — tính toán và cache dữ liệu báo cáo

### Bố cục giao diện

#### Header
| Thành phần | Chức năng |
|---|---|
| Tiêu đề "Báo cáo" | — |
| Dropdown khoảng thời gian | Hôm nay / 7 ngày / 30 ngày / Quý này / Năm nay |
| Nút **"Xuất all"** | Xuất tất cả báo cáo ra file |

#### 6 Cards báo cáo (Grid 3×2)

| Card | Icon | Khi ấn "Xem báo cáo" |
|---|---|---|
| **Doanh thu** | `trending_up` | Mở panel: biểu đồ doanh thu theo ngày/tuần/tháng + bảng chi tiết từng đơn |
| **Sản phẩm bán chạy** | `local_fire_department` | Mở panel: bảng xếp hạng sản phẩm theo số lượng bán + doanh thu |
| **Khách hàng** | `people` | Mở panel: phân tích khách mới/cũ, khách VIP, tần suất mua |
| **Kho hàng** | `inventory_2` | Mở panel: hàng tồn lâu, tốc độ bán, cảnh báo sắp hết |
| **Tài chính** | `account_balance` | Mở panel: tổng thu, tổng chi, lợi nhuận ròng |
| **Vận chuyển** | `local_shipping` | Mở panel: tỉ lệ giao thành công, thời gian giao trung bình, carrier performance |

#### Các nút & chức năng
| Nút | Khi ấn |
|---|---|
| **Xem báo cáo** (trên mỗi card) | Chuyển sang view detail của báo cáo đó, hiển thị biểu đồ + bảng |
| **Quay lại** (trong detail) | Quay về danh sách cards |
| **Xuất all** | Download tổng hợp CSV |

---

## 5. 📋 Phiếu kho (`warehouse_receipt_content.dart`)

### Mô tả
Quản lý phiếu nhập kho, xuất kho, chuyển kho, và kiểm kho. Mỗi phiếu ghi lại danh sách sản phẩm + số lượng thay đổi, cập nhật stock tự động.

### Backend cần tạo
- **Model:** `WarehouseReceipt` — id, code (PNK-xxx / PXK-xxx / PCK-xxx / PKK-xxx), type (nhap / xuat / chuyen / kiem), items: List<ReceiptItem> (productId, productName, quantity, note), supplier (nhà cung cấp - cho nhập), reason (lý do - cho xuất), status (Đang xử lý / Hoàn thành / Hủy), createdBy, createdAt
- **Service:** `WarehouseReceiptService` — Firestore collection `warehouse_receipts`. **Khi hoàn thành phiếu → tự động cập nhật stock của sản phẩm**
- **Provider:** `WarehouseReceiptProvider`

### Bố cục giao diện

#### Header
| Thành phần | Chức năng |
|---|---|
| Tiêu đề "Phiếu kho" | — |
| Nút **"+ Tạo phiếu"** | Mở dialog tạo phiếu mới (chọn loại) |

#### Tabs
`Nhập kho` · `Xuất kho` · `Chuyển kho` · `Kiểm kho`

#### Bảng dữ liệu
| Cột | Mô tả |
|---|---|
| Mã phiếu | Badge tím, click → chi tiết |
| Loại | Nhập / Xuất / Chuyển / Kiểm |
| Số SP | Số lượng sản phẩm trong phiếu |
| Tổng SL | Tổng số lượng tất cả items |
| NCC / Lý do | Nhà cung cấp (nhập) hoặc lý do (xuất) |
| Trạng thái | Badge: Đang xử lý / Hoàn thành / Hủy |
| Ngày tạo | — |
| Người tạo | Tên admin |
| Thao tác | ✅ Hoàn thành · ❌ Hủy · 🗑️ Xóa |

#### Các nút & chức năng
| Nút | Khi ấn |
|---|---|
| **+ Tạo phiếu** | Dialog: chọn loại phiếu → nhập NCC/lý do → thêm sản phẩm (search dropdown) + số lượng → tạo phiếu Firestore |
| **✅ Hoàn thành** | Dialog xác nhận → cập nhật status, **auto-sync stock** (nhập: +stock, xuất: -stock) |
| **❌ Hủy** | Dialog nhập lý do → cập nhật status = "Hủy" |
| **🗑️ Xóa** | Dialog xác nhận → xóa phiếu (chỉ khi status = "Đang xử lý") |
| **Row click** | Chi tiết phiếu: danh sách sản phẩm trong phiếu + số lượng + trạng thái |

#### Chi tiết phiếu (Detail Panel)
- **Thông tin phiếu**: mã, loại, NCC, lý do, người tạo, ngày tạo, trạng thái
- **Bảng sản phẩm**: tên SP, mã SP, số lượng nhập/xuất, ghi chú từng dòng
- **Timeline**: lịch sử trạng thái (tạo → xử lý → hoàn thành/hủy)

---

## 6. 🔄 Đổi trả / Hoàn tiền (`rma_content.dart`)

### Mô tả
Quản lý các yêu cầu đổi trả sản phẩm và hoàn tiền từ khách hàng. Mỗi yêu cầu liên kết với đơn hàng gốc.

### Backend cần tạo
- **Model:** `RmaRequest` — id, code (RMA-xxx), orderId, orderCode, customerName, customerPhone, reason (Lỗi sản phẩm / Sai size / Không đúng mô tả / Khác), type (Đổi hàng / Trả hàng / Hoàn tiền), items: List<RmaItem> (productName, quantity, note), status (Chờ duyệt / Đang xử lý / Hoàn thành / Từ chối), refundAmount, adminNote, createdAt, resolvedAt
- **Service:** `RmaService` — Firestore collection `rma_requests`
- **Provider:** `RmaProvider`

### Bố cục giao diện

#### Header
| Thành phần | Chức năng |
|---|---|
| Tiêu đề "Đổi trả / Hoàn tiền" | — |
| Nút **"+ Tạo yêu cầu"** | Mở dialog tạo RMA mới |

#### Hàng thống kê (4 cards)
| Card | Dữ liệu |
|---|---|
| Tổng yêu cầu | Count tất cả |
| Chờ duyệt | Count status = "Chờ duyệt" |
| Đang xử lý | Count status = "Đang xử lý" |
| Tỷ lệ hoàn thành | % Hoàn thành / (Hoàn thành + Từ chối) |

#### Tabs trạng thái
`Tất cả` · `Chờ duyệt` · `Đang xử lý` · `Hoàn thành` · `Từ chối`

#### Bảng dữ liệu
| Cột | Mô tả |
|---|---|
| Mã RMA | Badge tím, click → chi tiết |
| Mã đơn gốc | Link đến đơn hàng |
| Khách hàng | Tên + SĐT |
| Loại | Badge: Đổi hàng / Trả hàng / Hoàn tiền |
| Lý do | Tóm tắt |
| Trạng thái | Badge màu theo trạng thái |
| Ngày tạo | — |
| Thao tác | ✅ Duyệt · ❌ Từ chối · 🔄 Xử lý |

#### Các nút & chức năng
| Nút | Khi ấn |
|---|---|
| **+ Tạo yêu cầu** | Dialog: nhập mã đơn gốc, chọn loại (đổi/trả/hoàn tiền), chọn lý do, thêm sản phẩm đổi trả + SL, nhập ghi chú |
| **✅ Duyệt** | Cập nhật status → "Đang xử lý" |
| **❌ Từ chối** | Dialog nhập lý do từ chối → status = "Từ chối" |
| **🔄 Hoàn thành** | Dialog xác nhận + nhập số tiền hoàn (nếu hoàn tiền) → status = "Hoàn thành", ghi resolvedAt |
| **Row click** | Chi tiết: thông tin RMA + danh sách SP đổi trả + timeline trạng thái |

---

## 7. 📜 Nhật ký hệ thống (`audit_log_content.dart`)

### Mô tả
Trang read-only ghi lại tất cả hoạt động của admin trên hệ thống. Không có CRUD (chỉ xem + lọc). Các service khác sẽ tự động ghi log khi thực hiện thao tác.

### Backend cần tạo
- **Model:** `AuditLog` — id, action (CREATE / UPDATE / DELETE / STATUS_CHANGE / LOGIN / LOGOUT), entity (product / order / shipment / customer / ...), entityId, entityName, oldValue, newValue, performedBy, timestamp
- **Service:** `AuditLogService` — Firestore collection `audit_logs`. Cung cấp method `log(...)` để các service khác gọi khi thực hiện thao tác
- **Provider:** `AuditLogProvider`

### Bố cục giao diện

#### Header
| Thành phần | Chức năng |
|---|---|
| Tiêu đề "Nhật ký hệ thống" | — |
| Nút **"Xuất log"** | Xuất danh sách log ra file CSV |

#### Thanh lọc
| Thành phần | Chức năng |
|---|---|
| Ô tìm kiếm | Tìm theo tên entity, người thực hiện |
| Dropdown loại thao tác | Tất cả / Tạo / Sửa / Xóa / Đổi trạng thái / Đăng nhập |
| Dropdown đối tượng | Tất cả / Sản phẩm / Đơn hàng / Khách hàng / ... |
| Date range picker | Lọc theo khoảng thời gian |

#### Bảng dữ liệu (read-only, không có checkbox)
| Cột | Mô tả |
|---|---|
| Thời gian | Datetime chính xác |
| Hành động | Badge màu: Tạo (xanh lá) / Sửa (xanh dương) / Xóa (đỏ) / Đổi TT (cam) |
| Đối tượng | Loại entity + tên |
| Chi tiết | Tóm tắt thay đổi (old → new nếu có) |
| Người thực hiện | Tên/email admin |

#### Các nút & chức năng
| Nút | Khi ấn |
|---|---|
| **Xuất log** | Download CSV với tất cả log đã lọc |
| **Row click** | Mở panel chi tiết: hiển thị old/new value đầy đủ dạng diff |

---

## 8. ⚙️ Cài đặt (`settings_content.dart`)

### Mô tả
Trang cấu hình và tùy chỉnh hệ thống. Mỗi section là một card, click "Chỉnh sửa" sẽ mở form/dialog tương ứng.

### Backend cần tạo
- **Model:** `AppSettings` — singleton doc chứa tất cả cấu hình
- **Service:** `SettingsService` — Firestore doc `settings/app_config`
- **Provider:** `SettingsProvider`

### Bố cục giao diện — 6 Sections

#### 1. Thông tin cửa hàng 🏪
| Trường | Mô tả |
|---|---|
| Tên cửa hàng | Text input |
| Địa chỉ | Text input |
| SĐT | Text input |
| Email | Text input |
| Logo | Upload ảnh (Firebase Storage) |
| Mô tả | Textarea |

**Nút "Chỉnh sửa"** → Mở dialog form với các trường trên → Lưu vào Firestore

#### 2. Thanh toán 💳
| Trường | Mô tả |
|---|---|
| COD | Toggle bật/tắt |
| Momo | Toggle bật/tắt + nhập số tài khoản |
| VNPay | Toggle bật/tắt + nhập merchant key |
| ZaloPay | Toggle bật/tắt + nhập app ID |

**Nút "Chỉnh sửa"** → Dialog form toggle + input → Lưu Firestore

#### 3. Vận chuyển 🚚
| Trường | Mô tả |
|---|---|
| Đơn vị VC mặc định | Dropdown (GHN / GHTK / Viettel Post / J&T) |
| Phí ship mặc định | Số tiền (VND) |
| Miễn phí ship từ | Đơn trên X đồng miễn phí ship |

**Nút "Chỉnh sửa"** → Dialog form → Lưu Firestore

#### 4. Thông báo 🔔
| Trường | Mô tả |
|---|---|
| Email thông báo đơn mới | Toggle bật/tắt + nhập email nhận |
| SMS đơn mới | Toggle bật/tắt |
| Thông báo hết hàng | Toggle bật/tắt |

**Nút "Chỉnh sửa"** → Dialog form → Lưu Firestore

#### 5. Bảo mật 🔒
| Trường | Mô tả |
|---|---|
| Đổi mật khẩu | Nút → Dialog nhập mật khẩu cũ + mới + xác nhận |
| Xác thực 2 bước | Toggle bật/tắt (2FA) |
| Phiên đăng nhập | Hiển thị danh sách sessions + nút "Đăng xuất tất cả" |

#### 6. Giao diện 🎨
| Trường | Mô tả |
|---|---|
| Theme | Toggle Dark/Light (đã có ThemeProvider) |
| Ngôn ngữ | Dropdown (Tiếng Việt) |
| Múi giờ | Dropdown (GMT+7) |
| Định dạng tiền | Dropdown (VND / USD) |

**Nút "Chỉnh sửa"** → Dialog form → Lưu Firestore

---

## Tổng hợp backend cần tạo

| Trang | Model | Service | Provider | Collection |
|---|---|---|---|---|
| Thanh toán | `Payment` | `PaymentService` | `PaymentProvider` | `payments` |
| Khách hàng | `Customer` | `CustomerService` | `CustomerProvider` | `customers` |
| CMS | `CmsItem` | `CmsService` | `CmsProvider` | `cms` |
| Báo cáo | — (aggregate) | — | `ReportProvider` | — |
| Phiếu kho | `WarehouseReceipt` | `WarehouseReceiptService` | `WarehouseReceiptProvider` | `warehouse_receipts` |
| Đổi trả | `RmaRequest` | `RmaService` | `RmaProvider` | `rma_requests` |
| Nhật ký | `AuditLog` | `AuditLogService` | `AuditLogProvider` | `audit_logs` |
| Cài đặt | `AppSettings` | `SettingsService` | `SettingsProvider` | `settings` |

> **Ghi chú chung:**
> - Tất cả UI đều follow pattern hiện tại: stat cards → filter bar → tabs → table → dialog CRUD → detail panel.
> - Màu accent tím `#7C3AED` xuyên suốt.
> - Sử dụng `AppSnackBar` cho mọi thông báo.
> - Dark/Light mode thông qua `ThemeProvider`.
> - Pagination 10/25/50/100 cho mọi bảng dữ liệu.
