import 'package:afro_mansin/app/router/app_router.dart';
import 'package:afro_mansin/core/api/public_api.dart';
import 'package:afro_mansin/features/catalogue/presentation/catalogue_routes.dart';
import 'package:afro_mansin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afro_mansin/features/catalogue/presentation/controllers/country_selection.dart';

import 'catalogue_test_support.dart';

void main() {
  late CatalogueAdapter adapter;
  setUp(() {
    adapter = CatalogueAdapter();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> start(
    WidgetTester tester, {
    String location = AppRoutes.home,
    double scale = 1,
    Size size = const Size(430, 932),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = createAppRouter(initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicApiProvider.overrideWithValue(PublicApi(catalogueDio(adapter))),
          appRouterProvider.overrideWithValue(router),
        ],
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: const AmaApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final matches = find.text(text);
    if (matches.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        matches,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    final target = matches.last;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Maladies : accueil directement sur le pays par défaut puis recette',
    (tester) async {
      await start(tester);
      await tapText(tester, 'Maladie');
      expect(find.text('Choisissez votre pays'), findsNothing);
      expect(find.text('Brûlure thermique'), findsNothing);
      await tapText(tester, 'Constipation');
      await tapText(tester, 'Séné africain');
      expect(find.text('Cassia italica'), findsOneWidget);
      expect(find.text('Aucune photo disponible'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Posologie'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Boire un grand verre avant de se coucher'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.volume_up_outlined), findsNothing);
      expect(adapter.requests.any((r) => r.path == '/plantes/1'), isTrue);
      expect(adapter.requests.any((r) => r.path == '/indications/1'), isTrue);
      expect(
        adapter.requests.every(
          (r) => r.method == 'GET' && !r.headers.containsKey('Authorization'),
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Urgences : méthode non végétale sans plante fictive', (
    tester,
  ) async {
    await start(tester);
    await tapText(tester, 'Urgences');
    await tapText(tester, 'Brûlure thermique');
    await tapText(tester, 'Refroidissement d’une brûlure thermique');
    expect(find.text('Instructions et précautions'), findsOneWidget);
    expect(
      adapter.requests.any((r) => r.path == '/indications-methode/2/1'),
      isTrue,
    );
    expect(
      adapter.requests.any((r) => r.path.startsWith('/plantes/')),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Vitamines : fiche source sans préparation affichée automatiquement',
    (tester) async {
      await start(tester);
      await tapText(tester, 'Vitamines');
      await tapText(tester, 'Vitamine C');
      await tapText(tester, 'Orange(r) doux');
      expect(find.text('Plante source de vitamine'), findsOneWidget);
      expect(find.text('Méthode de préparation'), findsNothing);
      expect(
        adapter.requests.any((r) => r.path.startsWith('/indications/')),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Changer de pays recharge la rubrique et mémorise le choix', (
    tester,
  ) async {
    adapter.responses['/contrees'] = [
      {'id_contree': 7, 'nom': 'Togo'},
      {'id_contree': 1, 'nom': 'Bénin'},
    ];
    await start(tester);
    expect(find.text('Bénin'), findsOneWidget);
    await tapText(tester, 'Maladie');
    await tester.tap(find.byTooltip('Changer de pays'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('Togo'),
        matching: find.byWidgetPredicate(
          (widget) => widget is CheckedPopupMenuItem,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Aucune maladie renseignée pour ce pays.'),
      findsOneWidget,
    );
    expect(
      adapter.requests.any(
        (r) => r.path == '/maladies' && r.queryParameters['id_contree'] == 7,
      ),
      isTrue,
    );
    expect(
      (await SharedPreferences.getInstance()).getInt(CountryPreference.key),
      7,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Togo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Le pays mémorisé est restauré au démarrage', (tester) async {
    adapter.responses['/contrees'] = [
      {'id_contree': 1, 'nom': 'Bénin'},
      {'id_contree': 7, 'nom': 'Togo'},
    ];
    SharedPreferences.setMockInitialValues({CountryPreference.key: 7});
    await start(tester);
    expect(find.text('Togo'), findsOneWidget);
    await tapText(tester, 'Urgences');
    expect(
      find.text('Aucune urgence renseignée pour ce pays.'),
      findsOneWidget,
    );
  });

  testWidgets('Un ancien pays supprimé revient au Bénin avec son ID API', (
    tester,
  ) async {
    adapter.responses['/contrees'] = [
      {'id_contree': 8, 'nom': 'Togo'},
      {'id_contree': 42, 'nom': 'Bénin'},
    ];
    SharedPreferences.setMockInitialValues({CountryPreference.key: 99});
    await start(tester);
    expect(find.text('Bénin'), findsOneWidget);
    await tapText(tester, 'Vitamines');
    expect(
      adapter.requests.any(
        (r) => r.path == '/vitamines' && r.queryParameters['id_contree'] == 42,
      ),
      isTrue,
    );
  });

  testWidgets('Sans Bénin : premier pays disponible ; sans pays : état vide', (
    tester,
  ) async {
    adapter.responses['/contrees'] = [
      {'id_contree': 7, 'nom': 'Togo'},
    ];
    await start(tester);
    expect(find.text('Togo'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    adapter.responses['/contrees'] = [];
    await start(tester, location: '/catalogue/maladies');
    expect(find.text('Aucun pays disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Header sur petit écran avec texte agrandi', (tester) async {
    await start(tester, scale: 1.8, size: const Size(320, 700));
    expect(find.byTooltip('Changer de pays'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Erreur de connexion : Réessayer recharge la liste', (
    tester,
  ) async {
    adapter.offline = true;
    await start(tester, location: '/catalogue/maladies');
    expect(find.text('Pas de connexion internet'), findsOneWidget);
    adapter.offline = false;
    await tapText(tester, 'Réessayer');
    expect(find.text('Constipation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Catalogue vide : état vide explicite', (tester) async {
    adapter.responses['/vitamines'] = [];
    await start(
      tester,
      location: '/catalogue/vitamines/pays/1?pays=B%C3%A9nin',
    );
    expect(
      find.text('Aucune vitamine renseignée pour ce pays.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recherche locale : nom local et accents, sans search serveur', (
    tester,
  ) async {
    await start(tester, location: CatalogueRoutes.search);
    await tester.enterText(find.byType(TextField), 'agwema');
    await tester.pumpAndSettle();
    expect(find.text('Séné africain'), findsOneWidget);
    expect(find.text('Papayier'), findsNothing);
    expect(
      adapter.requests.every((r) => !r.queryParameters.containsKey('search')),
      isTrue,
    );
  });
  testWidgets('Lien invalide : état explicite sans appel réseau', (
    tester,
  ) async {
    await start(tester, location: '/catalogue/plantes/invalide');
    expect(find.text('Lien invalide'), findsOneWidget);
    expect(adapter.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Petit écran et texte agrandi : listes et fiches restent consultables',
    (tester) async {
      await start(
        tester,
        location: '/catalogue/maladies/pays',
        scale: 1.8,
        size: const Size(320, 700),
      );
      await tapText(tester, 'Bénin');
      await tapText(tester, 'Constipation');
      await tapText(tester, 'Séné africain');
      await tester.scrollUntilVisible(
        find.text('Posologie'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Posologie'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
