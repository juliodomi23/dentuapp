import 'package:flutter/material.dart';

class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key, this.personal = false});

  final bool personal;

  @override
  Widget build(BuildContext context) {
    final secciones = personal ? _personal : _clinica;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (titulo, texto) in secciones) ...[
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(texto),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

const _personal = <(String, String)>[
  (
    'Cuenta personal',
    'Dentu guarda tu nombre, correo y contraseña protegida para darte acceso a tu plan. Tu cuenta personal es independiente del expediente de la clínica.',
  ),
  (
    'Datos de seguimiento',
    'Guardamos tu plan semanal y los registros que añadas de comidas, fotos, agua, ejercicio, peso y síntomas para mostrarlos en la app.',
  ),
  (
    'Importar una dieta',
    'Los PDF o imágenes que selecciones se envían temporalmente a nuestro proveedor de inteligencia artificial para extraer el texto de tu dieta. Dentu guarda el plan que confirmas, no el archivo original. Revisa el borrador antes de usarlo.',
  ),
  (
    'Funciones con IA',
    'Si solicitas lista de compra o preparación de un platillo, compartimos el contenido del plan o el nombre del platillo con el servicio que genera la respuesta.',
  ),
  (
    'Borrar tu cuenta',
    'Desde Perfil puedes eliminar tu cuenta personal, el plan y los datos que registraste en la app. La eliminación es permanente.',
  ),
];

const _clinica = <(String, String)>[
  (
    'Datos de salud',
    'La app guarda las comidas, fotos, agua, ejercicio, peso y síntomas que registras para dar seguimiento a tu plan.',
  ),
  (
    'Tu clínica',
    'Los registros de la app y WhatsApp se reúnen en tu expediente de la clínica. Tu nutrióloga puede verlos durante el seguimiento.',
  ),
  (
    'Funciones con IA',
    'Si solicitas lista de compra o preparación de un platillo, compartimos el contenido del plan o el nombre del platillo con el servicio que genera la respuesta.',
  ),
  (
    'Borrar datos de la app',
    'Desde Perfil puedes borrar lo que registraste en la app. El expediente clínico y lo registrado por WhatsApp permanecen con tu clínica.',
  ),
];
