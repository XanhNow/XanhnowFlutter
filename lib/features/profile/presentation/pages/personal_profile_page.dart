import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/home_page.dart';
import '../../data/models/profile_models.dart';
import '../../domain/profile_repository.dart';
import '../bloc/profile_cubit.dart';
import 'profile_module_page.dart';

const _profileTextColor = Color(0xFF0B2F4A);

class PersonalProfilePage extends StatelessWidget {
  const PersonalProfilePage({
    this.type = CustomerProfileType.individualDemandOnly,
    super.key,
  });

  final CustomerProfileType type;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileCubit(repository: context.read<ProfileRepository>())
            ..load(type),
      child: const _PersonalProfileView(),
    );
  }
}

class _PersonalProfileView extends StatefulWidget {
  const _PersonalProfileView();

  @override
  State<_PersonalProfileView> createState() => _PersonalProfileViewState();
}

class _PersonalProfileViewState extends State<_PersonalProfileView> {
  final _imagePicker = ImagePicker();
  Uint8List? _avatarBytes;
  bool _showDetails = false;
  bool _deleteInProgress = false;
  String? _message;
  bool _messageIsError = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.actionStatus != current.actionStatus ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final errorMessage = state.errorMessage;
        if (state.status == ProfileLoadStatus.failure &&
            errorMessage != null &&
            errorMessage.isNotEmpty) {
          _deleteInProgress = false;
          _showMessage(errorMessage, isError: true);
        }
        if (_deleteInProgress &&
            state.actionStatus == ProfileActionStatus.idle &&
            state.status == ProfileLoadStatus.empty) {
          _deleteInProgress = false;
          _showMessage('Hồ sơ đã được xóa.');
        }
      },
      builder: (context, state) {
        final isBusy =
            state.actionStatus != ProfileActionStatus.idle ||
            state.status == ProfileLoadStatus.loading;

        return DefaultTextStyle.merge(
          style: const TextStyle(color: _profileTextColor),
          child: Scaffold(
            appBar: AppBar(
              foregroundColor: _profileTextColor,
              title: const Text('Hồ sơ cá nhân'),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _AvatarHeader(
                    avatarBytes: _avatarBytes,
                    title:
                        state.profile?.stringValue('fullName').isNotEmpty ==
                            true
                        ? state.profile!.stringValue('fullName')
                        : 'Hồ sơ cá nhân',
                    subtitle:
                        state.profile?.stringValue('phoneNumber') ??
                        state.selectedType.title,
                    onPickAvatar: isBusy ? null : _pickAvatar,
                  ),
                  const SizedBox(height: 16),
                  _StatusPanel(state: state),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    _InlineMessage(
                      message: _message!,
                      isError: _messageIsError,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: isBusy
                        ? null
                        : state.profile == null
                        ? () => _openEditPage(context, state.selectedType)
                        : () => setState(() => _showDetails = !_showDetails),
                    icon: state.profile == null
                        ? const Icon(Icons.assignment_ind_outlined)
                        : Icon(
                            _showDetails
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                    label: Text(
                      state.profile == null
                          ? 'Tạo hồ sơ'
                          : _showDetails
                          ? 'Ẩn hồ sơ'
                          : 'Xem hồ sơ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: isBusy || state.profile == null
                        ? null
                        : () => _openEditPage(context, state.selectedType),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa hồ sơ'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: isBusy || state.profile == null
                        ? null
                        : () => _confirmDelete(context),
                    icon:
                        isBusy &&
                            state.actionStatus == ProfileActionStatus.deleting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text('Xóa hồ sơ'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : () => _goHome(context),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Về trang Home'),
                  ),
                  if (_showDetails && state.profile != null) ...[
                    const SizedBox(height: 20),
                    _ProfileDetails(profile: state.profile!),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() => _avatarBytes = bytes);
    _showMessage('Đã cập nhật avatar trên thiết bị.');
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa hồ sơ?'),
          content: const Text('Hồ sơ draft hiện tại sẽ bị xóa khỏi hệ thống.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    _deleteInProgress = true;
    context.read<ProfileCubit>().deleteDraft();
  }

  void _openEditPage(BuildContext context, CustomerProfileType type) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ProfileModulePage(initialType: type),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }
}

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({
    required this.avatarBytes,
    required this.title,
    required this.subtitle,
    required this.onPickAvatar,
  });

  final Uint8List? avatarBytes;
  final String title;
  final String subtitle;
  final VoidCallback? onPickAvatar;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: avatarBytes == null
                  ? null
                  : MemoryImage(avatarBytes!),
              child: avatarBytes == null
                  ? const Icon(Icons.person_outline, size: 36)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _profileTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onPickAvatar,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Đổi avatar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    final child = switch (state.status) {
      ProfileLoadStatus.initial || ProfileLoadStatus.loading => const Row(
        children: [
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Đang tải hồ sơ cá nhân...')),
        ],
      ),
      ProfileLoadStatus.empty => const Text(
        'Chưa có hồ sơ cá nhân. Hãy tạo hồ sơ trước.',
      ),
      ProfileLoadStatus.loaded => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile ID: ${state.profile!.id}'),
          const SizedBox(height: 6),
          Text('Trạng thái: ${state.profile!.status}'),
        ],
      ),
      ProfileLoadStatus.failure => Text(
        state.errorMessage ?? 'Không tải được hồ sơ.',
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile});

  final CustomerProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final rows = profile.type.fields
        .map((field) => _DetailRow(label: field.label, value: _value(field)))
        .toList(growable: false);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin hồ sơ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _profileTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  String _value(ProfileInputField field) {
    if (field.kind == ProfileFieldKind.image) {
      final objectIdKey = switch (field.key) {
        'citizenIdFrontImage' => 'citizenIdFrontObjectId',
        'citizenIdBackImage' => 'citizenIdBackObjectId',
        _ => field.key,
      };
      return profile.stringValue(objectIdKey);
    }

    return profile.stringValue(field.key);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _profileTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(value.isEmpty ? 'Chưa có' : value),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(
            color: isError
                ? colorScheme.onErrorContainer
                : colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
