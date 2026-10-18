# API Afro Mansin - Guide d’intégration des parcours clients

## Sommaire

1. [Conventions communes](#conventions-communes)
2. [Parcours et appels à enchaîner](#parcours-et-appels-à-enchaîner)
3. [Dictionnaire des objets de sortie](#dictionnaire-des-objets-de-sortie)
4. [Référence des endpoints publics de consultation](#référence-des-endpoints-publics-de-consultation)
5. [Exemple d’intégration JavaScript](#exemple-dintégration-javascript)
6. [Annexe technique — suivi reporté](#annexe-technique--suivi-reporté)

Ce document permet de construire le site ou l’application grand public. Toutes les routes du parcours courant sont des GET publics, sans compte, cookie ni JWT. Pour les écritures du catalogue, voir [le guide admin](api-admin.md).

## Conventions communes

- Base de production : `https://phytot-rapie-app-backend-production.up.railway.app` ; en local : `http://localhost:3000`. Aucun préfixe `/api`.
- Version documentaire : 18 octobre 2026, fondée sur les contrôleurs, services, DTO et le schéma Prisma du dépôt. Les exemples sont illustratifs, pas une copie de la base de production ; remplacer les identifiants par ceux réellement obtenus.
- Corps de requête : JSON avec `Content-Type: application/json`. Les noms des propriétés sont en `snake_case`.
- Les listes sont des tableaux JSON directs, sans enveloppe `data`, sans pagination ni total. Une liste vide renvoie `[]` avec HTTP 200.
- Les identifiants de chemin sont des entiers ; utiliser les identifiants existants. Les chemins composites respectent exactement l’ordre indiqué.
- Les champs de sortie nullables sont renvoyés avec `null` lorsqu’ils ne sont pas renseignés. Les tableaux de relations absentes sont vides.
- Aucun paramètre `include`, `fields`, `search`, `page`, `limit` ou `sort` n’est implémenté. Les relations sont fixées par chaque service.
- Les paramètres de requête documentés sont facultatifs ; plusieurs filtres se combinent avec un ET. Les DTO de requête rejettent les propriétés inconnues ; les contrôleurs à paramètres individuels peuvent ignorer les paramètres supplémentaires. Ne pas compter sur un paramètre non documenté.
- Le suivi post-utilisation est reporté côté produit. Ses routes déjà présentes sont recensées en annexe technique, sans les intégrer aux parcours à livrer.

## Erreurs et statuts

| Statut | Signification |
|---|---|
| 200 | Lecture, modification ou connexion réussie |
| 201 | Création réussie, y compris les POST du suivi |
| 204 | Suppression réussie, aucun corps de réponse |
| 400 | JSON/DTO invalide, identifiant non entier ou référence liée inexistante lors d’une écriture |
| 401 | Token absent, invalide ou expiré ; identifiants de connexion invalides |
| 404 | Ressource demandée inexistante |
| 409 | Violation d’unicité |
| 500 | Erreur non traduite par le code, notamment certaines contraintes de suppression |

Exemple d’erreur de validation (le texte et l’ordre des messages dépendent des champs) :

```json
{"message":["nom should not be empty"],"error":"Bad Request","statusCode":400}
```

Exemple de ressource absente :

```json
{"message":"Plante 999 introuvable","error":"Not Found","statusCode":404}
```

Exemple de référence absente :

```json
{"message":"Contrée 999 introuvable","error":"Bad Request","statusCode":400}
```

Exemple sans authentification sur une route protégée :

```json
{"message":"Unauthorized","statusCode":401}
```

Le contenu exact des messages de conflit varie selon l’entité ; traiter d’abord le statut HTTP. Une erreur 502 avec « Application failed to respond » provient du proxy d’hébergement et ne suit pas ce contrat applicatif.

## Particularité du filtre `est_urgence`

Le DTO utilise actuellement `@Type(() => Boolean)`. Une chaîne non vide comme `"false"` est donc convertie en `true`. `?est_urgence=true` permet de demander les urgences, mais **ne pas utiliser `?est_urgence=false` pour les maladies ordinaires**. Pour ces dernières, charger `GET /maladies?id_contree=1` sans ce filtre puis garder les objets où `est_urgence === false` côté interface. Ce comportement décrit le code actuel ; il n’a pas été corrigé dans cette documentation.

## Disponibilité

`GET /health` — public, sans entrée ni corps. Réponse **200** :

```json
{"status":"ok","service":"afro-mansin-api"}
```

Ce contrôleur renvoie un état statique du processus ; il n’exécute pas de requête SQL à chaque appel et ne valide pas l’intégralité du catalogue.

## Parcours et appels à enchaîner

### Accueil et sélection du pays

`GET /contrees` renvoie les pays ; conserver `id_contree` dans l’état de navigation. Les trois rubriques Maladies, Urgences et Vitamines sont des éléments d’interface, pas trois ressources d’accueil distinctes. `GET /langues` permet de connaître les langues disponibles globalement ; une plante peut n’avoir qu’une partie de leurs noms/audio.

### Maladies → plantes → recette

1. `GET /maladies?id_contree=1` : charger le catalogue du pays, puis filtrer côté client `est_urgence === false` si l’écran exclut les urgences.
2. `GET /maladies/1` : afficher `regles_hygiene`, les `indications` et leurs objets `plante`. Conserver l’`id_indication` choisi.
3. `GET /indications/1` : obtenir la préparation, la posologie et les règles propres à cette recette, avec maladie et plante scalaires.
4. `GET /plantes/1` avec l’`id_plante` de cette indication : obtenir les photos, les noms locaux/langues et les autres indications.
5. Composer l’écran avec la recette sélectionnée et la fiche plante. Les photos/noms ne sont pas imbriqués dans `GET /indications/1`.

Alternative à l’étape 2 : `GET /indications?id_maladie=1`. Pour vérifier un couple précis : `GET /indications?id_maladie=1&id_plante=1` renvoie un tableau de zéro ou un élément grâce à l’unicité du couple, jamais un objet direct.

« Autres recettes » : utiliser `GET /plantes/1` → `indications` ou `GET /indications?id_plante=1`. Les indications de la plante peuvent concerner plusieurs pays : filtrer sur `indication.maladie.id_contree` si la navigation doit rester dans le pays choisi. Ne pas reprendre la recette d’une autre maladie automatiquement.

### Urgences → plante ou méthode

1. `GET /maladies?id_contree=1&est_urgence=true`.
2. `GET /maladies/1` : lire `indications` pour les recettes de plantes et `indications_methode` pour les méthodes non végétales.
3. Branche plante : suivre le même enchaînement indication puis plante que ci-dessus.
4. Branche méthode : `GET /indications-methode/1/1` avec l’identifiant maladie puis méthode. Afficher la `description` de l’association lorsqu’elle est renseignée, et les informations de l’objet `methode`.
5. `GET /methodes/1` est disponible pour consulter la description générale et ses maladies associées.

Ne pas considérer toutes les méthodes d’un pays comme liées à l’urgence sélectionnée : utiliser l’association. L’API ne garantit pas que les associations ont été saisies dans le même pays ni que la maladie est marquée urgente ; la cohérence éditoriale doit être vérifiée à la saisie.

### Vitamines → plantes sources

1. `GET /vitamines?id_contree=1`.
2. `GET /vitamines/1` : afficher `sources[].plante` ; ou utiliser `GET /sources-vitamine?id_vitamine=1`.
3. `GET /plantes/1` : charger les médias et noms locaux de la plante choisie.

L’association vitamine/plante contient uniquement ses deux identifiants. Aucune posologie, quantité de vitamine ou préparation spécifique n’est définie. Les indications de la plante concernent des maladies : ne pas les présenter comme une recette vitaminique.

### Affichage de la fiche plante

- Identité : `nom_francais`, `nom_scientifique`, `famille`.
- Reconnaissance : `description`, `repartition`, `reconnaissance_astuces`, `partie_utile` et `photos`.
- Noms : `noms_locaux[].nom_local` et `noms_locaux[].langue.nom` ; lire `audio_url` seulement si non null.
- Précautions : `contre_indications`, `effets_indesirables_connus`, `mise_en_garde_speciale` ; références : `reference_bibliographique`.
- La mise en garde est un texte ; aucun champ audio dédié n’existe pour elle.
- Les médias sont des URL externes à afficher/lire par le client ; l’API ne renvoie pas les fichiers binaires et ne garantit pas leur disponibilité.
- Masquer ou indiquer « non renseigné » pour les champs nulls ; prévoir les collections vides.
- L’avertissement général prévu par la maquette doit être porté par l’interface : aucun champ global de disclaimer n’est renvoyé par ces endpoints.

### Recherche et limites du parcours courant

Pas de moteur de recherche serveur ni de pagination. Une recherche locale peut filtrer une liste déjà chargée ; envoyer `?search=...` ne déclenche aucune recherche. Pas d’authentification client, favoris, historique personnel, géolocalisation, téléchargement hors ligne ni notifications implémentés. Aucune action de suivi n’est nécessaire pour le périmètre produit actuel.

## Dictionnaire des objets de sortie

Les objets « scalaires » ci-dessous contiennent uniquement les colonnes de l’entité. Les relations ajoutées par les lectures sont détaillées pour chaque endpoint. Les objets imbriqués scalaires ne sont pas développés récursivement.

### Objet `Contree`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_contree` | nombre entier | non |
| `nom` | chaîne | non |

### Objet `Langue`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_langue` | nombre entier | non |
| `nom` | chaîne | non |

### Objet `Maladie`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_maladie` | nombre entier | non |
| `nom` | chaîne | non |
| `est_urgence` | booléen | non |
| `regles_hygiene` | chaîne | oui |
| `id_contree` | nombre entier | non |

### Objet `Vitamine`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_vitamine` | nombre entier | non |
| `nom` | chaîne | non |
| `id_contree` | nombre entier | non |

### Objet `Plante`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_plante` | nombre entier | non |
| `nom_francais` | chaîne | non |
| `nom_scientifique` | chaîne | non |
| `famille` | chaîne | oui |
| `description` | chaîne | oui |
| `repartition` | chaîne | oui |
| `reconnaissance_astuces` | chaîne | oui |
| `partie_utile` | chaîne | oui |
| `contre_indications` | chaîne | oui |
| `effets_indesirables_connus` | chaîne | oui |
| `mise_en_garde_speciale` | chaîne | oui |
| `reference_bibliographique` | chaîne | oui |

### Objet `PhotoPlante`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_photo` | nombre entier | non |
| `id_plante` | nombre entier | non |
| `type` | chaîne | oui |
| `url` | chaîne | non |

### Objet `Methode`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_methode` | nombre entier | non |
| `nom` | chaîne | non |
| `description` | chaîne | oui |
| `id_contree` | nombre entier | non |

### Objet `NomLocal`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_plante` | nombre entier | non |
| `id_langue` | nombre entier | non |
| `nom_local` | chaîne | non |
| `audio_url` | chaîne | oui |

### Objet `Indication`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_indication` | nombre entier | non |
| `id_maladie` | nombre entier | non |
| `id_plante` | nombre entier | non |
| `methode_preparation` | chaîne | oui |
| `posologie` | chaîne | oui |
| `regles_hygieno_diet` | chaîne | oui |

### Objet `IndicationMethode`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_maladie` | nombre entier | non |
| `id_methode` | nombre entier | non |
| `description` | chaîne | oui |

### Objet `SourceVitamine`

| Propriété | Type JSON | Nullable |
|---|---|---|
| `id_vitamine` | nombre entier | non |
| `id_plante` | nombre entier | non |

## Référence des endpoints publics de consultation

### `contrees` — Contree

Nom unique. Trier les listes par nom est fait côté serveur.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /contrees` | public | Aucun filtre | 200 — tableau de `Contree` avec relations de liste ci-dessous |
| `GET /contrees/:id` | public | Chemin : `id` | 200 — un `Contree` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers.

Relations ajoutées à la liste : aucune.

Relations ajoutées au détail : aucune.

#### Exemple de lecture `GET /contrees/1`

```json
{
  "id_contree": 1,
  "nom": "Bénin"
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

### `langues` — Langue

Nom unique. Liste triée par nom.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /langues` | public | Aucun filtre | 200 — tableau de `Langue` avec relations de liste ci-dessous |
| `GET /langues/:id` | public | Chemin : `id` | 200 — un `Langue` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers.

Relations ajoutées à la liste : aucune.

Relations ajoutées au détail : aucune.

#### Exemple de lecture `GET /langues/1`

```json
{
  "id_langue": 1,
  "nom": "Fon"
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

### `plantes` — Plante

Nom scientifique unique. Pas de rattachement direct à un pays : passer par maladies/indications ou vitamines/sources. Liste triée par nom_francais.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /plantes` | public | Aucun filtre | 200 — tableau de `Plante` avec relations de liste ci-dessous |
| `GET /plantes/:id` | public | Chemin : `id` | 200 — un `Plante` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers.

Relations ajoutées à la liste : photos: PhotoPlante[] ; noms_locaux: (NomLocal + langue: Langue)[].

Relations ajoutées au détail : mêmes relations, plus indications: (Indication + maladie: Maladie)[].

#### Exemple de lecture `GET /plantes/1`

```json
{
  "id_plante": 1,
  "nom_francais": "Plante exemple",
  "nom_scientifique": "Species exemplum",
  "famille": "Famille exemple",
  "description": "Description éditoriale validée.",
  "repartition": "Bénin",
  "reconnaissance_astuces": "Critères de reconnaissance validés.",
  "partie_utile": "Partie documentée",
  "contre_indications": "Précautions documentées.",
  "effets_indesirables_connus": "Effets documentés.",
  "mise_en_garde_speciale": "Mise en garde validée.",
  "reference_bibliographique": "Référence documentaire",
  "photos": [
    {
      "id_photo": 1,
      "id_plante": 1,
      "type": "feuille",
      "url": "https://cdn.example.com/plante.jpg"
    }
  ],
  "noms_locaux": [
    {
      "id_plante": 1,
      "id_langue": 1,
      "nom_local": "Nom local exemple",
      "audio_url": "https://cdn.example.com/nom-fon.mp3",
      "langue": {
        "id_langue": 1,
        "nom": "Fon"
      }
    }
  ],
  "indications": [
    {
      "id_indication": 1,
      "id_maladie": 1,
      "id_plante": 1,
      "methode_preparation": "Préparation validée par le responsable du contenu.",
      "posologie": "Posologie validée par le responsable du contenu.",
      "regles_hygieno_diet": "Conseils validés.",
      "maladie": {
        "id_maladie": 1,
        "nom": "Maladie exemple",
        "est_urgence": false,
        "regles_hygiene": "Règles générales validées.",
        "id_contree": 1
      }
    }
  ]
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

### `maladies` — Maladie

est_urgence vaut false si omis à la création. Nom non unique. Liste triée par nom.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /maladies` | public | Query : `id_contree`, `est_urgence` | 200 — tableau de `Maladie` avec relations de liste ci-dessous |
| `GET /maladies/:id` | public | Chemin : `id` | 200 — un `Maladie` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers. Filtres : `id_contree` (entier), `est_urgence` (booléen converti, voir particularité ci-dessus).

Relations ajoutées à la liste : aucune.

Relations ajoutées au détail : contree: Contree ; indications: (Indication + plante: Plante)[] ; indications_methode: (IndicationMethode + methode: Methode)[].

#### Exemple de lecture `GET /maladies/1`

```json
{
  "id_maladie": 1,
  "nom": "Maladie exemple",
  "est_urgence": false,
  "regles_hygiene": "Règles générales validées.",
  "id_contree": 1,
  "contree": {
    "id_contree": 1,
    "nom": "Bénin"
  },
  "indications": [
    {
      "id_indication": 1,
      "id_maladie": 1,
      "id_plante": 1,
      "methode_preparation": "Préparation validée par le responsable du contenu.",
      "posologie": "Posologie validée par le responsable du contenu.",
      "regles_hygieno_diet": "Conseils validés.",
      "plante": {
        "id_plante": 1,
        "nom_francais": "Plante exemple",
        "nom_scientifique": "Species exemplum",
        "famille": "Famille exemple",
        "description": "Description éditoriale validée.",
        "repartition": "Bénin",
        "reconnaissance_astuces": "Critères de reconnaissance validés.",
        "partie_utile": "Partie documentée",
        "contre_indications": "Précautions documentées.",
        "effets_indesirables_connus": "Effets documentés.",
        "mise_en_garde_speciale": "Mise en garde validée.",
        "reference_bibliographique": "Référence documentaire"
      }
    }
  ],
  "indications_methode": [
    {
      "id_maladie": 1,
      "id_methode": 1,
      "description": "Description éditoriale validée.",
      "methode": {
        "id_methode": 1,
        "nom": "Méthode exemple",
        "description": "Description éditoriale validée.",
        "id_contree": 1
      }
    }
  ]
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

### `vitamines` — Vitamine

Nom non unique ; aucune restriction serveur à A/B/C/D. Liste triée par nom.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /vitamines` | public | Query : `id_contree` | 200 — tableau de `Vitamine` avec relations de liste ci-dessous |
| `GET /vitamines/:id` | public | Chemin : `id` | 200 — un `Vitamine` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers. Filtres : `id_contree` (entier).

Relations ajoutées à la liste : aucune.

Relations ajoutées au détail : contree: Contree ; sources: (SourceVitamine + plante: Plante)[].

#### Exemple de lecture `GET /vitamines/1`

```json
{
  "id_vitamine": 1,
  "nom": "Vitamine A",
  "id_contree": 1,
  "contree": {
    "id_contree": 1,
    "nom": "Bénin"
  },
  "sources": [
    {
      "id_vitamine": 1,
      "id_plante": 1,
      "plante": {
        "id_plante": 1,
        "nom_francais": "Plante exemple",
        "nom_scientifique": "Species exemplum",
        "famille": "Famille exemple",
        "description": "Description éditoriale validée.",
        "repartition": "Bénin",
        "reconnaissance_astuces": "Critères de reconnaissance validés.",
        "partie_utile": "Partie documentée",
        "contre_indications": "Précautions documentées.",
        "effets_indesirables_connus": "Effets documentés.",
        "mise_en_garde_speciale": "Mise en garde validée.",
        "reference_bibliographique": "Référence documentaire"
      }
    }
  ]
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

### `methodes` — Methode

Liste triée par nom. Le rattachement à une urgence se fait via indications-methode.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /methodes` | public | Query : `id_contree` | 200 — tableau de `Methode` avec relations de liste ci-dessous |
| `GET /methodes/:id` | public | Chemin : `id` | 200 — un `Methode` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers. Filtres : `id_contree` (entier).

Relations ajoutées à la liste : aucune.

Relations ajoutées au détail : contree: Contree ; indications_methode: (IndicationMethode + maladie: Maladie)[].

#### Exemple de lecture `GET /methodes/1`

```json
{
  "id_methode": 1,
  "nom": "Méthode exemple",
  "description": "Description éditoriale validée.",
  "id_contree": 1,
  "contree": {
    "id_contree": 1,
    "nom": "Bénin"
  },
  "indications_methode": [
    {
      "id_maladie": 1,
      "id_methode": 1,
      "description": "Description éditoriale validée.",
      "maladie": {
        "id_maladie": 1,
        "nom": "Maladie exemple",
        "est_urgence": false,
        "regles_hygiene": "Règles générales validées.",
        "id_contree": 1
      }
    }
  ]
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

### `indications` — Indication

Couple (id_maladie, id_plante) unique. La recette appartient à cette association. Pas de tri explicite sur la liste.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /indications` | public | Query : `id_maladie`, `id_plante` | 200 — tableau de `Indication` avec relations de liste ci-dessous |
| `GET /indications/:id` | public | Chemin : `id` | 200 — un `Indication` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers. Filtres : `id_maladie` (entier), `id_plante` (entier).

Relations ajoutées à la liste : maladie: Maladie ; plante: Plante.

Relations ajoutées au détail : maladie: Maladie ; plante: Plante.

#### Exemple de lecture `GET /indications/1`

```json
{
  "id_indication": 1,
  "id_maladie": 1,
  "id_plante": 1,
  "methode_preparation": "Préparation validée par le responsable du contenu.",
  "posologie": "Posologie validée par le responsable du contenu.",
  "regles_hygieno_diet": "Conseils validés.",
  "maladie": {
    "id_maladie": 1,
    "nom": "Maladie exemple",
    "est_urgence": false,
    "regles_hygiene": "Règles générales validées.",
    "id_contree": 1
  },
  "plante": {
    "id_plante": 1,
    "nom_francais": "Plante exemple",
    "nom_scientifique": "Species exemplum",
    "famille": "Famille exemple",
    "description": "Description éditoriale validée.",
    "repartition": "Bénin",
    "reconnaissance_astuces": "Critères de reconnaissance validés.",
    "partie_utile": "Partie documentée",
    "contre_indications": "Précautions documentées.",
    "effets_indesirables_connus": "Effets documentés.",
    "mise_en_garde_speciale": "Mise en garde validée.",
    "reference_bibliographique": "Référence documentaire"
  }
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

### `indications-methode` — IndicationMethode

Clé composite (id_maladie, id_methode). Le serveur vérifie l’existence des deux références, mais ne vérifie ni est_urgence=true ni l’égalité de leurs pays. Pas de tri explicite.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /indications-methode` | public | Query : `id_maladie`, `id_methode` | 200 — tableau de `IndicationMethode` avec relations de liste ci-dessous |
| `GET /indications-methode/:id_maladie/:id_methode` | public | Chemin : `id_maladie/id_methode` | 200 — un `IndicationMethode` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers. Filtres : `id_maladie` (entier), `id_methode` (entier).

Relations ajoutées à la liste : maladie: Maladie ; methode: Methode.

Relations ajoutées au détail : maladie: Maladie ; methode: Methode.

#### Exemple de lecture `GET /indications-methode/1/1`

```json
{
  "id_maladie": 1,
  "id_methode": 1,
  "description": "Description éditoriale validée.",
  "maladie": {
    "id_maladie": 1,
    "nom": "Maladie exemple",
    "est_urgence": false,
    "regles_hygiene": "Règles générales validées.",
    "id_contree": 1
  },
  "methode": {
    "id_methode": 1,
    "nom": "Méthode exemple",
    "description": "Description éditoriale validée.",
    "id_contree": 1
  }
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

### `sources-vitamine` — SourceVitamine

Clé composite (id_vitamine, id_plante). Aucun PATCH : supprimer puis recréer pour changer le lien. Aucune préparation/posologie propre à la vitamine. Pas de tri explicite.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /sources-vitamine` | public | Query : `id_vitamine`, `id_plante` | 200 — tableau de `SourceVitamine` avec relations de liste ci-dessous |
| `GET /sources-vitamine/:id_vitamine/:id_plante` | public | Chemin : `id_vitamine/id_plante` | 200 — un `SourceVitamine` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers. Filtres : `id_vitamine` (entier), `id_plante` (entier).

Relations ajoutées à la liste : plante: Plante ; vitamine: Vitamine.

Relations ajoutées au détail : plante: Plante ; vitamine: Vitamine.

#### Exemple de lecture `GET /sources-vitamine/1/1`

```json
{
  "id_vitamine": 1,
  "id_plante": 1,
  "plante": {
    "id_plante": 1,
    "nom_francais": "Plante exemple",
    "nom_scientifique": "Species exemplum",
    "famille": "Famille exemple",
    "description": "Description éditoriale validée.",
    "repartition": "Bénin",
    "reconnaissance_astuces": "Critères de reconnaissance validés.",
    "partie_utile": "Partie documentée",
    "contre_indications": "Précautions documentées.",
    "effets_indesirables_connus": "Effets documentés.",
    "mise_en_garde_speciale": "Mise en garde validée.",
    "reference_bibliographique": "Référence documentaire"
  },
  "vitamine": {
    "id_vitamine": 1,
    "nom": "Vitamine A",
    "id_contree": 1
  }
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

### `noms-locaux` — NomLocal

Un seul enregistrement par couple plante/langue. audio_url est une chaîne facultative, sans validation URL ni upload. Pas de tri explicite.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /noms-locaux` | public | Query : `id_plante`, `id_langue` | 200 — tableau de `NomLocal` avec relations de liste ci-dessous |
| `GET /noms-locaux/:id_plante/:id_langue` | public | Chemin : `id_plante/id_langue` | 200 — un `NomLocal` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers. Filtres : `id_plante` (entier), `id_langue` (entier).

Relations ajoutées à la liste : langue: Langue.

Relations ajoutées au détail : langue: Langue.

#### Exemple de lecture `GET /noms-locaux/1/1`

```json
{
  "id_plante": 1,
  "id_langue": 1,
  "nom_local": "Nom local exemple",
  "audio_url": "https://cdn.example.com/nom-fon.mp3",
  "langue": {
    "id_langue": 1,
    "nom": "Fon"
  }
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

### `photos-plante` — PhotoPlante

url est une chaîne non vide, sans validation de format URL ni upload. Aucune déduplication ni notion d’ordre de galerie. Pas de tri explicite.

| Méthode et endpoint | Accès | Entrée | Succès et sortie |
|---|---|---|---|
| `GET /photos-plante` | public | Query : `id_plante` | 200 — tableau de `PhotoPlante` avec relations de liste ci-dessous |
| `GET /photos-plante/:id` | public | Chemin : `id` | 200 — un `PhotoPlante` avec relations de détail ci-dessous ; 404 si absent |

Tous les paramètres de chemin sont des entiers. Filtres : `id_plante` (entier).

Relations ajoutées à la liste : aucune.

Relations ajoutées au détail : aucune.

#### Exemple de lecture `GET /photos-plante/1`

```json
{
  "id_photo": 1,
  "id_plante": 1,
  "type": "feuille",
  "url": "https://cdn.example.com/plante.jpg"
}
```

La liste renvoie un tableau de ces objets avec uniquement les relations de liste indiquées ci-dessus.

## Exemple d’intégration JavaScript

```js
const BASE_URL = 'https://phytot-rapie-app-backend-production.up.railway.app';

async function getJson(path) {
  const response = await fetch(`${BASE_URL}${path}`);
  if (!response.ok) {
    const body = await response.json().catch(() => null);
    const detail = Array.isArray(body?.message)
      ? body.message.join(', ')
      : body?.message;
    throw new Error(detail || `Erreur HTTP ${response.status}`);
  }
  return response.json();
}

async function chargerMaladiesOrdinaires(idContree) {
  const maladies = await getJson(`/maladies?id_contree=${idContree}`);
  return maladies.filter(maladie => maladie.est_urgence === false);
}

async function chargerRecette(idIndication) {
  const indication = await getJson(`/indications/${idIndication}`);
  const plante = await getJson(`/plantes/${indication.id_plante}`);
  return { indication, plante };
}
```

Pour une réponse 404, afficher une ressource indisponible et permettre le retour à la liste. Pour `[]`, afficher un état vide. Prévoir aussi les erreurs réseau et les erreurs 5xx. Ne pas appeler `response.json()` après un DELETE 204 (les DELETE appartiennent à l’administration).

## Annexe technique — suivi reporté

Ces routes existent dans le code mais ne font pas partie des parcours à livrer maintenant. Aucun appel à ces endpoints n’est requis pour consulter une recette. Cette annexe recense leur contrat actuel, sans annoncer de rappel automatique.

| Endpoint | Accès | Entrée | Sortie |
|---|---|---|---|
| `POST /suivis-utilisation` | public | Corps création ci-dessous | 201, SuiviUtilisation scalaire |
| `GET /suivis-utilisation` | public | Query facultative `id_indication` entier, `en_attente` booléen converti | 200, tableau de SuiviUtilisation scalaires, date_consultation décroissante |
| `GET /suivis-utilisation/:id` | public | id entier | 200, SuiviUtilisation + indication contenant maladie et plante scalaires ; 404 si absent |
| `POST /suivis-utilisation/:id/repondre` | public | id entier + questionnaire ci-dessous | 201, SuiviUtilisation scalaire ; 404 si absent |
| `DELETE /suivis-utilisation/:id` | admin JWT | id entier | 204 sans corps ; 401/404 selon le cas |

### Création

`id_indication` obligatoire, entier converti en nombre ; `date_consultation` facultative, chaîne ISO de date valide. Si absente, date serveur actuelle. 400 si indication inexistante ou DTO invalide.

```json
{"id_indication":1,"date_consultation":"2026-10-18T09:00:00.000Z"}
```

### Réponse au questionnaire

| Champ | Type | Obligatoire / validation |
|---|---|---|
| a_utilise | booléen JSON | obligatoire |
| comment_prepare | chaîne | facultatif |
| voie_administration | chaîne | facultatif |
| frequence_prise | chaîne | facultatif |
| effet_anormal | chaîne | facultatif |
| age | entier converti | facultatif, 0 à 120 |
| sexe | chaîne | facultatif, pas d’énumération |
| diabete | booléen JSON | facultatif |
| hta | booléen JSON | facultatif |
| ulcere | booléen JSON | facultatif |
| constipation_chr | booléen JSON | facultatif |

```json
{"a_utilise":false}
```

La réponse renseigne automatiquement `date_reponse` à l’heure serveur. Aucun délai de 48 h n’est imposé ; répondre à nouveau met à jour les champs envoyés et l’horodatage. Le serveur n’impose pas de branche conditionnelle selon a_utilise. `en_attente=true` filtre date_reponse=null ; `en_attente=false` subit le même problème de conversion que est_urgence et ne permet pas de demander les réponses terminées.

### Objet de sortie scalaire

```json
{
  "id_suivi": 1,
  "id_indication": 1,
  "date_consultation": "2026-10-18T09:00:00.000Z",
  "date_reponse": null,
  "a_utilise": null,
  "comment_prepare": null,
  "voie_administration": null,
  "frequence_prise": null,
  "effet_anormal": null,
  "age": null,
  "sexe": null,
  "diabete": null,
  "hta": null,
  "ulcere": null,
  "constipation_chr": null
}
```

Tous les champs du questionnaire sont nullables en sortie, date_reponse aussi ; les deux identifiants et date_consultation sont obligatoires. Aucun identifiant de compte ou d’appareil, token de possession du suivi, consentement, notification ou job de rappel n’est présent dans ce contrat. La lecture et la réponse sont actuellement publiques et ne vérifient pas le propriétaire du suivi.
