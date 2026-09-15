import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../utils/result.dart';
import '../models/dia.dart';
import '../models/operacion_pendiente.dart';
import '../models/preparacion.dart';
import '../models/registro_comida.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/conectividad_service.dart';
import '../services/local_queue_service.dart';

/// Día, comidas y agua. Offline-first: si un `PUT` falla por red, se guarda en
/// la cola, se devuelve como pendiente y se reintenta al volver la conexión o
/// al reanudar la app. Es el único repositorio que conoce la cola.
class DiarioRepository extends ChangeNotifier {
  DiarioRepository({
    required ApiService api,
    required LocalQueueService cola,
    ConectividadService? conectividad,
  }) : _api = api,
       _cola = cola,
       _conectividad = conectividad;

  final ApiService _api;
  final LocalQueueService _cola;
  final ConectividadService? _conectividad;

  /// Últimos días que respondió el backend, para poder mostrarlos sin internet.
  final Map<String, Dia> _diasEnCache = {};

  bool _reintentando = false;
  StreamSubscription<bool>? _suscripcionConexion;
  AppLifecycleListener? _cicloDeVida;

  int get totalPendientes => _cola.leerTodas().length;

  void iniciarSincronizacion() {
    _suscripcionConexion ??= _conectividad?.cambiosDeConexion
        .where((hayConexion) => hayConexion)
        .listen((_) => reintentarPendientes());
    _cicloDeVida ??= AppLifecycleListener(onResume: reintentarPendientes);
    reintentarPendientes();
  }

  Future<Result<Dia>> obtenerDia(String fecha) async {
    final resultado = await _api.obtenerDia(fecha);
    switch (resultado) {
      case Ok(:final value):
        _diasEnCache[fecha] = value;
        return Result.ok(_conPendientes(value));
      case Error(:final error):
        final enCache = _diasEnCache[fecha];
        if (enCache != null && _esErrorDeRed(error)) {
          return Result.ok(_conPendientes(enCache));
        }
        return Result.error(error);
    }
  }

  /// El día que ya se tiene en memoria (con los pendientes aplicados), sin llamar al backend.
  Dia? diaEnCache(String fecha) {
    final dia = _diasEnCache[fecha];
    return dia == null ? null : _conPendientes(dia);
  }

  Future<Result<RegistroComida>> guardarComida({
    required String fecha,
    required String tiempo,
    required String estado,
    String? queComio,
    String? nota,
    String? fotoPath,
  }) async {
    final anterior = _cola.buscar(OperacionPendiente.claveComida(fecha, tiempo));
    final resultado = await _api.guardarComida(
      fecha: fecha,
      tiempo: tiempo,
      estado: estado,
      queComio: queComio,
      nota: nota,
      fotoPath: fotoPath ?? anterior?.fotoPath,
    );

    switch (resultado) {
      case Ok(:final value):
        if (anterior != null) await _quitarDeCola(anterior);
        _ponerRegistroEnCache(fecha, tiempo, value);
        notifyListeners();
        return resultado;
      case Error(:final error):
        if (!_esErrorDeRed(error)) return resultado;
        final operacion = OperacionPendiente.comida(
          fecha: fecha,
          tiempo: tiempo,
          estado: estado,
          queComio: queComio,
          nota: nota,
          fotoPath: await _fotoParaCola(fotoPath, anterior),
        );
        await _cola.guardar(operacion);
        notifyListeners();
        final enCache = _tiempoEnCache(fecha, tiempo);
        return Result.ok(
          operacion.comoRegistro(
            planeado: enCache?.planeado ?? '',
            registroAnterior: enCache?.registro,
          ),
        );
    }
  }

  Future<Result<void>> borrarComida(String fecha, String tiempo) async {
    final pendiente = _cola.buscar(OperacionPendiente.claveComida(fecha, tiempo));
    if (pendiente != null) await _quitarDeCola(pendiente);

    final hayRegistroEnServidor = _tiempoEnCache(fecha, tiempo)?.registro != null;
    if (pendiente != null && !hayRegistroEnServidor) {
      notifyListeners();
      return const Result.ok(null);
    }

    final resultado = await _api.borrarComida(fecha, tiempo);
    final yaNoExiste =
        resultado is Error<void> &&
        resultado.error is ApiException &&
        (resultado.error as ApiException).esNoEncontrado;
    if (resultado is Ok || yaNoExiste) {
      _ponerRegistroEnCache(fecha, tiempo, null);
      notifyListeners();
      return const Result.ok(null);
    }
    notifyListeners();
    return resultado;
  }

