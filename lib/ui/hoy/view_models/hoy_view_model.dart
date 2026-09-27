import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;

import '../../../config/constantes.dart';
import '../../../data/models/dia.dart';
import '../../../data/models/plan.dart';
import '../../../data/models/registro_comida.dart';
import '../../../data/repositories/diario_repository.dart';
import '../../../data/repositories/plan_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/fechas.dart';
import '../../../utils/rachas.dart';
import '../../../utils/result.dart';
import '../../core/mensaje_error.dart';
import '../reto21_mensajes.dart';

/// Un momento de celebración por disparar: ícono + mensaje corto.
typedef Celebracion = ({IconData icono, String mensaje});

typedef RegistroComidaInput = ({
  String tiempo,
  String estado,
  String? queComio,
  String? fotoPath,
});

class HoyViewModel extends ChangeNotifier {
  HoyViewModel({
    required DiarioRepository diario,
    required PlanRepository plan,
    DateTime Function()? reloj,
    this.esperaAntesDeGuardar = const Duration(milliseconds: 700),
  }) : _diario = diario,
       _plan = plan,
       _reloj = reloj ?? DateTime.now {
    _fecha = soloFecha(_reloj());
    cargarDia = Command0<void>(_cargarDia);
    registrarComida = Command1<RegistroComida, RegistroComidaInput>(
      _registrarComida,
    );
    deshacerRegistro = Command1<void, String>(_deshacerRegistro);
    guardarAgua = Command0<void>(_guardarAgua);
    guardarEjercicio = Command0<void>(_guardarEjercicio);
    _diario.addListener(_alCambiarDiario);
    cargarDia.execute();
  }

  final DiarioRepository _diario;
  final PlanRepository _plan;
  final DateTime Function() _reloj;

  /// Espera tras el último toque de +/- antes de enviar, para no mandar una petición por toque.
  final Duration esperaAntesDeGuardar;

  late final Command0<void> cargarDia;
  late final Command1<RegistroComida, RegistroComidaInput> registrarComida;
  late final Command1<void, String> deshacerRegistro;
  late final Command0<void> guardarAgua;
  late final Command0<void> guardarEjercicio;

  late DateTime _fecha;
  Dia? _dia;
  Plan? _planActual;
  String? _mensajeErrorCarga;
  String? _aviso;
  Celebracion? _celebracionPendiente;
  final Set<String> _fechasCelebradas = {};
  String? _tiempoEnProceso;
  ({String fecha, int vasos})? _aguaPorGuardar;
  Timer? _temporizadorAgua;
  ({String fecha, int minutos, String? tipo, int? caloriasReloj})?
  _ejercicioPorGuardar;
  Timer? _temporizadorEjercicio;

  Dia? get dia => _dia;

  DateTime get fecha => _fecha;

  String get tituloFecha => textoFechaConDia(_fecha);

  String? get subtituloFecha =>
      switch (diasEntre(soloFecha(_reloj()), _fecha)) {
        0 => 'Hoy',
        -1 => 'Ayer',
        1 => 'Mañana',
        _ => null,
      };

  bool get esHoy => diasEntre(soloFecha(_reloj()), _fecha) == 0;

  bool get puedeRegistrar => _dia?.puedeRegistrar ?? false;

  String? get mensajeErrorCarga => _mensajeErrorCarga;

  /// Equivalentes del plan (solo si el plan está en modo "equivalentes").
  Map<String, double> get equivalentes => _planActual?.equivalentes ?? {};

  /// "Objetivo del día: 2000 kcal · 100g proteína · ...". Null si el plan no
  /// trae ninguna meta o todavía no se ha cargado.
  String? get textoObjetivoDia {
    final plan = _planActual;
    if (plan == null) return null;
    final partes = [
      if (plan.caloriasObjetivo != null)
        '${_numero(plan.caloriasObjetivo!)} kcal',
      if (plan.proteinasG != null) '${_numero(plan.proteinasG!)}g proteína',
      if (plan.carbohidratosG != null)
        '${_numero(plan.carbohidratosG!)}g carbos',
      if (plan.grasasG != null) '${_numero(plan.grasasG!)}g grasas',
    ];
    return partes.isEmpty ? null : 'Objetivo del día: ${partes.join(' · ')}';
  }

  /// Tiempo de comida que se está guardando, para deshabilitar su tarjeta.
  String? get tiempoEnProceso => _tiempoEnProceso;

