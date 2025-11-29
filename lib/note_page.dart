import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:universal_html/html.dart' as html;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:share_plus/share_plus.dart';
import 'encryption_helper.dart';

class NotePage extends StatefulWidget {
  final DocumentSnapshot? note;

  const NotePage({super.key, this.note});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _titleController = TextEditingController();
  late quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  bool _isEdited = false;
  bool _isSecured = false;
  String? _customPassword;
  Color _selectedTextColor = Colors.black;
  Color _selectedBgColor = Colors.transparent;
  bool _isEditingAppBarTitle = false;
  bool _isNewNote = false;
  final _appBarTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
    _loadNoteData();
    // Determine if this is a new note
    _isNewNote = widget.note == null;
    _titleController.addListener(_onEdited);
    _quillController.addListener(_onEdited);
  }

  void _loadNoteData() {
    if (widget.note != null) {
      _titleController.text = widget.note!['title'];
      _isSecured = widget.note!['secured'] ?? false;
      final data = widget.note!.data() as Map<String, dynamic>?;
      final encryptedPassword = data?['customPassword'];
      _customPassword = encryptedPassword != null
          ? EncryptionHelper.decrypt(encryptedPassword)
          : null;

      // Decrypt description
      String decryptedDesc = EncryptionHelper.decrypt(
        widget.note!['description'],
      );

      try {
        // Try to parse as JSON (Rich Text)
        final json = jsonDecode(decryptedDesc);
        _quillController = quill.QuillController(
          document: quill.Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Fallback: Treat as plain text (Legacy notes)
        final doc = quill.Document()..insert(0, decryptedDesc);
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      // New Note
      _quillController = quill.QuillController.basic();
    }
  }

  void _onEdited() {
    if (!_isEdited) {
      setState(() => _isEdited = true);
    }
  }

  Future<void> _requestStoragePermission() async {
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

  Future<void> _saveNote() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("notes");

    // Convert Rich Text to JSON string, then Encrypt
    final deltaJson = _quillController.document.toDelta().toJson();
    final jsonString = jsonEncode(deltaJson);
    final encryptedDesc = EncryptionHelper.encrypt(jsonString);

    final data = {
      'title': _titleController.text.trim().isEmpty
          ? "New Note"
          : _titleController.text.trim(),
      'description': encryptedDesc,
      'secured': _isSecured,
      'customPassword': _customPassword != null
          ? EncryptionHelper.encrypt(_customPassword!)
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (widget.note != null) {
      await widget.note!.reference.update(data);
    } else {
      await collection.add(data);
    }

    _isEdited = false;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteNote() async {
    if (widget.note != null) {
      if (_isSecured) {
        final verified = await _verifyPassword();
        if (!verified) return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => _buildStyledDialog(
          title: "Confirm Delete",
          content: "Do you want to delete this note?",
          positiveText: "Yes",
          negativeText: "No",
          positiveColor: Colors.red,
        ),
      );

      if (confirm ?? false) {
        await widget.note!.reference.delete();
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<bool> _verifyPassword({bool forOpening = false}) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 500,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  "Verify Password",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customPassword != null
                          ? "Enter your custom password:"
                          : "Enter your login password:",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: GoogleFonts.poppins(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: GoogleFonts.poppins(
                          color: const Color(0xFF5C5C5C),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF5C5C5C),
                          ),
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (_customPassword != null) {
                        if (passwordController.text.trim() == _customPassword) {
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Incorrect password!"),
                            ),
                          );
                        }
                      } else {
                        try {
                          final user = FirebaseAuth.instance.currentUser!;
                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: passwordController.text.trim(),
                          );
                          await user.reauthenticateWithCredential(cred);
                          Navigator.pop(context, true);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Incorrect password!"),
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5C5C5C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Verify",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return confirm ?? false;
  }

  Future<void> _showPasswordOptionsDialog() async {
    final passwordController = TextEditingController();
    int selectedOption = 0;
    bool obscurePassword = true;

    final result = await showDialog<String?>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 500,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  "Set Password Protection",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<int>(
                      title: Text(
                        "Use login password",
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      value: 0,
                      groupValue: selectedOption,
                      activeColor: const Color(0xFF5C5C5C),
                      onChanged: (val) {
                        setState(() => selectedOption = val!);
                      },
                    ),
                    RadioListTile<int>(
                      title: Text(
                        "Set new password",
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      value: 1,
                      groupValue: selectedOption,
                      activeColor: const Color(0xFF5C5C5C),
                      onChanged: (val) {
                        setState(() => selectedOption = val!);
                      },
                    ),
                    if (selectedOption == 1) const SizedBox(height: 10),
                    if (selectedOption == 1)
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: GoogleFonts.poppins(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: "New Password",
                          labelStyle: GoogleFonts.poppins(
                            color: const Color(0xFF5C5C5C),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF5C5C5C),
                            ),
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (selectedOption == 1) {
                        if (passwordController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Password cannot be empty!"),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, passwordController.text.trim());
                      } else {
                        Navigator.pop(context, "");
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5C5C5C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Confirm",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _isSecured = true;
        _customPassword = result.isEmpty ? null : result;
        _isEdited = true;
      });
    }
  }

  Future<void> _showShareMenu() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Share Options",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.file_download,
                color: Color(0xFF5C5C5C),
              ),
              title: Text("Export", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _exportNote();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF5C5C5C)),
              title: Text("Share", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _shareNote();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportNote() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Export Note",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          "Choose a format to export your note.",
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _exportAsPDF();
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: Text("PDF", style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C5C5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _exportAsTXT();
            },
            icon: const Icon(Icons.description, color: Colors.white),
            label: Text("TXT", style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C5C5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareNote() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Share Note",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          "Choose a format to share your note.",
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _shareAsPDF();
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: Text("PDF", style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C5C5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _shareAsTXT();
            },
            icon: const Icon(Icons.description, color: Colors.white),
            label: Text("TXT", style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C5C5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pdf.PdfColor _parsePdfColor(String colorStr) {
    if (colorStr.isEmpty) return pdf.PdfColors.black;
    if (colorStr.startsWith('#')) {
      return pdf.PdfColor.fromHex(colorStr);
    } else if (colorStr.startsWith('0x') || colorStr.startsWith('0X')) {
      return pdf.PdfColor.fromInt(int.parse(colorStr));
    } else {
      return pdf.PdfColor.fromHex('#$colorStr');
    }
  }

  Future<void> _exportAsPDF() async {
    try {
      await _requestStoragePermission();

      final pdfDoc = pw.Document();
      final title = _titleController.text.isEmpty
          ? 'Note'
          : _titleController.text;
      final delta = _quillController.document.toDelta();

      final devanagariData = await rootBundle.load(
        'assets/fonts/NotoSansDevanagari.ttf',
      );
      final gujaratiData = await rootBundle.load(
        'assets/fonts/NotoSansGujarati.ttf',
      );
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
            fontWeight: attrs['bold'] == true
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
            fontStyle: attrs['italic'] == true
                ? pw.FontStyle.italic
                : pw.FontStyle.normal,
            decoration: attrs['underline'] == true
                ? pw.TextDecoration.underline
                : null,
            color: attrs['color'] != null
                ? _parsePdfColor(attrs['color'])
                : pdf.PdfColors.black,
            background: attrs['background'] != null
                ? pw.BoxDecoration(color: _parsePdfColor(attrs['background']))
                : null,
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
        _showSnackBar("PDF exported to Downloads folder");
      }
    } catch (e) {
      _showSnackBar("Failed to export PDF: $e");
    }
  }

  Future<void> _exportAsTXT() async {
    await _requestStoragePermission();

    final fileName =
        "${_titleController.text.isEmpty ? 'note' : _titleController.text}.txt";

    // Get plain text from Quill controller
    final plainText = _quillController.document.toPlainText();

    final content = "Title: ${_titleController.text}\n\n$plainText";

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
        _showSnackBar("TXT exported to Downloads folder");
      } catch (e) {
        _showSnackBar("Failed to export TXT: $e");
      }
    }
  }

  Future<void> _shareAsPDF() async {
    try {
      await _requestStoragePermission();

      final pdfDoc = pw.Document();
      final title = _titleController.text.isEmpty
          ? 'Note'
          : _titleController.text;
      final delta = _quillController.document.toDelta();

      final devanagariData = await rootBundle.load(
        'assets/fonts/NotoSansDevanagari.ttf',
      );
      final gujaratiData = await rootBundle.load(
        'assets/fonts/NotoSansGujarati.ttf',
      );
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
            fontWeight: attrs['bold'] == true
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
            fontStyle: attrs['italic'] == true
                ? pw.FontStyle.italic
                : pw.FontStyle.normal,
            decoration: attrs['underline'] == true
                ? pw.TextDecoration.underline
                : null,
            color: attrs['color'] != null
                ? _parsePdfColor(attrs['color'])
                : pdf.PdfColors.black,
            background: attrs['background'] != null
                ? pw.BoxDecoration(color: _parsePdfColor(attrs['background']))
                : null,
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
        await Share.shareXFiles([xFile], text: _titleController.text);
      }
    } catch (e) {
      _showSnackBar("Failed to share PDF: $e");
    }
  }

  Future<void> _shareAsTXT() async {
    try {
      final plainText = _quillController.document.toPlainText();
      final content = "Title: ${_titleController.text}\n\n$plainText";

      if (kIsWeb) {
        await Share.share(content, subject: _titleController.text);
      } else {
        final fileName =
            "${_titleController.text.isEmpty ? 'note' : _titleController.text}.txt";
        final tempDir = await getTemporaryDirectory();
        final file = File("${tempDir.path}/$fileName");
        await file.writeAsString(content);
        final xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: _titleController.text);
      }
    } catch (e) {
      _showSnackBar("Failed to share TXT: $e");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF5C5C5C),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_isEdited) {
      if (widget.note == null) {
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (_) => _buildStyledDialog(
            title: "Save Changes?",
            content:
                "You have unsaved changes. Would you like to save before exiting?",
            positiveText: "Save",
            negativeText: "Discard",
            positiveColor: const Color(0xFF5C5C5C),
          ),
        );

        if (shouldSave == true) {
          await _saveNote();
          return false;
        }
      } else {
        await _saveNote();
        return false;
      }
    }
    return true;
  }

  Widget _buildStyledDialog({
    required String title,
    required String content,
    required String positiveText,
    required String negativeText,
    Color positiveColor = const Color(0xFF5C5C5C),
  }) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.black,
        ),
      ),
      content: Text(
        content,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black.withValues(alpha: 0.8),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            negativeText,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            backgroundColor: positiveColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            positiveText,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // --- Toolbar Logic ---

  void _toggleAttribute(quill.Attribute attribute) {
    final isToggled = _quillController.getSelectionStyle().containsKey(
      attribute.key,
    );
    if (isToggled) {
      _quillController.formatSelection(quill.Attribute.clone(attribute, null));
    } else {
      _quillController.formatSelection(attribute);
    }
    setState(() {});
  }

  void _pickColor(bool isBackground) {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isBackground ? 'Pick Background Color' : 'Pick Text Color',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                final hexString = color.value.toRadixString(16).padLeft(8, '0');
                final hex = '#${hexString.substring(2)}';
                setState(() {
                  if (isBackground) {
                    _selectedBgColor = color;
                    _quillController.formatSelection(
                      quill.BackgroundAttribute(hex),
                    );
                  } else {
                    _selectedTextColor = color;
                    _quillController.formatSelection(quill.ColorAttribute(hex));
                  }
                });
                Navigator.of(context).pop();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _isAttributeActive(quill.Attribute attribute) {
    return _quillController.getSelectionStyle().containsKey(attribute.key);
  }

  Widget _buildToolbarButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    Color? iconColor,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF5C5C5C),
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white),
          title: GestureDetector(
            onTap: () {
              // Only allow editing AppBar title for EXISTING notes
              if (!isEditing) return;

              setState(() {
                _appBarTitleController.text = _titleController.text;
                _isEditingAppBarTitle = true;
              });
            },
            child: Text(
              isEditing
                  ? (_titleController.text.isEmpty
                        ? "Untitled"
                        : _titleController.text)
                  : "New Note",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          actions: [
            if (isEditing)
              IconButton(
                onPressed: () async {
                  if (_isSecured) {
                    final verified = await _verifyPassword();
                    if (!verified) return;
                    setState(() {
                      _isSecured = false;
                      _customPassword = null;
                      _isEdited = true;
                    });
                  } else {
                    await _showPasswordOptionsDialog();
                  }
                },
                icon: Icon(
                  _isSecured ? Icons.lock : Icons.lock_open,
                  color: _isSecured ? Colors.amber : Colors.white,
                ),
                tooltip: _isSecured
                    ? "Remove Password Protection"
                    : "Add Password Protection",
              ),
            if (isEditing)
              IconButton(
                onPressed: _showShareMenu,
                icon: const Icon(Icons.share, color: Colors.white),
              ),
            if (isEditing)
              IconButton(
                onPressed: _deleteNote,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            IconButton(
              onPressed: _saveNote,
              icon: const Icon(Icons.save, color: Colors.white),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Dedicated Title Field for New Notes
                if (_isNewNote)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _titleController,
                      style: TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),

                      onChanged: (_) => _onEdited(),
                    ),
                  ),
                if (_isNewNote)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Text',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),

                // AppBar Title Editor (Only for existing notes when tapped)
                if (_isEditingAppBarTitle && !_isNewNote)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _appBarTitleController,
                                autofocus: true,
                                style: GoogleFonts.poppins(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: "Title",
                                  labelStyle: GoogleFonts.poppins(
                                    color: const Color(0xFF5C5C5C),
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Color(0xFF5C5C5C),
                              ),
                              onPressed: () {
                                setState(() {
                                  _titleController.text =
                                      _appBarTitleController.text;
                                  _isEditingAppBarTitle = false;
                                  _isEdited = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 12.0,
                            left: 12.0,
                            right: 12.0,
                            bottom: 0.0,
                          ),
                          child: quill.QuillEditor.basic(
                            controller: _quillController,
                            focusNode: _editorFocusNode,
                            scrollController: _editorScrollController,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Floating Toolbar at the bottom
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C5C5C),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolbarButton(
                      Icons.format_bold,
                      "Bold",
                      () => _toggleAttribute(quill.Attribute.bold),
                      isActive: _isAttributeActive(quill.Attribute.bold),
                    ),
                    _buildToolbarButton(
                      Icons.format_italic,
                      "Italic",
                      () => _toggleAttribute(quill.Attribute.italic),
                      isActive: _isAttributeActive(quill.Attribute.italic),
                    ),
                    _buildToolbarButton(
                      Icons.format_underline,
                      "Underline",
                      () => _toggleAttribute(quill.Attribute.underline),
                      isActive: _isAttributeActive(quill.Attribute.underline),
                    ),
                    _buildToolbarButton(
                      Icons.format_color_text,
                      "Color",
                      () => _pickColor(false),
                      iconColor: _selectedTextColor,
                    ),
                    _buildToolbarButton(
                      Icons.format_color_fill,
                      "Bg Color",
                      () => _pickColor(true),
                      iconColor: _selectedBgColor == Colors.transparent
                          ? Colors.white
                          : _selectedBgColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _appBarTitleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }
}
