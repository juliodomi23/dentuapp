import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_datos;
import 'package:timezone/timezone.dart' as tz;

import '../../config/app_config.dart';
import '../../utils/result.dart';

/// Notificaciones locales diarias. No necesita servidor.
class NotificationsService {
  NotificationsService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'recordatorios',
      'Recordatorios',
      channelDescription: 'Recordatorios de comidas y agua',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<Result<void>> inicializar() async {
    try {
      tz_datos.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(AppConfig.zonaHorariaClinica));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<bool>> pedirPermiso() async {
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return Result.ok(await android?.requestNotificationsPermission() ?? false);
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return Result.ok(
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
            false,
      );
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  /// Programa una notificación que se repite todos los días a la misma hora.
  /// Usa alarmas inexactas para no pedir el permiso de alarmas exactas.
  Future<Result<void>> programarDiaria({
    required int id,
    required int hora,
    required int minuto,
    required String titulo,
    required String cuerpo,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: _proximaVez(hora, minuto),
        notificationDetails: _detalles,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: titulo,
        body: cuerpo,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> cancelarTodas() async {
    try {
      await _plugin.cancelAll();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  tz.TZDateTime _proximaVez(int hora, int minuto) {
    final ahora = tz.TZDateTime.now(tz.local);
    var fecha = tz.TZDateTime(
      tz.local,
      ahora.year,
      ahora.month,
      ahora.day,
      hora,
      minuto,
    );
    if (fecha.isBefore(ahora)) fecha = fecha.add(const Duration(days: 1));
    return fecha;
  }
}
