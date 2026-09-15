import 'package:flutter/foundation.dart';

import '../../../config/constantes.dart';
import '../../../data/models/paciente_app.dart';
import '../../../data/models/perfil_paciente.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/diario_repository.dart';
import '../../../data/repositories/perfil_repository.dart';
import '../../../data/repositories/progreso_repository.dart';
import '../../../data/repositories/recordatorios_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../core/mensaje_error.dart';

typedef FilaDato = ({String etiqueta, String valor});

class PerfilViewModel extends ChangeNotifier {
  PerfilViewModel({
    required AuthRepository auth,
    required PerfilRepository perfil,
    required DiarioRepository diario,
    required RecordatoriosRepository recordatorios,
    required ProgresoRepository progreso,
  }) : _auth = auth,
       _perfil = perfil,
       _diario = diario,
       _recordatorios = recordatorios,
       _progreso = progreso {
    cargarDatos = Command0<void>(_cargarDatos)..execute();
    registrarPeso = Command1<void, double>(_registrarPeso);
    cerrarSesion = Command0<void>(_cerrarSesion);
    borrarCuenta = Command0<void>(_borrarCuenta);
    _auth.addListener(notifyListeners);
  }

  final AuthRepository _auth;
  final PerfilRepository _perfil;
  final DiarioRepository _diario;
  final RecordatoriosRepository _recordatorios;
  final ProgresoRepository _progreso;

  late final Command0<void> cargarDatos;
  late final Command1<void, double> registrarPeso;
  late final Command0<void> cerrarSesion;
  late final Command0<void> borrarCuenta;

  PerfilPaciente? _datos;
  String? _mensajeErrorDatos;
  String? _aviso;

  PacienteApp? get paciente => _auth.paciente;

  int get pendientesSinEnviar => _diario.totalPendientes;

  bool get ocupado => cerrarSesion.running || borrarCuenta.running;

  bool get hayDatos => _datos != null;

  String? get mensajeErrorDatos => _mensajeErrorDatos;

  String? tomarAviso() {
    final aviso = _aviso;
    _aviso = null;
    return aviso;
  }

  List<FilaDato> get datosPersonales {
    final d = _datos;
    if (d == null) return [];
    return [
      (etiqueta: 'Nombre', valor: '${d.nombre} ${d.apellido}'.trim()),
      (etiqueta: 'Teléfono', valor: d.telefono),
      (etiqueta: 'Correo', valor: d.email ?? '—'),
      (etiqueta: 'Fecha de nacimiento', valor: _fecha(d.fechaNacimiento)),
      (etiqueta: 'Sexo', valor: _capitalizar(d.sexo)),
      (etiqueta: 'Peso', valor: _unidad(d.peso, 'kg')),
      (etiqueta: 'Estatura', valor: _estatura(d.estatura)),
    ];
  }

  List<FilaDato> get datosSalud {
    final d = _datos;
    if (d == null) return [];
    return [
      (etiqueta: 'Objetivo', valor: d.objetivo ?? '—'),
      (etiqueta: 'Actividad física', valor: d.actividadFisica ?? '—'),
      (etiqueta: 'Enfermedades crónicas', valor: _lista(d.enfermedadesCronicas)),
      (etiqueta: 'Alergias alimentarias', valor: _lista(d.alergiasAlimentarias)),
    ];
  }

  String? get tituloMedicion {
    final medicion = _datos?.ultimaMedicion;
    return medicion == null ? null : 'Última medición (${_fecha(medicion.fecha)})';
  }

  List<FilaDato> get datosMedicion {
    final m = _datos?.ultimaMedicion;
    if (m == null) return [];
    return [
      (etiqueta: 'Peso', valor: _unidad(m.peso, 'kg')),
      (etiqueta: 'Cintura', valor: _unidad(m.cintura, 'cm')),
      (etiqueta: 'Cadera', valor: _unidad(m.cadera, 'cm')),
      (etiqueta: 'Grasa corporal', valor: _unidad(m.grasaCorporal, '%')),
      (etiqueta: 'Masa muscular', valor: _unidad(m.masaMuscular, 'kg')),
    ];
  }

  /// Acepta "82.5" o "82,5". Devuelve null si no es válido.
  double? leerPeso(String texto) {
    final peso = double.tryParse(texto.trim().replaceAll(',', '.'));
    if (peso == null) return null;
    if (peso < LimitesRegistro.pesoMin || peso > LimitesRegistro.pesoMax) return null;
    return peso;
  }

  String? validarPeso(String? texto) => leerPeso(texto ?? '') == null
      ? 'Escribe tu peso en kg (entre 20 y 400).'
      : null;

  @override
  void dispose() {
    _auth.removeListener(notifyListeners);
    super.dispose();
  }

  Future<Result<void>> _cargarDatos() async {
    final resultado = await _perfil.obtenerPerfil();
    switch (resultado) {
      case Ok(:final value):
        _datos = value;
        _mensajeErrorDatos = null;
      case Error(:final error):
        _mensajeErrorDatos = mensajeDeError(error);
    }
    notifyListeners();
    return resultado;
  }

  Future<Result<void>> _registrarPeso(double peso) async {
    final resultado = await _perfil.registrarPeso(peso);
    _aviso = switch (resultado) {
      Ok() => 'Peso registrado.',
      Error(:final error) => mensajeDeError(error),
    };
    notifyListeners();
    return resultado;
  }

  Future<Result<void>> _cerrarSesion() async {
    await _limpiarDatosLocales();
    await _auth.cerrarSesion();
    return const Result.ok(null);
  }

  Future<Result<void>> _borrarCuenta() async {
    final resultado = await _auth.borrarCuenta();
    switch (resultado) {
      case Ok():
        await _limpiarDatosLocales();
      case Error(:final error):
        _aviso = mensajeDeError(error);
        notifyListeners();
    }
    return resultado;
  }

  Future<void> _limpiarDatosLocales() async {
    await _diario.descartarPendientes();
    await _recordatorios.desactivarTodos();
    await _progreso.limpiarCacheFotos();
  }

  String _fecha(String? texto) {
    if (texto == null) return '—';
    final fecha = parsearFechaIso(texto);
    return fecha == null ? texto : textoFechaLarga(fecha);
  }

  String _unidad(double? valor, String unidad) {
    if (valor == null) return '—';
    final numero = valor == valor.roundToDouble()
        ? valor.toStringAsFixed(0)
        : valor.toStringAsFixed(1);
    return unidad == '%' ? '$numero%' : '$numero $unidad';
  }

  /// El contrato no dice la unidad: si es menor a 3 se asume metros, si no, centímetros.
  String _estatura(double? estatura) {
    if (estatura == null) return '—';
    return estatura < 3 ? '${estatura.toStringAsFixed(2)} m' : _unidad(estatura, 'cm');
  }

  String _lista(List<String> valores) =>
      valores.isEmpty ? 'Ninguna registrada' : valores.join(', ');

  String _capitalizar(String? texto) {
    if (texto == null || texto.isEmpty) return '—';
    return texto[0].toUpperCase() + texto.substring(1);
  }
}
