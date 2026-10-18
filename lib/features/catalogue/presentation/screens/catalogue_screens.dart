import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/catalogue.dart';
import '../catalogue_routes.dart';
import '../controllers/catalogue_providers.dart';
import '../widgets/catalogue_widgets.dart';

class CountriesScreen extends ConsumerWidget {
  const CountriesScreen({super.key, required this.section});
  final CatalogueSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CataloguePage(
    title: section.label,
    child: CatalogueAsync(
      value: ref.watch(countriesProvider),
      retry: () => ref.read(countriesProvider.notifier).reload(),
      builder: (countries) => CatalogueList<Country>(
        items: countries,
        title: 'Choisissez votre pays',
        subtitle: 'Découvrez les informations disponibles dans votre contrée.',
        searchLabel: 'Rechercher un pays',
        searchText: (c) => c.name,
        emptyMessage: 'Aucun pays disponible pour le moment.',
        refresh: () => ref.read(countriesProvider.notifier).reload(),
        itemBuilder: (country) => CatalogueTile(
          title: country.name,
          icon: Icons.public_rounded,
          onTap: () => context.push(
            CatalogueRoutes.entries(section, country.id, country.name),
          ),
        ),
      ),
    ),
  );
}

class EntriesScreen extends ConsumerWidget {
  const EntriesScreen({
    super.key,
    required this.section,
    required this.countryId,
    required this.countryName,
  });
  final CatalogueSection section;
  final int countryId;
  final String countryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (section == CatalogueSection.vitamines) {
      final provider = vitaminsProvider(countryId);
      return CataloguePage(
        title: section.label,
        child: CatalogueAsync(
          value: ref.watch(provider),
          retry: () => ref.read(provider.notifier).reload(),
          builder: (items) => CatalogueList<Vitamin>(
            items: items,
            title: countryName,
            subtitle:
                'Choisissez une vitamine pour découvrir ses plantes sources.',
            searchLabel: 'Rechercher une vitamine',
            searchText: (v) => v.name,
            emptyMessage: 'Aucune vitamine renseignée pour ce pays.',
            refresh: () => ref.read(provider.notifier).reload(),
            itemBuilder: (vitamin) => CatalogueTile(
              title: vitamin.name,
              icon: Icons.spa_outlined,
              onTap: () =>
                  context.push(CatalogueRoutes.vitamin(vitamin.id, countryId)),
            ),
          ),
        ),
      );
    }
    final emergency = section == CatalogueSection.urgences;
    final provider = conditionsProvider((
      countryId: countryId,
      emergency: emergency,
    ));
    return CataloguePage(
      title: section.label,
      child: CatalogueAsync(
        value: ref.watch(provider),
        retry: () => ref.read(provider.notifier).reload(),
        builder: (items) => CatalogueList<Condition>(
          items: items,
          title: countryName,
          subtitle: emergency
              ? 'Choisissez une urgence pour consulter les informations associées.'
              : 'Choisissez une maladie ou un symptôme.',
          searchLabel: emergency
              ? 'Rechercher une urgence'
              : 'Rechercher une maladie',
          searchText: (c) => c.name,
          emptyMessage: emergency
              ? 'Aucune urgence renseignée pour ce pays.'
              : 'Aucune maladie renseignée pour ce pays.',
          refresh: () => ref.read(provider.notifier).reload(),
          itemBuilder: (condition) => CatalogueTile(
            title: condition.name,
            emergency: emergency,
            icon: emergency ? Icons.emergency_outlined : Icons.healing_rounded,
            onTap: () => context.push(
              CatalogueRoutes.condition(condition.id, countryId),
            ),
          ),
        ),
      ),
    );
  }
}

