import 'package:dio/dio.dart';
import 'package:paperless_api/paperless_api.dart';

class DioHttpErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Some nginx configs convert 400 to 200 with HTML error page
    // Check if 200 response contains error HTML indicating missing client cert
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is String &&
          data.contains("No required SSL certificate was sent")) {
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: const PaperlessApiException(
              ErrorCode.missingClientCertificate,
            ),
          ),
        );
        return;
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 400) {
      final data = err.response!.data;
      if (PaperlessServerMessageException.canParse(data)) {
        final exception = PaperlessServerMessageException.fromJson(data);
        final message = exception.detail;
        handler.reject(
          DioException(
            message: message,
            requestOptions: err.requestOptions,
            error: exception,
            response: err.response,
            type: DioExceptionType.badResponse,
          ),
        );
      } else if (PaperlessFormValidationException.canParse(data)) {
        final exception = PaperlessFormValidationException.fromJson(data);
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: exception,
            response: err.response,
            type: DioExceptionType.badResponse,
          ),
        );
      } else if (data is String) {
        if (data.contains("No required SSL certificate was sent")) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              type: DioExceptionType.badResponse,
              error: const PaperlessApiException(
                  ErrorCode.missingClientCertificate),
            ),
          );
        } else {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              message: data,
              error: PaperlessApiException(
                ErrorCode.documentLoadFailed,
                details: data,
              ),
              response: err.response,
              stackTrace: err.stackTrace,
              type: DioExceptionType.badResponse,
            ),
          );
        }
      } else {
        handler.reject(err);
      }
    }
  }
}
