import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../utils/result.dart';
import '../models/paciente_app.dart';
import '../services/api_service.dart';
import '../services/preferencias_service.dart';
import '../services/secure_storage_service.dart';

enum EstadoSesion { cargando, sinSesion, conSesion }

/// Fuente de verdad de la sesión del paciente: token, URL del backend con la
/// que se vinculó, datos del paciente y consentimiento.
class AuthRepository extends ChangeNotifier {
  AuthRepository({
    required ApiService api,
    required SecureStorageService almacenamiento,
    required PreferenciasService preferencias,
  }) : _api = api,
       _almacenamiento = almacenamiento,
       _preferencias = preferencias {
    _api.leerToken = () => _token;
    _api.leerBaseUrl = () => _baseUrl;
    _api.alNoAutorizado = _expirarSesion;
  }

  static const _claveToken = 'token_paciente';
  static const _claveBaseUrl = 'base_url';
  static const _clavePaciente = 'paciente';
  static const _claveUltimoPaciente = 'ultimo_paciente_id';
  static const _claveConsentimiento = 'consentimiento_datos_salud_v1';

  final ApiService _api;
  final SecureStorageService _almacenamiento;
  final PreferenciasService _preferencias;

  EstadoSesion _estado = EstadoSesion.cargando;
  String? _token;
  String? _baseUrl;
  PacienteApp? _paciente;
  bool _sesionExpirada = false;
  bool _cambioDePaciente = false;

  EstadoSesion get estado => _estado;

  PacienteApp? get paciente => _paciente;

  /// true si la sesión se cerró sola por un 401 (token vencido o app desvinculada).
  bool get sesionExpirada => _sesionExpirada;

  /// true si el último `vincular` fue con un paciente distinto al anterior en este teléfono.
  bool get cambioDePaciente => _cambioDePaciente;

  /// null = todavía no se le preguntó.
  bool? get consentimiento => _preferencias.leerBool(_claveConsentimiento);

  Future<void> guardarConsentimiento(bool acepta) async {
    await _preferencias.guardarBool(_claveConsentimiento, acepta);
    notifyListeners();
  }

  /// Lee la sesión guardada. No llama al backend, para no frenar el arranque.
  Future<void> cargarSesion() async {
    final token = await _leer(_claveToken);
    if (token == null) {
      _cambiarEstado(EstadoSesion.sinSesion);
      return;
    }
    _token = token;
    _baseUrl = await _leer(_claveBaseUrl);
    _paciente = _pacienteDesdeJson(await _leer(_clavePaciente));
    _cambiarEstado(EstadoSesion.conSesion);
  }

  Future<Result<PacienteApp>> refrescarPerfil() async {
    final resultado = await _api.obtenerPerfil();
    if (resultado case Ok(:final value)) {
      _paciente = value;
      await _almacenamiento.escribir(_clavePaciente, jsonEncode(value.toJson()));
      notifyListeners();
    }
    return resultado;
  }

  /// Guarda la sesión en cuanto el backend responde (el código solo sirve una vez),
  /// pero no la activa hasta `confirmarVinculacion`, para mostrar antes la clínica.
  Future<Result<PacienteApp>> vincular({
    required String telefono,
    required String codigo,
  }) async {
    final resultado = await _api.vincular(telefono: telefono, codigo: codigo);
    switch (resultado) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        final anterior = await _leer(_claveUltimoPaciente);
        _cambioDePaciente = anterior != null && anterior != value.paciente.id;

        final guardado = await _guardarSesion(value, _api.urlVinculacion);
        if (guardado case Error(:final error)) return Result.error(error);

        _token = value.token;
        _baseUrl = _api.urlVinculacion;
        _paciente = value.paciente;
        _sesionExpirada = false;
        return Result.ok(value.paciente);
    }
  }

  void confirmarVinculacion() {
    if (_token == null) return;
    _cambiarEstado(EstadoSesion.conSesion);
  }

  Future<void> cerrarSesion() => _limpiarSesion(olvidarPaciente: true);

  Future<Result<void>> borrarCuenta() async {
    final resultado = await _api.borrarCuenta();
    if (resultado is Ok) {
      await _preferencias.borrar(_claveConsentimiento);
      await _limpiarSesion(olvidarPaciente: true);
    }
    return resultado;
  }

  Future<Result<void>> _guardarSesion(ResultadoVinculacion datos, String baseUrl) async {
    final escrituras = [
      await _almacenamiento.escribir(_claveToken, datos.token),
      await _almacenamiento.escribir(_claveBaseUrl, baseUrl),
      await _almacenamiento.escribir(
        _clavePaciente,
        jsonEncode(datos.paciente.toJson()),
      ),
      await _almacenamiento.escribir(_claveUltimoPaciente, datos.paciente.id),
    ];
    return escrituras.firstWhere((r) => r is Error, orElse: () => const Result.ok(null));
  }

  void _expirarSesion() {
    if (_estado != EstadoSesion.conSesion) return;
    _sesionExpirada = true;
    _limpiarSesion(olvidarPaciente: false);
  }

  /// `olvidarPaciente: false` conserva el id del último paciente para saber,
  /// al volver a vincular, si los registros pendientes son suyos.
  Future<void> _limpiarSesion({required bool olvidarPaciente}) async {
    _token = null;
    _baseUrl = null;
    _paciente = null;
    _cambiarEstado(EstadoSesion.sinSesion);

    await _almacenamiento.borrar(_claveToken);
    await _almacenamiento.borrar(_claveBaseUrl);
    await _almacenamiento.borrar(_clavePaciente);
    if (olvidarPaciente) await _almacenamiento.borrar(_claveUltimoPaciente);
  }

  Future<String?> _leer(String clave) async {
    final resultado = await _almacenamiento.leer(clave);
    return resultado is Ok<String?> ? resultado.value : null;
  }

  PacienteApp? _pacienteDesdeJson(String? texto) {
    if (texto == null) return null;
    try {
      return PacienteApp.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  void _cambiarEstado(EstadoSesion nuevo) {
    _estado = nuevo;
    notifyListeners();
  }
}
