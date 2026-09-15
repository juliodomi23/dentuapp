import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/operacion_pendiente.dart';

/// Cola offline en Hive. Cada operación se guarda con su `clave`, así una
/// operación nueva para la misma comida reemplaza a la anterior.
class LocalQueueService {
  LocalQueueService({required Box<dynamic> caja, required Directory carpetaFotos})
    : _caja = caja,
      _carpetaFotos = carpetaFotos;

  static const String nombreCaja = 'cola_offline';

  final Box<dynamic> _caja;
  final Directory _carpetaFotos;

  static Future<LocalQueueService> abrir() async {
    final caja = await Hive.openBox<dynamic>(nombreCaja);
    final documentos = await getApplicationDocumentsDirectory();
    final carpeta = Directory('${documentos.path}/fotos_pendientes');
    await carpeta.create(recursive: true);
    return LocalQueueService(caja: caja, carpetaFotos: carpeta);
  }

  /// De la más vieja a la más nueva.
  List<OperacionPendiente> leerTodas() {
    return _caja.values.map(_desdeHive).toList()
      ..sort((a, b) => a.creadaEn.compareTo(b.creadaEn));
  }

  OperacionPendiente? buscar(String clave) {
    final valor = _caja.get(clave);
    return valor == null ? null : _desdeHive(valor);
  }

  Future<void> guardar(OperacionPendiente operacion) =>
      _caja.put(operacion.clave, operacion.toMap());

  Future<void> borrar(String clave) => _caja.delete(clave);

  Future<void> borrarTodas() async {
    await _caja.clear();
    if (!await _carpetaFotos.exists()) return;
    await for (final archivo in _carpetaFotos.list()) {
      await archivo.delete();
    }
  }

  /// Copia la foto a la carpeta de la app, porque el picker la deja en una
  /// carpeta temporal que el sistema puede borrar.
  Future<String> copiarFoto(String rutaOriginal) async {
    final nombre = rutaOriginal.split(RegExp(r'[/\\]')).last;
    final punto = nombre.lastIndexOf('.');
    final extension = punto == -1 ? '.jpg' : nombre.substring(punto);
    final destino =
        '${_carpetaFotos.path}/${DateTime.now().microsecondsSinceEpoch}$extension';
    await File(rutaOriginal).copy(destino);
    return destino;
  }

  /// Solo borra fotos que viven en la carpeta de la cola.
  Future<void> borrarFoto(String? ruta) async {
    if (ruta == null || !ruta.startsWith(_carpetaFotos.path)) return;
    final archivo = File(ruta);
    if (await archivo.exists()) await archivo.delete();
  }

  OperacionPendiente _desdeHive(dynamic valor) =>
      OperacionPendiente.fromMap(Map<String, dynamic>.from(valor as Map));
}
