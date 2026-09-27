import 'package:flutter/material.dart';

Future<bool> confirmarCerrarSesion(
  BuildContext context, {
  required int pendientes,
  bool personal = false,
}) async {
  final confirma = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Cerrar sesión?'),
      content: Text(
        personal
            ? (pendientes == 0
                  ? 'Puedes volver a entrar con tu correo y contraseña.'
                  : 'Tienes $pendientes registro(s) sin enviar. Si cierras sesión se perderán. Puedes volver a entrar con tu correo y contraseña.')
            : pendientes == 0
            ? 'Para volver a entrar necesitarás un código nuevo de tu clínica.'
            : 'Tienes $pendientes registro(s) sin enviar. Si cierras sesión ahora se '
                  'perderán. Para volver a entrar necesitarás un código nuevo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  return confirma ?? false;
}

Future<bool> confirmarBorrarCuenta(
  BuildContext context, {
  bool personal = false,
}) async {
  final esquema = Theme.of(context).colorScheme;
  final confirma = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Borrar tu cuenta?'),
      content: Text(
        personal
            ? 'Se eliminarán tu cuenta personal, dieta y registros. Esta acción no se puede deshacer.'
            : 'Se borrarán las comidas, fotos, agua, peso y síntomas que registraste desde la '
                  'app. Tu expediente en la clínica y lo que registraste por WhatsApp se conservan.\n\n'
                  'Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: esquema.error,
            foregroundColor: esquema.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Borrar cuenta'),
        ),
      ],
    ),
  );
  return confirma ?? false;
}

/// Pide el peso. `leerPeso` convierte el texto (null si no es válido).
Future<double?> pedirPeso(
  BuildContext context, {
  required String? Function(String?) validar,
  required double? Function(String) leerPeso,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _DialogoPeso(validar: validar, leerPeso: leerPeso),
  );
}

class _DialogoPeso extends StatefulWidget {
  const _DialogoPeso({required this.validar, required this.leerPeso});

  final String? Function(String?) validar;
  final double? Function(String) leerPeso;

  @override
  State<_DialogoPeso> createState() => _DialogoPesoState();
}

class _DialogoPesoState extends State<_DialogoPeso> {
  final _formulario = GlobalKey<FormState>();
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formulario.currentState!.validate()) return;
    Navigator.of(context).pop(widget.leerPeso(_texto.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar mi peso'),
      content: Form(
        key: _formulario,
        child: TextFormField(
          controller: _texto,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Peso de hoy',
            suffixText: 'kg',
          ),
          validator: widget.validar,
          onFieldSubmitted: (_) => _guardar(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
