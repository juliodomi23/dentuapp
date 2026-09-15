import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/constantes.dart';
import '../../../config/tema.dart';
import '../../../data/models/plan.dart';
import '../../core/widgets/microinteracciones.dart';

class TarjetaDiaPlan extends StatefulWidget {
  const TarjetaDiaPlan({
    super.key,
    required this.nombreDia,
    required this.abreviatura,
    required this.comidas,
    required this.esHoy,
    required this.habilitado,
    required this.onMover,
    required this.onVerPreparacion,
    this.resaltado = false,
  });

  final String nombreDia;
  final String abreviatura;
  final ComidasDia comidas;
  final bool esHoy;
  final bool habilitado;
  final VoidCallback onMover;
  final ValueChanged<String> onVerPreparacion;

  /// True justo después de un intercambio que involucró este día: dispara un
  /// resalte breve en vez de que el cambio se vea de golpe.
  final bool resaltado;

  @override
  State<TarjetaDiaPlan> createState() => _TarjetaDiaPlanState();
}

class _TarjetaDiaPlanState extends State<TarjetaDiaPlan> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );

  /// 1 = recién resaltado, 0 = normal. Empieza en 0 (normal) salvo que ya
  /// llegue resaltado desde el primer build.
  late final Animation<double> _resalte = Tween<double>(
    begin: 1,
    end: 0,
  ).animate(CurvedAnimation(parent: _controlador, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    if (widget.resaltado) _controlador.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant TarjetaDiaPlan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resaltado && !oldWidget.resaltado) _controlador.forward(from: 0);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final colorBase = widget.esHoy ? ColoresDentu.dorado.withValues(alpha: 0.07) : null;

    return AnimatedBuilder(
      animation: _resalte,
      builder: (context, child) => Card(
        clipBehavior: Clip.antiAlias,
        color: Color.lerp(
          colorBase ?? esquema.surface,
          ColoresDentu.dorado.withValues(alpha: 0.3),
          _resalte.value,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: widget.esHoy ? BorderSide(color: esquema.primary, width: 1.5) : BorderSide.none,
        ),
        child: child,
      ),
      child: ExpansionTile(
        initiallyExpanded: widget.esHoy,
        onExpansionChanged: (_) => HapticFeedback.selectionClick(),
        leading: _BadgeDia(abreviatura: widget.abreviatura, esHoy: widget.esHoy),
        title: Text(
          widget.nombreDia,
          style: tema.textTheme.titleMedium?.copyWith(
            fontWeight: widget.esHoy ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: widget.esHoy
            ? Text(
                'Hoy',
                style: tema.textTheme.labelMedium?.copyWith(
                  color: esquema.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        children: [
          for (final tiempo in kTiempos) _filaComida(tiempo, esquema),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ReaccionToque(
                builder: (context, envolver) => OutlinedButton.icon(
                  onPressed: envolver(widget.habilitado ? widget.onMover : null),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Mover este menú a otro día'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaComida(String tiempo, ColorScheme esquema) {
    final platillo = widget.comidas.deTiempo(tiempo);
    return ListTile(
      dense: true,
      leading: Icon(kIconoTiempo[tiempo], size: 20, color: esquema.primary),
      title: Text(kNombreTiempo[tiempo]!),
      subtitle: Text(platillo.isEmpty ? 'Sin platillo' : platillo),
      trailing: platillo.isEmpty
          ? null
          : IconButton(
              onPressed: () => widget.onVerPreparacion(platillo),
              icon: const Icon(Icons.menu_book_rounded),
              iconSize: 20,
              tooltip: 'Ver preparación',
            ),
    );
  }
}

class _BadgeDia extends StatefulWidget {
  const _BadgeDia({required this.abreviatura, required this.esHoy});

  final String abreviatura;
  final bool esHoy;

  @override
  State<_BadgeDia> createState() => _BadgeDiaState();
}

class _BadgeDiaState extends State<_BadgeDia> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _entrada = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.12), weight: 55),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 45),
  ]).animate(CurvedAnimation(parent: _controlador, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    // Un poco más de presencia para el día de hoy al entrar a la pantalla,
    // sin usar el mismo ícono de fuego que "Hoy" para no competir con él.
    if (widget.esHoy) {
      _controlador.forward();
    } else {
      _controlador.value = 1;
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _entrada,
      child: ExcludeSemantics(
        child: CircleAvatar(
          radius: widget.esHoy ? 22 : 20,
          backgroundColor: widget.esHoy ? esquema.primary : esquema.surfaceContainerHighest,
          child: Text(
            widget.abreviatura,
            style: TextStyle(
              color: widget.esHoy ? esquema.onPrimary : esquema.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
