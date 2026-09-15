import '../../config/constantes.dart';

double? _aDouble(dynamic valor) => (valor as num?)?.toDouble();

class ComidasDia {
  const ComidasDia({
    required this.desayuno,
    required this.colacionAm,
    required this.comida,
    required this.colacionPm,
    required this.cena,
  });

  static const vacio = ComidasDia(
    desayuno: '',
    colacionAm: '',
    comida: '',
    colacionPm: '',
    cena: '',
  );

  final String desayuno;
  final String colacionAm;
  final String comida;
  final String colacionPm;
  final String cena;

  factory ComidasDia.fromJson(Map<String, dynamic> json) => ComidasDia(
    desayuno: json['desayuno'] as String? ?? '',
    colacionAm: json['colacion_am'] as String? ?? '',
    comida: json['comida'] as String? ?? '',
    colacionPm: json['colacion_pm'] as String? ?? '',
    cena: json['cena'] as String? ?? '',
  );

  String deTiempo(String tiempo) => switch (tiempo) {
    'desayuno' => desayuno,
    'colacion_am' => colacionAm,
    'comida' => comida,
    'colacion_pm' => colacionPm,
    'cena' => cena,
    _ => '',
  };

  bool get estaVacio => kTiempos.every((tiempo) => deTiempo(tiempo).isEmpty);
}

class Plan {
  const Plan({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.modo,
    required this.notas,
    required this.caloriasObjetivo,
    required this.proteinasG,
    required this.carbohidratosG,
    required this.grasasG,
    required this.equivalentes,
    required this.dias,
  });

  final String id;
  final String nombre;
  final String fechaInicio;

  /// `"menu"` o `"equivalentes"`.
  final String modo;
  final String? notas;

  /// kcal/día del plan completo. Metas del día completo, no por comida.
  final double? caloriasObjetivo;
  final double? proteinasG;
  final double? carbohidratosG;
  final double? grasasG;
  final Map<String, double> equivalentes;

  /// Siempre trae los 7 días (`lunes`..`domingo`).
  final Map<String, ComidasDia> dias;

  bool get esEquivalentes => modo == 'equivalentes';

  ComidasDia comidasDe(String diaSemana) => dias[diaSemana] ?? ComidasDia.vacio;

  factory Plan.fromJson(Map<String, dynamic> json) {
    final equivalentes = json['equivalentes'] as Map<String, dynamic>? ?? {};
    final dias = json['dias'] as Map<String, dynamic>? ?? {};
    return Plan(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      fechaInicio: json['fecha_inicio'] as String,
      modo: json['modo'] as String,
      notas: json['notas'] as String?,
      caloriasObjetivo: _aDouble(json['calorias_objetivo']),
      proteinasG: _aDouble(json['proteinas_g']),
      carbohidratosG: _aDouble(json['carbohidratos_g']),
      grasasG: _aDouble(json['grasas_g']),
      equivalentes: equivalentes.map(
        (grupo, cantidad) => MapEntry(grupo, (cantidad as num).toDouble()),
      ),
      dias: {
        for (final dia in kDiasSemana)
          dia: dias[dia] == null
              ? ComidasDia.vacio
              : ComidasDia.fromJson(dias[dia] as Map<String, dynamic>),
      },
    );
  }

  Plan copyWith({Map<String, ComidasDia>? dias}) => Plan(
    id: id,
    nombre: nombre,
    fechaInicio: fechaInicio,
    modo: modo,
    notas: notas,
    caloriasObjetivo: caloriasObjetivo,
    proteinasG: proteinasG,
    carbohidratosG: carbohidratosG,
    grasasG: grasasG,
    equivalentes: equivalentes,
    dias: dias ?? this.dias,
  );
}
