import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../widgets/login_utility_card.dart';
import 'login_utility_form_screen.dart';

class LoginUtilityTab extends StatelessWidget {
  final String userId;
  final String searchQuery;

  const LoginUtilityTab({
    super.key,
    required this.userId,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('loginUtilities')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: EmptyStateView(
              icon: Icons.error_outline,
              title: 'Error loading utilities',
              subtitle: '${snapshot.error}',
            ),
          );
        }

        final allUtilities = snapshot.data?.docs ?? [];
        final query = searchQuery.toLowerCase().trim();

        final utilities = query.isEmpty
            ? allUtilities
            : allUtilities.where((item) {
                final title = (item['title'] ?? '').toString().toLowerCase();
                return title.contains(query);
              }).toList();

        if (utilities.isEmpty) {
          return EmptyStateView(
            icon: Icons.login,
            title: query.isEmpty
                ? 'No login utilities found'
                : 'No login utilities match your search',
            subtitle: query.isEmpty
                ? 'Tap the + button to save your first credential'
                : 'Try searching for something else',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
          itemCount: utilities.length,
          itemBuilder: (context, index) {
            final utility = utilities[index];

            return LoginUtilityCard(
              utility: utility,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginUtilityFormScreen(utility: utility),
                  ),
                );
              },
              onDelete: () async {
                final confirm = await AppDialog.showConfirmation(
                  context,
                  title: 'Confirm Delete',
                  content: 'Do you want to delete this utility?',
                  positiveText: 'Yes',
                  negativeText: 'No',
                  positiveColor: AppColors.error,
                );

                if (confirm) {
                  await utility.reference.delete();
                }
              },
            );
          },
        );
      },
    );
  }
}
