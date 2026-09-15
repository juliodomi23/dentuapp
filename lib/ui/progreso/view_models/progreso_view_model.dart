import 'package:flutter/foundation.dart';

import '../../../config/constantes.dart';
import '../../../data/models/progreso.dart';
import '../../../data/repositories/progreso_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/fechas.dart';
import '../../../utils/rachas.dart';
import '../../../utils/result.dart';
import '../../core/mensaje_error.dart';

/// Un punto de la gráfica: `x` = días desde el primer peso.
typedef PuntoGraficaPeso = ({double x, double peso, String origen, String fecha});

class ProgresoViewModel extends ChangeNotifier {
  ProgresoViewModel({required ProgresoRepository progreso})
    : _repositorio = progreso {
    cargar = Command0<void>(_cargar)..execute();
  }

  final ProgresoRepository _repositorio;

  late final Command0<void> cargar;

  Progreso? _progreso;
  String? _mensajeErrorCarga;

  Progreso? get progreso => _progreso;

  String? get mensajeErrorCarga => _mensajeErrorCarga;

  String get textoPeriodo {
    final p = _progreso;
    if (p == null) return '';
    return 'Del ${_fechaCorta(p.desde)} al ${_fechaCorta(p.hasta)}';
  }

  String get textoApego =>
      _progreso?.apegoPct == null ? '—' : '${_progreso!.apegoPct}%';

  String get textoRacha {
    final racha = _progreso?.rachaActual ?? 0;
    return racha == 1 ? '1 día' : '$racha días';
  }

  int get diasRacha => _progreso?.rachaActual ?? 0;

  /// Si la racha actual cae en un día hito (3, 7, 14, 21), para resaltar la
  /// tarjeta de racha en vez de tratarla como una métrica más.
  bool get esRachaHito => esHitoRacha(diasRacha);

  String get textoAgua {
    final agua = _progreso?.aguaPromedio;
    return agua == null ? '—' : '${_formatear(agua)} vasos';
  }

  String get textoDiasRegistrados {
    final p = _progreso;
    return p == null ? '—' : '${p.diasRegistrados} de ${p.diasPeriodo}';
  }

  String? get textoCambioPeso {
    final peso = _progreso?.peso;
    if (peso == null || peso.inicial == null || peso.actual == null) return null;
    final diferencia = peso.diferencia ?? 0;
    final signo = diferencia > 0 ? '+' : '';
    return '${_formatear(peso.inicial!)} kg → ${_formatear(peso.actual!)} kg '
        '($signo${_formatear(diferencia)} kg)';
  }

  List<PuntoGraficaPeso> get puntosPeso {
    final serie = _progreso?.peso.serie ?? [];
    if (serie.isEmpty) return [];
    final primera = parsearFechaIso(serie.first.fecha)!;
    return [
      for (final punto in serie)
        (
          x: diasEntre(primera, parsearFechaIso(punto.fecha)!).toDouble(),
          peso: punto.peso,
          origen: punto.origen,
          fecha: punto.fecha,
        ),
    ];
  }

  String etiquetaEjeX(double x) {
    final serie = _progreso?.peso.serie ?? [];
    if (serie.isEmpty) return '';
    final primera = parsearFechaIso(serie.first.fecha)!;
    return textoFechaCorta(sumarDias(primera, x.round()));
  }

  /// Nombre de la métrica → promedio (null si no hay datos), en orden fijo.
  Map<String, double?> get sintomas {
    final promedios = _progreso?.sintomasPromedio.comoMapa ?? {};
    return {
      for (final metrica in kNombreSintoma.keys)
        kNombreSintoma[metrica]!: promedios[metrica],
    };
  }

  List<FotoProgreso> get fotos => _progreso?.fotos ?? [];

  String urlFoto(String fotoId) => _repositorio.urlFoto(fotoId);

  Map<String, String> cabecerasFoto() => _repositorio.cabecerasFoto();

  String descripcionFoto(FotoProgreso foto) =>
      '${kNombreTiempo[foto.tiempo] ?? foto.tiempo} del ${_fechaCorta(foto.fecha)}';

  Future<Result<void>> _cargar() async {
    final resultado = await _repositorio.obtenerProgreso();
    switch (resultado) {
      case Ok(:final value):
        _progreso = value;
        _mensajeErrorCarga = null;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        _mensajeErrorCarga = mensajeDeError(error);
        notifyListeners();
        return Result.error(error);
    }
  }

  String _fechaCorta(String fecha) {
    final dia = parsearFechaIso(fecha);
    return dia == null ? fecha : textoFechaCorta(dia);
  }

  String _formatear(double valor) =>
      valor == valor.roundToDouble() ? valor.toStringAsFixed(0) : valor.toStringAsFixed(1);
}
