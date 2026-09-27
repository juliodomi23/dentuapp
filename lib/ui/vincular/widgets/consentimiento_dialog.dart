import 'package:flutter/material.dart';

import '../../perfil/widgets/privacidad_screen.dart';

class ConsentimientoDialog extends StatelessWidget {
  const ConsentimientoDialog({super.key, this.personal = false});

  final bool personal;

  static Future<bool?> mostrar(BuildContext context, {bool personal = false}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConsentimientoDialog(personal: personal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Antes de empezar'),
      content: SingleChildScrollView(
        child: Text(
          personal
              ? 'Dentu guarda tu correo, dieta y los datos de alimentación y salud que registres para mostrarte tu seguimiento. Si importas un PDF o imágenes, enviamos esos archivos temporalmente a nuestro proveedor de inteligencia artificial para transcribirlos. Revisa y corrige el resultado antes de activarlo. Tu cuenta personal no crea un expediente en la clínica ni incluye consulta profesional. Puedes borrarla desde Perfil.'
              : 'Dentu guarda datos de tu salud y alimentación: lo que comes, fotos de tus comidas, agua, peso y cómo te sientes. Los usamos para que tu nutrióloga dé seguimiento a tu plan y se comparten con tu clínica. Lo que registres por WhatsApp llega al mismo lugar. Puedes borrar tu cuenta desde Perfil.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PrivacidadScreen(personal: personal),
            ),
          ),
          child: const Text('Ver aviso de privacidad'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No acepto'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Acepto'),
        ),
      ],
    );
  }
}
