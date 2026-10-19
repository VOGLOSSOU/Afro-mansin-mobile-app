import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/catalogue.dart';
import '../controllers/catalogue_providers.dart';
import '../controllers/country_selection.dart';

class CountrySelector extends ConsumerWidget {
  const CountrySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCountryProvider);
    return selected.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => IconButton(
        tooltip: 'Réessayer de charger les pays',
        onPressed: () => ref.read(countriesProvider.notifier).reload(),
        icon: const Icon(Icons.public_off),
      ),
      data: (country) {
        if (country == null) return const Text('Aucun pays');
        final countries = ref.watch(countriesProvider).asData!.value;
        return PopupMenuButton<Country>(
          tooltip: 'Changer de pays',
          onSelected: (value) async {
            final saved = await ref
                .read(countryPreferenceProvider.notifier)
                .select(value);
            if (!saved && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Le pays est sélectionné pour cette session. Votre choix n’a pas pu être mémorisé.',
                  ),
                ),
              );
            }
          },
          itemBuilder: (_) => [
            for (final item in countries)
              CheckedPopupMenuItem(
                value: item,
                checked: item.id == country.id,
                child: Text(item.name),
              ),
          ],
          child: Semantics(
            button: true,
            label: 'Pays sélectionné : ${country.name}. Changer de pays',
            excludeSemantics: true,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 150, minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.public_rounded,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      country.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
