import 'registro_comida.dart';

class TiempoDia {
  const TiempoDia({
    required this.tiempo,
    required this.planeado,
    required this.registro,
  });

  final String tiempo;
  final String planeado;
  final RegistroComida? registro;

  factory TiempoDia.fromJson(Map<String, dynamic> json) {
    final registro = json['registro'] as Map<String, dynamic>?;
    return TiempoDia(
      tiempo: json['tiempo'] as String,
      planeado: json['planeado'] as String? ?? '',
      registro: registro == null ? null : RegistroComida.fromJson(registro),
    );
  }

  TiempoDia conRegistro(RegistroComida? registro) =>
      TiempoDia(tiempo: tiempo, planeado: planeado, registro: registro);
}

class Dia {
  const Dia({
    required this.fecha,
    required this.diaSemana,
    required this.planId,
    required this.modo,
    required this.puedeRegistrar,
    required this.aguaVasos,
    required this.reto21Dia,
    required this.tiempos,
    required this.faltan,
    this.aguaPendiente = false,
    this.ejercicioMin = 0,
    this.ejercicioTipo,
    this.caloriasReloj,
    this.ejercicioPendiente = false,
  });

  final String fecha;
  final String diaSemana;
  final String? planId;

  /// `"menu"`, `"equivalentes"` o null si no hay plan.
  final String? modo;
  final bool puedeRegistrar;
  final int aguaVasos;
  final int? reto21Dia;

  /// Siempre 5, en el orden de `kTiempos`.
  final List<TiempoDia> tiempos;
  final List<String> faltan;

  /// Local: el vaso de agua sigue en la cola offline.
  final bool aguaPendiente;

  final int ejercicioMin;

  /// Texto libre ("caminata", "gym"), null si no hay registro.
  final String? ejercicioTipo;
  final int? caloriasReloj;

  /// Local: el registro de ejercicio sigue en la cola offline.
  final bool ejercicioPendiente;

  bool get tienePlan => planId != null;

  bool get esEquivalentes => modo == 'equivalentes';

  factory Dia.fromJson(Map<String, dynamic> json) => Dia(
    fecha: json['fecha'] as String,
    diaSemana: json['dia_semana'] as String,
    planId: json['plan_id'] as String?,
    modo: json['modo'] as String?,
    puedeRegistrar: json['puede_registrar'] as bool,
    aguaVasos: (json['agua_vasos'] as num? ?? 0).toInt(),
    reto21Dia: (json['reto_21_dia'] as num?)?.toInt(),
    tiempos: (json['tiempos'] as List<dynamic>)
        .map((t) => TiempoDia.fromJson(t as Map<String, dynamic>))
        .toList(),
    faltan: (json['faltan'] as List<dynamic>? ?? []).cast<String>(),
    ejercicioMin: (json['ejercicio_min'] as num? ?? 0).toInt(),
    ejercicioTipo: json['ejercicio_tipo'] as String?,
    caloriasReloj: (json['calorias_reloj'] as num?)?.toInt(),
  );

  Dia copyWith({
    List<TiempoDia>? tiempos,
    List<String>? faltan,
    int? aguaVasos,
    bool? aguaPendiente,
    int? ejercicioMin,
    String? ejercicioTipo,
    int? caloriasReloj,
    bool? ejercicioPendiente,
    bool borrarEjercicioTipo = false,
    bool borrarCaloriasReloj = false,
  }) => Dia(
    fecha: fecha,
    diaSemana: diaSemana,
    planId: planId,
    modo: modo,
    puedeRegistrar: puedeRegistrar,
    aguaVasos: aguaVasos ?? this.aguaVasos,
    reto21Dia: reto21Dia,
    tiempos: tiempos ?? this.tiempos,
    faltan: faltan ?? this.faltan,
    aguaPendiente: aguaPendiente ?? this.aguaPendiente,
    ejercicioMin: ejercicioMin ?? this.ejercicioMin,
    ejercicioTipo: borrarEjercicioTipo
        ? null
        : (ejercicioTipo ?? this.ejercicioTipo),
    caloriasReloj: borrarCaloriasReloj
        ? null
        : (caloriasReloj ?? this.caloriasReloj),
    ejercicioPendiente: ejercicioPendiente ?? this.ejercicioPendiente,
  );
}
