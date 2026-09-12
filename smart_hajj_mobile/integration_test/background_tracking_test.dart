import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_hajj_mobile/services/background_location.dart';

// Opt in: uploads emulator GPS for the registered demo pilgrim only.
// Grant location/notification permissions using adb before running. Once
// BACKGROUND_TRACKING_READY appears, press Android Home and inject a GPS fix.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android service uploads while activity is minimized and stops', (tester) async {
    if (!const bool.fromEnvironment('RUN_BACKGROUND_TRACKING')) return;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: Text('Background GPS validation · demo pilgrim')))));
    await BackgroundLocation.start('+99999991000');
    await Future<void>.delayed(const Duration(seconds: 2));
    expect((await BackgroundLocation.status())['running'], true);
    debugPrint('BACKGROUND_TRACKING_READY');
    await Future<void>.delayed(const Duration(seconds: 60));
    final status = await BackgroundLocation.status();
    expect(status['running'], true);
    expect(status['receipt'], isA<String>());
    final receipt = jsonDecode(status['receipt'] as String) as Map;
    expect(receipt['phone_number'], '+99999991000');
    expect(DateTime.now().toUtc().difference(DateTime.parse(receipt['measured_at'] as String)).inSeconds, lessThan(60));
    debugPrint('BACKGROUND_UPLOAD_CONFIRMED');
    await BackgroundLocation.stop();
    await Future<void>.delayed(const Duration(seconds: 2));
    expect((await BackgroundLocation.status())['running'], false);
    debugPrint('BACKGROUND_STOP_CONFIRMED');
  });
}
