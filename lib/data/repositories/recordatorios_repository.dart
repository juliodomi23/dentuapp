import '../../config/app_config.dart';
import '../../config/constantes.dart';
import '../../utils/result.dart';
import '../models/ajustes_recordatorios.dart';
import '../services/notifications_service.dart';
import '../services/preferencias_service.dart';

class PermisoDenegadoException implements Exception {
  const PermisoDenegadoException(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'PermisoDenegadoException: $mensaje';
}

/// Horarios de recordatorios de comidas y agua (notificaciones locales).
class RecordatoriosRepository {
  RecordatoriosRepository({
    required NotificationsService notificaciones,
    required PreferenciasService preferencias,
  }) : _notificaciones = notificaciones,
       _preferencias = preferencias;

  static const _clave = 'recordatorios';
  static const _idBaseComidas = 100;
  static const _idBaseAgua = 200;

  final NotificationsService _notificaciones;
  final PreferenciasService _preferencias;

  AjustesRecordatorios leerAjustes() {
    final guardados = _preferencias.leerMapa(_clave);
    return guardados == null
        ? AjustesRecordatorios.porDefecto
        : AjustesRecordatorios.fromMap(guardados);
  }

  /// Guarda los ajustes y vuelve a programar todas las notificaciones.
  Future<Result<void>> guardarAjustes(AjustesRecordatorios ajustes) async {
    if (ajustes.comidasActivas || ajustes.aguaActiva) {
      final permiso = await _notificaciones.pedirPermiso();
      if (permiso case Ok(value: false)) {
        return const Result.error(
          PermisoDenegadoException(
            'Activa las notificaciones de la app en los ajustes del teléfono.',
          ),
        );
      }
    }

    await _preferencias.guardarMapa(_clave, ajustes.toMap());

    final cancelacion = await _notificaciones.cancelarTodas();
    if (cancelacion is Error) return cancelacion;

    if (ajustes.comidasActivas) {
      final resultado = await _programarComidas(ajustes);
      if (resultado is Error) return resultado;
    }
    if (ajustes.aguaActiva) {
      final resultado = await _programarAgua(ajustes);
      if (resultado is Error) return resultado;
    }
    return const Result.ok(null);
  }

  Future<void> desactivarTodos() async {
    await _notificaciones.cancelarTodas();
    await _preferencias.borrar(_clave);
  }

  Future<Result<void>> _programarComidas(AjustesRecordatorios ajustes) async {
    for (var i = 0; i < kTiempos.length; i++) {
      final tiempo = kTiempos[i];
      final hora = ajustes.horarios[tiempo]!;
      final nombre = kNombreTiempo[tiempo]!;
      final resultado = await _notificaciones.programarDiaria(
        id: _idBaseComidas + i,
        hora: hora.hora,
        minuto: hora.minuto,
        titulo: nombre,
        cuerpo: '¿Ya registraste tu ${nombre.toLowerCase()} en ${AppConfig.nombreApp}?',
      );
      if (resultado is Error) return resultado;
    }
    return const Result.ok(null);
  }

  Future<Result<void>> _programarAgua(AjustesRecordatorios ajustes) async {
    final horas = ajustes.horasAgua;
    for (var i = 0; i < horas.length; i++) {
      final resultado = await _notificaciones.programarDiaria(
        id: _idBaseAgua + i,
        hora: horas[i],
        minuto: 0,
        titulo: 'Hora de tomar agua',
        cuerpo: 'Toma un vaso y súmalo en ${AppConfig.nombreApp}.',
      );
      if (resultado is Error) return resultado;
    }
    return const Result.ok(null);
  }
}
