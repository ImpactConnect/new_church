import 'package:flutter/material.dart';
import 'package:cms/src/core/theme.dart';

/// Standard page header used across all CMS screens.
class CmsPageHeader extends StatelessWidget {
  const CmsPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: CmsTheme.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: CmsTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// Standard CMS card container.
class CmsCard extends StatelessWidget {
  const CmsCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: child,
    );
  }
}

/// Status badge chip (active/inactive/transferred/pending/approved/rejected).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (Color, String) _resolve(String s) => switch (s) {
    'active' => (CmsTheme.success, 'Active'),
    'inactive' => (CmsTheme.textMuted, 'Inactive'),
    'transferred' => (CmsTheme.info, 'Transferred'),
    'pending' => (CmsTheme.warning, 'Pending'),
    'approved' => (CmsTheme.success, 'Approved'),
    'rejected' => (CmsTheme.danger, 'Rejected'),
    'not-disbursed' => (CmsTheme.textMuted, 'Not Disbursed'),
    'partially-disbursed' => (CmsTheme.warning, 'Partial'),
    'fully-disbursed' => (CmsTheme.success, 'Fully Disbursed'),
    _ => (CmsTheme.textMuted, s),
  };
}

/// Primary CMS button.
class CmsButton extends StatelessWidget {
  const CmsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = CmsButtonVariant.primary,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final CmsButtonVariant variant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 6),
              ],
              Text(label),
            ],
          );

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 11);

    return switch (variant) {
      CmsButtonVariant.primary => ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(padding: padding),
        child: child,
      ),
      CmsButtonVariant.secondary => OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(padding: padding),
        child: child,
      ),
      CmsButtonVariant.danger => ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: CmsTheme.danger,
          foregroundColor: Colors.white,
          padding: padding,
        ),
        child: child,
      ),
    };
  }
}

enum CmsButtonVariant { primary, secondary, danger }

/// Search field widget.
class CmsSearchField extends StatelessWidget {
  const CmsSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search…',
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter', fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 16, color: CmsTheme.textMuted),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

/// Empty state placeholder.
class CmsEmptyState extends StatelessWidget {
  const CmsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: CmsTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 32, color: CmsTheme.textMuted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CmsTheme.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: CmsTheme.textSecondary,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool danger = false,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: CmsTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: danger
              ? ElevatedButton.styleFrom(backgroundColor: CmsTheme.danger)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  ) ?? false;
}
