import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/avisos.dart';
import '../../core/widgets/encabezado_clinica.dart';
import '../view_models/perfil_view_model.dart';
import '../view_models/recordatorios_view_model.dart';
import '../view_models/sintomas_view_model.dart';
import 'dialogos_perfil.dart';
import 'mis_datos.dart';
import 'privacidad_screen.dart';
import 'recordatorios_screen.dart';
import 'sintomas_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key, required this.viewModel});

  final PerfilViewModel viewModel;

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  PerfilViewModel get _vm => widget.viewModel;

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

  void _mostrarAviso() => mostrarAviso(context, _vm.tomarAviso());

  void _abrir(Widget Function(BuildContext context) pantalla) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: pantalla));
  }

  Future<void> _registrarPeso() async {
    final peso = await pedirPeso(context, validar: _vm.validarPeso, leerPeso: _vm.leerPeso);
    if (peso != null) _vm.registrarPeso.execute(peso);
  }

  Future<void> _cerrarSesion() async {
    final confirma = await confirmarCerrarSesion(context, pendientes: _vm.pendientesSinEnviar);
    if (confirma) _vm.cerrarSesion.execute();
  }

  Future<void> _borrarCuenta() async {
    if (await confirmarBorrarCuenta(context)) _vm.borrarCuenta.execute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _vm,
          _vm.cargarDatos,
          _vm.cerrarSesion,
          _vm.borrarCuenta,
        ]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (_vm.ocupado) const LinearProgressIndicator(semanticsLabel: 'Procesando'),
            _encabezado(context),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.mood_rounded),
              title: const Text('¿Cómo te sientes?'),
              subtitle: const Text('Energía, digestión, hambre, sueño y ánimo'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _abrir(
                (context) => SintomasScreen(
                  viewModel: SintomasViewModel(perfil: context.read()),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.monitor_weight_rounded),
              title: const Text('Registrar mi peso'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _registrarPeso,
            ),
            ListTile(
              leading: const Icon(Icons.notifications_rounded),
              title: const Text('Recordatorios'),
              subtitle: const Text('Comidas y agua'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _abrir(
                (context) => RecordatoriosScreen(
                  viewModel: RecordatoriosViewModel(recordatorios: context.read()),
                ),
              ),
            ),
            const Divider(),
            const _TituloSeccion('Mis datos'),
            MisDatos(viewModel: _vm),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip_rounded),
              title: const Text('Aviso de privacidad'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _abrir((_) => const PrivacidadScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Cerrar sesión'),
              enabled: !_vm.ocupado,
              onTap: _cerrarSesion,
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_rounded, color: Theme.of(context).colorScheme.error),
              title: Text(
                'Borrar cuenta',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              enabled: !_vm.ocupado,
              onTap: _borrarCuenta,
            ),
          ],
        ),
      ),
    );
  }

  Widget _encabezado(BuildContext context) {
    final paciente = _vm.paciente;
    if (paciente == null) return const SizedBox.shrink();
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EncabezadoClinica(clinica: paciente.clinica),
          const SizedBox(height: 16),
          Text(paciente.nombreCompleto, style: tema.textTheme.titleLarge),
          if (paciente.objetivo != null) Text('Objetivo: ${paciente.objetivo}'),
        ],
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Semantics(
        header: true,
        child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
