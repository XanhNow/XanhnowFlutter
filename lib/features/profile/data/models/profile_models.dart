enum CustomerProfileType {
  individualDemandOnly,
  organizationDemandOnly,
  organizationDemandSupply,
  organizationDriver,
  individualDemandSupply,
  operator,
}

enum ProfileFieldKind { text, number, date, guid, image, multiline }

class ProfileInputField {
  const ProfileInputField({
    required this.key,
    required this.label,
    this.kind = ProfileFieldKind.text,
    this.required = true,
    this.fileFieldName,
  });

  final String key;
  final String label;
  final ProfileFieldKind kind;
  final bool required;
  final String? fileFieldName;
}

extension CustomerProfileTypeContract on CustomerProfileType {
  String get title {
    return switch (this) {
      CustomerProfileType.individualDemandOnly => 'Cá nhân chỉ giao việc',
      CustomerProfileType.organizationDemandOnly => 'Tổ chức chỉ giao việc',
      CustomerProfileType.organizationDemandSupply =>
        'Tổ chức giao và nhận việc',
      CustomerProfileType.organizationDriver => 'Lái xe thuộc tổ chức',
      CustomerProfileType.individualDemandSupply => 'Cá nhân giao và nhận việc',
      CustomerProfileType.operator => 'Nhân viên điều hành',
    };
  }

  String get basePath {
    return switch (this) {
      CustomerProfileType.individualDemandOnly =>
        '/api/customer/profiles/individual-demand-only',
      CustomerProfileType.organizationDemandOnly =>
        '/api/customer/profiles/organization-demand-only',
      CustomerProfileType.organizationDemandSupply =>
        '/api/customer/profiles/organization-demand-supply',
      CustomerProfileType.organizationDriver =>
        '/api/customer/profiles/organization-driver',
      CustomerProfileType.individualDemandSupply =>
        '/api/customer/profiles/individual-demand-supply',
      CustomerProfileType.operator => '/api/customer/profiles/operator',
    };
  }

  String get currentPath => '$basePath/current';

  List<ProfileInputField> get fields {
    return switch (this) {
      CustomerProfileType.individualDemandOnly => _individualDemandOnlyFields,
      CustomerProfileType.organizationDemandOnly =>
        _organizationDemandOnlyFields,
      CustomerProfileType.organizationDemandSupply =>
        _organizationDemandSupplyFields,
      CustomerProfileType.organizationDriver => _organizationDriverFields,
      CustomerProfileType.individualDemandSupply =>
        _individualDemandSupplyFields,
      CustomerProfileType.operator => _operatorFields,
    };
  }

  Map<String, dynamic> buildRequest(Map<String, String> values) {
    final body = <String, dynamic>{};
    for (final field in fields) {
      if (field.key.startsWith('historicalOperatingAddress.') ||
          field.key.startsWith('currentOperatingAddress.') ||
          field.key == 'spokenLanguages' ||
          field.key == 'declaredDrivers' ||
          field.key == 'vehiclePlateNumbers' ||
          field.kind == ProfileFieldKind.image) {
        continue;
      }
      body[field.key] = _valueFor(field, values[field.key] ?? '');
    }

    if (_hasField('vehiclePlateNumbers')) {
      body['vehiclePlateNumbers'] = _lines(values['vehiclePlateNumbers']);
    }
    if (_hasField('declaredDrivers')) {
      body['declaredDrivers'] = _declaredDrivers(values['declaredDrivers']);
    }
    if (_hasField('spokenLanguages')) {
      body['spokenLanguages'] = _spokenLanguages(values['spokenLanguages']);
    }
    if (_hasHistoricalAddress) {
      body['historicalOperatingAddress'] = _address(
        values,
        'historicalOperatingAddress',
        includeDistrict: true,
      );
    }
    if (_hasCurrentAddress) {
      body['currentOperatingAddress'] = _address(
        values,
        'currentOperatingAddress',
        includeDistrict: false,
      );
    }

    return body;
  }

