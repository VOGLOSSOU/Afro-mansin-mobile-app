import 'package:afro_mansin/core/api/public_api.dart';
import 'package:afro_mansin/features/catalogue/data/catalogue_repository.dart';
import 'package:afro_mansin/features/catalogue/presentation/controllers/catalogue_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalogue_test_support.dart';

void main() {
  late CatalogueAdapter adapter;
  late CatalogueRepository repository;
  setUp(() {
    adapter = CatalogueAdapter();
    repository = CatalogueRepository(PublicApi(catalogueDio(adapter)));
  });

  test(
    'Maladies ordinaires : omission de false et exclusion des urgences',
    () async {
      final result = await repository.conditions(1, emergency: false);
      expect(result.map((c) => c.name), ['Constipation']);
      expect(adapter.requests.single.queryParameters, {'id_contree': 1});
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
      expect(adapter.requests.single.method, 'GET');
    },
  );

  test(
    'Urgences : filtre true, méthode liée et description de l’association',
    () async {
      expect((await repository.conditions(1, emergency: true)).single.id, 2);
      expect(adapter.requests.last.queryParameters['est_urgence'], true);
      final condition = await repository.condition(2);
      expect(condition.recipes, isEmpty);
      expect(condition.methods.single.methodId, 1);
      final method = await repository.method(2, 1);
      expect(method.description, contains('20 minutes'));
      expect(method.condition?.name, 'Brûlure thermique');
    },
  );

  test(
    'Fiche détaillée : noms multilignes, champs null et recette distincte',
    () async {
      final plant = await repository.plant(1);
      expect(plant.family, isNull);
      expect(plant.photos, isEmpty);
      expect(plant.localNames, hasLength(4));
      expect(
        plant.localNames.firstWhere((n) => n.language == 'Fon').name,
        contains('\n'),
      );
      expect(plant.localNames.every((n) => n.audioUrl == null), isTrue);
      expect(plant.recipes.single.condition?.countryId, 1);
      final recipe = await repository.recipe(1);
      expect(recipe.plantId, plant.id);
      expect(recipe.preparation, contains('20 grammes'));
      expect(recipe.advice, isNull);
    },
  );

  test(
    'Vitamine C : plante source ; aucune recette vitaminique inventée',
    () async {
      final vitamin = await repository.vitamin(1);
      expect(vitamin.name, 'Vitamine C');
      expect(vitamin.plants.single.id, 4);
      expect(vitamin.plants.single.recipes, isEmpty);
    },
  );

  test('Liste vide et réponse invalide sont distinguées', () async {
    adapter.responses['/vitamines'] = [];
    expect(await repository.vitamins(1), isEmpty);
    adapter.responses['/vitamines'] = {'data': []};
    await expectLater(repository.vitamins(1), throwsA(isA<ApiFailure>()));
  });

  test(
    'Erreurs réseau et 404 sont converties en erreurs utilisables',
    () async {
      adapter.offline = true;
      await expectLater(
        repository.countries(),
        throwsA(isA<ApiFailure>().having((e) => e.isOffline, 'offline', true)),
      );
      adapter.offline = false;
      await expectLater(
        repository.plant(999),
        throwsA(isA<ApiFailure>().having((e) => e.statusCode, 'status', 404)),
      );
    },
  );

  test(
    'Un chargement tardif ne remplace pas le résultat d’une relance',
    () async {
      var call = 0;
      final controller = CatalogueListController<int>(() async {
        final current = ++call;
        await Future<void>.delayed(
          Duration(milliseconds: current == 1 ? 20 : 1),
        );
        return [current];
      });
      await controller.reload();
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(controller.state.asData?.value, [2]);
      controller.dispose();
    },
  );
}
