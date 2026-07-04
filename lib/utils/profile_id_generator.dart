import 'dart:math';

/// Generates a display-friendly unique profile ID.
/// Format: 2 digits + 3 uppercase letters + 2 digits (e.g., "09RTW44").
/// Total length is 7 characters.
String generateProfileId() {
  final rand = Random();
  const digits = '0123456789';
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final buffer = StringBuffer();
  buffer.write(digits[rand.nextInt(digits.length)]);
  buffer.write(digits[rand.nextInt(digits.length)]);
  buffer.write(letters[rand.nextInt(letters.length)]);
  buffer.write(letters[rand.nextInt(letters.length)]);
  buffer.write(letters[rand.nextInt(letters.length)]);
  buffer.write(digits[rand.nextInt(digits.length)]);
  buffer.write(digits[rand.nextInt(digits.length)]);

  return buffer.toString();
}
