import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/utils/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('verify succeeds for the same password and salt', () {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hash('s3cret-Pass', salt);
      expect(PasswordHasher.verify('s3cret-Pass', salt, hash), isTrue);
    });

    test('verify fails for a wrong password', () {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hash('s3cret-Pass', salt);
      expect(PasswordHasher.verify('wrong-pass', salt, hash), isFalse);
    });

    test('same password with different salts produces different hashes', () {
      final saltA = PasswordHasher.generateSalt();
      final saltB = PasswordHasher.generateSalt();
      expect(saltA, isNot(equals(saltB)));
      expect(
        PasswordHasher.hash('s3cret-Pass', saltA),
        isNot(equals(PasswordHasher.hash('s3cret-Pass', saltB))),
      );
    });

    test('generateSalt returns requested entropy length', () {
      // 16 bytes -> base64url without padding stripping: 24 chars.
      expect(PasswordHasher.generateSalt().length, greaterThanOrEqualTo(22));
    });
  });
}
