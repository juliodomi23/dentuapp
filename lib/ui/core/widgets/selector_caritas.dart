import 'package:flutter/material.dart';

/// Escala del 1 al 5 con íconos de sentimiento.
class SelectorCaritas extends StatelessWidget {
  const SelectorCaritas({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onCambio,
  });

  static const _iconos = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];
  static const _descripciones = ['Muy mal', 'Mal', 'Regular', 'Bien', 'Muy bien'];

  final String etiqueta;
  final int? valor;
  final ValueChanged<int> onCambio;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: tema.textTheme.titleSmall),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < _iconos.length; i++) _carita(tema, i + 1),
          ],
        ),
      ],
    );
  }

  Widget _carita(ThemeData tema, int puntos) {
    final seleccionada = valor == puntos;
    final color = seleccionada ? tema.colorScheme.primary : tema.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: seleccionada,
      label: '$etiqueta: ${_descripciones[puntos - 1]}',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onCambio(puntos),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: seleccionada ? tema.colorScheme.primaryContainer : null,
            border: seleccionada ? Border.all(color: tema.colorScheme.primary, width: 2) : null,
          ),
          child: ExcludeSemantics(
            child: Icon(_iconos[puntos - 1], size: 28, color: color),
          ),
        ),
      ),
    );
  }
}
