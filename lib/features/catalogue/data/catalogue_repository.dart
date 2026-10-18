import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/public_api.dart';
import '../domain/catalogue.dart';

final catalogueRepositoryProvider = Provider<CatalogueRepository>(
  (ref) => CatalogueRepository(ref.watch(publicApiProvider)),
);

class CatalogueRepository {
  CatalogueRepository(this._api);
  final PublicApi _api;

  Future<List<Plant>> plants() async =>
      _objects(await _api.get('/plantes')).map(_plant).toList();

  Future<List<Country>> countries() async =>
      _objects(await _api.get('/contrees')).map(_country).toList();

  Future<List<Condition>> conditions(
    int countryId, {
    required bool emergency,
  }) async {
    final values = _objects(
      await _api.get(
        '/maladies',
        query: {
          'id_contree': countryId,
          // Ne jamais envoyer false : l'API convertit la chaîne "false" en true.
          if (emergency) 'est_urgence': true,
        },
      ),
    ).map(_condition);
    return values
        .where((c) => c.isEmergency == emergency && c.countryId == countryId)
        .toList();
  }

  Future<List<Vitamin>> vitamins(int countryId) async => _objects(
    await _api.get('/vitamines', query: {'id_contree': countryId}),
  ).map(_vitamin).where((v) => v.countryId == countryId).toList();

  Future<Condition> condition(int id) async =>
      _condition(_object(await _api.get('/maladies/$id')));
  Future<Vitamin> vitamin(int id) async =>
      _vitamin(_object(await _api.get('/vitamines/$id')));
  Future<Plant> plant(int id) async =>
      _plant(_object(await _api.get('/plantes/$id')));
  Future<Recipe> recipe(int id) async =>
      _recipe(_object(await _api.get('/indications/$id')));
  Future<MethodLink> method(int conditionId, int methodId) async => _methodLink(
    _object(await _api.get('/indications-methode/$conditionId/$methodId')),
  );
}

// Le JSON reste dans data ; les entités domain ne dépendent ni du réseau ni de Flutter.
Map<String, dynamic> _object(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const ApiFailure('Les données reçues sont illisibles. Réessayez.');
}

List<Map<String, dynamic>> _objects(Object? value) {
  if (value is! List) {
    throw const ApiFailure('Les données reçues sont illisibles. Réessayez.');
  }
  return value.map(_object).toList();
}

List<Map<String, dynamic>> _relations(Map<String, dynamic> json, String key) =>
    json[key] == null ? [] : _objects(json[key]);
int _id(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int && value > 0) return value;
  throw const ApiFailure('Les données reçues sont incomplètes. Réessayez.');
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = _text(json[key]);
  if (value != null) return value;
  throw const ApiFailure('Les données reçues sont incomplètes. Réessayez.');
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
T? _nested<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    value == null ? null : parse(_object(value));
Country _country(Map<String, dynamic> j) =>
    Country(id: _id(j, 'id_contree'), name: _requiredText(j, 'nom'));
Condition _condition(Map<String, dynamic> j) => Condition(
  id: _id(j, 'id_maladie'),
  name: _requiredText(j, 'nom'),
  countryId: _id(j, 'id_contree'),
  isEmergency: j['est_urgence'] == true,
  countryName: _nested(j['contree'], (c) => _requiredText(c, 'nom')),
  hygiene: _text(j['regles_hygiene']),
  recipes: _relations(j, 'indications').map(_recipe).toList(),
  methods: _relations(j, 'indications_methode').map(_methodLink).toList(),
);
Plant _plant(Map<String, dynamic> j) => Plant(
  id: _id(j, 'id_plante'),
  name: _requiredText(j, 'nom_francais'),
  scientificName: _requiredText(j, 'nom_scientifique'),
  family: _text(j['famille']),
  description: _text(j['description']),
  distribution: _text(j['repartition']),
  recognition: _text(j['reconnaissance_astuces']),
  usefulPart: _text(j['partie_utile']),
  contraindications: _text(j['contre_indications']),
  adverseEffects: _text(j['effets_indesirables_connus']),
  warning: _text(j['mise_en_garde_speciale']),
  reference: _text(j['reference_bibliographique']),
  localNames: _relations(j, 'noms_locaux')
      .map(
        (n) => LocalName(
          language: _requiredText(_object(n['langue']), 'nom'),
          name: _requiredText(n, 'nom_local'),
          audioUrl: _text(n['audio_url']),
        ),
      )
      .toList(),
  photos: _relations(j, 'photos')
      .map(
        (p) => PlantPhoto(url: _requiredText(p, 'url'), type: _text(p['type'])),
      )
      .toList(),
  recipes: _relations(j, 'indications').map(_recipe).toList(),
);
Recipe _recipe(Map<String, dynamic> j) => Recipe(
  id: _id(j, 'id_indication'),
  plantId: _id(j, 'id_plante'),
  conditionId: _id(j, 'id_maladie'),
  preparation: _text(j['methode_preparation']),
  dosage: _text(j['posologie']),
  advice: _text(j['regles_hygieno_diet']),
  plant: _nested(j['plante'], _plant),
  condition: _nested(j['maladie'], _condition),
);
MethodLink _methodLink(Map<String, dynamic> j) => MethodLink(
  conditionId: _id(j, 'id_maladie'),
  methodId: _id(j, 'id_methode'),
  description: _text(j['description']),
  method: _nested(
    j['methode'],
    (m) => CareMethod(
      id: _id(m, 'id_methode'),
      name: _requiredText(m, 'nom'),
      description: _text(m['description']),
    ),
  ),
  condition: _nested(j['maladie'], _condition),
);
Vitamin _vitamin(Map<String, dynamic> j) => Vitamin(
  id: _id(j, 'id_vitamine'),
  name: _requiredText(j, 'nom'),
  countryId: _id(j, 'id_contree'),
  countryName: _nested(j['contree'], (c) => _requiredText(c, 'nom')),
  plants: _relations(
    j,
    'sources',
  ).map((s) => _plant(_object(s['plante']))).toList(),
);
