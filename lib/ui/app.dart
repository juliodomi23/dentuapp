import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/tema.dart';
import '../data/repositories/auth_repository.dart';
import 'core/widgets/estados.dart';
import 'inicio/widgets/inicio_screen.dart';
import 'vincular/view_models/vincular_view_model.dart';
import 'vincular/widgets/vincular_screen.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class DentuApp extends StatelessWidget {
  const DentuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppConfig.nombreApp,
      debugShowCheckedModeBanner: false,
      theme: crearTemaDentu(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _PantallaSegunSesion(),
    );
  }
}

/// Decide la pantalla raíz según la sesión (hace el papel del router).
class _PantallaSegunSesion extends StatelessWidget {
  const _PantallaSegunSesion();

  @override
  Widget build(BuildContext context) {
    final estado = context.select((AuthRepository auth) => auth.estado);

    if (estado == EstadoSesion.sinSesion) {
      // Si la sesión se cerró (p. ej. por un 401) con pantallas o diálogos abiertos, se cierran.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _navigatorKey.currentState?.popUntil((ruta) => ruta.isFirst),
      );
    }

    final pantalla = switch (estado) {
      EstadoSesion.cargando => const Scaffold(key: ValueKey('cargando'), body: EstadoCargando()),
      EstadoSesion.sinSesion => VincularScreen(
        key: const ValueKey('sin-sesion'),
        viewModel: VincularViewModel(auth: context.read(), diario: context.read()),
      ),
      EstadoSesion.conSesion => const InicioScreen(key: ValueKey('con-sesion')),
    };

    // Un pequeño fundido entre "cargando" → "vincular" → "app" para que el
    // arranque se sienta menos brusco, sin depender de ningún paquete nuevo.
    return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: pantalla);
  }
}
