import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../utils/app_info.dart';

/// Rappel discret pour les écrans de navigation, développé dans les fiches.
class MedicalDisclaimer extends StatelessWidget {
  const MedicalDisclaimer({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    child: Text(
      'Informations à titre indicatif. Ne remplace pas un avis médical.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    ),
  );
}

/// Avertissement intégré au contenu, sans masquer les informations à lire.
class MedicalNotice extends StatelessWidget {
  const MedicalNotice({super.key, this.emergency = false});

  final bool emergency;

  @override
  Widget build(BuildContext context) {
    final color = emergency ? AppColors.danger : AppColors.primaryDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: emergency
            ? AppColors.danger.withValues(alpha: 0.06)
            : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: emergency
            ? Border.all(color: AppColors.danger.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            emergency ? Icons.health_and_safety_outlined : Icons.info_outline,
            color: color,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emergency ? 'En cas d’urgence' : 'Avant toute utilisation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  emergency
                      ? 'Ces informations ne remplacent pas une prise en charge médicale. En cas d’urgence, contactez les secours locaux.'
                      : AppInfo.medicalDisclaimer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
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
