import 'package:flutter_test/flutter_test.dart';
import 'package:webadmin/utils/validators.dart';

void main() {
  group('Validators', () {
    // ══════════════════════════════════════
    // requireNonEmpty
    // ══════════════════════════════════════
    group('requireNonEmpty', () {
      test('không throw khi chuỗi hợp lệ', () {
        expect(
          () => Validators.requireNonEmpty('Hello', 'Tên'),
          returnsNormally,
        );
      });

      test('throw khi null', () {
        expect(
          () => Validators.requireNonEmpty(null, 'Tên'),
          throwsA(isA<String>()),
        );
      });

      test('throw khi chuỗi rỗng', () {
        expect(
          () => Validators.requireNonEmpty('', 'Tên'),
          throwsA(isA<String>()),
        );
      });

      test('throw khi chỉ có khoảng trắng', () {
        expect(
          () => Validators.requireNonEmpty('   ', 'Tên'),
          throwsA(contains('Vui lòng nhập')),
        );
      });
    });

    // ══════════════════════════════════════
    // requirePositive
    // ══════════════════════════════════════
    group('requirePositive', () {
      test('không throw khi số dương', () {
        expect(() => Validators.requirePositive(10, 'Giá'), returnsNormally);
      });

      test('throw khi = 0', () {
        expect(
          () => Validators.requirePositive(0, 'Giá'),
          throwsA(contains('phải lớn hơn 0')),
        );
      });

      test('throw khi âm', () {
        expect(
          () => Validators.requirePositive(-5, 'Giá'),
          throwsA(isA<String>()),
        );
      });

      test('throw khi null', () {
        expect(
          () => Validators.requirePositive(null, 'Giá'),
          throwsA(isA<String>()),
        );
      });
    });

    // ══════════════════════════════════════
    // requireNonNegative
    // ══════════════════════════════════════
    group('requireNonNegative', () {
      test('không throw khi = 0', () {
        expect(
          () => Validators.requireNonNegative(0, 'Tồn kho'),
          returnsNormally,
        );
      });

      test('không throw khi dương', () {
        expect(
          () => Validators.requireNonNegative(100, 'Tồn kho'),
          returnsNormally,
        );
      });

      test('throw khi âm', () {
        expect(
          () => Validators.requireNonNegative(-1, 'Tồn kho'),
          throwsA(contains('không được âm')),
        );
      });
    });

    // ══════════════════════════════════════
    // requireEmail
    // ══════════════════════════════════════
    group('requireEmail', () {
      test('không throw khi email hợp lệ', () {
        expect(() => Validators.requireEmail('test@gmail.com'), returnsNormally);
      });

      test('không throw khi null (optional)', () {
        expect(() => Validators.requireEmail(null), returnsNormally);
      });

      test('không throw khi rỗng (optional)', () {
        expect(() => Validators.requireEmail(''), returnsNormally);
      });

      test('throw khi email thiếu @', () {
        expect(
          () => Validators.requireEmail('testgmail.com'),
          throwsA(contains('Email không hợp lệ')),
        );
      });

      test('throw khi email thiếu domain', () {
        expect(
          () => Validators.requireEmail('test@'),
          throwsA(isA<String>()),
        );
      });
    });

    // ══════════════════════════════════════
    // requirePhone
    // ══════════════════════════════════════
    group('requirePhone', () {
      test('không throw khi SĐT hợp lệ 10 số', () {
        expect(() => Validators.requirePhone('0912345678'), returnsNormally);
      });

      test('không throw khi SĐT hợp lệ 11 số', () {
        expect(() => Validators.requirePhone('01234567890'), returnsNormally);
      });

      test('không throw khi null (optional)', () {
        expect(() => Validators.requirePhone(null), returnsNormally);
      });

      test('throw khi SĐT không bắt đầu bằng 0', () {
        expect(
          () => Validators.requirePhone('1912345678'),
          throwsA(contains('Số điện thoại không hợp lệ')),
        );
      });

      test('throw khi SĐT quá ngắn', () {
        expect(
          () => Validators.requirePhone('091234'),
          throwsA(isA<String>()),
        );
      });
    });

    // ══════════════════════════════════════
    // requireNonEmptyList
    // ══════════════════════════════════════
    group('requireNonEmptyList', () {
      test('không throw khi list có phần tử', () {
        expect(
          () => Validators.requireNonEmptyList(['a'], 'Sản phẩm'),
          returnsNormally,
        );
      });

      test('throw khi list rỗng', () {
        expect(
          () => Validators.requireNonEmptyList([], 'Sản phẩm'),
          throwsA(contains('không được để trống')),
        );
      });

      test('throw khi null', () {
        expect(
          () => Validators.requireNonEmptyList(null, 'Sản phẩm'),
          throwsA(isA<String>()),
        );
      });
    });

    // ══════════════════════════════════════
    // requireValidId
    // ══════════════════════════════════════
    group('requireValidId', () {
      test('không throw khi ID hợp lệ', () {
        expect(
          () => Validators.requireValidId('abc123', 'Mã SP'),
          returnsNormally,
        );
      });

      test('throw khi ID rỗng', () {
        expect(
          () => Validators.requireValidId('', 'Mã SP'),
          throwsA(contains('không hợp lệ')),
        );
      });

      test('throw khi null', () {
        expect(
          () => Validators.requireValidId(null, 'Mã SP'),
          throwsA(isA<String>()),
        );
      });
    });
  });
}
