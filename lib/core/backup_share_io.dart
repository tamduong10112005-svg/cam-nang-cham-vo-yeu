import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareBackup(String name, List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
  await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: 'Bản sao lưu Cẩm nang chăm vợ yêu',
      text: 'Tệp có dữ liệu cá nhân. Hãy lưu ở nơi riêng tư.'));
}