  Future<Result<int>> guardarAgua(String fecha, int vasos) async {
    final anterior = _cola.buscar(OperacionPendiente.claveAgua(fecha));
    final resultado = await _api.guardarAgua(fecha, vasos);

    switch (resultado) {
      case Ok(:final value):
        if (anterior != null) await _quitarDeCola(anterior);
        _ponerAguaEnCache(fecha, value);
        notifyListeners();
        return resultado;
      case Error(:final error):
        if (!_esErrorDeRed(error)) return resultado;
        await _cola.guardar(OperacionPendiente.agua(fecha: fecha, aguaVasos: vasos));
        notifyListeners();
        return Result.ok(vasos);
    }
  }

  Future<Result<({int minutos, String? tipo})>> guardarEjercicio({
    required String fecha,
    required int minutos,
    String? tipo,
  }) async {
    final anterior = _cola.buscar(OperacionPendiente.claveEjercicio(fecha));
    final resultado = await _api.guardarEjercicio(fecha: fecha, minutos: minutos, tipo: tipo);

    switch (resultado) {
      case Ok(:final value):
        if (anterior != null) await _quitarDeCola(anterior);
        _ponerEjercicioEnCache(fecha, value.minutos, value.tipo);
        notifyListeners();
        return resultado;
      case Error(:final error):
        if (!_esErrorDeRed(error)) return resultado;
        await _cola.guardar(
          OperacionPendiente.ejercicio(fecha: fecha, ejercicioMin: minutos, ejercicioTipo: tipo),
        );
        notifyListeners();
        return Result.ok((minutos: minutos, tipo: tipo));
    }
  }

  /// Envía la cola en orden. Se detiene si no hay red; si el servidor rechaza una
  /// operación por otra razón, la deja en la cola con el mensaje de error.
  Future<void> reintentarPendientes() async {
    if (_reintentando) return;
    _reintentando = true;
    var huboCambios = false;

    try {
      for (final operacion in _cola.leerTodas()) {
        final error = await _enviar(operacion);
        if (error == null) {
          await _quitarDeCola(operacion);
          huboCambios = true;
          continue;
        }
        if (_esErrorDeRed(error) || _esNoAutorizado(error)) break;

        if (_cola.buscar(operacion.clave)?.id == operacion.id) {
          await _cola.guardar(operacion.conError(_mensajeDe(error)));
          huboCambios = true;
        }
      }
    } finally {
      _reintentando = false;
      if (huboCambios) notifyListeners();
    }
  }

  Future<void> descartarPendientes() async {
    await _cola.borrarTodas();
    notifyListeners();
  }

  Future<Result<Preparacion>> obtenerPreparacion(String platillo) =>
      _api.obtenerPreparacion(platillo);

  String urlFoto(String fotoId) => _api.urlFoto(fotoId);

  Map<String, String> cabecerasFoto() => _api.cabecerasFoto();

