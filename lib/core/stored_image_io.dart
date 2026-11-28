import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveImage(List<int> bytes) async {
  final root = await getApplicationDocumentsDirectory();
  final dir =
      Directory('${root.path}${Platform.pathSeparator}love_care_photos');
  await dir.create(recursive: true);
  final file = File(
      '${dir.path}${Platform.pathSeparator}image_${DateTime.now().microsecondsSinceEpoch}.bin');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<void> deleteImage(String path) async {
  final root = await getApplicationDocumentsDirectory();
  final dir =
      Directory('${root.path}${Platform.pathSeparator}love_care_photos');
  if (!path.startsWith('${dir.path}${Platform.pathSeparator}')) return;
  final file = File(path);
  if (await file.exists()) await file.delete();
}

Future<List<int>?> readImage(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

bool imageExists(String path) => File(path).existsSync();

Widget imageWidget(String path,
        {double? width, double? height, BoxFit fit = BoxFit.cover}) =>
    Image.file(File(path), width: width, height: height, fit: fit);
