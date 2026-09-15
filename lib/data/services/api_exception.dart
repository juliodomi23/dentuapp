class ApiException implements Exception {
  const ApiException(this.codigo, this.mensaje);

  /// No hubo respuesta: sin internet, timeout o el servidor no contestó.
  static const int codigoSinConexion = 0;

  /// Falló algo en el teléfono (p. ej. no se encontró la foto) o la respuesta no se pudo leer.
  static const int codigoLocal = -1;

  factory ApiException.sinConexion() => const ApiException(
    codigoSinConexion,
    'Sin conexión. Revisa tu internet e intenta de nuevo.',
  );

  final int codigo;
  final String mensaje;

  bool get esSinConexion => codigo == codigoSinConexion;

  /// Vale la pena reintentar más tarde (red o servidor caído).
  bool get esRecuperable => esSinConexion || codigo >= 500;

  bool get esNoAutorizado => codigo == 401;

  bool get esNoEncontrado => codigo == 404;

  @override
  String toString() => 'ApiException($codigo): $mensaje';
}
