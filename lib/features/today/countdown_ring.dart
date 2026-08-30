import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// 120dp countdown ring around the offer payout (design §6 Flow A).
/// Urgency is encoded redundantly — never hue alone:
///  1. ring position (arc sweep shrinks with remaining time)
///  2. text label (seconds remaining in the ring center)
///  3. haptic cadence driven by the caller (family B ticks)
///  4. final-8s crimson pulse, one pulse per second
class CountdownRing extends StatefulWidget {
  const CountdownRing({
    super.key,
    required this.expiresAt,
    this.size = AppTokens.countdownRingDiameter,
    this.onTick,
    this.onExpired,
  });

  final DateTime expiresAt;

  /// Fired each second with the seconds remaining (>= 0). Used for family-B
  /// ticks during the final 8 seconds.
  final void Function(int secondsRemaining)? onTick;
  final VoidCallback? onExpired;
  final double size;

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _ticker;
  int _secondsRemaining = 0;
  int _lastTickedSecond = -1;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _update();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  @override
  void didUpdateWidget(CountdownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) _update();
  }

  void _update() {
    final remaining =
        widget.expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 999);
    setState(() => _secondsRemaining = remaining);
    final urgency = remaining > 0 && remaining <= 8;
    if (urgency && _lastTickedSecond != remaining) {
      _lastTickedSecond = remaining;
      widget.onTick?.call(remaining);
      _pulse.forward(from: 0);
    }
    if (remaining == 0 && _lastTickedSecond != 0) {
      _lastTickedSecond = 0;
      widget.onExpired?.call();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWindow = 30; // nominal ring window for the arc sweep
    final fraction =
        (_secondsRemaining / totalWindow).clamp(0.04, 1.0);
    final urgent = _secondsRemaining <= 8;
    final ringColor = urgent ? AppTokens.danger : AppTokens.offerAccent;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => CustomPaint(
              painter: _RingPainter(
                fraction: fraction,
                color: ringColor,
                track: Theme.of(context).colorScheme.outline,
                pulseAlpha: urgent && _secondsRemaining > 0
                    ? (1 - _pulse.value) * 0.35
                    : 0,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_secondsRemaining',
                  style: TextStyle(
                    fontSize: AppTokens.countdownSize,
                    fontWeight: FontWeight.w700,
                    color: ringColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  's',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
    required this.pulseAlpha,
  });

  final double fraction;
  final Color color;
  final Color track;
  final double pulseAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 6.0;
    final rect = Offset.zero & size;
    rect.deflate(stroke);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (pulseAlpha > 0) {
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 8 * (1 - pulseAlpha)
        ..color = color.withValues(alpha: pulseAlpha);
      canvas.drawArc(rect, 0, math.pi * 2, false, pulsePaint);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = color;
    // Start at 12 o'clock, sweep clockwise.
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.pulseAlpha != pulseAlpha;
}
