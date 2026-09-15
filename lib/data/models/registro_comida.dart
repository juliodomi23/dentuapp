class RegistroComida {
  const RegistroComida({
    required this.id,
    required this.fecha,
    required this.tiempo,
    required this.planId,
    required this.planeado,
    required this.estado,
    required this.queComio,
    required this.nota,
    required this.fotoId,
    required this.origen,
    required this.createdAt,
    required this.updatedAt,
    this.pendiente = false,
    this.errorEnvio,
    this.fotoLocal,
  });

  final String id;
  final String fecha;
  final String tiempo;
  final String? planId;
  final String planeado;
  final String estado;
  final String? queComio;
  final String? nota;
  final String? fotoId;

  /// `"app"` o `"whatsapp"`.
  final String origen;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos locales (no vienen del backend): registros que siguen en la cola offline.
  final bool pendiente;
  final String? errorEnvio;
  final String? fotoLocal;

  bool get tieneFoto => fotoId != null || fotoLocal != null;

  factory RegistroComida.fromJson(Map<String, dynamic> json) => RegistroComida(
    id: json['id'] as String,
    fecha: json['fecha'] as String,
    tiempo: json['tiempo'] as String,
    planId: json['plan_id'] as String?,
    planeado: json['planeado'] as String? ?? '',
    estado: json['estado'] as String,
    queComio: json['que_comio'] as String?,
    nota: json['nota'] as String?,
    fotoId: json['foto_id'] as String?,
    origen: json['origen'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
