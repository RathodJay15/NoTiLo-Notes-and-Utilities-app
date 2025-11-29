import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SimpleUtilityPage extends StatefulWidget {
  final DocumentSnapshot? utility;

  const SimpleUtilityPage({super.key, this.utility});

  @override
  State<SimpleUtilityPage> createState() => _SimpleUtilityPageState();
}

class _SimpleUtilityPageState extends State<SimpleUtilityPage> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    if (widget.utility != null) {
      _titleController.text = widget.utility!['title'] ?? '';
      _urlController.text = widget.utility!['url'] ?? '';
    }

    _titleController.addListener(_onEdited);
    _urlController.addListener(_onEdited);
  }

  void _onEdited() => setState(() => _isEdited = true);

  Future<void> _saveUtility() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("simpleUtilities");

    final data = {
      'title': _titleController.text.trim().isEmpty ? "New Simple Utility" : _titleController.text.trim(),
      'url': _urlController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (widget.utility != null) {
      await widget.utility!.reference.update(data);
    } else {
      await collection.add(data);
    }

    _isEdited = false;
    Navigator.pop(context);
  }

  Future<void> _deleteUtility() async {
    if (widget.utility != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => _buildStyledDialog(
          title: "Confirm Delete",
          content: "Do you want to delete this utility?",
          positiveText: "Yes",
          negativeText: "No",
          positiveColor: Colors.red,
        ),
      );

      if (confirm ?? false) {
        await widget.utility!.reference.delete();
        Navigator.pop(context);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isEdited) {
      // For NEW utilities: ask to save or discard
      if (widget.utility == null) {
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (_) => _buildStyledDialog(
            title: "Save Changes?",
            content: "You have unsaved changes. Would you like to save before exiting?",
            positiveText: "Save",
            negativeText: "Discard",
          ),
        );

        if (shouldSave == true) {
          await _saveUtility();
          return false;
        }
      } else {
        // For EXISTING utilities: auto-save without asking
        await _saveUtility();
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.utility != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF5C5C5C),
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            isEditing ? "Edit Simple Utility" : "New Simple Utility",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          actions: [
            if (isEditing)
              IconButton(
                onPressed: _deleteUtility,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            IconButton(
              onPressed: _saveUtility,
              icon: const Icon(Icons.save, color: Colors.white),
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
                  labelText: "Title / Name",
                  labelStyle: GoogleFonts.poppins(color: Color(0xFF5C5C5C)),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "URL",
                  labelStyle: GoogleFonts.poppins(color: Color(0xFF5C5C5C)),
                  border: InputBorder.none,
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
    _urlController.dispose();
    super.dispose();
  }
}
