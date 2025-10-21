// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class NotePage extends StatefulWidget {
//   final DocumentSnapshot? note;
//
//   const NotePage({Key? key, this.note}) : super(key: key);
//
//   @override
//   State<NotePage> createState() => _NotePageState();
// }
//
// class _NotePageState extends State<NotePage> {
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.note != null) {
//       _titleController.text = widget.note!['title'];
//       _descriptionController.text = widget.note!['description'];
//     }
//   }
//
//   Future<void> _saveNote() async {
//     final userId = FirebaseAuth.instance.currentUser!.uid;
//     final collection = FirebaseFirestore.instance
//         .collection("users")
//         .doc(userId)
//         .collection("notes");
//
//     final data = {
//       'title': _titleController.text,
//       'description': _descriptionController.text,
//       'updatedAt': FieldValue.serverTimestamp(),
//     };
//
//     if (widget.note != null) {
//       await widget.note!.reference.update(data);
//     } else {
//       await collection.add(data);
//     }
//
//     Navigator.pop(context);
//   }
//
//   Future<void> _deleteNote() async {
//     if (widget.note != null) {
//       final confirm = await showDialog<bool>(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text("Confirm Delete"),
//           content: const Text("Do you want to delete this note?"),
//           actions: [
//             TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
//             TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
//           ],
//         ),
//       );
//
//       if (confirm ?? false) {
//         await widget.note!.reference.delete();
//         Navigator.pop(context);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isEditing = widget.note != null;
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         title: Text(
//           isEditing ? widget.note!['title'] : "New Note",
//           style: GoogleFonts.poppins(color: Colors.black),
//         ),
//         actions: [
//           if (isEditing)
//             IconButton(
//               onPressed: _deleteNote,
//               icon: const Icon(Icons.delete, color: Colors.red),
//             ),
//           IconButton(
//             onPressed: _saveNote,
//             icon: const Icon(Icons.save, color: Colors.green),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _titleController,
//               decoration: const InputDecoration(hintText: "Title"),
//             ),
//             const SizedBox(height: 12),
//             Expanded(
//               child: TextField(
//                 controller: _descriptionController,
//                 decoration: const InputDecoration(hintText: "Description"),
//                 maxLines: null,
//                 expands: true,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (widget.note != null) {
      _titleController.text = widget.note!['title'];
      _descriptionController.text = widget.note!['description'];
    }

    _titleController.addListener(_onEdited);
    _descriptionController.addListener(_onEdited);
  }

  void _onEdited() {
    setState(() => _isEdited = true);
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

  Future<bool> _onWillPop() async {
    if (_isEdited) {
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
        await _saveNote();
        return false;
      }
    }
    return true;
  }

  /// 🧱 Custom AlertDialog matching your Notilo theme
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
                decoration: const InputDecoration(
                  hintText: "Title",
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  style: GoogleFonts.poppins(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: "Description",
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
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
