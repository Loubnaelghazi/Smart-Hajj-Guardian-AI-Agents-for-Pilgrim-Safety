import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hajj_mobile/app.dart';
import 'package:smart_hajj_mobile/core/config/app_config.dart';
import 'package:smart_hajj_mobile/core/network/dio_client.dart';
import 'package:smart_hajj_mobile/models/domain.dart';
import 'package:smart_hajj_mobile/providers/dashboard_provider.dart';
import 'package:smart_hajj_mobile/repositories/repositories.dart';

/// Opt-in mutation test for the configured demo identity, never production.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Mina separation -> SOS -> acknowledgment -> resolution -> return',
    (tester) async {
      expect(
        const bool.fromEnvironment('RUN_DEMO_SCENARIO'),
        isTrue,
        reason: 'This test changes demo incidents. Opt in with RUN_DEMO_SCENARIO=true.',
      );
      final api = ApiClient();
      addTearDown(() => api.dio.close());
      await (await SharedPreferences.getInstance()).remove('guardian.session');
      await tester.pumpWidget(const ProviderScope(child: GuardianApp()));
      Future<void> until(bool Function() condition, {int seconds = 120}) async {
        for (var i = 0; i < seconds * 2; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          if (condition()) return;
        }
        expect(
          condition(),
          isTrue,
          reason: 'Timed out waiting for scenario state',
        );
      }

      Future<void> visible(String text) async {
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(text),
          250,
          scrollable: find.byType(Scrollable).first,
        );
      }

      await until(() => find.text('Join my Hajj group').evaluate().isNotEmpty);
      await tester.tap(find.text('Join my Hajj group'));
      await until(() => find.textContaining('Hello,').evaluate().isNotEmpty);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GuardianApp)),
      );
      DashboardData data() => container.read(dashboardProvider).value!;
      await until(() => data().zone != null && data().incidentsChecked);
      expect(data().zone!.name, 'Mina demo meeting point');
      expect(data().zone!.radius, 250);
      expect(data().incidents, isEmpty);

      await tester.tap(find.text('Group').last);
      await visible('Mina demo meeting point');
      expect(find.text('250 m'), findsOneWidget);
      await tester.tap(find.text('Safety').last);
      await visible('Check safety now');
      await tester.tap(find.text('Check safety now'));
      await until(
        () => !data().checking && data().guardian?.confidence.score != null,
      );
      expect(data().guardian!.risk.level, RiskLevel.high);
      expect(data().guardian!.telecom.distance, 450);
      expect(data().guardian!.action, 'RETURN_TO_GROUP');
      expect(data().guardian!.incident, isNull);
      expect(data().guardian!.telecom.geofence, 'outside');

      container.read(routerProvider).go('/return');
      await tester.pumpAndSettle();
      expect(find.text('Return to your group'), findsOneWidget);
      expect(find.text('450 m'), findsOneWidget);
      expect(find.text('Call guide'), findsOneWidget);
      await visible('Open in Maps');
      expect(find.text('Open in Maps'), findsOneWidget);

      // Cancel is a real UI action; it must not create a backend incident.
      await tester.tap(find.text('SOS · I need help'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        await IncidentRepository(api).active(AppConfig.pilgrimId),
        isEmpty,
      );
      await tester.tap(find.text('SOS · I need help'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send SOS now'));
      await until(() => !data().sending && data().sosResult != null);
      expect(data().sosResult!.risk.score, 100);
      expect(data().sosResult!.risk.level, RiskLevel.critical);
      expect(data().sosResult!.emergency.triggered, isTrue);
      final incident = data().incidents.firstWhere((i) => i.type == 'SOS');
      final overview = object(
        await api.get('/api/agencies/${AppConfig.agencyId}/overview'),
      );
      expect(
        objects(overview['active_incidents'])
            .any((i) => i['id'] == incident.id),
        isTrue,
      );

      // Simulate guide/agency actions through the same existing command-center API.
      await api.dio.patch<dynamic>('/api/incidents/${incident.id}/acknowledge');
      await until(
        () => data().incidents.any(
          (i) => i.id == incident.id && i.status == 'ACKNOWLEDGED',
        ),
      );
      expect(
        find.text('Your guide or agency has acknowledged this alert.'),
        findsOneWidget,
      );
      await api.dio.patch<dynamic>('/api/incidents/${incident.id}/resolve');
      await until(() => data().incidents.every((i) => i.id != incident.id));
      await container.read(dashboardProvider.notifier).check();
      expect(data().guardian!.risk.level, RiskLevel.high);
      expect(data().incidents, isEmpty);

      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('DEMO SESSION'), findsOneWidget);
      await visible('Leave demo session');
      await tester.tap(find.text('Leave demo session'));
      await until(() => find.text('Join my Hajj group').evaluate().isNotEmpty);
      expect(
        (await SharedPreferences.getInstance()).getString('guardian.session'),
        isNull,
      );
      await tester.tap(find.text('Join my Hajj group'));
      await until(() => find.textContaining('Hello,').evaluate().isNotEmpty);
      expect(
        (await SharedPreferences.getInstance()).getString('guardian.session'),
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
