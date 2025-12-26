import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:universal_html/html.dart' as html;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:share_plus/share_plus.dart';
import 'encryption_helper.dart';

class NotePageController {
  final DocumentSnapshot? note;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController appBarTitleController = TextEditingController();
  late quill.QuillController quillController;
  final FocusNode editorFocusNode = FocusNode();
  final ScrollController editorScrollController = ScrollController();

  bool isEdited = false;
  bool isSecured = false;
  String? customPassword;
  Color selectedTextColor = Colors.black;
  Color selectedBgColor = Colors.transparent;
  bool isEditingAppBarTitle = false;
  bool isNewNote = false;

  Function(VoidCallback)? onStateChanged;

  NotePageController(this.note);

  void init() {
    isNewNote = note == null;
    loadNoteData();
    titleController.addListener(markEdited);
  }

  void setStateCallback(Function(VoidCallback) callback) {
    onStateChanged = callback;
  }

  void markEdited() {
    if (!isEdited) {
      isEdited = true;
      onStateChanged?.call(() {});
    }
  }

  void loadNoteData() {
    if (note != null) {
      titleController.text = note!['title'];
      isSecured = note!['secured'] ?? false;
      final data = note!.data() as Map<String, dynamic>?;
      final encryptedPassword = data?['customPassword'];
      customPassword = encryptedPassword != null
          ? EncryptionHelper.decrypt(encryptedPassword)
          : null;

      String decryptedDesc = EncryptionHelper.decrypt(note!['description']);

      try {
        final json = jsonDecode(decryptedDesc);
        quillController = quill.QuillController(
          document: quill.Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        final doc = quill.Document()..insert(0, decryptedDesc);
        quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      quillController = quill.QuillController.basic();
    }
    quillController.addListener(markEdited);
  }

  Future<void> requestStoragePermission() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted ||
          await Permission.storage.isGranted) {
        return;
      }
      await Permission.manageExternalStorage.request();
      await Permission.storage.request();
    }
  }

  Future<void> saveNote(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("notes");

    final deltaJson = quillController.document.toDelta().toJson();
    final jsonString = jsonEncode(deltaJson);
    final encryptedDesc = EncryptionHelper.encrypt(jsonString);

    final data = {
      'title': titleController.text.trim().isEmpty
          ? "New Note"
          : titleController.text.trim(),
      'description': encryptedDesc,
      'secured': isSecured,
      'customPassword': customPassword != null
          ? EncryptionHelper.encrypt(customPassword!)
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (note != null) {
      await note!.reference.update(data);
    } else {
      await collection.add(data);
    }

    isEdited = false;
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> deleteNote(BuildContext context, Future<bool> Function() verifyPassword) async {
    if (note != null) {
      if (isSecured) {
        final verified = await verifyPassword();
        if (!verified) return;
      }

      await note!.reference.delete();
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<bool> verifyPassword(BuildContext context, String enteredPassword) async {
    if (customPassword != null) {
      return enteredPassword.trim() == customPassword;
    } else {
      try {
        final user = FirebaseAuth.instance.currentUser!;
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: enteredPassword.trim(),
        );
        await user.reauthenticateWithCredential(cred);
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  void setPasswordProtection(String? password) {
    isSecured = true;
    customPassword = password?.isEmpty ?? true ? null : password;
    isEdited = true;
    onStateChanged?.call(() {});
  }

  void removePasswordProtection() {
    isSecured = false;
    customPassword = null;
    isEdited = true;
    onStateChanged?.call(() {});
  }

  pdf.PdfColor parsePdfColor(String colorStr) {
    if (colorStr.isEmpty) return pdf.PdfColors.black;
    if (colorStr.startsWith('#')) {
      return pdf.PdfColor.fromHex(colorStr);
    } else if (colorStr.startsWith('0x') || colorStr.startsWith('0X')) {
      return pdf.PdfColor.fromInt(int.parse(colorStr));
    } else {
      return pdf.PdfColor.fromHex('#$colorStr');
    }
  }

  Future<void> exportAsPDF(Function(String) showSnackBar) async {
    try {
      await requestStoragePermission();

      final pdfDoc = pw.Document();
      final title = titleController.text.isEmpty ? 'Note' : titleController.text;
      final delta = quillController.document.toDelta();

      final devanagariData = await rootBundle.load('assets/fonts/NotoSansDevanagari.ttf');
      final gujaratiData = await rootBundle.load('assets/fonts/NotoSansGujarati.ttf');
      final devanagariFont = pw.Font.ttf(devanagariData);
      final gujaratiFont = pw.Font.ttf(gujaratiData);

      List<pw.TextSpan> spans = [];
      for (var op in delta.toJson()) {
        final insert = op['insert'];
        final attrs = op['attributes'] ?? {};

        if (insert is String) {
          final style = pw.TextStyle(
            font: devanagariFont,
            fontFallback: [gujaratiFont],
            fontWeight: attrs['bold'] == true ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontStyle: attrs['italic'] == true ? pw.FontStyle.italic : pw.FontStyle.normal,
            decoration: attrs['underline'] == true ? pw.TextDecoration.underline : null,
            color: attrs['color'] != null ? parsePdfColor(attrs['color']) : pdf.PdfColors.black,
            background: attrs['background'] != null ? pw.BoxDecoration(color: parsePdfColor(attrs['background'])) : null,
          );
          spans.add(pw.TextSpan(text: insert, style: style));
        }
      }

      pdfDoc.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  font: devanagariFont,
                  fontFallback: [gujaratiFont],
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.RichText(text: pw.TextSpan(children: spans)),
          ],
        ),
      );

      final fileName = "$title.pdf";
      final bytes = await pdfDoc.save();

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory("/storage/emulated/0/Download");
        } else {
          dir = await getDownloadsDirectory();
        }

        final file = File("${dir!.path}/$fileName");
        await file.writeAsBytes(bytes);
        showSnackBar("PDF exported to Downloads folder");
      }
    } catch (e) {
      showSnackBar("Failed to export PDF: $e");
    }
  }

  Future<void> exportAsTXT(Function(String) showSnackBar) async {
    await requestStoragePermission();

    final fileName = "${titleController.text.isEmpty ? 'note' : titleController.text}.txt";
    final plainText = quillController.document.toPlainText();
    final content = "Title: ${titleController.text}\n\n$plainText";

    if (kIsWeb) {
      final bytes = Uint8List.fromList(content.codeUnits);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      try {
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory("/storage/emulated/0/Download");
        } else {
          dir = await getDownloadsDirectory();
        }

        final file = File("${dir!.path}/$fileName");
        await file.writeAsString(content);
        showSnackBar("TXT exported to Downloads folder");
      } catch (e) {
        showSnackBar("Failed to export TXT: $e");
      }
    }
  }

  Future<void> shareAsPDF(Function(String) showSnackBar) async {
    try {
      await requestStoragePermission();

      final pdfDoc = pw.Document();
      final title = titleController.text.isEmpty ? 'Note' : titleController.text;
      final delta = quillController.document.toDelta();

      final devanagariData = await rootBundle.load('assets/fonts/NotoSansDevanagari.ttf');
      final gujaratiData = await rootBundle.load('assets/fonts/NotoSansGujarati.ttf');
      final devanagariFont = pw.Font.ttf(devanagariData);
      final gujaratiFont = pw.Font.ttf(gujaratiData);

      List<pw.TextSpan> spans = [];
      for (var op in delta.toJson()) {
        final insert = op['insert'];
        final attrs = op['attributes'] ?? {};

        if (insert is String) {
          final style = pw.TextStyle(
            font: devanagariFont,
            fontFallback: [gujaratiFont],
            fontWeight: attrs['bold'] == true ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontStyle: attrs['italic'] == true ? pw.FontStyle.italic : pw.FontStyle.normal,
            decoration: attrs['underline'] == true ? pw.TextDecoration.underline : null,
            color: attrs['color'] != null ? parsePdfColor(attrs['color']) : pdf.PdfColors.black,
            background: attrs['background'] != null ? pw.BoxDecoration(color: parsePdfColor(attrs['background'])) : null,
          );
          spans.add(pw.TextSpan(text: insert, style: style));
        }
      }

      pdfDoc.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  font: devanagariFont,
                  fontFallback: [gujaratiFont],
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.RichText(text: pw.TextSpan(children: spans)),
          ],
        ),
      );

      final fileName = "$title.pdf";
      final bytes = await pdfDoc.save();

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File("${tempDir.path}/$fileName");
        await file.writeAsBytes(bytes);
        final xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: titleController.text);
      }
    } catch (e) {
      showSnackBar("Failed to share PDF: $e");
    }
  }

  Future<void> shareAsTXT(Function(String) showSnackBar) async {
    try {
      final plainText = quillController.document.toPlainText();
      final content = "Title: ${titleController.text}\n\n$plainText";

      if (kIsWeb) {
        await Share.share(content, subject: titleController.text);
      } else {
        final fileName = "${titleController.text.isEmpty ? 'note' : titleController.text}.txt";
        final tempDir = await getTemporaryDirectory();
        final file = File("${tempDir.path}/$fileName");
        await file.writeAsString(content);
        final xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: titleController.text);
      }
    } catch (e) {
      showSnackBar("Failed to share TXT: $e");
    }
  }

  void toggleAttribute(quill.Attribute attribute) {
    final isToggled = quillController.getSelectionStyle().containsKey(attribute.key);
    if (isToggled) {
      quillController.formatSelection(quill.Attribute.clone(attribute, null));
    } else {
      quillController.formatSelection(attribute);
    }
    onStateChanged?.call(() {});
  }

  void applyColor(Color color, bool isBackground) {
    final hexString = color.value.toRadixString(16).padLeft(8, '0');
    final hex = '#${hexString.substring(2)}';
    if (isBackground) {
      selectedBgColor = color;
      quillController.formatSelection(quill.BackgroundAttribute(hex));
    } else {
      selectedTextColor = color;
      quillController.formatSelection(quill.ColorAttribute(hex));
    }
    onStateChanged?.call(() {});
  }

  bool isAttributeActive(quill.Attribute attribute) {
    return quillController.getSelectionStyle().containsKey(attribute.key);
  }

  void updateAppBarTitle() {
    titleController.text = appBarTitleController.text;
    isEditingAppBarTitle = false;
    isEdited = true;
    onStateChanged?.call(() {});
  }

  void startEditingAppBarTitle() {
    appBarTitleController.text = titleController.text;
    isEditingAppBarTitle = true;
    onStateChanged?.call(() {});
  }

  Future<bool> onWillPop(BuildContext context, Future<void> Function() saveNote) async {
    if (isEdited) {
      if (note == null) {
        return false;
      } else {
        await saveNote();
        return false;
      }
    }
    return true;
  }

  void dispose() {
    titleController.dispose();
    appBarTitleController.dispose();
    quillController.dispose();
    editorFocusNode.dispose();
    editorScrollController.dispose();
  }
}
