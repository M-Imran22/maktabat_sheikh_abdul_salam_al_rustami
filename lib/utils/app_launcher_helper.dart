import 'package:flutter/services.dart';

class AppLauncherHelper {
  static const MethodChannel _channel = MethodChannel(
    'com.shaikhrustami.maktabat/app_launcher',
  );

  /// Checks if an external Android application is currently installed
  static Future<bool> isAppInstalled(String packageName) async {
    try {
      final bool? installed = await _channel.invokeMethod<bool>(
        'isAppInstalled',
        {'package': packageName},
      );
      return installed ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the external app if installed, or redirects to Google Play Store
  static Future<bool> launchAppOrStore({
    required String packageName,
    required String storeUrl,
  }) async {
    try {
      final bool? launched = await _channel.invokeMethod<bool>(
        'launchAppOrStore',
        {'package': packageName, 'storeUrl': storeUrl},
      );
      return launched ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android's share sheet with a short description and this app's Play link.
  static Future<bool> shareApp(String message) async {
    try {
      final bool? opened = await _channel.invokeMethod<bool>('shareApp', {
        'message': message,
      });
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }
}
