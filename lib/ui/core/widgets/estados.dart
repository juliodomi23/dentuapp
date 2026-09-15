import 'package:flutter/material.dart';

import '../../../config/tema.dart';

class EstadoCargando extends StatelessWidget {
  const EstadoCargando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(semanticsLabel: 'Cargando'),
      ),
    );
  }
}

class EstadoError extends StatelessWidget {
  const EstadoError({
    super.key,
    required this.mensaje,
    required this.onReintentar,
  });

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: tema.colorScheme.outline),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Qué motivo pintar junto a los círculos suaves de [EstadoVacio], para que
/// las distintas pantallas vacías no se vean todas idénticas aunque
/// compartan el mismo lenguaje visual (círculos verde/dorado).
enum IlustracionVacio { generica, fotos, plan, semana, peso }

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    this.icono = Icons.restaurant_rounded,
    this.ilustracion = IlustracionVacio.generica,
    required this.titulo,
    this.mensaje,
  });

  final IconData icono;
  final IlustracionVacio ilustracion;
  final String titulo;
  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: CustomPaint(
                painter: _FondoSuavePainter(ilustracion),
                child: Center(child: Icon(icono, size: 40, color: ColoresDentu.verde)),
              ),
            ),
            const SizedBox(height: 16),
            Text(titulo, style: tema.textTheme.titleMedium, textAlign: TextAlign.center),
            if (mensaje != null) ...[
              const SizedBox(height: 4),
              Text(mensaje!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dos círculos suaves en verde/dorado detrás del ícono, más un motivo
/// pequeño en la esquina según el contexto (cámara, plato, calendario o
/// tendencia). Le da calidez a un estado vacío sin recurrir a una mascota o
/// ilustración importada: son formas simples dibujadas con `CustomPainter`.
class _FondoSuavePainter extends CustomPainter {
  _FondoSuavePainter(this.ilustracion);

  final IlustracionVacio ilustracion;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      centro,
      size.width / 2,
      Paint()..color = ColoresDentu.verde.withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      centro,
      size.width / 2.8,
      Paint()..color = ColoresDentu.dorado.withValues(alpha: 0.12),
    );

    final trazo = Paint()
      ..color = ColoresDentu.dorado.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (ilustracion) {
      case IlustracionVacio.fotos:
        _dibujarCamara(canvas, size, trazo);
      case IlustracionVacio.plan:
        _dibujarPlato(canvas, size, trazo);
      case IlustracionVacio.semana:
        _dibujarCalendario(canvas, size, trazo);
      case IlustracionVacio.peso:
        _dibujarTendencia(canvas, size, trazo);
      case IlustracionVacio.generica:
        break;
    }
  }

  void _dibujarCamara(Canvas canvas, Size size, Paint trazo) {
    final centroCamara = Offset(size.width * 0.78, size.height * 0.78);
    final cuerpo = Rect.fromCenter(center: centroCamara, width: 24, height: 17);
    canvas.drawRRect(RRect.fromRectAndRadius(cuerpo, const Radius.circular(3)), trazo);
    canvas.drawLine(
      Offset(cuerpo.left + 5, cuerpo.top),
      Offset(cuerpo.left + 11, cuerpo.top),
      trazo,
    );
    canvas.drawCircle(centroCamara, 4.5, trazo);
  }

  void _dibujarPlato(Canvas canvas, Size size, Paint trazo) {
    final centroPlato = Offset(size.width * 0.78, size.height * 0.78);
    canvas.drawCircle(centroPlato, 11, trazo);
    canvas.drawCircle(centroPlato, 5, trazo);
  }

  void _dibujarCalendario(Canvas canvas, Size size, Paint trazo) {
    final rect = Rect.fromCenter(center: Offset(size.width * 0.78, size.height * 0.8), width: 23, height: 19);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), trazo);
    canvas.drawLine(Offset(rect.left + 6, rect.top - 3), Offset(rect.left + 6, rect.top + 3), trazo);
    canvas.drawLine(Offset(rect.right - 6, rect.top - 3), Offset(rect.right - 6, rect.top + 3), trazo);
    canvas.drawLine(Offset(rect.left, rect.top + 6), Offset(rect.right, rect.top + 6), trazo);
  }

  void _dibujarTendencia(Canvas canvas, Size size, Paint trazo) {
    final base = Offset(size.width * 0.62, size.height * 0.86);
    final camino = Path()
      ..moveTo(base.dx, base.dy)
      ..lineTo(base.dx + 8, base.dy - 7)
      ..lineTo(base.dx + 16, base.dy - 2)
      ..lineTo(base.dx + 26, base.dy - 14);
    canvas.drawPath(camino, trazo);
    canvas.drawCircle(
      Offset(base.dx + 26, base.dy - 14),
      2.5,
      Paint()..color = ColoresDentu.dorado.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _FondoSuavePainter oldDelegate) =>
      oldDelegate.ilustracion != ilustracion;
}
