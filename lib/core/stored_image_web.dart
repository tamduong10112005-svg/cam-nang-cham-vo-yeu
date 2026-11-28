import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

String _dataUrl(List<int> bytes) {
  final data = Uint8List.fromList(bytes);
  var mime = 'image/jpeg';
  if (data.length >= 8 &&
      data[0] == 0x89 &&
      data[1] == 0x50 &&
      data[2] == 0x4e &&
      data[3] == 0x47) {
    mime = 'image/png';
  } else if (data.length >= 12 &&
      String.fromCharCodes(data.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(data.sublist(8, 12)) == 'WEBP') {
    mime = 'image/webp';
  } else if (data.length >= 3 &&
      data[0] == 0xff &&
      data[1] == 0xd8 &&
      data[2] == 0xff) {
    mime = 'image/jpeg';
  }
  return 'data:$mime;base64,${base64Encode(data)}';
}

Future<String> saveImage(List<int> bytes) async => _dataUrl(bytes);

Future<void> deleteImage(String path) async {}

Future<List<int>?> readImage(String path) async {
  if (!path.startsWith('data:image/')) return null;
  final comma = path.indexOf(',');
  if (comma < 0) return null;
  try {
    return base64Decode(path.substring(comma + 1));
  } on FormatException {
    return null;
  }
}

bool imageExists(String path) => path.startsWith('data:image/');

Widget imageWidget(String path,
        {double? width, double? height, BoxFit fit = BoxFit.cover}) =>
    Image.memory(Uint8List.fromList(base64Decode(path.split(',').last)),
        width: width, height: height, fit: fit);
