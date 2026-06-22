import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

/// Wordmark logo: "Pitch To Picture" with the middle word in gold.
class PtpLogo extends StatelessWidget {
  const PtpLogo({super.key, this.fontSize = 28});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: 0.5,
    );
    return RichText(
      text: TextSpan(
        style: base,
        children: const [
          TextSpan(text: 'Pitch '),
          TextSpan(text: 'To ', style: TextStyle(color: AppColors.gold)),
          TextSpan(text: 'Picture'),
        ],
      ),
    );
  }
}
