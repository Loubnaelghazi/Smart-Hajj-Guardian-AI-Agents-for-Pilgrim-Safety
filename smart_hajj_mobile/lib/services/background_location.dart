import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';

class BackgroundLocation {
  static const _channel = MethodChannel('guardian/background_location');
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static Future<void> start(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await _channel.invokeMethod('start', {
      'phone': phone,
      'baseUrl': AppConfig.apiBaseUrl,
      'language': prefs.getString('guardian.language') ?? 'en',
    });
  }

  static Future<void> updateLanguage(String language) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod('language', {'language': language});
    } on MissingPluginException {
      // No native service exists on test hosts.
    }
  }

  static Future<void> stop() async {
    if (supported) {
      try {
        await _channel.invokeMethod('stop');
      } on MissingPluginException {
        /* No native service exists on test hosts. */
      }
    }
  }

  static Future<Map<String, dynamic>> status() async => supported
      ? Map<String, dynamic>.from(
          await _channel.invokeMethod<Map>('status') ?? {},
        )
      : {'running': false};
}
