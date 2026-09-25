# Ama — application mobile

Application mobile Flutter (Android + iOS) de **plantes médicinales africaines**. L'utilisateur
choisit un pays, puis une maladie, une urgence ou une vitamine, et arrive sur la fiche d'une
plante : noms en langues locales (fon, yoruba, adja, dendi…) avec audio, photos, recette,
posologie et mises en garde. 48 h après la consultation d'une recette, un questionnaire de suivi
recueille le retour de l'utilisateur (pharmacovigilance).

> Ce dépôt contient **uniquement l'app mobile**. Le backend, l'API et le serveur sont développés
> ailleurs. L'app ne fait que consommer l'API.

Projet anciennement nommé **Afro Mansìn**. Le client a abandonné ce nom, le nouveau nom est **Ama**
(« feuille » en fon). Voir [Nom et identifiants](#nom-et-identifiants) : les identifiants
techniques portent encore l'ancien nom.

---

## État d'avancement

| Élément | État |
|---|---|
| Splash screen (natif + Flutter animé) | ✅ |
| Onboarding 3 pages (défilement, « Passer », affiché une seule fois) | ✅ |
| Thème et charte graphique | ✅ |
| Accueil Maladie / Urgences / Vitamines + barre de recherche | ✅ UI (les taps affichent « Bientôt disponible ») |
| Parcours pays → maladie/vitamine/urgence → fiche plante | ⏳ en attente du contrat d'API |
| Lecture audio des noms locaux | ⏳ |
| Suivi à 48 h (notification locale + questionnaire) | ⏳ |
| Icône de l'app | ⏳ en attente d'un logo haute résolution (voir [Logo](#logo)) |

---

## Démarrer

Prérequis : Flutter 3.41+ (Dart 3.11+), Android SDK et/ou Xcode.

```bash
flutter pub get
flutter run
```

Pour revoir l'onboarding après l'avoir terminé, désinstaller l'app ou effacer ses données.

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

### Arborescence actuelle

```
lib/
├── main.dart                       # runApp immédiat + MaterialApp.router
├── app/
│   ├── router/app_router.dart      # Routes : / (splash), /onboarding, /home
│   └── theme/                      # app_colors, app_spacing, app_theme
├── core/
│   ├── utils/app_info.dart         # Nom de l'app, slogan, avertissement médical
│   └── widgets/                    # medical_disclaimer (bas de chaque écran)
└── features/
    ├── splash/                     # Splash animé → onboarding ou accueil
    ├── onboarding/                 # 3 pages + indicateur « déjà vu » (shared_preferences)
    └── home/                       # Accueil : recherche + Maladie / Urgences / Vitamines
```

### Dépendances

| Package | Rôle |
|---|---|
| `flutter_riverpod` ^2.6 | State management |
| `go_router` | Navigation |
| `shared_preferences` | Préférences locales (onboarding vu) |
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

### Logo

- `ama-logos.png` : image source générée (3 déclinaisons du même logo sur une seule image).
- `assets/images/` : versions à fond transparent **utilisées par l'app** :
  - `logo_symbol.png` : symbole couleur ;
  - `logo_symbol_light.png` : symbole crème, pour les fonds verts (utilisé par le splash) ;
  - `logo_full.png` : symbole + « Ama ».
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

- **Contrat d'API** (endpoints + exemples JSON) : nécessaire pour les parcours et la fiche plante.
- **Authentification** : l'API sera-t-elle appelée sans compte, ou avec un token ? La réponse
  décide si l'`AuthInterceptor` du guide est utile.
- **Hors-ligne** : quel niveau de cache pour les textes, photos et audios ?
- **Permission des notifications** : à demander avec l'implémentation du suivi à 48 h (l'onboarding
  l'annonce déjà en page 3).
- **Logo haute résolution** : pour l'icône de l'app et le splash natif.
- **Nom définitif et identifiants** : à valider par le client avant publication (disponibilité
  stores, domaine, marque OAPI).
