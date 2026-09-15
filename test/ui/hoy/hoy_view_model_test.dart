import 'dart:async';

import 'package:dentu_app/config/constantes.dart';
import 'package:dentu_app/data/models/dia.dart';
import 'package:dentu_app/data/models/lista_compra.dart';
import 'package:dentu_app/data/models/plan.dart';
import 'package:dentu_app/data/models/preparacion.dart';
import 'package:dentu_app/data/models/registro_comida.dart';
import 'package:dentu_app/data/repositories/diario_repository.dart';
import 'package:dentu_app/data/repositories/plan_repository.dart';
import 'package:dentu_app/data/services/api_exception.dart';
import 'package:dentu_app/ui/hoy/view_models/hoy_view_model.dart';
import 'package:dentu_app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Dia diaDePrueba({int? reto21Dia}) => Dia(
  fecha: '2026-09-11',
  diaSemana: 'jueves',
  planId: 'plan-1',
  modo: 'menu',
  puedeRegistrar: true,
  aguaVasos: 0,
  reto21Dia: reto21Dia ?? 8,
  tiempos: [
    for (final tiempo in kTiempos)
      TiempoDia(tiempo: tiempo, planeado: 'Platillo de $tiempo', registro: null),
  ],
  faltan: kTiempos,
);

class FakeDiarioRepository extends ChangeNotifier implements DiarioRepository {
  Completer<Result<Dia>>? cargaEnCurso;
  Result<Dia> respuestaCarga = Result.ok(diaDePrueba());
  bool registrarComoPendiente = false;
  final List<({String fecha, int vasos})> aguaGuardada = [];
  final List<({String fecha, int minutos, String? tipo})> ejercicioGuardado = [];
  Dia? _dia;

  @override
  int get totalPendientes => 0;

  @override
  void iniciarSincronizacion() {}

  @override
  Future<Result<Dia>> obtenerDia(String fecha) async {
    final resultado = cargaEnCurso != null ? await cargaEnCurso!.future : respuestaCarga;
    if (resultado case Ok(:final value)) _dia = value;
    return resultado;
  }

  @override
  Dia? diaEnCache(String fecha) => _dia?.fecha == fecha ? _dia : null;

  @override
  Future<Result<RegistroComida>> guardarComida({
    required String fecha,
    required String tiempo,
    required String estado,
    String? queComio,
    String? nota,
    String? fotoPath,
  }) async {
    final registro = RegistroComida(
      id: 'r1',
      fecha: fecha,
      tiempo: tiempo,
      planId: 'plan-1',
      planeado: 'Platillo de $tiempo',
      estado: estado,
      queComio: queComio,
      nota: nota,
      fotoId: null,
      origen: 'app',
      createdAt: DateTime(2026, 9, 11),
      updatedAt: DateTime(2026, 9, 11),
      pendiente: registrarComoPendiente,
    );
    _dia = _dia!.copyWith(
      tiempos: [
        for (final t in _dia!.tiempos) t.tiempo == tiempo ? t.conRegistro(registro) : t,
      ],
    );
    notifyListeners();
    return Result.ok(registro);
  }

  @override
  Future<Result<void>> borrarComida(String fecha, String tiempo) async => const Result.ok(null);

  @override
  Future<Result<int>> guardarAgua(String fecha, int vasos) async {
    aguaGuardada.add((fecha: fecha, vasos: vasos));
    _dia = _dia!.copyWith(aguaVasos: vasos);
    return Result.ok(vasos);
  }

  @override
  Future<Result<({int minutos, String? tipo})>> guardarEjercicio({
    required String fecha,
    required int minutos,
    String? tipo,
  }) async {
    ejercicioGuardado.add((fecha: fecha, minutos: minutos, tipo: tipo));
    _dia = _dia!.copyWith(
      ejercicioMin: minutos,
      ejercicioTipo: tipo,
      borrarEjercicioTipo: tipo == null,
    );
    return Result.ok((minutos: minutos, tipo: tipo));
  }

