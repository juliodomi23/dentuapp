import 'dart:convert';

import 'package:dentu_app/data/models/dia.dart';
import 'package:dentu_app/data/services/api_exception.dart';
import 'package:dentu_app/data/services/api_service.dart';
import 'package:dentu_app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('un 401 avisa para cerrar sesión, excepto al vincular', () async {
    final cliente = MockClient(
      (_) async => http.Response.bytes(
        utf8.encode('{"detail": "Código inválido o vencido"}'),
        401,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    var avisos = 0;
    final api = ApiService(urlVinculacion: 'http://vincular', cliente: cliente)
      ..leerToken = (() => 'token')
      ..alNoAutorizado = (() => avisos++);

    final dia = await api.obtenerDia('2026-09-11');
    final vinculacion = await api.vincular(telefono: '9611234567', codigo: '000000');

    expect((dia as Error<Dia>).error, isA<ApiException>());
    expect((vinculacion as Error).error.toString(), contains('Código inválido o vencido'));
    expect(avisos, 1);
  });

  test('usa la URL y el token de la sesión', () async {
    late http.Request peticion;
    final cliente = MockClient((request) async {
      peticion = request;
      return http.Response('{"fecha": "2026-09-11", "agua_vasos": 6}', 200);
    });
    final api = ApiService(urlVinculacion: 'http://vincular', cliente: cliente)
      ..leerToken = (() => 'abc')
      ..leerBaseUrl = (() => 'https://clinica.ejemplo');

    final resultado = await api.guardarAgua('2026-09-11', 6);

    expect((resultado as Ok<int>).value, 6);
    expect(peticion.url.toString(), 'https://clinica.ejemplo/api/app/dia/2026-09-11/agua');
    expect(peticion.headers['Authorization'], 'Bearer abc');
  });

  test('sin red devuelve un error recuperable', () async {
    final cliente = MockClient((_) async => throw http.ClientException('sin red'));
    final api = ApiService(urlVinculacion: 'http://vincular', cliente: cliente);

    final resultado = await api.guardarAgua('2026-09-11', 6);

    final error = (resultado as Error<int>).error as ApiException;
    expect(error.esSinConexion, isTrue);
    expect(error.esRecuperable, isTrue);
  });
}
