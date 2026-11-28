import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AppRelease {
  const AppRelease({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.releaseUrl,
  });

  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final String releaseUrl;
}

class AppUpdateService {
  AppUpdateService._();

  static const _channel = MethodChannel('vn.camnangchamvoyeu/app_update');
  static const _repository = String.fromEnvironment('UPDATE_REPOSITORY');
  static const _apkName = 'app-release.apk';
  static const _maxApkSize = 250 * 1024 * 1024;

  static bool get isConfigured =>
      RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(_repository);

  static Future<String> get currentVersion async =>
      await _channel.invokeMethod<String>('getVersionName') ?? '0.0.0';

  static Future<bool> ensureInstallPermission() async =>
      await _channel.invokeMethod<bool>('ensureInstallPermission') ?? false;

  static Future<AppRelease?> checkForUpdate() async {
    if (!isConfigured) {
      throw const FormatException(
          'Chưa cấu hình kho GitHub cho bản phát hành.');
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final uri = Uri.https(
        'api.github.com',
        '/repos/$_repository/releases/latest',
      );
      final request = await client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader, 'CamNangChamVoYeu-AppUpdater');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'GitHub trả về mã ${response.statusCode}. Kho phát hành có thể chưa công khai hoặc chưa có bản Release.',
          uri: uri,
        );
      }

      final payload = jsonDecode(await response.transform(utf8.decoder).join())
          as Map<String, dynamic>;
      final assets = payload['assets'] as List<dynamic>? ?? const [];
      final apk = assets.cast<Map<String, dynamic>?>().firstWhere(
            (asset) => asset?['name'] == _apkName,
            orElse: () => null,
          );
      if (apk == null) {
        throw const FormatException(
            'Bản GitHub Release mới nhất chưa có tệp APK chính thức.');
      }

      final tag = (payload['tag_name'] as String? ?? '').trim();
      final version = tag.startsWith('v') ? tag.substring(1) : tag;
      final downloadUrl = apk['browser_download_url'] as String? ?? '';
      final downloadUri = Uri.tryParse(downloadUrl);
      if (version.isEmpty ||
          downloadUri == null ||
          downloadUri.scheme != 'https' ||
          downloadUri.host != 'github.com') {
        throw const FormatException(
            'Thông tin bản cập nhật GitHub không hợp lệ.');
      }

      if (!_isNewer(version, await currentVersion)) return null;
      return AppRelease(
        version: version,
        downloadUrl: downloadUrl,
        releaseNotes: (payload['body'] as String? ?? '').trim(),
        releaseUrl: payload['html_url'] as String? ?? downloadUrl,
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<bool> downloadAndInstall(AppRelease release) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$_apkName');
    if (await file.exists()) await file.delete();

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30);
    try {
      final request = await client.getUrl(Uri.parse(release.downloadUrl));
      request.headers
          .set(HttpHeaders.userAgentHeader, 'CamNangChamVoYeu-AppUpdater');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Không tải được APK (mã ${response.statusCode}).');
      }
      final length = response.contentLength;
      if (length > _maxApkSize) {
        throw const FormatException('Tệp APK vượt quá giới hạn tải an toàn.');
      }

      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response) {
          received += chunk.length;
          if (received > _maxApkSize) {
            throw const FormatException(
                'Tệp APK vượt quá giới hạn tải an toàn.');
          }
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (received == 0 || (length >= 0 && received != length)) {
        throw const FormatException('Tệp APK tải xuống không đầy đủ.');
      }

      return await _channel.invokeMethod<bool>(
            'installApk',
            {'path': file.path},
          ) ??
          false;
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  static bool _isNewer(String candidate, String installed) {
    final candidateParts = _numericVersion(candidate);
    final installedParts = _numericVersion(installed);
    if (candidateParts == null || installedParts == null) {
      throw const FormatException('Số phiên bản phát hành không hợp lệ.');
    }
    for (var i = 0; i < 3; i++) {
      final comparison = candidateParts[i].compareTo(installedParts[i]);
      if (comparison != 0) return comparison > 0;
    }
    return false;
  }

  static List<int>? _numericVersion(String version) {
    final match =
        RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:[+-].*)?$').firstMatch(version);
    if (match == null) return null;
    return [
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    ];
  }
}