  /// Cuántos tiempos de comida ya tienen registro, del total del día.
  (int hechas, int total) get progresoComidas {
    final dia = _dia;
    if (dia == null || dia.tiempos.isEmpty) return (0, 0);
    return (
      dia.tiempos.where((t) => t.registro != null).length,
      dia.tiempos.length,
    );
  }

  /// Vasos de agua tomados, sobre la meta de referencia.
  (int vasos, int meta) get progresoAgua =>
      (_dia?.aguaVasos ?? 0, LimitesRegistro.aguaMetaVasos);

  /// Día actual del Reto 21, sobre el total; null si el paciente no lo tiene activo.
  (int dia, int total)? get progresoReto {
    final diaReto = _dia?.reto21Dia;
    if (diaReto == null) return null;
    return (diaReto, LimitesRegistro.reto21TotalDias);
  }

  /// Mensaje de una sola vez para la UI (snackbar). Se borra al leerlo.
  String? tomarAviso() {
    final aviso = _aviso;
    _aviso = null;
    return aviso;
  }

  /// Celebración de una sola vez para la UI (animación breve). Se borra al
  /// leerla. Solo se llena en hitos reales: día completo o hito de Reto 21;
  /// nunca en un registro normal (ver [_evaluarCelebracion]).
  Celebracion? tomarCelebracion() {
    final celebracion = _celebracionPendiente;
    _celebracionPendiente = null;
    return celebracion;
  }

  String? textoPlanVacio() {
    final dia = _dia;
    if (dia == null || dia.tienePlan) return null;
    return 'Tu nutrióloga está preparando tu plan. En cuanto lo arme, lo verás aquí.';
  }

  String? textoSoloLectura() {
    final dia = _dia;
    if (dia == null || dia.puedeRegistrar) return null;
    return diasEntre(soloFecha(_reloj()), _fecha) > 0
        ? 'Todavía no puedes registrar este día. Puedes ver tu menú.'
        : 'Solo puedes registrar hasta 7 días atrás.';
  }

  String? urlFotoDe(RegistroComida registro) {
    if (registro.fotoLocal != null) return 'file://${registro.fotoLocal}';
    if (registro.fotoId != null) return _diario.urlFoto(registro.fotoId!);
    return null;
  }

  Map<String, String> cabecerasFoto() => _diario.cabecerasFoto();

  void irDiaAnterior() => _irA(sumarDias(_fecha, -1));

  void irDiaSiguiente() => _irA(sumarDias(_fecha, 1));

  void irAHoy() => _irA(soloFecha(_reloj()));

  void sumarAgua() => _cambiarAgua(1);

  void restarAgua() => _cambiarAgua(-1);

  void sumarMinutosEjercicio() =>
      _cambiarMinutosEjercicio(LimitesRegistro.ejercicioPaso);

  void restarMinutosEjercicio() =>
      _cambiarMinutosEjercicio(-LimitesRegistro.ejercicioPaso);

  void cambiarTipoEjercicio(String? tipo) {
    final dia = _dia;
    if (dia == null || !dia.puedeRegistrar) return;
    final texto = tipo?.trim();
    _dia = dia.copyWith(
      ejercicioTipo: texto,
      borrarEjercicioTipo: texto == null || texto.isEmpty,
    );
    _programarEjercicio(
      dia.fecha,
      _dia!.ejercicioMin,
      _dia!.ejercicioTipo,
      _dia!.caloriasReloj,
    );
  }

  void cambiarCaloriasReloj(int? calorias) {
    final dia = _dia;
    if (dia == null || !dia.puedeRegistrar) return;
    if (calorias != null && (calorias < 0 || calorias > 5000)) return;
    _dia = dia.copyWith(
      caloriasReloj: calorias,
      borrarCaloriasReloj: calorias == null,
    );
    _programarEjercicio(
      dia.fecha,
      _dia!.ejercicioMin,
      _dia!.ejercicioTipo,
      calorias,
    );
  }

