import 'package:flutter/material.dart';

import '../view_models/perfil_view_model.dart';

/// Sección de solo lectura con los datos del expediente que la clínica comparte.
class MisDatos extends StatelessWidget {
  const MisDatos({super.key, required this.viewModel});

  final PerfilViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    if (!vm.hayDatos) {
      if (vm.cargarDatos.running) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(semanticsLabel: 'Cargando tus datos'),
        );
      }
      return ListTile(
        title: Text(vm.mensajeErrorDatos ?? 'No pudimos cargar tus datos.'),
        trailing: IconButton(
          onPressed: vm.cargarDatos.execute,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Reintentar cargar mis datos',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estos datos los actualiza tu clínica.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _Grupo(titulo: 'Datos personales', filas: vm.datosPersonales),
          _Grupo(titulo: 'Salud', filas: vm.datosSalud),
          if (vm.tituloMedicion != null)
            _Grupo(titulo: vm.tituloMedicion!, filas: vm.datosMedicion),
        ],
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.filas});

  final String titulo;
  final List<FilaDato> filas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(titulo, style: tema.textTheme.titleSmall)),
          const SizedBox(height: 4),
          for (final fila in filas)
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(fila.etiqueta, style: tema.textTheme.bodySmall),
                    ),
                    Expanded(child: Text(fila.valor)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
