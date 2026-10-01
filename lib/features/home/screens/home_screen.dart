import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/password_prompt_dialog.dart';
import '../../auth/services/auth_service.dart';
import '../../notes/screens/note_editor_screen.dart';
import '../../notes/screens/notes_tab.dart';
import '../../simple_utility/screens/simple_utility_form_screen.dart';
import '../../simple_utility/screens/simple_utility_tab.dart';
import '../../login_utility/screens/login_utility_form_screen.dart';
import '../../login_utility/screens/login_utility_tab.dart';
import '../widgets/home_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'User';
  int _currentIndex = 0;

  bool _isSearchingNotes = false;
  bool _isSearchingSimpleUtilities = false;
  bool _isSearchingLoginUtilities = false;

  final TextEditingController _notesSearchController = TextEditingController();
  final TextEditingController _simpleUtilitiesSearchController =
      TextEditingController();
  final TextEditingController _loginUtilitiesSearchController =
      TextEditingController();

  String _notesSearchQuery = '';
  String _simpleUtilitiesSearchQuery = '';
  String _loginUtilitiesSearchQuery = '';

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
        _simpleUtilitiesSearchQuery =
            _simpleUtilitiesSearchController.text.toLowerCase();
      });
    });

    _loginUtilitiesSearchController.addListener(() {
      setState(() {
        _loginUtilitiesSearchQuery =
            _loginUtilitiesSearchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _notesSearchController.dispose();
    _simpleUtilitiesSearchController.dispose();
    _loginUtilitiesSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _username = doc.data()?['username'] ?? 'User';
        });
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;

      final password = await PasswordPromptDialog.showForPasswordInput(
        context,
        title: 'Re-authenticate',
        promptMessage:
            'Please enter your password to confirm account deletion.',
        confirmButtonText: 'Delete',
      );

      if (password == null || password.isEmpty) return;

      // Re-authenticate user
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      // Delete user's data subcollections
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final notes = await userRef.collection('notes').get();
      for (var doc in notes.docs) {
        await doc.reference.delete();
      }

      final simpleUtilities =
          await userRef.collection('simpleUtilities').get();
      for (var doc in simpleUtilities.docs) {
        await doc.reference.delete();
      }

      final loginUtilities = await userRef.collection('loginUtilities').get();
      for (var doc in loginUtilities.docs) {
        await doc.reference.delete();
      }

      // Delete main user document
      await userRef.delete();

      // Clear remember_me preference
      final authService = AuthService();
      await authService.setRememberMe(false);

      // Delete Firebase Auth account
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account and all data deleted successfully',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error deleting account: ${e.message}';
      if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Please try again.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage, style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting account: $e',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    }
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
          _notesSearchQuery = '';
        }
      } else if (_currentIndex == 1) {
        _isSearchingSimpleUtilities = !_isSearchingSimpleUtilities;
        if (!_isSearchingSimpleUtilities) {
          _simpleUtilitiesSearchController.clear();
          _simpleUtilitiesSearchQuery = '';
        }
      } else {
        _isSearchingLoginUtilities = !_isSearchingLoginUtilities;
        if (!_isSearchingLoginUtilities) {
          _loginUtilitiesSearchController.clear();
          _loginUtilitiesSearchQuery = '';
        }
      }
    });
  }

  String get _currentTabTitle {
    switch (_currentIndex) {
      case 0:
        return 'Notes';
      case 1:
        return 'Simple Utility';
      case 2:
      default:
        return 'Login Utility';
    }
  }

  String get _searchHintText {
    switch (_currentIndex) {
      case 0:
        return 'Search notes...';
      case 1:
        return 'Search simple utilities...';
      case 2:
      default:
        return 'Search login utilities...';
    }
  }

  void _onFabPressed() {
    if (_currentIndex == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
      );
    } else if (_currentIndex == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SimpleUtilityFormScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginUtilityFormScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 1,
        title: _isSearching
            ? TextField(
                controller: _currentSearchController,
                autofocus: true,
                cursorColor: Colors.white,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _searchHintText,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: InputBorder.none,
                ),
              )
            : Text(
                '$_username : $_currentTabTitle',
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
                final confirm = await AppDialog.showConfirmation(
                  context,
                  title: 'Confirm Logout',
                  content: 'Are you sure you want to log out?',
                  positiveText: 'Logout',
                  negativeText: 'Cancel',
                );
                if (confirm) {
                  await _logout();
                }
              } else if (value == 'delete') {
                final confirm = await AppDialog.showConfirmation(
                  context,
                  title: 'Delete Account',
                  content:
                      'This will permanently delete your account and all your data. Are you sure?',
                  positiveText: 'Delete',
                  negativeText: 'Cancel',
                  positiveColor: AppColors.error,
                );
                if (confirm) {
                  await _deleteAccount();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Account'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          NotesTab(
            userId: userId,
            searchQuery: _notesSearchQuery,
          ),
          SimpleUtilityTab(
            userId: userId,
            searchQuery: _simpleUtilitiesSearchQuery,
          ),
          LoginUtilityTab(
            userId: userId,
            searchQuery: _loginUtilitiesSearchQuery,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _onFabPressed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _isSearchingNotes = false;
            _isSearchingSimpleUtilities = false;
            _isSearchingLoginUtilities = false;
            _notesSearchController.clear();
            _simpleUtilitiesSearchController.clear();
            _loginUtilitiesSearchController.clear();
          });
        },
      ),
    );
  }
}
