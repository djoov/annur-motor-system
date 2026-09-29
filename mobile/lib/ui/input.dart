import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Text field styled by `AppTheme.inputDecorationTheme` (radius 14, blue focus).
class CustomInput extends StatelessWidget {
  final String placeholder;
  final String? label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final int maxLines;

  const CustomInput({
    super.key,
    required this.placeholder,
    this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.focusNode,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        focusNode: focusNode,
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: validator,
        textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        style: const TextStyle(fontSize: 15, color: AppColors.foreground),
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
