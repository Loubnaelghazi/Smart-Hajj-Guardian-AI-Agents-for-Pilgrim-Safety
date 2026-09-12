import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hajj_mobile/core/network/dio_client.dart';
import 'package:smart_hajj_mobile/providers/dashboard_provider.dart';
import 'package:smart_hajj_mobile/providers/session_provider.dart';
import 'package:smart_hajj_mobile/services/incident_polling_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late ProviderContainer container;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'guardian.session': jsonEncode({
        'pilgrim_id': 'p',
        'group_id': 'g',
        'agency_id': 'a',
        'phone_number': '+1',
      }),
    });
    dio = Dio();
    container = ProviderContainer(
      overrides: [apiProvider.overrideWithValue(ApiClient(dio: dio))],
    );
  });
  tearDown(() {
    container.dispose();
    dio.close(force: true);
  });
  void seed({
    bool offline = false,
    void Function(RequestOptions, RequestInterceptorHandler)? sos,
  }) {
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          if (offline) {
            h.reject(
              DioException(
                requestOptions: r,
                type: DioExceptionType.connectionError,
              ),
            );
            return;
          }
          if (r.path == '/api/guardian/sos' && sos != null) {
            sos(r, h);
            return;
          }
          final data = switch (r.path) {
            '/api/pilgrims/p' => {
              'id': 'p',
              'group_id': 'g',
              'agency_id': 'a',
              'phone_number': '+1',
              'name': 'Ahmed',
            },
            '/api/groups/g' => {
              'group': {'id': 'g', 'name': 'Group A'},
              'safe_zone': null,
            },
            '/api/groups/g/safe-zone' => {'safe_zone': null},
            '/api/agencies/a' => {'id': 'a', 'name': 'Agency'},
            '/api/incidents/active' => [],
            '/api/pilgrims' => {'pilgrims': []},
            _ => {'status': 'ok'},
          };
          h.resolve(Response(requestOptions: r, data: data));
        },
      ),
    );
  }

  test(
    'failed refresh preserves actual profile and missing safe zone',
    () async {
      seed();
      final initial = await container.read(dashboardProvider.future);
      expect(initial.pilgrim?.name, 'Ahmed');
      expect(initial.zone, isNull);
      seed(offline: true);
      await container.read(dashboardProvider.notifier).refresh();
      final failed = container.read(dashboardProvider).value!;
      expect(failed.pilgrim?.name, 'Ahmed');
      expect(failed.error, contains('unavailable'));
      expect(failed.refreshing, isFalse);
    },
  );
  test('rapid SOS taps send one POST and maintain busy state', () async {
    final pending = Completer<void>();
    var calls = 0;
    seed(
      sos: (r, h) {
        calls++;
        pending.future.then(
          (_) => h.resolve(
            Response(
              requestOptions: r,
              data: {
                'phone_number': '+1',
                'risk': {'score': 100, 'level': 'CRITICAL'},
                'emergency': {'triggered': true},
              },
            ),
          ),
        );
      },
    );
    await container.read(dashboardProvider.future);
    final controller = container.read(dashboardProvider.notifier);
    final first = controller.check(sos: true);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(dashboardProvider).value!.sending, isTrue);
    await controller.check(sos: true);
    pending.complete();
    await first;
    expect(calls, 1);
    expect(container.read(dashboardProvider).value!.sending, isFalse);
    expect(
      container.read(dashboardProvider).value!.sosResult?.emergency.triggered,
      isTrue,
    );
  });
  testWidgets('poll clock stops, resumes once, and disposes', (tester) async {
    var ticks = 0;
    final service = IncidentPollingService(onTick: (_) => ticks++);
    service.start();
    service.start();
    await tester.pump(const Duration(seconds: 10));
    expect(ticks, 3);
    service.stop();
    await tester.pump(const Duration(seconds: 20));
    expect(ticks, 3);
    service.start();
    expect(ticks, 4);
    service.dispose();
    await tester.pump(const Duration(seconds: 10));
    expect(ticks, 4);
  });
  test('logout clears the persisted identity', () async {
    expect((await container.read(sessionProvider.future))?.pilgrimId, 'p');
    await container.read(sessionProvider.notifier).logout();
    expect(container.read(sessionProvider).value, isNull);
    expect(
      (await SharedPreferences.getInstance()).getString('guardian.session'),
      isNull,
    );
  });
}
