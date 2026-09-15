import 'package:flutter/material.dart';

import '../../core/widgets/estados.dart';
import '../view_models/progreso_view_model.dart';
import 'cuadricula_fotos.dart';
import 'grafica_peso.dart';
import 'sintomas_promedio.dart';
import 'tarjeta_racha.dart';
import 'tarjeta_resumen.dart';

class ProgresoScreen extends StatelessWidget {
  const ProgresoScreen({super.key, required this.viewModel});

  final ProgresoViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      body: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.cargar]),
        builder: (context, _) => _contenido(context),
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    final vm = viewModel;
    if (vm.progreso == null) {
      if (vm.cargar.running) return const EstadoCargando();
      final error = vm.mensajeErrorCarga;
      if (error != null) return EstadoError(mensaje: error, onReintentar: vm.cargar.execute);
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: vm.cargar.execute,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(vm.textoPeriodo, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          TarjetaRacha(dias: vm.diasRacha, esHito: vm.esRachaHito),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TarjetaResumen(
                  icono: Icons.flag_rounded,
                  titulo: 'Apego al plan',
                  valor: vm.textoApego,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TarjetaResumen(
                  icono: Icons.water_drop_rounded,
                  titulo: 'Agua promedio',
                  valor: vm.textoAgua,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TarjetaResumen(
                  icono: Icons.calendar_today_rounded,
                  titulo: 'Días registrados',
                  valor: vm.textoDiasRegistrados,
                ),
              ),
            ],
          ),
          _Seccion(
            titulo: 'Peso',
            child: GraficaPeso(
              puntos: vm.puntosPeso,
              etiquetaEjeX: vm.etiquetaEjeX,
              resumen: vm.textoCambioPeso,
            ),
          ),
          _Seccion(titulo: '¿Cómo te has sentido?', child: SintomasPromedio(sintomas: vm.sintomas)),
          _Seccion(
            titulo: 'Tus fotos',
            child: CuadriculaFotos(
              fotos: vm.fotos,
              urlFoto: vm.urlFoto,
              cabeceras: vm.cabecerasFoto(),
              descripcion: vm.descripcionFoto,
            ),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
