import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalogue/domain/catalogue.dart';
import '../../features/catalogue/presentation/catalogue_routes.dart';
import '../../features/catalogue/presentation/screens/catalogue_screens.dart';
import '../../features/catalogue/presentation/screens/plant_screen.dart';
import '../../features/catalogue/presentation/widgets/catalogue_widgets.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

// Pages de détail top-level, conformément au guide d'architecture.
GoRouter createAppRouter({
  String initialLocation = AppRoutes.splash,
}) => GoRouter(
  initialLocation: initialLocation,
  errorBuilder: (context, state) => CataloguePage(
    title: 'Page introuvable',
    child: Center(
      child: TextButton(
        onPressed: () => context.go(AppRoutes.home),
        child: const Text('Revenir à l’accueil'),
      ),
    ),
  ),
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: CatalogueRoutes.search,
      builder: (_, _) => const PlantSearchScreen(),
    ),
    GoRoute(
      path: '/catalogue/:section',
      builder: (_, state) => _safePage(
        () => SelectedEntriesScreen(
          section: CatalogueSection.fromPath(state.pathParameters['section']),
        ),
      ),
    ),
    GoRoute(
      path: '/catalogue/:section/pays',
      builder: (_, state) => _safePage(
        () => CountriesScreen(
          section: CatalogueSection.fromPath(state.pathParameters['section']),
        ),
      ),
    ),
    GoRoute(
      path: '/catalogue/:section/pays/:countryId',
      builder: (_, state) => _safePage(
        () => EntriesScreen(
          section: CatalogueSection.fromPath(state.pathParameters['section']),
          countryId: _id(state, 'countryId'),
          countryName: state.uri.queryParameters['pays'] ?? 'Votre pays',
        ),
      ),
    ),
    GoRoute(
      path: '/catalogue/maladies/:id',
      builder: (_, state) => _safePage(
        () => ConditionScreen(
          id: _id(state, 'id'),
          countryId: _queryId(state, 'paysId') ?? 0,
        ),
      ),
    ),
    GoRoute(
      path: '/catalogue/vitamines/:id',
      builder: (_, state) => _safePage(
        () => VitaminScreen(
          id: _id(state, 'id'),
          countryId: _queryId(state, 'paysId') ?? 0,
        ),
      ),
    ),
    GoRoute(
      path: '/catalogue/plantes/:id',
      builder: (_, state) => _safePage(
        () => PlantScreen(
          id: _id(state, 'id'),
          recipeId: _queryId(state, 'recette'),
          countryId: _queryId(state, 'paysId'),
          fromVitamin: state.uri.queryParameters['vitamine'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: '/catalogue/urgences/:conditionId/methodes/:methodId',
      builder: (_, state) => _safePage(
        () => MethodScreen(
          conditionId: _id(state, 'conditionId'),
          methodId: _id(state, 'methodId'),
        ),
      ),
    ),
  ],
);

int _id(GoRouterState state, String name) {
  final value = int.tryParse(state.pathParameters[name] ?? '');
  if (value == null || value <= 0) {
    throw const FormatException('Identifiant invalide');
  }
  return value;
}

int? _queryId(GoRouterState state, String name) {
  final value = state.uri.queryParameters[name];
  if (value == null) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) {
    throw const FormatException('Identifiant invalide');
  }
  return parsed;
}

Widget _safePage(Widget Function() build) {
  try {
    return build();
  } on FormatException {
    return const CataloguePage(
      title: 'Lien invalide',
      child: CatalogueMessage(
        title: 'Contenu introuvable',
        message: 'Revenez au catalogue pour choisir un contenu.',
      ),
    );
  }
}
