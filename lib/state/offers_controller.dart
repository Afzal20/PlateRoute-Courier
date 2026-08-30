import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/queue/offline_queue.dart';
import '../core/services/haptics_service.dart';
import '../data/models/offer.dart';
import 'active_task_controller.dart';
import 'app_providers.dart';
import 'auth_controller.dart';

/// Offer feed (MOB-CUR-02). Polls every 15s while online (WS push is the
/// future upgrade; polling keeps offers truthful without a socket), fires
/// haptic family A on arrival, and drives the atomic claim.
class OffersController extends AsyncNotifier<List<Offer>> {
  Timer? _poll;
  final Set<String> _seenTasks = {};

  static const pollInterval = Duration(seconds: 15);

  @override
  Future<List<Offer>> build() async {
    ref.onDispose(() => _poll?.cancel());
    final user = ref.watch(authProvider).value;
    if (user == null) {
      _poll?.cancel();
      return const [];
    }
    final offers = await _fetch();
    _startPoll();
    return offers;
  }

  Future<List<Offer>> _fetch() async {
    try {
      final offers = await ref.read(courierRepositoryProvider).fetchOffers();
      final now = DateTime.now();
      final fresh = offers.where((o) => !o.isExpiredAt(now)).toList();
      // Family A + instrumentation on first sight of an offer.
      for (final offer in fresh) {
        if (_seenTasks.add(offer.taskUuid)) {
          ref.read(hapticsProvider).play(HapticFamily.newOffer);
          ref.read(analyticsProvider).offerShown(
                task: offer.taskUuid,
                feeMinor: offer.feeMinor,
              );
        }
      }
      return fresh;
    } on ApiException {
      return state.value ?? const [];
    }
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(pollInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    state = AsyncData(await _fetch());
  }

  /// Atomic claim with in-place outcome (FR-DLV-03):
  ///  - success -> ActiveTaskController takes over, offer feed refreshes
  ///  - claim lost -> [ApiException.isClaimLost]; UI shows neutral gray card
  ///  - offline -> queued; UI reflects Local-saved chip
  Future<ClaimOutcome> claim(Offer offer) async {
    final analytics = ref.read(analyticsProvider);
    final shownAt = _shownAt[offer.taskUuid] ?? DateTime.now();
    final responseMs = DateTime.now().difference(shownAt).inMilliseconds;
    final ringSecond = offer.expiresAt.difference(DateTime.now()).inSeconds;
    try {
      final task = await ref.read(courierRepositoryProvider).claim(offer);
      analytics.offerResponseMs(task: offer.taskUuid, responseMs: responseMs);
      analytics.claimResult(
          task: offer.taskUuid, success: true, ringSecond: ringSecond, responseMs: responseMs);
      ref.read(hapticsProvider).play(HapticFamily.claimWin);
      await ref.read(activeTaskProvider.notifier).setFromClaim(task);
      unawaited(refresh());
      return ClaimOutcome.won;
    } on ApiException catch (e) {
      if (e.isClaimLost) {
        analytics.claimResult(
            task: offer.taskUuid, success: false, ringSecond: ringSecond, responseMs: responseMs);
        unawaited(refresh());
        return ClaimOutcome.lost;
      }
      if (e.isNetwork) {
        // Queue the claim; it reconciles on flush (MOB-CUR-07).
        await ref.read(offlineQueueProvider).enqueue(QueueItem(
              id: 'claim_${offer.id}',
              type: QueueActionType.claimOffer,
              payload: {'offer_id': offer.id, 'task': offer.taskUuid},
              createdAt: DateTime.now(),
            ));
        return ClaimOutcome.queued;
      }
      rethrow;
    }
  }

  Future<void> decline(Offer offer) async {
    try {
      await ref.read(courierRepositoryProvider).decline(offer);
    } on ApiException catch (e) {
      if (e.isNetwork) {
        await ref.read(offlineQueueProvider).enqueue(QueueItem(
              id: 'decline_${offer.id}',
              type: QueueActionType.declineOffer,
              payload: {'offer_id': offer.id},
              createdAt: DateTime.now(),
            ));
      } else {
        rethrow;
      }
    }
    unawaited(refresh());
  }

  final Map<String, DateTime> _shownAt = {};

  void markShown(Offer offer) {
    _shownAt.putIfAbsent(offer.taskUuid, DateTime.now);
  }
}

enum ClaimOutcome { won, lost, queued }

final offersProvider =
    AsyncNotifierProvider<OffersController, List<Offer>>(OffersController.new);
