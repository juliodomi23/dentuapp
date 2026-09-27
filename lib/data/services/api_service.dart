import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
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

/// Cliente HTTP de `/api/app/*`. No guarda estado: el token, la URL de la
/// sesión y qué hacer ante un 401 se los da `AuthRepository`.
class ApiService {
  ApiService({
    required this.urlVinculacion,
    http.Client? cliente,
    Duration timeout = AppConfig.timeoutApi,
  }) : _cliente = cliente ?? http.Client(),
       _timeout = timeout;

  /// URL que se usa para vincular (la del `--dart-define=API_URL`).
  final String urlVinculacion;
  final http.Client _cliente;
  final Duration _timeout;

  String? Function()? leerToken;
  String? Function()? leerBaseUrl;
  void Function()? alNoAutorizado;

  Future<Result<ResultadoVinculacion>> vincular({
    required String telefono,
    required String codigo,
  }) {
    return _enviar(
      () => _cliente.post(
        Uri.parse('$urlVinculacion/api/app/auth/vincular'),
        headers: _cabeceras(),
        body: jsonEncode({'telefono': telefono, 'codigo': codigo}),
      ),
      (json) => ResultadoVinculacion.fromJson(json as Map<String, dynamic>),
      avisarNoAutorizado: false,
    );
  }

