import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/api/public_api.dart';
import '../../../../core/widgets/medical_disclaimer.dart';
import '../../domain/catalogue.dart';

class CataloguePage extends StatelessWidget {
  const CataloguePage({
    super.key,
    required this.title,
    required this.child,
    this.showDisclaimer = true,
    this.actions,
  });
  final String title;
  final Widget child;
  final bool showDisclaimer;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: child,
              ),
            ),
          ),
          if (showDisclaimer) ...[
            const Divider(height: 1, color: AppColors.border),
            const MedicalDisclaimer(),
          ],
        ],
      ),
    ),
  );
}

class CatalogueAsync<T> extends StatelessWidget {
  const CatalogueAsync({
    super.key,
    required this.value,
    required this.retry,
    required this.builder,
  });
  final AsyncValue<T> value;
  final VoidCallback retry;
  final Widget Function(T) builder;

  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    loading: () => const Center(
      child: CircularProgressIndicator(
        semanticsLabel: 'Chargement du catalogue',
      ),
    ),
    error: (error, _) => CatalogueMessage(
      icon: error is ApiFailure && error.isOffline
          ? Icons.wifi_off_rounded
          : Icons.cloud_off_rounded,
      title: error is ApiFailure && error.isOffline
          ? 'Pas de connexion internet'
          : 'Contenu indisponible',
      message: error is ApiFailure
          ? error.message
          : 'Impossible de charger ce contenu. Réessayez.',
      action: retry,
    ),
    data: builder,
  );
}

class CatalogueMessage extends StatelessWidget {
  const CatalogueMessage({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.eco_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Recherche locale dans une liste reçue ; aucun paramètre search non supporté.
class CatalogueList<T> extends StatefulWidget {
  const CatalogueList({
    super.key,
    required this.items,
    required this.title,
    required this.subtitle,
    required this.searchLabel,
    required this.searchText,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.refresh,
  });
  final List<T> items;
  final String title, subtitle, searchLabel, emptyMessage;
  final String Function(T) searchText;
  final Widget Function(T) itemBuilder;
  final Future<void> Function() refresh;

  @override
  State<CatalogueList<T>> createState() => _CatalogueListState<T>();
}

class _CatalogueListState<T> extends State<CatalogueList<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = normalizeSearch(_query.trim());
    final items = widget.items
        .where(
          (item) => normalizeSearch(widget.searchText(item)).contains(query),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: widget.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CatalogueHeading(title: widget.title, subtitle: widget.subtitle),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              labelText: widget.searchLabel,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${items.length} résultat${items.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                widget.items.isEmpty
                    ? widget.emptyMessage
                    : 'Aucun résultat pour cette recherche.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: widget.itemBuilder(item),
            ),
        ],
      ),
    );
  }
}

String normalizeSearch(String value) {
  var result = value.toLowerCase();
  const groups = {
    'àâäáãå': 'a',
    'éèêë': 'e',
    'îïíì': 'i',
    'ôöóòõ': 'o',
    'ùûüú': 'u',
    'ç': 'c',
  };
  for (final group in groups.entries) {
    for (final letter in group.key.characters) {
      result = result.replaceAll(letter, group.value);
    }
  }
  return result;
}

class CatalogueHeading extends StatelessWidget {
  const CatalogueHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.emergency = false,
  });
  final String title, subtitle;
  final bool emergency;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: emergency
          ? AppColors.danger.withValues(alpha: 0.07)
          : AppColors.primarySurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: emergency ? AppColors.danger : AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

class CatalogueTile extends StatelessWidget {
  const CatalogueTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.scientificName,
    this.icon = Icons.eco_outlined,
    this.emergency = false,
  });
  final String title;
  final String? subtitle, scientificName;
  final IconData icon;
  final bool emergency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              icon,
              color: emergency ? AppColors.danger : AppColors.primary,
              size: 30,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (scientificName != null)
                    Text(scientificName!, style: AppTypography.scientificName),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

class PlantTile extends StatelessWidget {
  const PlantTile({super.key, required this.plant, required this.onTap});
  final Plant plant;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CatalogueTile(
    title: plant.name,
    scientificName: plant.scientificName,
    onTap: onTap,
  );
}

class CatalogueTextSection extends StatelessWidget {
  const CatalogueTextSection({
    super.key,
    required this.title,
    this.text,
    this.warning = false,
    this.showMissing = false,
  });
  final String title;
  final String? text;
  final bool warning, showMissing;
  @override
  Widget build(BuildContext context) {
    if (text == null && !showMissing) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Container(
        width: double.infinity,
        padding: warning
            ? const EdgeInsets.all(AppSpacing.lg)
            : EdgeInsets.zero,
        decoration: warning
            ? BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.25),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: warning ? AppColors.danger : null,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              text ?? 'Non renseigné',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
