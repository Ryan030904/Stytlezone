import 'csv_downloader.dart';

class CsvExport {
  const CsvExport._();

  static String buildCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeCsv).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsv).join(','));
    }
    return buffer.toString();
  }

  static void download({
    required String filename,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final csv = buildCsv(headers: headers, rows: rows);
    downloadCsvFile(filename: filename, content: csv);
  }

  static String _escapeCsv(dynamic value) {
    final raw = (value ?? '').toString();
    final escaped = raw.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }
}
