import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';

/// Un campo di testo con l'etichetta sopra, come nei wireframe.
class VivoTextField extends StatelessWidget {
  const VivoTextField({
    required this.hint,
    this.label,
    this.controller,
    this.icon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.onTap,
    super.key,
  });

  final String hint;

  final String? label;

  final TextEditingController? controller;

  final IconData? icon;

  final Widget? suffix;

  final bool obscureText;

  final TextInputType? keyboardType;

  final TextInputAction? textInputAction;

  final bool readOnly;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: testi.bodySmall),
          const SizedBox(height: VivoDimens.xs),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          readOnly: readOnly,
          onTap: onTap,
          style: testi.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: VivoColors.muted),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
