import 'package:flutter/material.dart';

import '../../core/widgets/estados.dart';
import '../view_models/lista_compra_view_model.dart';

/// Lista de compra aproximada, armada con IA a partir del plan de la semana.
/// Es un estimado para agilizar el súper, no una receta exacta ni sustituye
/// las cantidades que indique la nutrióloga.
class ListaCompraScreen extends StatelessWidget {
  const ListaCompraScreen({super.key, required this.viewModel});

  final ListaCompraViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de compra')),
      body: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.generar]),
        builder: (context, _) {
          if (viewModel.generar.running) return const EstadoCargando();

          final error = viewModel.mensajeError;
          if (error != null) {
            return EstadoError(mensaje: error, onReintentar: viewModel.generar.execute);
          }

          final lista = viewModel.lista;
          if (lista == null || lista.categorias.isEmpty) {
            return const EstadoVacio(
              icono: Icons.shopping_cart_rounded,
              titulo: 'No pudimos armar tu lista',
              mensaje: 'Intenta de nuevo en un momento.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Aproximada para una semana. Ajusta las cantidades a tu gusto.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              for (final categoria in lista.categorias)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(categoria.nombre, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        for (final item in categoria.items) _ItemCompra(texto: item),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemCompra extends StatefulWidget {
  const _ItemCompra({required this.texto});

  final String texto;

  @override
  State<_ItemCompra> createState() => _ItemCompraState();
}

class _ItemCompraState extends State<_ItemCompra> {
  bool _marcado = false;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: _marcado,
      onChanged: (valor) => setState(() => _marcado = valor ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        widget.texto,
        style: _marcado
            ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
            : null,
      ),
    );
  }
}
