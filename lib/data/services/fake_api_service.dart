import 'dart:io';

import '../../config/app_config.dart';
import '../../config/constantes.dart';
import '../../utils/fechas.dart';
import '../../utils/result.dart';
import '../models/dia.dart';
import '../models/lista_compra.dart';
import '../models/paciente_app.dart';
import '../models/perfil_paciente.dart';
import '../models/plan.dart';
import '../models/preparacion.dart';
import '../models/progreso.dart';
import '../models/registro_comida.dart';
import '../models/registro_sintomas.dart';
import 'api_exception.dart';
import 'api_service.dart';

/// Backend falso en memoria (`--dart-define=USE_MOCK=true`).
/// Aplica las mismas validaciones que el contrato para que la UI se pruebe igual.
///
/// Vincular: cualquier teléfono de 10 dígitos y cualquier código de 6 dígitos,
/// excepto `000000`, que responde 401 "Código inválido o vencido".
class FakeApiService implements ApiService {
  FakeApiService({
    DateTime Function()? reloj,
    this.demora = const Duration(milliseconds: 350),
    bool modoEquivalentes = false,
  }) : _reloj = reloj ?? DateTime.now {
    _plan = _crearPlan(modoEquivalentes);
    _paciente = _crearPaciente();
    _sembrarDatos();
  }

  static const int _maxFotoBytes = 5 * 1024 * 1024;

  final DateTime Function() _reloj;
  final Duration demora;

  late Plan _plan;
  late PacienteApp _paciente;
  final Map<String, RegistroComida> _registros = {};
  final Map<String, int> _agua = {};
  final Map<String, ({int minutos, String? tipo, int? caloriasReloj})>
  _ejercicio = {};
  final List<PuntoPeso> _pesos = [];
  final List<({RegistroSintomas registro, String origen})> _sintomas = [];
  final Map<String, String> _fotosLocales = {};
  int _siguienteId = 1;

  @override
  String get urlVinculacion => 'mock://dentu';

  @override
  String? Function()? leerToken;

  @override
  String? Function()? leerBaseUrl;

  @override
  void Function()? alNoAutorizado;

  DateTime get _hoy => soloFecha(_reloj());

  @override
  Future<Result<ResultadoVinculacion>> vincular({
    required String telefono,
    required String codigo,
  }) async {
    await _esperar();
    if (!RegExp(r'^\d{10,13}$').hasMatch(telefono)) {
      return _error(400, 'El teléfono debe tener 10 dígitos.');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      return _error(400, 'El código debe tener 6 dígitos.');
    }
    if (codigo == '000000') return _error(401, 'Código inválido o vencido');
    return Result.ok(
      ResultadoVinculacion(token: 'token-falso', paciente: _paciente),
    );
  }

  @override
  Future<Result<ResultadoVinculacion>> crearCuentaPersonal({
    required String nombre,
    required String email,
    required String password,
  }) async {
    _paciente = PacienteApp(
      id: 'personal-demo',
      nombre: nombre,
      apellido: '',
      telefono: '',
      objetivo: null,
      tienePlan: true,
      reto21: null,
      clinica: _paciente.clinica,
      esPersonal: true,
    );
    return Result.ok(
      ResultadoVinculacion(token: 'token-personal-demo', paciente: _paciente),
    );
  }

  @override
  Future<Result<ResultadoVinculacion>> iniciarCuentaPersonal({
    required String email,
    required String password,
  }) =>
      crearCuentaPersonal(nombre: 'Usuario', email: email, password: password);

  @override
  Future<Result<Map<String, dynamic>>> extraerDieta(List<String> rutas) async {
    return Result.ok({
      'nombre': 'Mi dieta importada',
      'notas': 'Revisa las indicaciones originales.',
      'dias': {
        for (final dia in kDiasSemana)
          dia: {
            for (final tiempo in kTiempos)
              tiempo: _plan.comidasDe(dia).deTiempo(tiempo),
          },
      },
    });
  }

