/// Valores que se definen al compilar con `--dart-define`.
class AppConfig {
  /// Nombre visible de la app. La marca final está pendiente: renombrar aquí
  /// (y el label de Android / display name de iOS).
  static const String nombreApp = 'Dentu';

  /// Solo se usa para vincular. Después, la app usa la URL guardada en la sesión.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://landing-clinicalgestorv3.y394ci.easypanel.host',
  );

  static const bool usarMock = bool.fromEnvironment('USE_MOCK');

  /// En modo mock, muestra el plan en modo "equivalentes" en lugar de menú.
  static const bool mockEquivalentes = bool.fromEnvironment('MOCK_EQUIVALENTES');

  static const Duration timeoutApi = Duration(seconds: 30);

  static const String zonaHorariaClinica = 'America/Mexico_City';

  static const int diasAtrasParaRegistrar = 7;
}
