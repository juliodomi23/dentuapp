import 'package:flutter/foundation.dart';

import '../../../config/constantes.dart';
import '../../../data/repositories/perfil_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/mensaje_error.dart';

class SintomasViewModel extends ChangeNotifier {
  SintomasViewModel({required PerfilRepository perfil}) : _perfil = perfil {
    guardar = Command0<void>(_guardar);
  }

  final PerfilRepository _perfil;

  late final Command0<void> guardar;

  final Map<String, int> _valores = {};
  String _notas = '';
  String? _aviso;

  /// Llave del contrato → nombre visible.
  Map<String, String> get metricas => kNombreSintoma;

  int? valorDe(String metrica) => _valores[metrica];

  bool get puedeGuardar => _valores.isNotEmpty;

  String? tomarAviso() {
    final aviso = _aviso;
    _aviso = null;
    return aviso;
  }

  void seleccionar(String metrica, int valor) {
    _valores[metrica] = valor;
    notifyListeners();
  }

  void cambiarNotas(String notas) => _notas = notas;

  Future<Result<void>> _guardar() async {
    final resultado = await _perfil.registrarSintomas(
      valores: Map.of(_valores),
      notas: _notas,
    );
    _aviso = switch (resultado) {
      Ok() => '¡Gracias! Registramos cómo te sientes hoy.',
      Error(:final error) => mensajeDeError(error),
    };
    notifyListeners();
    return resultado;
  }
}
