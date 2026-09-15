import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/tema.dart';

/// Da retroalimentación inmediata (escala + vibración leve) a una acción
/// común, sin robarle el gesto al widget interior: el botón real conserva su
/// `onPressed`, esta envoltura solo agrega la reacción visual/háptica.
///
/// Uso: `ReaccionToque(builder: (context, envolver) => FilledButton(onPressed:
/// envolver(miAccion), ...))`.
///
/// Investigación: la retroalimentación de acciones frecuentes (marcar una
/// comida, sumar un vaso de agua) debe sentirse instantánea para reforzar el
/// hábito de registrar, a diferencia de los hitos, que se celebran distinto
/// (ver [mostrarCelebracion]).
class ReaccionToque extends StatefulWidget {
  const ReaccionToque({super.key, required this.builder, this.haptico = true});

  final Widget Function(BuildContext context, VoidCallback? Function(VoidCallback?) envolver)
  builder;
  final bool haptico;

  @override
  State<ReaccionToque> createState() => _ReaccionToqueState();
}

class _ReaccionToqueState extends State<ReaccionToque> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _escala = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 65),
  ]).animate(CurvedAnimation(parent: _controlador, curve: Curves.easeOut));

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  VoidCallback? _envolver(VoidCallback? original) {
    if (original == null) return null;
    return () {
      if (widget.haptico) HapticFeedback.lightImpact();
      _controlador.forward(from: 0);
      original();
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _escala,
      builder: (context, child) => Transform.scale(scale: _escala.value, child: child),
      child: widget.builder(context, _envolver),
    );
  }
}

/// Dispara un momento breve de celebración (dura menos de un segundo, no
/// bloquea la interacción y termina solo) para un hito real: completar todas
/// las comidas del día, o llegar a un día hito de racha/Reto 21.
///
/// Investigación: en Duolingo la animación grande solo aparece en hitos, no
/// en cada acción — celebrar todo le resta impacto a lo que sí importa.
void mostrarCelebracion(BuildContext context, {required IconData icono, required String mensaje}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry entrada;
  entrada = OverlayEntry(
    builder: (context) =>
        _CelebracionOverlay(icono: icono, mensaje: mensaje, alTerminar: () => entrada.remove()),
  );
  overlay.insert(entrada);
}

class _CelebracionOverlay extends StatefulWidget {
  const _CelebracionOverlay({required this.icono, required this.mensaje, required this.alTerminar});

  final IconData icono;
  final String mensaje;
  final VoidCallback alTerminar;

  @override
  State<_CelebracionOverlay> createState() => _CelebracionOverlayState();
}

class _CelebracionOverlayState extends State<_CelebracionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _escalaIcono = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.15), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 20),
    // ojo: NO usar una curva de rebote (easeOutBack/elasticOut) aquí — TweenSequence
    // exige que el valor de la curva se quede siempre entre 0 y 1, y esas curvas se
    // pasan de 1.0 a propósito (por diseño). El "pop" ya está en los valores de la
    // secuencia de arriba (0.4 → 1.15 → 1.0 → 0.92); la curva solo marca el ritmo.
  ]).animate(CurvedAnimation(parent: _controlador, curve: Curves.easeOutCubic));

  late final Animation<double> _opacidad = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
  ]).animate(_controlador);

  @override
  void initState() {
    super.initState();
    _controlador.addStatusListener((estado) {
      if (estado == AnimationStatus.completed) widget.alTerminar();
    });
    _controlador.forward();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.4),
        child: FadeTransition(
          opacity: _opacidad,
          child: AnimatedBuilder(
            animation: _controlador,
            builder: (context, child) => CustomPaint(
              painter: _ParticulasPainter(progreso: _controlador.value),
              child: child,
            ),
            child: ScaleTransition(
              scale: _escalaIcono,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icono, size: 48, color: ColoresDentu.dorado),
                    const SizedBox(height: 10),
                    Text(
                      widget.mensaje,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: ColoresDentu.verde,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Estallido simple de puntos dorados alrededor del ícono, hecho con
/// `CustomPainter` puro (sin librerías de confeti/lottie).
class _ParticulasPainter extends CustomPainter {
  _ParticulasPainter({required this.progreso});

  final double progreso;

  static final List<double> _angulos = List.generate(10, (i) => (i / 10) * 2 * pi);

  @override
  void paint(Canvas canvas, Size size) {
    if (progreso <= 0.15 || progreso >= 0.85) return;
    final centro = Offset(size.width / 2, size.height / 2);
    final local = ((progreso - 0.15) / 0.7).clamp(0.0, 1.0);
    final radio = 30 + local * 70;
    final opacidad = (1 - local).clamp(0.0, 1.0);
    final pintura = Paint()..color = ColoresDentu.dorado.withValues(alpha: opacidad * 0.8);
    for (final angulo in _angulos) {
      final punto = centro + Offset(cos(angulo), sin(angulo)) * radio;
      canvas.drawCircle(punto, 3, pintura);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticulasPainter oldDelegate) => oldDelegate.progreso != progreso;
}
