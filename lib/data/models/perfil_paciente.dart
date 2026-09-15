double? _aDouble(dynamic valor) => (valor as num?)?.toDouble();

List<String> _aListaTextos(dynamic valor) =>
    (valor as List<dynamic>? ?? []).cast<String>();

class UltimaMedicion {
  const UltimaMedicion({
    required this.fecha,
    required this.peso,
    required this.cintura,
    required this.cadera,
    required this.grasaCorporal,
    required this.masaMuscular,
  });

  final String fecha;
  final double? peso;
  final double? cintura;
  final double? cadera;
  final double? grasaCorporal;
  final double? masaMuscular;

  factory UltimaMedicion.fromJson(Map<String, dynamic> json) => UltimaMedicion(
    fecha: json['fecha'] as String,
    peso: _aDouble(json['peso']),
    cintura: _aDouble(json['cintura']),
    cadera: _aDouble(json['cadera']),
    grasaCorporal: _aDouble(json['grasa_corporal']),
    masaMuscular: _aDouble(json['masa_muscular']),
  );
}

/// `GET /api/app/perfil`. Solo lectura.
class PerfilPaciente {
  const PerfilPaciente({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.email,
    required this.fechaNacimiento,
    required this.sexo,
    required this.peso,
    required this.estatura,
    required this.objetivo,
    required this.actividadFisica,
    required this.enfermedadesCronicas,
    required this.alergiasAlimentarias,
    required this.ultimaMedicion,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String? email;
  final String? fechaNacimiento;
  final String? sexo;
  final double? peso;
  final double? estatura;
  final String? objetivo;
  final String? actividadFisica;
  final List<String> enfermedadesCronicas;
  final List<String> alergiasAlimentarias;
  final UltimaMedicion? ultimaMedicion;

  factory PerfilPaciente.fromJson(Map<String, dynamic> json) {
    final medicion = json['ultima_medicion'] as Map<String, dynamic>?;
    return PerfilPaciente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      telefono: json['telefono'] as String,
      email: json['email'] as String?,
      fechaNacimiento: json['fecha_nacimiento'] as String?,
      sexo: json['sexo'] as String?,
      peso: _aDouble(json['peso']),
      estatura: _aDouble(json['estatura']),
      objetivo: json['objetivo'] as String?,
      actividadFisica: json['actividad_fisica'] as String?,
      enfermedadesCronicas: _aListaTextos(json['enfermedades_cronicas']),
      alergiasAlimentarias: _aListaTextos(json['alergias_alimentarias']),
      ultimaMedicion: medicion == null ? null : UltimaMedicion.fromJson(medicion),
    );
  }
}
