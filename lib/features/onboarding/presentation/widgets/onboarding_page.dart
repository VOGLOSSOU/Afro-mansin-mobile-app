import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

/// Page d'onboarding : image plein écran, ombre dégradée pour la lisibilité,
/// texte en blanc en bas de l'écran.
class OnboardingPage extends StatelessWidget {
  final String imageAsset;

  /// Cadrage de l'image quand l'écran la rogne (ex. sujet décentré).
  final Alignment imageAlignment;

  final String title;
  final String body;
  final String? note;

  /// Texte un peu plus appuyé (ex. avertissement médical).
  final bool highlightBody;

  /// Hauteur réservée en bas pour les points et le bouton de l'écran parent.
  static const double controlsHeight = 140;

  /// Hauteur réservée en haut pour le bouton « Passer ».
  static const double topBarHeight = 56;

  const OnboardingPage({
    super.key,
    required this.imageAsset,
    this.imageAlignment = Alignment.center,
    required this.title,
    required this.body,
    this.note,
    this.highlightBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final safe = MediaQuery.paddingOf(context);
    final top = safe.top + topBarHeight;
    final bottom = safe.bottom + controlsHeight;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          alignment: imageAlignment,
          // Tant que l'image n'est pas fournie : fond vert dégradé
          errorBuilder: (_, _, _) => const _FallbackBackground(),
        ),
        const _ReadabilityShade(),
        LayoutBuilder(
          builder: (context, constraints) {
            // Texte calé en bas ; défile seulement si l'écran est trop petit
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                top,
                AppSpacing.xl,
                bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - top - bottom)
                      .clamp(0.0, double.infinity),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.headlineLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      body,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textOnPrimary.withValues(
                          alpha: highlightBody ? 1 : 0.9,
                        ),
                        fontWeight: highlightBody ? FontWeight.w500 : null,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _Note(text: note!),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Ombre dégradée : légère en haut (bouton « Passer »), forte en bas (texte).
class _ReadabilityShade extends StatelessWidget {
  const _ReadabilityShade();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.2, 0.4, 0.65, 1.0],
          colors: [
            AppColors.shade.withValues(alpha: 0.45),
            AppColors.shade.withValues(alpha: 0.0),
            AppColors.shade.withValues(alpha: 0.35),
            AppColors.shade.withValues(alpha: 0.8),
            AppColors.shade.withValues(alpha: 0.92),
          ],
        ),
      ),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  const _FallbackBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
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
    final color = AppColors.textOnPrimary.withValues(alpha: 0.8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.notifications_none_rounded, size: 20, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
