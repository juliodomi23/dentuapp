import 'package:hive/hive.dart';

/// Ajustes locales que no son secretos (consentimiento, recordatorios).
class PreferenciasService {
  PreferenciasService(this._caja);

  static const String nombreCaja = 'preferencias';

  final Box<dynamic> _caja;

  static Future<PreferenciasService> abrir() async =>
      PreferenciasService(await Hive.openBox<dynamic>(nombreCaja));

  bool? leerBool(String clave) => _caja.get(clave) as bool?;

  Future<void> guardarBool(String clave, bool valor) => _caja.put(clave, valor);

  Map<String, dynamic>? leerMapa(String clave) {
    final valor = _caja.get(clave);
    return valor == null ? null : Map<String, dynamic>.from(valor as Map);
  }

  Future<void> guardarMapa(String clave, Map<String, dynamic> valor) =>
      _caja.put(clave, valor);

  Future<void> borrar(String clave) => _caja.delete(clave);
}
