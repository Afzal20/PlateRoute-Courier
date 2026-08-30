import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Haptic families A–E (COURIER_APP_UI.md §8). Vibration outranks audio:
/// helmets muffle speakers. Every family also fires [borderFlash] so the
/// screen border flashes 300ms — glare-legible redundancy for sound events.
enum HapticFamily {
  /// A — new task offer: strong double pulse.
  newOffer,

  /// B — offer final 8 seconds: escalating short buzz per tick.
  offerTick,

  /// C — claim result: win = medium, lose = none (no shame buzz).
  claimWin,

  /// D — stage unlocked (arrived, picked): P2 short-tick.
  stageUnlock,

  /// E — incoming call: continuous ring, must be [stopRing]ed.
  incomingCall,
}

class Haptics {
  Haptics();

  final _borderFlashController = StreamController<Duration>.broadcast();

  /// Emits a 300ms (or longer for family A) flash window per event.
  Stream<Duration> get borderFlash => _borderFlashController.stream;

  Future<void> play(HapticFamily family) async {
    switch (family) {
      case HapticFamily.newOffer:
        _flash(const Duration(milliseconds: 450));
        await _vibrate(pattern: [0, 60, 90, 60], intensities: [0, 255, 0, 220]);
      case HapticFamily.offerTick:
        _flash(const Duration(milliseconds: 300));
        await _vibrate(pattern: [0, 35], intensities: [0, 200]);
      case HapticFamily.claimWin:
        _flash(const Duration(milliseconds: 300));
        await _vibrate(pattern: [0, 80], intensities: [0, 160]);
      case HapticFamily.stageUnlock:
        _flash(const Duration(milliseconds: 300));
        HapticFeedback.mediumImpact();
      case HapticFamily.incomingCall:
        _flash(const Duration(milliseconds: 900));
        await _vibrate(pattern: [0, 400, 200, 400], repeat: 1);
    }
  }

  Future<void> stopRing() => safeVibrateCancel();

  Future<void> safeVibrateCancel() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  void _flash(Duration window) {
    if (!_borderFlashController.isClosed) _borderFlashController.add(window);
  }

  Future<void> _vibrate(
      {List<int> pattern = const [0, 80],
      List<int> intensities = const [0, 255],
      int repeat = -1}) async {
    if (kIsWeb) return;
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
            pattern: pattern, intensities: intensities, repeat: repeat);
      }
    } catch (_) {
      // Emulators without a vibrator must never crash the shift.
      HapticFeedback.mediumImpact();
    }
  }
}
