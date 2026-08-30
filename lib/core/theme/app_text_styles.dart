import 'package:flutter/material.dart';

class AppTextStyles {
  // One size up from customer ramp per specs (Body 17, Body S 15)
  // Weight skews Medium/SemiBold due to glare.

  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500, // Medium
    fontFamily: 'Inter',
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
  );

  static const TextStyle offerTotal = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700, // Bold
    fontFamily: 'Inter',
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle countdownDigits = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700, // Bold
    fontFamily: 'Inter',
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700, // Bold
    fontFamily: 'Inter',
  );
  
  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600, // SemiBold
    fontFamily: 'Inter',
  );
}
