import 'csv_downloader_stub.dart'
    if (dart.library.html) 'csv_downloader_web.dart' as impl;

void downloadCsvFile({
  required String filename,
  required String content,
}) {
  impl.downloadCsvFile(filename: filename, content: content);
}