  @override
  Future<Result<Plan>> guardarDietaPersonal(
    Map<String, dynamic> borrador,
  ) async {
    _plan = Plan.fromJson({
      'id': 'plan-personal-demo',
      'fecha_inicio': fechaIso(_hoy),
      'modo': 'menu',
      'equivalentes': {},
      'calorias_objetivo': null,
      'proteinas_g': null,
      'carbohidratos_g': null,
      'grasas_g': null,
      ...borrador,
    });
    return Result.ok(_plan);
  }

  @override
  Future<Result<Map<String, dynamic>>> consultarIap() async => Result.ok({
    'requerido': false,
    'activo': true,
    'product_id': null,
    'expira': null,
    'review_bypass': false,
  });

  @override
  Future<Result<Map<String, dynamic>>> validarCompraApple(
    String recibo,
  ) async => consultarIap();

  @override
  Future<Result<PacienteApp>> obtenerPerfil() async {
    await _esperar();
    return Result.ok(_paciente);
  }

  @override
  Future<Result<PerfilPaciente>> obtenerPerfilPaciente() async {
    await _esperar();
    return Result.ok(
      PerfilPaciente(
        id: _paciente.id,
        nombre: _paciente.nombre,
        apellido: _paciente.apellido,
        telefono: _paciente.telefono,
        email: 'maria.lopez@ejemplo.com',
        fechaNacimiento: '1990-03-14',
        sexo: 'femenino',
        peso: _pesos.isEmpty ? null : _pesos.last.peso,
        estatura: 162,
        objetivo: _paciente.objetivo,
        actividadFisica: 'Camina 30 minutos, 3 veces por semana',
        enfermedadesCronicas: const ['Gastritis'],
        alergiasAlimentarias: const [],
        ultimaMedicion: UltimaMedicion(
          fecha: fechaIso(sumarDias(_hoy, -13)),
          peso: 85.0,
          cintura: 92,
          cadera: 104,
          grasaCorporal: 34.5,
          masaMuscular: null,
        ),
      ),
    );
  }

  /// Hay un solo plan, así que siempre es "el más reciente" (regla del contrato).
  @override
  Future<Result<Plan?>> obtenerPlanSemana() async {
    await _esperar();
    return Result.ok(_plan);
  }

  @override
  Future<Result<ListaCompra>> obtenerListaCompra() async {
    await _esperar();
    return Result.ok(
      ListaCompra.fromJson({
        'categorias': [
          {
            'nombre': 'Frutas y verduras',
            'items': ['1 kg de jitomate', '1 lechuga', '6 plátanos'],
          },
          {
            'nombre': 'Proteínas',
            'items': ['12 huevos', '500g de pechuga de pollo'],
          },
        ],
      }),
    );
  }

  @override
  Future<Result<Preparacion>> obtenerPreparacion(String platillo) async {
    await _esperar();
    return Result.ok(
      Preparacion.fromJson({
        'ingredientes': [
          '1 huevo',
          '1 tortilla de maíz',
          '1/4 taza de salsa roja',
        ],
        'pasos': [
          'Calienta la tortilla en un comal.',
          'Fríe el huevo al gusto.',
          'Sirve sobre la tortilla y baña con la salsa caliente.',
        ],
        'tiempo_min': 15,
        'dificultad': 'fácil',
      }),
    );
  }

  @override
  Future<Result<Dia>> obtenerDia(String fecha) async {
    await _esperar();
    final dia = parsearFechaIso(fecha);
    if (dia == null) return _error(400, 'Fecha inválida');
    return Result.ok(_construirDia(dia));
  }

