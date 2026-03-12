import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Service upload ảnh lên Cloudinary (unsigned preset).
class CloudinaryService {
  static const String _cloudName = 'dtwzcwhaa';
  static const String _uploadPreset = 'stylezone';
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload bytes ảnh, trả về URL public.
  static Future<String?> uploadImage(Uint8List imageBytes, {String? fileName}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
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
      return null;
    }
  }
}
