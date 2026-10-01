import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            backgroundColor: AppColors.primary,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.note, size: 22),
                label: 'Notes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.link, size: 22),
                label: 'Simple Utility',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.login, size: 22),
                label: 'Login Utility',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
