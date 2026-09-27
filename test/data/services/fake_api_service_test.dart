import 'package:dentu_app/config/constantes.dart';
import 'package:dentu_app/data/models/dia.dart';
import 'package:dentu_app/data/models/registro_comida.dart';
import 'package:dentu_app/data/services/api_exception.dart';
import 'package:dentu_app/data/services/fake_api_service.dart';
import 'package:dentu_app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hoy es jueves 11 de septiembre de 2026.
FakeApiService crearApi() =>
    FakeApiService(reloj: () => DateTime(2026, 9, 11, 10), demora: Duration.zero);

int? codigoDeError(Result<Object?> resultado) =>
    resultado is Error<Object?> ? (resultado.error as ApiException).codigo : null;

void main() {
  group('rango de fechas para registrar', () {
    test('permite hoy y hasta 7 días atrás', () async {
      final api = crearApi();

      final hoy = await api.guardarComida(fecha: '2026-09-11', tiempo: 'cena', estado: EstadoComida.cumplido);
      final hace7 = await api.guardarComida(fecha: '2026-09-04', tiempo: 'cena', estado: EstadoComida.cumplido);

      expect(hoy, isA<Ok<RegistroComida>>());
      expect(hace7, isA<Ok<RegistroComida>>());
    });

    test('rechaza con 400 hace 8 días, mañana y fechas mal escritas', () async {
      final api = crearApi();

      Future<int?> intentar(String fecha) async => codigoDeError(
        await api.guardarComida(fecha: fecha, tiempo: 'cena', estado: EstadoComida.cumplido),
      );

      expect(await intentar('2026-09-03'), 400);
      expect(await intentar('2026-09-12'), 400);
      expect(await intentar('11-09-2026'), 400);
      expect(await intentar('2026-02-30'), 400);
    });

    test('el agua y deshacer usan el mismo rango', () async {
      final api = crearApi();

      expect(codigoDeError(await api.guardarAgua('2026-09-03', 5)), 400);
      expect(codigoDeError(await api.guardarAgua('2026-09-11', 31)), 400);
      expect(codigoDeError(await api.borrarComida('2026-09-03', 'cena')), 400);
      expect(codigoDeError(await api.borrarComida('2026-09-11', 'cena')), 404);
    });

    test('el ejercicio usa el mismo rango y valida minutos y tipo', () async {
      final api = crearApi();

      expect(
        codigoDeError(await api.guardarEjercicio(fecha: '2026-09-03', minutos: 20)),
        400,
      );
      expect(
        codigoDeError(await api.guardarEjercicio(fecha: '2026-09-11', minutos: 601)),
        400,
      );
      expect(
        codigoDeError(await api.guardarEjercicio(fecha: '2026-09-11', minutos: -1)),
        400,
      );
      expect(
        codigoDeError(
          await api.guardarEjercicio(
            fecha: '2026-09-11',
            minutos: 30,
            tipo: 'x' * 61,
          ),
        ),
        400,
      );

      final ok = await api.guardarEjercicio(fecha: '2026-09-11', minutos: 30, tipo: 'caminata');
      expect(
        (ok as Ok).value,
        (minutos: 30, tipo: 'caminata', caloriasReloj: null),
      );
    });

    test('puede_registrar del día sigue la misma regla', () async {
      final api = crearApi();

      Future<bool> puede(String fecha) async =>
          ((await api.obtenerDia(fecha)) as Ok<Dia>).value.puedeRegistrar;

      expect(await puede('2026-09-11'), isTrue);
      expect(await puede('2026-09-04'), isTrue);
      expect(await puede('2026-09-03'), isFalse);
      expect(await puede('2026-09-12'), isFalse);
    });
  });

  group('estado "cambio"', () {
    test('sin que_comio (o solo espacios) responde 400', () async {
      final api = crearApi();

      final sinTexto = await api.guardarComida(fecha: '2026-09-11', tiempo: 'cena', estado: EstadoComida.cambio);
      final soloEspacios = await api.guardarComida(
        fecha: '2026-09-11',
        tiempo: 'cena',
        estado: EstadoComida.cambio,
        queComio: '   ',
      );

      expect(codigoDeError(sinTexto), 400);
      expect(codigoDeError(soloEspacios), 400);
    });

    test('con que_comio se guarda con origen app', () async {
      final api = crearApi();

      final resultado = await api.guardarComida(
        fecha: '2026-09-11',
        tiempo: 'cena',
        estado: EstadoComida.cambio,
        queComio: 'tacos de guisado',
      );

      final registro = (resultado as Ok<RegistroComida>).value;
      expect(registro.estado, EstadoComida.cambio);
      expect(registro.queComio, 'tacos de guisado');
      expect(registro.origen, 'app');
    });
  });

  test('intercambiar el mismo día responde 400', () async {
    final resultado = await crearApi().intercambiarDias(diaOrigen: 'lunes', diaDestino: 'lunes');
    expect(codigoDeError(resultado), 400);
  });

  test('borrar cuenta conserva lo registrado por WhatsApp', () async {
    final api = crearApi();

    await api.borrarCuenta();
    final dia = ((await api.obtenerDia('2026-09-11')) as Ok<Dia>).value;

    final desayuno = dia.tiempos.firstWhere((t) => t.tiempo == 'desayuno');
    final colacion = dia.tiempos.firstWhere((t) => t.tiempo == 'colacion_am');
    expect(desayuno.registro, isNull, reason: 'era de la app');
    expect(colacion.registro?.origen, 'whatsapp');
    expect(dia.aguaVasos, 0);
  });
}
