import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://phytot-rapie-app-backend-production.up.railway.app',
);

final publicApiProvider = Provider<PublicApi>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return PublicApi(dio);
});

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.isOffline = false, this.statusCode});
  final String message;
  final bool isOffline;
  final int? statusCode;
}

/// Client public uniquement : aucun compte, token ou intercepteur d'auth.
class PublicApi {
  PublicApi(this._dio);
  final Dio _dio;

  Future<Object?> get(String path, {Map<String, Object>? query}) async {
    try {
      return (await _dio.get<Object?>(path, queryParameters: query)).data;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError) {
        throw const ApiFailure(
          'Pas de connexion internet. Vérifiez votre connexion et réessayez.',
          isOffline: true,
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const ApiFailure('La connexion prend trop de temps. Réessayez.');
      }
      final status = error.response?.statusCode;
      if (status == 404) {
        throw const ApiFailure(
          'Ce contenu n’est plus disponible.',
          statusCode: 404,
        );
      }
      // Ne pas afficher les détails techniques ou HTML du proxy à l'utilisateur.
      throw ApiFailure(
        'Le catalogue est momentanément indisponible. Réessayez dans un instant.',
        statusCode: status,
      );
    }
  }
}
