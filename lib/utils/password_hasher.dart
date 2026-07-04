import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 password hashing for local accounts.
///
/// Good enough for an offline single-player game; must be replaced with a
/// server-side KDF (Argon2/bcrypt) if online accounts ever appear.
class PasswordHasher {
  const PasswordHasher._();

  static String generateSalt([int byteLength = 16]) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hash(String raw, String salt) =>
      sha256.convert(utf8.encode('$salt$raw')).toString();

  static bool verify(String raw, String salt, String expectedHash) =>
      hash(raw, salt) == expectedHash;
}
