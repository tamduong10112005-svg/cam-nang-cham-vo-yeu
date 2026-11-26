import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cam_nang_cham_vo_yeu/core/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('encrypts personal data and restores it after initialization', () async {
    final store = LocalStore();
    await store.initialize();
    await store.saveNickname('Mây');
    await store.saveCycle(DateTime(2026, 11, 10), 30);
    await store.saveEntry(const NoteEntry(
        id: '1', title: 'Phở', category: 'Món ăn', note: 'Ít hành'));
    await store.savePlanner(PlannerEntry(
        id: '2',
        kind: 'Kỷ niệm',
        title: 'Ngày cưới',
        date: DateTime(2027, 3, 1)));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('notes.v1'), startsWith('enc1:'));
    expect(prefs.getString('planner.v1'), startsWith('enc1:'));
    expect(prefs.getString('cycles.v1'), startsWith('enc1:'));
    expect(prefs.getString('cycle.start.v1'), isNull);

    final reopened = LocalStore();
    await reopened.initialize();
    expect(reopened.nickname, 'Mây');
    expect(reopened.cycleLength, 30);
    expect(reopened.notes.single.note, 'Ít hành');
    expect(reopened.planner.single.title, 'Ngày cưới');
    expect(reopened.cycles.single.start, DateTime(2026, 11, 10));
  });

  test('exports a backup and restores notes and planner records', () async {
    final store = LocalStore();
    await store.initialize();
    await store.saveEntry(
        const NoteEntry(id: 'n', title: 'Trà đào', category: 'Món ăn'));
    await store.savePlanner(
        const PlannerEntry(id: 'p', kind: 'Việc chăm sóc', title: 'Mua hoa'));
    await store.saveNotificationGroup('anniversary', true);
    await store.saveNotificationGroup('task', true);
    await store.saveReminderHour(9);
    final backup = await store.exportData();

    await store.clearAll();
    await store.initialize();
    await store.importData(backup);
    expect(store.notes.single.title, 'Trà đào');
    expect(store.planner.single.title, 'Mua hoa');
    expect(store.notificationEnabled('anniversary'), isTrue);
    expect(store.notificationEnabled('task'), isTrue);
    expect(store.reminderHour, 9);
  });
}
