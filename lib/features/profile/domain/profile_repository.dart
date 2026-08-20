import 'dart:typed_data';

import '../data/customer_profile_api.dart';
import '../data/models/profile_models.dart';
import '../data/object_storage_api.dart';

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

  Future<void> updateCurrentProfile(
    CustomerProfileType type,
    Map<String, dynamic> body,
  ) {
    return _api.updateCurrentProfile(type, body);
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
