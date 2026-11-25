import 'package:elements/app/app.dart';
import 'package:elements/services/save_service.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appSaveService.init();
  runApp(const ElementShiftApp());
}
