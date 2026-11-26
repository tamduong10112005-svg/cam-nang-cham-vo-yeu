import 'package:material_ui/material_ui.dart';
import 'app.dart';
import 'core/local_store.dart';
import 'core/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LocalStore();
  await store.initialize();
  await NotificationService.instance.initialize();
  await NotificationService.instance.reschedule(store);
  runApp(LoveCareApp(store: store));
}
