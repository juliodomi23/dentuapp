import 'package:flutter/material.dart';

import '../../../data/models/progreso.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/foto_comida.dart';

class CuadriculaFotos extends StatelessWidget {
  const CuadriculaFotos({
    super.key,
    required this.fotos,
    required this.urlFoto,
    required this.cabeceras,
    required this.descripcion,
  });

  final List<FotoProgreso> fotos;
  final String Function(String fotoId) urlFoto;
  final Map<String, String> cabeceras;
  final String Function(FotoProgreso foto) descripcion;

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) {
      return const EstadoVacio(
        icono: Icons.photo_camera_rounded,
        ilustracion: IlustracionVacio.fotos,
        titulo: 'Todavía no tienes fotos',
        mensaje: 'Agrega una desde "Hoy" para llevar tu registro visual.',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fotos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, indice) {
        final foto = fotos[indice];
        final texto = descripcion(foto);
        return InkWell(
          onTap: () => _verFoto(context, foto, texto),
          child: FotoComida(url: urlFoto(foto.id), cabeceras: cabeceras, descripcion: texto),
        );
      },
    );
  }

  void _verFoto(BuildContext context, FotoProgreso foto, String texto) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: FotoComida(url: urlFoto(foto.id), cabeceras: cabeceras, descripcion: texto),
            ),
            Padding(padding: const EdgeInsets.all(12), child: Text(texto)),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          ],
        ),
      ),
    );
  }
}
