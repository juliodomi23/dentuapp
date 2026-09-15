import 'package:flutter/material.dart';

import '../../../config/constantes.dart';
import '../../../data/models/ajustes_recordatorios.dart';
import '../../../data/repositories/recordatorios_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/mensaje_error.dart';

class RecordatoriosViewModel extends ChangeNotifier {
  RecordatoriosViewModel({required RecordatoriosRepository recordatorios})
    : _repositorio = recordatorios {
    _ajustes = _repositorio.leerAjustes();
    guardar = Command0<void>(_guardar);
  }

  final RecordatoriosRepository _repositorio;

  late final Command0<void> guardar;

  late AjustesRecordatorios _ajustes;
  String? _aviso;

  AjustesRecordatorios get ajustes => _ajustes;

  List<String> get tiempos => kTiempos;

  String nombreTiempo(String tiempo) => kNombreTiempo[tiempo] ?? tiempo;

  IconData iconoTiempo(String tiempo) => kIconoTiempo[tiempo] ?? Icons.restaurant_rounded;

  String get textoHorasAgua =>
      'De ${AjustesRecordatorios.aguaDesdeHora}:00 a ${AjustesRecordatorios.aguaHastaHora}:00';

  String? tomarAviso() {
    final aviso = _aviso;
    _aviso = null;
    return aviso;
  }

  void cambiarComidasActivas(bool activas) =>
      _aplicar(_ajustes.copyWith(comidasActivas: activas));

  void cambiarHorario(String tiempo, HoraDelDia hora) =>
      _aplicar(_ajustes.copyWith(horarios: {..._ajustes.horarios, tiempo: hora}));

  void cambiarAguaActiva(bool activa) =>
      _aplicar(_ajustes.copyWith(aguaActiva: activa));

  void cambiarAguaCadaHoras(int horas) =>
      _aplicar(_ajustes.copyWith(aguaCadaHoras: horas));

  void _aplicar(AjustesRecordatorios nuevos) {
    _ajustes = nuevos;
    notifyListeners();
    guardar.execute();
  }

  Future<Result<void>> _guardar() async {
    final porGuardar = _ajustes;
    final resultado = await _repositorio.guardarAjustes(porGuardar);
    if (resultado case Error(:final error)) {
      _ajustes = _repositorio.leerAjustes();
      _aviso = mensajeDeError(error);
    } else if (!identical(porGuardar, _ajustes)) {
      // El paciente cambió algo mientras se guardaba: se guarda lo más nuevo.
      return _guardar();
    }
    notifyListeners();
    return resultado;
  }
}
