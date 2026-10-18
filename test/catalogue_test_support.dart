import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Réponses publiques enregistrées : tests déterministes sans accès production.
class CatalogueAdapter implements HttpClientAdapter {
  CatalogueAdapter()
    : responses = Map<String, dynamic>.from(
        jsonDecode(File('test/fixtures/catalogue.json').readAsStringSync())
            as Map,
      );
  final Map<String, dynamic> responses;
  final List<RequestOptions> requests = [];
  bool offline = false;
  int? forcedStatus;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    var key = options.path;
    if (options.path == '/maladies' &&
        options.queryParameters['est_urgence'] == true) {
      key = '/urgences';
    }
    final found = responses.containsKey(key);
    return ResponseBody.fromString(
      jsonEncode(responses[key] ?? {'message': 'Introuvable'}),
      forcedStatus ?? (found ? 200 : 404),
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio catalogueDio(CatalogueAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
