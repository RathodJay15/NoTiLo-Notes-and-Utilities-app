import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class PasswordPromptDialog extends StatefulWidget {
  final String title;
  final String promptMessage;
  final String confirmButtonText;
  final String? expectedCustomPassword;
  final bool reauthenticateWithFirebase;

  const PasswordPromptDialog({
    super.key,
    this.title = 'Verify Password',
    this.promptMessage = 'Enter your password to continue:',
    this.confirmButtonText = 'Verify',
    this.expectedCustomPassword,
    this.reauthenticateWithFirebase = true,
  });

  /// Displays the password dialog and returns `true` if password is verified successfully.
  static Future<bool> show(
    BuildContext context, {
    String title = 'Verify Password',
    String? promptMessage,
    String confirmButtonText = 'Verify',
    String? expectedCustomPassword,
    bool reauthenticateWithFirebase = true,
  }) async {
    final effectiveMessage = promptMessage ??
        (expectedCustomPassword != null
            ? 'Enter your custom password:'
            : 'Enter your login password:');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => PasswordPromptDialog(
        title: title,
        promptMessage: effectiveMessage,
        confirmButtonText: confirmButtonText,
        expectedCustomPassword: expectedCustomPassword,
        reauthenticateWithFirebase: reauthenticateWithFirebase,
      ),
    );

    return result ?? false;
  }

  /// Displays the password dialog and returns the entered password string (e.g. for re-authentication).
  static Future<String?> showForPasswordInput(
    BuildContext context, {
    String title = 'Re-authenticate',
    String promptMessage = 'Please enter your password to confirm.',
    String confirmButtonText = 'Confirm',
  }) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        bool obscurePassword = true;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                title,
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
                    promptMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: controller,
                    obscureText: obscurePassword,
                    style: GoogleFonts.poppins(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.poppins(
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.primary,
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
                    backgroundColor: AppColors.cancelGrey,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text.trim()),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    confirmButtonText,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  State<PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<PasswordPromptDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (widget.expectedCustomPassword != null) {
        if (input == widget.expectedCustomPassword) {
          if (mounted) Navigator.pop(context, true);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect password!')),
            );
          }
        }
      } else if (widget.reauthenticateWithFirebase) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.email != null) {
          final cred = EmailAuthProvider.credential(
            email: user.email!,
            password: input,
          );
          await user.reauthenticateWithCredential(cred);
          if (mounted) Navigator.pop(context, true);
        } else {
          if (mounted) Navigator.pop(context, false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect password. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          widget.title,
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
              widget.promptMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _controller,
              obscureText: _obscurePassword,
              style: GoogleFonts.poppins(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: GoogleFonts.poppins(color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.primary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
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
              backgroundColor: AppColors.cancelGrey,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: _isLoading ? null : _verify,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.confirmButtonText,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }
}
