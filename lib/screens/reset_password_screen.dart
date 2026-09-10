import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

/// Offline stand-in for "forgot password" — no email service to send
/// a real link through, so Email + Nickname (the display name set at
/// signup) together stand in for proof of ownership. Once both match
/// a real account, New Password / Confirm New Password unlock.
///
/// This is demo-grade identity verification, not real security — a
/// nickname isn't a secret. Fine for an offline prototype.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _identityVerified = false;
  bool _checkingIdentity = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Guards against a slower, older check landing after a newer one
  // already resolved (e.g. typing fast in either field).
  int _verifyRequestId = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkIdentity() async {
    final email = _emailController.text.trim();
    final nickname = _nicknameController.text.trim();
    final requestId = ++_verifyRequestId;

    if (email.isEmpty || nickname.isEmpty) {
      setState(() {
        _identityVerified = false;
        _checkingIdentity = false;
      });
      return;
    }

    setState(() => _checkingIdentity = true);

    final matches = await AuthService.instance.verifyIdentityForReset(
      email,
      nickname,
    );

    if (!mounted || requestId != _verifyRequestId) return; // stale result

    setState(() {
      _identityVerified = matches;
      _checkingIdentity = false;
      if (!matches) _successMessage = null;
    });
  }

  Future<void> _handleReset() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_identityVerified) {
      setState(
        () => _errorMessage =
            'Kailangan tugma muna ang email at palayaw bago magpatuloy.',
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Hindi magkatugma ang bagong password.');
      return;
    }

    setState(() => _isSaving = true);

    final error = await AuthService.instance.resetPassword(
      email: _emailController.text.trim(),
      nickname: _nicknameController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      setState(() {
        _isSaving = false;
        _successMessage =
            'Matagumpay na na-reset ang password. Maaari ka nang mag-log in.';
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _identityVerified = false;
      });
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = error;
      });
    }
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'I-reset ang Password',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ilagay ang iyong email at palayaw para i-verify ang iyong account.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // EMAIL + NICKNAME — identity verification
                // ==========================================
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  onChanged: (_) => _checkIdentity(),
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  controller: _nicknameController,
                  label: 'Palayaw',
                  icon: Icons.badge_outlined,
                  onChanged: (_) => _checkIdentity(),
                ),
                const SizedBox(height: 6),
                if (_checkingIdentity)
                  const Text(
                    'Sinusuri...',
                    style: TextStyle(color: AppColors.textWhite, fontSize: 12),
                  )
                else if (_emailController.text.isNotEmpty &&
                    _nicknameController.text.isNotEmpty)
                  Text(
                    _identityVerified
                        ? 'Na-verify ang account.'
                        : 'Walang account na tumutugma sa email at palayaw na ito.',
                    style: TextStyle(
                      color: _identityVerified
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 20),

                // ==========================================
                // NEW PASSWORD + CONFIRM — locked until
                // identity above is verified.
                // ==========================================
                AbsorbPointer(
                  absorbing: !_identityVerified,
                  child: Opacity(
                    opacity: _identityVerified ? 1 : 0.4,
                    child: Column(
                      children: [
                        AuthTextField(
                          controller: _newPasswordController,
                          label: 'Bagong Password',
                          icon: Icons.lock,
                          obscureText: _obscureNew,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AuthTextField(
                          controller: _confirmPasswordController,
                          label: 'Kumpirmahin ang Bagong Password',
                          icon: Icons.lock,
                          obscureText: _obscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                if (_successMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _successMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                const SizedBox(height: 26),
                AuthButton(
                  label: 'I-reset ang Password',
                  isLoading: _isSaving,
                  onPressed: _identityVerified ? _handleReset : null,
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
