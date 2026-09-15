import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/tema.dart';

/// Muestra una foto de comida desde el backend (con token), desde el teléfono
/// (`file://`, fotos pendientes de enviar) o un ejemplo (`mock://`, modo demo).
class FotoComida extends StatelessWidget {
  const FotoComida({
    super.key,
    required this.url,
    this.cabeceras = const {},
    this.tamano,
    this.descripcion,
  });

  final String url;
  final Map<String, String> cabeceras;
  final double? tamano;
  final String? descripcion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: descripcion ?? 'Foto de comida',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: tamano, height: tamano, child: _imagen(context)),
      ),
    );
  }

  Widget _imagen(BuildContext context) {
    if (url.startsWith('file://')) {
      return Image.file(
        File(url.substring('file://'.length)),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _FotoNoDisponible(),
      );
    }
    if (url.startsWith('mock://')) return const _FotoDeEjemplo();
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: cabeceras,
      fit: BoxFit.cover,
      placeholder: (context, _) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      errorWidget: (_, _, _) => const _FotoNoDisponible(),
    );
  }
}

class _FotoDeEjemplo extends StatelessWidget {
  const _FotoDeEjemplo();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColoresDentu.dorado.withValues(alpha: 0.25),
      child: const Center(
        child: Icon(Icons.restaurant_rounded, size: 36, color: ColoresDentu.dorado),
      ),
    );
  }
}

class _FotoNoDisponible extends StatelessWidget {
  const _FotoNoDisponible();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.broken_image_rounded)),
    );
  }
}
