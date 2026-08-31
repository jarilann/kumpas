import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../constants/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Pakilagay ang iyong palayaw.');
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Hindi magkatugma ang password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.signUp(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      // Save the full name to the Firebase user profile.
      await _authService.updateDisplayName(_nameController.text.trim());
    }

    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });

    // On success, AuthWrapper's StreamBuilder in main.dart detects the
    // newly signed-in user and navigates to HomeScreen automatically.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.deepOrange, AppColors.accentYellow],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // ------------------------------------------------
                // LOGO
                // ------------------------------------------------
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.front_hand,
                        size: 70,
                        color: AppColors.textWhite,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------
                const Text(
                  'GUMAWA NG\nACCOUNT',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // NICKNAME
                // ------------------------------------------------
                AuthTextField(
                  controller: _nameController,
                  label: 'Palayaw/Nickname',
                  icon: Icons.badge,
                ),
                const SizedBox(height: 18),

                // ------------------------------------------------
                // EMAIL
                // ------------------------------------------------
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                ),
                const SizedBox(height: 18),

                // ------------------------------------------------
                // PASSWORD
                // ------------------------------------------------
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // ------------------------------------------------
                // CONFIRM PASSWORD
                // ------------------------------------------------
                AuthTextField(
                  controller: _confirmController,
                  label: 'Kumpirmahin ang Password',
                  icon: Icons.lock,
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 26),

                // ------------------------------------------------
                // SIGN UP BUTTON
                // ------------------------------------------------
                AuthButton(
                  label: 'Mag-sign up',
                  isLoading: _isLoading,
                  onPressed: _handleSignUp,
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // "MAY ACCOUNT KA NA? MAG-LOG IN"
                // ------------------------------------------------
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textWhiteMuted,
                      ),
                      children: [
                        const TextSpan(text: 'May account ka na? '),
                        TextSpan(
                          text: 'Mag-log in',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}