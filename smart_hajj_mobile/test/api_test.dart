import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hajj_mobile/core/network/app_exception.dart';
import 'package:smart_hajj_mobile/core/network/dio_client.dart';
import 'package:smart_hajj_mobile/models/domain.dart';
import 'package:smart_hajj_mobile/repositories/repositories.dart';

void main() {
  ApiClient client(int status, dynamic body) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (status >= 400) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: status),
                type: DioExceptionType.badResponse,
              ),
            );
          } else {
            handler.resolve(
              Response(requestOptions: options, statusCode: status, data: body),
            );
          }
        },
      ),
    );
    return ApiClient(dio: dio);
  }

  test('safe zone 404 is a nonfatal absence', () async {
    expect(await GroupRepository(client(404, {})).safeZone('g'), isNull);
  });
  for (final status in [400, 401, 403, 409, 422, 429, 500]) {
    test('HTTP $status becomes a normalized error', () async {
      await expectLater(
        client(status, {}).get('/health'),
        throwsA(
          isA<AppException>().having((e) => e.statusCode, 'status', status),
        ),
      );
    });
  }
  test('invalid JSON body does not escape into UI', () async {
    await expectLater(
      client(200, '<html>error</html>').get('/health'),
      throwsA(isA<AppException>()),
    );
  });
  test('SOS uses inspected endpoint and maps radius_m to radius', () async {
    final dio = Dio();
    RequestOptions? captured;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          captured = request;
          handler.resolve(
            Response(
              requestOptions: request,
              data: {
                'phone_number': '+1',
                'risk': {'score': 100, 'level': 'CRITICAL'},
                'emergency': {'triggered': true},
              },
            ),
          );
        },
      ),
    );
    await GuardianRepository(ApiClient(dio: dio)).analyze(
      '+1',
      SafeZone.fromJson({'latitude': 21, 'longitude': 39, 'radius_m': 250}),
      sos: true,
    );
    expect(captured!.path, '/api/guardian/sos');
    expect(captured!.data, {
      'phone_number': '+1',
      'safe_area': {'latitude': 21.0, 'longitude': 39.0, 'radius': 250},
    });
  });
  test(
    'ordinary analysis cannot silently use simulator default zone',
    () async {
      await expectLater(
        GuardianRepository(client(200, {})).analyze('+1', null),
        throwsA(isA<AppException>()),
      );
    },
  );
  test('timed out SOS is uncertain, never auto-retried', () async {
    final dio = Dio();
    var calls = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          calls++;
          h.reject(
            DioException(
              requestOptions: r,
              type: DioExceptionType.receiveTimeout,
            ),
          );
        },
      ),
    );
    await expectLater(
      ApiClient(dio: dio).post('/api/guardian/sos', {'phone_number': '+1'}),
      throwsA(
        isA<AppException>().having((e) => e.uncertain, 'uncertain', true),
      ),
    );
    expect(calls, 1);
  });
}
