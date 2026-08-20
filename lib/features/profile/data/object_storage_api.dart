import 'dart:typed_data';

import '../../../core/network/api_client.dart';

class ObjectStorageApi {
  const ObjectStorageApi(this._client);

  final ApiClient _client;

  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final response = await _client.postMultipartFile<String>(
      '/api/v1/objects',
      bytes: bytes,
      fileName: fileName,
      decode: (json) {
        final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
        return map['id'] as String? ?? map['Id'] as String? ?? '';
      },
    );

    return response.data;
  }
}
