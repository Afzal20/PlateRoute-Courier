import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/haptics_service.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/geo.dart';
import '../../core/utils/money.dart';
import '../../data/models/offer.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_providers.dart';
import '../../state/motion_controller.dart';
import '../../state/offers_controller.dart';
import '../shared/widgets.dart';
import 'address_block.dart';
import 'countdown_ring.dart';

enum _CardState { live, claiming, claimedFirst, missed }

/// S3 — pinned-top OfferCard. Payout in offerAccent 24 Bold tabular,
/// 120dp CountdownRing, distance chip + zone word, atomic claim morph.
/// Loss states are neutral gray, never red (no shame screens).
class OfferCard extends ConsumerStatefulWidget {
  const OfferCard({
    super.key,
    required this.offer,
    this.onClaimResult,
  });

  final Offer offer;
  final void Function(ClaimOutcome outcome)? onClaimResult;

  @override
  ConsumerState<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends ConsumerState<OfferCard> {
  _CardState _state = _CardState.live;
  bool _dismissScheduled = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final offer = widget.offer;
    final motion = ref.watch(motionProvider);

    // Neutral gray loss cards auto-dismiss: "Claimed first" 3s, missed 4s.
    if (_state == _CardState.claimedFirst) {
      _scheduleDismiss(const Duration(seconds: 3));
      return PanelCard(
        child: SizedBox(
          height: 96,
          child: Center(
            child: Text(l10n.claimedFirst,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppTokens.neutralMiss)),
          ),
        ),
      );
    }
    if (_state == _CardState.missed) {
      _scheduleDismiss(const Duration(seconds: 4));
      return PanelCard(
        child: SizedBox(
          height: 96,
          child: Center(
            child: Text(l10n.missedOffer,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppTokens.neutralMiss)),
          ),
        ),
      );
    }

    final moving = motion.isMoving;
    return PanelCard(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _state == _CardState.claiming
            ? _claimingBody(theme, l10n)
            : _liveBody(context, l10n, theme, offer, moving),
      ),
    );
  }

  void _scheduleDismiss(Duration duration) {
    if (_dismissScheduled) return;
    _dismissScheduled = true;
    Future.delayed(duration, () {
      if (mounted) unawaited(ref.read(offersProvider.notifier).refresh());
    });
  }

  Widget _liveBody(BuildContext context, AppLocalizations l10n,
      ThemeData theme, Offer offer, bool moving) {
    final fix = ref.watch(motionProvider).latest;
    final pickupM = fix == null
        ? 0.0
        : Geo.haversineM(fix.lat, fix.lng, offer.pickupLat, offer.pickupLng);
    final dropM = Geo.haversineM(
        offer.pickupLat, offer.pickupLng, offer.dropoffLat, offer.dropoffLng);

    return Column(
      key: const ValueKey('live'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (moving)
          MotionSummaryStrip(label: l10n.motionSummary)
        else ...[
          Row(
            children: [
              CountdownRing(
                expiresAt: offer.expiresAt,
                onTick: (_) =>
                    ref.read(hapticsProvider).play(HapticFamily.offerTick),
                onExpired: () => setState(() => _state = _CardState.missed),
              ),
              SizedBox(width: Spacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Money.bdt(offer.feeMinor),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: AppTokens.offerTotalSize,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.offerAccent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox(height: Spacing.xs),
                    Text(
                      l10n.distanceChip(
                        Geo.humanDistance(pickupM),
                        Geo.humanDistance(dropM),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(height: Spacing.s),
                    InlineChip(
                      label: Geo.zoneWordOf(offer.dropoffLat, offer.dropoffLng),
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Spacing.m),
          FilledButton(
            onPressed: () => unawaited(_claim()),
            child: Text(l10n.claimBtn),
          ),
          SizedBox(height: Spacing.s),
          OutlinedButton(
            onPressed: () => unawaited(
                ref.read(offersProvider.notifier).decline(offer)),
            child: Text(l10n.declineBtn),
          ),
        ],
      ],
    );
  }

  Future<void> _claim() async {
    setState(() => _state = _CardState.claiming);
    final ClaimOutcome outcome;
    try {
      outcome = await ref.read(offersProvider.notifier).claim(widget.offer);
    } on Object {
      if (mounted) setState(() => _state = _CardState.live);
      return;
    }
    if (!mounted) return;
    switch (outcome) {
      case ClaimOutcome.won:
      case ClaimOutcome.queued:
        widget.onClaimResult?.call(outcome);
      case ClaimOutcome.lost:
        setState(() => _state = _CardState.claimedFirst);
        widget.onClaimResult?.call(outcome);
    }
  }

  Widget _claimingBody(ThemeData theme, AppLocalizations l10n) {
    return SizedBox(
      key: const ValueKey('claiming'),
      height: 190,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
            SizedBox(height: Spacing.m),
            Text(l10n.claiming, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
