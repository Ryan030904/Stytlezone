import 'dart:typed_data';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

/// Widget chọn & upload ảnh lên Cloudinary.
/// Hiển thị preview ảnh hiện tại, nút chọn file, trạng thái upload.
class CloudinaryImagePicker extends StatefulWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final String label;

  const CloudinaryImagePicker({
    super.key,
    required this.controller,
    required this.isDarkMode,
    this.label = 'Hình ảnh sản phẩm',
  });

  @override
  State<CloudinaryImagePicker> createState() => _CloudinaryImagePickerState();
}

class _CloudinaryImagePickerState extends State<CloudinaryImagePicker> {
  bool _isUploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    final upload = html.FileUploadInputElement()..accept = 'image/*';
    upload.click();

    upload.onChange.listen((event) async {
      final files = upload.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];

      // Validate size (max 10MB)
      if (file.size > 10 * 1024 * 1024) {
        setState(() => _error = 'Ảnh quá lớn (tối đa 10MB)');
        return;
      }

      setState(() { _isUploading = true; _error = null; });

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) async {
        final bytes = reader.result as Uint8List;
        final url = await CloudinaryService.uploadImage(bytes, fileName: file.name);
        if (!mounted) return;
        if (url != null) {
          widget.controller.text = url;
          setState(() => _isUploading = false);
        } else {
          setState(() { _isUploading = false; _error = 'Upload thất bại, thử lại'; });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final hasImage = widget.controller.text.isNotEmpty;
    final bg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tp)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: bdr)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          // Preview area
          if (hasImage)
            Stack(children: [
              Container(
                width: double.infinity, height: 160,
                decoration: BoxDecoration(color: isDark ? Colors.black26 : const Color(0xFFF3F4F6)),
                child: Image.network(widget.controller.text, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.broken_image_rounded, size: 32, color: ts),
                    const SizedBox(height: 4),
                    Text('Không tải được ảnh', style: TextStyle(fontSize: 11, color: ts)),
                  ]))),
              ),
              // Remove button
              Positioned(top: 8, right: 8, child: InkWell(
                onTap: () => setState(() => widget.controller.clear()),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(7)),
                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white)),
              )),
            ])
          else if (_isUploading)
            Container(
              width: double.infinity, height: 120,
              color: isDark ? Colors.black12 : const Color(0xFFF9FAFB),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF7C3AED))),
                const SizedBox(height: 10),
                Text('Đang upload...', style: TextStyle(fontSize: 12, color: ts)),
              ]),
            )
          else
            InkWell(
              onTap: _pickAndUpload,
              child: Container(
                width: double.infinity, height: 120,
                color: Colors.transparent,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.cloud_upload_rounded, size: 22, color: Color(0xFF7C3AED))),
                  const SizedBox(height: 8),
                  Text('Nhấn để chọn ảnh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED))),
                  const SizedBox(height: 2),
                  Text('PNG, JPG, WEBP (tối đa 10MB)', style: TextStyle(fontSize: 10, color: ts)),
                ]),
              ),
            ),
          // Action bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: bdr))),
            child: Row(children: [
              if (hasImage) ...[
                Icon(Icons.check_circle_rounded, size: 14, color: const Color(0xFF10B981)),
                const SizedBox(width: 6),
                Expanded(child: Text('Đã upload', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF10B981)))),
              ] else
                Expanded(child: Text('Chưa có ảnh', style: TextStyle(fontSize: 11, color: ts))),
              if (!_isUploading)
                SizedBox(height: 28, child: TextButton.icon(
                  onPressed: _pickAndUpload,
                  icon: Icon(hasImage ? Icons.refresh_rounded : Icons.add_photo_alternate_rounded, size: 14),
                  label: Text(hasImage ? 'Đổi ảnh' : 'Chọn ảnh', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(horizontal: 8)),
                )),
            ]),
          ),
          // Error
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              child: Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
            ),
        ]),
      ),
    ]);
  }
}
