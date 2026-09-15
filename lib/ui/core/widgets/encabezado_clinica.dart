import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/models/paciente_app.dart';

/// Logo y nombre de la clínica. El tema de la app es fijo (no usa `color_primario`).
class EncabezadoClinica extends StatelessWidget {
  const EncabezadoClinica({super.key, required this.clinica, this.tamanoLogo = 56});

  final Clinica clinica;
  final double tamanoLogo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Semantics(
          image: true,
          label: 'Logo de ${clinica.nombre}',
          child: ExcludeSemantics(child: _logo(tema)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clinica.nombre,
                style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (clinica.telefono != null)
                Text('Tel. ${clinica.telefono}', style: tema.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logo(ThemeData tema) {
    final inicial = Text(
      clinica.nombre.isEmpty ? '?' : clinica.nombre[0].toUpperCase(),
      style: TextStyle(
        color: tema.colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
        fontSize: tamanoLogo * 0.4,
      ),
    );
    return CircleAvatar(
      radius: tamanoLogo / 2,
      backgroundColor: tema.colorScheme.primary,
      child: clinica.logoUrl == null
          ? inicial
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: clinica.logoUrl!,
                width: tamanoLogo,
                height: tamanoLogo,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Center(child: inicial),
              ),
            ),
    );
  }
}
