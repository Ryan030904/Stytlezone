/// Lớp validation đầu vào cho service layer.
/// Throw [String] nếu dữ liệu không hợp lệ.
class Validators {
  Validators._();

  /// Kiểm tra giá trị không rỗng.
  static void requireNonEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      throw 'Vui lòng nhập $fieldName.';
    }
  }

  /// Kiểm tra số dương (> 0).
  static void requirePositive(num? value, String fieldName) {
    if (value == null || value <= 0) {
      throw '$fieldName phải lớn hơn 0.';
    }
  }

  /// Kiểm tra số không âm (≥ 0).
  static void requireNonNegative(num? value, String fieldName) {
    if (value == null || value < 0) {
      throw '$fieldName không được âm.';
    }
  }

  /// Kiểm tra email hợp lệ (đơn giản).
  static void requireEmail(String? value) {
    if (value == null || value.trim().isEmpty) return; // email optional
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) {
      throw 'Email không hợp lệ.';
    }
  }

  /// Kiểm tra SĐT VN (10-11 số, bắt đầu 0).
  static void requirePhone(String? value) {
    if (value == null || value.trim().isEmpty) return; // phone optional
    final regex = RegExp(r'^0\d{9,10}$');
    if (!regex.hasMatch(value.trim().replaceAll(' ', ''))) {
      throw 'Số điện thoại không hợp lệ (10-11 số, bắt đầu bằng 0).';
    }
  }

  /// Kiểm tra danh sách không rỗng.
  static void requireNonEmptyList(List? value, String fieldName) {
    if (value == null || value.isEmpty) {
      throw '$fieldName không được để trống.';
    }
  }

  /// Kiểm tra ID document hợp lệ.
  static void requireValidId(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      throw '$fieldName không hợp lệ.';
    }
  }
}