  bool _hasField(String key) => fields.any((field) => field.key == key);
  bool get _hasHistoricalAddress => fields.any(
    (field) => field.key.startsWith('historicalOperatingAddress.'),
  );
  bool get _hasCurrentAddress =>
      fields.any((field) => field.key.startsWith('currentOperatingAddress.'));
}

class CustomerProfileSummary {
  const CustomerProfileSummary({
    required this.type,
    required this.id,
    required this.status,
    required this.raw,
  });

  factory CustomerProfileSummary.fromJson(
    CustomerProfileType type,
    Object? json,
  ) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    return CustomerProfileSummary(
      type: type,
      id: map['id'] as String? ?? '',
      status: map['status'] as String? ?? 'Unknown',
      raw: map,
    );
  }

  final CustomerProfileType type;
  final String id;
  final String status;
  final Map<String, dynamic> raw;

  String stringValue(String key) {
    final value = _readPath(raw, key);
    if (value is List) {
      return value.map(_lineValue).join('\n');
    }
    return value?.toString() ?? '';
  }
}

const _individualDemandOnlyFields = [
  ProfileInputField(key: 'fullName', label: 'Họ và tên'),
  ProfileInputField(key: 'email', label: 'Email'),
  ProfileInputField(key: 'citizenIdNumber', label: 'Số CCCD'),
  ProfileInputField(
    key: 'citizenIdFrontImage',
    label: 'Ảnh CCCD mặt trước',
    kind: ProfileFieldKind.image,
    fileFieldName: 'CitizenIdFrontImage',
  ),
  ProfileInputField(
    key: 'citizenIdBackImage',
    label: 'Ảnh CCCD mặt sau',
    kind: ProfileFieldKind.image,
    fileFieldName: 'CitizenIdBackImage',
  ),
];

const _identityFieldsWithOptionalEmail = [
  ProfileInputField(key: 'fullName', label: 'Họ và tên'),
  ProfileInputField(key: 'email', label: 'Email', required: false),
  ProfileInputField(key: 'citizenIdNumber', label: 'Số CCCD'),
  ProfileInputField(
    key: 'citizenIdFrontObjectId',
    label: 'ObjectId ảnh CCCD mặt trước',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'citizenIdBackObjectId',
    label: 'ObjectId ảnh CCCD mặt sau',
    kind: ProfileFieldKind.guid,
  ),
];

const _representativeFields = [
  ProfileInputField(key: 'representativeFullName', label: 'Họ tên đại diện'),
  ProfileInputField(key: 'representativeEmail', label: 'Email đại diện'),
  ProfileInputField(
    key: 'representativeCitizenIdNumber',
    label: 'Số CCCD đại diện',
  ),
  ProfileInputField(key: 'businessLicenseCode', label: 'Mã giấy phép KD'),
  ProfileInputField(
    key: 'citizenIdFrontObjectId',
    label: 'ObjectId CCCD đại diện mặt trước',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'citizenIdBackObjectId',
    label: 'ObjectId CCCD đại diện mặt sau',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'businessLicenseObjectId',
    label: 'ObjectId giấy phép kinh doanh',
    kind: ProfileFieldKind.guid,
  ),
];

const _vehicleFields = [
  ProfileInputField(key: 'vehicleType', label: 'Loại xe'),
  ProfileInputField(
    key: 'seatCount',
    label: 'Số chỗ ngồi',
    kind: ProfileFieldKind.number,
  ),
  ProfileInputField(
    key: 'manufactureYear',
    label: 'Năm sản xuất',
    kind: ProfileFieldKind.number,
  ),
  ProfileInputField(key: 'color', label: 'Màu xe'),
  ProfileInputField(
    key: 'inspectionExpiryDate',
    label: 'Ngày hết hạn đăng kiểm (yyyy-mm-dd)',
    kind: ProfileFieldKind.date,
  ),
  ProfileInputField(key: 'licensePlate', label: 'Biển số xe'),
];

