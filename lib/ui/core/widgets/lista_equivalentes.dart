import 'package:flutter/material.dart';

class ListaEquivalentes extends StatelessWidget {
  const ListaEquivalentes({super.key, required this.equivalentes});

  final Map<String, double> equivalentes;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tus equivalentes del día', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final grupo in equivalentes.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(grupo.key)),
                    Text(
                      _formatear(grupo.value),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatear(double valor) =>
      valor == valor.roundToDouble() ? valor.toStringAsFixed(0) : valor.toStringAsFixed(1);
}
