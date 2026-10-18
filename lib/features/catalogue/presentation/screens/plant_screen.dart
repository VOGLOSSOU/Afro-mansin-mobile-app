import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/api/public_api.dart';
import '../../domain/catalogue.dart';
import '../catalogue_routes.dart';
import '../controllers/catalogue_providers.dart';
import '../widgets/catalogue_widgets.dart';
import '../widgets/plant_media.dart';

class PlantScreen extends ConsumerWidget {
  const PlantScreen({
    super.key,
    required this.id,
    this.recipeId,
    this.countryId,
    this.fromVitamin = false,
  });
  final int id;
  final int? recipeId, countryId;
  final bool fromVitamin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = plantProvider(id);
    final recipeValue = recipeId == null
        ? null
        : ref.watch(recipeProvider(recipeId!));
    return CataloguePage(
      title: 'Fiche plante',
      child: CatalogueAsync(
        value: ref.watch(provider),
        retry: () => ref.invalidate(provider),
        builder: (plant) => RefreshIndicator(
          onRefresh: () async {
            try {
              await Future.wait([
                ref.refresh(provider.future),
                if (recipeId != null)
                  ref.refresh(recipeProvider(recipeId!).future),
              ]);
            } catch (_) {
              // Les deux états AsyncValue affichent leurs erreurs et leurs boutons de reprise.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                plant.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(plant.scientificName, style: AppTypography.scientificName),
              if (plant.family != null)
                Text(
                  plant.family!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: AppSpacing.xl),
              CatalogueTextSection(
                title: 'Attention',
                text: plant.warning,
                warning: true,
              ),
              PlantGallery(photos: plant.photos),
              if (fromVitamin)
                const CatalogueTextSection(
                  title: 'Plante source de vitamine',
                  text:
                      'Cette fiche décrit la plante. Aucune préparation ou posologie spécifique à la vitamine n’est renseignée.',
                ),
              _LocalNames(names: plant.localNames),
              CatalogueTextSection(
                title: 'Description',
                text: plant.description,
              ),
              CatalogueTextSection(
                title: 'Répartition',
                text: plant.distribution,
              ),
              CatalogueTextSection(
                title: 'Reconnaître la plante',
                text: plant.recognition,
              ),
              CatalogueTextSection(
                title: 'Partie utile',
                text: plant.usefulPart,
              ),
              CatalogueTextSection(
                title: 'Contre-indications',
                text: plant.contraindications,
                warning: true,
                showMissing: true,
              ),
              CatalogueTextSection(
                title: 'Effets indésirables connus',
                text: plant.adverseEffects,
                warning: true,
                showMissing: true,
              ),
              if (recipeValue != null)
                _RecipeSection(
                  value: recipeValue,
                  plantId: plant.id,
                  retry: () => ref.invalidate(recipeProvider(recipeId!)),
                ),
              CatalogueTextSection(
                title: 'Référence bibliographique',
                text: plant.reference,
              ),
              _OtherRecipes(
                plant: plant,
                currentRecipeId: recipeId,
                countryId: countryId,
                fromVitamin: fromVitamin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalNames extends StatelessWidget {
  const _LocalNames({required this.names});
  final List<LocalName> names;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Noms dans les langues',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        if (names.isEmpty) const Text('Aucun nom local renseigné.'),
        for (final name in names)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.language,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Noto Sans pour tous les noms locaux, y compris les variantes multilignes.
                      SelectableText(
                        name.name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                if (name.audioUrl != null && isMediaUrl(name.audioUrl!))
                  NameAudioButton(
                    key: ValueKey('${name.language}:${name.audioUrl}'),
                    url: name.audioUrl!,
                    language: name.language,
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RecipeSection extends StatelessWidget {
  const _RecipeSection({
    required this.value,
    required this.retry,
    required this.plantId,
  });
  final AsyncValue<Recipe> value;
  final VoidCallback retry;
  final int plantId;

  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    loading: () => const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Chargement de la recette',
        ),
      ),
    ),
    error: (error, stack) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error is ApiFailure
                ? error.message
                : 'La recette n’a pas pu être chargée.',
          ),
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer la recette'),
          ),
        ],
      ),
    ),
    data: (recipe) {
      if (recipe.plantId != plantId) {
        return const CatalogueTextSection(
          title: 'Recette indisponible',
          text: 'Cette recette ne correspond pas à la plante consultée.',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatalogueHeading(
            title: 'Recette',
            subtitle: recipe.condition?.name ?? 'Indication de la plante',
            emergency: recipe.condition?.isEmergency == true,
          ),
          const SizedBox(height: AppSpacing.lg),
          CatalogueTextSection(
            title: 'Méthode de préparation',
            text: recipe.preparation,
            showMissing: true,
          ),
          CatalogueTextSection(
            title: 'Posologie',
            text: recipe.dosage,
            showMissing: true,
          ),
          CatalogueTextSection(
            title: 'Règles hygiéno-diététiques',
            text: recipe.advice,
          ),
        ],
      );
    },
  );
}

class _OtherRecipes extends StatelessWidget {
  const _OtherRecipes({
    required this.plant,
    required this.currentRecipeId,
    required this.countryId,
    required this.fromVitamin,
  });
  final Plant plant;
  final int? currentRecipeId, countryId;
  final bool fromVitamin;

  @override
  Widget build(BuildContext context) {
    final recipes = plant.recipes
        .where(
          (r) =>
              r.id != currentRecipeId &&
              (countryId == null || r.condition?.countryId == countryId),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentRecipeId == null ? 'Recettes par maladie' : 'Autres recettes',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (fromVitamin && recipes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Ces recettes concernent des maladies et ne constituent pas un mode d’emploi pour la vitamine.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (recipes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Text(
              currentRecipeId == null
                  ? 'Aucune recette renseignée pour cette plante.'
                  : 'Aucune autre recette disponible pour cette plante.',
            ),
          ),
        for (final recipe in recipes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: CatalogueTile(
              title: recipe.condition?.name ?? 'Consulter la recette',
              subtitle: recipe.condition?.countryName,
              emergency: recipe.condition?.isEmergency == true,
              onTap: () => context.push(
                CatalogueRoutes.plant(
                  plant.id,
                  recipeId: recipe.id,
                  countryId: recipe.condition?.countryId ?? countryId,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
