import 'package:flutter/foundation.dart';

import '../../../config/constantes.dart';
import '../../../data/models/plan.dart';
import '../../../data/repositories/plan_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../core/mensaje_error.dart';

typedef MovimientoMenu = ({String diaOrigen, String diaDestino});

class SemanaViewModel extends ChangeNotifier {
  SemanaViewModel({required PlanRepository plan, DateTime Function()? reloj})
    : _planRepository = plan,
      _reloj = reloj ?? DateTime.now {
    cargar = Command0<void>(_cargar)..execute();
    moverMenu = Command1<Plan, MovimientoMenu>(_moverMenu);
  }

  final PlanRepository _planRepository;
  final DateTime Function() _reloj;

  late final Command0<void> cargar;
  late final Command1<Plan, MovimientoMenu> moverMenu;

  Plan? _plan;
  bool _cargadoAlgunaVez = false;
  String? _mensajeErrorCarga;
  String? _aviso;
  MovimientoMenu? _ultimoIntercambio;

  Plan? get plan => _plan;

  bool get sinPlan => _cargadoAlgunaVez && _plan == null && _mensajeErrorCarga == null;

  String? get mensajeErrorCarga => _mensajeErrorCarga;

  String get diaDeHoy => diaSemanaDe(_reloj());

  List<String> get dias => kDiasSemana;

  List<String> otrosDias(String dia) =>
      kDiasSemana.where((otro) => otro != dia).toList();

  String? tomarAviso() {
    final aviso = _aviso;
    _aviso = null;
    return aviso;
  }

  /// Qué dos días se acaban de intercambiar, para que la pantalla los
  /// resalte un instante en vez de que el cambio se vea de golpe. Se borra
  /// al leerlo, igual que [tomarAviso].
  MovimientoMenu? tomarUltimoIntercambio() {
    final intercambio = _ultimoIntercambio;
    _ultimoIntercambio = null;
    return intercambio;
  }

  Future<Result<void>> _cargar() async {
    final resultado = await _planRepository.obtenerSemana();
    _cargadoAlgunaVez = true;
    switch (resultado) {
      case Ok(:final value):
        _plan = value;
        _mensajeErrorCarga = null;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        _mensajeErrorCarga = mensajeDeError(error);
        notifyListeners();
        return Result.error(error);
    }
  }

  Future<Result<Plan>> _moverMenu(MovimientoMenu movimiento) async {
    final resultado = await _planRepository.intercambiarDias(
      diaOrigen: movimiento.diaOrigen,
      diaDestino: movimiento.diaDestino,
    );
    switch (resultado) {
      case Ok(:final value):
        _plan = value;
        _aviso =
            'Listo: se intercambiaron los menús del ${kNombreDia[movimiento.diaOrigen]!.toLowerCase()} '
            'y del ${kNombreDia[movimiento.diaDestino]!.toLowerCase()}.';
        _ultimoIntercambio = movimiento;
      case Error(:final error):
        _aviso = mensajeDeError(error);
    }
    notifyListeners();
    return resultado;
  }
}
