import 'registro_comida.dart';

/// Un `PUT comidas`, `PUT agua` o `PUT ejercicio` que no se pudo enviar y espera
/// en la cola offline.
class OperacionPendiente {
  const OperacionPendiente({
    required this.id,
    required this.tipo,
    required this.fecha,
    required this.creadaEn,
    this.tiempo,
    this.estado,
    this.queComio,
    this.nota,
    this.fotoPath,
    this.aguaVasos,
    this.ejercicioMin,
    this.ejercicioTipo,
    this.caloriasReloj,
    this.ultimoError,
  });

  static const String tipoComida = 'comida';
  static const String tipoAgua = 'agua';
  static const String tipoEjercicio = 'ejercicio';

  static int _contador = 0;

  final String id;
  final String tipo;
  final String fecha;
  final DateTime creadaEn;
  final String? tiempo;
  final String? estado;
  final String? queComio;
  final String? nota;

  /// Copia de la foto dentro de la carpeta de la app (no la ruta temporal del picker).
  final String? fotoPath;
  final int? aguaVasos;
  final int? ejercicioMin;
  final String? ejercicioTipo;
  final int? caloriasReloj;

  /// Mensaje del servidor si la rechazó por algo que no es de red (p. ej. fecha fuera de rango).
  final String? ultimoError;

  static String claveComida(String fecha, String tiempo) =>
      'comida|$fecha|$tiempo';

  static String claveAgua(String fecha) => 'agua|$fecha';

  static String claveEjercicio(String fecha) => 'ejercicio|$fecha';

  /// Una sola operación por comida (o por día de agua/ejercicio): la más nueva reemplaza a la anterior.
  String get clave => switch (tipo) {
    tipoComida => claveComida(fecha, tiempo!),
    tipoAgua => claveAgua(fecha),
    _ => claveEjercicio(fecha),
  };

  static String _nuevoId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_contador++}';

  factory OperacionPendiente.comida({
    required String fecha,
    required String tiempo,
    required String estado,
    String? queComio,
    String? nota,
    String? fotoPath,
  }) => OperacionPendiente(
    id: _nuevoId(),
    tipo: tipoComida,
    fecha: fecha,
    creadaEn: DateTime.now(),
    tiempo: tiempo,
    estado: estado,
    queComio: queComio,
    nota: nota,
    fotoPath: fotoPath,
  );

  factory OperacionPendiente.agua({
    required String fecha,
    required int aguaVasos,
  }) => OperacionPendiente(
    id: _nuevoId(),
    tipo: tipoAgua,
    fecha: fecha,
    creadaEn: DateTime.now(),
    aguaVasos: aguaVasos,
  );

  factory OperacionPendiente.ejercicio({
    required String fecha,
    required int ejercicioMin,
    String? ejercicioTipo,
    int? caloriasReloj,
  }) => OperacionPendiente(
    id: _nuevoId(),
    tipo: tipoEjercicio,
    fecha: fecha,
    creadaEn: DateTime.now(),
    ejercicioMin: ejercicioMin,
    ejercicioTipo: ejercicioTipo,
    caloriasReloj: caloriasReloj,
  );

  OperacionPendiente conError(String mensaje) => OperacionPendiente(
    id: id,
    tipo: tipo,
    fecha: fecha,
    creadaEn: creadaEn,
    tiempo: tiempo,
    estado: estado,
    queComio: queComio,
    nota: nota,
    fotoPath: fotoPath,
    aguaVasos: aguaVasos,
    ejercicioMin: ejercicioMin,
    ejercicioTipo: ejercicioTipo,
    caloriasReloj: caloriasReloj,
    ultimoError: mensaje,
  );

  /// Cómo se ve en la UI mientras no se envía.
  RegistroComida comoRegistro({
    required String planeado,
    RegistroComida? registroAnterior,
  }) => RegistroComida(
    id: 'pendiente-$id',
    fecha: fecha,
    tiempo: tiempo!,
    planId: registroAnterior?.planId,
    planeado: planeado,
    estado: estado!,
    queComio: queComio,
    nota: nota,
    fotoId: registroAnterior?.fotoId,
    origen: 'app',
    createdAt: creadaEn,
    updatedAt: creadaEn,
    pendiente: true,
    errorEnvio: ultimoError,
    fotoLocal: fotoPath,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'tipo': tipo,
    'fecha': fecha,
    'creada_en': creadaEn.toIso8601String(),
    'tiempo': tiempo,
    'estado': estado,
    'que_comio': queComio,
    'nota': nota,
    'foto_path': fotoPath,
    'agua_vasos': aguaVasos,
    'ejercicio_min': ejercicioMin,
    'ejercicio_tipo': ejercicioTipo,
    'calorias_reloj': caloriasReloj,
    'ultimo_error': ultimoError,
  };

  factory OperacionPendiente.fromMap(Map<String, dynamic> map) =>
      OperacionPendiente(
        id: map['id'] as String,
        tipo: map['tipo'] as String,
        fecha: map['fecha'] as String,
        creadaEn: DateTime.parse(map['creada_en'] as String),
        tiempo: map['tiempo'] as String?,
        estado: map['estado'] as String?,
        queComio: map['que_comio'] as String?,
        nota: map['nota'] as String?,
        fotoPath: map['foto_path'] as String?,
        aguaVasos: map['agua_vasos'] as int?,
        ejercicioMin: map['ejercicio_min'] as int?,
        ejercicioTipo: map['ejercicio_tipo'] as String?,
        caloriasReloj: map['calorias_reloj'] as int?,
        ultimoError: map['ultimo_error'] as String?,
      );
}
