import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../data/customer_profile_api.dart';
import '../data/models/profile_models.dart';
import '../data/object_storage_api.dart';

class ProfileImageFile {
  const ProfileImageFile({
    required this.fieldName,
    required this.bytes,
    required this.fileName,
  });

  final String fieldName;
  final Uint8List bytes;
  final String fileName;

  MultipartFilePayload toMultipartFile() {
    return MultipartFilePayload(
      fieldName: fieldName,
      bytes: bytes,
      fileName: fileName,
    );
  }
}

class ProfileRepository {
  const ProfileRepository({
    required CustomerProfileApi api,
    required ObjectStorageApi objectStorageApi,
  }) : _api = api,
       _objectStorageApi = objectStorageApi;

  final CustomerProfileApi _api;
  final ObjectStorageApi _objectStorageApi;

  Future<CustomerProfileSummary?> getCurrentProfile(CustomerProfileType type) {
    return _api.getCurrentProfile(type);
  }

  Future<String> createProfile(
    CustomerProfileType type,
    Map<String, dynamic> body,
  ) {
    return _api.createProfile(type, body);
  }

  Future<String> createIndividualDemandOnlyProfile(
    Map<String, dynamic> body,
    List<ProfileImageFile> files,
  ) {
    return _api.createIndividualDemandOnlyProfile(
      body,
      files.map((file) => file.toMultipartFile()).toList(growable: false),
    );
  }

  Future<void> updateCurrentProfile(
    CustomerProfileType type,
    Map<String, dynamic> body,
  ) {
    return _api.updateCurrentProfile(type, body);
  }

  Future<void> updateCurrentIndividualDemandOnlyProfile(
    Map<String, dynamic> body,
    List<ProfileImageFile> files,
  ) {
    return _api.updateCurrentIndividualDemandOnlyProfile(
      body,
      files.map((file) => file.toMultipartFile()).toList(growable: false),
    );
  }

  Future<void> submitCurrentProfile(CustomerProfileType type) {
    return _api.submitCurrentProfile(type);
  }

  Future<void> deleteCurrentDraft(CustomerProfileType type) {
    return _api.deleteCurrentDraft(type);
  }

  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _objectStorageApi.uploadImage(bytes: bytes, fileName: fileName);
  }
}
