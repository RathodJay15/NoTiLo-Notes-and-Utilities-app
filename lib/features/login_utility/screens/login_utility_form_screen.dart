import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/encryption_helper.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/password_prompt_dialog.dart';

class LoginUtilityFormScreen extends StatefulWidget {
  final DocumentSnapshot? utility;

  const LoginUtilityFormScreen({super.key, this.utility});

  @override
  State<LoginUtilityFormScreen> createState() => _LoginUtilityFormScreenState();
}

class _LoginUtilityFormScreenState extends State<LoginUtilityFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isEdited = false;
  bool _isVerified = false;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.utility != null) {
      _titleController.text = widget.utility!['title'] ?? '';
      _urlController.text = widget.utility!['url'] ?? '';
      _usernameController.text =
          EncryptionHelper.decrypt(widget.utility!['usernameOrEmail'] ?? '');
      _passwordController.text =
          EncryptionHelper.decrypt(widget.utility!['password'] ?? '');
      _obscurePassword = true;
    } else {
      _obscurePassword = false;
    }

    _titleController.addListener(_onEdited);
    _urlController.addListener(_onEdited);
    _usernameController.addListener(_onEdited);
    _passwordController.addListener(_onEdited);
  }

  void _onEdited() => setState(() => _isEdited = true);

  Future<void> _saveUtility() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('loginUtilities');

    final data = {
      'title': _titleController.text.trim().isEmpty
          ? 'New Login Utility'
          : _titleController.text.trim(),
      'url': _urlController.text.trim(),
      'usernameOrEmail':
          EncryptionHelper.encrypt(_usernameController.text.trim()),
      'password': EncryptionHelper.encrypt(_passwordController.text.trim()),
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

  Future<void> _verifyAndTogglePassword() async {
    if (_isVerified) {
      setState(() => _obscurePassword = !_obscurePassword);
      return;
    }

    final verified = await PasswordPromptDialog.show(
      context,
      promptMessage:
          'Enter your login password to view this utility password:',
    );

    if (verified && mounted) {
      setState(() {
        _isVerified = true;
        _obscurePassword = false;
      });

      _autoHideTimer?.cancel();
      _autoHideTimer = Timer(const Duration(seconds: 30), () {
        if (mounted) {
          setState(() {
            _obscurePassword = true;
            _isVerified = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password hidden again for security.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password verified successfully!')),
      );
    }
  }

  Widget _buildPasswordField() {
    if (widget.utility == null) {
      return TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: GoogleFonts.poppins(color: Colors.black),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: GoogleFonts.poppins(color: AppColors.primary),
          border: InputBorder.none,
        ),
        onChanged: (_) => _onEdited(),
      );
    }

    return GestureDetector(
      onTap: _verifyAndTogglePassword,
      child: AbsorbPointer(
        absorbing: !_isVerified,
        child: TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.poppins(color: Colors.black),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: GoogleFonts.poppins(color: AppColors.primary),
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
            isEditing ? 'Edit Login Utility' : 'New Login Utility',
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
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Username / Email',
                  labelStyle: GoogleFonts.poppins(color: AppColors.primary),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
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
