import '../../utils/result.dart';
import '../models/lista_compra.dart';
import '../models/plan.dart';
import '../services/api_service.dart';

class PlanRepository {
  PlanRepository({required ApiService api, String? Function()? leerPacienteId})
    : _api = api,
      _leerPacienteId = leerPacienteId;

  final ApiService _api;
  final String? Function()? _leerPacienteId;

  Plan? _plan;
  String? _pacienteDelCache;

  void _verificarDueno() {
    final actual = _leerPacienteId?.call();
    if (actual != _pacienteDelCache) {
      _plan = null;
      _pacienteDelCache = actual;
    }
  }

  /// Plan vigente de hoy. Si no hay red, devuelve el último que se cargó.
  Future<Result<Plan?>> obtenerSemana() async {
    _verificarDueno();
    final resultado = await _api.obtenerPlanSemana();
    switch (resultado) {
      case Ok(:final value):
        _plan = value;
        return resultado;
      case Error():
        return _plan == null ? resultado : Result.ok(_plan);
    }
  }

  Future<Result<Plan>> intercambiarDias({
    required String diaOrigen,
    required String diaDestino,
  }) async {
    _verificarDueno();
    final resultado = await _api.intercambiarDias(
      diaOrigen: diaOrigen,
      diaDestino: diaDestino,
    );
    if (resultado case Ok(:final value)) _plan = value;
    return resultado;
  }

  Future<Result<ListaCompra>> obtenerListaCompra() => _api.obtenerListaCompra();

  Future<Result<Map<String, dynamic>>> extraerDieta(List<String> rutas) =>
      _api.extraerDieta(rutas);

  Future<Result<Plan>> guardarDietaPersonal(
    Map<String, dynamic> borrador,
  ) async {
    _verificarDueno();
    final resultado = await _api.guardarDietaPersonal(borrador);
    if (resultado case Ok(:final value)) _plan = value;
    return resultado;
  }
}
