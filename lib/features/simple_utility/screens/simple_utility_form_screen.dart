import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';

class SimpleUtilityFormScreen extends StatefulWidget {
  final DocumentSnapshot? utility;

  const SimpleUtilityFormScreen({super.key, this.utility});

  @override
  State<SimpleUtilityFormScreen> createState() =>
      _SimpleUtilityFormScreenState();
}

class _SimpleUtilityFormScreenState extends State<SimpleUtilityFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
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
        .collection('users')
        .doc(userId)
        .collection('simpleUtilities');

    final data = {
      'title': _titleController.text.trim().isEmpty
          ? 'New Simple Utility'
          : _titleController.text.trim(),
      'url': _urlController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (widget.utility != null) {
      await widget.utility!.reference.update(data);
    } else {
      await collection.add(data);
    }

    _isEdited = false;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteUtility() async {
    if (widget.utility != null) {
      final confirm = await AppDialog.showConfirmation(
        context,
        title: 'Confirm Delete',
        content: 'Do you want to delete this utility?',
        positiveText: 'Yes',
        negativeText: 'No',
        positiveColor: AppColors.error,
      );

      if (confirm) {
        await widget.utility!.reference.delete();
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isEdited) {
      if (widget.utility == null) {
        final shouldSave = await AppDialog.showConfirmation(
          context,
          title: 'Save Changes?',
          content:
              'You have unsaved changes. Would you like to save before exiting?',
          positiveText: 'Save',
          negativeText: 'Discard',
          positiveColor: AppColors.primary,
        );

        if (shouldSave) {
          await _saveUtility();
          return false;
        }
      } else {
        await _saveUtility();
        return false;
      }
    }
    return true;
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
          backgroundColor: AppColors.primary,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            isEditing ? 'Edit Simple Utility' : 'New Simple Utility',
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
                icon: const Icon(Icons.delete, color: AppColors.error),
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
                  labelText: 'Title / Name',
                  labelStyle: GoogleFonts.poppins(color: AppColors.primary),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'URL',
                  labelStyle: GoogleFonts.poppins(color: AppColors.primary),
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
