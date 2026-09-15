import 'package:flutter/material.dart';

import '../../../config/tema.dart';

/// Color del fuego según la racha: gris al arrancar, naranja tibio a la
/// semana, dorado con brillo cerca del Reto 21 completo. Refuerza el avance
/// en los días "de en medio", no solo en el hito final.
Color _colorTemperatura(int dias) {
  if (dias < 3) return const Color(0xFF9E9E9E);
  if (dias < 7) return const Color(0xFFE0823F);
  return ColoresDentu.dorado;
}

double _glowDe(int dias) {
  if (dias < 7) return 0;
  if (dias < 21) return 0.30;
  return 0.55;
}

/// La racha de días registrados como un logro, no como una métrica más:
/// número grande, mensaje que cambia según el número y un pulso sutil del
/// ícono al cargar. En hitos reales (3, 7, 14, 21 días) lleva un borde
/// dorado, sin disparar ninguna animación adicional aquí (la celebración
/// grande vive en "Hoy", para no repetirla cada vez que se entra a esta
/// pantalla).
class TarjetaRacha extends StatefulWidget {
  const TarjetaRacha({super.key, required this.dias, required this.esHito});

  final int dias;
  final bool esHito;

  @override
  State<TarjetaRacha> createState() => _TarjetaRachaState();
}

class _TarjetaRachaState extends State<TarjetaRacha> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _pulso = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.15), weight: 45),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 55),
  ]).animate(CurvedAnimation(parent: _controlador, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _controlador.forward();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  String get _mensaje {
    final dias = widget.dias;
    if (dias <= 0) return 'Registra hoy para empezar tu racha.';
    if (dias < 3) return '¡Vas arrancando!';
    if (dias < 7) return 'Le vas agarrando el ritmo.';
    if (dias < 14) return 'Ya llevas una semana.';
    if (dias < 21) return 'Vas asentando el hábito.';
    return '¡No has fallado en $dias días!';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = _colorTemperatura(widget.dias);
    final glow = _glowDe(widget.dias);
    return Card(
      color: ColoresDentu.dorado.withValues(alpha: 0.08),
      shape: widget.esHito
          ? RoundedRectangleBorder(
              side: const BorderSide(color: ColoresDentu.dorado, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ScaleTransition(
              scale: _pulso,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: glow <= 0
                      ? null
                      : [BoxShadow(color: color.withValues(alpha: glow), blurRadius: 18, spreadRadius: 2)],
                ),
                child: Icon(Icons.local_fire_department_rounded, color: color, size: 36),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.dias == 1 ? '1 día seguido' : '${widget.dias} días seguidos',
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColoresDentu.verde,
                    ),
                  ),
                  Text(_mensaje, style: tema.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
