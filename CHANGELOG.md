# Changelog

All notable changes to this project will be documented in this file.

## 10.9.1
- Update package flutter

## 10.9.0

* **BREAKING CHANGE**: Uses named arguments for `attributes` on `insert`/`retain` operations. Update call sites to pass `attributes` as a named parameter.
* Bumps version to `10.9.0`.

## 10.8.3

* Updates `Delta.diff` check to use Map equality instead of reference equality [#2](https://github.com/FlutterQuill/dart-quill-delta/pull/2).

## 10.8.2

* Updates the minimum required Dart SDK from `3.2.0` to `3.0.0` for improved compatibility.

## 10.8.1

* Separates [dart_quill_delta](https://pub.dev/packages/dart_quill_delta) version from [flutter_quill](https://pub.dev/packages/flutter_quill). Discussed in [Flutter Quill #2259](https://github.com/singerdmx/flutter-quill/issues/2259)