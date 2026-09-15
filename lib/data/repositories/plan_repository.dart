import '../../utils/result.dart';
import '../models/lista_compra.dart';
import '../models/plan.dart';
import '../services/api_service.dart';

class PlanRepository {
  PlanRepository({required ApiService api}) : _api = api;

  final ApiService _api;

  Plan? _plan;

  /// Plan vigente de hoy. Si no hay red, devuelve el último que se cargó.
  Future<Result<Plan?>> obtenerSemana() async {
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
    final resultado = await _api.intercambiarDias(
      diaOrigen: diaOrigen,
      diaDestino: diaDestino,
    );
    if (resultado case Ok(:final value)) _plan = value;
    return resultado;
  }

  Future<Result<ListaCompra>> obtenerListaCompra() => _api.obtenerListaCompra();
}
