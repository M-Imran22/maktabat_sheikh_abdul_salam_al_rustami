/// Application configuration for server endpoints and asset paths.
/// You can update [pdfBaseUrl] and [audioBaseUrl] with your server's endpoint.
class AppConfig {
  /// Base URL where PDF books are hosted on your server.
  static const String pdfBaseUrl = "https://portal.shaikhrustaminetwork.com/books/";

  /// Base URL where audio lectures are hosted on your server.
  static const String audioBaseUrl = "https://portal.shaikhrustaminetwork.com/Audio/";

  /// Checks if a valid remote server URL has been set for PDFs.
  static bool get isPdfServerConfigured {
    return pdfBaseUrl.trim().isNotEmpty &&
        (pdfBaseUrl.startsWith('http://') || pdfBaseUrl.startsWith('https://'));
  }

  /// Checks if a valid remote server URL has been set for Audio.
  static bool get isAudioServerConfigured {
    return audioBaseUrl.trim().isNotEmpty &&
        (audioBaseUrl.startsWith('http://') ||
            audioBaseUrl.startsWith('https://'));
  }

  /// Resolves the full URL for a given PDF file name or relative path.
  static String? getPdfUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return null;
    if (fileName.startsWith('http://') || fileName.startsWith('https://')) {
      return fileName;
    }
    if (!isPdfServerConfigured) return null;
    final base = pdfBaseUrl.endsWith('/') ? pdfBaseUrl : '$pdfBaseUrl/';
    final segments =
        fileName.split('/').map((s) => Uri.encodeComponent(s)).join('/');
    return '$base$segments';
  }

  /// Resolves the full URL for a given audio file name or relative path.
  static String? getAudioUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return null;
    if (fileName.startsWith('http://') || fileName.startsWith('https://')) {
      return fileName;
    }
    if (!isAudioServerConfigured) return null;
    final base = audioBaseUrl.endsWith('/') ? audioBaseUrl : '$audioBaseUrl/';
    final segments =
        fileName.split('/').map((s) => Uri.encodeComponent(s)).join('/');
    return '$base$segments';
  }

  /// Resolves the URL for the dynamic audio catalog JSON on the server.
  /// When audios are added to the server, updating audio_catalog.json allows
  /// the app to sync newly added lectures automatically without an app update.
  static String? get audioCatalogUrl {
    if (!isAudioServerConfigured) return null;
    final base = audioBaseUrl.endsWith('/') ? audioBaseUrl : '$audioBaseUrl/';
    return '${base}audio_catalog.json';
  }
}
