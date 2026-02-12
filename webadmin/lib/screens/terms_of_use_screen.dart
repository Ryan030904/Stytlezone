import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

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
          'Điều khoản sử dụng',
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
                        '1. Chấp nhận điều khoản',
                        'Bằng việc truy cập và sử dụng StyleZone Admin Dashboard, bạn đồng ý tuân thủ và chịu ràng buộc '
                            'bởi các điều khoản và điều kiện sau đây. Nếu bạn không đồng ý với bất kỳ phần nào của điều khoản này, '
                            'bạn không nên sử dụng dịch vụ.',
                      ),
                      _buildSection(
                        '2. Tài khoản quản trị viên',
                        '• Bạn phải được cấp quyền truy cập bởi quản trị viên cấp cao\n'
                            '• Mỗi tài khoản chỉ dành cho một cá nhân sử dụng\n'
                            '• Bạn có trách nhiệm bảo mật thông tin đăng nhập\n'
                            '• Không được chia sẻ tài khoản với người khác\n'
                            '• Phải thông báo ngay khi phát hiện truy cập trái phép',
                      ),
                      _buildSection(
                        '3. Quyền và nghĩa vụ',
                        'Khi sử dụng hệ thống, bạn có quyền:\n\n'
                            '• Truy cập các chức năng quản trị được phân quyền\n'
                            '• Quản lý sản phẩm, đơn hàng, khách hàng theo vai trò\n'
                            '• Xem và xuất báo cáo trong phạm vi quyền hạn\n\n'
                            'Bạn có nghĩa vụ:\n\n'
                            '• Sử dụng hệ thống đúng mục đích công việc\n'
                            '• Bảo mật thông tin khách hàng và dữ liệu kinh doanh\n'
                            '• Tuân thủ quy trình và hướng dẫn vận hành',
                      ),
                      _buildSection(
                        '4. Hành vi bị cấm',
                        '• Truy cập hoặc sửa đổi dữ liệu ngoài phạm vi quyền hạn\n'
                            '• Cố gắng vượt qua các biện pháp bảo mật hệ thống\n'
                            '• Sao chép, phân phối hoặc tiết lộ thông tin mật\n'
                            '• Sử dụng hệ thống cho mục đích cá nhân hoặc bất hợp pháp\n'
                            '• Cài đặt phần mềm độc hại hoặc can thiệp vào hệ thống\n'
                            '• Chia sẻ thông tin đăng nhập hoặc quyền truy cập',
                      ),
                      _buildSection(
                        '5. Quyền sở hữu trí tuệ',
                        'Tất cả nội dung, thiết kế, mã nguồn, thương hiệu và tài sản trí tuệ liên quan đến '
                            'StyleZone Admin Dashboard thuộc quyền sở hữu của StyleZone. Bạn không được:\n\n'
                            '• Sao chép hoặc tái tạo giao diện hệ thống\n'
                            '• Sử dụng thương hiệu StyleZone cho mục đích riêng\n'
                            '• Reverse-engineer hoặc decompile mã nguồn',
                      ),
                      _buildSection(
                        '6. Giới hạn trách nhiệm',
                        'StyleZone nỗ lực cung cấp dịch vụ ổn định và đáng tin cậy. Tuy nhiên, chúng tôi không đảm bảo:\n\n'
                            '• Dịch vụ hoạt động liên tục không gián đoạn\n'
                            '• Dữ liệu luôn chính xác 100% trong mọi trường hợp\n'
                            '• Khả năng phục hồi dữ liệu trong trường hợp bất khả kháng\n\n'
                            'StyleZone không chịu trách nhiệm cho các thiệt hại phát sinh từ việc sử dụng sai '
                            'hoặc truy cập trái phép vào hệ thống.',
                      ),
                      _buildSection(
                        '7. Đình chỉ và chấm dứt',
                        'Chúng tôi có quyền đình chỉ hoặc chấm dứt quyền truy cập của bạn nếu:\n\n'
                            '• Vi phạm các điều khoản sử dụng\n'
                            '• Phát hiện hoạt động đáng ngờ hoặc bất thường\n'
                            '• Theo yêu cầu của cơ quan có thẩm quyền\n'
                            '• Khi kết thúc hợp đồng lao động hoặc hợp tác',
                      ),
                      _buildSection(
                        '8. Thay đổi điều khoản',
                        'StyleZone có quyền cập nhật và thay đổi các điều khoản này bất kỳ lúc nào. '
                            'Các thay đổi sẽ được thông báo qua:\n\n'
                            '• Thông báo trên hệ thống dashboard\n'
                            '• Email đến tất cả quản trị viên\n\n'
                            'Việc tiếp tục sử dụng dịch vụ sau khi thay đổi đồng nghĩa với việc bạn chấp nhận '
                            'các điều khoản mới.',
                      ),
                      _buildSection(
                        '9. Liên hệ',
                        'Mọi thắc mắc về điều khoản sử dụng, vui lòng liên hệ:\n\n'
                            '📧 Email: legal@stylezone.com\n'
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
            child: Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điều khoản sử dụng',
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
