import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/paciente_app.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/diario_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/mensaje_error.dart';

typedef DatosVinculacion = ({String telefono, String codigo});

class VincularViewModel extends ChangeNotifier {
  VincularViewModel({
    required AuthRepository auth,
    required DiarioRepository diario,
  }) : _auth = auth,
       _diario = diario {
    vincular = Command1<PacienteApp, DatosVinculacion>(_vincular);
  }

  final AuthRepository _auth;
  final DiarioRepository _diario;

  late final Command1<PacienteApp, DatosVinculacion> vincular;

  PacienteApp? _pacienteVinculado;

  bool get debePreguntarConsentimiento => _auth.consentimiento == null;

  bool get consentimientoAceptado => _auth.consentimiento == true;

  bool consentimientoAceptadoPara({required bool personal}) =>
      _auth.consentimientoPara(personal: personal) == true;

  bool debePreguntarConsentimientoPara({required bool personal}) =>
      _auth.consentimientoPara(personal: personal) == null;

  bool get sesionExpirada => _auth.sesionExpirada;

  /// Se llena al vincular bien; la pantalla muestra la confirmación con la clínica.
  PacienteApp? get pacienteVinculado => _pacienteVinculado;

  String? get mensajeError {
    final resultado = vincular.result;
    return resultado is Error<PacienteApp>
        ? mensajeDeError(resultado.error)
        : null;
  }

  Future<void> responderConsentimiento(bool acepta) async {
    await _auth.guardarConsentimiento(acepta);
    notifyListeners();
  }

  Future<void> responderConsentimientoPara(
    bool acepta, {
    required bool personal,
  }) async {
    if (personal) {
      await _auth.guardarConsentimientoPersonal(acepta);
    } else {
      await _auth.guardarConsentimiento(acepta);
    }
    notifyListeners();
  }

  String? validarTelefono(String? texto) {
    final digitos = _soloDigitos(texto ?? '');
    return digitos.length == 10 ? null : 'Escribe tu teléfono a 10 dígitos.';
  }

  String? validarCodigo(String? texto) {
    final digitos = _soloDigitos(texto ?? '');
    return digitos.length == 6 ? null : 'El código tiene 6 dígitos.';
  }

  void continuar() => _auth.confirmarVinculacion();

  Future<Result<PacienteApp>> _vincular(DatosVinculacion datos) async {
    final resultado = await _auth.vincular(
      telefono: _soloDigitos(datos.telefono),
      codigo: _soloDigitos(datos.codigo),
    );
    if (resultado case Ok(:final value)) {
      if (_auth.cambioDePaciente) {
        await _diario.descartarPendientes();
      } else {
        unawaited(_diario.reintentarPendientes());
      }
      _pacienteVinculado = value;
      notifyListeners();
    }
    return resultado;
  }

  String _soloDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');
}
