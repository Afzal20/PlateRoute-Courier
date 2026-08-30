import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/geo.dart';
import '../../l10n/app_localizations.dart';

/// Giant address block (design §6 Flow B): venue name prominent over street.
///
/// The current backend offer payload carries only coordinates, so the block
/// renders the derived zone word + an honest coordinate line instead of
/// inventing a venue name. When the server adds `venue`/`street` fields they
/// surface automatically via [venue]/[street].
class AddressBlock extends StatelessWidget {
  const AddressBlock({
    super.key,
    required this.lat,
    required this.lng,
    required this.isNear,
    this.venue,
    this.street,
  });

  final double lat;
  final double lng;
  final String? venue;
  final String? street;

  /// Geofence hint: flips the border blue and swaps the hint line
  /// ("You are near the gate") using location accuracy thresholds.
  final bool isNear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent =
        isNear ? theme.colorScheme.primary : theme.colorScheme.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: EdgeInsets.all(Spacing.l),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: accent, width: isNear ? 2 : AppTokens.borderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(venue ?? Geo.zoneWordOf(lat, lng),
              style: theme.textTheme.titleLarge),
          SizedBox(height: Spacing.xs),
          Text(
            street ?? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: Spacing.s),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isNear
                ? Row(
                    key: const ValueKey('near'),
                    children: [
                      Icon(Icons.flag_outlined,
                          size: 16, color: theme.colorScheme.primary),
                      SizedBox(width: Spacing.xs),
                      Text(
                        l10n.nearGate,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('far'),
                    children: [
                      const Icon(Icons.route_outlined,
                          size: 16, color: AppTokens.neutralMiss),
                      SizedBox(width: Spacing.xs),
                      Text(l10n.stageToPickup,
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Distance chip text: "2.4 km pickup - 3.1 km drop".
String distanceChipText(String pickup, String drop) =>
    '$pickup pickup - $drop drop';

/// Motion-gated inert summary strip: a breathing outline above ~7 km/h.
/// No interactive children render inside — taps route through the gate.
class MotionSummaryStrip extends StatefulWidget {
  const MotionSummaryStrip({super.key, required this.label});

  final String label;

  @override
  State<MotionSummaryStrip> createState() => _MotionSummaryStripState();
}

class _MotionSummaryStripState extends State<MotionSummaryStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) => Container(
        width: double.infinity,
        padding:
            EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.m),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline
                .withValues(alpha: 0.35 + 0.3 * _breath.value),
            width: AppTokens.borderStroke,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car_filled_outlined,
                size: 18, color: AppTokens.neutralMiss),
            SizedBox(width: Spacing.s),
            Expanded(
              child: Text(
                widget.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTokens.neutralMiss),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
