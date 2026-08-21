import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/admin_recovery_repository.dart';
import '../bloc/admin_recovery_cubit.dart';

const _adminTextColor = Color(0xFF0B2F4A);

class AdminRecoveryPage extends StatelessWidget {
  const AdminRecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminRecoveryCubit(
        repository: context.read<AdminRecoveryRepository>(),
      ),
      child: const _AdminRecoveryView(),
    );
  }
}

class _AdminRecoveryView extends StatefulWidget {
  const _AdminRecoveryView();

  @override
  State<_AdminRecoveryView> createState() => _AdminRecoveryViewState();
}

class _AdminRecoveryViewState extends State<_AdminRecoveryView> {
  final _phoneController = TextEditingController();
  final _adminIdController = TextEditingController(text: 'hotline-admin');
  final _reasonController = TextEditingController(
    text: 'Người dùng mất/thay điện thoại, đã xác minh qua hotline.',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _adminIdController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(color: _adminTextColor),
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: _adminTextColor,
          title: const Text('Admin khôi phục tài khoản'),
        ),
        body: BlocConsumer<AdminRecoveryCubit, AdminRecoveryState>(
          listenWhen: (previous, current) =>
              previous.notice != current.notice ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            final message = state.errorMessage ?? state.notice;
            if (message == null || message.isEmpty) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(message),
              ),
            );
          },
          builder: (context, state) {
            final isBusy =
                state.status == AdminRecoveryStatus.loading ||
                state.actionStatus != AdminRecoveryActionStatus.idle;

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Hotline/Admin recovery',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _adminTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại người dùng',
                      prefixIcon: Icon(Icons.phone_android_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => context.read<AdminRecoveryCubit>().findUser(
                            _phoneController.text,
                          ),
                    icon: isBusy && state.status == AdminRecoveryStatus.loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Tra cứu tài khoản'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _adminIdController,
                    decoration: const InputDecoration(
                      labelText: 'Mã admin/hotline',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Lý do xử lý',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.user != null) ...[
                    _UserStatusPanel(state: state),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => context
                                .read<AdminRecoveryCubit>()
                                .createRequest(
                                  reason: _reasonController.text,
                                  adminId: _adminIdController.text,
                                ),
                      icon:
                          state.actionStatus ==
                              AdminRecoveryActionStatus.creating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_task_outlined),
                      label: const Text('Tạo yêu cầu khôi phục'),
                    ),
                  ],
                  if (state.request != null) ...[
                    const SizedBox(height: 16),
                    _RecoveryRequestPanel(state: state),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => context.read<AdminRecoveryCubit>().approve(
                              reason: _reasonController.text,
                              adminId: _adminIdController.text,
                            ),
                      icon:
                          state.actionStatus ==
                              AdminRecoveryActionStatus.approving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Duyệt khôi phục'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => context.read<AdminRecoveryCubit>().reject(
                              reason: _reasonController.text,
                              adminId: _adminIdController.text,
                            ),
                      icon:
                          state.actionStatus ==
                              AdminRecoveryActionStatus.rejecting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined),
                      label: const Text('Từ chối'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Về trang Home'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserStatusPanel extends StatelessWidget {
  const _UserStatusPanel({required this.state});

  final AdminRecoveryState state;

  @override
  Widget build(BuildContext context) {
    final user = state.user!;
    return _InfoPanel(
      icon: Icons.person_search_outlined,
      title: 'Tài khoản',
      rows: [
        _InfoRow('User ID', user.userId),
        _InfoRow('Số điện thoại', user.phoneNumber),
        _InfoRow('Passkey', '${user.passkeyCredentialCount} credential'),
        _InfoRow('Smart OTP', '${user.smartOtpDeviceCount} thiết bị'),
        _InfoRow('Trạng thái khóa', user.isLocked ? 'Đang khóa' : 'Không khóa'),
      ],
    );
  }
}

class _RecoveryRequestPanel extends StatelessWidget {
  const _RecoveryRequestPanel({required this.state});

  final AdminRecoveryState state;

  @override
  Widget build(BuildContext context) {
    final request = state.request!;
    return _InfoPanel(
      icon: Icons.fact_check_outlined,
      title: 'Yêu cầu khôi phục',
      rows: [
        _InfoRow('Request ID', request.id),
        _InfoRow('Trạng thái', request.status),
        _InfoRow('Người tạo', request.createdByAdminId),
        _InfoRow('Lý do', request.reason),
        if (request.securityRecoveryGrantId != null)
          _InfoRow('Recovery grant ID', request.securityRecoveryGrantId!),
        if (request.recoveryGrantExpiresAtUtc != null)
          _InfoRow('Hết hạn', request.recoveryGrantExpiresAtUtc!),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _adminTextColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            for (final row in rows) ...[
              Text(row.label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              SelectableText(
                row.value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}
