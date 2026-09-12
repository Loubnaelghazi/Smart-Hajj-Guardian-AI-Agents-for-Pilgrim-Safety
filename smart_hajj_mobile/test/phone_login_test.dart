import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_hajj_mobile/core/network/app_exception.dart';
import 'package:smart_hajj_mobile/core/network/dio_client.dart';
import 'package:smart_hajj_mobile/providers/session_provider.dart';
import 'package:smart_hajj_mobile/repositories/repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'a different registered phone creates its own persisted session',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.path, '/api/pilgrims/lookup');
            expect(request.method, 'POST');
            expect(request.data, {'phone_number': '+212622222222'});
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'id': 'another-pilgrim',
                  'phone_number': '+212622222222',
                  'group_id': 'another-group',
                  'agency_id': 'another-agency',
                },
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [apiProvider.overrideWithValue(ApiClient(dio: dio))],
      );
      addTearDown(container.dispose);
      await container.read(sessionProvider.future);
      await container.read(sessionProvider.notifier).login('  +212622222222  ');
      final session = container.read(sessionProvider).value!;
      expect(session.pilgrimId, 'another-pilgrim');
      expect(session.groupId, 'another-group');
      expect(session.agencyId, 'another-agency');
      expect(
        (await container.read(storageProvider).restore())?.pilgrimId,
        'another-pilgrim',
      );
    },
  );
  test('unknown phone is rejected without saving a session', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          h.reject(
            DioException(
              requestOptions: r,
              response: Response(requestOptions: r, statusCode: 404),
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [apiProvider.overrideWithValue(ApiClient(dio: dio))],
    );
    addTearDown(container.dispose);
    await container.read(sessionProvider.future);
    await expectLater(
      container.read(sessionProvider.notifier).login('+212600000099'),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('No pilgrim is registered'),
        ),
      ),
    );
    expect(container.read(sessionProvider).value, isNull);
    expect(await container.read(storageProvider).restore(), isNull);
  });
  test('blank phone makes no network request', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: (_, _) => fail('Unexpected request')),
    );
    await expectLater(
      PilgrimRepository(ApiClient(dio: dio)).findByPhone('  '),
      throwsA(isA<AppException>()),
    );
  });
  test('lookup timeout has no emergency or uncertain-SOS message', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) => h.reject(
          DioException(
            requestOptions: r,
            type: DioExceptionType.receiveTimeout,
          ),
        ),
      ),
    );
    await expectLater(
      PilgrimRepository(ApiClient(dio: dio)).findByPhone('+212622222222'),
      throwsA(
        isA<AppException>()
            .having((e) => e.uncertain, 'uncertain', false)
            .having((e) => e.message, 'message', isNot(contains('emergency'))),
      ),
    );
  });
  test('mismatched backend identity is rejected', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) => h.resolve(
          Response(
            requestOptions: r,
            data: {
              'id': 'other',
              'phone_number': '+212600000000',
              'group_id': 'g',
              'agency_id': 'a',
            },
          ),
        ),
      ),
    );
    await expectLater(
      PilgrimRepository(ApiClient(dio: dio)).findByPhone('+212622222222'),
      throwsA(isA<AppException>()),
    );
  });
}
