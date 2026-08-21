import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../errors/app_exception.dart';
import '../storage/secure_token_store.dart';
import 'api_result.dart';

typedef JsonMap = Map<String, dynamic>;

class MultipartFilePayload {
  const MultipartFilePayload({
    required this.fieldName,
    required this.bytes,
    required this.fileName,
  });

  final String fieldName;
  final Uint8List bytes;
  final String fileName;
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    required SecureTokenStore tokenStore,
    http.Client? httpClient,
    Uuid? uuid,
  }) : _baseUri = Uri.parse(baseUrl.replaceAll(RegExp(r'/+$'), '')),
       _tokenStore = tokenStore,
       _http = httpClient ?? http.Client(),
       _uuid = uuid ?? const Uuid();

  final Uri _baseUri;
  final SecureTokenStore _tokenStore;
  final http.Client _http;
  final Uuid _uuid;
  String? _temporaryAccessToken;

  Future<T> withTemporaryAccessToken<T>(
    String accessToken,
    Future<T> Function() action,
  ) async {
    final previous = _temporaryAccessToken;
    _temporaryAccessToken = accessToken;
    try {
      return await action();
    } finally {
      _temporaryAccessToken = previous;
    }
  }

  Future<ApiEnvelope<T>> get<T>(
    String path,
    T Function(Object? json) decode, {
    bool authenticated = true,
    bool suppressNotFoundLog = false,
  }) async {
    final uri = _uri(path);
    final response = await _http.get(
      uri,
      headers: await _headers(authenticated: authenticated),
    );
    return _parse(
      response,
      decode,
      method: 'GET',
      uri: uri,
      suppressNotFoundLog: suppressNotFoundLog,
    );
  }

  Future<ApiEnvelope<T>> post<T>(
    String path,
    Object body,
    T Function(Object? json) decode, {
    bool authenticated = true,
    String? idempotencyKey,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _uri(path);
    final response = await _http.post(
      uri,
      headers: await _headers(
        authenticated: authenticated,
        idempotencyKey: idempotencyKey,
        extraHeaders: extraHeaders,
      ),
      body: jsonEncode(body),
    );
    return _parse(response, decode, method: 'POST', uri: uri);
  }

  Future<ApiEnvelope<T>> put<T>(
    String path,
    Object body,
    T Function(Object? json) decode, {
    bool authenticated = true,
    String? idempotencyKey,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _uri(path);
    final response = await _http.put(
      uri,
      headers: await _headers(
        authenticated: authenticated,
        idempotencyKey: idempotencyKey,
        extraHeaders: extraHeaders,
      ),
      body: jsonEncode(body),
    );
    return _parse(response, decode, method: 'PUT', uri: uri);
  }

  Future<void> postNoContent(
    String path, {
    bool authenticated = true,
    String? idempotencyKey,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _uri(path);
    final response = await _http.post(
      uri,
      headers: await _headers(
        authenticated: authenticated,
        idempotencyKey: idempotencyKey,
        extraHeaders: extraHeaders,
      ),
    );
    _parseNoContent(response, method: 'POST', uri: uri);
  }

  Future<void> putNoContent(
    String path,
    Object body, {
    bool authenticated = true,
    String? idempotencyKey,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _uri(path);
    final response = await _http.put(
      uri,
      headers: await _headers(
        authenticated: authenticated,
        idempotencyKey: idempotencyKey,
        extraHeaders: extraHeaders,
      ),
      body: jsonEncode(body),
    );
    _parseNoContent(response, method: 'PUT', uri: uri);
  }

  Future<ApiEnvelope<T>> postMultipartFile<T>(
    String path, {
    required Uint8List bytes,
    required String fileName,
    required T Function(Object? json) decode,
    String fieldName = 'file',
    bool authenticated = true,
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _headers(authenticated: authenticated));
    request.headers.remove('Content-Type');
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
    );

    final streamedResponse = await _http.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _parse(response, decode, method: 'POST', uri: uri);
  }

  Future<ApiEnvelope<T>> postMultipart<T>(
    String path, {
    required Map<String, String> fields,
    required List<MultipartFilePayload> files,
    required T Function(Object? json) decode,
    bool authenticated = true,
  }) {
    return _sendMultipart(
      'POST',
      path,
      fields: fields,
      files: files,
      decode: decode,
      authenticated: authenticated,
    );
  }

  Future<void> putMultipartNoContent(
    String path, {
    required Map<String, String> fields,
    required List<MultipartFilePayload> files,
    bool authenticated = true,
  }) async {
    final envelope = await _sendMultipart<void>(
      'PUT',
      path,
      fields: fields,
      files: files,
      decode: (_) {},
      authenticated: authenticated,
    );
    return envelope.data;
  }

  Future<void> delete(
    String path, {
    bool authenticated = true,
    String? idempotencyKey,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _uri(path);
    final response = await _http.delete(
      uri,
      headers: await _headers(
        authenticated: authenticated,
        idempotencyKey: idempotencyKey,
        extraHeaders: extraHeaders,
      ),
    );
    _logResponse('DELETE', uri, response);
    if (response.statusCode == 204) {
      return;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwError(response);
    }
  }

  Future<ApiEnvelope<T>> _sendMultipart<T>(
    String method,
    String path, {
    required Map<String, String> fields,
    required List<MultipartFilePayload> files,
    required T Function(Object? json) decode,
    required bool authenticated,
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest(method, uri);
    request.headers.addAll(await _headers(authenticated: authenticated));
    request.headers.remove('Content-Type');
    request.fields.addAll(fields);
    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          file.fieldName,
          file.bytes,
          filename: file.fileName,
        ),
      );
    }

    final streamedResponse = await _http.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _parse(response, decode, method: method, uri: uri);
  }

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return _baseUri.replace(path: '${_baseUri.path}/$normalized');
  }

  Future<Map<String, String>> _headers({
    required bool authenticated,
    String? idempotencyKey,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Correlation-Id': _uuid.v4(),
      'X-Contract-Version': 'v1',
      ...?extraHeaders,
    };
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    if (authenticated) {
      final accessToken = _temporaryAccessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      } else {
        final tokens = await _tokenStore.read();
        if (tokens?.accessToken case final storedAccessToken?) {
          headers['Authorization'] = 'Bearer $storedAccessToken';
        }
      }
    }
    return headers;
  }

  ApiEnvelope<T> _parse<T>(
    http.Response response,
    T Function(Object? json) decode, {
    required String method,
    required Uri uri,
    bool suppressNotFoundLog = false,
  }) {
    _logResponse(
      method,
      uri,
      response,
      suppressNotFoundLog: suppressNotFoundLog,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwError(response);
    }
    if (response.bodyBytes.isEmpty) {
      return ApiEnvelope<T>(data: decode(null), metadata: ApiMetadata.empty());
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as JsonMap;
    if (!json.containsKey('data') || !json.containsKey('metadata')) {
      return ApiEnvelope<T>(data: decode(json), metadata: ApiMetadata.empty());
    }
    return ApiEnvelope<T>(
      data: decode(json['data']),
      metadata: ApiMetadata.fromJson(json['metadata'] as JsonMap),
    );
  }

  void _parseNoContent(
    http.Response response, {
    required String method,
    required Uri uri,
  }) {
    _logResponse(method, uri, response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwError(response);
    }
  }

  Never _throwError(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as JsonMap;
      if (json.containsKey('title') || json.containsKey('detail')) {
        final title = json['title'] as String? ?? 'Request failed';
        final detail = json['detail'] as String? ?? title;
        throw AppException(
          detail,
          code: title,
          statusCode: response.statusCode,
        );
      }
      final error = ApiError.fromJson(json);
      final message = _friendlyErrorMessage(error);
      throw AppException(
        message,
        code: error.code,
        statusCode: response.statusCode,
      );
    } on FormatException {
      final reason = response.statusCode == 504
          ? 'Gateway timeout. Backend did not respond in time.'
          : 'Unexpected server response.';
      throw AppException(reason, statusCode: response.statusCode);
    }
  }

  String _friendlyErrorMessage(ApiError error) {
    if (error.code == 'CONFLICT' &&
        error.message.contains('Auth_Login_App returned 400')) {
      return 'Phone number was rejected by Auth Login. Please use a new Vietnamese mobile number.';
    }
    if (error.code == 'CONFLICT' &&
        error.message.contains('Auth_Login_App returned 409')) {
      return 'Số điện thoại này đã được đăng ký. Vui lòng dùng số khác hoặc chuyển sang đăng nhập.';
    }
    return error.message;
  }

  void _logResponse(
    String method,
    Uri uri,
    http.Response response, {
    bool suppressNotFoundLog = false,
  }) {
    if (!kDebugMode) {
      return;
    }
    if (suppressNotFoundLog && response.statusCode == 404) {
      return;
    }
    final requestId = response.headers['x-request-id'];
    final requestIdSuffix = requestId == null ? '' : ' requestId=$requestId';
    final errorSuffix = response.statusCode >= 400
        ? _debugErrorSuffix(response)
        : '';
    debugPrint(
      'XanhNow API $method ${uri.path} -> ${response.statusCode}$requestIdSuffix$errorSuffix',
    );
  }

  String _debugErrorSuffix(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as JsonMap;
      final code = json['code'];
      final message = json['message'];
      if (code is String && message is String) {
        return ' code=$code message=$message';
      }
      if (message is String) {
        return ' message=$message';
      }
    } on Object {
      return '';
    }
    return '';
  }
}
