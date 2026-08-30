import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/active_task_controller.dart';
import '../../state/offers_controller.dart';
import '../offline/offline_ui.dart';
import '../shared/widgets.dart';
import 'active_task_card.dart';
import 'offer_card.dart';
import 'shift_pill.dart';

/// S2 — Today (bottom tab 1): shift pill top-right on every state, offer
/// feed pinned TOP, active task card, offline queue banner (design §5/§6).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final offers = ref.watch(offersProvider);
    final activeTask = ref.watch(activeTaskProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.today),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ShiftPill(),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineQueueBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(offersProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Offers live pinned at the TOP of the list — thumb-stable
                  // even when scrolled (design §6 Flow A).
                  ...offers.when(
                    data: (list) => [
                      for (final offer in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OfferCard(
                            key: ValueKey('offer_${offer.id}'),
                            offer: offer,
                          ),
                        ),
                    ],
                    loading: () => const [
                      Center(child: CircularProgressIndicator()),
                    ],
                    error: (e, _) => [
                      PanelCard(
                        child: Text(l10n.errorGeneric,
                            style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),

                  // In-place transform: after a claim the ActiveTaskCard takes
                  // this slot without any navigation jump.
                  if (activeTask != null) ...[
                    const SizedBox(height: 8),
                    const ActiveTaskCard(),
                  ] else if (offers.value?.isEmpty ?? false) ...[
                    const SizedBox(height: 32),
                    Icon(Icons.inbox_outlined,
                        size: 48, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(height: 12),
                    Text(l10n.noOffers,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(l10n.noOffersHint,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
