import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  final bool isDarkMode;

  const AppFooter({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode
        ? AppTheme.darkTextSecondary
        : AppTheme.textLight;
    final hoverColor = isDarkMode
        ? AppTheme.darkTextPrimary
        : AppTheme.textDark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: AppConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? AppTheme.darkBorderColor : AppTheme.borderColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFooterLink('Chính sách bảo mật', textColor, hoverColor),
          SizedBox(width: AppConstants.paddingMedium),
          Text('•', style: TextStyle(color: textColor)),
          SizedBox(width: AppConstants.paddingMedium),
          _buildFooterLink('Điều khoản sử dụng', textColor, hoverColor),
          SizedBox(width: AppConstants.paddingMedium),
          Text('•', style: TextStyle(color: textColor)),
          SizedBox(width: AppConstants.paddingMedium),
          Text(
            '© 2024 StyleZone. All rights reserved.',
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, Color textColor, Color hoverColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Handle link navigation
        },
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
