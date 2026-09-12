import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/background_location.dart';

final localeProvider = AsyncNotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    return Locale(prefs.getString('guardian.language') == 'ar' ? 'ar' : 'en');
  }

  Future<void> change(String code) async {
    if (code != 'en' && code != 'ar') return;
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString('guardian.language', code);
    if (!saved) throw StateError('Language preference could not be saved');
    if (ref.mounted) state = AsyncData(Locale(code));
    await BackgroundLocation.updateLanguage(code);
  }
}
