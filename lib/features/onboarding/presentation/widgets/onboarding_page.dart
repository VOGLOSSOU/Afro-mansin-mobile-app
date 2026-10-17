import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String? note;

  /// Met le texte en avant dans un encadré (ex. avertissement médical) au lieu
  /// d'un paragraphe centré.
  final bool highlightBody;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.note,
    this.highlightBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // L'illustration rétrécit sur les petits écrans pour laisser la place au texte
        final isCompact = constraints.maxHeight < 520;
        final illustrationSize =
            (constraints.maxHeight * (isCompact ? 0.2 : 0.26)).clamp(72.0, 168.0);

        // Scrollable en dernier recours (très petits écrans / grandes polices)
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              // Placeholder en attendant les illustrations
              Container(
                width: illustrationSize,
                height: illustrationSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: illustrationSize * 0.48, color: color),
              ),
              SizedBox(height: isCompact ? AppSpacing.lg : AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (highlightBody)
                _HighlightedBody(text: body, color: color)
              else
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              if (note != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _Note(text: note!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HighlightedBody extends StatelessWidget {
  final String text;
  final Color color;

  const _HighlightedBody({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;

  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
