import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DarJarTextField extends StatelessWidget {
  const DarJarTextField({
    required this.label,
    this.hint,
    this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixText,
    this.inputFormatters,
    this.textInputAction,
    this.textDirection,
    super.key,
  });

  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      textDirection: textDirection,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixText: suffixText,
      ),
    );
  }
}
