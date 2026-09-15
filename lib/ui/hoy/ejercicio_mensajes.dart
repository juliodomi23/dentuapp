/// Copy de aliado, no de juez: en 0 minutos no se regaña, se invita.
/// Se usa tanto en la tarjeta rápida de "Hoy" como en la vista de detalle.
String? notaEjercicio(int minutos, bool habilitado) {
  if (!habilitado || minutos > 0) return null;
  return 'Hoy fue un día de descanso, o uno para retomar 🙂';
}

/// Tips genéricos de ejercicio y caminata, mientras la clínica no manda
/// recomendaciones personalizadas por paciente.
const List<String> kTipsEjercicio = [
  'Caminar 20-30 minutos al día ya cuenta como actividad real, no hace falta el gym.',
  'Sube escaleras en vez de elevador cuando puedas: son minutos de más sin planearlo.',
  'Estira 5 minutos antes y después de caminar o hacer ejercicio para cuidar tus articulaciones.',
  'Si un día no puedes hacer una rutina completa, una caminata corta sigue sumando a tu racha.',
  'Camina después de comer: ayuda a la digestión y a mantener estable el azúcar en la sangre.',
  'La constancia importa más que la intensidad: 15 minutos todos los días superan una hora una vez a la semana.',
];
