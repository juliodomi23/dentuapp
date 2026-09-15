import 'package:flutter/material.dart';

import '../../../config/tema.dart';
import '../../core/widgets/microinteracciones.dart';
import '../ejercicio_mensajes.dart';
import '../view_models/hoy_view_model.dart';
import 'dialogo_tipo_ejercicio.dart';

/// Vista dedicada al ejercicio: para quien quiere registrar con calma (no
/// solo +/- rápido) y ver algo más de contexto que en la tarjeta de "Hoy".
/// El historial multi-día queda pendiente de que el backend lo exponga; por
/// ahora solo tips generales, sin depender de datos que no existen todavía.
class EjercicioDetalleScreen extends StatelessWidget {
  const EjercicioDetalleScreen({super.key, required this.viewModel});

  final HoyViewModel viewModel;

  Future<void> _editarTipo(BuildContext context) async {
    final tipo = await DialogoTipoEjercicio.mostrar(
      context,
      tipoActual: viewModel.dia?.ejercicioTipo,
    );
    if (tipo != null) viewModel.cambiarTipoEjercicio(tipo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final dia = viewModel.dia;
          final tema = Theme.of(context);
          final minutos = dia?.ejercicioMin ?? 0;
          final habilitado = dia?.puedeRegistrar ?? false;
          final nota = notaEjercicio(minutos, habilitado);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        minutos == 1 ? '1 minuto' : '$minutos minutos',
                        style: tema.textTheme.displaySmall?.copyWith(color: tema.colorScheme.tertiary),
                      ),
                      const SizedBox(height: 4),
                      Text('de ejercicio hoy', style: tema.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ReaccionToque(
                            builder: (context, envolver) => IconButton.filledTonal(
                              onPressed: envolver(
                                habilitado && minutos > 0 ? viewModel.restarMinutosEjercicio : null,
                              ),
                              icon: const Icon(Icons.remove_rounded),
                              tooltip: 'Quitar minutos',
                            ),
                          ),
                          const SizedBox(width: 20),
                          ReaccionToque(
                            builder: (context, envolver) => IconButton.filled(
                              onPressed: envolver(habilitado ? viewModel.sumarMinutosEjercicio : null),
                              icon: const Icon(Icons.add_rounded),
                              tooltip: 'Agregar minutos',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: habilitado ? () => _editarTipo(context) : null,
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(
                          dia?.ejercicioTipo?.isNotEmpty == true
                              ? dia!.ejercicioTipo!
                              : 'Agregar qué hiciste',
                        ),
                      ),
                      if (dia?.ejercicioPendiente ?? false)
                        const Text(
                          'Pendiente de enviar',
                          style: TextStyle(color: ColoresDentu.pendiente),
                        )
                      else if (nota != null)
                        Text(nota, style: tema.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text('Tips de movimiento', style: tema.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              for (final tip in kTipsEjercicio)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.directions_walk_rounded, color: tema.colorScheme.tertiary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
