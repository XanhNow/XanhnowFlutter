import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/profile_models.dart';
import '../../domain/profile_repository.dart';

enum ProfileLoadStatus { initial, loading, loaded, empty, failure }

enum ProfileActionStatus { idle, saving, submitting, deleting, uploading }

class ProfileState extends Equatable {
  const ProfileState({
    required this.status,
    required this.selectedType,
    this.actionStatus = ProfileActionStatus.idle,
    this.profile,
    this.errorMessage,
    this.uploadingFieldKey,
  });

  const ProfileState.initial()
    : this(
        status: ProfileLoadStatus.initial,
        selectedType: CustomerProfileType.individualDemandOnly,
      );

  final ProfileLoadStatus status;
  final CustomerProfileType selectedType;
  final ProfileActionStatus actionStatus;
  final CustomerProfileSummary? profile;
  final String? errorMessage;
  final String? uploadingFieldKey;

  ProfileState copyWith({
    ProfileLoadStatus? status,
    CustomerProfileType? selectedType,
    ProfileActionStatus? actionStatus,
    CustomerProfileSummary? profile,
    String? errorMessage,
    String? uploadingFieldKey,
    bool clearProfile = false,
    bool clearError = false,
    bool clearUploadingField = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      selectedType: selectedType ?? this.selectedType,
      actionStatus: actionStatus ?? this.actionStatus,
      profile: clearProfile ? null : profile ?? this.profile,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      uploadingFieldKey: clearUploadingField
          ? null
          : uploadingFieldKey ?? this.uploadingFieldKey,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedType,
    actionStatus,
    profile,
    errorMessage,
    uploadingFieldKey,
  ];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required ProfileRepository repository})
    : _repository = repository,
      super(const ProfileState.initial());

  final ProfileRepository _repository;

  Future<void> load(CustomerProfileType type) async {
    emit(
      state.copyWith(
        status: ProfileLoadStatus.loading,
        selectedType: type,
        clearProfile: true,
        clearError: true,
      ),
    );

    try {
      final profile = await _repository.getCurrentProfile(type);
      emit(
        state.copyWith(
          status: profile == null
              ? ProfileLoadStatus.empty
              : ProfileLoadStatus.loaded,
          profile: profile,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileLoadStatus.failure,
          errorMessage: error.toString(),
          clearProfile: true,
        ),
      );
    }
  }

  Future<void> save(Map<String, dynamic> body) async {
    final type = state.selectedType;
    final hasProfile = state.profile != null;
    emit(
      state.copyWith(
        actionStatus: ProfileActionStatus.saving,
        clearError: true,
      ),
    );

    try {
      if (hasProfile) {
        await _repository.updateCurrentProfile(type, body);
      } else {
        await _repository.createProfile(type, body);
      }
      emit(state.copyWith(actionStatus: ProfileActionStatus.idle));
      await load(type);
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileLoadStatus.failure,
          actionStatus: ProfileActionStatus.idle,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> saveIndividualDemandOnly(
    Map<String, dynamic> body,
    List<ProfileImageFile> files,
  ) async {
    final type = CustomerProfileType.individualDemandOnly;
    final hasProfile = state.profile != null;
    emit(
      state.copyWith(
        actionStatus: ProfileActionStatus.saving,
        clearError: true,
      ),
    );

    try {
      if (hasProfile) {
        await _repository.updateCurrentIndividualDemandOnlyProfile(body, files);
      } else {
        await _repository.createIndividualDemandOnlyProfile(body, files);
      }
      emit(state.copyWith(actionStatus: ProfileActionStatus.idle));
      await load(type);
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileLoadStatus.failure,
          actionStatus: ProfileActionStatus.idle,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> submit() async {
    final type = state.selectedType;
    emit(
      state.copyWith(
        actionStatus: ProfileActionStatus.submitting,
        clearError: true,
      ),
    );

    try {
      await _repository.submitCurrentProfile(type);
      emit(state.copyWith(actionStatus: ProfileActionStatus.idle));
      await load(type);
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileLoadStatus.failure,
          actionStatus: ProfileActionStatus.idle,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> deleteDraft() async {
    final type = state.selectedType;
    emit(
      state.copyWith(
        actionStatus: ProfileActionStatus.deleting,
        clearError: true,
      ),
    );

    try {
      await _repository.deleteCurrentDraft(type);
      emit(state.copyWith(actionStatus: ProfileActionStatus.idle));
      await load(type);
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileLoadStatus.failure,
          actionStatus: ProfileActionStatus.idle,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<String?> uploadImage({
    required String fieldKey,
    required Uint8List bytes,
    required String fileName,
  }) async {
    emit(
      state.copyWith(
        actionStatus: ProfileActionStatus.uploading,
        uploadingFieldKey: fieldKey,
        clearError: true,
      ),
    );

    try {
      final objectId = await _repository.uploadImage(
        bytes: bytes,
        fileName: fileName,
      );
      emit(
        state.copyWith(
          actionStatus: ProfileActionStatus.idle,
          clearUploadingField: true,
        ),
      );
      return objectId;
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileLoadStatus.failure,
          actionStatus: ProfileActionStatus.idle,
          errorMessage: error.toString(),
          clearUploadingField: true,
        ),
      );
      return null;
    }
  }
}
