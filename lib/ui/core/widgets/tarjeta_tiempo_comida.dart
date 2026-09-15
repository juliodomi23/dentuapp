import 'package:flutter/material.dart';

import '../../../config/constantes.dart';
import '../../../config/tema.dart';
import '../../../data/models/dia.dart';
import '../../../data/models/registro_comida.dart';
import 'foto_comida.dart';
import 'microinteracciones.dart';

/// Un tiempo de comida del día: lo planeado, cómo le fue y sus acciones.
class TarjetaTiempoComida extends StatelessWidget {
  const TarjetaTiempoComida({
    super.key,
    required this.tiempoDia,
    required this.puedeRegistrar,
    required this.ocupado,
    required this.onRegistrar,
    required this.onDeshacer,
    required this.onAgregarFoto,
    this.esEquivalentes = false,
    this.urlFoto,
    this.cabecerasFoto = const {},
    this.onVerPreparacion,
  });

  final TiempoDia tiempoDia;
  final bool puedeRegistrar;
  final bool ocupado;
  final bool esEquivalentes;
  final ValueChanged<String> onRegistrar;
  final VoidCallback onDeshacer;
  final VoidCallback onAgregarFoto;
  final String? urlFoto;
  final Map<String, String> cabecerasFoto;

  /// Null si no hay un platillo real que explicar (plan vacío o equivalentes).
  final VoidCallback? onVerPreparacion;

  String get _nombre => kNombreTiempo[tiempoDia.tiempo] ?? tiempoDia.tiempo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final registro = tiempoDia.registro;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: _colorEstado(registro?.estado, esquema), width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(kIconoTiempo[tiempoDia.tiempo] ?? Icons.restaurant_rounded, color: esquema.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _nombre,
                      style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: registro == null
                        ? const SizedBox.shrink(key: ValueKey('sin-estado'))
                        : _EtiquetaEstado(key: ValueKey(registro.estado), estado: registro.estado),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(_textoPlaneado(), style: tema.textTheme.bodyMedium)),
                  if (onVerPreparacion != null)
                    InkWell(
                      onTap: onVerPreparacion,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.menu_book_rounded, size: 20, color: esquema.primary),
                      ),
                    ),
                ],
              ),
              if (registro?.estado == EstadoComida.cambio && registro?.queComio != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '→ "${registro!.queComio}"',
                    style: tema.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              if (registro != null && registro.pendiente) _AvisoPendiente(registro: registro),
              if (urlFoto != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: FotoComida(
                    url: urlFoto!,
                    cabeceras: cabecerasFoto,
                    tamano: 96,
                    descripcion: 'Foto de tu ${_nombre.toLowerCase()}',
                  ),
                ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey('$ocupado-${registro?.estado}-$puedeRegistrar'),
                  child: _acciones(registro),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Color del acento izquierdo según cómo le fue al paciente en este
  /// tiempo de comida; transparente si todavía no registra nada.
  Color _colorEstado(String? estado, ColorScheme esquema) => switch (estado) {
    EstadoComida.cumplido => ColoresDentu.verde,
    EstadoComida.cambio => ColoresDentu.dorado,
    EstadoComida.omitido => esquema.outlineVariant,
    _ => Colors.transparent,
  };

  String _textoPlaneado() {
    if (tiempoDia.planeado.isNotEmpty) return tiempoDia.planeado;
    if (esEquivalentes) return 'Arma tu comida con tus equivalentes.';
    return 'Sin platillo en tu plan.';
  }

  Widget _acciones(RegistroComida? registro) {
    if (ocupado) return const LinearProgressIndicator(semanticsLabel: 'Guardando');
    if (registro == null) {
      return puedeRegistrar ? _BotonesEstado(onRegistrar: onRegistrar) : const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (puedeRegistrar)
          ReaccionToque(
            haptico: false,
            builder: (context, envolver) => IconButton(
              onPressed: envolver(onAgregarFoto),
              icon: const Icon(Icons.add_a_photo_rounded),
              tooltip: registro.tieneFoto ? 'Cambiar foto de $_nombre' : 'Agregar foto de $_nombre',
            ),
          ),
        if (puedeRegistrar || registro.pendiente)
          ReaccionToque(
            builder: (context, envolver) => TextButton.icon(
              onPressed: envolver(onDeshacer),
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Deshacer'),
            ),
          ),
      ],
    );
  }
}

class _EtiquetaEstado extends StatelessWidget {
  const _EtiquetaEstado({super.key, required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final esCumplido = estado == EstadoComida.cumplido;
    final color = esCumplido ? esquema.primary : esquema.onSurfaceVariant;
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kIconoEstado[estado] ?? Icons.check_circle_rounded, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            kTextoEstado[estado] ?? estado,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _BotonesEstado extends StatelessWidget {
  const _BotonesEstado({required this.onRegistrar});

  final ValueChanged<String> onRegistrar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ReaccionToque(
          builder: (context, envolver) => FilledButton.tonalIcon(
            onPressed: envolver(() => onRegistrar(EstadoComida.cumplido)),
            icon: Icon(kIconoEstado[EstadoComida.cumplido]),
            label: Text(kTextoEstado[EstadoComida.cumplido]!),
          ),
        ),
        ReaccionToque(
          builder: (context, envolver) => OutlinedButton.icon(
            onPressed: envolver(() => onRegistrar(EstadoComida.cambio)),
            icon: Icon(kIconoEstado[EstadoComida.cambio]),
            label: Text(kTextoEstado[EstadoComida.cambio]!),
          ),
        ),
        ReaccionToque(
          builder: (context, envolver) => OutlinedButton.icon(
            onPressed: envolver(() => onRegistrar(EstadoComida.omitido)),
            icon: Icon(kIconoEstado[EstadoComida.omitido]),
            label: Text(kTextoEstado[EstadoComida.omitido]!),
          ),
        ),
      ],
    );
  }
}

class _AvisoPendiente extends StatelessWidget {
  const _AvisoPendiente({required this.registro});

  final RegistroComida registro;

  @override
  Widget build(BuildContext context) {
    final error = registro.errorEnvio;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 18, color: ColoresDentu.pendiente),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              error == null ? 'Pendiente de enviar' : 'No se pudo enviar: $error',
              style: const TextStyle(color: ColoresDentu.pendiente),
            ),
          ),
        ],
      ),
    );
  }
}
