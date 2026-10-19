# Ama — application mobile

Application mobile Flutter (Android + iOS) de **plantes médicinales africaines**. L'utilisateur
retrouve le Bénin sélectionné par défaut, peut changer de pays dans le header, puis choisit
une maladie, une urgence ou une vitamine et arrive sur la fiche d'une
plante : noms en langues locales (fon, yoruba, adja, dendi…) avec audio, photos, recette,
posologie et mises en garde. Le suivi post-utilisation à 48 h reste reporté et ne fait pas partie
des parcours actuellement intégrés.

> Ce dépôt contient **uniquement l'app mobile**. Le backend, l'API et le serveur sont développés
> ailleurs. L'app ne fait que consommer l'API.

Projet anciennement nommé **Afro Mansìn**. Le client a abandonné ce nom, le nouveau nom est **Ama**
(« feuille » en fon). Voir [Nom et identifiants](#nom-et-identifiants) : les identifiants
techniques portent encore l'ancien nom.

---

## État d'avancement

| Élément | État |
|---|---|
| Splash screen (natif + Flutter, logo qui pulse ~6 s) | ✅ |
| Typographie Fraunces + Noto Sans (embarquées) | ✅ |
| Onboarding 3 pages (défilement, « Passer », affiché une seule fois) | ✅ |
| Images plein écran de l'onboarding | ✅ `assets/images/onboarding_1-3.jpg` (originaux PNG dans `design/onboarding/`) |
| Thème et charte graphique | ✅ |
| Accueil Maladie / Urgences / Vitamines + recherche locale des plantes | ✅ relié aux parcours |
| Pays global mémorisé → maladie/vitamine/urgence → fiche plante ou méthode | ✅ GET publics sur l’API Railway |
| Noms locaux, photos et audio | ✅ champs absents gérés ; lecture HTTPS si une URL audio est renseignée |
| Suivi à 48 h (notification locale + questionnaire) | Reporté |
| Icône de l'app | ⏳ en attente d'un logo haute résolution (voir [Logo](#logo)) |

---

## Démarrer

Prérequis : Flutter 3.41+ (Dart 3.11+), Android SDK et/ou Xcode.

```bash
flutter pub get
flutter run
```

Pour revoir l'onboarding après l'avoir terminé, désinstaller l'app ou effacer ses données.

### API et parcours intégrés

La base par défaut est `https://phytot-rapie-app-backend-production.up.railway.app`, sans préfixe `/api` et sans token. Pour viser un autre environnement :

```bash
flutter run --dart-define=API_BASE_URL=https://votre-api.example.com
```

Les IDs viennent des réponses de l’API, jamais de constantes de production dans le code de l’application. Les maladies ordinaires sont filtrées côté mobile pour contourner la conversion actuelle de `est_urgence=false` côté serveur. La recette et la fiche plante sont chargées séparément ; une fiche vitaminique ne reprend pas automatiquement une posologie de maladie.

Les nouvelles pages proposent recherche locale dans les listes, états vides, chargement, erreur réseau et reprise, ainsi que rafraîchissement par glissement. Les détails sont conservés en mémoire pour la session, sans cache disque du catalogue. Les noms dans les langues sont en Noto Sans, les noms scientifiques en italique. Aucun média n’est inventé quand les URL sont absentes.

Scénarios disponibles au Bénin : Constipation et ses trois plantes, Brûlure thermique et sa méthode, Vitamine C et l’oranger. Voir [le parcours illustré](docs_api/parcours-user-illustre.md) et [la note d’intégration mobile](docs_api/integration-mobile.md).

### Vérifications avant commit / release

```bash
flutter analyze   # doit être à 0 issue
flutter test
```

La checklist de release complète est dans
[FLUTTER_ARCHITECTURE_GUIDE.md §10](FLUTTER_ARCHITECTURE_GUIDE.md#10-checklist-avant-chaque-release).

---

## Architecture

**Le guide [FLUTTER_ARCHITECTURE_GUIDE.md](FLUTTER_ARCHITECTURE_GUIDE.md) est la référence
obligatoire** pour tout le code de ce projet. En résumé :

- Organisation par feature : `features/<feature>/{data, domain, presentation}`, avec `core/`
  pour le transverse et `app/` pour le router et le thème.
- Riverpod 2, avec deux patterns seulement : `FutureProvider.family` + `keepAlive` pour une page
  détail, `StateNotifier` pour une liste ou un flux complexe. Riverpod reste volontairement en
  2.x, parce que `StateNotifier` n'est plus qu'en « legacy » dans Riverpod 3.
- go_router : seuls les onglets de la bottom nav vont dans le `ShellRoute`. Toutes les pages de
  détail sont en routes top-level.
- Pas de code-gen : le parsing JSON → entités est écrit à la main dans la couche `data`.
- `main()` appelle `runApp()` immédiatement, sans aucun `await` avant le premier rendu.
- On n'ajoute une dépendance ou un composant partagé que quand le besoin est concret.

### Connexion internet requise

Décision du 17/10/2026 : **pour l'instant, l'app fonctionne uniquement en ligne**. Le mode
hors-ligne sera ajouté une fois l'app stable. En attendant :

- pas de cache persistant des données de l'API (textes, photos, audios). Le cache
  « stale-while-error » du guide (§5) est donc mis de côté pour l'instant ;
- seul un cache en mémoire pour la durée de la session est autorisé (Riverpod `keepAlive`), pour
  éviter de recharger un écran déjà visité ;
- chaque écran qui appelle l'API affiche un état clair « Pas de connexion internet » avec un
  bouton **Réessayer** ;
- tout accès aux données passe par les repositories (couche `data`). Le mode hors-ligne pourra
  ainsi y être ajouté plus tard sans toucher aux écrans.

### Arborescence actuelle

```
lib/
├── main.dart                       # runApp immédiat + MaterialApp.router
├── app/
│   ├── router/app_router.dart      # Splash, onboarding, accueil et parcours catalogue
│   └── theme/                      # app_colors, app_spacing, app_typography, app_theme
├── core/
│   ├── api/public_api.dart         # GET Dio publics, timeouts et erreurs
│   ├── utils/app_info.dart         # Nom de l'app, slogan, avertissement médical
│   └── widgets/                    # medical_disclaimer (bas de chaque écran)
└── features/
    ├── splash/                     # Splash animé → onboarding ou accueil
    ├── onboarding/                 # 3 pages + indicateur « déjà vu » (shared_preferences)
    ├── home/                       # Entrées des trois parcours et recherche
    └── catalogue/                  # Entités, repository, providers, listes et fiches
```

### Dépendances

| Package | Rôle |
|---|---|
| `flutter_riverpod` ^2.6 | State management |
| `go_router` | Navigation |
| `shared_preferences` | Préférences locales (onboarding vu) |
| `dio` | GET publics de l’API, timeouts et gestion des erreurs |
| `just_audio` | Lecture des noms locaux quand audio_url est renseigné |

Les polices ne passent pas par `google_fonts` : elles sont déclarées dans `pubspec.yaml`.
| `flutter_native_splash` (dev) | Génération du splash natif |

---

## Charte graphique

Palette « terre et plantes », définie dans [lib/app/theme/app_colors.dart](lib/app/theme/app_colors.dart) :

| Rôle | Couleur | Hex |
|---|---|---|
| Primaire | Vert forêt | `#2E6B3F` |
| Secondaire | Terracotta | `#B5582A` |
| Accent (audio, badges) | Ocre | `#D9A441` |
| Fond | Crème | `#FAF6EE` |
| Texte | Brun très foncé | `#2B2118` |
| Urgences / mises en garde | Rouge | `#B3261E` |

**Le rouge est réservé** au parcours Urgences et aux mises en garde (contre-indications,
« Attention »). Ne pas l'utiliser ailleurs, pour qu'il garde son poids.

L'avertissement médical (« Les conseils contenus dans cette application ne représentent
aucunement une consultation médicale… ») est centralisé dans `AppInfo.medicalDisclaimer`. La
maquette l'affiche sur tous les écrans.

### Typographie

Deux polices, **embarquées dans l'app** (`assets/fonts/`, licence OFL, aucun téléchargement à
l'exécution) et centralisées dans [lib/app/theme/app_typography.dart](lib/app/theme/app_typography.dart) :

- **Fraunces** : uniquement les titres et les noms de plantes en gros. Jamais pour du texte
  courant ni des boutons.
- **Noto Sans** : tout le reste (textes, boutons, menus, champs, légendes).

Règles :

- **Noms en langues locales (fon, yoruba, goun…) toujours en Noto Sans**, même dans un titre.
  Fraunces n'a pas les lettres ɛ ɔ ɖ Ɖ Ɔ ǹ (vérifié) : elles basculent en Noto Sans via le
  repli (`fontFamilyFallback`), et le mot devient visuellement mélangé.
- **Noms scientifiques toujours en italique** : utiliser `AppTypography.scientificName`.
- Jamais de `fontFamily` ni de taille en dur dans un widget : partir de
  `Theme.of(context).textTheme.xxx` (éventuellement `.copyWith(color: …)`).

| Usage | Style du thème | Police | Taille / graisse |
|---|---|---|---|
| Titre écran / nom de plante (fiche) | `headlineLarge` | Fraunces | 28 / 600 |
| Titre de section | `headlineMedium` | Fraunces | 22 / 600 |
| Nom de plante dans une carte | `titleMedium` | Fraunces | 18 / 500 |
| Texte courant | `bodyLarge` | Noto Sans | 16 / 400 |
| Texte secondaire | `bodyMedium` | Noto Sans | 14 / 400 |
| Boutons, onglets, labels | `labelLarge` | Noto Sans | 14 / 500 |
| Légendes, badges | `labelSmall` | Noto Sans | 12 / 500 |

Les fichiers `.ttf` statiques ont été générés depuis les polices variables de Google Fonts
(Fraunces : opsz 24, SOFT 0, WONK 0 ; Noto Sans : wdth 100).

Phrase de contrôle des caractères : `Amavivɛ ɖɔ Ɖɛ Ɔ ẹ ọ ṣ ǹ ɛ̀ ɔ́ - Vernonia amygdalina`.

### Logo

- `ama-logos.png` : image source générée (3 déclinaisons du même logo sur une seule image).
- `assets/images/` : versions à fond transparent **utilisées par l'app** :
  - `logo_symbol.png` : symbole couleur ;
  - `logo_symbol_light.png` : symbole crème, pour les fonds verts ;
  - `logo_full.png` : symbole + « Ama » ;
  - `logo_full_light.png` : symbole + « Ama » en crème, pour les fonds verts (utilisé par le splash).
- `design/logo/` : déclinaisons pour la communication (non embarquées dans l'app), dont les
  versions sur fond vert en 1024 × 1024.

⚠️ La source ne fait qu'environ 280 × 370 px par logo. C'est suffisant pour le splash Flutter,
**pas pour l'icône de l'app** (iOS exige 1024 × 1024) ni pour l'impression. Il faut une
version vectorisée (SVG) ou haute résolution du symbole avant de générer les icônes.

### Splash natif

Configuré dans la section `flutter_native_splash` du `pubspec.yaml` : fond vert uni, pour
s'enchaîner sans flash avec le splash Flutter. Après toute modification de cette section :

```bash
dart run flutter_native_splash:create
```

---

## Nom et identifiants

Le nom et le package sont **provisoires**. Ils restent modifiables jusqu'à la première
publication sur les stores ; après, l'identifiant du package devient définitif.

| Élément | Valeur actuelle | Où le changer |
|---|---|---|
| Nom affiché dans l'app | `Ama` | `AppInfo.name` dans [lib/core/utils/app_info.dart](lib/core/utils/app_info.dart) |
| Nom sous l'icône Android | `afro_mansin` | `android:label` dans `android/app/src/main/AndroidManifest.xml` |
| Nom sous l'icône iOS | `Afro Mansin` | `CFBundleDisplayName` dans `ios/Runner/Info.plist` |
| Package Android | `com.afromansin.afro_mansin` | `namespace` + `applicationId` dans `android/app/build.gradle.kts`, et déplacer le dossier Kotlin de `MainActivity` |
| Bundle ID iOS | `com.afromansin.afroMansin` | `PRODUCT_BUNDLE_IDENTIFIER` dans `ios/Runner.xcodeproj/project.pbxproj` |
| Nom du package Dart | `afro_mansin` | `name` dans `pubspec.yaml` + imports `package:afro_mansin/` des tests |

Cible envisagée : `com.<domaine-du-client>.app`, à caler sur le nom de domaine retenu.

---

## Documents de référence

| Fichier | Contenu |
|---|---|
| `afro-mansin-05042026-Vf pdf.pdf` | Maquette fonctionnelle du client (31 écrans, parcours complets) |
| `ECHANTILLON_BASE APP EXCEL.xlsx` | Échantillon de données réelles (3 fiches plantes, constipation) |
| [modele-donnees.md](modele-donnees.md) | Modèle de données déduit des deux sources ci-dessus. Côté app, il donne la forme attendue des entités `domain/`, pas un schéma à implémenter |
| [FLUTTER_ARCHITECTURE_GUIDE.md](FLUTTER_ARCHITECTURE_GUIDE.md) | Règles d'architecture à respecter |

## Points ouverts

- **Catalogue** : contrat disponible dans [docs_api/api-client.md](docs_api/api-client.md) et intégré. Les appels mobiles sont publics, sans compte ni token admin.
- **Hors-ligne** : reporté. Voir [Connexion internet requise](#connexion-internet-requise).
- **Notifications et suivi** : reportés ; aucune permission ni promesse de rappel dans l’onboarding actuel.
- **Logo haute résolution** : pour l'icône de l'app et le splash natif.
- **Nom définitif et identifiants** : à valider par le client avant publication (disponibilité
  stores, domaine, marque OAPI).
