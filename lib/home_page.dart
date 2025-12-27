import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'note_page.dart';
import 'simple_utility_page.dart';
import 'login_utility_page.dart';
import 'encryption_helper.dart';
import 'services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = "User";
  int _currentIndex = 0;
  bool _isSearchingNotes = false;
  bool _isSearchingSimpleUtilities = false;
  bool _isSearchingLoginUtilities = false;

  final TextEditingController _notesSearchController = TextEditingController();
  final TextEditingController _simpleUtilitiesSearchController =
      TextEditingController();
  final TextEditingController _loginUtilitiesSearchController =
      TextEditingController();

  String _notesSearchQuery = "";
  String _simpleUtilitiesSearchQuery = "";
  String _loginUtilitiesSearchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadUsername();

    _notesSearchController.addListener(() {
      setState(() {
        _notesSearchQuery = _notesSearchController.text.toLowerCase();
      });
    });

    _simpleUtilitiesSearchController.addListener(() {
      setState(() {
        _simpleUtilitiesSearchQuery = _simpleUtilitiesSearchController.text
            .toLowerCase();
      });
    });

    _loginUtilitiesSearchController.addListener(() {
      setState(() {
        _loginUtilitiesSearchQuery = _loginUtilitiesSearchController.text
            .toLowerCase();
      });
    });
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      setState(() {
        username = doc.data()?["username"] ?? "User";
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;

      final passwordController = TextEditingController();
      bool obscurePassword = true;

      final password = await showDialog<String>(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  "Re-authenticate",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Please enter your password to confirm account deletion.",
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
                  vertical: 5,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
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
                    onPressed: () =>
                        Navigator.pop(context, passwordController.text),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF5C5C5C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Confirm",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (password == null || password.isEmpty) return;

      // Step 2: Re-authenticate user
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      // Step 3: Delete user's data
      final userRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid);

      final notesSnapshot = await userRef.collection("notes").get();
      for (var doc in notesSnapshot.docs) {
        await doc.reference.delete();
      }

      final simpleUtilitiesSnapshot = await userRef
          .collection("simpleUtilities")
          .get();
      for (var doc in simpleUtilitiesSnapshot.docs) {
        await doc.reference.delete();
      }

      final loginUtilitiesSnapshot = await userRef
          .collection("loginUtilities")
          .get();
      for (var doc in loginUtilitiesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Step 4: Delete main user document
      await userRef.delete();

      // Step 5: Clear remember_me preference
      final authService = AuthService();
      await authService.setRememberMe(false);
      print('Remember me cleared after account deletion');

      // Step 6: Delete Firebase Auth account
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Account deleted successfully.",
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Error deleting account: ${e.message}";
      if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password. Please try again.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage, style: GoogleFonts.poppins())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error deleting account: $e",
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not launch URL")));
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
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

  // Helper to format time as AM/PM
  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return "$hour12:$minute $period";
  }

  String _getPreviewText(String encryptedDesc) {
    String decrypted = EncryptionHelper.decrypt(encryptedDesc);
    try {
      final json = jsonDecode(decrypted);
      if (json is List) {
        final doc = quill.Document.fromJson(json);
        return doc.toPlainText().trim();
      }
    } catch (e) {
      // Not JSON or error parsing, return as plain text
    }
    return decrypted;
  }

  // Verify password to view secured note
  Future<bool> _verifyPasswordForNote(DocumentSnapshot note) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    final data = note.data() as Map<String, dynamic>?;
    final encryptedCustomPassword = data?['customPassword'];
    final customPassword = encryptedCustomPassword != null
        ? EncryptionHelper.decrypt(encryptedCustomPassword)
        : null;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 500,
              child: AlertDialog(
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
                      customPassword != null
                          ? "Enter your custom password:"
                          : "Enter your login password:",
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
                    onPressed: () async {
                      if (customPassword != null) {
                        if (passwordController.text.trim() == customPassword) {
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Incorrect password!"),
                            ),
                          );
                        }
                      } else {
                        try {
                          final user = FirebaseAuth.instance.currentUser!;
                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: passwordController.text.trim(),
                          );
                          await user.reauthenticateWithCredential(cred);
                          Navigator.pop(context, true);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Incorrect password!"),
                            ),
                          );
                        }
                      }
                    },
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
              ),
            );
          },
        );
      },
    );

    return confirm ?? false;
  }

  @override
  void dispose() {
    _notesSearchController.dispose();
    _simpleUtilitiesSearchController.dispose();
    _loginUtilitiesSearchController.dispose();
    super.dispose();
  }

  bool get _isSearching {
    if (_currentIndex == 0) return _isSearchingNotes;
    if (_currentIndex == 1) return _isSearchingSimpleUtilities;
    return _isSearchingLoginUtilities;
  }

  TextEditingController get _currentSearchController {
    if (_currentIndex == 0) return _notesSearchController;
    if (_currentIndex == 1) return _simpleUtilitiesSearchController;
    return _loginUtilitiesSearchController;
  }

  void _toggleSearch() {
    setState(() {
      if (_currentIndex == 0) {
        _isSearchingNotes = !_isSearchingNotes;
        if (!_isSearchingNotes) {
          _notesSearchController.clear();
          _notesSearchQuery = "";
        }
      } else if (_currentIndex == 1) {
        _isSearchingSimpleUtilities = !_isSearchingSimpleUtilities;
        if (!_isSearchingSimpleUtilities) {
          _simpleUtilitiesSearchController.clear();
          _simpleUtilitiesSearchQuery = "";
        }
      } else {
        _isSearchingLoginUtilities = !_isSearchingLoginUtilities;
        if (!_isSearchingLoginUtilities) {
          _loginUtilitiesSearchController.clear();
          _loginUtilitiesSearchQuery = "";
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C5C5C),
        elevation: 1,
        title: _isSearching
            ? TextField(
                controller: _currentSearchController,
                autofocus: true,
                cursorColor: Colors.white,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _currentIndex == 0
                      ? "Search notes..."
                      : _currentIndex == 1
                      ? "Search simple utilities..."
                      : "Search login utilities...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: InputBorder.none,
                ),
              )
            : Text(
                "$username : ${_currentIndex == 0
                    ? 'Notes'
                    : _currentIndex == 1
                    ? 'Simple Utility'
                    : 'Login Utility'}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => _buildStyledDialog(
                    title: "Confirm Logout",
                    content: "Are you sure you want to log out?",
                    positiveText: "Logout",
                    negativeText: "Cancel",
                  ),
                );
                if (confirm ?? false) {
                  await _logout();
                }
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => _buildStyledDialog(
                    title: "Delete Account",
                    content:
                        "This will permanently delete your account and all your data. Are you sure?",
                    positiveText: "Delete",
                    negativeText: "Cancel",
                    positiveColor: Colors.red,
                  ),
                );

                if (confirm ?? false) {
                  await _deleteAccount();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text("Delete Account"),
              ),
              const PopupMenuItem(value: 'logout', child: Text("Logout")),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: [
          // NOTES TAB
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(userId)
                .collection("notes")
                .orderBy("updatedAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final allNotes = snapshot.data!.docs;

              // Filter notes based on search query
              final notes = _notesSearchQuery.isEmpty
                  ? allNotes
                  : allNotes.where((note) {
                      final title = note['title'].toString().toLowerCase();
                      return title.contains(_notesSearchQuery);
                    }).toList();

              if (notes.isEmpty) {
                return Center(
                  child: Text(
                    _notesSearchQuery.isEmpty
                        ? "No notes found"
                        : "No notes match your search",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final title = note['title'];
                  // Decrypt description for preview (handle Rich Text)
                  final description = _getPreviewText(note['description']);
                  final updatedAt =
                      (note['updatedAt'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  final isSecured = note['secured'] ?? false;

                  return GestureDetector(
                    onTap: () async {
                      if (isSecured) {
                        final verified = await _verifyPasswordForNote(note);
                        if (!verified) return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotePage(note: note)),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),

                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: title + lock icon + delete
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (isSecured)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.lock,
                                          color: Colors.amber,
                                          size: 24,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  // If note is secured, verify password first
                                  if (isSecured) {
                                    final verified =
                                        await _verifyPasswordForNote(note);
                                    if (!verified) return;
                                  }

                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => _buildStyledDialog(
                                      title: "Confirm Delete",
                                      content:
                                          "Do you want to delete this note?",
                                      positiveText: "Yes",
                                      negativeText: "No",
                                    ),
                                  );
                                  if (confirm ?? false) {
                                    await note.reference.delete();
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // description
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${updatedAt.day}/${updatedAt.month}/${updatedAt.year}",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(updatedAt),
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // SIMPLE UTILITIES TAB
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(userId)
                .collection("simpleUtilities")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final allUtilities = snapshot.data!.docs;

              // Filter utilities based on search query
              final utilities = _simpleUtilitiesSearchQuery.isEmpty
                  ? allUtilities
                  : allUtilities.where((utility) {
                      final title = utility['title'].toString().toLowerCase();
                      return title.contains(_simpleUtilitiesSearchQuery);
                    }).toList();

              if (utilities.isEmpty) {
                return Center(
                  child: Text(
                    _simpleUtilitiesSearchQuery.isEmpty
                        ? "No simple utilities found"
                        : "No simple utilities match your search",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                itemCount: utilities.length,
                itemBuilder: (context, index) {
                  final utility = utilities[index];
                  final title = utility['title'] ?? '';
                  final url = utility['url'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SimpleUtilityPage(utility: utility),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
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
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => _buildStyledDialog(
                                      title: "Confirm Delete",
                                      content:
                                          "Do you want to delete this utility?",
                                      positiveText: "Yes",
                                      negativeText: "No",
                                    ),
                                  );
                                  if (confirm ?? false) {
                                    await utility.reference.delete();
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            url,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _openUrl(url),
                              child: const Text("Open URL"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // LOGIN UTILITIES TAB
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(userId)
                .collection("loginUtilities")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final allUtilities = snapshot.data!.docs;

              // Filter utilities based on search query
              final utilities = _loginUtilitiesSearchQuery.isEmpty
                  ? allUtilities
                  : allUtilities.where((utility) {
                      final title = utility['title'].toString().toLowerCase();
                      return title.contains(_loginUtilitiesSearchQuery);
                    }).toList();

              if (utilities.isEmpty) {
                return Center(
                  child: Text(
                    _loginUtilitiesSearchQuery.isEmpty
                        ? "No login utilities found"
                        : "No login utilities match your search",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                itemCount: utilities.length,
                itemBuilder: (context, index) {
                  final utility = utilities[index];
                  final title = utility['title'] ?? '';
                  final url = utility['url'] ?? '';
                  final usernameOrEmail = utility['usernameOrEmail'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginUtilityPage(utility: utility),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
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
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => _buildStyledDialog(
                                      title: "Confirm Delete",
                                      content:
                                          "Do you want to delete this utility?",
                                      positiveText: "Yes",
                                      negativeText: "No",
                                    ),
                                  );
                                  if (confirm ?? false) {
                                    await utility.reference.delete();
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const SizedBox(height: 4),
                          // Decrypt username for display
                          Text(
                            EncryptionHelper.decrypt(usernameOrEmail),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await _copyToClipboard(
                                    EncryptionHelper.decrypt(usernameOrEmail),
                                  );
                                  await _openUrl(url);
                                },
                                child: const Text("Open"),
                              ),
                              TextButton(
                                onPressed: () => _copyToClipboard(
                                  EncryptionHelper.decrypt(usernameOrEmail),
                                ),
                                child: const Text("Copy Username"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5C5C5C),
        onPressed: () {
          // Direct navigation based on current tab
          if (_currentIndex == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotePage()),
            );
          } else if (_currentIndex == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SimpleUtilityPage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginUtilityPage()),
            );
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFF5C5C5C),
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
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 40,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                    // Reset search when switching tabs
                    _isSearchingNotes = false;
                    _isSearchingSimpleUtilities = false;
                    _isSearchingLoginUtilities = false;
                    _notesSearchController.clear();
                    _simpleUtilitiesSearchController.clear();
                    _loginUtilitiesSearchController.clear();
                  });
                },
                backgroundColor: const Color(0xFF5C5C5C),
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.grey,
                selectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 9),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 2, bottom: 2),
                      child: Icon(Icons.note, size: 20),
                    ),
                    label: 'Notes',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 2, bottom: 2),
                      child: Icon(Icons.link, size: 20),
                    ),
                    label: 'Simple Utility',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 2, bottom: 2),
                      child: Icon(Icons.login, size: 20),
                    ),
                    label: 'Login Utility',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
