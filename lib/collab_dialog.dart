import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Collaborator {
  final String name;
  final String email;
  final String role;

  Collaborator({required this.name, required this.email, required this.role});

  String getInitials() {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}

class CollabDialog extends StatefulWidget {
  const CollabDialog({super.key});

  @override
  State<CollabDialog> createState() => _CollabDialogState();
}

class _CollabDialogState extends State<CollabDialog> {
  final List<Collaborator> _collaborators = [];

  void _showAddCollaboratorDialog() {
    final emailController = TextEditingController();
    String selectedRole = 'Viewer';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add Collaborator', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: emailController,
                    style: GoogleFonts.poppins(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Enter email',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Role:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
                  RadioListTile<String>(
                    title: Text('Viewer', style: GoogleFonts.poppins(fontSize: 14)),
                    value: 'Viewer',
                    groupValue: selectedRole,
                    activeColor: const Color(0xFF5C5C5C),
                    onChanged: (val) => setState(() => selectedRole = val!),
                  ),
                  RadioListTile<String>(
                    title: Text('Editor', style: GoogleFonts.poppins(fontSize: 14)),
                    value: 'Editor',
                    groupValue: selectedRole,
                    activeColor: const Color(0xFF5C5C5C),
                    onChanged: (val) => setState(() => selectedRole = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                ),
                TextButton(
                  onPressed: () {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter an email', style: GoogleFonts.poppins())),
                      );
                      return;
                    }

                    // Extract name from email (before @)
                    final name = email.split('@')[0].replaceAll('.', ' ').replaceAll('_', ' ');
                    final capitalizedName = name.split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');

                    this.setState(() {
                      _collaborators.add(Collaborator(name: capitalizedName, email: email, role: selectedRole));
                    });

                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF5C5C5C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('People with access', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                  IconButton(
                    onPressed: _showAddCollaboratorDialog,
                    icon: const Icon(Icons.add_circle, color: Color(0xFF5C5C5C), size: 28),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: _collaborators.isEmpty
                  ? Center(
                      child: Text('No Collaborator', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _collaborators.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
                      itemBuilder: (context, index) {
                        final collaborator = _collaborators[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF5C5C5C),
                            child: Text(collaborator.getInitials(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                          title: Text(collaborator.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
                          subtitle: Text(collaborator.email, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                          trailing: Text(collaborator.role, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
                        );
                      },
                    ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF5C5C5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Done', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
