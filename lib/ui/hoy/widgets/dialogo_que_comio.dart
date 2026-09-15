import 'package:flutter/material.dart';

import '../../../config/constantes.dart';

/// Pide qué comió en lugar de lo planeado. Devuelve el texto o null si cancela.
class DialogoQueComio extends StatefulWidget {
  const DialogoQueComio({super.key, required this.planeado});

  final String planeado;

  static Future<String?> mostrar(BuildContext context, {required String planeado}) {
    return showDialog<String>(
      context: context,
      builder: (_) => DialogoQueComio(planeado: planeado),
    );
  }

  @override
  State<DialogoQueComio> createState() => _DialogoQueComioState();
}

class _DialogoQueComioState extends State<DialogoQueComio> {
  final _texto = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _guardar() {
    final texto = _texto.text.trim();
    if (texto.isEmpty) {
      setState(() => _error = 'Escribe qué comiste.');
      return;
    }
    Navigator.of(context).pop(texto);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lo cambié'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.planeado.isNotEmpty)
            Text('En tu plan: ${widget.planeado}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _texto,
            autofocus: true,
            maxLength: LimitesRegistro.queComioMax,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: '¿Qué comiste en su lugar?',
              hintText: 'Ej. unos tacos de guisado',
              errorText: _error,
            ),
            onSubmitted: (_) => _guardar(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
