import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'encryption_helper.dart';

class LoginUtilityPage extends StatefulWidget {
  final DocumentSnapshot? utility;

  const LoginUtilityPage({super.key, this.utility});

  @override
  State<LoginUtilityPage> createState() => _LoginUtilityPageState();
}

class _LoginUtilityPageState extends State<LoginUtilityPage> {
  final _titleController = TextEditingController();
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
    // If opening an existing utility → load values + KEEP password hidden
    if (widget.utility != null) {
      _titleController.text = widget.utility!['title'] ?? '';
      _urlController.text = widget.utility!['url'];
      // Decrypt username and password when loading
      _usernameController.text = EncryptionHelper.decrypt(widget.utility!['usernameOrEmail']);
      _passwordController.text = EncryptionHelper.decrypt(widget.utility!['password']);

      _obscurePassword = true;   // Existing → hidden
    } else {
      // Creating new utility → SHOW password field (not hidden)
      _obscurePassword = false;  // NEW → visible
    }

    _titleController.addListener(_onEdited);
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
        .collection("loginUtilities");

    // Encrypt username and password before saving
    final data = {
      'title': _titleController.text.trim().isEmpty ? "New Login Utility" : _titleController.text.trim(),
      'url': _urlController.text.trim(),
      'usernameOrEmail': EncryptionHelper.encrypt(_usernameController.text.trim()),
      'password': EncryptionHelper.encrypt(_passwordController.text.trim()),
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

  Future<void> _verifyAndTogglePassword() async {
    if (_isVerified) {
      setState(() => _obscurePassword = !_obscurePassword);
      return;
    }

    final passwordController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        bool obscurePassword = true;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                    "Enter your login password to view this utility password:",
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
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
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
                  onPressed: () => Navigator.pop(context, true),
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
            );
          },
        );
      },

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
  Widget _buildPasswordField() {
    // CASE 1 — NEW UTILITY → Normal TextField
    if (widget.utility == null) {
      return TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: GoogleFonts.poppins(color: Colors.black),
        decoration: InputDecoration(
          labelText: "Password",
          labelStyle: GoogleFonts.poppins(color: Color(0xFF5C5C5C)),
          border: InputBorder.none,
        ),
        onChanged: (_) => _onEdited(),
      );
    }

    // CASE 2 — EXISTING UTILITY → Locked until verified
    return GestureDetector(
      onTap:  () => _verifyAndTogglePassword(),
      child: AbsorbPointer(
        absorbing: !_isVerified,
        child: TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.poppins(color: Colors.black),
          decoration: InputDecoration(
            labelText: "Password",
            labelStyle: GoogleFonts.poppins(color: Color(0xFF5C5C5C)),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: _verifyAndTogglePassword,
            ),
          ),
          onChanged: (_) => _onEdited(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.utility != null;

    return PopScope(
      canPop: false, // Prevents auto pop; we’ll handle it manually
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
            isEditing ? "Edit Login Utility" : "New Login Utility",
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
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Username / Email",
                  labelStyle: GoogleFonts.poppins(color: Color(0xFF5C5C5C)),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),

              //create password field
              _buildPasswordField(),

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
    _usernameController.dispose();
    _passwordController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }
}
