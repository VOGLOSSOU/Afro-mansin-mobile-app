enum CatalogueSection {
  maladies('maladies', 'Maladies'),
  urgences('urgences', 'Urgences'),
  vitamines('vitamines', 'Vitamines');

  const CatalogueSection(this.path, this.label);
  final String path;
  final String label;

  static CatalogueSection fromPath(String? path) => values.firstWhere(
    (s) => s.path == path,
    orElse: () => throw const FormatException('Rubrique invalide'),
  );
}

class Country {
  const Country({required this.id, required this.name});
  final int id;
  final String name;
}

class LocalName {
  const LocalName({required this.language, required this.name, this.audioUrl});
  final String language;
  final String name;
  final String? audioUrl;
}

class PlantPhoto {
  const PlantPhoto({required this.url, this.type});
  final String url;
  final String? type;
}

class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.scientificName,
    this.family,
    this.description,
    this.distribution,
    this.recognition,
    this.usefulPart,
    this.contraindications,
    this.adverseEffects,
    this.warning,
    this.reference,
    this.localNames = const [],
    this.photos = const [],
    this.recipes = const [],
  });
  final int id;
  final String name, scientificName;
  final String? family, description, distribution, recognition, usefulPart;
  final String? contraindications, adverseEffects, warning, reference;
  final List<LocalName> localNames;
  final List<PlantPhoto> photos;
  final List<Recipe> recipes;
}

class Condition {
  const Condition({
    required this.id,
    required this.name,
    required this.countryId,
    required this.isEmergency,
    this.countryName,
    this.hygiene,
    this.recipes = const [],
    this.methods = const [],
  });
  final int id, countryId;
  final String name;
  final bool isEmergency;
  final String? countryName, hygiene;
  final List<Recipe> recipes;
  final List<MethodLink> methods;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.plantId,
    required this.conditionId,
    this.preparation,
    this.dosage,
    this.advice,
    this.plant,
    this.condition,
  });
  final int id, plantId, conditionId;
  final String? preparation, dosage, advice;
  final Plant? plant;
  final Condition? condition;
}

class CareMethod {
  const CareMethod({required this.id, required this.name, this.description});
  final int id;
  final String name;
  final String? description;
}

class MethodLink {
  const MethodLink({
    required this.conditionId,
    required this.methodId,
    this.description,
    this.method,
    this.condition,
  });
  final int conditionId, methodId;
  final String? description;
  final CareMethod? method;
  final Condition? condition;
}

class Vitamin {
  const Vitamin({
    required this.id,
    required this.name,
    required this.countryId,
    this.countryName,
    this.plants = const [],
  });
  final int id, countryId;
  final String name;
  final String? countryName;
  final List<Plant> plants;
}
