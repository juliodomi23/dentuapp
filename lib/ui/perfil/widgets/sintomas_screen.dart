import 'package:flutter/material.dart';

import '../../../config/constantes.dart';
import '../../core/widgets/avisos.dart';
import '../../core/widgets/selector_caritas.dart';
import '../view_models/sintomas_view_model.dart';

class SintomasScreen extends StatefulWidget {
  const SintomasScreen({super.key, required this.viewModel});

  final SintomasViewModel viewModel;

  @override
  State<SintomasScreen> createState() => _SintomasScreenState();
}

class _SintomasScreenState extends State<SintomasScreen> {
  SintomasViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_alCambiar);
  }

  @override
  void dispose() {
    _vm.removeListener(_alCambiar);
    super.dispose();
  }

  void _alCambiar() {
    mostrarAviso(context, _vm.tomarAviso());
    if (_vm.guardar.completed && mounted) {
      _vm.guardar.clearResult();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('¿Cómo te sientes?')),
      body: ListenableBuilder(
        listenable: Listenable.merge([_vm, _vm.guardar]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Califica cómo estás hoy, del 1 al 5. Llena solo lo que quieras.'),
            for (final metrica in _vm.metricas.entries)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SelectorCaritas(
                  etiqueta: metrica.value,
                  valor: _vm.valorDe(metrica.key),
                  onCambio: (valor) => _vm.seleccionar(metrica.key, valor),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              onChanged: _vm.cambiarNotas,
              maxLength: LimitesRegistro.notaMax,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _vm.puedeGuardar && !_vm.guardar.running ? _vm.guardar.execute : null,
              child: _vm.guardar.running
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Guardando'),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
