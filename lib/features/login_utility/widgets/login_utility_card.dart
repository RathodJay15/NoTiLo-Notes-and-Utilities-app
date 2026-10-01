import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/encryption_helper.dart';
import '../../../core/utils/url_helper.dart';

class LoginUtilityCard extends StatelessWidget {
  final DocumentSnapshot utility;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const LoginUtilityCard({
    super.key,
    required this.utility,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = utility['title'] ?? '';
    final url = utility['url'] ?? '';
    final rawUsername = utility['usernameOrEmail'] ?? '';
    final decryptedUsername = EncryptionHelper.decrypt(rawUsername);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              decryptedUsername,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await UrlHelper.copyToClipboard(context, decryptedUsername);
                    if (context.mounted) {
                      await UrlHelper.launchURL(context, url);
                    }
                  },
                  child: const Text('Open'),
                ),
                TextButton(
                  onPressed: () =>
                      UrlHelper.copyToClipboard(context, decryptedUsername),
                  child: const Text('Copy Username'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