  @override
  Future<void> reintentarPendientes() async {}

  @override
  Future<void> descartarPendientes() async {}

  @override
  String urlFoto(String fotoId) => 'mock://$fotoId';

  @override
  Map<String, String> cabecerasFoto() => {};

  @override
  Future<Result<Preparacion>> obtenerPreparacion(String platillo) async =>
      const Result.error(ApiException(404, 'Sin preparación'));
}

class FakePlanRepository implements PlanRepository {
  @override
  Future<Result<Plan?>> obtenerSemana() async => const Result.ok(null);

  @override
  Future<Result<Plan>> intercambiarDias({
    required String diaOrigen,
    required String diaDestino,
  }) async => const Result.error(ApiException(404, 'Sin plan'));

  @override
  Future<Result<ListaCompra>> obtenerListaCompra() async =>
      const Result.error(ApiException(404, 'Sin plan'));
}

void main() {
  late FakeDiarioRepository diario;

  HoyViewModel crearViewModel() => HoyViewModel(
    diario: diario,
    plan: FakePlanRepository(),
    reloj: () => DateTime(2026, 9, 11, 10),
    esperaAntesDeGuardar: Duration.zero,
  );

  setUp(() => diario = FakeDiarioRepository());

  test('muestra la carga y luego el día', () async {
    diario.cargaEnCurso = Completer();
    final vm = crearViewModel();

    expect(vm.cargarDia.running, isTrue);
    expect(vm.dia, isNull);

    diario.cargaEnCurso!.complete(Result.ok(diaDePrueba()));
    await pumpEventQueue();

    expect(vm.cargarDia.running, isFalse);
    expect(vm.cargarDia.completed, isTrue);
    expect(vm.dia?.fecha, '2026-09-11');
    expect(vm.subtituloFecha, 'Hoy');
  });

  test('si falla la carga expone el error', () async {
    diario.respuestaCarga = const Result.error(
      ApiException(500, 'El servidor no está disponible.'),
    );
    final vm = crearViewModel();
    await pumpEventQueue();

    expect(vm.cargarDia.error, isTrue);
    expect(vm.mensajeErrorCarga, 'El servidor no está disponible.');
    expect(vm.dia, isNull);
  });

  test('registrar una comida actualiza el día y avisa', () async {
    final vm = crearViewModel();
    await pumpEventQueue();

    await vm.registrarComida.execute((
      tiempo: 'comida',
      estado: EstadoComida.cumplido,
      queComio: null,
      fotoPath: null,
    ));

    expect(vm.registrarComida.completed, isTrue);
    final comida = vm.dia!.tiempos.firstWhere((t) => t.tiempo == 'comida');
    expect(comida.registro?.estado, EstadoComida.cumplido);
    expect(vm.tiempoEnProceso, isNull);
    expect(vm.tomarAviso(), 'Comida registrada.');
  });

  test('un registro pendiente avisa que se enviará después', () async {
    diario.registrarComoPendiente = true;
    final vm = crearViewModel();
    await pumpEventQueue();

    await vm.registrarComida.execute((
      tiempo: 'cena',
      estado: EstadoComida.omitido,
      queComio: null,
      fotoPath: null,
    ));

    expect(vm.dia!.tiempos.last.registro?.pendiente, isTrue);
    expect(vm.tomarAviso(), contains('Sin conexión'));
  });

  test('varios toques de agua mandan solo el último valor', () async {
    final vm = crearViewModel();
    await pumpEventQueue();

    vm.sumarAgua();
    vm.sumarAgua();
    vm.sumarAgua();
    expect(vm.dia!.aguaVasos, 3);
    await pumpEventQueue();

    expect(diario.aguaGuardada, [(fecha: '2026-09-11', vasos: 3)]);
    expect(vm.dia!.aguaVasos, 3);
  });

  test('varios toques de ejercicio mandan solo el último valor', () async {
    final vm = crearViewModel();
    await pumpEventQueue();

    vm.sumarMinutosEjercicio();
    vm.sumarMinutosEjercicio();
    expect(vm.dia!.ejercicioMin, LimitesRegistro.ejercicioPaso * 2);
    await pumpEventQueue();

    expect(diario.ejercicioGuardado, [
      (fecha: '2026-09-11', minutos: LimitesRegistro.ejercicioPaso * 2, tipo: null),
    ]);
  });

  test('el objetivo del día se arma con las macros del plan', () async {
    final vm = HoyViewModel(
      diario: diario,
      plan: _PlanConMacros(),
      reloj: () => DateTime(2026, 9, 11, 10),
      esperaAntesDeGuardar: Duration.zero,
    );
    await pumpEventQueue();

    expect(
      vm.textoObjetivoDia,
      'Objetivo del día: 2000 kcal · 100g proteína · 275g carbos · 55g grasas',
    );
  });

  group('celebración de hitos', () {
    test('se celebra cuando se completan todas las comidas del día', () async {
      final vm = crearViewModel();
      await pumpEventQueue();

      expect(vm.tomarCelebracion(), isNull);

      for (final tiempo in kTiempos) {
        await vm.registrarComida.execute((
          tiempo: tiempo,
          estado: EstadoComida.cumplido,
          queComio: null,
          fotoPath: null,
        ));
      }

      final celebracion = vm.tomarCelebracion();
      expect(celebracion, isNotNull);
      expect(celebracion!.mensaje, '¡Completaste todo tu día!');
    });

    test('no se celebra un registro normal que no completa el día', () async {
      final vm = crearViewModel();
      await pumpEventQueue();

      await vm.registrarComida.execute((
        tiempo: 'desayuno',
        estado: EstadoComida.cumplido,
        queComio: null,
        fotoPath: null,
      ));

      expect(vm.tomarCelebracion(), isNull);
    });

    test('se celebra al cargar un día hito del Reto 21', () async {
      diario.respuestaCarga = Result.ok(diaDePrueba(reto21Dia: 7));
      final vm = crearViewModel();
      await pumpEventQueue();

      final celebracion = vm.tomarCelebracion();
      expect(celebracion, isNotNull);
      expect(celebracion!.mensaje, 'Ya llevas una semana.');
    });

    test('un día que no es hito del Reto 21 no celebra al cargar', () async {
      diario.respuestaCarga = Result.ok(diaDePrueba(reto21Dia: 8));
      final vm = crearViewModel();
      await pumpEventQueue();

      expect(vm.tomarCelebracion(), isNull);
    });

    test('la celebración no se repite dos veces para el mismo día', () async {
      diario.respuestaCarga = Result.ok(diaDePrueba(reto21Dia: 7));
      final vm = crearViewModel();
      await pumpEventQueue();

      expect(vm.tomarCelebracion(), isNotNull);

      await vm.registrarComida.execute((
        tiempo: 'desayuno',
        estado: EstadoComida.cumplido,
        queComio: null,
        fotoPath: null,
      ));

      expect(vm.tomarCelebracion(), isNull);
    });
  });
}

class _PlanConMacros implements PlanRepository {
  @override
  Future<Result<Plan?>> obtenerSemana() async => Result.ok(
    Plan(
      id: 'plan-1',
      nombre: 'Semana 1',
      fechaInicio: '2026-09-01',
      modo: 'menu',
      notas: null,
      caloriasObjetivo: 2000,
      proteinasG: 100,
      carbohidratosG: 275,
      grasasG: 55,
      equivalentes: const {},
      dias: {for (final dia in kDiasSemana) dia: ComidasDia.vacio},
    ),
  );

  @override
  Future<Result<Plan>> intercambiarDias({
    required String diaOrigen,
    required String diaDestino,
  }) async => const Result.error(ApiException(404, 'Sin plan'));

  @override
  Future<Result<ListaCompra>> obtenerListaCompra() async =>
      const Result.error(ApiException(404, 'Sin plan'));
}
