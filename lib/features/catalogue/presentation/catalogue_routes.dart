import '../domain/catalogue.dart';

/// Les libellés ne servent qu'à l'affichage ; les requêtes utilisent les IDs.
class CatalogueRoutes {
  CatalogueRoutes._();
  static const search = '/catalogue/recherche';
  static String countries(CatalogueSection section) =>
      '/catalogue/${section.path}/pays';
  static String entries(
    CatalogueSection section,
    int countryId,
    String countryName,
  ) => Uri(
    path: '/catalogue/${section.path}/pays/$countryId',
    queryParameters: {'pays': countryName},
  ).toString();
  static String condition(int id, int countryId) =>
      '/catalogue/maladies/$id?paysId=$countryId';
  static String vitamin(int id, int countryId) =>
      '/catalogue/vitamines/$id?paysId=$countryId';
  static String plant(
    int id, {
    int? recipeId,
    int? countryId,
    bool vitamin = false,
  }) => Uri(
    path: '/catalogue/plantes/$id',
    queryParameters: {
      if (recipeId != null) 'recette': '$recipeId',
      if (countryId != null) 'paysId': '$countryId',
      if (vitamin) 'vitamine': 'true',
    },
  ).toString();
  static String method(int conditionId, int methodId) =>
      '/catalogue/urgences/$conditionId/methodes/$methodId';
}
