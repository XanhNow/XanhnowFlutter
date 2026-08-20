import 'package:flutter/material.dart';

import 'app/xanhnow_flutter_app.dart';
import 'core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(XanhNowFlutterApp(config: AppConfig.fromEnvironment()));
}
