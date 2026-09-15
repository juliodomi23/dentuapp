import 'package:flutter/material.dart';

import '../../../config/constantes.dart';
import '../../../config/tema.dart';
import '../reto21_mensajes.dart';

/// El corazón emocional de "Hoy": el Reto 21 se muestra como un logro (número
/// grande, mensaje que cambia según el día, fuego con un pulso sutil al
/// cargar o al subir de día) y no como una barra de progreso genérica.
class BarraReto extends StatefulWidget {
  const BarraReto({super.key, required this.dia});

  static const int totalDias = LimitesRegistro.reto21TotalDias;

  final int dia;

  @override
  State<BarraReto> createState() => _BarraRetoState();
}

class _BarraRetoState extends State<BarraReto> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _pulso = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 45),
    TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 55),
  ]).animate(CurvedAnimation(parent: _controlador, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _controlador.forward();
  }

  @override
  void didUpdateWidget(covariant BarraReto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dia > oldWidget.dia) _controlador.forward(from: 0);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final dia = widget.dia;
    return Card(
      color: ColoresDentu.dorado.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ScaleTransition(
                  scale: _pulso,
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: ColoresDentu.dorado,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reto 21 · día $dia',
                        style: tema.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ColoresDentu.verde,
                        ),
                      ),
                      Text(mensajeReto21(dia), style: tema.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Reto 21',
              value: 'Día $dia de ${BarraReto.totalDias}',
              child: ExcludeSemantics(
                child: Row(
                  children: List.generate(3, (tramo) {
                    final avanceTramo = (dia - tramo * 7).clamp(0, 7) / 7;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: tramo < 2 ? 4 : 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: avanceTramo),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            builder: (context, valor, _) => LinearProgressIndicator(
                              value: valor,
                              minHeight: 10,
                              color: ColoresDentu.dorado,
                              backgroundColor: ColoresDentu.dorado.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            if (tramoCompletadoReto21(dia) >= 0) ...[
              const SizedBox(height: 8),
              Text(
                kTramosReto21[tramoCompletadoReto21(dia)],
                style: tema.textTheme.bodySmall?.copyWith(
                  color: ColoresDentu.verde,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