const _vehicleFileFields = [
  ProfileInputField(
    key: 'vehicleFrontObjectId',
    label: 'ObjectId ảnh xe phía trước',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'vehicleBackObjectId',
    label: 'ObjectId ảnh xe phía sau',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'vehicleLeftSideObjectId',
    label: 'ObjectId ảnh xe bên trái',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'vehicleRightSideObjectId',
    label: 'ObjectId ảnh xe bên phải',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'vehicleRegistrationFrontObjectId',
    label: 'ObjectId đăng ký xe mặt trước',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'vehicleRegistrationBackObjectId',
    label: 'ObjectId đăng ký xe mặt sau',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'vehicleInspectionObjectId',
    label: 'ObjectId đăng kiểm xe',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'driverLicenseFrontObjectId',
    label: 'ObjectId GPLX mặt trước',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'driverLicenseBackObjectId',
    label: 'ObjectId GPLX mặt sau',
    kind: ProfileFieldKind.guid,
  ),
];

const _addressFields = [
  ProfileInputField(
    key: 'historicalOperatingAddress.provinceCode',
    label: 'Tỉnh/thành cũ - mã',
  ),
  ProfileInputField(
    key: 'historicalOperatingAddress.provinceName',
    label: 'Tỉnh/thành cũ - tên',
  ),
  ProfileInputField(
    key: 'historicalOperatingAddress.districtCode',
    label: 'Quận/huyện cũ - mã',
  ),
  ProfileInputField(
    key: 'historicalOperatingAddress.districtName',
    label: 'Quận/huyện cũ - tên',
  ),
  ProfileInputField(
    key: 'historicalOperatingAddress.communeCode',
    label: 'Phường/xã cũ - mã',
  ),
  ProfileInputField(
    key: 'historicalOperatingAddress.communeName',
    label: 'Phường/xã cũ - tên',
  ),
  ProfileInputField(
    key: 'historicalOperatingAddress.localArea',
    label: 'Khu vực hoạt động cũ',
  ),
  ProfileInputField(
    key: 'historicalOperatingAddress.houseNumber',
    label: 'Số nhà/đường cũ',
  ),
  ProfileInputField(
    key: 'historicalOperatingAddress.additionalDetail',
    label: 'Chi tiết địa chỉ cũ',
  ),
  ProfileInputField(
    key: 'currentOperatingAddress.provinceCode',
    label: 'Tỉnh/thành hiện hành - mã',
  ),
  ProfileInputField(
    key: 'currentOperatingAddress.provinceName',
    label: 'Tỉnh/thành hiện hành - tên',
  ),
  ProfileInputField(
    key: 'currentOperatingAddress.communeCode',
    label: 'Phường/xã hiện hành - mã',
  ),
  ProfileInputField(
    key: 'currentOperatingAddress.communeName',
    label: 'Phường/xã hiện hành - tên',
  ),
  ProfileInputField(
    key: 'currentOperatingAddress.localArea',
    label: 'Khu vực hoạt động hiện hành',
  ),
  ProfileInputField(
    key: 'currentOperatingAddress.houseNumber',
    label: 'Số nhà/đường hiện hành',
  ),
  ProfileInputField(
    key: 'currentOperatingAddress.additionalDetail',
    label: 'Chi tiết địa chỉ hiện hành',
  ),
  ProfileInputField(
    key: 'spokenLanguages',
    label: 'Ngoại ngữ, mỗi dòng: code|tên tùy chỉnh',
    kind: ProfileFieldKind.multiline,
  ),
];

