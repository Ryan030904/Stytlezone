/// Cấu hình ứng dụng — tập trung các giá trị có thể thay đổi theo môi trường.
/// Trong tương lai có thể đọc từ environment variables hoặc remote config.
class AppConfig {
  AppConfig._();

  // ── Cloudinary ──────────────────────────────────
  static const String cloudinaryCloudName = 'dtwzcwhaa';
  static const String cloudinaryUploadPreset = 'stylezone';
  static String get cloudinaryUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  // ── Upload limits ───────────────────────────────
  static const int maxUploadSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp',
  ];
}