  @override
  void dispose() {
    _suscripcionConexion?.cancel();
    _cicloDeVida?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------

  /// Devuelve null si se envió bien, o el error.
  Future<Exception?> _enviar(OperacionPendiente operacion) async {
    if (operacion.tipo == OperacionPendiente.tipoAgua) {
      final resultado = await _api.guardarAgua(operacion.fecha, operacion.aguaVasos!);
      switch (resultado) {
        case Ok(:final value):
          _ponerAguaEnCache(operacion.fecha, value);
          return null;
        case Error(:final error):
          return error;
      }
    }

    if (operacion.tipo == OperacionPendiente.tipoEjercicio) {
      final resultado = await _api.guardarEjercicio(
        fecha: operacion.fecha,
        minutos: operacion.ejercicioMin!,
        tipo: operacion.ejercicioTipo,
      );
      switch (resultado) {
        case Ok(:final value):
          _ponerEjercicioEnCache(operacion.fecha, value.minutos, value.tipo);
          return null;
        case Error(:final error):
          return error;
      }
    }

    final resultado = await _api.guardarComida(
      fecha: operacion.fecha,
      tiempo: operacion.tiempo!,
      estado: operacion.estado!,
      queComio: operacion.queComio,
      nota: operacion.nota,
      fotoPath: operacion.fotoPath,
    );
    switch (resultado) {
      case Ok(:final value):
        _ponerRegistroEnCache(operacion.fecha, operacion.tiempo!, value);
        return null;
      case Error(:final error):
        return error;
    }
  }

  /// Quita la operación solo si no la reemplazó otra más nueva mientras se enviaba.
  Future<void> _quitarDeCola(OperacionPendiente operacion) async {
    final actual = _cola.buscar(operacion.clave);
    final sigueEnCola = actual?.id == operacion.id;
    if (sigueEnCola) await _cola.borrar(operacion.clave);

    final laFotoLaUsaOtra = !sigueEnCola && actual?.fotoPath == operacion.fotoPath;
    if (!laFotoLaUsaOtra) await _cola.borrarFoto(operacion.fotoPath);
  }

  Future<String?> _fotoParaCola(String? fotoNueva, OperacionPendiente? anterior) async {
    if (fotoNueva == null) return anterior?.fotoPath;
    await _cola.borrarFoto(anterior?.fotoPath);
    try {
      return await _cola.copiarFoto(fotoNueva);
    } on FileSystemException {
      return null;
    }
  }

  Dia _conPendientes(Dia dia) {
    final tiempos = [
      for (final tiempoDia in dia.tiempos) _tiempoConPendiente(dia.fecha, tiempoDia),
    ];
    final agua = _cola.buscar(OperacionPendiente.claveAgua(dia.fecha));
    final ejercicio = _cola.buscar(OperacionPendiente.claveEjercicio(dia.fecha));
    return dia.copyWith(
      tiempos: tiempos,
      faltan: _calcularFaltan(tiempos),
      aguaVasos: agua?.aguaVasos,
      aguaPendiente: agua != null,
      ejercicioMin: ejercicio?.ejercicioMin,
      ejercicioTipo: ejercicio?.ejercicioTipo,
      borrarEjercicioTipo: ejercicio != null && ejercicio.ejercicioTipo == null,
      ejercicioPendiente: ejercicio != null,
    );
  }

  TiempoDia _tiempoConPendiente(String fecha, TiempoDia tiempoDia) {
    final pendiente = _cola.buscar(
      OperacionPendiente.claveComida(fecha, tiempoDia.tiempo),
    );
    if (pendiente == null) return tiempoDia;
    return tiempoDia.conRegistro(
      pendiente.comoRegistro(
        planeado: tiempoDia.planeado,
        registroAnterior: tiempoDia.registro,
      ),
    );
  }

  List<String> _calcularFaltan(List<TiempoDia> tiempos) => [
    for (final t in tiempos)
      if (t.planeado.isNotEmpty && t.registro == null) t.tiempo,
  ];

  TiempoDia? _tiempoEnCache(String fecha, String tiempo) {
    final dia = _diasEnCache[fecha];
    if (dia == null) return null;
    for (final tiempoDia in dia.tiempos) {
      if (tiempoDia.tiempo == tiempo) return tiempoDia;
    }
    return null;
  }

  void _ponerRegistroEnCache(String fecha, String tiempo, RegistroComida? registro) {
    final dia = _diasEnCache[fecha];
    if (dia == null) return;
    final tiempos = [
      for (final t in dia.tiempos) t.tiempo == tiempo ? t.conRegistro(registro) : t,
    ];
    _diasEnCache[fecha] = dia.copyWith(
      tiempos: tiempos,
      faltan: _calcularFaltan(tiempos),
    );
  }

  void _ponerAguaEnCache(String fecha, int vasos) {
    final dia = _diasEnCache[fecha];
    if (dia != null) _diasEnCache[fecha] = dia.copyWith(aguaVasos: vasos);
  }

  void _ponerEjercicioEnCache(String fecha, int minutos, String? tipo) {
    final dia = _diasEnCache[fecha];
    if (dia == null) return;
    _diasEnCache[fecha] = dia.copyWith(
      ejercicioMin: minutos,
      ejercicioTipo: tipo,
      borrarEjercicioTipo: tipo == null,
    );
  }

  bool _esErrorDeRed(Exception error) =>
      error is ApiException && error.esRecuperable;

  bool _esNoAutorizado(Exception error) =>
      error is ApiException && error.esNoAutorizado;

  String _mensajeDe(Exception error) =>
      error is ApiException ? error.mensaje : 'No se pudo enviar.';
}
