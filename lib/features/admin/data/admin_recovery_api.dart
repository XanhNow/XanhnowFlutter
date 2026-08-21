import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import 'models/admin_recovery_models.dart';

class AdminRecoveryApi {
  const AdminRecoveryApi(this._client);

  final ApiClient _client;

  Future<AdminUserSecurityStatus?> findUserByPhone(String phoneNumber) async {
    try {
      final response = await _client.get(
        '/admin/recovery/users?phone=${Uri.encodeQueryComponent(phoneNumber)}',
        AdminUserSecurityStatus.fromJson,
        suppressNotFoundLog: true,
      );
      return response.data;
    } on AppException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<AdminRecoveryRequest> createRequest({
    required String userId,
    required String phoneNumber,
    required String reason,
    required String adminId,
  }) async {
    final response = await _client.post('/admin/recovery/requests', {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'reason': reason,
      'adminId': adminId,
    }, AdminRecoveryRequest.fromJson);
    return response.data;
  }

  Future<AdminRecoveryRequest> approve({
    required String requestId,
    required String adminId,
    required String reason,
  }) async {
    final response = await _client.post(
      '/admin/recovery/requests/$requestId/approve',
      {'adminId': adminId, 'reason': reason},
      AdminRecoveryRequest.fromJson,
    );
    return response.data;
  }

  Future<AdminRecoveryRequest> reject({
    required String requestId,
    required String adminId,
    required String reason,
  }) async {
    final response = await _client.post(
      '/admin/recovery/requests/$requestId/reject',
      {'adminId': adminId, 'reason': reason},
      AdminRecoveryRequest.fromJson,
    );
    return response.data;
  }
}
