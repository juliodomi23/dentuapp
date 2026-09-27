import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../config/constantes.dart';
import '../../../config/tema.dart';
import '../../../data/models/dia.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/diario_repository.dart';
import '../../core/widgets/avisos.dart';
import '../../core/widgets/dialogo_preparacion.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/lista_equivalentes.dart';
import '../../core/widgets/microinteracciones.dart';
import '../../core/widgets/tarjeta_tiempo_comida.dart';
import '../view_models/hoy_view_model.dart';
import 'barra_reto.dart';
import 'circulo_resumen_dia.dart';
import 'contador_agua.dart';
import 'dialogo_que_comio.dart';
import 'ejercicio_detalle_screen.dart';
import 'objetivo_dia.dart';
import 'selector_dia.dart';
import 'tarjeta_ejercicio.dart';

class HoyScreen extends StatefulWidget {
  const HoyScreen({super.key, required this.viewModel});

  final HoyViewModel viewModel;

  @override
  State<HoyScreen> createState() => _HoyScreenState();
}

class _HoyScreenState extends State<HoyScreen> {
  HoyViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_mostrarAviso);
  }

  @override
  void dispose() {
    _vm.removeListener(_mostrarAviso);
    super.dispose();
  }

  void _mostrarAviso() {
    final aviso = _vm.tomarAviso();
    if (aviso != null) mostrarAviso(context, aviso);

    final celebracion = _vm.tomarCelebracion();
    if (celebracion != null) {
      mostrarCelebracion(
        context,
        icono: celebracion.icono,
        mensaje: celebracion.mensaje,
      );
    }
  }

  Future<void> _registrar(TiempoDia tiempoDia, String estado) async {
    String? queComio;
    if (estado == EstadoComida.cambio) {
      queComio = await DialogoQueComio.mostrar(
        context,
        planeado: tiempoDia.planeado,
      );
      if (queComio == null) return;
    }
    _vm.registrarComida.execute((
      tiempo: tiempoDia.tiempo,
      estado: estado,
      queComio: queComio,
      fotoPath: null,
    ));
  }

  Future<void> _agregarFoto(TiempoDia tiempoDia) async {
    final registro = tiempoDia.registro;
    if (registro == null) return;
    final origen = await _elegirOrigenFoto();
    if (origen == null) return;

    try {
      final foto = await ImagePicker().pickImage(
        source: origen,
        maxWidth: 1080,
        imageQuality: 70,
      );
      if (foto == null) return;
      _vm.registrarComida.execute((
        tiempo: tiempoDia.tiempo,
        estado: registro.estado,
        queComio: registro.queComio,
        fotoPath: foto.path,
      ));
    } on PlatformException {
      if (mounted) {
        mostrarAviso(
          context,
          'No pudimos abrir la cámara o la galería. Revisa los permisos.',
        );
      }
    }
  }

  Future<ImageSource?> _elegirOrigenFoto() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _verPreparacion(String platillo) {
    DialogoPreparacion.mostrar(
      context,
      platillo: platillo,
      cargar: context.read<DiarioRepository>().obtenerPreparacion,
    );
  }

  void _abrirEjercicio() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EjercicioDetalleScreen(viewModel: _vm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoy')),
      body: ListenableBuilder(
        listenable: Listenable.merge([_vm, _vm.cargarDia]),
        builder: (context, _) => RefreshIndicator(
          onRefresh: _vm.cargarDia.execute,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SelectorDia(
                titulo: _vm.tituloFecha,
                subtitulo: _vm.subtituloFecha,
                esHoy: _vm.esHoy,
                onAnterior: _vm.irDiaAnterior,
                onSiguiente: _vm.irDiaSiguiente,
                onHoy: _vm.irAHoy,
              ),
              ..._contenido(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contenido() {
    final dia = _vm.dia;
    if (dia == null) {
      if (_vm.cargarDia.running) return const [EstadoCargando()];
      final error = _vm.mensajeErrorCarga;
      if (error != null) {
        return [
          EstadoError(mensaje: error, onReintentar: _vm.cargarDia.execute),
        ];
      }
      return const [];
    }

    final textoObjetivo = _vm.textoObjetivoDia;
    final textoSoloLectura = _vm.textoSoloLectura();
    final textoPlanVacio =
        context.read<AuthRepository>().paciente?.esPersonal == true &&
            !dia.tienePlan
        ? 'Abre Semana para importar el PDF o las fotos de tu dieta.'
        : _vm.textoPlanVacio();
    final (comidasHechas, comidasTotal) = _vm.progresoComidas;
    final (vasos, metaAgua) = _vm.progresoAgua;
    final progresoReto = _vm.progresoReto;
    return [
      if (_vm.cargarDia.running)
        const LinearProgressIndicator(semanticsLabel: 'Actualizando'),
      if (comidasTotal > 0 || vasos > 0 || progresoReto != null) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: CirculoResumenDia(
              anillos: [
                if (comidasTotal > 0)
                  AnilloResumen(
                    color: ColoresDentu.verde,
                    valor: comidasHechas / comidasTotal,
                    etiqueta: 'Comidas · $comidasHechas/$comidasTotal',
                  ),
                AnilloResumen(
                  color: ColoresDentu.dorado,
                  valor: vasos / metaAgua,
                  etiqueta: 'Agua · $vasos/$metaAgua vasos',
                ),
                if (progresoReto != null)
                  AnilloResumen(
                    color: ColoresDentu.terracota,
                    valor: progresoReto.$1 / progresoReto.$2,
                    etiqueta: 'Reto 21 · día ${progresoReto.$1}',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (textoObjetivo != null) ...[
        ObjetivoDia(texto: textoObjetivo),
        const SizedBox(height: 8),
      ],
      ContadorAgua(
        vasos: dia.aguaVasos,
        pendiente: dia.aguaPendiente,
        habilitado: dia.puedeRegistrar,
        onSumar: _vm.sumarAgua,
        onRestar: _vm.restarAgua,
      ),
      TarjetaEjercicio(
        minutos: dia.ejercicioMin,
        tipo: dia.ejercicioTipo,
        pendiente: dia.ejercicioPendiente,
        habilitado: dia.puedeRegistrar,
        onAbrirDetalle: _abrirEjercicio,
      ),
      if (dia.reto21Dia != null) BarraReto(dia: dia.reto21Dia!),
      if (textoSoloLectura != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(textoSoloLectura, textAlign: TextAlign.center),
        ),
      if (textoPlanVacio != null)
        EstadoVacio(
          icono: Icons.restaurant_menu_rounded,
          ilustracion: IlustracionVacio.plan,
          titulo: 'Sin plan todavía',
          mensaje: textoPlanVacio,
        )
      else ...[
        if (dia.esEquivalentes && _vm.equivalentes.isNotEmpty)
          ListaEquivalentes(equivalentes: _vm.equivalentes),
        for (final tiempoDia in dia.tiempos)
          TarjetaTiempoComida(
            tiempoDia: tiempoDia,
            puedeRegistrar: dia.puedeRegistrar,
            esEquivalentes: dia.esEquivalentes,
            ocupado: _vm.tiempoEnProceso == tiempoDia.tiempo,
            urlFoto: tiempoDia.registro == null
                ? null
                : _vm.urlFotoDe(tiempoDia.registro!),
            cabecerasFoto: _vm.cabecerasFoto(),
            onRegistrar: (estado) => _registrar(tiempoDia, estado),
            onDeshacer: () => _vm.deshacerRegistro.execute(tiempoDia.tiempo),
            onAgregarFoto: () => _agregarFoto(tiempoDia),
            onVerPreparacion: tiempoDia.planeado.isEmpty
                ? null
                : () => _verPreparacion(tiempoDia.planeado),
          ),
      ],
    ];
  }
}
