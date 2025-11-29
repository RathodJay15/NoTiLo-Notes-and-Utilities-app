import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final authService = AuthService();
  await authService.enforceRememberMeOnStartup();

  runApp(const RestartWidget(child: MyApp()));
}

class RestartWidget extends StatefulWidget {
  final Widget child;
  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: key, child: widget.child);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notilo',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,

        //  this block for consistent dark grey borders on TextFields
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF5C5C5C), width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF5C5C5C), width: 1.0),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF5C5C5C)),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),

        //  Ensures focus color (cursor, highlight) also uses grey instead of blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF5C5C5C),
          primary: Color(0xFF5C5C5C),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isLoggedIn = user != null;
      _isLoading = false;
    });

    // Listen to auth state changes and log them
    FirebaseAuth.instance.authStateChanges().listen((user) {
      print('authStateChanges: ${user?.uid ?? "null (signed out)"}');
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
        });
      }
    });
    
    // Also listen to token changes for debugging
    FirebaseAuth.instance.idTokenChanges().listen((user) {
      print('idTokenChanges: ${user?.uid ?? "null"}');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5C5C5C)),
        ),
      );
    }

    return _isLoggedIn ? const HomePage() : const LoginPage();
  }
}
