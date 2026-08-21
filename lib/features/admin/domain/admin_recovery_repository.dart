import '../data/admin_recovery_api.dart';
import '../data/models/admin_recovery_models.dart';

class AdminRecoveryRepository {
  const AdminRecoveryRepository({required AdminRecoveryApi api}) : _api = api;

  final AdminRecoveryApi _api;

  Future<AdminUserSecurityStatus?> findUserByPhone(String phoneNumber) {
    return _api.findUserByPhone(phoneNumber);
  }

  Future<AdminRecoveryRequest> createRequest({
    required String userId,
    required String phoneNumber,
    required String reason,
    required String adminId,
  }) {
    return _api.createRequest(
      userId: userId,
      phoneNumber: phoneNumber,
      reason: reason,
      adminId: adminId,
    );
  }

  Future<AdminRecoveryRequest> approve({
    required String requestId,
    required String adminId,
    required String reason,
  }) {
    return _api.approve(requestId: requestId, adminId: adminId, reason: reason);
  }

  Future<AdminRecoveryRequest> reject({
    required String requestId,
    required String adminId,
    required String reason,
  }) {
    return _api.reject(requestId: requestId, adminId: adminId, reason: reason);
  }
}