  Future<Result<ResultadoVinculacion>> crearCuentaPersonal({
    required String nombre,
    required String email,
    required String password,
  }) => _enviar(
    () => _cliente.post(
      Uri.parse('$urlVinculacion/api/app/auth/personal/registro'),
      headers: _cabeceras(),
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'password': password,
      }),
    ),
    (json) => ResultadoVinculacion.fromJson(json as Map<String, dynamic>),
    avisarNoAutorizado: false,
  );

  Future<Result<ResultadoVinculacion>> iniciarCuentaPersonal({
    required String email,
    required String password,
  }) => _enviar(
    () => _cliente.post(
      Uri.parse('$urlVinculacion/api/app/auth/personal/login'),
      headers: _cabeceras(),
      body: jsonEncode({'email': email, 'password': password}),
    ),
    (json) => ResultadoVinculacion.fromJson(json as Map<String, dynamic>),
    avisarNoAutorizado: false,
  );

  Future<Result<Map<String, dynamic>>> extraerDieta(List<String> rutas) =>
      _enviar(
        () async {
          final peticion = http.MultipartRequest(
            'POST',
            _uri('/api/app/plan/personal/extraer'),
          )..headers.addAll(_cabeceras(esJson: false));
          for (final ruta in rutas) {
            peticion.files.add(
              await http.MultipartFile.fromPath('archivos', ruta),
            );
          }
          return http.Response.fromStream(await _cliente.send(peticion));
        },
        (json) => json as Map<String, dynamic>,
        timeout: const Duration(seconds: 100),
      );

  Future<Result<Plan>> guardarDietaPersonal(Map<String, dynamic> borrador) =>
      _enviar(
        () => _cliente.put(
          _uri('/api/app/plan/personal'),
          headers: _cabeceras(),
          body: jsonEncode(borrador),
        ),
        (json) => Plan.fromJson(
          (json as Map<String, dynamic>)['plan'] as Map<String, dynamic>,
        ),
      );

  Future<Result<Map<String, dynamic>>> consultarIap() => _enviar(
    () => _cliente.get(_uri('/api/app/iap/estado'), headers: _cabeceras()),
    (json) => json as Map<String, dynamic>,
  );

  Future<Result<Map<String, dynamic>>> validarCompraApple(String recibo) =>
      _enviar(
        () => _cliente.post(
          _uri('/api/app/iap/apple/validar'),
          headers: _cabeceras(),
          body: jsonEncode({'recibo': recibo}),
        ),
        (json) => json as Map<String, dynamic>,
        timeout: const Duration(seconds: 40),
      );

  Future<Result<PacienteApp>> obtenerPerfil() {
    return _enviar(
      () => _cliente.get(_uri('/api/app/me'), headers: _cabeceras()),
      (json) => PacienteApp.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<PerfilPaciente>> obtenerPerfilPaciente() {
    return _enviar(
      () => _cliente.get(_uri('/api/app/perfil'), headers: _cabeceras()),
      (json) => PerfilPaciente.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<Plan?>> obtenerPlanSemana() {
    return _enviar(
      () => _cliente.get(_uri('/api/app/plan/semana'), headers: _cabeceras()),
      (json) {
        final plan = (json as Map<String, dynamic>)['plan'];
        return plan == null
            ? null
            : Plan.fromJson(plan as Map<String, dynamic>);
      },
    );
  }

  /// El backend arma el plan_id y los platillos desde la sesión del paciente
  /// y llama a n8n server-side: la API key de ese webhook nunca viaja en la app.
  Future<Result<ListaCompra>> obtenerListaCompra() {
    return _enviar(
      () => _cliente.get(_uri('/api/app/lista-compra'), headers: _cabeceras()),
      (json) => ListaCompra.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Cacheado en n8n por el texto del platillo (no por paciente), así que
  /// suele responder al instante salvo la primera vez que se pide ese platillo.
  Future<Result<Preparacion>> obtenerPreparacion(String platillo) {
    final ruta =
        '/api/app/preparacion?platillo=${Uri.encodeQueryComponent(platillo)}';
    return _enviar(
      () => _cliente.get(_uri(ruta), headers: _cabeceras()),
      (json) => Preparacion.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<Dia>> obtenerDia(String fecha) {
    return _enviar(
      () => _cliente.get(_uri('/api/app/dia/$fecha'), headers: _cabeceras()),
      (json) => Dia.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<RegistroComida>> guardarComida({
    required String fecha,
    required String tiempo,
    required String estado,
    String? queComio,
    String? nota,
    String? fotoPath,
  }) {
    return _enviar(() async {
      final peticion =
          http.MultipartRequest('PUT', _uri('/api/app/comidas/$fecha/$tiempo'))
            ..headers.addAll(_cabeceras(esJson: false))
            ..fields['estado'] = estado;
      if (queComio != null && queComio.isNotEmpty) {
        peticion.fields['que_comio'] = queComio;
      }
      if (nota != null && nota.isNotEmpty) {
        peticion.fields['nota'] = nota;
      }
      if (fotoPath != null) {
        peticion.files.add(await http.MultipartFile.fromPath('foto', fotoPath));
      }
      return http.Response.fromStream(await _cliente.send(peticion));
    }, (json) => RegistroComida.fromJson(json as Map<String, dynamic>));
  }

  Future<Result<void>> borrarComida(String fecha, String tiempo) {
    return _enviar(
      () => _cliente.delete(
        _uri('/api/app/comidas/$fecha/$tiempo'),
        headers: _cabeceras(),
      ),
      (_) {},
    );
  }

  Future<Result<int>> guardarAgua(String fecha, int vasos) {
    return _enviar(
      () => _cliente.put(
        _uri('/api/app/dia/$fecha/agua'),
        headers: _cabeceras(),
        body: jsonEncode({'agua_vasos': vasos}),
      ),
      (json) => ((json as Map<String, dynamic>)['agua_vasos'] as num).toInt(),
    );
  }

  Future<Result<({int minutos, String? tipo, int? caloriasReloj})>>
  guardarEjercicio({
    required String fecha,
    required int minutos,
    String? tipo,
    int? caloriasReloj,
  }) {
    return _enviar(
      () => _cliente.put(
        _uri('/api/app/dia/$fecha/ejercicio'),
        headers: _cabeceras(),
        body: jsonEncode({
          'ejercicio_min': minutos,
          'ejercicio_tipo': tipo,
          'calorias_reloj': caloriasReloj,
        }),
      ),
      (json) {
        final cuerpo = json as Map<String, dynamic>;
        return (
          minutos: (cuerpo['ejercicio_min'] as num).toInt(),
          tipo: cuerpo['ejercicio_tipo'] as String?,
          caloriasReloj: (cuerpo['calorias_reloj'] as num?)?.toInt(),
        );
      },
    );
  }

  Future<Result<Plan>> intercambiarDias({
    required String diaOrigen,
    required String diaDestino,
  }) {
    return _enviar(
      () => _cliente.put(
        _uri('/api/app/plan/intercambiar'),
        headers: _cabeceras(),
        body: jsonEncode({'dia_origen': diaOrigen, 'dia_destino': diaDestino}),
      ),
      (json) => Plan.fromJson(
        (json as Map<String, dynamic>)['plan'] as Map<String, dynamic>,
      ),
    );
  }

  Future<Result<void>> registrarPeso(double peso, {String? fecha}) {
    return _enviar(
      () => _cliente.post(
        _uri('/api/app/peso'),
        headers: _cabeceras(),
        body: jsonEncode({'peso': peso, 'fecha': ?fecha}),
      ),
      (_) {},
    );
  }

  Future<Result<void>> registrarSintomas(RegistroSintomas sintomas) {
    return _enviar(
      () => _cliente.post(
        _uri('/api/app/sintomas'),
        headers: _cabeceras(),
        body: jsonEncode(sintomas.toJson()),
      ),
      (_) {},
    );
  }

  Future<Result<Progreso>> obtenerProgreso({String? desde}) {
    final uri = _uri(
      '/api/app/progreso',
    ).replace(queryParameters: desde == null ? null : {'desde': desde});
    return _enviar(
      () => _cliente.get(uri, headers: _cabeceras()),
      (json) => Progreso.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<void>> borrarCuenta() {
    return _enviar(
      () => _cliente.delete(_uri('/api/app/cuenta'), headers: _cabeceras()),
      (_) {},
    );
  }

  String urlFoto(String fotoId) => _uri('/api/app/fotos/$fotoId').toString();

  Map<String, String> cabecerasFoto() {
    final token = leerToken?.call();
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  Uri _uri(String ruta) =>
      Uri.parse('${leerBaseUrl?.call() ?? urlVinculacion}$ruta');

  Map<String, String> _cabeceras({bool esJson = true}) {
    final token = leerToken?.call();
    return {
      'Accept': 'application/json',
      if (esJson) 'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Result<T>> _enviar<T>(
    Future<http.Response> Function() peticion,
    T Function(dynamic json) convertir, {
    bool avisarNoAutorizado = true,
    Duration? timeout,
  }) async {
    try {
      final respuesta = await peticion().timeout(timeout ?? _timeout);
      final codigo = respuesta.statusCode;

      if (codigo == 401 && avisarNoAutorizado) alNoAutorizado?.call();

      if (codigo < 200 || codigo >= 300) {
        return Result.error(ApiException(codigo, _mensajeDeError(respuesta)));
      }

      final texto = utf8.decode(respuesta.bodyBytes);
      return Result.ok(convertir(texto.isEmpty ? null : jsonDecode(texto)));
    } on TimeoutException {
      return Result.error(ApiException.sinConexion());
    } on SocketException {
      return Result.error(ApiException.sinConexion());
    } on http.ClientException {
      return Result.error(ApiException.sinConexion());
    } on FileSystemException {
      return const Result.error(
        ApiException(ApiException.codigoLocal, 'No se encontró la foto.'),
      );
    } on FormatException {
      return Result.error(_respuestaInesperada);
    } on TypeError {
      return Result.error(_respuestaInesperada);
    }
  }

  static const _respuestaInesperada = ApiException(
    ApiException.codigoLocal,
    'El servidor respondió algo inesperado.',
  );

  String _mensajeDeError(http.Response respuesta) {
    try {
      final cuerpo = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (cuerpo is Map && cuerpo['detail'] is String) {
        return cuerpo['detail'] as String;
      }
    } on FormatException {
      // Sin JSON: se usa el mensaje genérico por código.
    }
    return switch (respuesta.statusCode) {
      400 || 422 => 'Revisa los datos e intenta de nuevo.',
      401 => 'Tu sesión terminó. Vuelve a iniciar sesión.',
      404 => 'No se encontró la información.',
      413 => 'La foto pesa más de 5 MB.',
      415 => 'Ese formato de foto no se puede subir.',
      429 => 'Demasiados intentos. Espera un momento.',
      >= 500 => 'El servidor no está disponible. Intenta más tarde.',
      _ => 'Ocurrió un error (${respuesta.statusCode}).',
    };
  }
}
