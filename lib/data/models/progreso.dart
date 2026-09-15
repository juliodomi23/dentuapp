double? _aDouble(dynamic valor) => (valor as num?)?.toDouble();

int _aInt(dynamic valor) => (valor as num? ?? 0).toInt();

class ConteoEstados {
  const ConteoEstados({
    required this.cumplido,
    required this.cambio,
    required this.omitido,
  });

  final int cumplido;
  final int cambio;
  final int omitido;

  int get total => cumplido + cambio + omitido;

  factory ConteoEstados.fromJson(Map<String, dynamic> json) => ConteoEstados(
    cumplido: _aInt(json['cumplido']),
    cambio: _aInt(json['cambio']),
    omitido: _aInt(json['omitido']),
  );
}

class ConteoCanal {
  const ConteoCanal({required this.app, required this.whatsapp});

  final int app;
  final int whatsapp;

  factory ConteoCanal.fromJson(Map<String, dynamic> json) =>
      ConteoCanal(app: _aInt(json['app']), whatsapp: _aInt(json['whatsapp']));
}

class PuntoPeso {
  const PuntoPeso({
    required this.fecha,
    required this.peso,
    required this.origen,
  });

  final String fecha;
  final double peso;

  /// `"consulta"`, `"app"` o `"whatsapp"`.
  final String origen;

  factory PuntoPeso.fromJson(Map<String, dynamic> json) => PuntoPeso(
    fecha: json['fecha'] as String,
    peso: (json['peso'] as num).toDouble(),
    origen: json['origen'] as String? ?? 'consulta',
  );
}

class ResumenPeso {
  const ResumenPeso({
    required this.inicial,
    required this.actual,
    required this.diferencia,
    required this.serie,
  });

  final double? inicial;
  final double? actual;
  final double? diferencia;
  final List<PuntoPeso> serie;

  factory ResumenPeso.fromJson(Map<String, dynamic> json) => ResumenPeso(
    inicial: _aDouble(json['inicial']),
    actual: _aDouble(json['actual']),
    diferencia: _aDouble(json['diferencia']),
    serie: (json['serie'] as List<dynamic>? ?? [])
        .map((p) => PuntoPeso.fromJson(p as Map<String, dynamic>))
        .toList(),
  );
}

class SintomasPromedio {
  const SintomasPromedio({
    required this.energia,
    required this.digestion,
    required this.hambre,
    required this.sueno,
    required this.animo,
  });

  final double? energia;
  final double? digestion;
  final double? hambre;
  final double? sueno;
  final double? animo;

  /// En el orden de `kNombreSintoma`.
  Map<String, double?> get comoMapa => {
    'energia': energia,
    'digestion': digestion,
    'hambre': hambre,
    'sueno': sueno,
    'animo': animo,
  };

  factory SintomasPromedio.fromJson(Map<String, dynamic> json) =>
      SintomasPromedio(
        energia: _aDouble(json['energia']),
        digestion: _aDouble(json['digestion']),
        hambre: _aDouble(json['hambre']),
        sueno: _aDouble(json['sueno']),
        animo: _aDouble(json['animo']),
      );
}

class TextoFrecuente {
  const TextoFrecuente({required this.texto, required this.veces});

  final String texto;
  final int veces;

  factory TextoFrecuente.fromJson(Map<String, dynamic> json) => TextoFrecuente(
    texto: json['texto'] as String,
    veces: _aInt(json['veces']),
  );
}

class DondeSeSale {
  const DondeSeSale({
    required this.tiempo,
    required this.cambio,
    required this.omitido,
    required this.queComioFrecuente,
  });

  final String tiempo;
  final int cambio;
  final int omitido;
  final List<TextoFrecuente> queComioFrecuente;

  factory DondeSeSale.fromJson(Map<String, dynamic> json) => DondeSeSale(
    tiempo: json['tiempo'] as String,
    cambio: _aInt(json['cambio']),
    omitido: _aInt(json['omitido']),
    queComioFrecuente: (json['que_comio_frecuente'] as List<dynamic>? ?? [])
        .map((t) => TextoFrecuente.fromJson(t as Map<String, dynamic>))
        .toList(),
  );
}

class FotoProgreso {
  const FotoProgreso({
    required this.id,
    required this.fecha,
    required this.tiempo,
  });

  final String id;
  final String fecha;
  final String tiempo;

  factory FotoProgreso.fromJson(Map<String, dynamic> json) => FotoProgreso(
    id: json['id'] as String,
    fecha: json['fecha'] as String,
    tiempo: json['tiempo'] as String,
  );
}

class Progreso {
  const Progreso({
    required this.desde,
    required this.hasta,
    required this.diasPeriodo,
    required this.diasRegistrados,
    required this.conteo,
    required this.apegoPct,
    required this.rachaActual,
    required this.aguaPromedio,
    required this.canal,
    required this.peso,
    required this.sintomasPromedio,
    required this.dondeSeSale,
    required this.fotos,
  });

  final String desde;
  final String hasta;
  final int diasPeriodo;
  final int diasRegistrados;
  final ConteoEstados conteo;
  final int? apegoPct;
  final int rachaActual;
  final double? aguaPromedio;
  final ConteoCanal canal;
  final ResumenPeso peso;
  final SintomasPromedio sintomasPromedio;
  final List<DondeSeSale> dondeSeSale;
  final List<FotoProgreso> fotos;

  factory Progreso.fromJson(Map<String, dynamic> json) => Progreso(
    desde: json['desde'] as String,
    hasta: json['hasta'] as String,
    diasPeriodo: _aInt(json['dias_periodo']),
    diasRegistrados: _aInt(json['dias_registrados']),
    conteo: ConteoEstados.fromJson(json['conteo'] as Map<String, dynamic>),
    apegoPct: (json['apego_pct'] as num?)?.round(),
    rachaActual: _aInt(json['racha_actual']),
    aguaPromedio: _aDouble(json['agua_promedio']),
    canal: ConteoCanal.fromJson(json['canal'] as Map<String, dynamic>),
    peso: ResumenPeso.fromJson(json['peso'] as Map<String, dynamic>),
    sintomasPromedio: SintomasPromedio.fromJson(
      json['sintomas_promedio'] as Map<String, dynamic>,
    ),
    dondeSeSale: (json['donde_se_sale'] as List<dynamic>? ?? [])
        .map((d) => DondeSeSale.fromJson(d as Map<String, dynamic>))
        .toList(),
    fotos: (json['fotos'] as List<dynamic>? ?? [])
        .map((f) => FotoProgreso.fromJson(f as Map<String, dynamic>))
        .toList(),
  );
}
