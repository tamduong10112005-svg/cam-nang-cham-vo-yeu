import 'package:material_ui/material_ui.dart';

import 'stored_image_io.dart'
    if (dart.library.js_interop) 'stored_image_web.dart' as platform;

Future<String> saveStoredImage(List<int> bytes) => platform.saveImage(bytes);

Future<void> deleteStoredImage(String path) => platform.deleteImage(path);

Future<List<int>?> readStoredImage(String path) => platform.readImage(path);

bool storedImageExists(String path) => platform.imageExists(path);

Widget storedImageWidget(String path,
        {double? width, double? height, BoxFit fit = BoxFit.cover}) =>
    platform.imageWidget(path, width: width, height: height, fit: fit);
