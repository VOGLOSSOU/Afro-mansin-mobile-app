import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/app_info.dart';
import '../../../../core/widgets/medical_disclaimer.dart';
import '../widgets/home_entry_card.dart';
import '../../../catalogue/domain/catalogue.dart';
import '../../../catalogue/presentation/catalogue_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                      Text(AppInfo.name, style: textTheme.headlineMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Que recherchez-vous ?', style: textTheme.headlineLarge),
                  const SizedBox(height: AppSpacing.lg),
                  _SearchBar(onTap: () => context.push(CatalogueRoutes.search)),
                  const SizedBox(height: AppSpacing.xl),
                  HomeEntryCard(
                    icon: Icons.healing_rounded,
                    color: AppColors.primary,
                    title: 'Maladie',
                    subtitle:
                        'Les plantes utilisées selon la maladie ou le symptôme',
                    onTap: () => context.push(
                      CatalogueRoutes.countries(CatalogueSection.maladies),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HomeEntryCard(
                    icon: Icons.emergency_rounded,
                    color: AppColors.danger,
                    title: 'Urgences',
                    subtitle: "Plantes et gestes en cas d'urgence",
                    onTap: () => context.push(
                      CatalogueRoutes.countries(CatalogueSection.urgences),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HomeEntryCard(
                    icon: Icons.spa_rounded,
                    color: AppColors.secondary,
                    title: 'Vitamines',
                    subtitle: 'Les plantes riches en vitamines A, B, C, D',
                    onTap: () => context.push(
                      CatalogueRoutes.countries(CatalogueSection.vitamines),
                    ),
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

/// Ouvre la recherche locale dans le catalogue public.
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
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Recherche',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
