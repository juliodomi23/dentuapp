import 'package:flutter/material.dart';

import '../../../data/models/preparacion.dart';
import '../../../utils/result.dart';
import '../mensaje_error.dart';

/// Bottom sheet con la preparación de un platillo (ingredientes + pasos),
/// pedida a demanda. Se usa igual desde "Hoy" y desde "Semana", cada quien
/// solo pasa cómo pedirla ([cargar]) y qué platillo es.
class DialogoPreparacion {
  static Future<void> mostrar(
    BuildContext context, {
    required String platillo,
    required Future<Result<Preparacion>> Function(String) cargar,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ContenidoPreparacion(platillo: platillo, cargar: cargar),
    );
  }
}

class _ContenidoPreparacion extends StatefulWidget {
  const _ContenidoPreparacion({required this.platillo, required this.cargar});

  final String platillo;
  final Future<Result<Preparacion>> Function(String) cargar;

  @override
  State<_ContenidoPreparacion> createState() => _ContenidoPreparacionState();
}

class _ContenidoPreparacionState extends State<_ContenidoPreparacion> {
  Preparacion? _preparacion;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final resultado = await widget.cargar(widget.platillo);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      switch (resultado) {
        case Ok(:final value):
          _preparacion = value;
        case Error(:final error):
          _error = mensajeDeError(error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.platillo, style: tema.textTheme.titleLarge),
                const SizedBox(height: 16),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null) ...[
                  Text(_error!),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _cargar,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ] else
                  _Preparacion(preparacion: _preparacion!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Preparacion extends StatelessWidget {
  const _Preparacion({required this.preparacion});

  final Preparacion preparacion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final detalle = [
      if (preparacion.tiempoMin != null) '${preparacion.tiempoMin} min',
      if (preparacion.dificultad != null) preparacion.dificultad!,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detalle.isNotEmpty) ...[
          Text(detalle, style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.primary)),
          const SizedBox(height: 16),
        ],
        if (preparacion.ingredientes.isNotEmpty) ...[
          Text('Ingredientes', style: tema.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final ingrediente in preparacion.ingredientes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('•  $ingrediente'),
            ),
          const SizedBox(height: 16),
        ],
        if (preparacion.pasos.isNotEmpty) ...[
          Text('Preparación', style: tema.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final (i, paso) in preparacion.pasos.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${i + 1}. $paso'),
            ),
        ],
      ],
    );
  }
}
