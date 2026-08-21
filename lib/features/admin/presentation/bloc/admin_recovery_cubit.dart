import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/admin_recovery_models.dart';
import '../../domain/admin_recovery_repository.dart';

enum AdminRecoveryStatus { initial, loading, userFound, userNotFound, failure }

enum AdminRecoveryActionStatus { idle, creating, approving, rejecting }

class AdminRecoveryState extends Equatable {
  const AdminRecoveryState({
    required this.status,
    this.actionStatus = AdminRecoveryActionStatus.idle,
    this.user,
    this.request,
    this.errorMessage,
    this.notice,
  });

  const AdminRecoveryState.initial()
    : this(status: AdminRecoveryStatus.initial);

  final AdminRecoveryStatus status;
  final AdminRecoveryActionStatus actionStatus;
  final AdminUserSecurityStatus? user;
  final AdminRecoveryRequest? request;
  final String? errorMessage;
  final String? notice;

  AdminRecoveryState copyWith({
    AdminRecoveryStatus? status,
    AdminRecoveryActionStatus? actionStatus,
    AdminUserSecurityStatus? user,
    AdminRecoveryRequest? request,
    String? errorMessage,
    String? notice,
    bool clearUser = false,
    bool clearRequest = false,
    bool clearError = false,
    bool clearNotice = false,
  }) {
    return AdminRecoveryState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      user: clearUser ? null : user ?? this.user,
      request: clearRequest ? null : request ?? this.request,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      notice: clearNotice ? null : notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [
    status,
    actionStatus,
    user,
    request,
    errorMessage,
    notice,
  ];
}

class AdminRecoveryCubit extends Cubit<AdminRecoveryState> {
  AdminRecoveryCubit({required AdminRecoveryRepository repository})
    : _repository = repository,
      super(const AdminRecoveryState.initial());

  final AdminRecoveryRepository _repository;

  Future<void> findUser(String phoneNumber) async {
    final phone = phoneNumber.trim();
    if (phone.isEmpty) {
      emit(
        state.copyWith(
          status: AdminRecoveryStatus.failure,
          errorMessage: 'Nhập số điện thoại cần tra cứu.',
          clearNotice: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AdminRecoveryStatus.loading,
        actionStatus: AdminRecoveryActionStatus.idle,
        clearUser: true,
        clearRequest: true,
        clearError: true,
        clearNotice: true,
      ),
    );

    try {
      final user = await _repository.findUserByPhone(phone);
      if (user == null) {
        emit(
          state.copyWith(
            status: AdminRecoveryStatus.userNotFound,
            notice: 'Không tìm thấy tài khoản với số điện thoại này.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: AdminRecoveryStatus.userFound,
          user: user,
          notice: 'Đã tìm thấy tài khoản.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminRecoveryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> createRequest({
    required String reason,
    required String adminId,
  }) async {
    final user = state.user;
    if (user == null) {
      emit(state.copyWith(errorMessage: 'Chưa có tài khoản để tạo yêu cầu.'));
      return;
    }

    if (reason.trim().isEmpty || adminId.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Nhập mã admin và lý do xử lý.'));
      return;
    }

    emit(
      state.copyWith(
        actionStatus: AdminRecoveryActionStatus.creating,
        clearError: true,
        clearNotice: true,
      ),
    );

    try {
      final request = await _repository.createRequest(
        userId: user.userId,
        phoneNumber: user.phoneNumber,
        reason: reason.trim(),
        adminId: adminId.trim(),
      );
      emit(
        state.copyWith(
          actionStatus: AdminRecoveryActionStatus.idle,
          request: request,
          notice: 'Đã tạo yêu cầu khôi phục.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: AdminRecoveryActionStatus.idle,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> approve({required String reason, required String adminId}) {
    return _decide(
      actionStatus: AdminRecoveryActionStatus.approving,
      reason: reason,
      adminId: adminId,
      action: _repository.approve,
      successMessage: 'Đã duyệt. Security đã revoke thiết bị cũ và cấp grant.',
    );
  }

  Future<void> reject({required String reason, required String adminId}) {
    return _decide(
      actionStatus: AdminRecoveryActionStatus.rejecting,
      reason: reason,
      adminId: adminId,
      action: _repository.reject,
      successMessage: 'Đã từ chối yêu cầu khôi phục.',
    );
  }

  Future<void> _decide({
    required AdminRecoveryActionStatus actionStatus,
    required String reason,
    required String adminId,
    required Future<AdminRecoveryRequest> Function({
      required String requestId,
      required String adminId,
      required String reason,
    })
    action,
    required String successMessage,
  }) async {
    final request = state.request;
    if (request == null) {
      emit(state.copyWith(errorMessage: 'Chưa có yêu cầu để xử lý.'));
      return;
    }

    if (reason.trim().isEmpty || adminId.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Nhập mã admin và lý do xử lý.'));
      return;
    }

    emit(
      state.copyWith(
        actionStatus: actionStatus,
        clearError: true,
        clearNotice: true,
      ),
    );

    try {
      final updated = await action(
        requestId: request.id,
        adminId: adminId.trim(),
        reason: reason.trim(),
      );
      emit(
        state.copyWith(
          actionStatus: AdminRecoveryActionStatus.idle,
          request: updated,
          notice: successMessage,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: AdminRecoveryActionStatus.idle,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
