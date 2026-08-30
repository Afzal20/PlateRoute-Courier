import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// 64dp full-width CTA (Accept task, Navigate, Arrived) — bottom anchored by
/// the caller. White bold >=18sp on #2563EB = large-text AA at 3.0+.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 22), SizedBox(width: Spacing.s)],
        Text(label),
      ],
    );
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(
          expanded ? double.infinity : 0,
          AppTokens.primaryActionHeight,
        ),
      ),
      child: leading ?? child,
    );
  }
}

/// 56dp secondary action (Call / Chat) in context strips.
class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppTokens.secondaryActionHeight),
      ),
    );
  }
}

/// Mandatory-outline card (no shadows — sun kills shadows).
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).colorScheme.outline;
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(Spacing.l),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? border,
          width: AppTokens.borderStroke,
        ),
      ),
      child: child,
    );
  }
}

/// Small inline chip. Disabled entirely in gloves mode (design §4: smallest
/// chips are disabled behind the single gloves toggle).
class InlineChip extends StatelessWidget {
  const InlineChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.outline;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: Spacing.s, vertical: Spacing.xs),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: c),
          ),
        ],
      ),
    );
  }
}
