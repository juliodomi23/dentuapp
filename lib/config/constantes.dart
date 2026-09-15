import 'package:flutter/material.dart';

const List<String> kTiempos = [
  'desayuno',
  'colacion_am',
  'comida',
  'colacion_pm',
  'cena',
];

const Map<String, String> kNombreTiempo = {
  'desayuno': 'Desayuno',
  'colacion_am': 'Colación AM',
  'comida': 'Comida',
  'colacion_pm': 'Colación PM',
  'cena': 'Cena',
};

const Map<String, IconData> kIconoTiempo = {
  'desayuno': Icons.wb_sunny_rounded,
  'colacion_am': Icons.emoji_food_beverage_rounded,
  'comida': Icons.restaurant_rounded,
  'colacion_pm': Icons.cookie_rounded,
  'cena': Icons.nightlight_rounded,
};

const List<String> kDiasSemana = [
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo',
];

const Map<String, String> kNombreDia = {
  'lunes': 'Lunes',
  'martes': 'Martes',
  'miercoles': 'Miércoles',
  'jueves': 'Jueves',
  'viernes': 'Viernes',
  'sabado': 'Sábado',
  'domingo': 'Domingo',
};

/// Iniciales de 2 letras para el selector compacto de días.
const Map<String, String> kAbreviaturaDia = {
  'lunes': 'Lu',
  'martes': 'Ma',
  'miercoles': 'Mi',
  'jueves': 'Ju',
  'viernes': 'Vi',
  'sabado': 'Sá',
  'domingo': 'Do',
};

class EstadoComida {
  static const String cumplido = 'cumplido';
  static const String cambio = 'cambio';
  static const String omitido = 'omitido';

  static const List<String> todos = [cumplido, cambio, omitido];
}

const Map<String, String> kTextoEstado = {
  EstadoComida.cumplido: 'Lo comí',
  EstadoComida.cambio: 'Lo cambié',
  EstadoComida.omitido: 'No lo comí',
};

const Map<String, IconData> kIconoEstado = {
  EstadoComida.cumplido: Icons.check_circle_rounded,
  EstadoComida.cambio: Icons.edit_rounded,
  EstadoComida.omitido: Icons.cancel_rounded,
};

class LimitesRegistro {
  static const int queComioMax = 300;
  static const int notaMax = 500;
  static const int aguaMax = 30;

  /// Solo para escalar el copy motivacional del contador de agua, no limita
  /// el registro: 8 vasos (~2L) es la referencia común de hidratación diaria.
  static const int aguaMetaVasos = 8;

  static const int reto21TotalDias = 21;
  static const double pesoMin = 20;
  static const double pesoMax = 400;
  static const int ejercicioMinMax = 600;
  static const int ejercicioTipoMax = 60;
  static const int ejercicioPaso = 5;
}

/// Métricas de "¿Cómo te sientes?" (mismas llaves que `POST /app/sintomas`).
const Map<String, String> kNombreSintoma = {
  'energia': 'Energía',
  'digestion': 'Digestión',
  'hambre': 'Hambre',
  'sueno': 'Sueño',
  'animo': 'Ánimo',
};
