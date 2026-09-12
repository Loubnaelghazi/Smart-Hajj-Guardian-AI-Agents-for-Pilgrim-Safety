import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hajj_mobile/app.dart';
import 'package:smart_hajj_mobile/core/config/app_config.dart';
import 'package:smart_hajj_mobile/core/network/dio_client.dart';
import 'package:smart_hajj_mobile/models/domain.dart';
import 'package:smart_hajj_mobile/repositories/repositories.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real backend: demo session, tabs, safe zone and deliberate SOS',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guardian.session');
      await tester.pumpWidget(const ProviderScope(child: GuardianApp()));
      Future<void> waitFor(Finder finder, {int seconds = 30}) async {
        for (var i = 0; i < seconds * 2; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          if (finder.evaluate().isNotEmpty) return;
        }
        expect(finder, findsWidgets);
      }

      await waitFor(find.text('Join my Hajj group'));
      await tester.tap(find.text('Join my Hajj group'));
      await waitFor(find.textContaining('Hello,'));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Group').last);
      await waitFor(find.text('Here to help'));
      await tester.tap(find.text('Safety').last);
      await waitFor(find.text('Your safety,\nat a glance.'));
      await tester.tap(find.text('Profile').last);
      await waitFor(find.text('Your Hajj journey'));
      expect(find.text('DEMO SESSION'), findsOneWidget);
      await tester.tap(find.text('Home').last);
      await waitFor(find.textContaining('Hello,'));
      if (const bool.fromEnvironment('RUN_LIVE_SOS')) {
        await tester.scrollUntilVisible(
          find.text('SOS · I need help'),
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('SOS · I need help'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Send SOS now'));
        await waitFor(
          find.text('Emergency request sent to Guardian.'),
          seconds: 120,
        );
        final api = ApiClient();
        final incidents = await IncidentRepository(api)
            .active(AppConfig.pilgrimId);
        expect(
          incidents.any(
            (i) => i.type == 'SOS' && i.risk.level == RiskLevel.critical,
          ),
          isTrue,
        );
        final overview = object(
          await api.get('/api/agencies/${AppConfig.agencyId}/overview'),
        );
        expect(
          objects(overview['active_incidents']).any(
            (i) => i['pilgrim_id'] == AppConfig.pilgrimId && i['type'] == 'SOS',
          ),
          isTrue,
        );
        api.dio.close();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
