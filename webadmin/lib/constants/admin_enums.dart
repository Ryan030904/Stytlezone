enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  partialRefunded,
  reconciled,
}

enum PaymentMethod {
  cod,
  vietQr,
  bankTransfer,
  momo,
  vnpay,
  zaloPay,
}

enum ReceiptType {
  stockIn,
  stockOut,
  transfer,
  stockCheck,
}

enum ReceiptStatus {
  draft,
  processing,
  completed,
  cancelled,
}

enum RmaStatus {
  pendingReview,
  approved,
  rejected,
  processing,
  completed,
}

enum RmaType {
  exchange,
  returnAndRefund,
}

enum RmaReason {
  wrongSize,
  wrongColor,
  wrongItem,
  defective,
  changedMind,
  other,
}

enum AuditAction {
  create,
  update,
  delete,
  softDelete,
  restore,
  statusChange,
  login,
  logout,
  reconcile,
  refund,
  exportCsv,
}

enum AuditEntity {
  category,
  product,
  order,
  shipment,
  promotion,
  payment,
  customer,
  cms,
  report,
  warehouseReceipt,
  rma,
  setting,
  auth,
}

class EnumMapper {
  const EnumMapper._();

  static String paymentStatus(PaymentStatus value) => value.name;
  static PaymentStatus parsePaymentStatus(String? value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  static String paymentMethod(PaymentMethod value) => value.name;
  static PaymentMethod parsePaymentMethod(String? value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cod,
    );
  }

  static String receiptType(ReceiptType value) => value.name;
  static ReceiptType parseReceiptType(String? value) {
    return ReceiptType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReceiptType.stockIn,
    );
  }

  static String receiptStatus(ReceiptStatus value) => value.name;
  static ReceiptStatus parseReceiptStatus(String? value) {
    return ReceiptStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReceiptStatus.draft,
    );
  }

  static String rmaStatus(RmaStatus value) => value.name;
  static RmaStatus parseRmaStatus(String? value) {
    return RmaStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RmaStatus.pendingReview,
    );
  }

  static String rmaType(RmaType value) => value.name;
  static RmaType parseRmaType(String? value) {
    return RmaType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RmaType.returnAndRefund,
    );
  }

  static String rmaReason(RmaReason value) => value.name;
  static RmaReason parseRmaReason(String? value) {
    return RmaReason.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RmaReason.other,
    );
  }

  static String auditAction(AuditAction value) => value.name;
  static AuditAction parseAuditAction(String? value) {
    return AuditAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AuditAction.update,
    );
  }

  static String auditEntity(AuditEntity value) => value.name;
  static AuditEntity parseAuditEntity(String? value) {
    return AuditEntity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AuditEntity.auth,
    );
  }
}

extension PaymentStatusLabel on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Chờ xác nhận';
      case PaymentStatus.paid:
        return 'Đã thanh toán';
      case PaymentStatus.failed:
        return 'Thất bại';
      case PaymentStatus.refunded:
        return 'Đã hoàn tiền';
      case PaymentStatus.partialRefunded:
        return 'Hoàn tiền một phần';
      case PaymentStatus.reconciled:
        return 'Đã đối soát';
    }
  }
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cod:
        return 'COD';
      case PaymentMethod.vietQr:
        return 'VietQR';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.zaloPay:
        return 'ZaloPay';
    }
  }
}

extension AuditActionLabel on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.create:
        return 'Tạo mới';
      case AuditAction.update:
        return 'Cập nhật';
      case AuditAction.delete:
        return 'Xóa';
      case AuditAction.softDelete:
        return 'Xóa mềm';
      case AuditAction.restore:
        return 'Khôi phục';
      case AuditAction.statusChange:
        return 'Đổi trạng thái';
      case AuditAction.login:
        return 'Đăng nhập';
      case AuditAction.logout:
        return 'Đăng xuất';
      case AuditAction.reconcile:
        return 'Đối soát';
      case AuditAction.refund:
        return 'Hoàn tiền';
      case AuditAction.exportCsv:
        return 'Xuất CSV';
    }
  }
}
