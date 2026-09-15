import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_config.dart';
import '../../../data/models/paciente_app.dart';
import '../../core/widgets/encabezado_clinica.dart';
import '../view_models/vincular_view_model.dart';
import 'consentimiento_dialog.dart';

class VincularScreen extends StatefulWidget {
  const VincularScreen({super.key, required this.viewModel});

  final VincularViewModel viewModel;

  @override
  State<VincularScreen> createState() => _VincularScreenState();
}

class _VincularScreenState extends State<VincularScreen> {
  final _formulario = GlobalKey<FormState>();
  final _telefono = TextEditingController();
  final _codigo = TextEditingController();

  VincularViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_vm.debePreguntarConsentimiento) _abrirConsentimiento();
    });
  }

  @override
  void dispose() {
    _telefono.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _abrirConsentimiento() async {
    final acepta = await ConsentimientoDialog.mostrar(context);
    if (acepta != null) await _vm.responderConsentimiento(acepta);
  }

  void _enviar() {
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _vm.vincular.execute((telefono: _telefono.text, codigo: _codigo.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_vm, _vm.vincular]),
          builder: (context, _) {
            final paciente = _vm.pacienteVinculado;
            if (paciente != null) {
              return _Confirmacion(paciente: paciente, onContinuar: _vm.continuar);
            }
            return _formularioVista(context);
          },
        ),
      ),
    );
  }

  Widget _formularioVista(BuildContext context) {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Text(
          AppConfig.nombreApp,
          style: tema.textTheme.displaySmall?.copyWith(
            color: tema.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text('Tu seguimiento nutricional', style: tema.textTheme.titleMedium),
        const SizedBox(height: 24),
        if (_vm.sesionExpirada)
          const _Aviso(
            texto: 'Tu sesión terminó. Pide un nuevo código a tu clínica para volver a entrar.',
          ),
        if (_vm.consentimientoAceptado)
          _formularioVinculacion(tema)
        else
          _SinConsentimiento(onRevisar: _abrirConsentimiento),
      ],
    );
  }

  Widget _formularioVinculacion(ThemeData tema) {
    final cargando = _vm.vincular.running;
    return Form(
      key: _formulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Tu teléfono',
              hintText: '10 dígitos',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
            validator: _vm.validarTelefono,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codigo,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'Código de 6 dígitos',
              prefixIcon: Icon(Icons.lock_outline_rounded),
              helperText: 'Pídelo a tu clínica por WhatsApp: escribe "quiero la app".',
              helperMaxLines: 2,
            ),
            validator: _vm.validarCodigo,
            onFieldSubmitted: (_) => _enviar(),
          ),
          const SizedBox(height: 16),
          if (_vm.mensajeError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_vm.mensajeError!, style: TextStyle(color: tema.colorScheme.error)),
            ),
          FilledButton(
            onPressed: cargando ? null : _enviar,
            child: cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Vinculando'),
                  )
                : const Text('Vincular mi app'),
          ),
        ],
      ),
    );
  }
}

class _SinConsentimiento extends StatelessWidget {
  const _SinConsentimiento({required this.onRevisar});

  final VoidCallback onRevisar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Para usar la app necesitamos tu consentimiento para guardar tus datos de '
          'salud y alimentación.',
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRevisar, child: const Text('Revisar de nuevo')),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esquema.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(texto, style: TextStyle(color: esquema.onErrorContainer)),
    );
  }
}

class _Confirmacion extends StatelessWidget {
  const _Confirmacion({required this.paciente, required this.onContinuar});

  final PacienteApp paciente;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        EncabezadoClinica(clinica: paciente.clinica, tamanoLogo: 72),
        const SizedBox(height: 32),
        Text('¡Listo, ${paciente.nombre}!', style: tema.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Tu app quedó vinculada con ${paciente.clinica.nombre}. Aquí vas a ver tu '
          'plan y registrar tus comidas.',
        ),
        const SizedBox(height: 32),
        FilledButton(onPressed: onContinuar, child: const Text('Continuar')),
      ],
    );
  }
}
