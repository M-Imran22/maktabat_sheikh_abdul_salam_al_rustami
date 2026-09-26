import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Manages local cached audio files preserving the original directory structure.
class AudioCacheManager {
  static Future<Directory> _getBaseAudioDir({bool create = true}) async {
    final docs = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${docs.path}/app_audio');
    if (create && !await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  /// Returns the target local File for a given relative path.
  static Future<File> _fileFor(
    String relativePath, {
    bool create = false,
  }) async {
    final baseDir = await _getBaseAudioDir(create: create);
    final normalized = relativePath.replaceAll('\\', '/');
    if (normalized.isEmpty ||
        normalized.startsWith('/') ||
        RegExp(r'^[A-Za-z]:').hasMatch(normalized) ||
        normalized.split('/').any((part) => part == '..' || part == '.')) {
      throw FormatException('Invalid audio path: $relativePath');
    }
    final file = File('${baseDir.path}/$normalized');
    if (create && !await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return file;
  }

  static Future<File> getLocalFile(String relativePath) =>
      _fileFor(relativePath, create: true);

  /// Returns the cached file path if it exists, otherwise null.
  static Future<String?> getCachedAudioPath(String relativePath) async {
    final file = await _fileFor(relativePath);
    return await file.exists() && await file.length() > 1024 ? file.path : null;
  }

  /// Checks if the audio file exists locally for offline playback.
  static Future<bool> isDownloaded(String relativePath) async {
    return await getCachedAudioPath(relativePath) != null;
  }

  /// Deletes a cached audio file to free up device storage.
  static Future<void> deleteCachedAudio(String relativePath) async {
    final file = await _fileFor(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
