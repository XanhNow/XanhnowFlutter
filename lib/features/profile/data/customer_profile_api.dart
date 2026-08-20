import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import 'models/profile_models.dart';

class CustomerProfileApi {
  const CustomerProfileApi(this._client);

  final ApiClient _client;

  Future<CustomerProfileSummary?> getCurrentProfile(
    CustomerProfileType type,
  ) async {
    try {
      final response = await _client.get(
        type.currentPath,
        (json) => CustomerProfileSummary.fromJson(type, json),
      );
      return response.data;
    } on AppException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<String> createProfile(
    CustomerProfileType type,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(type.basePath, body, (json) {
      final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
      return map['id'] as String? ?? '';
    });
    return response.data;
  }

  Future<void> updateCurrentProfile(
    CustomerProfileType type,
    Map<String, dynamic> body,
  ) {
    return _client.putNoContent(type.currentPath, body);
  }

  Future<void> submitCurrentProfile(CustomerProfileType type) {
    return _client.postNoContent('${type.currentPath}/submit');
  }

  Future<void> deleteCurrentDraft(CustomerProfileType type) {
    return _client.delete(type.currentPath);
  }
}
