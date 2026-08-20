import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/profile_models.dart';
import '../../domain/profile_repository.dart';
import '../bloc/profile_cubit.dart';

const _profileTextColor = Color(0xFF0B2F4A);

class ProfileModulePage extends StatelessWidget {
  const ProfileModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileCubit(repository: context.read<ProfileRepository>())
            ..load(CustomerProfileType.individualDemandOnly),
      child: const _ProfileModuleView(),
    );
  }
}

class _ProfileModuleView extends StatefulWidget {
  const _ProfileModuleView();

  @override
  State<_ProfileModuleView> createState() => _ProfileModuleViewState();
}

class _ProfileModuleViewState extends State<_ProfileModuleView> {
  final _controllers = <String, TextEditingController>{};
  final _imagePicker = ImagePicker();
  CustomerProfileType? _syncedType;
  String? _syncedProfileId;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          previous.selectedType != current.selectedType ||
          previous.profile?.id != current.profile?.id ||
          previous.status != current.status,
      listener: (_, state) => _syncControllers(state),
      builder: (context, state) {
        _syncControllers(state);
        final isBusy =
            state.actionStatus != ProfileActionStatus.idle ||
            state.status == ProfileLoadStatus.loading;

        return DefaultTextStyle.merge(
          style: const TextStyle(color: _profileTextColor),
          child: Scaffold(
            appBar: AppBar(
              foregroundColor: _profileTextColor,
              title: const Text('Profile Module'),
            ),
            body: SafeArea(
              child: Form(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Hồ sơ Customer',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: _profileTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Module này gọi đúng contract Customer backend: create, get current, update current, submit và delete draft.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _profileTextColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<CustomerProfileType>(
                      initialValue: state.selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Loại hồ sơ',
                        prefixIcon: Icon(Icons.assignment_ind_outlined),
                      ),
                      items: CustomerProfileType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.title),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: isBusy
                          ? null
                          : (type) {
                              if (type != null) {
                                context.read<ProfileCubit>().load(type);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    _ProfileStatusPanel(state: state),
                    const SizedBox(height: 16),
                    ...state.selectedType.fields.map(
                      (field) => _buildField(context, state, field),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: isBusy
                          ? null
                          : () {
                              context.read<ProfileCubit>().save(
                                state.selectedType.buildRequest(_formValues()),
                              );
                            },
                      icon:
                          isBusy &&
                              state.actionStatus == ProfileActionStatus.saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        state.profile == null ? 'Tạo hồ sơ' : 'Cập nhật hồ sơ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isBusy || state.profile == null
                          ? null
                          : () => context.read<ProfileCubit>().submit(),
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Submit hồ sơ hiện tại'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isBusy || state.profile == null
                          ? null
                          : () => context.read<ProfileCubit>().deleteDraft(),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa draft hiện tại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(
    BuildContext context,
    ProfileState state,
    ProfileInputField field,
  ) {
    final controller = _controllerFor(field.key);
    final isUploading =
        state.actionStatus == ProfileActionStatus.uploading &&
        state.uploadingFieldKey == field.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: switch (field.kind) {
          ProfileFieldKind.number => TextInputType.number,
          ProfileFieldKind.multiline => TextInputType.multiline,
          _ => TextInputType.text,
        },
        minLines: field.kind == ProfileFieldKind.multiline ? 3 : 1,
        maxLines: field.kind == ProfileFieldKind.multiline ? 6 : 1,
        decoration: InputDecoration(
          labelText: field.label,
          helperText: switch (field.kind) {
            ProfileFieldKind.guid => 'Upload ảnh lên MinIO để lấy objectId',
            ProfileFieldKind.date => 'Backend nhận DateOnly dạng yyyy-mm-dd',
            _ => null,
          },
          suffixIcon: field.kind == ProfileFieldKind.guid
              ? IconButton(
                  tooltip: 'Upload ảnh',
                  onPressed: isUploading
                      ? null
                      : () => _pickAndUpload(context, field),
                  icon: isUploading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    ProfileInputField field,
  ) async {
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
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) {
      return;
    }

    final objectId = await context.read<ProfileCubit>().uploadImage(
      fieldKey: field.key,
      bytes: await picked.readAsBytes(),
      fileName: picked.name,
    );
    if (!context.mounted || objectId == null || objectId.isEmpty) {
      return;
    }

    _controllerFor(field.key).text = objectId;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã upload ${field.label}')));
  }

  TextEditingController _controllerFor(String key) {
    return _controllers.putIfAbsent(key, TextEditingController.new);
  }

  Map<String, String> _formValues() {
    return {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };
  }

  void _syncControllers(ProfileState state) {
    final profileId = state.profile?.id;
    if (_syncedType == state.selectedType && _syncedProfileId == profileId) {
      return;
    }

    _syncedType = state.selectedType;
    _syncedProfileId = profileId;

    for (final field in state.selectedType.fields) {
      _controllerFor(field.key).text =
          state.profile?.stringValue(field.key) ?? '';
    }
  }
}

class _ProfileStatusPanel extends StatelessWidget {
  const _ProfileStatusPanel({required this.state});

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
          Expanded(child: Text('Đang kiểm tra hồ sơ hiện tại...')),
        ],
      ),
      ProfileLoadStatus.empty => Text(
        'Chưa có hồ sơ ${state.selectedType.title}. Nhập form và bấm Tạo hồ sơ.',
      ),
      ProfileLoadStatus.loaded => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loại hồ sơ: ${state.profile!.type.title}'),
          const SizedBox(height: 6),
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
