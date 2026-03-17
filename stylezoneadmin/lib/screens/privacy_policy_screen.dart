import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : AppTheme.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chính sách bảo mật',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppTheme.textDark,
          ),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.07)
                        : AppTheme.lightBgSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildSection(
                        '1. Giới thiệu',
                        'Chào mừng bạn đến với StyleZone Admin. Chúng tôi cam kết bảo vệ quyền riêng tư và dữ liệu cá nhân của bạn. '
                            'Chính sách bảo mật này giải thích cách chúng tôi thu thập, sử dụng, chia sẻ và bảo vệ thông tin cá nhân '
                            'khi bạn sử dụng nền tảng quản trị StyleZone.',
                      ),
                      _buildSection(
                        '2. Thông tin chúng tôi thu thập',
                        '• Thông tin tài khoản: Tên, email, mật khẩu (được mã hóa)\n'
                            '• Thông tin thiết bị: Loại thiết bị, hệ điều hành, trình duyệt\n'
                            '• Dữ liệu sử dụng: Lịch sử truy cập, thao tác quản trị, thời gian sử dụng\n'
                            '• Thông tin đăng nhập: Địa chỉ IP, vị trí đăng nhập, thời gian đăng nhập',
                      ),
                      _buildSection(
                        '3. Mục đích sử dụng dữ liệu',
                        '• Xác thực và bảo mật tài khoản quản trị viên\n'
                            '• Cung cấp và cải thiện dịch vụ quản trị\n'
                            '• Phát hiện và ngăn chặn gian lận, hoạt động bất thường\n'
                            '• Gửi thông báo hệ thống và cập nhật quan trọng\n'
                            '• Phân tích và tối ưu hóa hiệu suất hệ thống',
                      ),
                      _buildSection(
                        '4. Bảo mật dữ liệu',
                        'Chúng tôi áp dụng các biện pháp bảo mật tiêu chuẩn ngành:\n\n'
                            '• Mã hóa SSL/TLS cho tất cả dữ liệu truyền tải\n'
                            '• Mật khẩu được mã hóa bằng thuật toán bcrypt\n'
                            '• Xác thực hai yếu tố (2FA) cho tài khoản quản trị\n'
                            '• Giám sát bảo mật 24/7\n'
                            '• Sao lưu dữ liệu định kỳ trên Firebase Cloud',
                      ),
                      _buildSection(
                        '5. Chia sẻ dữ liệu',
                        'Chúng tôi không bán hoặc cho thuê thông tin cá nhân của bạn cho bất kỳ bên thứ ba nào. '
                            'Dữ liệu chỉ được chia sẻ trong các trường hợp sau:\n\n'
                            '• Với sự đồng ý rõ ràng của bạn\n'
                            '• Để tuân thủ nghĩa vụ pháp lý\n'
                            '• Với các nhà cung cấp dịch vụ đáng tin cậy (Firebase, Google Cloud)',
                      ),
                      _buildSection(
                        '6. Quyền của bạn',
                        '• Quyền truy cập: Xem thông tin cá nhân đã thu thập\n'
                            '• Quyền chỉnh sửa: Cập nhật hoặc sửa đổi thông tin\n'
                            '• Quyền xóa: Yêu cầu xóa tài khoản và dữ liệu\n'
                            '• Quyền phản đối: Từ chối xử lý dữ liệu cho một số mục đích\n'
                            '• Quyền di chuyển: Xuất dữ liệu cá nhân theo định dạng chuẩn',
                      ),
                      _buildSection(
                        '7. Cookie và Công nghệ theo dõi',
                        'Chúng tôi sử dụng cookie và công nghệ tương tự để:\n\n'
                            '• Duy trì phiên đăng nhập của bạn\n'
                            '• Ghi nhớ tùy chọn giao diện (chế độ sáng/tối)\n'
                            '• Phân tích lưu lượng truy cập và hiệu suất\n\n'
                            'Bạn có thể quản lý cookie thông qua cài đặt trình duyệt.',
                      ),
                      _buildSection(
                        '8. Liên hệ',
                        'Nếu bạn có bất kỳ câu hỏi nào về chính sách bảo mật này, vui lòng liên hệ:\n\n'
                            '📧 Email: privacy@stylezone.com\n'
                            '📞 Điện thoại: (028) 1234-5678\n'
                            '📍 Địa chỉ: TP. Hồ Chí Minh, Việt Nam',
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withValues(alpha: 0.1)),
                      const SizedBox(height: 12),
                      Text(
                        'Cập nhật lần cuối: Tháng 2, 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.shield_rounded, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chính sách bảo mật',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'StyleZone Admin Dashboard',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFA78BFA),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
