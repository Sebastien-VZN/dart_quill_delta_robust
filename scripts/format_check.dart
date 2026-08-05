import 'dart:io';

/// Runs `dart format --set-exit-if-changed` on every `.dart` file in the
/// repository, excluding generated/build directories.
///
/// Mirrors the CI `dart format --output=none --set-exit-if-changed .` check
/// so contributors can run the exact same gate locally before pushing.
void main() {
  final root = Directory.current;
  final excludedDirs = <String>{
    '${root.path}${Platform.pathSeparator}build',
    '${root.path}${Platform.pathSeparator}.dart_tool',
  };

  final files = <String>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final dir = entity.parent.path;
    if (excludedDirs.any(dir.startsWith)) continue;

    files.add(entity.path);
  }

  if (files.isEmpty) {
    stderr.writeln('No Dart files found to format.');
    exit(1);
  }

  final result = Process.runSync(
    'dart',
    ['format', '--output=none', '--set-exit-if-changed', ...files],
    runInShell: true,
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exit(result.exitCode);
}
