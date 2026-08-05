// This example intentionally uses `print` to demonstrate output, so the
// `avoid_print` lint is not relevant here.
// ignore_for_file: avoid_print
import 'package:dart_quill_delta/dart_quill_delta.dart';

void main() {
  final doc = Delta()..insert('Hello world', attributes: {'h': '1'});
  final change = Delta()
    ..retain(6)
    ..delete(5)
    ..insert('Earth');
  final result = doc.compose(change);
  print('Original document:\n$doc\n');
  print('Change:\n$change\n');
  print('Updated document:\n$result\n');

  /// Prints:
  ///
  ///     Original document:
  ///     ins⟨Hello world⟩ + {h: 1}
  ///
  ///     Change:
  ///     ret⟨6⟩
  ///     ins⟨Earth⟩
  ///     del⟨5⟩
  ///
  ///     Updated document:
  ///     ins⟨Hello ⟩ + {h: 1}
  ///     ins⟨Earth⟩
}
