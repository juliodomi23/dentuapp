/// Cuerpo de `POST /api/app/sintomas`. Todas las métricas son opcionales (1..5).
class RegistroSintomas {
  const RegistroSintomas({required this.valores, this.fecha, this.notas});

  /// Llaves: `energia`, `digestion`, `hambre`, `sueno`, `animo`.
  final Map<String, int> valores;
  final String? fecha;
  final String? notas;

  Map<String, dynamic> toJson() => {
    if (fecha != null) 'fecha': fecha,
    ...valores,
    if (notas != null && notas!.trim().isNotEmpty) 'notas': notas!.trim(),
  };
}
