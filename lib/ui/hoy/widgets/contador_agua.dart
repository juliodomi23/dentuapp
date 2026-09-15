import 'package:flutter/material.dart';

import '../../../config/constantes.dart';
import '../../../config/tema.dart';
import '../../core/widgets/microinteracciones.dart';

/// Mensaje que reacciona al avance hacia [LimitesRegistro.aguaMetaVasos], no
/// solo el número de vasos: reforzar que "la app está viendo" el progreso
/// motiva más que un contador plano.
String _mensajeAgua(int vasos) {
  final meta = LimitesRegistro.aguaMetaVasos;
  if (vasos <= 0) return 'Tu cuerpo está pidiendo agua 💧';
  if (vasos < meta * 0.6) return 'Vas bien, sigue así';
  if (vasos < meta) return 'Ya casi llegas a tu meta';
  return '¡Hidratación nivel experto!';
}

class ContadorAgua extends StatelessWidget {
  const ContadorAgua({
    super.key,
    required this.vasos,
    required this.pendiente,
    required this.habilitado,
    required this.onSumar,
    required this.onRestar,
  });

  final int vasos;
  final bool pendiente;
  final bool habilitado;
  final VoidCallback onSumar;
  final VoidCallback onRestar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: tema.colorScheme.primary, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: tema.colorScheme.primaryContainer,
                child: Icon(Icons.water_drop_rounded, color: tema.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Agua', style: tema.textTheme.titleSmall),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animacion) =>
                            ScaleTransition(scale: animacion, child: child),
                        child: Text(
                          vasos == 1 ? '1 vaso' : '$vasos vasos',
                          key: ValueKey(vasos),
                          style: tema.textTheme.titleLarge,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: pendiente
                            ? const Text(
                                'Pendiente de enviar',
                                key: ValueKey('pendiente'),
                                style: TextStyle(color: ColoresDentu.pendiente, fontSize: 12),
                              )
                            : Text(
                                _mensajeAgua(vasos),
                                key: ValueKey('mensaje-$vasos'),
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: tema.colorScheme.primary,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              ReaccionToque(
                builder: (context, envolver) => IconButton.filledTonal(
                  onPressed: envolver(habilitado && vasos > 0 ? onRestar : null),
                  icon: const Icon(Icons.remove_rounded),
                  tooltip: 'Quitar un vaso de agua',
                ),
              ),
              const SizedBox(width: 8),
              ReaccionToque(
                builder: (context, envolver) => IconButton.filled(
                  onPressed: envolver(habilitado ? onSumar : null),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Agregar un vaso de agua',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
