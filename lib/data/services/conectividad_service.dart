import 'package:connectivity_plus/connectivity_plus.dart';

class ConectividadService {
  ConectividadService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emite `true` cuando el teléfono tiene alguna red y `false` cuando no.
  Stream<bool> get cambiosDeConexion =>
      _connectivity.onConnectivityChanged.map(_hayConexion);

  static bool _hayConexion(List<ConnectivityResult> redes) =>
      redes.any((red) => red != ConnectivityResult.none);
}
