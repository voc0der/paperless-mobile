import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/interceptor/dio_offline_interceptor.dart';
import 'package:paperless_mobile/core/interceptor/dio_unauthorized_interceptor.dart';
import 'package:paperless_mobile/core/interceptor/retry_on_connection_change_interceptor.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';

/// Manages the security context, authentication and base request URL for
/// an underlying [Dio] client which is injected into all services
/// requiring authenticated access to the Paperless REST API.
class SessionManagerImpl extends ValueNotifier<Dio> implements SessionManager {
  @override
  Dio get client => value;

  SessionManagerImpl([List<Interceptor> interceptors = const []])
      : super(_initDio(interceptors));

  static Dio _initDio(List<Interceptor> interceptors) {
    //en- and decoded by utf8 by default
    final Dio dio = Dio(
      BaseOptions(
        contentType: Headers.jsonContentType,
        followRedirects: true,
        maxRedirects: 10,
      ),
    );
    dio.options
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 60)
      ..responseType = ResponseType.json;
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        () => HttpClient()..badCertificateCallback = (cert, host, port) => true;
    dio.interceptors.addAll([
      ...interceptors,
      DioUnauthorizedInterceptor(),
      DioHttpErrorInterceptor(),
      DioOfflineInterceptor(),
      RetryOnConnectionChangeInterceptor(dio: dio)
    ]);
    return dio;
  }

  @override
  void updateSettings({
    String? baseUrl,
    String? authToken,
    ClientCertificate? clientCertificate,
  }) {
    if (clientCertificate != null) {
      final bytes = clientCertificate.bytes;
      final passphrase = clientCertificate.passphrase;
      final hasPassphrase = passphrase != null && passphrase.isNotEmpty;
      try {
        // NOTE: On Android, the private key is configured separately via
        // usePrivateKey*/usePrivateKeyBytes*. On iOS, useCertificateChain*
        // is a no-op and the PKCS#12 data passed to usePrivateKey* should
        // contain both certificate + key.
        //
        // Using both calls is safe cross-platform as long as the .pfx actually
        // contains a private key.
        final context = SecurityContext();

        if (hasPassphrase) {
          context.useCertificateChainBytes(bytes, password: passphrase);
          context.usePrivateKeyBytes(bytes, password: passphrase);
        } else {
          context.useCertificateChainBytes(bytes);
          context.usePrivateKeyBytes(bytes);
        }
        final adapter = IOHttpClientAdapter()
          ..createHttpClient = () => HttpClient(context: context)
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;

        client.httpClientAdapter = adapter;
      } on TlsException catch (e) {
        debugPrint(
          'Failed to load client certificate '
          '(file=${clientCertificate.filename}, bytes=${bytes.length}, '
          'hasPassphrase=$hasPassphrase): $e',
        );
        rethrow;
      }
    }

    if (baseUrl != null) {
      client.options.baseUrl = baseUrl;
    }

    if (authToken != null) {
      client.options.headers.addAll({
        HttpHeaders.authorizationHeader: 'Token $authToken',
      });
    }

    notifyListeners();
  }

  @override
  void resetSettings() {
    client.httpClientAdapter = IOHttpClientAdapter();
    client.options.baseUrl = '';
    client.options.headers.remove(HttpHeaders.authorizationHeader);
    notifyListeners();
  }
}
