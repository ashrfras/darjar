import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_country_code_picker.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DarJarInternationalPhoneField extends StatelessWidget {
  const DarJarInternationalPhoneField({
    required this.controller,
    required this.countryCode,
    required this.onCountryCodeChanged,
    required this.phoneLabel,
    required this.countryCodeLabel,
    this.fieldKey,
    this.countryCodeKey,
    super.key,
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final String phoneLabel;
  final String countryCodeLabel;
  final Key? fieldKey;
  final Key? countryCodeKey;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: DarJarCountryCodePickerField(
              key: countryCodeKey,
              value: countryCode,
              label: countryCodeLabel,
              onChanged: onCountryCodeChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: DarJarTextField(
                key: fieldKey,
                controller: controller,
                label: phoneLabel,
                labelAsHint: true,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s-]')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
