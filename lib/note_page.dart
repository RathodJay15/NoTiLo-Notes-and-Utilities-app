import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'note_page_controller.dart';

class NotePage extends StatefulWidget {
  final DocumentSnapshot? note;

  const NotePage({super.key, this.note});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  late NotePageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotePageController(widget.note);
    _controller.setStateCallback(setState);
    _controller.init();
    _controller.requestStoragePermission();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF5C5C5C),
      ),
    );
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text("Verify Password", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _controller.customPassword != null ? "Enter your custom password:" : "Enter your login password:",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: GoogleFonts.poppins(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: GoogleFonts.poppins(color: const Color(0xFF5C5C5C)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF5C5C5C)),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("Cancel", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final verified = await _controller.verifyPassword(context, passwordController.text);
                      if (verified) {
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect password!")));
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5C5C5C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("Verify", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text("Set Password Protection", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<int>(
                      title: Text("Use login password", style: GoogleFonts.poppins(fontSize: 14)),
                      value: 0,
                      groupValue: selectedOption,
                      activeColor: const Color(0xFF5C5C5C),
                      onChanged: (val) => setState(() => selectedOption = val!),
                    ),
                    RadioListTile<int>(
                      title: Text("Set new password", style: GoogleFonts.poppins(fontSize: 14)),
                      value: 1,
                      groupValue: selectedOption,
                      activeColor: const Color(0xFF5C5C5C),
                      onChanged: (val) => setState(() => selectedOption = val!),
                    ),
                    if (selectedOption == 1) const SizedBox(height: 10),
                    if (selectedOption == 1)
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: GoogleFonts.poppins(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: "New Password",
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF5C5C5C)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF5C5C5C)),
                            onPressed: () => setState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                      ),
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("Cancel", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  ),
                  TextButton(
                    onPressed: () {
                      if (selectedOption == 1) {
                        if (passwordController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password cannot be empty!")));
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("Confirm", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      _controller.setPasswordProtection(result);
    }
  }

  Future<void> _showShareMenu() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Share Options", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download, color: Color(0xFF5C5C5C)),
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
        title: Text("Export Note", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        content: Text("Choose a format to export your note.", style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14)),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.exportAsPDF(_showSnackBar);
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: Text("PDF", style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C5C5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.exportAsTXT(_showSnackBar);
            },
            icon: const Icon(Icons.description, color: Colors.white),
            label: Text("TXT", style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C5C5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
        title: Text("Share Note", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        content: Text("Choose a format to share your note.", style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14)),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.shareAsPDF(_showSnackBar);
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: Text("PDF", style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C5C5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.shareAsTXT(_showSnackBar);
            },
            icon: const Icon(Icons.description, color: Colors.white),
            label: Text("TXT", style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C5C5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
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
        await _controller.deleteNote(context, _verifyPassword);
      }
    }
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
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black)),
      content: Text(content, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black.withValues(alpha: 0.8))),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(negativeText, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            backgroundColor: positiveColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(positiveText, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  void _pickColor(bool isBackground) {
    final colors = [Colors.black, Colors.white, Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.purple, Colors.pink, Colors.brown, Colors.grey];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBackground ? 'Pick Background Color' : 'Pick Text Color', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                _controller.applyColor(color, isBackground);
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

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onPressed, {Color? iconColor, bool isActive = false}) {
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

  Future<bool> _onWillPop() async {
    if (_controller.isEdited) {
      if (widget.note == null) {
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (_) => _buildStyledDialog(
            title: "Save Changes?",
            content: "You have unsaved changes. Would you like to save before exiting?",
            positiveText: "Save",
            negativeText: "Discard",
            positiveColor: const Color(0xFF5C5C5C),
          ),
        );

        if (shouldSave == true) {
          await _controller.saveNote(context);
          return false;
        }
      } else {
        await _controller.saveNote(context);
        return false;
      }
    }
    return true;
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
              if (!isEditing) return;
              _controller.startEditingAppBarTitle();
            },
            child: Text(
              isEditing ? (_controller.titleController.text.isEmpty ? "Untitled" : _controller.titleController.text) : "New Note",
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ),
          actions: [
            if (isEditing)
              IconButton(
                onPressed: () async {
                  if (_controller.isSecured) {
                    final verified = await _verifyPassword();
                    if (!verified) return;
                    _controller.removePasswordProtection();
                  } else {
                    await _showPasswordOptionsDialog();
                  }
                },
                icon: Icon(_controller.isSecured ? Icons.lock : Icons.lock_open, color: _controller.isSecured ? Colors.amber : Colors.white),
                tooltip: _controller.isSecured ? "Remove Password Protection" : "Add Password Protection",
              ),
            if (isEditing) IconButton(onPressed: _showShareMenu, icon: const Icon(Icons.share, color: Colors.white)),
            if (isEditing) IconButton(onPressed: _deleteNote, icon: const Icon(Icons.delete, color: Colors.red)),
            IconButton(onPressed: () => _controller.saveNote(context), icon: const Icon(Icons.save, color: Colors.white)),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_controller.isNewNote)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _controller.titleController,
                      style: TextStyle(color: Colors.black),
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      onChanged: (_) => _controller.markEdited(),
                    ),
                  ),
                if (_controller.isNewNote)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Text', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                      ],
                    ),
                  ),
                if (_controller.isEditingAppBarTitle && !_controller.isNewNote)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller.appBarTitleController,
                                autofocus: true,
                                style: GoogleFonts.poppins(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: "Title",
                                  labelStyle: GoogleFonts.poppins(color: const Color(0xFF5C5C5C)),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: Color(0xFF5C5C5C)),
                              onPressed: () => _controller.updateAppBarTitle(),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                    ],
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0, bottom: 0.0),
                          child: quill.QuillEditor.basic(
                            controller: _controller.quillController,
                            focusNode: _controller.editorFocusNode,
                            scrollController: _controller.editorScrollController,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C5C5C),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolbarButton(Icons.format_bold, "Bold", () => _controller.toggleAttribute(quill.Attribute.bold), isActive: _controller.isAttributeActive(quill.Attribute.bold)),
                    _buildToolbarButton(Icons.format_italic, "Italic", () => _controller.toggleAttribute(quill.Attribute.italic), isActive: _controller.isAttributeActive(quill.Attribute.italic)),
                    _buildToolbarButton(Icons.format_underline, "Underline", () => _controller.toggleAttribute(quill.Attribute.underline), isActive: _controller.isAttributeActive(quill.Attribute.underline)),
                    _buildToolbarButton(Icons.format_color_text, "Color", () => _pickColor(false), iconColor: _controller.selectedTextColor),
                    _buildToolbarButton(Icons.format_color_fill, "Bg Color", () => _pickColor(true), iconColor: _controller.selectedBgColor == Colors.transparent ? Colors.white : _controller.selectedBgColor),
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
    _controller.dispose();
    super.dispose();
  }
}
