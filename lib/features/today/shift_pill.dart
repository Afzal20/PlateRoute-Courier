import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../state/shift_controller.dart';

/// Persistent top-right online/offline pill (MOB-CUR-01). Visible on every
/// Today state — going online is the day's first act and leaving it reachable
/// prevents stranded-offline anxiety.
class ShiftPill extends ConsumerWidget {
  const ShiftPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final shift = ref.watch(shiftProvider);
    final isOnline = shift.value?.isOnline ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ref.read(shiftProvider.notifier).toggleOnline(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(
              horizontal: Spacing.m, vertical: Spacing.s),
          decoration: BoxDecoration(
            color: isOnline
                ? AppTokens.success.withValues(alpha: 0.16)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOnline ? AppTokens.success : Theme.of(context).colorScheme.outline,
              width: AppTokens.borderStroke,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppTokens.success : Colors.transparent,
                  border: Border.all(
                    color: isOnline
                        ? AppTokens.success
                        : Theme.of(context).colorScheme.outline,
                    width: 1.5,
                  ),
                ),
              ),
              SizedBox(width: Spacing.s),
              Text(
                isOnline ? l10n.online : l10n.offline,
                style: TextStyle(
                  color: isOnline ? AppTokens.success : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                isOnline
                    ? Icons.power_settings_new
                    : Icons.power_settings_new_outlined,
                size: 16,
                color: isOnline ? AppTokens.success : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