  @override
  Future<Result<RegistroComida>> guardarComida({
    required String fecha,
    required String tiempo,
    required String estado,
    String? queComio,
    String? nota,
    String? fotoPath,
  }) async {
    await _esperar();
    final errorFecha = _validarFechaRegistrable(fecha);
    if (errorFecha != null) return Result.error(errorFecha);
    if (!kTiempos.contains(tiempo)) return _error(400, 'Tiempo inválido');
    if (!EstadoComida.todos.contains(estado)) {
      return _error(400, 'Estado inválido');
    }
    final textoQueComio = queComio?.trim() ?? '';
    if (estado == EstadoComida.cambio && textoQueComio.isEmpty) {
      return _error(400, 'Escribe qué comiste en su lugar.');
    }
    if (textoQueComio.length > LimitesRegistro.queComioMax) {
      return _error(400, 'Lo que comiste debe tener máximo 300 caracteres.');
    }
    if ((nota?.length ?? 0) > LimitesRegistro.notaMax) {
      return _error(400, 'La nota debe tener máximo 500 caracteres.');
    }
    if (fotoPath != null) {
      final archivo = File(fotoPath);
      if (archivo.existsSync() && archivo.lengthSync() > _maxFotoBytes) {
        return _error(413, 'La foto pesa más de 5 MB.');
      }
    }

    final clave = _claveRegistro(fecha, tiempo);
    final anterior = _registros[clave];
    String? fotoId = anterior?.fotoId;
    if (fotoPath != null) {
      fotoId = 'foto-${_siguienteId++}';
      _fotosLocales[fotoId] = fotoPath;
    }
    final ahora = DateTime.now().toUtc();
    final registro = RegistroComida(
      id: anterior?.id ?? 'reg-${_siguienteId++}',
      fecha: fecha,
      tiempo: tiempo,
      planId: _plan.id,
      planeado: _planeadoPara(parsearFechaIso(fecha)!, tiempo),
      estado: estado,
      queComio: textoQueComio.isEmpty ? null : textoQueComio,
      nota: nota,
      fotoId: fotoId,
      origen: 'app',
      createdAt: anterior?.createdAt ?? ahora,
      updatedAt: ahora,
    );
    _registros[clave] = registro;
    return Result.ok(registro);
  }

  @override
  Future<Result<void>> borrarComida(String fecha, String tiempo) async {
    await _esperar();
    final errorFecha = _validarFechaRegistrable(fecha);
    if (errorFecha != null) return Result.error(errorFecha);
    final borrado = _registros.remove(_claveRegistro(fecha, tiempo));
    if (borrado == null) return _error(404, 'No existe ese registro');
    _fotosLocales.remove(borrado.fotoId);
    return const Result.ok(null);
  }

  @override
  Future<Result<int>> guardarAgua(String fecha, int vasos) async {
    await _esperar();
    final errorFecha = _validarFechaRegistrable(fecha);
    if (errorFecha != null) return Result.error(errorFecha);
    if (vasos < 0 || vasos > LimitesRegistro.aguaMax) {
      return _error(400, 'Los vasos de agua deben estar entre 0 y 30.');
    }
    _agua[fecha] = vasos;
    return Result.ok(vasos);
  }

  @override
  Future<Result<({int minutos, String? tipo, int? caloriasReloj})>>
  guardarEjercicio({
    required String fecha,
    required int minutos,
    String? tipo,
    int? caloriasReloj,
  }) async {
    await _esperar();
    final errorFecha = _validarFechaRegistrable(fecha);
    if (errorFecha != null) return Result.error(errorFecha);
    if (minutos < 0 || minutos > LimitesRegistro.ejercicioMinMax) {
      return _error(400, 'Los minutos de ejercicio deben estar entre 0 y 600.');
    }
    final textoTipo = tipo?.trim();
    if ((textoTipo?.length ?? 0) > LimitesRegistro.ejercicioTipoMax) {
      return _error(
        400,
        'El tipo de ejercicio debe tener máximo 60 caracteres.',
      );
    }
    if (caloriasReloj != null && (caloriasReloj < 0 || caloriasReloj > 5000)) {
      return _error(400, 'Las calorías del reloj deben estar entre 0 y 5000.');
    }
    final valor = (
      minutos: minutos,
      tipo: textoTipo?.isEmpty ?? true ? null : textoTipo,
      caloriasReloj: caloriasReloj,
    );
    _ejercicio[fecha] = valor;
    return Result.ok(valor);
  }

