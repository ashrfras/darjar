import 'package:flutter/material.dart';

class DarJarTextField extends StatelessWidget {
  const DarJarTextField({
    required this.label,
    this.hint,
    this.prefixIcon,
    this.controller,
    super.key,
  });

  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}
