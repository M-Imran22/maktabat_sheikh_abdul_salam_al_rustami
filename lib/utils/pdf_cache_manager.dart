import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PDFCacheManager {
  static Future<String?> getCachedPDF(String bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$bookId.pdf');
    return file.existsSync() ? file.path : null;
  }

  static Future<void> markAsDownloaded(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloaded_$bookId', true);
  }

  static Future<bool> isDownloaded(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('downloaded_$bookId') ?? false;
  }
}