import 'package:flutter/material.dart';

/// Design tokens from `COURIER_APP_UI.md` §3 (dark-first palette contract).
///
/// Rules baked in here:
///  - OLED-friendly true dark canvas; cards separate by tone + border.
///  - **No shadows anywhere** — "sun kills shadows"; elevation is borders.
///  - `offerAccent` yellow is reserved for money/urgency, never errors.
///  - `danger` never appears inside offers (no shame screens).
abstract final class AppTokens {
  // ---- Dark (default) ----
  static const darkCanvas = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF16213A);
  static const darkBorder = Color(0xFF2C3A55);
  static const darkTextPrimary = Color(0xFFF1F5FB);
  static const darkTextSecondary = Color(0xFFA9B6C9);
  static const darkPrimary = Color(0xFF60A5FA); // 7.0:1 on canvas

  // ---- Light (mirrors customer palette) ----
  static const lightCanvas = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF475569);
  static const lightPrimary = Color(0xFF2563EB);

  // ---- Shared accents ----
  static const offerAccent = Color(0xFFFACC15); // glare-legible yellow
  static const ctaBackground = Color(0xFF2563EB); // white bold label = AA
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFEF4444); // hard failures only
  static const neutralMiss = Color(0xFF64748B); // "Claimed first" gray

  // ---- Type ramp (one size up from customer app) ----
  static const bodySize = 17.0;
  static const bodySmallSize = 15.0;
  static const offerTotalSize = 24.0;
  static const countdownSize = 40.0;

  // ---- Touch floors ----
  static const primaryActionHeight = 64.0;
  static const secondaryActionHeight = 56.0;
  static const countdownRingDiameter = 120.0;
  static const borderStroke = 1.5;

  // ---- Motion gating ----
  static const motionSpeedThresholdMps = 1.95; // ~7 km/h
  static const geofenceNearMeters = 60.0;
}

/// Gloves mode multiplier — applied via spacing tokens only, never per-screen.
abstract final class Spacing {
  static const double _base = 4.0;

  /// 1.0 normally, 1.25 in gloves mode (set by [GlovesScope]).
  static double multiplier = 1.0;

  static double get xs => _base * 1 * multiplier; // 4dp
  static double get s => _base * 2 * multiplier; // 8dp
  static double get m => _base * 3 * multiplier; // 12dp
  static double get l => _base * 4 * multiplier; // 16dp
  static double get xl => _base * 6 * multiplier; // 24dp
  static double get xxl => _base * 8 * multiplier; // 32dp
}

/// InheritedWidget so gloves mode re-resolves spacing without rebuilding
/// every token reference by hand.
class GlovesScope extends InheritedWidget {
  const GlovesScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static double multiplierOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlovesScope>()?.enabled ?? false
          ? 1.25
          : 1.0;

  @override
  bool updateShouldNotify(GlovesScope oldWidget) =>
      oldWidget.enabled != enabled;
}
