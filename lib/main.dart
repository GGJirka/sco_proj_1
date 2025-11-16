import 'package:flutter/material.dart';

import 'app.dart';
import 'services/service_locator.dart';

const String _buildFlavor = String.fromEnvironment(
  'BUILD_FLAVOR',
  defaultValue: 'baseline',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isHardened = _buildFlavor == 'hardened';
  await setupLocator(hardened: isHardened);
  runApp(MyApp(buildFlavor: _buildFlavor, isHardened: isHardened));
}
