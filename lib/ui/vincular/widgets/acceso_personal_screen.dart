import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/diario_repository.dart';
import '../../../utils/result.dart';
import '../../core/mensaje_error.dart';

class AccesoPersonalScreen extends StatefulWidget {
  const AccesoPersonalScreen({super.key, required this.onVolver});

  final VoidCallback onVolver;

  @override
  State<AccesoPersonalScreen> createState() => _AccesoPersonalScreenState();
}

class _AccesoPersonalScreenState extends State<AccesoPersonalScreen> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _crear = true;
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final auth = context.read<AuthRepository>();
    final diario = context.read<DiarioRepository>();
    final resultado = _crear
        ? await auth.crearCuentaPersonal(
            nombre: _nombre.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          )
        : await auth.entrarCuentaPersonal(
            email: _email.text.trim(),
            password: _password.text,
          );
    if (resultado is Ok && auth.cambioDePaciente) {
      await diario.descartarPendientes();
    }
    if (!mounted) return;
    if (resultado case Error(:final error)) {
      setState(() {
        _ocupado = false;
        _error = mensajeDeError(error);
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_crear ? 'Crear cuenta personal' : 'Entrar a mi cuenta'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Sigue tu propia dieta',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sube el plan que te dio tu profesional de salud y lleva tus comidas en la app.',
            ),
            const SizedBox(height: 24),
            Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_crear) ...[
                    TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Tu nombre'),
                      validator: (v) => (v?.trim().length ?? 0) >= 2
                          ? null
                          : 'Escribe tu nombre.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                    validator: (v) => (v?.contains('@') ?? false)
                        ? null
                        : 'Escribe un correo válido.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: [
                      _crear
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (v) => (v?.length ?? 0) >= 8
                        ? null
                        : 'Usa al menos 8 caracteres.',
                    onFieldSubmitted: (_) => _enviar(),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: _ocupado ? null : _enviar,
                    child: _ocupado
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_crear ? 'Crear cuenta' : 'Entrar'),
                  ),
                  TextButton(
                    onPressed: _ocupado
                        ? null
                        : () => setState(() {
                            _crear = !_crear;
                            _error = null;
                          }),
                    child: Text(
                      _crear ? 'Ya tengo cuenta' : 'Crear una cuenta',
                    ),
                  ),
                  TextButton(
                    onPressed: _ocupado ? null : widget.onVolver,
                    child: const Text('Volver a opciones de acceso'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
