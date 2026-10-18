import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalogue_repository.dart';
import '../../domain/catalogue.dart';

/// Les listes peuvent être rafraîchies/recherchées sans cache persistant.
class CatalogueListController<T> extends StateNotifier<AsyncValue<List<T>>> {
  CatalogueListController(this._load) : super(const AsyncLoading()) {
    reload();
  }
  final Future<List<T>> Function() _load;
  int _generation = 0;

  Future<void> reload() async {
    final generation = ++_generation;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(_load);
    if (mounted && generation == _generation) state = result;
  }
}

final countriesProvider =
    StateNotifierProvider.autoDispose<
      CatalogueListController<Country>,
      AsyncValue<List<Country>>
    >(
      (ref) => CatalogueListController(
        ref.watch(catalogueRepositoryProvider).countries,
      ),
    );

final plantsProvider =
    StateNotifierProvider.autoDispose<
      CatalogueListController<Plant>,
      AsyncValue<List<Plant>>
    >(
      (ref) => CatalogueListController(
        ref.watch(catalogueRepositoryProvider).plants,
      ),
    );

typedef ConditionQuery = ({int countryId, bool emergency});
final conditionsProvider = StateNotifierProvider.autoDispose
    .family<
      CatalogueListController<Condition>,
      AsyncValue<List<Condition>>,
      ConditionQuery
    >((ref, query) {
      final repository = ref.watch(catalogueRepositoryProvider);
      return CatalogueListController(
        () =>
            repository.conditions(query.countryId, emergency: query.emergency),
      );
    });
final vitaminsProvider = StateNotifierProvider.autoDispose
    .family<CatalogueListController<Vitamin>, AsyncValue<List<Vitamin>>, int>((
      ref,
      countryId,
    ) {
      final repository = ref.watch(catalogueRepositoryProvider);
      return CatalogueListController(() => repository.vitamins(countryId));
    });

// Un fetch de détail propre, jamais une fiche construite depuis une liste incomplète.
final conditionProvider = FutureProvider.autoDispose.family<Condition, int>((
  ref,
  id,
) {
  ref.keepAlive();
  return ref.watch(catalogueRepositoryProvider).condition(id);
});
final vitaminProvider = FutureProvider.autoDispose.family<Vitamin, int>((
  ref,
  id,
) {
  ref.keepAlive();
  return ref.watch(catalogueRepositoryProvider).vitamin(id);
});
final plantProvider = FutureProvider.autoDispose.family<Plant, int>((ref, id) {
  ref.keepAlive();
  return ref.watch(catalogueRepositoryProvider).plant(id);
});
final recipeProvider = FutureProvider.autoDispose.family<Recipe, int>((
  ref,
  id,
) {
  ref.keepAlive();
  return ref.watch(catalogueRepositoryProvider).recipe(id);
});
typedef MethodQuery = ({int conditionId, int methodId});
final methodProvider = FutureProvider.autoDispose
    .family<MethodLink, MethodQuery>((ref, query) {
      ref.keepAlive();
      return ref
          .watch(catalogueRepositoryProvider)
          .method(query.conditionId, query.methodId);
    });