  @override
  void dispose() {
    _diario.removeListener(_alCambiarDiario);
    _temporizadorAgua?.cancel();
    _temporizadorEjercicio?.cancel();
    final aguaSinEnviar = _aguaPorGuardar;
    if (aguaSinEnviar != null) {
      unawaited(_diario.guardarAgua(aguaSinEnviar.fecha, aguaSinEnviar.vasos));
    }
    final ejercicioSinEnviar = _ejercicioPorGuardar;
    if (ejercicioSinEnviar != null) {
      unawaited(
        _diario.guardarEjercicio(
          fecha: ejercicioSinEnviar.fecha,
          minutos: ejercicioSinEnviar.minutos,
          tipo: ejercicioSinEnviar.tipo,
          caloriasReloj: ejercicioSinEnviar.caloriasReloj,
        ),
      );
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------

  void _irA(DateTime nuevaFecha) {
    _enviarPendientesYa();
    _fecha = nuevaFecha;
    _dia = _diario.diaEnCache(fechaIso(_fecha));
    _mensajeErrorCarga = null;
    notifyListeners();
    cargarDia.execute();
  }

  Future<Result<void>> _cargarDia() async {
    while (true) {
      final fecha = fechaIso(_fecha);
      final resultado = await _diario.obtenerDia(fecha);
      if (fecha != fechaIso(_fecha)) continue;

      switch (resultado) {
        case Ok(:final value):
          _dia = value;
          _mensajeErrorCarga = null;
          await _cargarPlanSiHaceFalta();
          _evaluarCelebracion();
          notifyListeners();
          return const Result.ok(null);
        case Error(:final error):
          if (_dia?.fecha != fecha) _dia = null;
          _mensajeErrorCarga = mensajeDeError(error);
          if (_dia != null) _aviso = _mensajeErrorCarga;
          notifyListeners();
          return Result.error(error);
      }
    }
  }

  Future<void> _cargarPlanSiHaceFalta() async {
    if (_planActual != null) return;
    final resultado = await _plan.obtenerSemana();
    if (resultado case Ok(:final value?)) _planActual = value;
  }

  Future<Result<RegistroComida>> _registrarComida(
    RegistroComidaInput datos,
  ) async {
    _tiempoEnProceso = datos.tiempo;
    notifyListeners();

    final fecha = fechaIso(_fecha);
    final resultado = await _diario.guardarComida(
      fecha: fecha,
      tiempo: datos.tiempo,
      estado: datos.estado,
      queComio: datos.queComio,
      fotoPath: datos.fotoPath,
    );

    _tiempoEnProceso = null;
    switch (resultado) {
      case Ok(:final value):
        _refrescarDesdeCache();
        _aviso = value.pendiente
            ? 'Sin conexión: lo guardamos y se enviará cuando vuelva el internet.'
            : '${kNombreTiempo[datos.tiempo]} registrada.';
        _evaluarCelebracion();
      case Error(:final error):
        _aviso = mensajeDeError(error);
    }
    notifyListeners();
    return resultado;
  }

  /// Detecta hitos reales (día completo o Reto 21 en un día hito) y deja una
  /// celebración lista para mostrarse una sola vez por fecha. No se dispara
  /// con cada registro normal: eso lo cubre la microinteracción del botón.
  void _evaluarCelebracion() {
    final dia = _dia;
    if (dia == null || _fechasCelebradas.contains(dia.fecha)) return;

    final diaReto = dia.reto21Dia;
    final esHitoReto = diaReto != null && esHitoRacha(diaReto);
    final diaCompleto =
        dia.tienePlan && dia.tiempos.every((t) => t.registro != null);

    if (esHitoReto) {
      _fechasCelebradas.add(dia.fecha);
      _celebracionPendiente = (
        icono: Icons.local_fire_department_rounded,
        mensaje: mensajeReto21(diaReto),
      );
    } else if (diaCompleto) {
      _fechasCelebradas.add(dia.fecha);
      _celebracionPendiente = (
        icono: Icons.emoji_events_rounded,
        mensaje: '¡Completaste todo tu día!',
      );
    }
  }

  Future<Result<void>> _deshacerRegistro(String tiempo) async {
    _tiempoEnProceso = tiempo;
    notifyListeners();

    final resultado = await _diario.borrarComida(fechaIso(_fecha), tiempo);

    _tiempoEnProceso = null;
    if (resultado case Error(:final error)) {
      _aviso = mensajeDeError(error);
    } else {
      _refrescarDesdeCache();
    }
    notifyListeners();
    return resultado;
  }

  void _cambiarAgua(int cambio) {
    final dia = _dia;
    if (dia == null || !dia.puedeRegistrar) return;
    final vasos = (dia.aguaVasos + cambio).clamp(0, LimitesRegistro.aguaMax);
    if (vasos == dia.aguaVasos) return;

    _dia = dia.copyWith(aguaVasos: vasos);
    _aguaPorGuardar = (fecha: dia.fecha, vasos: vasos);
    notifyListeners();

    _temporizadorAgua?.cancel();
    _temporizadorAgua = Timer(esperaAntesDeGuardar, guardarAgua.execute);
  }

  void _cambiarMinutosEjercicio(int cambio) {
    final dia = _dia;
    if (dia == null || !dia.puedeRegistrar) return;
    final minutos = (dia.ejercicioMin + cambio).clamp(
      0,
      LimitesRegistro.ejercicioMinMax,
    );
    if (minutos == dia.ejercicioMin) return;

    _dia = dia.copyWith(ejercicioMin: minutos);
    _programarEjercicio(
      dia.fecha,
      minutos,
      _dia!.ejercicioTipo,
      _dia!.caloriasReloj,
    );
  }

  void _programarEjercicio(
    String fecha,
    int minutos,
    String? tipo,
    int? caloriasReloj,
  ) {
    _ejercicioPorGuardar = (
      fecha: fecha,
      minutos: minutos,
      tipo: tipo,
      caloriasReloj: caloriasReloj,
    );
    notifyListeners();

    _temporizadorEjercicio?.cancel();
    _temporizadorEjercicio = Timer(
      esperaAntesDeGuardar,
      guardarEjercicio.execute,
    );
  }

  void _enviarPendientesYa() {
    if (_temporizadorAgua?.isActive ?? false) {
      _temporizadorAgua!.cancel();
      guardarAgua.execute();
    }
    if (_temporizadorEjercicio?.isActive ?? false) {
      _temporizadorEjercicio!.cancel();
      guardarEjercicio.execute();
    }
  }

  /// Si el paciente sigue tocando mientras se envía, el ciclo manda el último valor.
  Future<Result<void>> _guardarAgua() async {
    while (_aguaPorGuardar != null) {
      final porGuardar = _aguaPorGuardar!;
      _aguaPorGuardar = null;
      final resultado = await _diario.guardarAgua(
        porGuardar.fecha,
        porGuardar.vasos,
      );
      if (resultado case Error(:final error)) {
        _aviso = mensajeDeError(error);
        _refrescarDesdeCache();
        notifyListeners();
        return Result.error(error);
      }
    }
    _refrescarDesdeCache();
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _guardarEjercicio() async {
    while (_ejercicioPorGuardar != null) {
      final porGuardar = _ejercicioPorGuardar!;
      _ejercicioPorGuardar = null;
      final resultado = await _diario.guardarEjercicio(
        fecha: porGuardar.fecha,
        minutos: porGuardar.minutos,
        tipo: porGuardar.tipo,
        caloriasReloj: porGuardar.caloriasReloj,
      );
      if (resultado case Error(:final error)) {
        _aviso = mensajeDeError(error);
        _refrescarDesdeCache();
        notifyListeners();
        return Result.error(error);
      }
    }
    _refrescarDesdeCache();
    notifyListeners();
    return const Result.ok(null);
  }

  void _alCambiarDiario() {
    _refrescarDesdeCache();
    notifyListeners();
  }

  /// Toma del repositorio el día actual (con pendientes) sin llamar al backend.
  /// Respeta lo que el paciente acaba de tocar y aún no se envía (agua, ejercicio).
  void _refrescarDesdeCache() {
    final fecha = fechaIso(_fecha);
    var enCache = _diario.diaEnCache(fecha);
    if (enCache == null) return;

    final aguaLocal = _aguaPorGuardar;
    if (aguaLocal != null && aguaLocal.fecha == fecha) {
      enCache = enCache.copyWith(aguaVasos: aguaLocal.vasos);
    }
    final ejercicioLocal = _ejercicioPorGuardar;
    if (ejercicioLocal != null && ejercicioLocal.fecha == fecha) {
      enCache = enCache.copyWith(
        ejercicioMin: ejercicioLocal.minutos,
        ejercicioTipo: ejercicioLocal.tipo,
        caloriasReloj: ejercicioLocal.caloriasReloj,
        borrarEjercicioTipo: ejercicioLocal.tipo == null,
        borrarCaloriasReloj: ejercicioLocal.caloriasReloj == null,
      );
    }
    _dia = enCache;
  }

  static String _numero(double valor) => valor == valor.roundToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toStringAsFixed(1);
}
