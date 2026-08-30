/*
A text field on the dark ground.

Sign in and register are the only two screens in the app on a dark surface - they are the
app introducing itself, before there is any content to show - so they are the only two
that need an inverted field. Everything else uses the theme's field, which is built for
the chalk-coloured screens.

Written once here rather than a second full InputDecorationTheme, because two screens do
not justify a theme, and because a second theme is a thing that quietly drifts out of step
with the first.
*/

import 'package:flutter/material.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';

class SlDarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  // One short line under the field, for something the label cannot say on its own.
  final String? helper;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final TextCapitalization textCapitalization;
  final bool obscure;
  final String? Function(String?)? validator;

  // Shown at the right of the field - the eye that reveals a password.
  final Widget? suffix;

  const SlDarkField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.obscure = false,
    this.validator,
    this.suffix,
  });

  // The error colour has to be legible on deep teal, so it is a light clay rather
  // than the clay used on white.
  static const Color _errorOnDark = Color(0xFFFFC2B4);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      obscureText: obscure,
      validator: validator,
      style: AppType.b(AppType.body, color: AppPalette.onDark),
      cursorColor: AppPalette.onDark,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        suffixIcon: suffix,
        filled: true,
        fillColor: AppPalette.onDark.withValues(alpha: 0.08),
        labelStyle: AppType.b(
          AppType.body,
          color: AppPalette.onDark.withValues(alpha: 0.7),
          size: 14,
        ),
        floatingLabelStyle: AppType.b(
          AppType.meta,
          color: AppPalette.onDark.withValues(alpha: 0.9),
        ),
        helperStyle: AppType.b(
          AppType.meta,
          color: AppPalette.onDark.withValues(alpha: 0.6),
          size: 12,
        ),
        errorStyle: AppType.b(AppType.meta, color: _errorOnDark, size: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppPalette.onDark.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppPalette.onDark.withValues(alpha: 0.85),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _errorOnDark),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _errorOnDark, width: 1.6),
        ),
      ),
    );
  }
}
