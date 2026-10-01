import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/encryption_helper.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/password_prompt_dialog.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

class NotesTab extends StatelessWidget {
  final String userId;
  final String searchQuery;

  const NotesTab({
    super.key,
    required this.userId,
    required this.searchQuery,
  });

  Future<bool> _verifyPasswordForNote(
    BuildContext context,
    DocumentSnapshot note,
  ) async {
    final data = note.data() as Map<String, dynamic>?;
    final encryptedCustomPassword = data?['customPassword'];
    final customPassword = encryptedCustomPassword != null
        ? EncryptionHelper.decrypt(encryptedCustomPassword)
        : null;

    return PasswordPromptDialog.show(
      context,
      expectedCustomPassword: customPassword,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
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
              title: 'Error loading notes',
              subtitle: '${snapshot.error}',
            ),
          );
        }

        final allNotes = snapshot.data?.docs ?? [];
        final query = searchQuery.toLowerCase().trim();

        final notes = query.isEmpty
            ? allNotes
            : allNotes.where((note) {
                final title = (note['title'] ?? '').toString().toLowerCase();
                return title.contains(query);
              }).toList();

        if (notes.isEmpty) {
          return EmptyStateView(
            icon: Icons.note_outlined,
            title: query.isEmpty ? 'No notes found' : 'No notes match your search',
            subtitle: query.isEmpty
                ? 'Tap the + button to create your first note'
                : 'Try searching for something else',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final isSecured = note['secured'] ?? false;

            return NoteCard(
              note: note,
              onTap: () async {
                if (isSecured) {
                  final verified = await _verifyPasswordForNote(context, note);
                  if (!verified) return;
                }

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteEditorScreen(note: note),
                    ),
                  );
                }
              },
              onDelete: () async {
                if (isSecured) {
                  final verified = await _verifyPasswordForNote(context, note);
                  if (!verified) return;
                }

                if (context.mounted) {
                  final confirm = await AppDialog.showConfirmation(
                    context,
                    title: 'Confirm Delete',
                    content: 'Do you want to delete this note?',
                    positiveText: 'Yes',
                    negativeText: 'No',
                    positiveColor: AppColors.error,
                  );

                  if (confirm) {
                    await note.reference.delete();
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}
