import 'package:flutter/material.dart';

import '../../core/widgets/microinteracciones.dart';

/// Selector de día ◀ ▶ con el día actual resaltado en el color primario.
class SelectorDia extends StatelessWidget {
  const SelectorDia({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.esHoy,
    required this.onAnterior,
    required this.onSiguiente,
    required this.onHoy,
  });

  final String titulo;
  final String? subtitulo;
  final bool esHoy;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final VoidCallback onHoy;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final colorTexto = esHoy ? esquema.onPrimaryContainer : esquema.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ReaccionToque(
            haptico: false,
            builder: (context, envolver) => IconButton.filledTonal(
              onPressed: envolver(onAnterior),
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Día anterior',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: esHoy ? esquema.primaryContainer : esquema.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subtitulo != null)
                      Text(
                        subtitulo!.toUpperCase(),
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: colorTexto.withValues(alpha: 0.75),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    Text(
                      titulo,
                      style: tema.textTheme.titleMedium?.copyWith(
                        color: colorTexto,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitulo == null && !esHoy)
                      TextButton(onPressed: onHoy, child: const Text('Ir a hoy')),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ReaccionToque(
            haptico: false,
            builder: (context, envolver) => IconButton.filledTonal(
              onPressed: envolver(onSiguiente),
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Día siguiente',
            ),
          ),
        ],
      ),
    );
  }
}
