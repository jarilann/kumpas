import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/module_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user?.isAnonymous ?? false;
    final email = user?.email;

    return ModuleScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentYellow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_circle, color: AppColors.textWhite, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGuest ? 'Bisita' : (email ?? 'Walang email'),
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isGuest)
                        const Text(
                          'Hindi na-save ang progreso ng bisita account',
                          style: TextStyle(color: AppColors.textWhite, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!isGuest && email != null)
            _SettingsTile(
              icon: Icons.lock_reset_rounded,
              label: 'Baguhin ang Password',
              onTap: () async {
                final error = await AuthService().sendPasswordReset(email);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error ?? 'Ipinadala ang link sa pag-reset ng password sa $email.',
                    ),
                  ),
                );
              },
            ),
          _SettingsTile(
            icon: Icons.logout_rounded,
            label: 'Mag-logout',
            onTap: () => FirebaseAuth.instance.signOut(),
            // AuthWrapper's stream picks this up and swaps back to
            // OnboardingScreen automatically — same as the home
            // screen's logout icon.
          ),
          const Spacer(),
          const Center(
            child: Text(
              'KumpasKonek v1.0.0',
              style: TextStyle(color: AppColors.textWhiteMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textWhite, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textWhiteMuted),
            ],
          ),
        ),
      ),
    );
  }
}
