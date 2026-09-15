import 'package:flutter/material.dart';

import '../../../config/tema.dart';
import '../ejercicio_mensajes.dart';

/// Resumen rápido del ejercicio de hoy en "Hoy"; el registro detallado (tipo,
/// minutos, tips) vive en [EjercicioDetalleScreen] para no saturar esta
/// pantalla a quien solo quiere ver su día de un vistazo.
class TarjetaEjercicio extends StatelessWidget {
  const TarjetaEjercicio({
    super.key,
    required this.minutos,
    required this.tipo,
    required this.pendiente,
    required this.habilitado,
    required this.onAbrirDetalle,
  });

  final int minutos;
  final String? tipo;
  final bool pendiente;
  final bool habilitado;
  final VoidCallback onAbrirDetalle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final nota = notaEjercicio(minutos, habilitado);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAbrirDetalle,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: tema.colorScheme.tertiary, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: tema.colorScheme.tertiaryContainer,
                  child: Icon(Icons.directions_run_rounded, color: tema.colorScheme.tertiary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ejercicio', style: tema.textTheme.titleSmall),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animacion) =>
                            ScaleTransition(scale: animacion, child: child),
                        child: Text(
                          minutos == 1 ? '1 minuto' : '$minutos minutos',
                          key: ValueKey(minutos),
                          style: tema.textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        tipo?.isNotEmpty == true ? tipo! : 'Toca para registrar',
                        style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.tertiary),
                      ),
                      if (pendiente)
                        const Text(
                          'Pendiente de enviar',
                          style: TextStyle(color: ColoresDentu.pendiente, fontSize: 12),
                        )
                      else if (nota != null)
                        Text(nota, style: tema.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: tema.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
