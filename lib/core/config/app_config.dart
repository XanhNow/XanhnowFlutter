class AppConfig {
  const AppConfig({
    required this.securityBaseUrl,
    required this.customerBaseUrl,
    required this.objectStorageBaseUrl,
    required this.adminBaseUrl,
    required this.contractVersion,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      securityBaseUrl: String.fromEnvironment(
        'XANHNOW_SECURITY_BASE_URL',
        defaultValue: 'https://api.ioxy.site/security',
      ),
      customerBaseUrl: String.fromEnvironment(
        'XANHNOW_CUSTOMER_BASE_URL',
        defaultValue: 'https://api.ioxy.site/customer',
      ),
      objectStorageBaseUrl: String.fromEnvironment(
        'XANHNOW_OBJECT_STORAGE_BASE_URL',
        defaultValue: 'https://api.ioxy.site/object-storage',
      ),
      adminBaseUrl: String.fromEnvironment(
        'XANHNOW_ADMIN_BASE_URL',
        defaultValue: 'https://api.ioxy.site/admin',
      ),
      contractVersion: String.fromEnvironment(
        'XANHNOW_CONTRACT_VERSION',
        defaultValue: 'v1',
      ),
    );
  }

  final String securityBaseUrl;
  final String customerBaseUrl;
  final String objectStorageBaseUrl;
  final String adminBaseUrl;
  final String contractVersion;
}
