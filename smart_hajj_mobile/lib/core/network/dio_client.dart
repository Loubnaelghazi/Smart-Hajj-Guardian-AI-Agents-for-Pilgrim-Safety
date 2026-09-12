import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'app_exception.dart';

class ApiClient {
  ApiClient({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 90),
              sendTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/json'},
            ),
          );
  final Dio dio;
  Future<dynamic> get(String path) => _request(path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _request(path, body: body);
  Future<dynamic> _request(String path, {Map<String, dynamic>? body}) async {
    final mayHaveSideEffects = body != null && path != '/api/pilgrims/lookup';
    try {
      final response = body == null
          ? await dio.get<dynamic>(path)
          : await dio.post<dynamic>(path, data: body);
      if (response.data is! Map && response.data is! List) {
        throw AppException(
          'Guardian returned incomplete information. Please try again.',
          uncertain: mayHaveSideEffects,
        );
      }
      return response.data;
    } on DioException catch (error) {
      if (mayHaveSideEffects && (error.response?.statusCode ?? 0) >= 500) {
        throw AppException(
          'We could not confirm the request. Check emergency status or call your guide before retrying.',
          statusCode: error.response?.statusCode,
          uncertain: true,
        );
      }
      if (error.response != null) {
        throw AppException.status(error.response?.statusCode);
      }
      throw AppException(
        !mayHaveSideEffects ? 'Guardian connection unavailable. Retrying…' : 'We could not confirm the request. It may have reached Guardian. Check emergency status or call your guide before retrying.',
        uncertain: mayHaveSideEffects,
      );
    } on FormatException {
      throw AppException(
        'Guardian returned incomplete information. Please try again.',
        uncertain: mayHaveSideEffects,
      );
    }
  }
}
