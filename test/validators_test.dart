import 'package:dormio/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('valid', () => expect(Validators.email('elena@arts-kyoto.ac.jp'), isNull));
    test('invalid', () => expect(Validators.email('elena@'), isNotNull));
    test('empty', () => expect(Validators.email(''), isNotNull));
  });

  group('phone', () {
    test('accepts formatted PH number', () => expect(Validators.phone('0917 123 4567'), isNull));
    test('accepts E.164', () => expect(Validators.phone('+639171234567'), isNull));
    test('rejects letters', () => expect(Validators.phone('abc12345'), isNotNull));
    test('toE164 drops leading zero', () {
      expect(Validators.toE164('+81', '080-1234-5678'), '+818012345678');
    });
  });

  group('password', () {
    test('too short', () => expect(Validators.password('a1!'), isNotNull));
    test('no number', () => expect(Validators.password('abcdefgh!'), isNotNull));
    test('no symbol', () => expect(Validators.password('abcdefg1'), isNotNull));
    test('valid', () => expect(Validators.password('abcdef1!'), isNull));
    test('strength bar', () {
      expect(Validators.passwordStrength('abc'), 1);
      expect(Validators.passwordStrength('Abcdef1!'), 4);
    });
  });

  group('numbers and dates', () {
    test('price', () {
      expect(Validators.price('4,500'), isNull);
      expect(Validators.price('0'), isNotNull);
      expect(Validators.price('free'), isNotNull);
    });
    test('move-in date cannot be in the past', () {
      expect(Validators.moveInDate(DateTime.now().subtract(const Duration(days: 3))), isNotNull);
      expect(Validators.moveInDate(DateTime.now().add(const Duration(days: 3))), isNull);
    });
    test('duration', () {
      expect(Validators.durationMonths(0), isNotNull);
      expect(Validators.durationMonths(6), isNull);
      expect(Validators.durationMonths(30), isNotNull);
    });
  });
}
