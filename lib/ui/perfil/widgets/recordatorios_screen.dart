import 'package:flutter/material.dart';

import '../../../data/models/ajustes_recordatorios.dart';
import '../../core/widgets/avisos.dart';
import '../view_models/recordatorios_view_model.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key, required this.viewModel});

  final RecordatoriosViewModel viewModel;

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  RecordatoriosViewModel get _vm => widget.viewModel;

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

  Future<void> _elegirHora(String tiempo, HoraDelDia actual) async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: actual.hora, minute: actual.minuto),
      helpText: 'Hora del recordatorio',
    );
    if (elegida != null) {
      _vm.cambiarHorario(tiempo, HoraDelDia(elegida.hour, elegida.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios')),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final ajustes = _vm.ajustes;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Los recordatorios llegan aunque no tengas internet.'),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.restaurant_rounded),
                title: const Text('Recordatorios de comidas'),
                value: ajustes.comidasActivas,
                onChanged: _vm.cambiarComidasActivas,
              ),
              if (ajustes.comidasActivas)
                for (final tiempo in _vm.tiempos)
                  ListTile(
                    leading: Icon(_vm.iconoTiempo(tiempo)),
                    title: Text(_vm.nombreTiempo(tiempo)),
                    trailing: Text(ajustes.horarios[tiempo]!.texto),
                    onTap: () => _elegirHora(tiempo, ajustes.horarios[tiempo]!),
                  ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.water_drop_rounded),
                title: const Text('Recordatorios de agua'),
                subtitle: Text(_vm.textoHorasAgua),
                value: ajustes.aguaActiva,
                onChanged: _vm.cambiarAguaActiva,
              ),
              if (ajustes.aguaActiva)
                ListTile(
                  title: const Text('Cada cuánto'),
                  trailing: DropdownButton<int>(
                    value: ajustes.aguaCadaHoras,
                    items: [
                      for (final horas in AjustesRecordatorios.opcionesAguaCadaHoras)
                        DropdownMenuItem(
                          value: horas,
                          child: Text(horas == 1 ? 'Cada hora' : 'Cada $horas horas'),
                        ),
                    ],
                    onChanged: (horas) {
                      if (horas != null) _vm.cambiarAguaCadaHoras(horas);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
