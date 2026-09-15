import 'package:flutter/material.dart';

import '../../../config/app_config.dart';

/// Aviso de privacidad simplificado, conforme a la LFPDPPP (México), para
/// datos de salud recabados por la app y por WhatsApp. Redactado a partir de
/// lo que la app realmente hace (ver `contrato-api-ecosistema.md` del
/// proyecto); no sustituye una revisión por un abogado antes de publicar la
/// app en producción o en las tiendas.
class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key});

  static const _secciones = [
    (
      titulo: 'Responsable',
      texto: 'La clínica con la que vinculaste tu app es responsable del tratamiento de tus '
          'datos personales, conforme a la Ley Federal de Protección de Datos Personales en '
          'Posesión de los Particulares (LFPDPPP).',
    ),
    (
      titulo: 'Datos que recabamos',
      texto: 'Nombre, teléfono y datos de salud y alimentación: comidas registradas, fotos de '
          'comidas, agua, peso, medidas y cómo te sientes. Son datos personales sensibles y los '
          'tratamos con medidas de seguridad adicionales.',
    ),
    (
      titulo: 'Para qué los usamos',
      texto: 'Para que tu nutrióloga dé seguimiento a tu plan, para mostrarte tu progreso dentro '
          'de la app y para recordarte tus citas y registros pendientes.',
    ),
    (
      titulo: 'Con quién se comparten',
      texto: 'No vendemos ni compartimos tus datos con terceros para fines de mercadotecnia. '
          'Cuando pides la lista de compra o la preparación de un platillo, el nombre del '
          'platillo (nunca tu nombre, tu foto ni tus datos de salud) se envía a un proveedor de '
          'inteligencia artificial para generar esa respuesta.',
    ),
    (
      titulo: 'Canales',
      texto: 'Puedes registrar desde la app ${AppConfig.nombreApp} o por WhatsApp. '
          'Todo se guarda en el mismo expediente de tu clínica, sin importar el canal.',
    ),
    (
      titulo: 'Tus derechos (ARCO)',
      texto: 'Puedes pedir Acceso, Rectificación, Cancelación u Oposición al tratamiento de tus '
          'datos, así como revocar tu consentimiento, contactando directamente a tu clínica.',
    ),
    (
      titulo: 'Borrar tu cuenta',
      texto: 'Desde Perfil puedes borrar lo que registraste desde la app en cualquier momento. '
          'Tu expediente clínico y lo que registraste por WhatsApp se conservan, porque son '
          'parte de tu historial médico con la clínica.',
    ),
    (
      titulo: 'Cambios a este aviso',
      texto: 'Si actualizamos este aviso, te lo notificaremos dentro de la app antes de que '
          'entre en vigor.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de privacidad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final seccion in _secciones) ...[
            Semantics(
              header: true,
              child: Text(seccion.titulo, style: tema.textTheme.titleMedium),
            ),
            const SizedBox(height: 4),
            Text(seccion.texto),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
