import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/domain.dart';

class LocalStorage {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();
  Future<PilgrimSession?> restore() async {
    final raw = (await _prefs).getString('guardian.session');
    if (raw == null) return null;
    try {
      final session = PilgrimSession.fromJson(object(jsonDecode(raw)));
      return session.valid ? session : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> save(PilgrimSession session) async {
    if (!await (await _prefs).setString(
      'guardian.session',
      jsonEncode(session.toJson()),
    )) {
      throw const FormatException('Session storage unavailable');
    }
  }

  Future<void> clear() async {
    await (await _prefs).remove('guardian.session');
  }
}
