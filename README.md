# 📜 dart_quill_delta_robust

A **hardened, production-ready fork** of [`dart_quill_delta`](https://github.com/FlutterQuill/dart-quill-delta) for the [`flutter_quill`](https://pub.dev/packages/flutter_quill) ecosystem.

An unofficial Dart port of [quill-js-delta](https://github.com/quilljs/delta/), originally written in TypeScript. It implements the [Quill Delta](https://www.npmjs.com/package/quill-delta) format — a JSON-based data structure used to describe rich-text documents and their changes. For the full format reference, see the official [Quill Delta documentation](https://quilljs.com/docs/delta/).

> **⚠️ Breaking change**: Optional `attributes` parameters on `insert` / `retain` (both `Delta` methods and `Operation` factories) are now **named** instead of positional. See below.

## Why this fork?

This fork is maintained as part of the **robust** family of forks, sharing the same rigor across all projects:

- **API hardening**: `insert(dynamic data, {Map<String, dynamic>? attributes})` and `retain(int count, {Map<String, dynamic>? attributes})` use **named** `attributes:` — an explicit, self-documenting signature.
- **Strict analysis**: enforced with [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) plus Axomind customization (`strict-casts`, `strict-inference`, `strict-raw-types`).
- **Fork identity**: repository, homepage and issue tracker point to this fork; `publish_to: none`.
- **Bug fixes**: carries upstream-corrected `diff` (deep `Map` equality) and SDK constraint updates.

## Breaking change — named `attributes:`

```dart
// Before (positional)
delta.insert('Hello', {'bold': true});
delta.retain(3, {'color': 'red'});

// After (named)
delta.insert('Hello', attributes: {'bold': true});
delta.retain(3, attributes: {'color': 'red'});
```

The same applies to `Operation.insert(...)` and `Operation.retain(...)`. Single-argument calls (no attributes) are unaffected.

## Usage

```dart
import 'package:dart_quill_delta/dart_quill_delta.dart';

final doc = Delta()
  ..insert('Hello world', attributes: {'h': '1'})
  ..retain(6, attributes: {'bold': true})
  ..insert('\n');
```

## Getting started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dart_quill_delta:
    git:
      url: https://github.com/Sebastien-VZN/dart_quill_delta_robust.git
```

Then run `dart pub get` (or `flutter pub get`) and import the package:

```dart
import 'package:dart_quill_delta/dart_quill_delta.dart';
```

## 📚 Documentation

For detailed usage and API references, refer to the official [Quill Delta documentation](https://quilljs.com/docs/delta/).

## 📜 Acknowledgments

* The original package [dart_quill_delta](https://github.com/FlutterQuill/dart-quill-delta).
* [quill-js-delta](https://github.com/quilljs/delta/) and [Delta Delta](https://github.com/slab/delta).

---

[Français](./README_FR.md)
