import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const AppHeader({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? AppTheme.darkCardBg : AppTheme.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
    final borderColor = isDarkMode
        ? AppTheme.darkBorderColor
        : AppTheme.borderColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: AppConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                  ),
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
                child: Center(child: Text('✨', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Text(
                'StyleZone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          // Theme Toggle Button
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkBg : AppTheme.lightBg,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                _buildThemeButton(
                  icon: Icons.light_mode,
                  isActive: !isDarkMode,
                  onTap: isDarkMode ? onThemeToggle : null,
                ),
                _buildThemeButton(
                  icon: Icons.dark_mode,
                  isActive: isDarkMode,
                  onTap: !isDarkMode ? onThemeToggle : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingSmall,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          ),
          child: Icon(
            icon,
            color: isActive ? AppTheme.white : AppTheme.textLight,
            size: 20,
          ),
        ),
      ),
    );
  }
}
