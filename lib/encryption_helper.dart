import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class EncryptionHelper {
  // Generate a key from the user's UID
  static String _getKey() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    // Use the first 32 characters of the UID as a key
    // Pad with zeros if needed to ensure consistent length
    return userId.padRight(32, '0').substring(0, 32);
  }

  // Simple XOR-based encryption (suitable for basic obfuscation)
  // For production apps, consider using more robust encryption like AES
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
      // This handles cases where data might not be encrypted yet
      return encryptedText;
    }
  }
}
