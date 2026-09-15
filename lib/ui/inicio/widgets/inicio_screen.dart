import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../hoy/view_models/hoy_view_model.dart';
import '../../hoy/widgets/ejercicio_detalle_screen.dart';
import '../../hoy/widgets/hoy_screen.dart';
import '../../perfil/view_models/perfil_view_model.dart';
import '../../perfil/widgets/perfil_screen.dart';
import '../../progreso/view_models/progreso_view_model.dart';
import '../../progreso/widgets/progreso_screen.dart';
import '../../semana/view_models/semana_view_model.dart';
import '../../semana/widgets/semana_screen.dart';

/// Barra inferior: Hoy / Ejercicio / Semana / Progreso / Perfil.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late final HoyViewModel _hoy;
  late final SemanaViewModel _semana;
  late final ProgresoViewModel _progreso;
  late final PerfilViewModel _perfil;
  int _indice = 0;

  @override
  void initState() {
    super.initState();
    _hoy = HoyViewModel(diario: context.read(), plan: context.read());
    _semana = SemanaViewModel(plan: context.read());
    _progreso = ProgresoViewModel(progreso: context.read());
    _perfil = PerfilViewModel(
      auth: context.read(),
      perfil: context.read(),
      diario: context.read(),
      recordatorios: context.read(),
      progreso: context.read(),
    );
  }

  @override
  void dispose() {
    _hoy.dispose();
    _semana.dispose();
    _progreso.dispose();
    _perfil.dispose();
    super.dispose();
  }

  /// Al entrar a una pestaña se recarga, para ver lo registrado por WhatsApp o
  /// los cambios hechos en otra pestaña.
  void _seleccionar(int indice) {
    setState(() => _indice = indice);
    switch (indice) {
      case 0:
      case 1:
        _hoy.cargarDia.execute();
      case 2:
        _semana.cargar.execute();
      case 3:
        _progreso.cargar.execute();
      case 4:
        _perfil.cargarDatos.execute();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      HoyScreen(viewModel: _hoy),
      EjercicioDetalleScreen(viewModel: _hoy),
      SemanaScreen(viewModel: _semana),
      ProgresoScreen(viewModel: _progreso),
      PerfilScreen(viewModel: _perfil),
    ];
    return Scaffold(
      // No es un IndexedStack: cada pestaña se queda montada (mismo truco de
      // IndexedStack para no perder el estado de sus ViewModels) pero la que
      // no está activa se desvanece con un pequeño desplazamiento en vez de
      // aparecer/desaparecer de golpe.
      body: SizedBox.expand(
        child: Stack(
          children: [
            for (var i = 0; i < pantallas.length; i++)
              _PestanaAnimada(activa: i == _indice, child: pantallas[i]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _seleccionar,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Ejercicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Semana',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

/// Envuelve una pestaña para que aparezca/desaparezca con un fundido y un
/// desplazamiento leve en vez de un salto seco, sin desmontarla nunca (eso
/// es lo que permite conservar el estado de su ViewModel). La pestaña
/// inactiva se ignora para toque y lectores de pantalla.
class _PestanaAnimada extends StatelessWidget {
  const _PestanaAnimada({required this.activa, required this.child});

  final bool activa;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !activa,
      child: AnimatedOpacity(
        opacity: activa ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: activa ? Offset.zero : const Offset(0, 0.02),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: ExcludeSemantics(excluding: !activa, child: child),
        ),
      ),
    );
  }
}
