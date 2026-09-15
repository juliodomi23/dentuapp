import '../../utils/fechas.dart';
import '../../utils/result.dart';
import '../models/perfil_paciente.dart';
import '../models/registro_sintomas.dart';
import '../services/api_service.dart';

class PerfilRepository {
  PerfilRepository({required ApiService api, DateTime Function()? reloj})
    : _api = api,
      _reloj = reloj ?? DateTime.now;

  final ApiService _api;
  final DateTime Function() _reloj;

  Future<Result<PerfilPaciente>> obtenerPerfil() => _api.obtenerPerfilPaciente();

  Future<Result<void>> registrarPeso(double peso) =>
      _api.registrarPeso(peso, fecha: fechaIso(_reloj()));

  Future<Result<void>> registrarSintomas({
    required Map<String, int> valores,
    String? notas,
  }) {
    return _api.registrarSintomas(
      RegistroSintomas(valores: valores, notas: notas, fecha: fechaIso(_reloj())),
    );
  }
}
