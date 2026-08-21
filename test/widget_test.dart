import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xanhnow_flutter/app/xanhnow_flutter_app.dart';
import 'package:xanhnow_flutter/core/config/app_config.dart';

void main() {
  testWidgets('XanhNow Flutter app starts while restoring session', (
    tester,
  ) async {
    await tester.pumpWidget(
      const XanhNowFlutterApp(
        config: AppConfig(
          securityBaseUrl: 'https://api.ioxy.site/security',
          customerBaseUrl: 'https://api.ioxy.site/customer',
          objectStorageBaseUrl: 'https://api.ioxy.site/object-storage',
          adminBaseUrl: 'https://api.ioxy.site/admin',
          contractVersion: 'v1',
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
