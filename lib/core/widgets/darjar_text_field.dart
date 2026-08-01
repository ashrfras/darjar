import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DarJarTextField extends StatelessWidget {
  const DarJarTextField({
    required this.label,
    this.hint,
    this.helper,
    this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixText,
    this.inputFormatters,
    this.textInputAction,
    this.textDirection,
    this.textCapitalization = TextCapitalization.none,
    this.labelAsHint = false,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final String? hint;
  final String? helper;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;
  final TextCapitalization textCapitalization;
  final bool labelAsHint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

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
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: labelAsHint ? null : label,
        hintText: labelAsHint ? (hint ?? label) : hint,
        hintMaxLines: 1,
        helperText: helper,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixText: suffixText,
      ),
    );
  }
}
