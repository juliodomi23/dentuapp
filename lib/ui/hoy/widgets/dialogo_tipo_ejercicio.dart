import 'package:flutter/material.dart';

import '../../../config/constantes.dart';

/// Pide el tipo de ejercicio (texto libre, opcional). Devuelve el texto, ''
/// para borrarlo, o null si cancela.
class DialogoTipoEjercicio extends StatefulWidget {
  const DialogoTipoEjercicio({super.key, this.tipoActual});

  final String? tipoActual;

  static Future<String?> mostrar(BuildContext context, {String? tipoActual}) {
    return showDialog<String>(
      context: context,
      builder: (_) => DialogoTipoEjercicio(tipoActual: tipoActual),
    );
  }

  @override
  State<DialogoTipoEjercicio> createState() => _DialogoTipoEjercicioState();
}

class _DialogoTipoEjercicioState extends State<DialogoTipoEjercicio> {
  late final _texto = TextEditingController(text: widget.tipoActual);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Qué ejercicio hiciste?'),
      content: TextField(
        controller: _texto,
        autofocus: true,
        maxLength: LimitesRegistro.ejercicioTipoMax,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Ej. caminata, gym'),
        onSubmitted: (texto) => Navigator.of(context).pop(texto.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_texto.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
