import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../utils/result.dart';

/// Almacenamiento cifrado (Keystore en Android, Keychain en iOS) para la sesión.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? almacenamiento})
    : _almacenamiento =
          almacenamiento ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _almacenamiento;

  Future<Result<String?>> leer(String clave) async {
    try {
      return Result.ok(await _almacenamiento.read(key: clave));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> escribir(String clave, String valor) async {
    try {
      await _almacenamiento.write(key: clave, value: valor);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> borrar(String clave) async {
    try {
      await _almacenamiento.delete(key: clave);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
