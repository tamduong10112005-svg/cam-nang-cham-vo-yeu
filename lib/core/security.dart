import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

final _pinKdf = Pbkdf2.hmacSha256(iterations: 120000, bits: 256);

Future<String> createPinHash(String pin) async {
  final random = Random.secure();
  final salt = List<int>.generate(16, (_) => random.nextInt(256));
  final key = await _pinKdf.deriveKeyFromPassword(password: pin, nonce: salt);
  final hash = await key.extractBytes();
  return '${base64Encode(salt)}:${base64Encode(hash)}';
}

Future<bool> verifyPin(String pin, String? stored) async {
  if (stored == null || !stored.contains(':')) return false;
  final parts = stored.split(':');
  try {
    final salt = base64Decode(parts.first);
    final expected = base64Decode(parts.last);
    final key = await _pinKdf.deriveKeyFromPassword(password: pin, nonce: salt);
    final actual = await key.extractBytes();
    if (actual.length != expected.length) return false;
    var difference = 0;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual[i] ^ expected[i];
    }
    return difference == 0;
  } on FormatException {
    return false;
  }
}
