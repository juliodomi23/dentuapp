import 'package:dentu_app/utils/rachas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('esHitoRacha', () {
    test('los días 3, 7, 14 y 21 son hito', () {
      for (final dia in [3, 7, 14, 21]) {
        expect(esHitoRacha(dia), isTrue, reason: 'día $dia debería ser hito');
      }
    });

    test('los demás días no son hito', () {
      for (final dia in [0, 1, 2, 4, 6, 8, 13, 15, 20, 22]) {
        expect(esHitoRacha(dia), isFalse, reason: 'día $dia no debería ser hito');
      }
    });
  });
}
