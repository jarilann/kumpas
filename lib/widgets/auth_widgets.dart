import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

// ------------------------------------------------------------
// STYLED TEXT FIELD
// Used for Username/Email and Password
// ------------------------------------------------------------

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textWhite,
          ),
        ),

        const SizedBox(height: 8),

        // Text field
        TextField(
          controller: controller,
          obscureText: obscureText,

          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),

          decoration: InputDecoration(
            // Left icon
            prefixIcon: Icon(
              icon,
              color: AppColors.accentYellow,
              size: 27,
            ),

            // Password eye icon
            suffixIcon: suffixIcon,

            // White box
            filled: true,
            fillColor: Colors.white,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),

            // Normal
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            // Not focused
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            // Focused
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.accentYellow,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// AUTH BUTTON
// Used for Mag-log in / Mag-sign up
// ------------------------------------------------------------

class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.textWhite,

          padding: const EdgeInsets.symmetric(
            vertical: 17,
          ),

          elevation: 3,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textWhite,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
      ),
    );
  }
}