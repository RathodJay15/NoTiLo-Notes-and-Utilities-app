import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'encryption_helper.dart';

class Formatters {
  Formatters._();

  static String formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  static String formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

  static String getNotePreviewText(String encryptedDesc) {
    final decrypted = EncryptionHelper.decrypt(encryptedDesc);
    try {
      final json = jsonDecode(decrypted);
      if (json is List) {
        final doc = quill.Document.fromJson(json);
        return doc.toPlainText().trim();
      }
    } catch (_) {
      // Fallback: plain text
    }
    return decrypted;
  }
}
