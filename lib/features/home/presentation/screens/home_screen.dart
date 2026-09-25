import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/app_info.dart';
import '../../../../core/widgets/medical_disclaimer.dart';
import '../widgets/home_entry_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Les parcours (choix du pays, puis listes) arrivent avec le contrat d'API.
  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Bientôt disponible')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/logo_symbol.png', height: 36),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        AppInfo.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Que recherchez-vous ?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SearchBar(onTap: () => _comingSoon(context)),
                  const SizedBox(height: AppSpacing.xl),
                  HomeEntryCard(
                    icon: Icons.healing_rounded,
                    color: AppColors.primary,
                    title: 'Maladie',
                    subtitle: 'Les plantes utilisées selon la maladie ou le symptôme',
                    onTap: () => _comingSoon(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HomeEntryCard(
                    icon: Icons.emergency_rounded,
                    color: AppColors.danger,
                    title: 'Urgences',
                    subtitle: "Plantes et gestes en cas d'urgence",
                    onTap: () => _comingSoon(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HomeEntryCard(
                    icon: Icons.spa_rounded,
                    color: AppColors.secondary,
                    title: 'Vitamines',
                    subtitle: 'Les plantes riches en vitamines A, B, C, D',
                    onTap: () => _comingSoon(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            const MedicalDisclaimer(),
          ],
        ),
      ),
    );
  }
}

/// Barre de recherche — non fonctionnelle pour l'instant, ouvre la recherche au tap.
class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.textSecondary),
              SizedBox(width: AppSpacing.md),
              Text(
                'Recherche',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
