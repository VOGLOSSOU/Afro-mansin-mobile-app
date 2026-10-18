# Ama - Intégration du catalogue public

Mise à jour : 18 octobre 2026.

## Navigation

- Accueil > Maladie > pays > maladie > plante > fiche et recette sélectionnée.
- Accueil > Urgences > pays > urgence > plante ou méthode non végétale selon les associations.
- Accueil > Vitamines > pays > vitamine > plante source > fiche sans recette vitaminique inventée.
- Recherche d’accueil > recherche locale parmi les plantes par nom français, scientifique ou local > fiche ; recettes par maladie accessibles séparément.
- Autres recettes : exclusion de la recette courante et conservation du pays quand un contexte pays est fourni.

## Organisation du code

| Emplacement | Rôle |
|---|---|
| lib/core/api/public_api.dart | Client GET Dio, URL par environnement, délais et erreurs accessibles |
| lib/features/catalogue/domain/ | Entités Dart sans parsing JSON ni dépendance Flutter |
| lib/features/catalogue/data/ | Requêtes et parsing manuel des sorties de l’API |
| lib/features/catalogue/presentation/controllers/ | Listes StateNotifier, détails FutureProvider avec cache mémoire de session |
| lib/features/catalogue/presentation/screens/ | Pays, listes, maladie, vitamine, méthode, recherche et fiche plante |
| lib/features/catalogue/presentation/widgets/ | États asynchrones, cartes, textes, galerie et audio |
| lib/app/router/app_router.dart | Pages de catalogue en routes top-level, paramètres validés |

## Contrat pris en compte

Les listes sont des tableaux sans enveloppe ni pagination. Les relations du GET liste ne remplacent pas la source détaillée de la fiche. Les propriétés nulles sont omises à l’écran ou signalées comme non renseignées, sans signifier absence de risque. Les noms peuvent contenir plusieurs variantes séparées par des retours à la ligne.

Les maladies ordinaires sont filtrées en mémoire sans envoyer est_urgence=false. Les urgences envoient est_urgence=true. Aucune route admin ni suivi n’est appelée. Le guide générique d’architecture propose des fonctions d’auth et cache disque qui ne sont pas nécessaires dans le périmètre actuel : elles n’ont pas été ajoutées.

La recherche reste locale et aucun paramètre search n’est envoyé. Les médias sont chargés depuis leurs URL HTTPS lorsqu’elles existent. Les images utilisent le cache mémoire Flutter ; aucun cache persistant de catalogue ou de média n’est ajouté. L’audio utilise just_audio et est libéré à la sortie de la fiche. Les photos et audios de production étant actuellement absents, la lecture de médias réels devra être vérifiée lorsqu’ils seront renseignés.

## Vérification

```bash
flutter analyze
flutter test
flutter build appbundle --debug
```

Les tests automatisés utilisent des réponses publiques enregistrées dans test/fixtures/catalogue.json et un adaptateur Dio de test. Ils ne créent ni ne suppriment de données en production. Ils couvrent les trois parcours, l’absence de recette automatique pour les vitamines, les noms locaux et champs nulls, le filtre urgences, les erreurs et la reprise, les listes vides et la recherche locale.

Les éléments suivants restent hors périmètre : suivi à 48 h, notifications, mode hors ligne et espace admin mobile. La configuration de signature pour une publication sur les stores reste celle du projet et nécessite un travail de release séparé.

## Résultat de la validation dans cet environnement

- flutter analyze : aucune issue.
- flutter test : 17 tests réussis, dont navigation complète des trois parcours, reprise réseau, liens invalides et petit écran avec texte agrandi.
- Contrôle complémentaire avec le nouveau repository sur l’API réelle : réussi pour les trois parcours, exclusivement en GET.
- Captures de cinq écrans contrôlées au format téléphone.
- Compilation native Android : tentée mais non terminée, car les téléchargements de l’outillage Gradle sont trop lents dans cet environnement. Le wrapper du projet est resté en version 8.14. Relancer flutter build appbundle --debug une fois l’outillage disponible.
- Aucun appareil Android/iOS connecté lors de cette validation ; compilation iOS et lecture d’un média réel non vérifiées ici.
