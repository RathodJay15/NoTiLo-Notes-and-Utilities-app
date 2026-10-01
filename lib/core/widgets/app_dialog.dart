import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppDialog {
  AppDialog._();

  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String content,
    required String positiveText,
    required String negativeText,
    Color positiveColor = AppColors.primary,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.cancelGrey,
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
            onPressed: () => Navigator.pop(ctx, true),
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
      ),
    );

    return result ?? false;
  }
}
