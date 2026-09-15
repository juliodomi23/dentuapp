import '../../data/repositories/recordatorios_repository.dart';
import '../../data/services/api_exception.dart';

/// Texto que ve el paciente para un error.
String mensajeDeError(Exception error) => switch (error) {
  ApiException(:final mensaje) => mensaje,
  PermisoDenegadoException(:final mensaje) => mensaje,
  _ => 'Ocurrió un error. Intenta de nuevo.',
};
