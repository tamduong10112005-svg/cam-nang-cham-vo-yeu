import 'backup_share_io.dart'
    if (dart.library.js_interop) 'backup_share_web.dart' as platform;

Future<void> shareBackup(String name, List<int> bytes) =>
    platform.shareBackup(name, bytes);
