import 'package:flutter/material.dart';

import '../../../config/constantes.dart';
import '../../core/widgets/microinteracciones.dart';

/// Elige el día destino. Devuelve el día (`lunes`..`domingo`) o null si cancela.
class DialogoMoverMenu extends StatelessWidget {
  const DialogoMoverMenu({super.key, required this.diaOrigen, required this.opciones});

  final String diaOrigen;
  final List<String> opciones;

  static Future<String?> mostrar(
    BuildContext context, {
    required String diaOrigen,
    required List<String> opciones,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => DialogoMoverMenu(diaOrigen: diaOrigen, opciones: opciones),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Mover el menú del ${kNombreDia[diaOrigen]!.toLowerCase()}'),
      contentPadding: const EdgeInsets.only(top: 16),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Elige el día. Los menús de los dos días se intercambian.'),
            ),
            const SizedBox(height: 8),
            for (final dia in opciones)
              ReaccionToque(
                builder: (context, envolver) => ListTile(
                  title: Text(kNombreDia[dia]!),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: envolver(() => Navigator.of(context).pop(dia)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
      ],
    );
  }
}
