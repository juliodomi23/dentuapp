import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../utils/result.dart';
import '../models/progreso.dart';
import '../services/api_service.dart';

class ProgresoRepository {
  ProgresoRepository({required ApiService api}) : _api = api;

  final ApiService _api;

  Future<Result<Progreso>> obtenerProgreso({String? desde}) =>
      _api.obtenerProgreso(desde: desde);

  String urlFoto(String fotoId) => _api.urlFoto(fotoId);

  Map<String, String> cabecerasFoto() => _api.cabecerasFoto();

  /// Las fotos de comida son datos sensibles: se borran del caché al salir.
  Future<void> limpiarCacheFotos() => DefaultCacheManager().emptyCache();
}
