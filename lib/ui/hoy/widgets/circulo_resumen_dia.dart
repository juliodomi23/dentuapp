import 'dart:math';

import 'package:flutter/material.dart';

/// Un anillo del círculo: color, avance (0..1) y el texto que lo describe en
/// la leyenda de abajo.
class AnilloResumen {
  const AnilloResumen({required this.color, required this.valor, required this.etiqueta});

  final Color color;
  final double valor;
  final String etiqueta;
}

/// El resumen del día como anillos concéntricos (comidas, agua, Reto 21) en
/// vez de tres tarjetas sueltas: de un vistazo se ve qué tan completo va el
/// día, como los anillos de actividad de un reloj inteligente.
class CirculoResumenDia extends StatelessWidget {
  const CirculoResumenDia({super.key, required this.anillos});

  final List<AnilloResumen> anillos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (context, t, _) => SizedBox(
            width: 168,
            height: 168,
            child: CustomPaint(painter: _AnillosPainter(anillos: anillos, t: t)),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final anillo in anillos)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: anillo.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(anillo.etiqueta, style: tema.textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _AnillosPainter extends CustomPainter {
  _AnillosPainter({required this.anillos, required this.t});

  final List<AnilloResumen> anillos;
  final double t;

  static const double _grosor = 12;
  static const double _espacio = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    var radio = size.width / 2 - _grosor / 2;

    for (final anillo in anillos) {
      final fondo = Paint()
        ..color = anillo.color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _grosor
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(centro, radio, fondo);

      final valor = anillo.valor.clamp(0.0, 1.0);
      if (valor > 0) {
        final trazo = Paint()
          ..color = anillo.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _grosor
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: centro, radius: radio),
          -pi / 2,
          2 * pi * valor * t,
          false,
          trazo,
        );
      }
      radio -= _grosor + _espacio;
    }
  }

  @override
  bool shouldRepaint(covariant _AnillosPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.anillos != anillos;
}
