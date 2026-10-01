import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import '../widgets/auth_card.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _rememberMe = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
      return;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _authService.setRememberMe(_rememberMe);
      // authStateChanges in main.dart handles navigation automatically
    } on FirebaseAuthException catch (e) {
      setState(() {
        _passwordError = e.message ?? 'Login failed: ${e.code}';
      });
    } catch (e) {
      setState(() {
        _passwordError = 'Login failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email first');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: AuthCard(
        title: 'Sign In to continue',
        children: [
          CustomTextField(
            controller: _emailController,
            labelText: 'Email',
            errorText: _emailError,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            isPassword: true,
            errorText: _passwordError,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (val) {
                  setState(() => _rememberMe = val ?? false);
                },
                activeColor: AppColors.primary,
              ),
              Text(
                'Remember me',
                style: GoogleFonts.poppins(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Login',
            isLoading: _isLoading,
            onPressed: _login,
          ),
          const SizedBox(height: 26),
          GestureDetector(
            onTap: _forgotPassword,
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegistrationScreen(),
                ),
              );
            },
            child: Text(
              "Don't have an account? Sign Up",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
