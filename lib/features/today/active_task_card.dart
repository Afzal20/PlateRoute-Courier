import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/location_service.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/geo.dart';
import '../../data/models/offer.dart';
import '../../l10n/app_localizations.dart';
import '../../state/active_task_controller.dart';
import '../../state/motion_controller.dart';
import '../shared/widgets.dart';
import 'address_block.dart';
import 'cod_box.dart';
import 'pull_over_sheet.dart';

/// S4 — stage-driven tri-panel (design §6 Flow B):
///  toPickup -> at_vendor: pickup address, [Navigate][Call restaurant][Chat]
///  out (picked): dropoff address, [Navigate][Call customer]
///  atDropoff: unlocks the Delivered flow (POD camera).
class ActiveTaskCard extends ConsumerWidget {
  const ActiveTaskCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final task = ref.watch(activeTaskProvider);
    final motion = ref.watch(motionProvider);
    if (task == null) return const SizedBox.shrink();

    final dropoffSide = task.stage.isDropoffSide;
    final fix = motion.latest;
    final isNear = dropoffSide
        ? LocationService.isNearGeofence(fix, task.dropoffLat, task.dropoffLng)
        : LocationService.isNearGeofence(fix, task.pickupLat, task.pickupLng);
    final distToTarget = fix == null
        ? null
        : (dropoffSide
            ? Geo.haversineM(fix.lat, fix.lng, task.dropoffLat, task.dropoffLng)
            : Geo.haversineM(fix.lat, fix.lng, task.pickupLat, task.pickupLng));
    final moving = motion.isMoving;

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InlineChip(
                label: _stageLabel(l10n, task.stage),
                color: theme.colorScheme.primary,
              ),
              const Spacer(),
              if (distToTarget != null)
                Text(Geo.humanDistance(distToTarget),
                    style: theme.textTheme.labelMedium),
            ],
          ),
          SizedBox(height: Spacing.m),
          if (moving)
            MotionSummaryStrip(label: l10n.motionSummary)
          else ...[
            AddressBlock(
              lat: dropoffSide ? task.dropoffLat : task.pickupLat,
              lng: dropoffSide ? task.dropoffLng : task.pickupLng,
              isNear: isNear,
            ),
            SizedBox(height: Spacing.m),
            Text(l10n.etaMinutes(task.promisedEtaMinutes),
                style: theme.textTheme.bodySmall),
            SizedBox(height: Spacing.m),
            CodBox(amountMinor: task.codMinor),
            SizedBox(height: Spacing.m),
            _actions(context, ref, l10n, task, moving),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, WidgetRef ref, AppLocalizations l10n,
      dynamic task, bool moving) {
    // [Navigate 64dp][Call 56dp rows][stage action] — motion gate routes
    // Navigate through the pull-over sheet; calls are always exempt (§10).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: moving
              ? () => _gate(context)
              : () => unawaited(_navigate(task)),
          icon: const Icon(Icons.navigation_outlined),
          label: Text(l10n.navigateBtn),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppTokens.primaryActionHeight),
          ),
        ),
        SizedBox(height: Spacing.s),
        Row(
          children: [
            Expanded(
              child: SecondaryActionButton(
                label: task.stage.isDropoffSide
                    ? l10n.callCustomer
                    : l10n.callVendor,
                icon: Icons.call_outlined,
                onPressed: () => unawaited(_call()),
              ),
            ),
            SizedBox(width: Spacing.s),
            Expanded(
              child: SecondaryActionButton(
                label: l10n.callExempt,
                icon: Icons.support_agent_outlined,
                onPressed: () => unawaited(_call()),
              ),
            ),
          ],
        ),
        SizedBox(height: Spacing.m),
        FilledButton.tonal(
          onPressed: () => unawaited(_advance(context, ref, l10n, task)),
          style: FilledButton.styleFrom(
            minimumSize:
                const Size.fromHeight(AppTokens.secondaryActionHeight),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: Text(_stageAction(l10n, task.stage)),
        ),
      ],
    );
  }

  String _stageLabel(AppLocalizations l10n, TripStage stage) =>
      switch (stage) {
        TripStage.toPickup || TripStage.atVendor => l10n.stageToPickup,
        TripStage.picked => l10n.stagePicked,
        TripStage.out => l10n.stageOut,
        TripStage.atDropoff => l10n.stageAtDropoff,
        TripStage.delivered => l10n.deliveredConfirm,
      };

  String _stageAction(AppLocalizations l10n, TripStage stage) =>
      switch (stage) {
        TripStage.toPickup => l10n.atVendorBtn,
        TripStage.atVendor => l10n.pickedBtn,
        TripStage.picked || TripStage.out => l10n.arrivedStep,
        TripStage.atDropoff => l10n.podTitle,
        TripStage.delivered => l10n.deliveredConfirm,
      };

  Future<void> _advance(BuildContext context, WidgetRef ref,
      AppLocalizations l10n, dynamic task) async {
    if (task.stage == TripStage.atDropoff) {
      // Delivered flow: POD camera with order id auto-stamped (FR-DLV-03).
      unawaited(context.push('/pod/${task.taskUuid}'));
      return;
    }
    final result = await ref.read(activeTaskProvider.notifier).advanceStage();
    if (result == StageResult.queued && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorNetwork)),
      );
    }
  }

  Future<void> _navigate(dynamic task) async {
    final (lat, lng) = task.stage.isDropoffSide
        ? (task.dropoffLat, task.dropoffLng)
        : (task.pickupLat, task.pickupLng);
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call() async {
    // Platform dialer keeps the call UI out of our chrome; motion-gate exempt.
    await launchUrl(Uri.parse('tel:'));
  }

  void _gate(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const PullOverSheet(),
    );
  }
}
