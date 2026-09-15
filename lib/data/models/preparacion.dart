class Preparacion {
  const Preparacion({
    required this.ingredientes,
    required this.pasos,
    this.tiempoMin,
    this.dificultad,
  });

  final List<String> ingredientes;
  final List<String> pasos;
  final int? tiempoMin;
  final String? dificultad;

  factory Preparacion.fromJson(Map<String, dynamic> json) => Preparacion(
    ingredientes: (json['ingredientes'] as List<dynamic>? ?? []).map((i) => i.toString()).toList(),
    pasos: (json['pasos'] as List<dynamic>? ?? []).map((p) => p.toString()).toList(),
    tiempoMin: (json['tiempo_min'] as num?)?.toInt(),
    dificultad: json['dificultad'] as String?,
  );
}
