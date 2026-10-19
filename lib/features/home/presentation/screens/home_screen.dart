import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalogue/presentation/controllers/country_selection.dart';
import '../../../catalogue/presentation/widgets/country_selector.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/app_info.dart';
import '../../../../core/widgets/medical_disclaimer.dart';
import '../widgets/home_entry_card.dart';
import '../../../catalogue/domain/catalogue.dart';
import '../../../catalogue/presentation/catalogue_routes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final country = ref.watch(selectedCountryProvider).asData?.value;
    void open(CatalogueSection section) {
      if (country != null) {
        context.push(CatalogueRoutes.section(section));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Choisissez un pays dès que la liste est disponible.',
            ),
          ),
        );
      }
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
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
                Expanded(
                  child: Text(
                    AppInfo.name,
                    style: textTheme.headlineMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const CountrySelector(),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Que recherchez-vous ?', style: textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.lg),
            _SearchBar(onTap: () => context.push(CatalogueRoutes.search)),
            const SizedBox(height: AppSpacing.xl),
            HomeEntryCard(
              icon: Icons.medical_services_outlined,
              color: AppColors.primary,
              title: 'Maladie',
              subtitle: 'Les plantes utilisées selon la maladie ou le symptôme',
              onTap: () => open(CatalogueSection.maladies),
            ),
            const SizedBox(height: AppSpacing.md),
            HomeEntryCard(
              icon: Icons.health_and_safety_outlined,
              color: AppColors.danger,
              title: 'Urgences',
              subtitle: "Plantes et gestes en cas d'urgence",
              onTap: () => open(CatalogueSection.urgences),
            ),
            const SizedBox(height: AppSpacing.md),
            HomeEntryCard(
              icon: Icons.spa_outlined,
              color: AppColors.secondary,
              title: 'Vitamines',
              subtitle: 'Les plantes riches en vitamines A, B, C, D',
              onTap: () => open(CatalogueSection.vitamines),
            ),
            const SizedBox(height: AppSpacing.lg),
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
