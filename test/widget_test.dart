import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cam_nang_cham_vo_yeu/app.dart';
import 'package:cam_nang_cham_vo_yeu/core/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('shows the Vietnamese five-tab home shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final store = LocalStore();
    await store.initialize();
    await tester.pumpWidget(LoveCareApp(store: store));
    final navigationBar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigationBar.destinations, hasLength(5));
    expect(find.text('Hôm nay yêu nàng nhé'), findsOneWidget);
  });
}
