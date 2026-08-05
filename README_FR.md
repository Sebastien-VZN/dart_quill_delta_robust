# 📜 dart_quill_delta_robust

Un **fork renforcé, prêt pour la production** de [`dart_quill_delta`](https://github.com/FlutterQuill/dart-quill-delta) pour l'écosystème [`flutter_quill`](https://pub.dev/packages/flutter_quill).

Un portage non officiel en Dart de [quill-js-delta](https://github.com/quilljs/delta/), initialement écrit en TypeScript. Il implémente le format [Quill Delta](https://www.npmjs.com/package/quill-delta) — une structure de données JSON décrivant des documents texte enrichi et leurs modifications. Pour la référence complète du format, voir la [documentation officielle Quill Delta](https://quilljs.com/docs/delta/).

> **⚠️ Changement majeur** : le paramètre optionnel `attributes` de `insert` / `retain` (méthodes `Delta` et factories `Operation`) devient **nommé** au lieu de positionnel. Voir ci-dessous.

## Pourquoi ce fork ?

Ce fork fait partie de la famille **robust**, qui partage la même rigueur sur tous les projets :

- **API durcie** : `insert(dynamic data, {Map<String, dynamic>? attributes})` et `retain(int count, {Map<String, dynamic>? attributes})` utilisent `attributes:` **nommé** — une signature explicite et auto-documentée.
- **Analyse stricte** : imposée via [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) avec personnalisation Axomind (`strict-casts`, `strict-inference`, `strict-raw-types`).
- **Identité du fork** : repository, homepage et issue tracker pointent vers ce fork ; `publish_to: none`.
- **Corrections** : `diff` upstream-corrigé (égalité profonde des `Map`) et mises à jour des contraintes SDK.

## Changement majeur — `attributes:` nommé

```dart
// Avant (positionnel)
delta.insert('Bonjour', {'bold': true});
delta.retain(3, {'color': 'red'});

// Après (nommé)
delta.insert('Bonjour', attributes: {'bold': true});
delta.retain(3, attributes: {'color': 'red'});
```

Idem pour `Operation.insert(...)` et `Operation.retain(...)`. Les appels sans attributs ne sont pas impactés.

## Utilisation

```dart
import 'package:dart_quill_delta/dart_quill_delta.dart';

final doc = Delta()
  ..insert('Bonjour le monde', attributes: {'h': '1'})
  ..retain(6, attributes: {'bold': true})
  ..insert('\n');
```

## Démarrage

Ajoutez la dépendance à votre `pubspec.yaml` :

```yaml
dependencies:
  dart_quill_delta:
    git:
      url: https://github.com/Sebastien-VZN/dart_quill_delta_robust.git
```

Puis lancez `dart pub get` (ou `flutter pub get`) et importez le package :

```dart
import 'package:dart_quill_delta/dart_quill_delta.dart';
```

## 📚 Documentation

Pour l'usage détaillé et la référence API, voir la [documentation officielle Quill Delta](https://quilljs.com/docs/delta/).

## 📜 Remerciements

* Le package original [dart_quill_delta](https://github.com/FlutterQuill/dart-quill-delta).
* [quill-js-delta](https://github.com/quilljs/delta/) et [Delta Delta](https://github.com/slab/delta).
