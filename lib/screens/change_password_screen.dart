import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/module_widgets.dart';

/// Old Password / New Password / Confirm New Password. The New and
/// Confirm fields stay locked (greyed out, untappable) until Old
/// Password is verified — checked live against the signed-in
/// account's real stored password as the person types, via
/// AuthService.verifyCurrentPassword. No separate "verify" button.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _oldPasswordVerified = false;
  bool _checkingOldPassword = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Guards against a slower, older verification check landing after
  // a newer keystroke's check already resolved — e.g. typing fast
  // then quickly backspacing could otherwise show a stale result.
  int _verifyRequestId = 0;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkOldPassword(String value) async {
    final requestId = ++_verifyRequestId;

    if (value.isEmpty) {
      setState(() {
        _oldPasswordVerified = false;
        _checkingOldPassword = false;
      });
      return;
    }

    setState(() => _checkingOldPassword = true);

    final matches = await AuthService.instance.verifyCurrentPassword(value);

    if (!mounted || requestId != _verifyRequestId) return; // stale result

    setState(() {
      _oldPasswordVerified = matches;
      _checkingOldPassword = false;
      if (!matches) {
        // Old password changed/became wrong — don't leave a stale
        // typed new password sitting around unlocked-looking.
        _successMessage = null;
      }
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_oldPasswordVerified) {
      setState(
        () => _errorMessage = 'Tama muna ang lumang password bago magpatuloy.',
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Hindi magkatugma ang bagong password.');
      return;
    }

    setState(() => _isSaving = true);

    final error = await AuthService.instance.changePassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      setState(() {
        _isSaving = false;
        _successMessage = 'Matagumpay na napalitan ang password.';
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _oldPasswordVerified = false;
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
    return ModuleScaffold(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Baguhin ang Password',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),

            // ================================================
            // OLD PASSWORD
            // ================================================
            AuthTextField(
              controller: _oldPasswordController,
              label: 'Lumang Password',
              icon: Icons.lock_outline,
              obscureText: _obscureOld,
              onChanged: _checkOldPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureOld ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscureOld = !_obscureOld),
              ),
            ),
            const SizedBox(height: 6),
            if (_checkingOldPassword)
              const Text(
                'Sinusuri...',
                style: TextStyle(
                  color: AppColors.textWhiteMuted,
                  fontSize: 12,
                ),
              )
            else if (_oldPasswordController.text.isNotEmpty)
              Text(
                _oldPasswordVerified
                    ? 'Tama ang lumang password.'
                    : 'Maling password.',
                style: TextStyle(
                  color: _oldPasswordVerified ? Colors.green : Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 20),

            // ================================================
            // NEW PASSWORD + CONFIRM — locked until old password
            // is verified above.
            // ================================================
            AbsorbPointer(
              absorbing: !_oldPasswordVerified,
              child: Opacity(
                opacity: _oldPasswordVerified ? 1 : 0.4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthTextField(
                      controller: _newPasswordController,
                      label: 'Bagong Password',
                      icon: Icons.lock,
                      obscureText: _obscureNew,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_off : Icons.visibility,
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
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _successMessage!,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 26),
            AuthButton(
              label: 'I-save',
              isLoading: _isSaving,
              onPressed: _oldPasswordVerified ? _handleSave : null,
            ),
          ],
        ),
      ),
    );
  }
}
