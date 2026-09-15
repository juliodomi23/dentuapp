import 'package:flutter/material.dart';

class SintomasPromedio extends StatelessWidget {
  const SintomasPromedio({super.key, required this.sintomas});

  /// Nombre visible → promedio de 1 a 5 (null si no hay datos).
  final Map<String, double?> sintomas;

  @override
  Widget build(BuildContext context) {
    if (sintomas.values.every((valor) => valor == null)) {
      return const Text('Registra cómo te sientes desde Perfil para verlo aquí.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entrada in sintomas.entries)
          _FilaSintoma(nombre: entrada.key, valor: entrada.value),
        const SizedBox(height: 4),
        Text('1 = muy mal · 5 = muy bien', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _FilaSintoma extends StatelessWidget {
  const _FilaSintoma({required this.nombre, required this.valor});

  final String nombre;
  final double? valor;

  @override
  Widget build(BuildContext context) {
    final texto = valor == null ? '—' : valor!.toStringAsFixed(1);
    return Semantics(
      label: '$nombre: ${valor == null ? 'sin datos' : '$texto de 5'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(nombre)),
              Expanded(
                child: LinearProgressIndicator(value: (valor ?? 0) / 5, minHeight: 8),
              ),
              SizedBox(width: 40, child: Text(texto, textAlign: TextAlign.end)),
            ],
          ),
        ),
      ),
    );
  }
}
