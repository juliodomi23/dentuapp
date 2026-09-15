import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/constantes.dart';
import '../../../data/models/plan.dart';
import '../../../data/repositories/diario_repository.dart';
import '../../../data/repositories/plan_repository.dart';
import '../../core/widgets/avisos.dart';
import '../../core/widgets/dialogo_preparacion.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/lista_equivalentes.dart';
import '../view_models/lista_compra_view_model.dart';
import '../view_models/semana_view_model.dart';
import 'dialogo_mover_menu.dart';
import 'lista_compra_screen.dart';
import 'tarjeta_dia_plan.dart';

class SemanaScreen extends StatefulWidget {
  const SemanaScreen({super.key, required this.viewModel});

  final SemanaViewModel viewModel;

  @override
  State<SemanaScreen> createState() => _SemanaScreenState();
}

class _SemanaScreenState extends State<SemanaScreen> {
  SemanaViewModel get _vm => widget.viewModel;

  String? _diaOrigenResaltado;
  String? _diaDestinoResaltado;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_alCambiarVm);
  }

  @override
  void dispose() {
    _vm.removeListener(_alCambiarVm);
    super.dispose();
  }

  void _alCambiarVm() {
    mostrarAviso(context, _vm.tomarAviso());

    final intercambio = _vm.tomarUltimoIntercambio();
    if (intercambio == null) return;

    // Resalta un instante las dos tarjetas que se acaban de intercambiar en
    // vez de que el cambio se vea de golpe; `TarjetaDiaPlan` se encarga de
    // desvanecer el resalte sola una vez que detecta el flanco (ver
    // `didUpdateWidget` en `tarjeta_dia_plan.dart`), así que aquí basta con
    // dejarlo "prendido" el tiempo justo para que se alcance a pintar.
    setState(() {
      _diaOrigenResaltado = intercambio.diaOrigen;
      _diaDestinoResaltado = intercambio.diaDestino;
    });
    Future.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      setState(() {
        _diaOrigenResaltado = null;
        _diaDestinoResaltado = null;
      });
    });
  }

  Future<void> _mover(String diaOrigen) async {
    final destino = await DialogoMoverMenu.mostrar(
      context,
      diaOrigen: diaOrigen,
      opciones: _vm.otrosDias(diaOrigen),
    );
    if (destino == null) return;
    _vm.moverMenu.execute((diaOrigen: diaOrigen, diaDestino: destino));
  }

  void _verPreparacion(String platillo) {
    DialogoPreparacion.mostrar(
      context,
      platillo: platillo,
      cargar: context.read<DiarioRepository>().obtenerPreparacion,
    );
  }

  void _abrirListaCompra() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ListaCompraScreen(
          viewModel: ListaCompraViewModel(plan: context.read<PlanRepository>()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi semana'),
        actions: [
          ListenableBuilder(
            listenable: _vm,
            builder: (context, _) {
              final plan = _vm.plan;
              if (plan == null || plan.esEquivalentes) return const SizedBox.shrink();
              return IconButton(
                onPressed: _abrirListaCompra,
                icon: const Icon(Icons.shopping_cart_rounded),
                tooltip: 'Lista de compra',
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_vm, _vm.cargar, _vm.moverMenu]),
        builder: (context, _) => _contenido(),
      ),
    );
  }

  Widget _contenido() {
    final plan = _vm.plan;
    if (plan == null) {
      if (_vm.cargar.running) return const EstadoCargando();
      final error = _vm.mensajeErrorCarga;
      if (error != null) return EstadoError(mensaje: error, onReintentar: _vm.cargar.execute);
      if (_vm.sinPlan) {
        return const EstadoVacio(
          icono: Icons.calendar_view_week_rounded,
          ilustracion: IlustracionVacio.semana,
          titulo: 'Tu semana está por armarse',
          mensaje: 'Aquí verás tu semana completa en cuanto tu nutrióloga arme tu primer plan.',
        );
      }
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: _vm.cargar.execute,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _EncabezadoPlan(plan: plan),
          if (_vm.moverMenu.running) const LinearProgressIndicator(semanticsLabel: 'Moviendo menú'),
          if (plan.esEquivalentes)
            ListaEquivalentes(equivalentes: plan.equivalentes)
          else
            for (final dia in _vm.dias)
              TarjetaDiaPlan(
                nombreDia: kNombreDia[dia]!,
                abreviatura: kAbreviaturaDia[dia]!,
                comidas: plan.comidasDe(dia),
                esHoy: dia == _vm.diaDeHoy,
                habilitado: !_vm.moverMenu.running,
                onMover: () => _mover(dia),
                onVerPreparacion: _verPreparacion,
                resaltado: dia == _diaOrigenResaltado || dia == _diaDestinoResaltado,
              ),
        ],
      ),
    );
  }
}

class _EncabezadoPlan extends StatelessWidget {
  const _EncabezadoPlan({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.nombre, style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (plan.esEquivalentes)
              const Text('Tu plan es por equivalentes: arma tus comidas con estas porciones.'),
            if (plan.notas != null) ...[
              const SizedBox(height: 8),
              Text(plan.notas!),
            ],
          ],
        ),
      ),
    );
  }
}
