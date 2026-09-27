import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../utils/audio_cache_manager.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Map<String, StreamController<double>> _progressControllers = {};
  final Map<String, StreamController<bool>> _statusControllers = {};
  final Map<String, StreamController<String>> _errorControllers = {};
  final Map<String, bool> _activeDownloads = {};
  final Map<String, double> _activeProgress = {};

  Stream<double> getProgressStream(String id) {
    _progressControllers[id] ??= StreamController<double>.broadcast();
    return _progressControllers[id]!.stream;
  }

  Stream<bool> getStatusStream(String id) {
    _statusControllers[id] ??= StreamController<bool>.broadcast();
    return _statusControllers[id]!.stream;
  }

  Stream<String> getErrorStream(String id) {
    _errorControllers[id] ??= StreamController<String>.broadcast();
    return _errorControllers[id]!.stream;
  }

  bool isDownloading(String id) {
    return _activeDownloads[id] ?? false;
  }

  double getProgress(String id) {
    return _activeProgress[id] ?? 0.0;
  }

  Future<void> downloadBook(
    String bookId,
    String? url, {
    http.Client Function()? clientFactory,
  }) async {
    if (_activeDownloads[bookId] == true) return;
    if (url == null || url.trim().isEmpty || !url.startsWith('http')) {
      _errorControllers[bookId]?.add('سرور کا پتہ درست نہیں ہے');
      return;
    }

    _activeDownloads[bookId] = true;
    _activeProgress[bookId] = 0.0;
    _statusControllers[bookId]?.add(true);

    http.Client? client;
    IOSink? sink;
    File? tempFile;

    try {
      client = clientFactory?.call() ?? http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.followRedirects = true;

      final response = await client.send(request);

      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          throw const HttpException('یہ کتاب سرور پر دستیاب نہیں ہے۔');
        }
        throw Exception(
          'سرور سے ڈاؤن لوڈ ناکام ہوا (کوڈ: ${response.statusCode})',
        );
      }

      final contentLength = response.contentLength ?? 0;
      final dir = await getApplicationDocumentsDirectory();
      final targetFile = File('${dir.path}/$bookId.pdf');
      tempFile = File('${targetFile.path}.part');
      sink = tempFile.openWrite();

      int downloadedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          final progress = (downloadedBytes / contentLength).clamp(0.0, 1.0);
          _activeProgress[bookId] = progress;
          _progressControllers[bookId]?.add(progress);
        }
      }

      await _finishDownload(
        bookId,
        tempFile,
        targetFile,
        sink,
        contentLength,
        downloadedBytes,
      );
    } catch (e) {
      await _handleDownloadError(
        bookId,
        tempFile,
        sink,
        e is HttpException ? e.message : e.toString(),
      );
    } finally {
      client?.close();
    }
  }

  Future<void> _finishDownload(
    String bookId,
    File tempFile,
    File targetFile,
    IOSink sink,
    int expectedBytes,
    int downloadedBytes,
  ) async {
    try {
      await sink.flush();
      await sink.close();

      final length = await tempFile.length();
      if (length <= 1024 ||
          length != downloadedBytes ||
          (expectedBytes > 0 && length != expectedBytes)) {
        throw const FormatException('فائل ڈاؤن لوڈ مکمل نہیں ہوئی');
      }
      final bytes = await tempFile.openRead(0, 4).first;
      if (String.fromCharCodes(bytes) != '%PDF') {
        throw const FormatException('ڈاؤن لوڈ شدہ فائل درست پی ڈی ایف نہیں ہے');
      }
      if (await targetFile.exists()) await targetFile.delete();
      await tempFile.rename(targetFile.path);
      _activeProgress[bookId] = 1.0;
      _progressControllers[bookId]?.add(1.0);
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      _errorControllers[bookId]?.add('فائل محفوظ کرنے میں خرابی: $e');
    } finally {
      _activeDownloads[bookId] = false;
      _activeProgress.remove(bookId);
      _statusControllers[bookId]?.add(false);
    }
  }

  Future<void> _handleDownloadError(
    String id,
    File? file,
    IOSink? sink,
    String errorMessage,
  ) async {
    try {
      if (sink != null) {
        await sink.close();
      }
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    _activeDownloads[id] = false;
    _activeProgress.remove(id);
    _statusControllers[id]?.add(false);
    _errorControllers[id]?.add(errorMessage);
  }

  /// Downloads an audio file by its relative path and stores it in AudioCacheManager.
  Future<void> downloadAudio(
    String relativePath,
    String? url, {
    http.Client Function()? clientFactory,
  }) async {
    final audioId = relativePath;
    if (_activeDownloads[audioId] == true) return;
    if (url == null || url.trim().isEmpty || !url.startsWith('http')) {
      _errorControllers[audioId]?.add('سرور کا پتہ درست نہیں ہے');
      return;
    }

    _activeDownloads[audioId] = true;
    _activeProgress[audioId] = 0.0;
    _statusControllers[audioId]?.add(true);

    http.Client? client;
    IOSink? sink;
    File? tempFile;

    try {
      client = clientFactory?.call() ?? http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.followRedirects = true;

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'سرور سے ڈاؤن لوڈ ناکام ہوا (کوڈ: ${response.statusCode})',
        );
      }

      final contentLength = response.contentLength ?? 0;
      final targetFile = await AudioCacheManager.getLocalFile(relativePath);
      tempFile = File('${targetFile.path}.part');
      sink = tempFile.openWrite();

      int downloadedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          final progress = (downloadedBytes / contentLength).clamp(0.0, 1.0);
          _activeProgress[audioId] = progress;
          _progressControllers[audioId]?.add(progress);
        }
      }

      await _finishAudioDownload(
        audioId,
        tempFile,
        targetFile,
        sink,
        contentLength,
        downloadedBytes,
      );
    } catch (e) {
      await _handleDownloadError(audioId, tempFile, sink, e.toString());
    } finally {
      client?.close();
    }
  }

  Future<void> _finishAudioDownload(
    String audioId,
    File tempFile,
    File targetFile,
    IOSink sink,
    int expectedBytes,
    int downloadedBytes,
  ) async {
    try {
      await sink.flush();
      await sink.close();

      final length = await tempFile.length();
      if (length <= 1024 ||
          length != downloadedBytes ||
          (expectedBytes > 0 && length != expectedBytes)) {
        throw const FormatException('فائل ڈاؤن لوڈ نامکمل رہ گئی');
      }
      if (await targetFile.exists()) await targetFile.delete();
      await tempFile.rename(targetFile.path);
      _activeProgress[audioId] = 1.0;
      _progressControllers[audioId]?.add(1.0);
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      _errorControllers[audioId]?.add('آڈیو محفوظ کرنے میں خرابی: $e');
    } finally {
      _activeDownloads[audioId] = false;
      _activeProgress.remove(audioId);
      _statusControllers[audioId]?.add(false);
    }
  }

  void dispose() {
    for (var controller in _progressControllers.values) {
      controller.close();
    }
    for (var controller in _statusControllers.values) {
      controller.close();
    }
    for (var controller in _errorControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    _statusControllers.clear();
    _errorControllers.clear();
    _activeDownloads.clear();
    _activeProgress.clear();
  }
}
