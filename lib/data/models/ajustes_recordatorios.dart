import '../../config/constantes.dart';

class HoraDelDia {
  const HoraDelDia(this.hora, this.minuto);

  final int hora;
  final int minuto;

  String get texto =>
      '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

  static HoraDelDia desdeTexto(String texto) {
    final partes = texto.split(':');
    return HoraDelDia(int.parse(partes[0]), int.parse(partes[1]));
  }
}

class AjustesRecordatorios {
  const AjustesRecordatorios({
    required this.comidasActivas,
    required this.horarios,
    required this.aguaActiva,
    required this.aguaCadaHoras,
  });

  static const int aguaDesdeHora = 9;
  static const int aguaHastaHora = 21;
  static const List<int> opcionesAguaCadaHoras = [1, 2, 3];

  static const porDefecto = AjustesRecordatorios(
    comidasActivas: false,
    horarios: {
      'desayuno': HoraDelDia(8, 0),
      'colacion_am': HoraDelDia(11, 0),
      'comida': HoraDelDia(14, 0),
      'colacion_pm': HoraDelDia(17, 30),
      'cena': HoraDelDia(20, 0),
    },
    aguaActiva: false,
    aguaCadaHoras: 2,
  );

  final bool comidasActivas;
  final Map<String, HoraDelDia> horarios;
  final bool aguaActiva;
  final int aguaCadaHoras;

  /// Horas del día en las que suena el recordatorio de agua.
  List<int> get horasAgua => [
    for (
      var hora = aguaDesdeHora;
      hora <= aguaHastaHora;
      hora += aguaCadaHoras
    )
      hora,
  ];

  AjustesRecordatorios copyWith({
    bool? comidasActivas,
    Map<String, HoraDelDia>? horarios,
    bool? aguaActiva,
    int? aguaCadaHoras,
  }) => AjustesRecordatorios(
    comidasActivas: comidasActivas ?? this.comidasActivas,
    horarios: horarios ?? this.horarios,
    aguaActiva: aguaActiva ?? this.aguaActiva,
    aguaCadaHoras: aguaCadaHoras ?? this.aguaCadaHoras,
  );

  Map<String, dynamic> toMap() => {
    'comidas_activas': comidasActivas,
    'horarios': horarios.map((tiempo, hora) => MapEntry(tiempo, hora.texto)),
    'agua_activa': aguaActiva,
    'agua_cada_horas': aguaCadaHoras,
  };

  factory AjustesRecordatorios.fromMap(Map<String, dynamic> map) {
    final guardados = Map<String, dynamic>.from(map['horarios'] as Map? ?? {});
    return AjustesRecordatorios(
      comidasActivas: map['comidas_activas'] as bool? ?? false,
      horarios: {
        for (final tiempo in kTiempos)
          tiempo: guardados[tiempo] == null
              ? porDefecto.horarios[tiempo]!
              : HoraDelDia.desdeTexto(guardados[tiempo] as String),
      },
      aguaActiva: map['agua_activa'] as bool? ?? false,
      aguaCadaHoras: map['agua_cada_horas'] as int? ?? porDefecto.aguaCadaHoras,
    );
  }
}
