import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> shareBackup(String name, List<int> bytes) async {
  await SharePlus.instance.share(ShareParams(
      files: [
        XFile.fromData(Uint8List.fromList(bytes),
            mimeType: 'application/json', name: name)
      ],
      subject: 'Bản sao lưu Cẩm nang chăm vợ yêu',
      text: 'Tệp có dữ liệu cá nhân. Hãy lưu ở nơi riêng tư.'));
}
