import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class EncryptionHelper {
  // Generate a key from the user's UID
  static String _getKey() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '0' * 32;
    return user.uid.padRight(32, '0').substring(0, 32);
  }

  // Simple XOR-based encryption (suitable for basic obfuscation)
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';

    final key = _getKey();
    final bytes = utf8.encode(plainText);
    final keyBytes = utf8.encode(key);

    final encrypted = List<int>.generate(bytes.length, (i) {
      return bytes[i] ^ keyBytes[i % keyBytes.length];
    });

    return base64.encode(encrypted);
  }

  // Decrypt the encrypted text
  static String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    try {
      final key = _getKey();
      final encrypted = base64.decode(encryptedText);
      final keyBytes = utf8.encode(key);

      final decrypted = List<int>.generate(encrypted.length, (i) {
        return encrypted[i] ^ keyBytes[i % keyBytes.length];
      });

      return utf8.decode(decrypted);
    } catch (e) {
      // If decryption fails, return the original text
      return encryptedText;
    }
  }
}
