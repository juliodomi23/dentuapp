import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../perfil/widgets/privacidad_screen.dart';

/// Consentimiento expreso para datos sensibles (salud y alimentación).
/// Adaptado de `consent_dialog.dart` de 300 Lugares. Devuelve true si acepta.
class ConsentimientoDialog extends StatelessWidget {
  const ConsentimientoDialog({super.key});

  static Future<bool?> mostrar(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ConsentimientoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Antes de empezar'),
      content: const SingleChildScrollView(
        child: Text(
          '${AppConfig.nombreApp} guarda datos de tu salud y alimentación: lo que comes, '
          'fotos de tus comidas, agua, peso y cómo te sientes. Son datos personales '
          'sensibles.\n\n'
          'Los usamos solo para que tu nutrióloga dé seguimiento a tu plan y se '
          'comparten con tu clínica. Lo que registres por WhatsApp llega al mismo lugar.\n\n'
          'Para usar la app necesitamos tu consentimiento expreso. Puedes borrar tu '
          'cuenta cuando quieras desde Perfil.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PrivacidadScreen()),
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