class ConditionScreen extends ConsumerWidget {
  const ConditionScreen({super.key, required this.id, required this.countryId});
  final int id, countryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = conditionProvider(id);
    return CataloguePage(
      title: 'Informations',
      child: CatalogueAsync(
        value: ref.watch(provider),
        retry: () => ref.invalidate(provider),
        builder: (condition) => RefreshIndicator(
          onRefresh: () async {
            try {
              ref.invalidate(provider);
              await ref.read(provider.future);
            } catch (_) {
              // L’erreur est présentée par CatalogueAsync, pas comme erreur de geste.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              CatalogueHeading(
                title: condition.name,
                subtitle: condition.countryName ?? 'Informations par pays',
                emergency: condition.isEmergency,
              ),
              const SizedBox(height: AppSpacing.xl),
              CatalogueTextSection(
                title: condition.isEmergency
                    ? 'À savoir avant tout'
                    : 'Règles d’hygiène',
                text: condition.hygiene,
                warning: condition.isEmergency,
              ),
              if (condition.recipes.isNotEmpty) ...[
                Text(
                  'Plantes proposées',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final recipe in condition.recipes)
                  if (recipe.plant != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: PlantTile(
                        plant: recipe.plant!,
                        onTap: () => context.push(
                          CatalogueRoutes.plant(
                            recipe.plantId,
                            recipeId: recipe.id,
                            countryId: condition.countryId,
                          ),
                        ),
                      ),
                    ),
              ],
              if (condition.methods.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Méthodes non végétales',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final method in condition.methods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: CatalogueTile(
                      title: method.method?.name ?? 'Consulter la méthode',
                      icon: Icons.health_and_safety_outlined,
                      emergency: condition.isEmergency,
                      onTap: () => context.push(
                        CatalogueRoutes.method(condition.id, method.methodId),
                      ),
                    ),
                  ),
              ],
              if (condition.recipes.isEmpty && condition.methods.isEmpty)
                const CatalogueTextSection(
                  title: 'Contenu à venir',
                  text: 'Aucune plante ou méthode renseignée pour le moment.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VitaminScreen extends ConsumerWidget {
  const VitaminScreen({super.key, required this.id, required this.countryId});
  final int id, countryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = vitaminProvider(id);
    return CataloguePage(
      title: 'Plantes sources',
      child: CatalogueAsync(
        value: ref.watch(provider),
        retry: () => ref.invalidate(provider),
        builder: (vitamin) => RefreshIndicator(
          onRefresh: () async {
            try {
              ref.invalidate(provider);
              await ref.read(provider.future);
            } catch (_) {
              // L’erreur est présentée par CatalogueAsync, pas comme erreur de geste.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              CatalogueHeading(
                title: vitamin.name,
                subtitle:
                    '${vitamin.countryName ?? 'Votre pays'} · Plantes sources',
              ),
              const SizedBox(height: AppSpacing.xl),
              const CatalogueTextSection(
                title: 'Sources végétales',
                text:
                    'Consultez les plantes associées à cette vitamine. Leur fiche permet de les reconnaître et de connaître leurs précautions.',
              ),
              if (vitamin.plants.isEmpty)
                const Text(
                  'Aucune plante source renseignée pour cette vitamine.',
                ),
              for (final plant in vitamin.plants)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PlantTile(
                    plant: plant,
                    onTap: () => context.push(
                      CatalogueRoutes.plant(
                        plant.id,
                        countryId: vitamin.countryId,
                        vitamin: true,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MethodScreen extends ConsumerWidget {
  const MethodScreen({
    super.key,
    required this.conditionId,
    required this.methodId,
  });
  final int conditionId, methodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = methodProvider((
      conditionId: conditionId,
      methodId: methodId,
    ));
    return CataloguePage(
      title: 'Méthode',
      child: CatalogueAsync(
        value: ref.watch(provider),
        retry: () => ref.invalidate(provider),
        builder: (link) => RefreshIndicator(
          onRefresh: () async {
            try {
              ref.invalidate(provider);
              await ref.read(provider.future);
            } catch (_) {
              // L’erreur est présentée par CatalogueAsync, pas comme erreur de geste.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              CatalogueHeading(
                title: link.method?.name ?? 'Méthode non végétale',
                subtitle:
                    link.condition?.name ?? 'Informations de premiers secours',
                emergency: true,
              ),
              const SizedBox(height: AppSpacing.xl),
              CatalogueTextSection(
                title: 'Instructions et précautions',
                text: link.description ?? link.method?.description,
                showMissing: true,
              ),
              if (link.description != null &&
                  link.method?.description != null &&
                  link.description != link.method?.description)
                CatalogueTextSection(
                  title: 'Informations générales',
                  text: link.method?.description,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlantSearchScreen extends ConsumerWidget {
  const PlantSearchScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CataloguePage(
    title: 'Recherche',
    child: CatalogueAsync(
      value: ref.watch(plantsProvider),
      retry: () => ref.read(plantsProvider.notifier).reload(),
      builder: (plants) => CatalogueList<Plant>(
        items: plants,
        title: 'Trouver une plante',
        subtitle:
            'Recherchez dans les plantes du catalogue par nom français, scientifique ou local.',
        searchLabel: 'Nom d’une plante',
        searchText: (p) =>
            '${p.name} ${p.scientificName} ${p.localNames.map((n) => n.name).join(' ')}',
        emptyMessage: 'Aucune plante disponible pour le moment.',
        refresh: () => ref.read(plantsProvider.notifier).reload(),
        itemBuilder: (p) => PlantTile(
          plant: p,
          onTap: () => context.push(CatalogueRoutes.plant(p.id)),
        ),
      ),
    ),
  );
}
