import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/diario_repository.dart';
import 'data/repositories/iap_repository.dart';
import 'data/repositories/perfil_repository.dart';
import 'data/repositories/plan_repository.dart';
import 'data/repositories/progreso_repository.dart';
import 'data/repositories/recordatorios_repository.dart';
import 'data/services/api_service.dart';
import 'data/services/conectividad_service.dart';
import 'data/services/fake_api_service.dart';
import 'data/services/local_queue_service.dart';
import 'data/services/notifications_service.dart';
import 'data/services/preferencias_service.dart';
import 'data/services/secure_storage_service.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  Intl.defaultLocale = 'es_MX';
  await Hive.initFlutter();
  // verifyReceipt necesita el recibo completo que expone StoreKit 1. Migrar a
  // transacciones JWS antes de que Flutter retire esta compatibilidad.
  // ignore: deprecated_member_use
  if (Platform.isIOS) InAppPurchaseStoreKitPlatform.enableStoreKit1();

  // Services
  final ApiService api = AppConfig.usarMock
      ? FakeApiService(modoEquivalentes: AppConfig.mockEquivalentes)
      : ApiService(urlVinculacion: AppConfig.apiUrl);
  final almacenamiento = SecureStorageService();
  final preferencias = await PreferenciasService.abrir();
  final colaOffline = await LocalQueueService.abrir();
  final notificaciones = NotificationsService();
  await notificaciones.inicializar();
  final conectividad = ConectividadService();

  // Repositories
  final auth = AuthRepository(
    api: api,
    almacenamiento: almacenamiento,
    preferencias: preferencias,
  );
  await auth.cargarSesion();
  if (auth.estado == EstadoSesion.conSesion) unawaited(auth.refrescarPerfil());

  final diario = DiarioRepository(
    api: api,
    cola: colaOffline,
    conectividad: conectividad,
  )..iniciarSincronizacion();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: diario),
        ChangeNotifierProvider(create: (_) => IapRepository(api: api)),
        Provider(
          create: (_) =>
              PlanRepository(api: api, leerPacienteId: () => auth.paciente?.id),
        ),
        Provider(create: (_) => ProgresoRepository(api: api)),
        Provider(create: (_) => PerfilRepository(api: api)),
        Provider(
          create: (_) => RecordatoriosRepository(
            notificaciones: notificaciones,
            preferencias: preferencias,
          ),
        ),
      ],
      child: const DentuApp(),
    ),
  );
}
