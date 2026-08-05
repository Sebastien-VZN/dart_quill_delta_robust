import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

void main() {
  group('invertAttributes', () {
    test('attr is null', () {
      final base = <String, dynamic>{'bold': true};
      expect(Delta.invertAttributes(null, base), <String, dynamic>{});
    });

    test('base is null', () {
      final attributes = <String, dynamic>{'bold': true};
      final expected = <String, dynamic>{'bold': null};
      expect(Delta.invertAttributes(attributes, null), expected);
    });

    test('both null', () {
      expect(Delta.invertAttributes(null, null), <String, dynamic>{});
    });

    test('merge', () {
      final attributes = <String, dynamic>{'bold': true};
      final base = <String, dynamic>{'italic': true};
      final expected = <String, dynamic>{'bold': null};
      expect(Delta.invertAttributes(attributes, base), expected);
    });

    test('null', () {
      final attributes = <String, dynamic>{'bold': null};
      final base = <String, dynamic>{'bold': true};
      final expected = <String, dynamic>{'bold': true};
      expect(Delta.invertAttributes(attributes, base), expected);
    });

    test('replace', () {
      final attributes = <String, dynamic>{'color': 'red'};
      final base = <String, dynamic>{'color': 'blue'};
      final expected = base;
      expect(Delta.invertAttributes(attributes, base), expected);
    });

    test('noop', () {
      final attributes = <String, dynamic>{'color': 'red'};
      final base = <String, dynamic>{'color': 'red'};
      final expected = <String, dynamic>{};
      expect(Delta.invertAttributes(attributes, base), expected);
    });

    test('combined', () {
      final attributes = {
        'bold': true,
        'italic': null,
        'color': 'red',
        'size': '12px',
      };
      final base = {
        'font': 'serif',
        'italic': true,
        'color': 'blue',
        'size': '12px',
      };
      final expected = {'bold': null, 'italic': true, 'color': 'blue'};
      expect(Delta.invertAttributes(attributes, base), expected);
    });
  });

  group('composeAttributes', () {
    const attributes = {'b': true, 'color': 'red'};

    test('left is null', () {
      expect(Delta.composeAttributes(null, attributes), attributes);
    });

    test('right is null', () {
      expect(Delta.composeAttributes(attributes, null), attributes);
    });

    test('both are null', () {
      expect(Delta.composeAttributes(null, null), isNull);
    });

    test('missing', () {
      expect(
        Delta.composeAttributes(attributes, const {'i': true}),
        {'b': true, 'color': 'red', 'i': true},
      );
    });

    test('overwrite', () {
      expect(
        Delta.composeAttributes(
          attributes,
          const {'b': false, 'color': 'blue'},
        ),
        {'b': false, 'color': 'blue'},
      );
    });

    test('remove', () {
      expect(
        Delta.composeAttributes(attributes, const {'b': null}),
        {'color': 'red'},
      );
    });

    test('remove to null', () {
      expect(
        Delta.composeAttributes(attributes, const {'b': null, 'color': null}),
        isNull,
      );
    });

    test('remove missing', () {
      expect(
        Delta.composeAttributes(attributes, const {'i': null}),
        attributes,
      );
    });
  });

  group('transformAttributes', () {
    const left = {'bold': true, 'color': 'red', 'font': null};
    const right = {'color': 'blue', 'font': 'serif', 'italic': true};

    test('left is null', () {
      expect(Delta.transformAttributes(null, left, false), left);
    });

    test('right is null', () {
      expect(Delta.transformAttributes(left, null, false), null);
    });

    test('both are null', () {
      expect(Delta.transformAttributes(null, null, false), null);
    });

    test('with priority', () {
      expect(
        Delta.transformAttributes(left, right, true),
        const {'italic': true},
      );
    });

    test('without priority', () {
      expect(Delta.transformAttributes(left, right, false), right);
    });
  });

  group('$Operation', () {
    test('insert factory', () {
      final op = Operation.insert('a', attributes: const {'b': true});
      expect(op.isInsert, isTrue);
      expect(op.length, 1);
      expect(op.attributes, const {'b': true});
    });

    test('insert (object) factory', () {
      final op =
          Operation.insert(<String, dynamic>{}, attributes: const {'b': true});
      expect(op.isInsert, isTrue);
      expect(op.length, 1);
      expect(op.attributes, const {'b': true});
    });

    test('delete factory', () {
      final op = Operation.delete(5);
      expect(op.isDelete, isTrue);
      expect(op.length, 5);
      expect(op.attributes, isNull);
    });

    test('retain factory', () {
      final op = Operation.retain(5, attributes: const {'b': true});
      expect(op.isRetain, isTrue);
      expect(op.length, 5);
      expect(op.attributes, const {'b': true});
    });

    test('isPlain', () {
      final op1 = Operation.retain(1);
      final op2 = Operation.retain(1, attributes: {});
      final op3 = Operation.retain(1, attributes: {'b': true});
      expect(op1.isPlain, isTrue);
      expect(op2.isPlain, isTrue);
      expect(op3.isPlain, isFalse);
      expect(op1.isNotPlain, isFalse);
      expect(op2.isNotPlain, isFalse);
      expect(op3.isNotPlain, isTrue);
    });

    test('isEmpty', () {
      final op1 = Operation.retain(0);
      final op2 = Operation.retain(0, attributes: {});
      final op3 = Operation.retain(1);
      expect(op1.isEmpty, isTrue);
      expect(op2.isEmpty, isTrue);
      expect(op3.isEmpty, isFalse);
      expect(op1.isNotEmpty, isFalse);
      expect(op2.isNotEmpty, isFalse);
      expect(op3.isNotEmpty, isTrue);
    });

    test('equality', () {
      final op1 = Operation.insert('a');
      final op2 =
          Operation.insert('b', attributes: const {'h': '1', 'b': true});
      final op3 =
          Operation.insert('b', attributes: const {'h': true, 'b': '1'});
      final op4 = Operation.insert('a');
      expect(op1, isNot(op2));
      expect(op2, isNot(op3));
      expect(op1, op4);
    });

    test('hashCode', () {
      final op1 =
          Operation.insert('b', attributes: const {'h': '1', 'b': true});
      final op2 =
          Operation.insert('b', attributes: const {'h': '1', 'b': true});
      final op3 =
          Operation.insert('b', attributes: const {'h': true, 'b': '1'});
      expect(op2.hashCode, isNot(op3.hashCode));
      expect(op2.hashCode, op1.hashCode);
    });

    test('toString', () {
      final op1 = Operation.insert(
        'Hello world!\nAnd fancy line-breaks.\n',
        attributes: {'b': true},
      );
      final op2 = Operation.retain(3, attributes: {'b': '1'});
      final op3 = Operation.delete(3);
      final op4 = Operation.insert({'a': 1}, attributes: {'b': true});
      expect(
        '$op1',
        'insert⟨ Hello world!⏎And fancy line-breaks.⏎ ⟩ + {b: true}',
      );
      expect('$op2', 'retain⟨ 3 ⟩ + {b: 1}');
      expect('$op3', 'delete⟨ 3 ⟩');
      expect('$op4', 'insert⟨ {a: 1} ⟩ + {b: true}');
    });

    test('attributes immutable', () {
      final op = Operation.insert('\n', attributes: {'b': true});
      final attrs = op.attributes!;
      attrs['b'] = null;
      expect(op.attributes, {'b': true});
    });

    test('attributes operator== simple', () {
      final op1 = Operation.insert('\n', attributes: {'b': true});
      final op2 = Operation.insert('\n', attributes: {'b': true});
      expect(op1 == op2, isTrue);
    });

    test('attributes operator== complex', () {
      final op1 = Operation.insert(
        '\n',
        attributes: {
          'b': {'c': 'd'},
        },
      );
      final op2 = Operation.insert(
        '\n',
        attributes: {
          'b': {'c': 'd'},
        },
      );
      expect(op1 == op2, isTrue);
    });
  });

  group('Delta', () {
    test('isEmpty', () {
      final delta = Delta();
      expect(delta, isEmpty);
    });

    test('json', () {
      final delta = Delta()
        ..insert('abc', attributes: {'b': true})
        ..insert('def')
        ..insert({'a': 1});
      final result = json.encode(delta);
      expect(
        result,
        '[{"insert":"abc","attributes":{"b":true}},{"insert":"def"},{"insert":{"a":1}}]',
      );
      final decoded = Delta.fromJson(json.decode(result) as List<dynamic>);
      expect(decoded, delta);
    });

    test('toString', () {
      final delta = Delta()
        ..insert('Hello world!', attributes: {'b': true})
        ..retain(5);
      expect('$delta', 'insert⟨ Hello world! ⟩ + {b: true}\nretain⟨ 5 ⟩');
    });

    group('invert', () {
      test('insert', () {
        final delta = Delta()
          ..retain(2)
          ..insert('A');
        final base = Delta()..insert('123456');
        final expected = Delta()
          ..retain(2)
          ..delete(1);
        final inverted = delta.invert(base);
        expect(expected, inverted);
        expect(base.compose(delta).compose(inverted), base);
      });

      test('delete', () {
        final delta = Delta()
          ..retain(2)
          ..delete(3);
        final base = Delta()..insert('123456');
        final expected = Delta()
          ..retain(2)
          ..insert('345');
        final inverted = delta.invert(base);
        expect(expected, inverted);
        expect(base.compose(delta).compose(inverted), base);
      });

      test('retain', () {
        final delta = Delta()
          ..retain(2)
          ..retain(3, attributes: {'b': true});
        final base = Delta()..insert('123456');
        final expected = Delta()
          ..retain(2)
          ..retain(3, attributes: {'b': null});
        final inverted = delta.invert(base);
        expect(expected, inverted);
        expect(base.compose(delta).compose(inverted), base);
      });

      test('retain on a delta with different attributes', () {
        final base = Delta()
          ..insert('123')
          ..insert('4', attributes: {'b': true});
        final delta = Delta()..retain(4, attributes: {'i': true});
        final expected = Delta()..retain(4, attributes: {'i': null});
        final inverted = delta.invert(base);
        expect(expected, inverted);
        expect(base.compose(delta).compose(inverted), base);
      });

      test('combined', () {
        final delta = Delta()
          ..retain(2)
          ..delete(2)
          ..insert('AB', attributes: {'italic': true})
          ..retain(2, attributes: {'italic': null, 'bold': true})
          ..retain(2, attributes: {'color': 'red'})
          ..delete(1);
        final base = Delta()
          ..insert('123', attributes: {'bold': true})
          ..insert('456', attributes: {'italic': true})
          ..insert('789', attributes: {'color': 'red', 'bold': true});
        final expected = Delta()
          ..retain(2)
          ..insert('3', attributes: {'bold': true})
          ..insert('4', attributes: {'italic': true})
          ..delete(2)
          ..retain(2, attributes: {'italic': true, 'bold': null})
          ..retain(2)
          ..insert('9', attributes: {'color': 'red', 'bold': true});

        final inverted = delta.invert(base);
        expect(inverted, expected);
        expect(base.compose(delta).compose(inverted), base);
      });
    });

    group('push', () {
      // ==== insert combinations ====

      test('insert + insert', () {
        final delta = Delta()
          ..insert('abc')
          ..insert('123');
        expect(delta.first, Operation.insert('abc123'));
      });

      test('insert + insert (object)', () {
        const data = <String, dynamic>{};
        final delta = Delta()
          ..insert('abc')
          ..insert(data);
        expect(delta[0], Operation.insert('abc'));
        expect(delta[1], Operation.insert(data));
      });

      test('insert (object) + insert', () {
        const data = <String, dynamic>{};
        final delta = Delta()
          ..insert(data)
          ..insert('abc');
        expect(delta[0], Operation.insert(data));
        expect(delta[1], Operation.insert('abc'));
      });

      test('insert + delete', () {
        final delta = Delta()
          ..insert('abc')
          ..delete(3);
        expect(delta[0], Operation.insert('abc'));
        expect(delta[1], Operation.delete(3));
      });

      test('insert (object) + delete', () {
        final delta = Delta()
          ..insert(const <String, dynamic>{})
          ..delete(3);
        expect(delta[0], Operation.insert(const <String, dynamic>{}));
        expect(delta[1], Operation.delete(3));
      });

      test('insert + retain', () {
        final delta = Delta()
          ..insert('abc')
          ..retain(3);
        expect(delta[0], Operation.insert('abc'));
        expect(delta[1], Operation.retain(3));
      });

      test('insert (object) + retain', () {
        final delta = Delta()
          ..insert(const <String, dynamic>{})
          ..retain(3);
        expect(delta[0], Operation.insert(const <String, dynamic>{}));
        expect(delta[1], Operation.retain(3));
      });

      // ==== delete combinations ====

      test('delete + insert', () {
        final delta = Delta()
          ..delete(2)
          ..insert('abc');
        expect(delta[0], Operation.insert('abc'));
        expect(delta[1], Operation.delete(2));
      });

      test('delete + insert (object)', () {
        final delta = Delta()
          ..delete(2)
          ..insert(const <String, dynamic>{});
        expect(delta[0], Operation.insert(const <String, dynamic>{}));
        expect(delta[1], Operation.delete(2));
      });

      test('delete + delete', () {
        final delta = Delta()
          ..delete(2)
          ..delete(3);
        expect(delta.first, Operation.delete(5));
      });

      test('delete + retain', () {
        final delta = Delta()
          ..delete(2)
          ..retain(3);
        expect(delta[0], Operation.delete(2));
        expect(delta[1], Operation.retain(3));
      });

      // ==== retain combinations ====

      test('retain + insert', () {
        final delta = Delta()
          ..retain(2)
          ..insert('abc');
        expect(delta[0], Operation.retain(2));
        expect(delta[1], Operation.insert('abc'));
      });

      test('retain + insert (object)', () {
        final delta = Delta()
          ..retain(2)
          ..insert(const <String, dynamic>{});
        expect(delta[0], Operation.retain(2));
        expect(delta[1], Operation.insert(const <String, dynamic>{}));
      });

      test('retain + delete', () {
        final delta = Delta()
          ..retain(2)
          ..delete(3);
        expect(delta[0], Operation.retain(2));
        expect(delta[1], Operation.delete(3));
      });

      test('retain + retain', () {
        final delta = Delta()
          ..retain(2)
          ..retain(3);
        expect(delta.first, Operation.retain(5));
      });

      // ==== edge scenarios ====

      test('consequent inserts with different attributes do not merge', () {
        final delta = Delta()
          ..insert('abc', attributes: const {'b': true})
          ..insert('123');
        expect(delta.toList(), [
          Operation.insert('abc', attributes: const {'b': true}),
          Operation.insert('123'),
        ]);
      });

      test('consequent inserts (object) do not merge', () {
        final delta = Delta()
          ..insert(const <String, dynamic>{})
          ..insert(const <String, dynamic>{});
        expect(delta.toList(), [
          Operation.insert(const <String, dynamic>{}),
          Operation.insert(const <String, dynamic>{}),
        ]);
      });

      test('consequent inserts (object) with different attributes do not merge',
          () {
        final delta = Delta()
          ..insert(const <String, dynamic>{}, attributes: const {'b': true})
          ..insert(const <String, dynamic>{});
        expect(delta.toList(), [
          Operation.insert(
            const <String, dynamic>{},
            attributes: const {'b': true},
          ),
          Operation.insert(const <String, dynamic>{}),
        ]);
      });

      test('consequent inserts (object) with same attributes do not merge', () {
        final delta = Delta()
          ..insert(const <String, dynamic>{}, attributes: const {'b': true})
          ..insert(const <String, dynamic>{}, attributes: const {'b': true});
        expect(delta.toList(), [
          Operation.insert(
            const <String, dynamic>{},
            attributes: const {'b': true},
          ),
          Operation.insert(
            const <String, dynamic>{},
            attributes: const {'b': true},
          ),
        ]);
      });

      test('consequent retain with different attributes do not merge', () {
        final delta = Delta()
          ..retain(5, attributes: const {'b': true})
          ..retain(3);
        expect(delta.toList(), [
          Operation.retain(5, attributes: const {'b': true}),
          Operation.retain(3),
        ]);
      });

      test('consequent inserts with same attributes merge', () {
        final ul = {'block': 'ul'};
        final doc = Delta()
          ..insert('DartConf')
          ..insert('\n', attributes: ul)
          ..insert('Los Angeles')
          ..insert('\n', attributes: ul);
        final change = Delta()
          ..retain(8)
          ..insert('\n', attributes: ul);
        final result = doc.compose(change);
        final expected = Delta()
          ..insert('DartConf')
          ..insert('\n\n', attributes: ul)
          ..insert('Los Angeles')
          ..insert('\n', attributes: ul);
        expect(result, expected);
      });

      test('consequent deletes and inserts', () {
        final doc = Delta()..insert('YOLOYOLO');
        final change = Delta()
          ..insert('YATA')
          ..delete(4)
          ..insert('YATA');
        final result = doc.compose(change);
        final expected = Delta()..insert('YATAYATAYOLO');
        expect(result, expected);
      });

      test('consequent deletes and inserts (object)', () {
        final doc = Delta()
          ..insert(const <String, dynamic>{})
          ..insert(const <String, dynamic>{})
          ..insert(const <String, dynamic>{});
        final change = Delta()
          ..insert('YATA')
          ..delete(2)
          ..insert('YATA');
        final result = doc.compose(change);
        final expected = Delta()
          ..insert('YATAYATA')
          ..insert(const <String, dynamic>{});
        expect(result, expected);
      });
    });
    group('compose', () {
      // ==== insert combinations ====

      test('insert + insert', () {
        final a = Delta()..insert('A');
        final b = Delta()..insert('B');
        final expected = Delta()..insert('BA');
        expect(a.compose(b), expected);
      });

      test('insert + insert (object)', () {
        final a = Delta()..insert('A');
        final b = Delta()..insert(const <String, dynamic>{});
        final expected = Delta()
          ..insert(const <String, dynamic>{})
          ..insert('A');
        expect(a.compose(b), expected);
      });

      test('insert (object) + insert', () {
        final a = Delta()..insert(const <String, dynamic>{});
        final b = Delta()..insert('B');
        final expected = Delta()
          ..insert('B')
          ..insert(const <String, dynamic>{});
        expect(a.compose(b), expected);
      });

      test('insert + delete', () {
        final a = Delta()..insert('A');
        final b = Delta()..delete(1);
        expect(a.compose(b), isEmpty);
      });

      test('insert (object) + delete', () {
        final a = Delta()..insert(const <String, dynamic>{});
        final b = Delta()..delete(1);
        expect(a.compose(b), isEmpty);
      });

      test('insert + retain', () {
        final a = Delta()..insert('A');
        final b = Delta()..retain(1, attributes: const {'b': true});
        expect(a.compose(b).toList(), [
          Operation.insert('A', attributes: const {'b': true}),
        ]);
      });

      test('insert (object) + retain', () {
        final a = Delta()..insert(const <String, dynamic>{});
        final b = Delta()..retain(1, attributes: const {'b': true});
        expect(a.compose(b).toList(), [
          Operation.insert(
            const <String, dynamic>{},
            attributes: const {'b': true},
          ),
        ]);
      });

      // ==== delete combinations ====

      test('delete + insert', () {
        final a = Delta()..delete(1);
        final b = Delta()..insert('B');
        final expected = Delta()
          ..insert('B')
          ..delete(1);
        expect(a.compose(b), expected);
      });

      test('delete + insert (object)', () {
        final a = Delta()..delete(1);
        final b = Delta()..insert(const <String, dynamic>{});
        final expected = Delta()
          ..insert(const <String, dynamic>{})
          ..delete(1);
        expect(a.compose(b), expected);
      });

      test('delete + delete', () {
        final a = Delta()..delete(1);
        final b = Delta()..delete(1);
        final expected = Delta()..delete(2);
        expect(a.compose(b), expected);
      });

      test('delete + retain', () {
        final a = Delta()..delete(1);
        final b = Delta()..retain(1, attributes: const {'b': true});
        final expected = Delta()
          ..delete(1)
          ..retain(1, attributes: const {'b': true});
        expect(a.compose(b), expected);
      });

      // ==== retain combinations ====

      test('retain + insert', () {
        final a = Delta()..retain(1, attributes: const {'b': true});
        final b = Delta()..insert('B');
        final expected = Delta()
          ..insert('B')
          ..retain(1, attributes: const {'b': true});
        expect(a.compose(b), expected);
      });

      test('retain + insert (object)', () {
        final a = Delta()..retain(1, attributes: const {'b': true});
        final b = Delta()..insert(const <String, dynamic>{});
        final expected = Delta()
          ..insert(const <String, dynamic>{})
          ..retain(1, attributes: const {'b': true});
        expect(a.compose(b), expected);
      });

      test('retain + delete', () {
        final a = Delta()..retain(1, attributes: const {'b': true});
        final b = Delta()..delete(1);
        final expected = Delta()..delete(1);
        expect(a.compose(b), expected);
      });

      test('retain + retain', () {
        final a = Delta()..retain(1, attributes: const {'color': 'blue'});
        final b = Delta()
          ..retain(1, attributes: const {'color': 'red', 'b': true});
        final expected = Delta()
          ..retain(1, attributes: const {'color': 'red', 'b': true});
        expect(a.compose(b), expected);
      });

      // ===== other scenarios =====

      test('insert in middle of text', () {
        final a = Delta()..insert('Hello');
        final b = Delta()
          ..retain(3)
          ..insert('X');
        final expected = Delta()..insert('HelXlo');
        expect(a.compose(b), expected);
      });

      test('insert (object) in middle of text', () {
        final a = Delta()..insert('Hello');
        final b = Delta()
          ..retain(3)
          ..insert(const <String, dynamic>{});
        final expected = Delta()
          ..insert('Hel')
          ..insert(const <String, dynamic>{})
          ..insert('lo');
        expect(a.compose(b), expected);
      });

      test('insert and delete ordering', () {
        final a = Delta()..insert('Hello');
        final b = Delta()..insert('Hello');
        final insertFirst = Delta()
          ..retain(3)
          ..insert('X')
          ..delete(1);
        final deleteFirst = Delta()
          ..retain(3)
          ..delete(1)
          ..insert('X');
        final expected = Delta()..insert('HelXo');
        expect(a.compose(insertFirst), expected);
        expect(b.compose(deleteFirst), expected);
      });

      test('insert (object) and delete ordering', () {
        final a = Delta()
          ..insert(const [1])
          ..insert(const [2])
          ..insert(const [3]);
        final b = Delta()
          ..insert(const [1])
          ..insert(const [2])
          ..insert(const [3]);
        final insertFirst = Delta()
          ..retain(2)
          ..insert('X')
          ..delete(1);
        final deleteFirst = Delta()
          ..retain(2)
          ..delete(1)
          ..insert('X');
        final expected = Delta()
          ..insert(const [1])
          ..insert(const [2])
          ..insert('X');
        expect(a.compose(insertFirst), expected);
        expect(b.compose(deleteFirst), expected);
      });

      test('delete entire text', () {
        final a = Delta()
          ..retain(4)
          ..insert('Hello');
        final b = Delta()..delete(9);
        final expected = Delta()..delete(4);
        expect(a.compose(b), expected);
      });

      test('delete object', () {
        final a = Delta()
          ..retain(4)
          ..insert(const <String, dynamic>{});
        final b = Delta()..delete(5);
        final expected = Delta()..delete(4);
        expect(a.compose(b), expected);
      });

      test('retain more than length of text', () {
        final a = Delta()..insert('Hello');
        final b = Delta()..retain(10);
        final expected = Delta()..insert('Hello');
        expect(a.compose(b), expected);
      });

      test('retain more than length of op with object', () {
        final a = Delta()..insert(const <String, dynamic>{});
        final b = Delta()..retain(10);
        final expected = Delta()..insert(const <String, dynamic>{});
        expect(a.compose(b), expected);
      });

      test('remove all attributes', () {
        final a = Delta()..insert('A', attributes: const {'b': true});
        final b = Delta()..retain(1, attributes: const {'b': null});
        final expected = Delta()..insert('A');
        expect(a.compose(b), expected);
      });

      test('remove all attributes in object', () {
        final a = Delta()
          ..insert(const <String, dynamic>{}, attributes: const {'b': true});
        final b = Delta()..retain(1, attributes: const {'b': null});
        final expected = Delta()..insert(const <String, dynamic>{});
        expect(a.compose(b), expected);
      });
    });

    group('transform', () {
      test('insert + insert', () {
        final a1 = Delta()..insert('A');
        final b1 = Delta()..insert('B');
        final a2 = Delta.from(a1);
        final b2 = Delta.from(b1);
        final expected1 = Delta()
          ..retain(1)
          ..insert('B');
        final expected2 = Delta()..insert('B');
        expect(a1.transform(b1, true), expected1);
        expect(a2.transform(b2, false), expected2);
      });

      test('insert + insert (object)', () {
        final a1 = Delta()..insert('A');
        final b1 = Delta()..insert(const <String, dynamic>{});
        final a2 = Delta.from(a1);
        final b2 = Delta.from(b1);
        final expected1 = Delta()
          ..retain(1)
          ..insert(const <String, dynamic>{});
        final expected2 = Delta()..insert(const <String, dynamic>{});
        expect(a1.transform(b1, true), expected1);
        expect(a2.transform(b2, false), expected2);
      });

      test('insert + retain', () {
        final a = Delta()..insert('A');
        final b = Delta()
          ..retain(1, attributes: const {'bold': true, 'color': 'red'});
        final expected = Delta()
          ..retain(1)
          ..retain(1, attributes: const {'bold': true, 'color': 'red'});
        expect(a.transform(b, true), expected);
      });

      test('insert (object) + retain', () {
        final a = Delta()..insert(const <String, dynamic>{});
        final b = Delta()
          ..retain(1, attributes: const {'bold': true, 'color': 'red'});
        final expected = Delta()
          ..retain(1)
          ..retain(1, attributes: const {'bold': true, 'color': 'red'});
        expect(a.transform(b, true), expected);
      });

      test('insert + delete', () {
        final a = Delta()..insert('A');
        final b = Delta()..delete(1);
        final expected = Delta()
          ..retain(1)
          ..delete(1);
        expect(a.transform(b, true), expected);
      });

      test('insert (object) + delete', () {
        final a = Delta()..insert(const <String, dynamic>{});
        final b = Delta()..delete(1);
        final expected = Delta()
          ..retain(1)
          ..delete(1);
        expect(a.transform(b, true), expected);
      });

      test('delete + insert', () {
        final a = Delta()..delete(1);
        final b = Delta()..insert('B');
        final expected = Delta()..insert('B');
        expect(a.transform(b, true), expected);
      });

      test('delete + insert (object)', () {
        final a = Delta()..delete(1);
        final b = Delta()..insert(const <String, dynamic>{});
        final expected = Delta()..insert(const <String, dynamic>{});
        expect(a.transform(b, true), expected);
      });

      test('delete + retain', () {
        final a = Delta()..delete(1);
        final b = Delta()
          ..retain(1, attributes: const {'bold': true, 'color': 'red'});
        final expected = Delta();
        expect(a.transform(b, true), expected);
      });

      test('delete + delete', () {
        final a = Delta()..delete(1);
        final b = Delta()..delete(1);
        final expected = Delta();
        expect(a.transform(b, true), expected);
      });

      test('retain + insert', () {
        final a = Delta()..retain(1, attributes: const {'color': 'blue'});
        final b = Delta()..insert('B');
        final expected = Delta()..insert('B');
        expect(a.transform(b, true), expected);
      });

      test('retain + insert (object)', () {
        final a = Delta()..retain(1, attributes: const {'color': 'blue'});
        final b = Delta()..insert(const <String, dynamic>{});
        final expected = Delta()..insert(const <String, dynamic>{});
        expect(a.transform(b, true), expected);
      });

      test('retain + retain', () {
        final a1 = Delta()..retain(1, attributes: const {'color': 'blue'});
        final b1 = Delta()
          ..retain(1, attributes: const {'bold': true, 'color': 'red'});
        final a2 = Delta()..retain(1, attributes: const {'color': 'blue'});
        final b2 = Delta()
          ..retain(1, attributes: const {'bold': true, 'color': 'red'});
        final expected1 = Delta()..retain(1, attributes: const {'bold': true});
        final expected2 = Delta();
        expect(a1.transform(b1, true), expected1);
        expect(b2.transform(a2, true), expected2);
      });

      test('retain + retain without priority', () {
        final a1 = Delta()..retain(1, attributes: const {'color': 'blue'});
        final b1 = Delta()
          ..retain(1, attributes: const {'bold': true, 'color': 'red'});
        final a2 = Delta()..retain(1, attributes: const {'color': 'blue'});
        final b2 = Delta()
          ..retain(1, attributes: const {'bold': true, 'color': 'red'});
        final expected1 = Delta()
          ..retain(1, attributes: const {'bold': true, 'color': 'red'});
        final expected2 = Delta()
          ..retain(1, attributes: const {'color': 'blue'});
        expect(a1.transform(b1, false), expected1);
        expect(b2.transform(a2, false), expected2);
      });

      test('retain + delete', () {
        final a = Delta()..retain(1, attributes: const {'color': 'blue'});
        final b = Delta()..delete(1);
        final expected = Delta()..delete(1);
        expect(a.transform(b, true), expected);
      });

      test('alternating edits', () {
        final a1 = Delta()
          ..retain(2)
          ..insert('si')
          ..delete(5);
        final b1 = Delta()
          ..retain(1)
          ..insert('e')
          ..delete(5)
          ..retain(1)
          ..insert('ow');
        final a2 = Delta.from(a1);
        final b2 = Delta.from(b1);
        final expected1 = Delta()
          ..retain(1)
          ..insert('e')
          ..delete(1)
          ..retain(2)
          ..insert('ow');
        final expected2 = Delta()
          ..retain(2)
          ..insert('si')
          ..delete(1);
        expect(a1.transform(b1, false), expected1);
        expect(b2.transform(a2, false), expected2);
      });

      test('conflicting appends', () {
        final a1 = Delta()
          ..retain(3)
          ..insert('aa');
        final b1 = Delta()
          ..retain(3)
          ..insert('bb');
        final a2 = Delta.from(a1);
        final b2 = Delta.from(b1);
        final expected1 = Delta()
          ..retain(5)
          ..insert('bb');
        final expected2 = Delta()
          ..retain(3)
          ..insert('aa');
        expect(a1.transform(b1, true), expected1);
        expect(b2.transform(a2, false), expected2);
      });

      test('prepend + append', () {
        final a1 = Delta()..insert('aa');
        final b1 = Delta()
          ..retain(3)
          ..insert('bb');
        final expected1 = Delta()
          ..retain(5)
          ..insert('bb');
        final a2 = Delta.from(a1);
        final b2 = Delta.from(b1);
        final expected2 = Delta()..insert('aa');
        expect(a1.transform(b1, false), expected1);
        expect(b2.transform(a2, false), expected2);
      });

      test('trailing deletes with differing lengths', () {
        final a1 = Delta()
          ..retain(2)
          ..delete(1);
        final b1 = Delta()..delete(3);
        final expected1 = Delta()..delete(2);
        final a2 = Delta.from(a1);
        final b2 = Delta.from(b1);
        final expected2 = Delta();
        expect(a1.transform(b1, false), expected1);
        expect(b2.transform(a2, false), expected2);
      });
    });

    group('transformPosition', () {
      test('insert before position', () {
        final delta = Delta()..insert('A');
        expect(delta.transformPosition(2), 3);
      });

      test('insert (object) before position', () {
        final delta = Delta()..insert(const <String, dynamic>{});
        expect(delta.transformPosition(2), 3);
      });

      test('insert after position', () {
        final delta = Delta()
          ..retain(2)
          ..insert('A');
        expect(delta.transformPosition(1), 1);
      });

      test('insert (object) after position', () {
        final delta = Delta()
          ..retain(2)
          ..insert(const <String, dynamic>{});
        expect(delta.transformPosition(1), 1);
      });

      test('insert at position', () {
        final delta = Delta()
          ..retain(2)
          ..insert('A');
        expect(delta.transformPosition(2, force: false), 2);
        expect(delta.transformPosition(2), 3);
      });

      test('insert (object) at position', () {
        final delta = Delta()
          ..retain(2)
          ..insert(const <String, dynamic>{});
        expect(delta.transformPosition(2, force: false), 2);
        expect(delta.transformPosition(2), 3);
      });

      test('delete before position', () {
        final delta = Delta()..delete(2);
        expect(delta.transformPosition(4), 2);
      });

      test('delete after position', () {
        final delta = Delta()
          ..retain(4)
          ..delete(2);
        expect(delta.transformPosition(2), 2);
      });

      test('delete across position', () {
        final delta = Delta()
          ..retain(1)
          ..delete(4);
        expect(delta.transformPosition(2), 1);
      });

      test('insert and delete before position', () {
        final delta = Delta()
          ..retain(2)
          ..insert('A')
          ..delete(2);
        expect(delta.transformPosition(4), 3);
      });

      test('insert before and delete across position', () {
        final delta = Delta()
          ..retain(2)
          ..insert('A')
          ..delete(4);
        expect(delta.transformPosition(4), 3);
      });

      test('delete before and delete across position', () {
        final delta = Delta()
          ..delete(1)
          ..retain(1)
          ..delete(4);
        expect(delta.transformPosition(4), 1);
      });
    });

    group('slice', () {
      test('start', () {
        final slice = (Delta()
              ..retain(2)
              ..insert('A'))
            .slice(2);
        final expected = Delta()..insert('A');
        expect(slice, expected);
      });

      test('start and end chop', () {
        final slice = (Delta()..insert('0123456789')).slice(2, 7);
        final expected = Delta()..insert('23456');
        expect(slice, expected);
      });

      test('start and end multiple chop', () {
        final slice = (Delta()
              ..insert('0123', attributes: {'bold': true})
              ..insert('4567'))
            .slice(3, 5);
        final expected = Delta()
          ..insert('3', attributes: {'bold': true})
          ..insert('4');
        expect(slice, expected);
      });

      test('start and end', () {
        final slice = (Delta()
              ..retain(2)
              ..insert('A', attributes: {'bold': true})
              ..insert('B'))
            .slice(2, 3);
        final expected = Delta()..insert('A', attributes: {'bold': true});
        expect(slice, expected);
      });

      test('start and end objects', () {
        final slice = (Delta()
              ..insert(const [1])
              ..insert(const [2])
              ..insert(const [3])
              ..insert(const [4])
              ..insert(const [5]))
            .slice(2, 3);
        final expected = Delta()..insert(const [3]);
        expect(slice, expected);
      });

      test('from beginning', () {
        final delta = Delta()
          ..retain(2)
          ..insert('A', attributes: {'bold': true})
          ..insert('B');
        final slice = delta.slice(0);
        expect(slice, delta);
      });

      test('split ops', () {
        final slice = (Delta()
              ..insert('AB', attributes: {'bold': true})
              ..insert('C'))
            .slice(1, 2);
        final expected = Delta()..insert('B', attributes: {'bold': true});
        expect(slice, expected);
      });

      test('split ops multiple times', () {
        final slice = (Delta()
              ..insert('ABC', attributes: {'bold': true})
              ..insert('D'))
            .slice(1, 2);
        final expected = Delta()..insert('B', attributes: {'bold': true});
        expect(slice, expected);
      });
    });

    group('diff', () {
      test('insert', () {
        final a = Delta()..insert('A');
        final b = Delta()..insert('AB');
        final expected = Delta()
          ..retain(1)
          ..insert('B');
        expect(a.diff(b), expected);
      });

      test('delete', () {
        final a = Delta()..insert('AB');
        final b = Delta()..insert('A');
        final expected = Delta()
          ..retain(1)
          ..delete(1);
        expect(a.diff(b), expected);
      });

      test('retain', () {
        final a = Delta()..insert('A');
        final b = Delta()..insert('A');
        final expected = Delta();
        expect(a.diff(b), expected);
      });

      test('format', () {
        final a = Delta()..insert('A');
        final b = Delta()..insert('A', attributes: {'b': true});
        final expected = Delta()..retain(1, attributes: {'b': true});
        expect(a.diff(b), expected);
      });

      test('object attributes', () {
        final a = Delta()
          ..insert(
            'A',
            attributes: {
              'font': {'family': 'Helvetica', 'size': '15px'},
            },
          );
        final b = Delta()
          ..insert(
            'A',
            attributes: {
              'font': {'family': 'Helvetica', 'size': '15px'},
            },
          );
        final expected = Delta();
        expect(a.diff(b), expected);
      });

      test('embed integer match', () {
        final a = Delta()..insert(1);
        final b = Delta()..insert(1);
        final expected = Delta();
        expect(a.diff(b), expected);
      });

      test('embed integer mismatch', () {
        final a = Delta()..insert(1);
        final b = Delta()..insert(2);
        final expected = Delta()
          ..delete(1)
          ..insert(2);
        expect(a.diff(b), expected);
      });

      test('embed object match', () {
        final a = Delta()..insert({'image': 'http://google.com'});
        final b = Delta()..insert({'image': 'http://google.com'});
        final expected = Delta();
        expect(a.diff(b), expected);
      });

      test('embed object match #2', () {
        final a = Delta()
          ..insert({'image': 'http://google.com'})
          ..insert('\n');
        final b = Delta()..insert({'image': 'http://google.com'});
        final expected = Delta()
          ..retain(1)
          ..delete(1);
        expect(a.diff(b), expected);
      });

      test('embed object mismatch', () {
        final a = Delta()
          ..insert({
            'image': 'http://google.com',
            'alt': 'Overwrite',
          });
        final b = Delta()..insert({'image': 'http://google.com'});
        final expected = Delta()
          ..insert({'image': 'http://google.com'})
          ..delete(1);
        expect(a.diff(b), expected);
      });

      test('embed object change', () {
        final a = Delta()..insert({'image': 'http://google.com'});
        final b = Delta()..insert({'image': 'http://github.com'});
        final expected = Delta()
          ..insert({'image': 'http://github.com'})
          ..delete(1);
        expect(a.diff(b), expected);
      });

      test('embed false positive', () {
        final a = Delta()..insert(1);
        final b = Delta()
          ..insert(
            String.fromCharCode(0),
          ); // Placeholder char for embed in diff()
        final expected = Delta()
          ..insert(String.fromCharCode(0))
          ..delete(1);
        expect(a.diff(b), expected);
      });

      test('error on non-documents', () {
        final a = Delta()..insert('A');
        final b = Delta()
          ..retain(1)
          ..insert('B');
        expect(() => a.diff(b), throwsArgumentError);
        expect(() => b.diff(a), throwsArgumentError);
      });

      test('inconvenient indexes', () {
        final a = Delta()
          ..insert('12', attributes: {'b': true})
          ..insert('34', attributes: {'i': true});
        final b = Delta()..insert('123', attributes: {'bg': 'red'});
        final expected = Delta()
          ..retain(2, attributes: {'b': null, 'bg': 'red'})
          ..retain(1, attributes: {'i': null, 'bg': 'red'})
          ..delete(1);
        expect(a.diff(b), expected);
      });

      test('combination', () {
        final a = Delta()
          ..insert('Bad', attributes: {'bg': 'red'})
          ..insert('cat', attributes: {'bg': 'blue'});
        final b = Delta()
          ..insert('Good', attributes: {'b': true})
          ..insert('dog', attributes: {'i': true});
        final expected = Delta()
          ..insert('Good', attributes: {'b': true})
          ..delete(2)
          ..retain(1, attributes: {'i': true, 'bg': null})
          ..delete(3)
          ..insert('og', attributes: {'i': true});
        expect(a.diff(b, cleanupSemantic: false), expected);
      });

      test('cleanup semantic', () {
        final a = Delta()
          ..insert('Bad', attributes: {'bg': 'red'})
          ..insert('cat', attributes: {'bg': 'blue'});
        final b = Delta()
          ..insert('Good', attributes: {'b': true})
          ..insert('dog', attributes: {'i': true});
        final expected = Delta()
          ..insert('Good', attributes: {'b': true})
          ..insert('dog', attributes: {'i': true})
          ..delete(6);
        expect(a.diff(b), expected);
      });

      test('same document', () {
        final a = Delta()
          ..insert('A')
          ..insert('B', attributes: {'b': true});
        final expected = Delta();
        expect(a.diff(a), expected);
      });

      test('non-document', () {
        final a = Delta()..insert('Test');
        final b = Delta()..delete(4);
        expect(() => a.diff(b), throwsArgumentError);
      });
    });
  });

  group('DeltaIterator', () {
    final delta = Delta()
      ..insert('Hello', attributes: {'b': true})
      ..retain(3)
      ..insert(' world', attributes: {'i': true})
      ..insert(Embed('hr'))
      ..delete(4);
    late DeltaIterator iterator;

    setUp(() {
      iterator = DeltaIterator(delta);
    });

    test('hasNext', () {
      expect(iterator.hasNext, isTrue);
      iterator
        ..next()
        ..next()
        ..next()
        ..next()
        ..next();
      expect(iterator.hasNext, isFalse);
    });

    test('peekLength', () {
      expect(iterator.peekLength(), 5);
      iterator.next();
      expect(iterator.peekLength(), 3);
      iterator.next();
      expect(iterator.peekLength(), 6);
      iterator.next();
      expect(iterator.peekLength(), 1);
      iterator.next();
      expect(iterator.peekLength(), 4);
      iterator.next();
    });

    test('peekLength with operation split', () {
      iterator.next(2);
      expect(iterator.peekLength(), 5 - 2);
    });

    test('peekLength after EOF', () {
      iterator.skip(19);
      expect(iterator.peekLength(), DeltaIterator.maxLength);
    });

    test('peek operation type', () {
      expect(iterator.isNextInsert, isTrue);
      iterator.next();
      expect(iterator.isNextRetain, isTrue);
      iterator.next();
      expect(iterator.isNextInsert, isTrue);
      iterator.next();
      expect(iterator.isNextInsert, isTrue);
      iterator.next();
      expect(iterator.isNextDelete, isTrue);
      iterator.next();
    });

    test('next', () {
      expect(
        iterator.next(),
        Operation.insert('Hello', attributes: {'b': true}),
      );
      expect(iterator.next(), Operation.retain(3));
      expect(
        iterator.next(),
        Operation.insert(' world', attributes: {'i': true}),
      );
      expect(iterator.next(), Operation.insert(Embed('hr')));
      expect(iterator.next(), Operation.delete(4));
    });

    test('next with operation split', () {
      expect(iterator.next(2), Operation.insert('He', attributes: {'b': true}));
      expect(
        iterator.next(10),
        Operation.insert('llo', attributes: {'b': true}),
      );
      expect(iterator.next(1), Operation.retain(1));
      expect(iterator.next(2), Operation.retain(2));
    });

    test('next after EOF', () {
      iterator.skip(19);
      expect(iterator.next(), Operation.retain(DeltaIterator.maxLength));
    });
  });
}

class Embed {
  Embed(this.data);
  final String data;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Embed) return false;
    final typedOther = other;
    return typedOther.data == data;
  }

  @override
  int get hashCode => data.hashCode;

  Map<String, dynamic> toJson() => {'data': data};
}
