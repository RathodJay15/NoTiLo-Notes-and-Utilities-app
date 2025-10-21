// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class UtilityPage extends StatefulWidget {
//   final DocumentSnapshot? utility;
//
//   const UtilityPage({Key? key, this.utility}) : super(key: key);
//
//   @override
//   State<UtilityPage> createState() => _UtilityPageState();
// }
//
// class _UtilityPageState extends State<UtilityPage> {
//   final _urlController = TextEditingController();
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _isEdited = false;
//   bool _isVerified = false; // user verification flag
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.utility != null) {
//       _urlController.text = widget.utility!['url'];
//       _usernameController.text = widget.utility!['usernameOrEmail'];
//       _passwordController.text = widget.utility!['password'];
//     }
//
//     _urlController.addListener(_onEdited);
//     _usernameController.addListener(_onEdited);
//     _passwordController.addListener(_onEdited);
//   }
//
//   void _onEdited() {
//     setState(() => _isEdited = true);
//   }
//
//   Future<void> _saveUtility() async {
//     final userId = FirebaseAuth.instance.currentUser!.uid;
//     final collection = FirebaseFirestore.instance
//         .collection("users")
//         .doc(userId)
//         .collection("utilities");
//
//     final data = {
//       'url': _urlController.text.trim(),
//       'usernameOrEmail': _usernameController.text.trim(),
//       'password': _passwordController.text.trim(),
//       'createdAt': FieldValue.serverTimestamp(),
//     };
//
//     if (widget.utility != null) {
//       await widget.utility!.reference.update(data);
//     } else {
//       await collection.add(data);
//     }
//
//     _isEdited = false;
//     Navigator.pop(context);
//   }
//
//   Future<void> _deleteUtility() async {
//     if (widget.utility != null) {
//       final confirm = await showDialog<bool>(
//         context: context,
//         builder: (_) => _buildStyledDialog(
//           title: "Confirm Delete",
//           content: "Do you want to delete this utility?",
//           positiveText: "Yes",
//           negativeText: "No",
//           positiveColor: Colors.red,
//         ),
//       );
//
//       if (confirm ?? false) {
//         await widget.utility!.reference.delete();
//         Navigator.pop(context);
//       }
//     }
//   }
//
//   Future<bool> _onWillPop() async {
//     if (_isEdited) {
//       final shouldSave = await showDialog<bool>(
//         context: context,
//         builder: (_) => _buildStyledDialog(
//           title: "Save Changes?",
//           content: "You have unsaved changes. Would you like to save before exiting?",
//           positiveText: "Save",
//           negativeText: "Discard",
//         ),
//       );
//
//       if (shouldSave == true) {
//         await _saveUtility();
//         return false;
//       }
//     }
//     return true;
//   }
//
//   Widget _buildStyledDialog({
//     required String title,
//     required String content,
//     required String positiveText,
//     required String negativeText,
//     Color positiveColor = const Color(0xFF5C5C5C),
//   }) {
//     return AlertDialog(
//       backgroundColor: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       title: Text(
//         title,
//         style: GoogleFonts.poppins(
//           fontWeight: FontWeight.w600,
//           color: Colors.black,
//         ),
//       ),
//       content: Text(
//         content,
//         style: GoogleFonts.poppins(
//           color: Colors.black87,
//           fontSize: 14,
//         ),
//       ),
//       actionsAlignment: MainAxisAlignment.end,
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context, false),
//           child: Text(
//             negativeText,
//             style: GoogleFonts.poppins(color: Colors.grey[700]),
//           ),
//         ),
//         TextButton(
//           onPressed: () => Navigator.pop(context, true),
//           child: Text(
//             positiveText,
//             style: GoogleFonts.poppins(
//               color: positiveColor,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _verifyAndTogglePassword() async {
//     if (_isVerified) {
//       setState(() => _obscurePassword = !_obscurePassword);
//       return;
//     }
//
//     final passwordController = TextEditingController();
//
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text("Verify Password", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text("Enter your login password to view this utility password:",
//                 style: GoogleFonts.poppins(fontSize: 14)),
//             const SizedBox(height: 12),
//             TextField(
//               controller: passwordController,
//               obscureText: true,
//               style: GoogleFonts.poppins(),
//               decoration: const InputDecoration(hintText: "Enter Password"),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey[700])),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: Text("Verify", style: GoogleFonts.poppins(color: const Color(0xFF5C5C5C))),
//           ),
//         ],
//       ),
//     );
//
//     if (confirm ?? false) {
//       try {
//         final user = FirebaseAuth.instance.currentUser!;
//         final cred = EmailAuthProvider.credential(
//           email: user.email!,
//           password: passwordController.text.trim(),
//         );
//
//         await user.reauthenticateWithCredential(cred);
//
//         setState(() {
//           _isVerified = true;
//           _obscurePassword = false;
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Password verified successfully!")),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Incorrect password. Please try again.")),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isEditing = widget.utility != null;
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 1,
//           title: Text(
//             isEditing ? "Edit Utility" : "New Utility",
//             style: GoogleFonts.poppins(color: Colors.black),
//           ),
//           actions: [
//             if (isEditing)
//               IconButton(
//                 onPressed: _deleteUtility,
//                 icon: const Icon(Icons.delete, color: Colors.red),
//               ),
//             IconButton(
//               onPressed: _saveUtility,
//               icon: const Icon(Icons.save, color: Color(0xFF5C5C5C)),
//             ),
//           ],
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             children: [
//               TextField(
//                 controller: _urlController,
//                 style: GoogleFonts.poppins(color: Colors.black),
//                 decoration: const InputDecoration(hintText: "URL"),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: _usernameController,
//                 style: GoogleFonts.poppins(color: Colors.black),
//                 decoration: const InputDecoration(hintText: "Username / Email"),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: _passwordController,
//                 obscureText: _obscurePassword,
//                 readOnly: true,
//                 style: GoogleFonts.poppins(color: Colors.black),
//                 decoration: InputDecoration(
//                   hintText: "Password",
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscurePassword ? Icons.visibility : Icons.visibility_off,
//                       color: Colors.grey[700],
//                     ),
//                     onPressed: _verifyAndTogglePassword,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _urlController.dispose();
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class UtilityPage extends StatefulWidget {
  final DocumentSnapshot? utility;

  const UtilityPage({Key? key, this.utility}) : super(key: key);

  @override
  State<UtilityPage> createState() => _UtilityPageState();
}

class _UtilityPageState extends State<UtilityPage> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isEdited = false;
  bool _isVerified = false;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.utility != null) {
      _urlController.text = widget.utility!['url'];
      _usernameController.text = widget.utility!['usernameOrEmail'];
      _passwordController.text = widget.utility!['password'];
    }

    _urlController.addListener(_onEdited);
    _usernameController.addListener(_onEdited);
    _passwordController.addListener(_onEdited);
  }

  void _onEdited() {
    setState(() => _isEdited = true);
  }

  Future<void> _saveUtility() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("utilities");

    final data = {
      'url': _urlController.text.trim(),
      'usernameOrEmail': _usernameController.text.trim(),
      'password': _passwordController.text.trim(),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            negativeText,
            style: GoogleFonts.poppins(color: Colors.grey[700]),
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

  Future<void> _verifyAndTogglePassword() async {
    if (_isVerified) {
      setState(() => _obscurePassword = !_obscurePassword);
      return;
    }

    final passwordController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Verify Password", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter your login password to view this utility password:",
                style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: GoogleFonts.poppins(),
              decoration: const InputDecoration(hintText: "Enter Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Verify", style: GoogleFonts.poppins(color: const Color(0xFF5C5C5C))),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        final user = FirebaseAuth.instance.currentUser!;
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordController.text.trim(),
        );

        await user.reauthenticateWithCredential(cred);

        setState(() {
          _isVerified = true;
          _obscurePassword = false;
        });

        // Start 30-second auto-hide timer
        _autoHideTimer?.cancel();
        _autoHideTimer = Timer(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() {
              _obscurePassword = true;
              _isVerified = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Password hidden again for security."),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password verified successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incorrect password. Please try again.")),
        );
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.utility != null;

    return PopScope(
      canPop: false, // Prevents auto pop; we’ll handle it manually
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Text(
            isEditing ? "Edit Utility" : "New Utility",
            style: GoogleFonts.poppins(color: Colors.black),
          ),
          actions: [
            if (isEditing)
              IconButton(
                onPressed: _deleteUtility,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            IconButton(
              onPressed: _saveUtility,
              icon: const Icon(Icons.save, color: Color(0xFF5C5C5C)),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _urlController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: const InputDecoration(hintText: "URL"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: const InputDecoration(hintText: "Username / Email"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                readOnly: true,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey[700],
                    ),
                    onPressed: _verifyAndTogglePassword,
                  ),
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
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }
}