  @override
  Future<Result<Plan>> intercambiarDias({
    required String diaOrigen,
    required String diaDestino,
  }) async {
    await _esperar();
    if (!kDiasSemana.contains(diaOrigen) || !kDiasSemana.contains(diaDestino)) {
      return _error(400, 'Día inválido');
    }
    if (diaOrigen == diaDestino) {
      return _error(400, 'Elige dos días distintos.');
    }
    final dias = Map<String, ComidasDia>.from(_plan.dias);
    dias[diaOrigen] = _plan.dias[diaDestino]!;
    dias[diaDestino] = _plan.dias[diaOrigen]!;
    _plan = _plan.copyWith(dias: dias);
    return Result.ok(_plan);
  }

  @override
  Future<Result<void>> registrarPeso(double peso, {String? fecha}) async {
    await _esperar();
    if (peso < LimitesRegistro.pesoMin || peso > LimitesRegistro.pesoMax) {
      return _error(400, 'El peso debe estar entre 20 y 400 kg.');
    }
    final fechaPeso = fecha ?? fechaIso(_hoy);
    if (parsearFechaIso(fechaPeso) == null) {
      return _error(400, 'Fecha inválida');
    }
    _pesos
      ..add(PuntoPeso(fecha: fechaPeso, peso: peso, origen: 'app'))
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> registrarSintomas(RegistroSintomas sintomas) async {
    await _esperar();
    final fueraDeRango = sintomas.valores.values.any((v) => v < 1 || v > 5);
    if (fueraDeRango) return _error(400, 'Cada valor debe estar entre 1 y 5.');
    _sintomas.add((
      registro: RegistroSintomas(
        valores: sintomas.valores,
        fecha: sintomas.fecha ?? fechaIso(_hoy),
        notas: sintomas.notas,
      ),
      origen: 'app',
    ));
    return const Result.ok(null);
  }

  @override
  Future<Result<Progreso>> obtenerProgreso({String? desde}) async {
    await _esperar();
    final inicio = desde == null
        ? sumarDias(_hoy, -13)
        : parsearFechaIso(desde);
    if (inicio == null) return _error(400, 'Fecha inválida');
    return Result.ok(_calcularProgreso(inicio));
  }

  @override
  Future<Result<void>> borrarCuenta() async {
    await _esperar();
    // Solo lo que vino de la app. Lo de WhatsApp y consulta se conserva.
    final clavesDeLaApp = _registros.entries
        .where((entrada) => entrada.value.origen == 'app')
        .map((entrada) => entrada.key)
        .toList();
    for (final clave in clavesDeLaApp) {
      _fotosLocales.remove(_registros.remove(clave)?.fotoId);
    }
    _agua.clear();
    _ejercicio.clear();
    _pesos.removeWhere((p) => p.origen == 'app');
    _sintomas.removeWhere((s) => s.origen == 'app');
    return const Result.ok(null);
  }

  @override
  String urlFoto(String fotoId) {
    final local = _fotosLocales[fotoId];
    return local == null ? 'mock://$fotoId' : 'file://$local';
  }

  @override
  Map<String, String> cabecerasFoto() => {};

  // ---------------------------------------------------------------------------

  Future<void> _esperar() async {
    if (demora > Duration.zero) await Future<void>.delayed(demora);
  }

  Result<T> _error<T>(int codigo, String mensaje) =>
      Result.error(ApiException(codigo, mensaje));

  String _claveRegistro(String fecha, String tiempo) => '$fecha|$tiempo';

  ApiException? _validarFechaRegistrable(String fecha) {
    final dia = parsearFechaIso(fecha);
    if (dia == null) return const ApiException(400, 'Fecha inválida');
    final diasAtras = diasEntre(dia, _hoy);
    if (diasAtras < 0 || diasAtras > AppConfig.diasAtrasParaRegistrar) {
      return const ApiException(
        400,
        'Solo puedes registrar desde hace 7 días hasta hoy.',
      );
    }
    return null;
  }

  bool _puedeRegistrar(DateTime dia) {
    final diasAtras = diasEntre(dia, _hoy);
    return diasAtras >= 0 && diasAtras <= AppConfig.diasAtrasParaRegistrar;
  }

  String _planeadoPara(DateTime dia, String tiempo) =>
      _plan.comidasDe(diaSemanaDe(dia)).deTiempo(tiempo);

  Dia _construirDia(DateTime dia) {
    final fecha = fechaIso(dia);
    final tiempos = [
      for (final tiempo in kTiempos)
        TiempoDia(
          tiempo: tiempo,
          planeado: _planeadoPara(dia, tiempo),
          registro: _registros[_claveRegistro(fecha, tiempo)],
        ),
    ];
    final ejercicio = _ejercicio[fecha];
    return Dia(
      fecha: fecha,
      diaSemana: diaSemanaDe(dia),
      planId: _plan.id,
      modo: _plan.modo,
      puedeRegistrar: _puedeRegistrar(dia),
      aguaVasos: _agua[fecha] ?? 0,
      reto21Dia: _diaDelReto(dia),
      tiempos: tiempos,
      faltan: [
        for (final t in tiempos)
          if (t.planeado.isNotEmpty && t.registro == null) t.tiempo,
      ],
      ejercicioMin: ejercicio?.minutos ?? 0,
      ejercicioTipo: ejercicio?.tipo,
      caloriasReloj: ejercicio?.caloriasReloj,
    );
  }

  int? _diaDelReto(DateTime dia) {
    final reto = _paciente.reto21;
    if (reto == null) return null;
    final diasDesdeInicio = diasEntre(parsearFechaIso(reto.fechaInicio)!, dia);
    if (diasDesdeInicio < 0) return null;
    return (diasDesdeInicio + 1).clamp(1, 21);
  }

  Progreso _calcularProgreso(DateTime inicio) {
    final desde = fechaIso(inicio);
    final hasta = fechaIso(_hoy);
    bool enRango(String fecha) =>
        fecha.compareTo(desde) >= 0 && fecha.compareTo(hasta) <= 0;

    final registros = _registros.values.where((r) => enRango(r.fecha)).toList();
    int contar(String estado) =>
        registros.where((r) => r.estado == estado).length;
    final conteo = ConteoEstados(
      cumplido: contar(EstadoComida.cumplido),
      cambio: contar(EstadoComida.cambio),
      omitido: contar(EstadoComida.omitido),
    );
    final fechasConRegistro = registros.map((r) => r.fecha).toSet();
    final aguaEnRango = _agua.entries.where((e) => enRango(e.key)).toList();
    final pesos = _pesos.where((p) => enRango(p.fecha)).toList();

    return Progreso(
      desde: desde,
      hasta: hasta,
      diasPeriodo: diasEntre(inicio, _hoy) + 1,
      diasRegistrados: fechasConRegistro.length,
      conteo: conteo,
      apegoPct: conteo.total == 0
          ? null
          : (conteo.cumplido / conteo.total * 100).round(),
      rachaActual: _calcularRacha(),
      aguaPromedio: aguaEnRango.isEmpty
          ? null
          : _redondear1(
              aguaEnRango.map((e) => e.value).reduce((a, b) => a + b) /
                  aguaEnRango.length,
            ),
      canal: ConteoCanal(
        app: registros.where((r) => r.origen == 'app').length,
        whatsapp: registros.where((r) => r.origen == 'whatsapp').length,
      ),
      peso: ResumenPeso(
        inicial: pesos.isEmpty ? null : pesos.first.peso,
        actual: pesos.isEmpty ? null : pesos.last.peso,
        diferencia: pesos.isEmpty
            ? null
            : _redondear1(pesos.last.peso - pesos.first.peso),
        serie: pesos,
      ),
      sintomasPromedio: _promediarSintomas(desde, hasta),
      dondeSeSale: _calcularDondeSeSale(registros),
      fotos: _listarFotos(registros),
    );
  }

  int _calcularRacha() {
    final fechas = _registros.values.map((r) => r.fecha).toSet();
    var dia = fechas.contains(fechaIso(_hoy)) ? _hoy : sumarDias(_hoy, -1);
    var racha = 0;
    while (fechas.contains(fechaIso(dia))) {
      racha++;
      dia = sumarDias(dia, -1);
    }
    return racha;
  }

  SintomasPromedio _promediarSintomas(String desde, String hasta) {
    final enRango = _sintomas
        .map((s) => s.registro)
        .where(
          (s) =>
              s.fecha!.compareTo(desde) >= 0 && s.fecha!.compareTo(hasta) <= 0,
        );
    double? promedio(String metrica) {
      final valores = enRango
          .map((s) => s.valores[metrica])
          .whereType<int>()
          .toList();
      if (valores.isEmpty) return null;
      return _redondear1(valores.reduce((a, b) => a + b) / valores.length);
    }

    return SintomasPromedio(
      energia: promedio('energia'),
      digestion: promedio('digestion'),
      hambre: promedio('hambre'),
      sueno: promedio('sueno'),
      animo: promedio('animo'),
    );
  }

  List<DondeSeSale> _calcularDondeSeSale(List<RegistroComida> registros) {
    final resultado = <DondeSeSale>[];
    for (final tiempo in kTiempos) {
      final delTiempo = registros.where((r) => r.tiempo == tiempo);
      final cambios = delTiempo.where((r) => r.estado == EstadoComida.cambio);
      final omitidos = delTiempo.where((r) => r.estado == EstadoComida.omitido);
      if (cambios.isEmpty && omitidos.isEmpty) continue;

      final veces = <String, int>{};
      for (final r in cambios) {
        final texto = (r.queComio ?? '').toLowerCase().trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
        if (texto.isNotEmpty) veces[texto] = (veces[texto] ?? 0) + 1;
      }
      final frecuentes = veces.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      resultado.add(
        DondeSeSale(
          tiempo: tiempo,
          cambio: cambios.length,
          omitido: omitidos.length,
          queComioFrecuente: frecuentes
              .take(3)
              .map((e) => TextoFrecuente(texto: e.key, veces: e.value))
              .toList(),
        ),
      );
    }
    resultado.sort(
      (a, b) => (b.cambio + b.omitido).compareTo(a.cambio + a.omitido),
    );
    return resultado;
  }

  List<FotoProgreso> _listarFotos(List<RegistroComida> registros) {
    final conFoto = registros.where((r) => r.fotoId != null).toList()
      ..sort((a, b) {
        final porFecha = b.fecha.compareTo(a.fecha);
        if (porFecha != 0) return porFecha;
        return kTiempos.indexOf(b.tiempo).compareTo(kTiempos.indexOf(a.tiempo));
      });
    return conFoto
        .take(60)
        .map(
          (r) => FotoProgreso(id: r.fotoId!, fecha: r.fecha, tiempo: r.tiempo),
        )
        .toList();
  }

  double _redondear1(double valor) => (valor * 10).round() / 10;

  // --- Datos de ejemplo ------------------------------------------------------

  PacienteApp _crearPaciente() => PacienteApp(
    id: 'pac-demo-1',
    nombre: 'María',
    apellido: 'López Hernández',
    telefono: '9611234567',
    objetivo: 'Bajar de peso y mejorar la digestión',
    tienePlan: true,
    reto21: Reto21(
      activo: true,
      fechaInicio: fechaIso(sumarDias(_hoy, -7)),
      diaActual: 8,
    ),
    clinica: const Clinica(
      nombre: 'Dentu',
      logoUrl: null,
      colorPrimario: '#1e7a4d',
      telefono: '9611234567',
    ),
  );

  Plan _crearPlan(bool modoEquivalentes) {
    const menu = {
      'lunes': [
        'Huevo a la mexicana con 2 tortillas de maíz y ½ taza de frijoles',
        '1 taza de papaya con limón',
        'Pechuga a la plancha, ½ taza de arroz y ensalada verde',
        '10 almendras y 1 pepino',
        'Sopa de verduras con 1 quesadilla de queso panela',
      ],
      'martes': [
        'Avena con leche descremada y plátano',
        '1 manzana',
        'Caldo de pollo con verduras y 2 tortillas',
        '1 yogur natural sin azúcar',
        '2 tostadas horneadas de tinga de pollo con lechuga',
      ],
      'miercoles': [
        'Chilaquiles verdes horneados con pollo deshebrado',
        '1 taza de melón',
        'Pescado a la veracruzana con ½ taza de arroz',
        'Jícama con chile y limón',
        'Molletes integrales con pico de gallo',
      ],
      'jueves': [
        'Omelette de espinaca con 1 tortilla',
        '1 taza de fresas',
        '3 tacos de bistec con nopales asados',
        '1 pera',
        'Ensalada de atún con galletas integrales',
      ],
      'viernes': [
        'Licuado de avena, leche descremada y fresa',
        '1 naranja',
        'Enfrijoladas de pollo con queso fresco',
        '20 cacahuates naturales',
        'Sopa de lentejas',
      ],
      'sabado': [
        'Huevos rancheros con salsa roja',
        '1 taza de sandía',
        'Pozole de pollo con lechuga y rábano',
        'Pepino con chile',
        'Sándwich integral de pechuga de pavo',
      ],
      'domingo': [
        'Hot cakes de avena con fruta picada',
        '1 mandarina',
        'Carne asada con guacamole y frijoles de la olla',
        '1 yogur griego',
        'Cereal integral con leche descremada',
      ],
    };

    ComidasDia comidas(List<String> platillos) => modoEquivalentes
        ? ComidasDia.vacio
        : ComidasDia(
            desayuno: platillos[0],
            colacionAm: platillos[1],
            comida: platillos[2],
            colacionPm: platillos[3],
            cena: platillos[4],
          );

    return Plan(
      id: 'plan-demo-1',
      nombre: 'Semana 1',
      fechaInicio: fechaIso(sumarDias(_hoy, -10)),
      modo: modoEquivalentes ? 'equivalentes' : 'menu',
      notas: 'Toma 2 litros de agua al día. Evita refrescos y jugos.',
      caloriasObjetivo: 2000,
      proteinasG: 100,
      carbohidratosG: 275,
      grasasG: 55,
      equivalentes: const {
        'Verduras': 4,
        'Frutas': 3,
        'Cereales sin grasa': 6,
        'Leguminosas': 1,
        'Origen animal bajo en grasa': 5,
        'Leche descremada': 1,
        'Aceites y grasas': 3.5,
      },
      dias: {for (final dia in kDiasSemana) dia: comidas(menu[dia]!)},
    );
  }

  void _sembrarDatos() {
    const cambios = [
      'unos tacos de guisado',
      'una torta de jamón',
      'galletas',
      'una manzana',
    ];

    void agregar(
      DateTime dia,
      String tiempo,
      String estado, {
      String? queComio,
      String origen = 'app',
      String? fotoId,
    }) {
      final fecha = fechaIso(dia);
      final momento = dia.toUtc();
      _registros[_claveRegistro(fecha, tiempo)] = RegistroComida(
        id: 'reg-${_siguienteId++}',
        fecha: fecha,
        tiempo: tiempo,
        planId: _plan.id,
        planeado: _planeadoPara(dia, tiempo),
        estado: estado,
        queComio: queComio,
        nota: null,
        fotoId: fotoId,
        origen: origen,
        createdAt: momento,
        updatedAt: momento,
      );
    }

    for (var diasAtras = 1; diasAtras <= 6; diasAtras++) {
      if (diasAtras == 4) continue;
      final dia = sumarDias(_hoy, -diasAtras);
      for (var i = 0; i < kTiempos.length; i++) {
        final patron = (diasAtras + i) % 5;
        final estado = switch (patron) {
          3 => EstadoComida.cambio,
          4 => EstadoComida.omitido,
          _ => EstadoComida.cumplido,
        };
        agregar(
          dia,
          kTiempos[i],
          estado,
          queComio: estado == EstadoComida.cambio
              ? cambios[(diasAtras + i) % cambios.length]
              : null,
          origen: (diasAtras + i) % 3 == 0 ? 'whatsapp' : 'app',
          fotoId: i == 0 && diasAtras.isOdd ? 'mock-foto-$diasAtras' : null,
        );
      }
    }

    agregar(_hoy, 'desayuno', EstadoComida.cumplido, fotoId: 'mock-foto-hoy');
    agregar(
      _hoy,
      'colacion_am',
      EstadoComida.cambio,
      queComio: 'una manzana',
      origen: 'whatsapp',
    );

    _agua
      ..[fechaIso(_hoy)] = 5
      ..[fechaIso(sumarDias(_hoy, -1))] = 8
      ..[fechaIso(sumarDias(_hoy, -2))] = 6
      ..[fechaIso(sumarDias(_hoy, -3))] = 7
      ..[fechaIso(sumarDias(_hoy, -5))] = 4;

    _ejercicio
      ..[fechaIso(_hoy)] = (minutos: 20, tipo: 'caminata', caloriasReloj: 115)
      ..[fechaIso(sumarDias(_hoy, -1))] = (
        minutos: 30,
        tipo: 'gym',
        caloriasReloj: 210,
      )
      ..[fechaIso(sumarDias(_hoy, -3))] = (
        minutos: 45,
        tipo: 'bicicleta',
        caloriasReloj: null,
      );

    _pesos.addAll([
      PuntoPeso(
        fecha: fechaIso(sumarDias(_hoy, -13)),
        peso: 85.0,
        origen: 'consulta',
      ),
      PuntoPeso(
        fecha: fechaIso(sumarDias(_hoy, -10)),
        peso: 84.6,
        origen: 'app',
      ),
      PuntoPeso(
        fecha: fechaIso(sumarDias(_hoy, -7)),
        peso: 84.1,
        origen: 'whatsapp',
      ),
      PuntoPeso(
        fecha: fechaIso(sumarDias(_hoy, -3)),
        peso: 83.7,
        origen: 'app',
      ),
      PuntoPeso(
        fecha: fechaIso(sumarDias(_hoy, -1)),
        peso: 83.2,
        origen: 'app',
      ),
    ]);

    _sintomas.addAll([
      (
        registro: RegistroSintomas(
          fecha: fechaIso(sumarDias(_hoy, -6)),
          valores: const {
            'energia': 3,
            'digestion': 2,
            'hambre': 4,
            'sueno': 3,
            'animo': 3,
          },
        ),
        origen: 'whatsapp',
      ),
      (
        registro: RegistroSintomas(
          fecha: fechaIso(sumarDias(_hoy, -2)),
          valores: const {
            'energia': 4,
            'digestion': 3,
            'hambre': 3,
            'sueno': 4,
            'animo': 4,
          },
        ),
        origen: 'app',
      ),
    ]);
  }
}
