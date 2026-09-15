/// Mensaje corto según el día del Reto 21, para que la barra se sienta como
/// un logro que avanza y no como una barra de progreso genérica.
String mensajeReto21(int dia) {
  if (dia >= 21) return '¡Completaste el Reto 21!';
  if (dia >= 14) return 'Va que va, ya casi llegas.';
  if (dia >= 7) return 'Ya llevas una semana.';
  if (dia >= 3) return 'Le vas agarrando el ritmo.';
  return '¡Vas arrancando!';
}

/// 21 días de corrido se sienten lejanos; dividirlos en 3 hitos narrativos da
/// razones para volver entre semana y semana, no solo al final.
const List<String> kTramosReto21 = [
  'Semana 1: rompiste el hielo',
  'Semana 2: ya es hábito',
  'Semana 3: lo lograste',
];

/// Índice (0-2) del último tramo de 7 días completado, o -1 si ninguno.
int tramoCompletadoReto21(int dia) {
  if (dia >= 21) return 2;
  if (dia >= 14) return 1;
  if (dia >= 7) return 0;
  return -1;
}
