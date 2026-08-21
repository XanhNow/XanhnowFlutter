class AdminUserSecurityStatus {
  const AdminUserSecurityStatus({
    required this.userId,
    required this.phoneNumber,
    required this.passkeyCredentialCount,
    required this.smartOtpDeviceCount,
    required this.isLocked,
    this.displayName,
  });

  factory AdminUserSecurityStatus.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    return AdminUserSecurityStatus(
      userId: map['userId'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      displayName: map['displayName'] as String?,
      passkeyCredentialCount: map['passkeyCredentialCount'] as int? ?? 0,
      smartOtpDeviceCount: map['smartOtpDeviceCount'] as int? ?? 0,
      isLocked: map['isLocked'] as bool? ?? false,
    );
  }

  final String userId;
  final String phoneNumber;
  final String? displayName;
  final int passkeyCredentialCount;
  final int smartOtpDeviceCount;
  final bool isLocked;
}

class AdminRecoveryRequest {
  const AdminRecoveryRequest({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.reason,
    required this.createdByAdminId,
    required this.createdAtUtc,
    required this.status,
    this.decisionByAdminId,
    this.decisionAtUtc,
    this.decisionReason,
    this.securityRecoveryGrantId,
    this.recoveryGrantExpiresAtUtc,
    this.securityCorrelationId,
  });

  factory AdminRecoveryRequest.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    return AdminRecoveryRequest(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      createdByAdminId: map['createdByAdminId'] as String? ?? '',
      createdAtUtc: map['createdAtUtc'] as String? ?? '',
      status: map['status'] as String? ?? 'Unknown',
      decisionByAdminId: map['decisionByAdminId'] as String?,
      decisionAtUtc: map['decisionAtUtc'] as String?,
      decisionReason: map['decisionReason'] as String?,
      securityRecoveryGrantId: map['securityRecoveryGrantId'] as String?,
      recoveryGrantExpiresAtUtc: map['recoveryGrantExpiresAtUtc'] as String?,
      securityCorrelationId: map['securityCorrelationId'] as String?,
    );
  }

  final String id;
  final String userId;
  final String phoneNumber;
  final String reason;
  final String createdByAdminId;
  final String createdAtUtc;
  final String status;
  final String? decisionByAdminId;
  final String? decisionAtUtc;
  final String? decisionReason;
  final String? securityRecoveryGrantId;
  final String? recoveryGrantExpiresAtUtc;
  final String? securityCorrelationId;
}
