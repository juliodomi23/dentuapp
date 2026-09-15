import 'package:dentu_app/ui/hoy/reto21_mensajes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el mensaje cambia según el día del Reto 21', () {
    expect(mensajeReto21(1), '¡Vas arrancando!');
    expect(mensajeReto21(2), '¡Vas arrancando!');
    expect(mensajeReto21(3), 'Le vas agarrando el ritmo.');
    expect(mensajeReto21(7), 'Ya llevas una semana.');
    expect(mensajeReto21(14), 'Va que va, ya casi llegas.');
    expect(mensajeReto21(21), '¡Completaste el Reto 21!');
  });
}
