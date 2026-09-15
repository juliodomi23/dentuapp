import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ColoresDentu {
  static const Color verde = Color(0xFF1E7A4D);
  static const Color dorado = Color(0xFFC9A24B);
  static const Color terracota = Color(0xFFD97B5B);
  static const Color pendiente = Color(0xFFB26A00);

  /// Fondo cálido (no blanco puro) para que la app no se sienta clínica.
  static const Color fondoCalido = Color(0xFFFBF6EC);
  static const Color superficieTarjeta = Color(0xFFFFFDF8);
}

ThemeData crearTemaDentu() {
  // No dejamos que Material 3 derive todo del seed (eso da los morados/grises
  // genéricos de "app sin diseño"): fijamos a mano los colores de marca y un
  // tercer acento cálido para comida/energía.
  final esquema = ColorScheme.fromSeed(seedColor: ColoresDentu.verde).copyWith(
    primary: ColoresDentu.verde,
    secondary: ColoresDentu.dorado,
    tertiary: ColoresDentu.terracota,
    surface: ColoresDentu.fondoCalido,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: esquema);
  final textoBase = base.textTheme;

  // Una sola fuente con carácter para títulos y números grandes (racha, reto
  // 21); el cuerpo se queda con la fuente del sistema para no cargar la app.
  TextStyle? conCaracter(TextStyle? estilo) =>
      GoogleFonts.fraunces(textStyle: estilo, fontWeight: FontWeight.w600);

  final textTheme = textoBase.copyWith(
    displayLarge: conCaracter(textoBase.displayLarge),
    displayMedium: conCaracter(textoBase.displayMedium),
    displaySmall: conCaracter(textoBase.displaySmall),
    headlineLarge: conCaracter(textoBase.headlineLarge),
    headlineMedium: conCaracter(textoBase.headlineMedium),
    headlineSmall: conCaracter(textoBase.headlineSmall),
    titleLarge: conCaracter(textoBase.titleLarge),
  );

  const tamanoMinimoBoton = Size(48, 48);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: ColoresDentu.fondoCalido,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: ColoresDentu.fondoCalido,
      foregroundColor: ColoresDentu.verde,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: tamanoMinimoBoton),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: tamanoMinimoBoton),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: tamanoMinimoBoton),
    ),
    cardTheme: CardThemeData(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: ColoresDentu.superficieTarjeta,
      elevation: 1,
      shadowColor: ColoresDentu.verde.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
