class Reto21 {
  const Reto21({
    required this.activo,
    required this.fechaInicio,
    required this.diaActual,
  });

  final bool activo;
  final String fechaInicio;
  final int diaActual;

  factory Reto21.fromJson(Map<String, dynamic> json) => Reto21(
    activo: json['activo'] as bool,
    fechaInicio: json['fecha_inicio'] as String,
    diaActual: (json['dia_actual'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'activo': activo,
    'fecha_inicio': fechaInicio,
    'dia_actual': diaActual,
  };
}

class Clinica {
  const Clinica({
    required this.nombre,
    required this.logoUrl,
    required this.colorPrimario,
    required this.telefono,
  });

  final String nombre;
  final String? logoUrl;
  final String colorPrimario;
  final String? telefono;

  factory Clinica.fromJson(Map<String, dynamic> json) => Clinica(
    nombre: json['nombre'] as String,
    logoUrl: json['logo_url'] as String?,
    colorPrimario: json['color_primario'] as String,
    telefono: json['telefono'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'logo_url': logoUrl,
    'color_primario': colorPrimario,
    'telefono': telefono,
  };
}

class PacienteApp {
  const PacienteApp({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.objetivo,
    required this.tienePlan,
    required this.reto21,
    required this.clinica,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String? objetivo;
  final bool tienePlan;
  final Reto21? reto21;
  final Clinica clinica;

  String get nombreCompleto => '$nombre $apellido'.trim();

  factory PacienteApp.fromJson(Map<String, dynamic> json) {
    final reto = json['reto_21'] as Map<String, dynamic>?;
    return PacienteApp(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      telefono: json['telefono'] as String,
      objetivo: json['objetivo'] as String?,
      tienePlan: json['tiene_plan'] as bool,
      reto21: reto == null ? null : Reto21.fromJson(reto),
      clinica: Clinica.fromJson(json['clinica'] as Map<String, dynamic>),
    );
  }

  /// Se usa para guardar el paciente en la sesión local.
  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'apellido': apellido,
    'telefono': telefono,
    'objetivo': objetivo,
    'tiene_plan': tienePlan,
    'reto_21': reto21?.toJson(),
    'clinica': clinica.toJson(),
  };
}

class ResultadoVinculacion {
  const ResultadoVinculacion({required this.token, required this.paciente});

  final String token;
  final PacienteApp paciente;

  factory ResultadoVinculacion.fromJson(Map<String, dynamic> json) =>
      ResultadoVinculacion(
        token: json['token'] as String,
        paciente: PacienteApp.fromJson(json['paciente'] as Map<String, dynamic>),
      );
}
