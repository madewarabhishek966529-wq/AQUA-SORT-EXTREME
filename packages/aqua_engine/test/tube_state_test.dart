import 'package:aqua_engine/aqua_engine.dart';
import 'package:test/test.dart';

void main() {
  group('TubeState', () {
    test('empty tube properties', () {
      final empty = TubeState.empty();
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
      expect(empty.isFull, isFalse);
      expect(empty.freeSpace, equals(4));
      expect(empty.topColor, isNull);
      expect(empty.topColorCount, equals(0));
      expect(empty.isSingleColor, isFalse);
      expect(empty.isSolved, isTrue);
      expect(empty.colorChanges, equals(0));
      expect(empty.encode(), equals(''));
    });

    test('single color full tube is solved', () {
      final tube = TubeState([1, 1, 1, 1]);
      expect(tube.isEmpty, isFalse);
      expect(tube.isFull, isTrue);
      expect(tube.freeSpace, equals(0));
      expect(tube.topColor, equals(1));
      expect(tube.topColorCount, equals(4));
      expect(tube.isSingleColor, isTrue);
      expect(tube.isSolved, isTrue);
      expect(tube.colorChanges, equals(0));
      expect(tube.encode(), equals('1,1,1,1'));
    });

    test('partial tube is not solved', () {
      final tube = TubeState([1, 1]);
      expect(tube.isEmpty, isFalse);
      expect(tube.isFull, isFalse);
      expect(tube.freeSpace, equals(2));
      expect(tube.topColor, equals(1));
      expect(tube.topColorCount, equals(2));
      expect(tube.isSingleColor, isTrue);
      expect(tube.isSolved, isFalse); // not full!
    });

    test('mixed color tube is not solved', () {
      final tube = TubeState([1, 2, 2, 2]);
      expect(tube.isFull, isTrue);
      expect(tube.topColor, equals(2));
      expect(tube.topColorCount, equals(3));
      expect(tube.isSingleColor, isFalse);
      expect(tube.isSolved, isFalse);
      expect(tube.colorChanges, equals(1));
    });

    test('color changes count transitions', () {
      expect(TubeState([1, 2, 3, 4]).colorChanges, equals(3));
      expect(TubeState([1, 1, 2, 1]).colorChanges, equals(2));
      expect(TubeState([1, 1, 1, 2]).colorChanges, equals(1));
      expect(TubeState([2, 2, 2, 2]).colorChanges, equals(0));
    });

    test('withPouredOut and withPouredIn', () {
      final original = TubeState([1, 2, 2, 2]);
      final pouredOut = original.withPouredOut(2);
      expect(pouredOut.units, equals([1, 2]));

      final pouredIn = pouredOut.withPouredIn(2, 2);
      expect(pouredIn, equals(original));
    });

    test('serialization and encoding round-trip', () {
      final tube = TubeState([3, 3, 4, 4]);
      final encoded = tube.encode();
      final decoded = TubeState.decode(encoded);
      expect(decoded, equals(tube));

      final json = tube.toJson();
      final fromJson = TubeState.fromJson(json);
      expect(fromJson, equals(tube));
    });

    test('capacity bounds validation', () {
      expect(() => TubeState([1, 2, 3, 4, 5]), throwsArgumentError);
      expect(() => TubeState.empty(capacity: 0), throwsArgumentError);
    });
  });
}
