import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import 'package:permission_handler/permission_handler.dart';

class NotePage extends StatefulWidget {
  final DocumentSnapshot? note;

  const NotePage({Key? key, this.note}) : super(key: key);

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
    if (widget.note != null) {
      _titleController.text = widget.note!['title'];
      _descriptionController.text = widget.note!['description'];
    }
    _titleController.addListener(_onEdited);
    _descriptionController.addListener(_onEdited);
  }

  void _onEdited() => setState(() => _isEdited = true);

  Future<void> _requestStoragePermission() async {
    if (kIsWeb) {
      debugPrint("Web platform — storage permission not required.");
      return;
    }

    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted ||
          await Permission.storage.isGranted) return;

      if (await Permission.manageExternalStorage.request().isGranted ||
          await Permission.storage.request().isGranted) {
        debugPrint("Storage permission granted");
      } else {
        debugPrint("Storage permission denied");
      }
    }
  }


  Future<void> _saveNote() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("notes");

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (widget.note != null) {
      await widget.note!.reference.update(data);
    } else {
      await collection.add(data);
    }

    _isEdited = false;
    Navigator.pop(context);
  }

  Future<void> _deleteNote() async {
    if (widget.note != null) {
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
        Navigator.pop(context);
      }
    }
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
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 14,
          ),
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
                  borderRadius: BorderRadius.circular(12)),
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
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsPDF() async {
    await _requestStoragePermission();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _titleController.text,
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                _descriptionController.text,
                style: const pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    final fileName =
        "${_titleController.text.isEmpty ? 'note' : _titleController.text}.pdf";
    final bytes = await pdf.save();

    if (kIsWeb) {
      // ✅ Web download via Blob
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
        await file.writeAsBytes(bytes);
        _showSnackBar("PDF exported to Downloads folder");
      } catch (e) {
        _showSnackBar("Failed to export PDF: $e");
      }
    }
  }


  Future<void> _exportAsTXT() async {
    await _requestStoragePermission();

    final fileName =
        "${_titleController.text.isEmpty ? 'note' : _titleController.text}.txt";
    final content =
        "Title: ${_titleController.text}\n\n${_descriptionController.text}";

    if (kIsWeb) {
      // ✅ Web download via Blob
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      content: Text(
        content,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: 14,
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            negativeText,
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            positiveText,
            style: GoogleFonts.poppins(
              color: positiveColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Text(
            isEditing ? widget.note!['title'] : "New Note",
            style: GoogleFonts.poppins(color: Colors.black),
          ),
          actions: [
            if (isEditing)
              IconButton(
                onPressed: _exportNote,
                icon: const Icon(Icons.ios_share_outlined,
                    color: Color(0xFF5C5C5C)),
              ),
            if (isEditing)
              IconButton(
                onPressed: _deleteNote,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            IconButton(
              onPressed: _saveNote,
              icon: const Icon(Icons.save, color: Color(0xFF5C5C5C)),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Title",
                  labelStyle: GoogleFonts.poppins(color: Color(0xFF5C5C5C)),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  style: GoogleFonts.poppins(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: GoogleFonts.poppins(color: Color(0xFF5C5C5C)),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
