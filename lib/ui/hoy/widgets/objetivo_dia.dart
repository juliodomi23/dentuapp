import 'package:flutter/material.dart';

/// Bloque compacto con las metas del día completo (kcal/macros del plan).
class ObjetivoDia extends StatelessWidget {
  const ObjetivoDia({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Card(
      color: esquema.secondaryContainer.withValues(alpha: 0.55),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.flag_rounded, color: esquema.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: esquema.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
