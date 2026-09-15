import 'package:intl/intl.dart';

import '../config/constantes.dart';

const String _locale = 'es_MX';

final RegExp _formatoFechaIso = RegExp(r'^\d{4}-\d{2}-\d{2}$');

DateTime soloFecha(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);

/// `DateTime` → `"YYYY-MM-DD"`.
String fechaIso(DateTime fecha) {
  final anio = fecha.year.toString().padLeft(4, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '$anio-$mes-$dia';
}

/// `"YYYY-MM-DD"` → `DateTime` local a medianoche. Devuelve null si no es válida.
DateTime? parsearFechaIso(String texto) {
  if (!_formatoFechaIso.hasMatch(texto)) return null;
  final fecha = DateTime.tryParse(texto);
  if (fecha == null || fechaIso(fecha) != texto) return null;
  return fecha;
}

String diaSemanaDe(DateTime fecha) => kDiasSemana[fecha.weekday - 1];

/// Días de `desde` a `hasta` (negativo si `hasta` es antes). Ignora horas.
int diasEntre(DateTime desde, DateTime hasta) {
  final a = DateTime.utc(desde.year, desde.month, desde.day);
  final b = DateTime.utc(hasta.year, hasta.month, hasta.day);
  return b.difference(a).inDays;
}

DateTime sumarDias(DateTime fecha, int dias) =>
    DateTime(fecha.year, fecha.month, fecha.day + dias);

/// "Jueves 11 sep". Requiere `initializeDateFormatting('es_MX')` (se hace en main).
String textoFechaConDia(DateTime fecha) =>
    _capitalizar(DateFormat('EEEE d MMM', _locale).format(fecha));

/// "11 sep".
String textoFechaCorta(DateTime fecha) =>
    DateFormat('d MMM', _locale).format(fecha);

/// "14 de marzo de 1990".
String textoFechaLarga(DateTime fecha) =>
    DateFormat("d 'de' MMMM 'de' y", _locale).format(fecha);

String _capitalizar(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);
