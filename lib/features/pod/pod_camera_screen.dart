import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/exif_writer.dart';
import '../../l10n/app_localizations.dart';
import '../../state/active_task_controller.dart';
import '../../state/app_providers.dart';

/// S5 — proof-of-delivery camera (MOB-CUR-04 / FR-DLV-03).
/// Minimal chrome; the shutter stays locked until focus settles; the order id
/// is auto-stamped into the JPEG EXIF UserComment; the captured path lands in
/// the task log and round-trips to history/earnings.
class PodCameraScreen extends ConsumerStatefulWidget {
  const PodCameraScreen({super.key, required this.taskUuid});

  final String taskUuid;

  @override
  ConsumerState<PodCameraScreen> createState() => _PodCameraScreenState();
}

class _PodCameraScreenState extends ConsumerState<PodCameraScreen> {
  CameraController? _controller;
  bool _focusStable = false;
  DateTime? _openedAt;
  bool _capturing = false;
  bool _captured = false;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) return;
      final back = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);
      final controller = CameraController(back, ResolutionPreset.high,
          enableAudio: false);
      setState(() => _controller = controller);
      await controller.initialize();
      // Focus-stability gate: request autofocus + a settle window.
      await _settleFocus(controller);
      if (!mounted) return;
      setState(() => _focusStable = true);
    } on Object {
      if (mounted) setState(() => _focusStable = false);
    }
  }

  Future<void> _settleFocus(CameraController controller) async {
    try {
      await controller.setFocusMode(FocusMode.auto);
    } on Object {
      // Focus API unsupported — the settle window still gates the shutter.
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
}

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !_focusStable || _capturing) return;
    setState(() => _capturing = true);
    try {
      final shot = await controller.takePicture();
      final bytes = await shot.readAsBytes();
      // Auto order-id metadata stamp (FR-DLV-03) — server audits via EXIF.
      final stamped =
          ExifWriter.stampUserComment(bytes, 'order_id=$_orderId');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pod_${widget.taskUuid}.jpg');
      await file.writeAsBytes(stamped, flush: true);

      await ref.read(activeTaskProvider.notifier).attachPod(file.path);
      _noteCapture();
      if (!mounted) return;
      setState(() {
        _captured = true;
        _capturing = false;
      });
    } on Object {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _noteCapture() {
    final opened = _openedAt;
    if (opened == null) return;
    final seconds = DateTime.now().difference(opened).inSeconds;
    ref.read(analyticsProvider).podCaptureSeconds(
          task: widget.taskUuid,
          seconds: seconds,
        );
  }

  String get _orderId {
    final task = ref.read(activeTaskProvider);
    return (task?.orderUuid.isNotEmpty ?? false)
        ? task!.orderUuid
        : (task?.taskUuid ?? widget.taskUuid);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.podTitle),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            CameraPreview(controller)
          else
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _focusStable ? l10n.podHint : l10n.loading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => unawaited(_capture()),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _focusStable && !_capturing
                            ? Colors.white
                            : Colors.white38,
                        width: 4,
                      ),
                    ),
                    child: _capturing
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3),
                          )
                        : Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _captured
                                    ? AppTokens.success
                                    : _focusStable
                                        ? AppTokens.offerAccent
                                        : Colors.white38,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_captured) ...[
                  const Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 40),
                  const SizedBox(height: 4),
                  FilledButton(
                    onPressed: () => unawaited(_finish(context, l10n)),
                    child: Text(l10n.podDone),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish(BuildContext context, AppLocalizations l10n) async {
    await ref.read(activeTaskProvider.notifier).markDelivered();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.deliveredConfirm),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }
}