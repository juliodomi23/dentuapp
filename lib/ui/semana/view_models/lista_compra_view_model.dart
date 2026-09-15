import 'package:flutter/foundation.dart';

import '../../../data/models/lista_compra.dart';
import '../../../data/repositories/plan_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/mensaje_error.dart';

class ListaCompraViewModel extends ChangeNotifier {
  ListaCompraViewModel({required PlanRepository plan}) : _plan = plan {
    generar = Command0<void>(_generar)..execute();
  }

  final PlanRepository _plan;

  late final Command0<void> generar;

  ListaCompra? _lista;
  String? _mensajeError;

  ListaCompra? get lista => _lista;

  String? get mensajeError => _mensajeError;

  Future<Result<void>> _generar() async {
    final resultado = await _plan.obtenerListaCompra();
    switch (resultado) {
      case Ok(:final value):
        _lista = value;
        _mensajeError = null;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        _mensajeError = mensajeDeError(error);
        notifyListeners();
        return Result.error(error);
    }
  }
}
