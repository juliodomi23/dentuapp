import 'dart:io';

import 'package:dentu_app/config/constantes.dart';
import 'package:dentu_app/data/models/dia.dart';
import 'package:dentu_app/data/models/registro_comida.dart';
import 'package:dentu_app/data/repositories/diario_repository.dart';
import 'package:dentu_app/data/services/api_exception.dart';
import 'package:dentu_app/data/services/fake_api_service.dart';
import 'package:dentu_app/data/services/local_queue_service.dart';
import 'package:dentu_app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

const hoy = '2026-09-11';

/// Backend falso al que se le puede "quitar el internet" para los PUT.
class ApiConRedControlable extends FakeApiService {
  ApiConRedControlable() : super(reloj: () => DateTime(2026, 9, 11, 10), demora: Duration.zero);

  bool sinRed = false;
  int enviosComida = 0;
  int enviosAgua = 0;
  int enviosEjercicio = 0;

  @override
  Future<Result<RegistroComida>> guardarComida({
    required String fecha,
    required String tiempo,
    required String estado,
    String? queComio,
    String? nota,
    String? fotoPath,
  }) async {
    if (sinRed) return Result.error(ApiException.sinConexion());
    enviosComida++;
    return super.guardarComida(
      fecha: fecha,
      tiempo: tiempo,
      estado: estado,
      queComio: queComio,
      nota: nota,
      fotoPath: fotoPath,
    );
  }

  @override
  Future<Result<int>> guardarAgua(String fecha, int vasos) async {
    if (sinRed) return Result.error(ApiException.sinConexion());
    enviosAgua++;
    return super.guardarAgua(fecha, vasos);
  }

  @override
  Future<Result<({int minutos, String? tipo})>> guardarEjercicio({
    required String fecha,
    required int minutos,
    String? tipo,
  }) async {
    if (sinRed) return Result.error(ApiException.sinConexion());
    enviosEjercicio++;
    return super.guardarEjercicio(fecha: fecha, minutos: minutos, tipo: tipo);
  }
}

void main() {
  late Directory carpetaTemporal;
  late Directory carpetaFotos;
  late ApiConRedControlable api;
  late LocalQueueService cola;
  late DiarioRepository repositorio;
  var numeroDeCaja = 0;

  setUp(() async {
    carpetaTemporal = await Directory.systemTemp.createTemp('dentu_test_');
    carpetaFotos = await Directory('${carpetaTemporal.path}/fotos').create();
    Hive.init(carpetaTemporal.path);
    final caja = await Hive.openBox<dynamic>('cola_${numeroDeCaja++}');
    api = ApiConRedControlable();
    cola = LocalQueueService(caja: caja, carpetaFotos: carpetaFotos);
    repositorio = DiarioRepository(api: api, cola: cola);
    await repositorio.obtenerDia(hoy);
  });

  tearDown(() async {
    await Hive.close();
    await carpetaTemporal.delete(recursive: true);
  });

  Future<TiempoDia> tiempoDeHoy(String tiempo) async {
    final dia = ((await repositorio.obtenerDia(hoy)) as Ok<Dia>).value;
    return dia.tiempos.firstWhere((t) => t.tiempo == tiempo);
  }

  test('sin red: encola y devuelve el registro marcado como pendiente', () async {
    api.sinRed = true;

    final resultado = await repositorio.guardarComida(
      fecha: hoy,
      tiempo: 'comida',
      estado: EstadoComida.cumplido,
    );

    expect((resultado as Ok<RegistroComida>).value.pendiente, isTrue);
    expect(repositorio.totalPendientes, 1);
    final comida = await tiempoDeHoy('comida');
    expect(comida.registro?.pendiente, isTrue);
    expect(comida.registro?.planeado, isNotEmpty);
  });

  test('al volver la red vacía la cola y no duplica', () async {
    api.sinRed = true;
    await repositorio.guardarComida(fecha: hoy, tiempo: 'comida', estado: EstadoComida.cumplido);
    await repositorio.guardarComida(
      fecha: hoy,
      tiempo: 'comida',
      estado: EstadoComida.cambio,
      queComio: 'tacos de guisado',
    );
    await repositorio.guardarAgua(hoy, 6);
    await repositorio.guardarAgua(hoy, 7);
    expect(repositorio.totalPendientes, 2, reason: 'una por comida y una por agua');

    api.sinRed = false;
    await repositorio.reintentarPendientes();
    await repositorio.reintentarPendientes();

    expect(repositorio.totalPendientes, 0);
    expect(api.enviosComida, 1);
    expect(api.enviosAgua, 1);
    final comida = await tiempoDeHoy('comida');
    expect(comida.registro?.estado, EstadoComida.cambio);
    expect(comida.registro?.queComio, 'tacos de guisado');
    expect(comida.registro?.pendiente, isFalse);
    final dia = ((await repositorio.obtenerDia(hoy)) as Ok<Dia>).value;
    expect(dia.aguaVasos, 7);
    expect(dia.aguaPendiente, isFalse);
  });

  test('si sigue sin red, reintentar no pierde nada', () async {
    api.sinRed = true;
    await repositorio.guardarComida(fecha: hoy, tiempo: 'cena', estado: EstadoComida.omitido);

    await repositorio.reintentarPendientes();

    expect(repositorio.totalPendientes, 1);
  });

  test('un error que no es de red no se encola', () async {
    final resultado = await repositorio.guardarComida(
      fecha: hoy,
      tiempo: 'cena',
      estado: EstadoComida.cambio,
    );

    expect(((resultado as Error<RegistroComida>).error as ApiException).codigo, 400);
    expect(repositorio.totalPendientes, 0);
  });

  test('guarda una copia de la foto y la borra al enviarse', () async {
    final fotoDelPicker = File('${carpetaTemporal.path}/picker.jpg');
    await fotoDelPicker.writeAsBytes([1, 2, 3]);
    api.sinRed = true;

    await repositorio.guardarComida(
      fecha: hoy,
      tiempo: 'cena',
      estado: EstadoComida.cumplido,
      fotoPath: fotoDelPicker.path,
    );
    final copia = cola.leerTodas().single.fotoPath!;
    expect(copia.startsWith(carpetaFotos.path), isTrue);
    expect(File(copia).existsSync(), isTrue);

    api.sinRed = false;
    await repositorio.reintentarPendientes();

    expect(File(copia).existsSync(), isFalse);
    expect((await tiempoDeHoy('cena')).registro?.fotoId, isNotNull);
  });

  test('el ejercicio también se encola y se reintenta sin duplicar', () async {
    api.sinRed = true;

    final resultado = await repositorio.guardarEjercicio(fecha: hoy, minutos: 20, tipo: 'caminata');
    expect((resultado as Ok).value, (minutos: 20, tipo: 'caminata'));
    expect(repositorio.totalPendientes, 1);
    var dia = ((await repositorio.obtenerDia(hoy)) as Ok<Dia>).value;
    expect(dia.ejercicioPendiente, isTrue);
    expect(dia.ejercicioMin, 20);

    await repositorio.guardarEjercicio(fecha: hoy, minutos: 30, tipo: 'gym');
    expect(repositorio.totalPendientes, 1, reason: 'reemplaza al anterior, no se acumula');

    api.sinRed = false;
    await repositorio.reintentarPendientes();

    expect(repositorio.totalPendientes, 0);
    expect(api.enviosEjercicio, 1);
    dia = ((await repositorio.obtenerDia(hoy)) as Ok<Dia>).value;
    expect(dia.ejercicioMin, 30);
    expect(dia.ejercicioTipo, 'gym');
    expect(dia.ejercicioPendiente, isFalse);
  });
}
