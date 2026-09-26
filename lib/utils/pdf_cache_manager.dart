import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PDFCacheManager {
  static Future<String?> getCachedPDF(String bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$bookId.pdf');
    if (!await file.exists() || await file.length() <= 1024) return null;
    final header = await file.openRead(0, 4).first;
    return String.fromCharCodes(header) == '%PDF' ? file.path : null;
  }

  static Future<bool> isDownloaded(String bookId) async {
    return await getCachedPDF(bookId) != null;
  }
}