const _operatorFields = [
  ProfileInputField(key: 'fullName', label: 'Họ và tên'),
  ProfileInputField(key: 'complaintHotline', label: 'Hotline khiếu nại'),
  ProfileInputField(key: 'citizenIdNumber', label: 'Số CCCD'),
  ProfileInputField(key: 'email', label: 'Email'),
  ProfileInputField(
    key: 'citizenIdFrontObjectId',
    label: 'ObjectId ảnh CCCD mặt trước',
    kind: ProfileFieldKind.guid,
  ),
  ProfileInputField(
    key: 'citizenIdBackObjectId',
    label: 'ObjectId ảnh CCCD mặt sau',
    kind: ProfileFieldKind.guid,
  ),
];

const _organizationDemandOnlyFields = _representativeFields;

const _organizationDemandSupplyFields = [
  ..._representativeFields,
  ProfileInputField(
    key: 'vehiclePlateNumbers',
    label: 'Danh sách biển số, mỗi dòng một biển số',
    kind: ProfileFieldKind.multiline,
  ),
  ProfileInputField(
    key: 'declaredDrivers',
    label: 'Lái xe khai trước, mỗi dòng: họ tên|số điện thoại',
    kind: ProfileFieldKind.multiline,
  ),
];

const _individualDemandSupplyFields = [
  ..._identityFieldsWithOptionalEmail,
  ..._vehicleFields,
  ..._addressFields,
  ..._vehicleFileFields,
];

const _organizationDriverFields = [
  ..._identityFieldsWithOptionalEmail,
  ..._vehicleFields,
  ProfileInputField(key: 'companyName', label: 'Tên công ty/nhà xe'),
  ProfileInputField(key: 'companyPhoneNumber', label: 'SĐT công ty/nhà xe'),
  ..._addressFields,
  ..._vehicleFileFields,
];

dynamic _valueFor(ProfileInputField field, String raw) {
  final value = raw.trim();
  if (value.isEmpty && !field.required) {
    return null;
  }

  return switch (field.kind) {
    ProfileFieldKind.number => int.tryParse(value) ?? 0,
    _ => value,
  };
}

List<String> _lines(String? raw) {
  return (raw ?? '')
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, String>> _declaredDrivers(String? raw) {
  return _lines(raw)
      .map((line) {
        final parts = line.split('|').map((part) => part.trim()).toList();
        return {
          'fullName': parts.isNotEmpty ? parts[0] : '',
          'phoneNumber': parts.length > 1 ? parts[1] : '',
        };
      })
      .toList(growable: false);
}

List<Map<String, String?>> _spokenLanguages(String? raw) {
  return _lines(raw)
      .map((line) {
        final parts = line.split('|').map((part) => part.trim()).toList();
        return {
          'code': parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null,
          'customName': parts.length > 1 && parts[1].isNotEmpty
              ? parts[1]
              : null,
        };
      })
      .toList(growable: false);
}

Map<String, String?> _address(
  Map<String, String> values,
  String prefix, {
  required bool includeDistrict,
}) {
  String? read(String key) {
    final value = values['$prefix.$key']?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  return {
    'provinceCode': read('provinceCode'),
    'provinceName': read('provinceName'),
    if (includeDistrict) 'districtCode': read('districtCode'),
    if (includeDistrict) 'districtName': read('districtName'),
    'communeCode': read('communeCode'),
    'communeName': read('communeName'),
    'localArea': read('localArea'),
    'houseNumber': read('houseNumber'),
    'additionalDetail': read('additionalDetail'),
  };
}

Object? _readPath(Map<String, dynamic> map, String path) {
  Object? current = map;
  for (final part in path.split('.')) {
    if (current is! Map<String, dynamic>) {
      return null;
    }
    current = current[part];
  }
  return current;
}

String _lineValue(Object? value) {
  if (value is Map<String, dynamic>) {
    if (value.containsKey('phoneNumber')) {
      return '${value['fullName'] ?? ''}|${value['phoneNumber'] ?? ''}';
    }
    return '${value['code'] ?? ''}|${value['customName'] ?? ''}';
  }
  return value?.toString() ?? '';
}
