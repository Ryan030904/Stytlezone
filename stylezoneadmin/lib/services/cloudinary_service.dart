import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

/// Service upload ảnh lên Cloudinary (unsigned preset).
class CloudinaryService {

  /// Upload bytes ảnh, trả về URL public.
  static Future<String?> uploadImage(Uint8List imageBytes, {String? fileName}) async {
    try {
      // Validate file size
      if (imageBytes.length > AppConfig.maxUploadSizeBytes) {
        throw 'Ảnh vượt quá 5MB. Vui lòng chọn ảnh nhỏ hơn.';
      }

      // Validate file extension (nếu có fileName)
      if (fileName != null && fileName.contains('.')) {
        final ext = fileName.split('.').last.toLowerCase();
        if (!AppConfig.allowedImageExtensions.contains(ext)) {
          throw 'Định dạng ảnh không được hỗ trợ. Chấp nhận: ${AppConfig.allowedImageExtensions.join(', ')}';
        }
      }

      final request = http.MultipartRequest('POST', Uri.parse(AppConfig.cloudinaryUploadUrl));
      request.fields['upload_preset'] = AppConfig.cloudinaryUploadPreset;
      if (fileName != null) {
        request.fields['public_id'] = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      }

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);
        return json['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      if (e is String) rethrow;
      return null;
    }
  }
}
