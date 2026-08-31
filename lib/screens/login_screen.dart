import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../constants/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      // AuthWrapper's StreamBuilder in main.dart does swap its child to
      // HomeScreen the moment sign-in succeeds — but that swap happens on
      // the ROOT route. Since LoginScreen was reached via Navigator.push
      // (not the root route itself), it sits on top of that swap and
      // hides it until popped. So we explicitly clear back to root here
      // instead of waiting on the stream.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> _showForgotPasswordDialog() async {
    String resetEmail = _emailController.text.trim();
    String? dialogError;
    bool isSending = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Reset ng Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ilagay ang iyong email. Magpapadala kami ng link para i-reset ang password.',
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: resetEmail,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      resetEmail = value;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  if (dialogError != null) ...[
                    const SizedBox(height: 10),

                    Text(
                      dialogError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),

              actions: [
                // ------------------------------------------------
                // CANCEL
                // ------------------------------------------------

                TextButton(
                  onPressed: isSending
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text(
                    'Kanselahin',
                  ),
                ),

                // ------------------------------------------------
                // SEND
                // ------------------------------------------------

                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmail.trim();

                          // Check empty email
                          if (email.isEmpty) {
                            setDialogState(() {
                              dialogError =
                                  'Ilagay ang iyong email.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSending = true;
                            dialogError = null;
                          });

                          // Send Firebase password reset email
                          final error =
                              await _authService.sendPasswordReset(
                            email,
                          );

                          // The dialog may have been closed while
                          // Firebase was processing the request.
                          if (!dialogContext.mounted) return;

                          if (error == null) {
                            // Close dialog
                            Navigator.of(dialogContext).pop();

                            // Make sure LoginScreen still exists
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Naipadala na ang email para sa pag-reset ng password.',
                                ),
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isSending = false;
                              dialogError = error;
                            });
                          }
                        },

                  child: isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Ipadala',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
            colors: [
              AppColors.deepOrange,
              AppColors.accentYellow,
            ],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // ==================================================
                // LOGO
                // ==================================================

                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,

                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons.front_hand,
                        size: 70,
                        color: AppColors.textWhite,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // LOGIN TITLE
                // ==================================================

                const Text(
                  'LOGIN',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // EMAIL
                // ==================================================

                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                ),

                const SizedBox(height: 18),

                // ==================================================
                // PASSWORD
                // ==================================================

                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: _obscurePassword,

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),

                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // FORGOT PASSWORD
                // ==================================================

                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,

                    child: const Text(
                      'Nakalimutan ang Password?',

                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // LOGIN ERROR
                // ==================================================

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),

                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: 26),

                // ==================================================
                // LOGIN BUTTON
                // ==================================================

                AuthButton(
                  label: 'Mag-log in',
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),

                const SizedBox(height: 18),

                // ==================================================
                // SIGN UP
                // ==================================================

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textWhiteMuted,
                      ),

                      children: [
                        const TextSpan(
                          text: 'Wala pang account? ',
                        ),

                        TextSpan(
                          text: 'Mag-sign up',

                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                            decoration:
                                TextDecoration.underline,
                          ),

                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SignUpScreen(),
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