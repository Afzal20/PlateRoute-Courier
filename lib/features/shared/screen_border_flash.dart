import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Screen-border flash (design §8): 300ms glare-legible redundancy for
/// sound/haptic events. Listens to the app-wide Haptics borderFlash stream.
class ScreenBorderFlash extends StatefulWidget {
  const ScreenBorderFlash({super.key, required this.child, this.flashes});

  final Widget child;
  final Stream<Duration>? flashes;

  @override
  State<ScreenBorderFlash> createState() => _ScreenBorderFlashState();
}

class _ScreenBorderFlashState extends State<ScreenBorderFlash> {
  StreamSubscription<Duration>? _sub;
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub?.cancel();
    final stream = widget.flashes;
    if (stream != null) {
      _sub = stream.listen((window) {
        if (!mounted) return;
        setState(() => _visible = true);
        _hideTimer?.cancel();
        _hideTimer = Timer(window, () {
          if (mounted) setState(() => _visible = false);
        });
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTokens.offerAccent,
                    width: 6,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
