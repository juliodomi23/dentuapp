import 'package:dentu_app/config/constantes.dart';
import 'package:dentu_app/data/models/dia.dart';
import 'package:dentu_app/data/models/paciente_app.dart';
import 'package:dentu_app/data/models/perfil_paciente.dart';
import 'package:dentu_app/data/models/plan.dart';
import 'package:dentu_app/data/models/progreso.dart';
import 'package:dentu_app/data/models/registro_comida.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> registroJson({String? queComio, String? fotoId, String? planId}) => {
  'id': 'reg-1',
  'fecha': '2026-09-11',
  'tiempo': 'comida',
  'plan_id': planId,
  'planeado': 'Pechuga a la plancha',
  'estado': queComio == null ? 'cumplido' : 'cambio',
  'que_comio': queComio,
  'nota': null,
  'foto_id': fotoId,
  'origen': 'whatsapp',
  'created_at': '2026-09-11T14:05:00Z',
  'updated_at': '2026-09-11T14:06:00Z',
};

void main() {
  group('PacienteApp', () {
    test('con reto 21 y clínica completa', () {
      final paciente = PacienteApp.fromJson({
        'id': 'p1',
        'nombre': 'María',
        'apellido': 'López',
        'telefono': '9611234567',
        'objetivo': 'Bajar de peso',
        'tiene_plan': true,
        'reto_21': {'activo': true, 'fecha_inicio': '2026-09-04', 'dia_actual': 8},
        'clinica': {
          'nombre': 'Dentu',
          'logo_url': 'https://ejemplo.com/logo.png',
          'color_primario': '#1e7a4d',
          'telefono': '9610000000',
        },
      });

      expect(paciente.nombreCompleto, 'María López');
      expect(paciente.reto21!.diaActual, 8);
      expect(paciente.clinica.logoUrl, 'https://ejemplo.com/logo.png');
    });

    test('con nulos y se puede volver a guardar como JSON', () {
      final json = {
        'id': 'p1',
        'nombre': 'Juan',
        'apellido': 'Pérez',
        'telefono': '9611234567',
        'objetivo': null,
        'tiene_plan': false,
        'reto_21': null,
        'clinica': {
          'nombre': 'Dentu',
          'logo_url': null,
          'color_primario': '#1e7a4d',
          'telefono': null,
        },
      };

      final paciente = PacienteApp.fromJson(json);
      expect(paciente.objetivo, isNull);
      expect(paciente.reto21, isNull);
      expect(paciente.clinica.telefono, isNull);
      expect(PacienteApp.fromJson(paciente.toJson()).clinica.nombre, 'Dentu');
    });
  });

  group('PerfilPaciente', () {
    test('completo', () {
      final perfil = PerfilPaciente.fromJson({
        'id': 'p1',
        'nombre': 'María',
        'apellido': 'López',
        'telefono': '9611234567',
        'email': 'maria@ejemplo.com',
        'fecha_nacimiento': '1990-03-14',
        'sexo': 'femenino',
        'peso': 83,
        'estatura': 162.5,
        'objetivo': 'Bajar de peso',
        'actividad_fisica': 'Camina',
        'enfermedades_cronicas': ['Gastritis'],
        'alergias_alimentarias': ['Nuez', 'Mariscos'],
        'ultima_medicion': {
          'fecha': '2026-08-29',
          'peso': 85,
          'cintura': 92.5,
          'cadera': null,
          'grasa_corporal': 34.5,
          'masa_muscular': null,
        },
      });

      expect(perfil.peso, 83.0);
      expect(perfil.alergiasAlimentarias, ['Nuez', 'Mariscos']);
      expect(perfil.ultimaMedicion!.cintura, 92.5);
      expect(perfil.ultimaMedicion!.cadera, isNull);
    });

    test('con nulos y listas vacías', () {
      final perfil = PerfilPaciente.fromJson({
        'id': 'p1',
        'nombre': 'Juan',
        'apellido': 'Pérez',
        'telefono': '9611234567',
        'email': null,
        'fecha_nacimiento': null,
        'sexo': null,
        'peso': null,
        'estatura': null,
        'objetivo': null,
        'actividad_fisica': null,
        'enfermedades_cronicas': <String>[],
        'alergias_alimentarias': <String>[],
        'ultima_medicion': null,
      });

      expect(perfil.email, isNull);
      expect(perfil.enfermedadesCronicas, isEmpty);
      expect(perfil.ultimaMedicion, isNull);
    });
  });

  test('Plan: 7 días, equivalentes enteros y decimales, notas nulas', () {
    final plan = Plan.fromJson({
      'id': 'plan-1',
      'nombre': 'Semana 1',
      'fecha_inicio': '2026-09-01',
      'modo': 'equivalentes',
      'notas': null,
      'equivalentes': {'Verduras': 4, 'Aceites y grasas': 3.5},
      'dias': {
        for (final dia in kDiasSemana)
          dia: {'desayuno': '', 'colacion_am': '', 'comida': '', 'colacion_pm': '', 'cena': ''},
      },
    });

    expect(plan.esEquivalentes, isTrue);
    expect(plan.notas, isNull);
    expect(plan.caloriasObjetivo, isNull);
    expect(plan.equivalentes['Verduras'], 4.0);
    expect(plan.equivalentes['Aceites y grasas'], 3.5);
    expect(plan.dias.keys, kDiasSemana);
    expect(plan.comidasDe('lunes').estaVacio, isTrue);
  });

  test('Plan: con macros del día', () {
    final plan = Plan.fromJson({
      'id': 'plan-1',
      'nombre': 'Semana 1',
      'fecha_inicio': '2026-09-01',
      'modo': 'menu',
      'notas': null,
      'calorias_objetivo': 2000,
      'proteinas_g': 100,
      'carbohidratos_g': 275.5,
      'grasas_g': null,
      'equivalentes': <String, dynamic>{},
      'dias': {
        for (final dia in kDiasSemana)
          dia: {'desayuno': '', 'colacion_am': '', 'comida': '', 'colacion_pm': '', 'cena': ''},
      },
    });

    expect(plan.caloriasObjetivo, 2000.0);
    expect(plan.proteinasG, 100.0);
    expect(plan.carbohidratosG, 275.5);
    expect(plan.grasasG, isNull);
  });

  test('RegistroComida con nulos', () {
    final registro = RegistroComida.fromJson(registroJson());

    expect(registro.planId, isNull);
    expect(registro.queComio, isNull);
    expect(registro.fotoId, isNull);
    expect(registro.origen, 'whatsapp');
    expect(registro.createdAt, DateTime.utc(2026, 9, 11, 14, 5));
    expect(registro.pendiente, isFalse);
  });

  test('Dia con registros nulos y presentes', () {
    final dia = Dia.fromJson({
      'fecha': '2026-09-11',
      'dia_semana': 'jueves',
      'plan_id': null,
      'modo': null,
      'puede_registrar': true,
      'agua_vasos': 5,
      'reto_21_dia': null,
      'tiempos': [
        for (final tiempo in kTiempos)
          {
            'tiempo': tiempo,
            'planeado': '',
            'registro': tiempo == 'comida'
                ? registroJson(queComio: 'tacos', fotoId: 'f1', planId: 'plan-1')
                : null,
          },
      ],
      'faltan': <String>[],
    });

    expect(dia.tienePlan, isFalse);
    expect(dia.modo, isNull);
    expect(dia.reto21Dia, isNull);
    expect(dia.tiempos, hasLength(5));
    expect(dia.tiempos[0].registro, isNull);
    expect(dia.tiempos[2].registro!.queComio, 'tacos');
    expect(dia.tiempos[2].registro!.fotoId, 'f1');
    expect(dia.ejercicioMin, 0, reason: 'sin registro en el JSON');
    expect(dia.ejercicioTipo, isNull);
  });

  test('Dia con ejercicio registrado', () {
    final dia = Dia.fromJson({
      'fecha': '2026-09-11',
      'dia_semana': 'jueves',
      'plan_id': 'plan-1',
      'modo': 'menu',
      'puede_registrar': true,
      'agua_vasos': 0,
      'ejercicio_min': 30,
      'ejercicio_tipo': 'caminata',
      'reto_21_dia': null,
      'tiempos': [
        for (final tiempo in kTiempos) {'tiempo': tiempo, 'planeado': '', 'registro': null},
      ],
      'faltan': <String>[],
    });

    expect(dia.ejercicioMin, 30);
    expect(dia.ejercicioTipo, 'caminata');
  });

  group('Progreso', () {
    test('sin registros (todo nulo o vacío)', () {
      final progreso = Progreso.fromJson({
        'desde': '2026-08-29',
        'hasta': '2026-09-11',
        'dias_periodo': 14,
        'dias_registrados': 0,
        'conteo': {'cumplido': 0, 'cambio': 0, 'omitido': 0},
        'apego_pct': null,
        'racha_actual': 0,
        'agua_promedio': null,
        'canal': {'app': 0, 'whatsapp': 0},
        'peso': {'inicial': null, 'actual': null, 'diferencia': null, 'serie': <dynamic>[]},
        'sintomas_promedio': {
          'energia': null,
          'digestion': null,
          'hambre': null,
          'sueno': null,
          'animo': null,
        },
        'donde_se_sale': <dynamic>[],
        'fotos': <dynamic>[],
      });

      expect(progreso.apegoPct, isNull);
      expect(progreso.aguaPromedio, isNull);
      expect(progreso.peso.serie, isEmpty);
      expect(progreso.sintomasPromedio.energia, isNull);
      expect(progreso.fotos, isEmpty);
    });

    test('con datos', () {
      final progreso = Progreso.fromJson({
        'desde': '2026-08-29',
        'hasta': '2026-09-11',
        'dias_periodo': 14,
        'dias_registrados': 9,
        'conteo': {'cumplido': 30, 'cambio': 8, 'omitido': 4},
        'apego_pct': 71,
        'racha_actual': 3,
        'agua_promedio': 6.5,
        'canal': {'app': 25, 'whatsapp': 17},
        'peso': {
          'inicial': 85,
          'actual': 83.2,
          'diferencia': -1.8,
          'serie': [
            {'fecha': '2026-08-29', 'peso': 85, 'origen': 'consulta'},
            {'fecha': '2026-09-10', 'peso': 83.2, 'origen': 'app'},
          ],
        },
        'sintomas_promedio': {
          'energia': 3.5,
          'digestion': 2.5,
          'hambre': 3,
          'sueno': null,
          'animo': 4,
        },
        'donde_se_sale': [
          {
            'tiempo': 'cena',
            'cambio': 5,
            'omitido': 2,
            'que_comio_frecuente': [
              {'texto': 'tacos de guisado', 'veces': 3},
            ],
          },
        ],
        'fotos': [
          {'id': 'f1', 'fecha': '2026-09-11', 'tiempo': 'desayuno'},
        ],
      });

      expect(progreso.apegoPct, 71);
      expect(progreso.conteo.total, 42);
      expect(progreso.peso.inicial, 85.0);
      expect(progreso.peso.serie.last.origen, 'app');
      expect(progreso.sintomasPromedio.hambre, 3.0);
      expect(progreso.dondeSeSale.single.queComioFrecuente.single.veces, 3);
      expect(progreso.fotos.single.id, 'f1');
    });
  });
}
