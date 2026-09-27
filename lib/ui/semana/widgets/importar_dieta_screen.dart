import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../config/constantes.dart';
import '../../../data/repositories/plan_repository.dart';
import '../../../utils/result.dart';
import '../../core/mensaje_error.dart';

class ImportarDietaScreen extends StatefulWidget {
  const ImportarDietaScreen({super.key});

  @override
  State<ImportarDietaScreen> createState() => _ImportarDietaScreenState();
}

class _ImportarDietaScreenState extends State<ImportarDietaScreen> {
  final _nombre = TextEditingController();
  final _notas = TextEditingController();
  final _archivos = <String>[];
  Map<String, dynamic>? _borrador;
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _notas.dispose();
    super.dispose();
  }

  void _agregarArchivos(List<String> rutas) {
    if (rutas.isEmpty) return;
    setState(() {
      _archivos.addAll(rutas);
      if (_archivos.length > 5) _archivos.removeRange(5, _archivos.length);
      _error = null;
    });
  }

  Future<void> _elegirDocumentos() async {
    try {
      final resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
          'heif',
        ],
      );
      if (!mounted) return;
      _agregarArchivos(
        resultado.map((f) => f.path).whereType<String>().toList(),
      );
    } on PlatformException {
      if (mounted) {
        setState(() => _error = 'No se pudo abrir el selector de archivos.');
      }
    }
  }

  Future<void> _elegirFotos() async {
    try {
      final fotos = await ImagePicker().pickMultiImage();
      if (mounted) _agregarArchivos(fotos.map((f) => f.path).toList());
    } on PlatformException {
      if (mounted) {
        setState(() => _error = 'No se pudieron seleccionar las fotos.');
      }
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final foto = await ImagePicker().pickImage(source: ImageSource.camera);
      if (mounted && foto != null) _agregarArchivos([foto.path]);
    } on PlatformException {
      if (mounted) setState(() => _error = 'No se pudo abrir la cámara.');
    }
  }

  Future<void> _extraer() async {
    if (_archivos.isEmpty) {
      setState(() => _error = 'Selecciona al menos un PDF o imagen.');
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final resultado = await context.read<PlanRepository>().extraerDieta(
      _archivos,
    );
    if (!mounted) return;
    switch (resultado) {
      case Ok(:final value):
        _borrador = value;
        _nombre.text = value['nombre'] as String? ?? 'Mi dieta';
        _notas.text = value['notas'] as String? ?? '';
      case Error(:final error):
        _error = mensajeDeError(error);
    }
    setState(() => _ocupado = false);
  }

  Future<void> _guardar() async {
    final borrador = _borrador;
    if (borrador == null) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final resultado = await context
        .read<PlanRepository>()
        .guardarDietaPersonal({
          'nombre': _nombre.text.trim(),
          'notas': _notas.text.trim(),
          'dias': borrador['dias'],
        });
    if (!mounted) return;
    switch (resultado) {
      case Ok():
        Navigator.of(context).pop(true);
      case Error(:final error):
        setState(() {
          _ocupado = false;
          _error = mensajeDeError(error);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar mi dieta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Sube hasta 5 archivos PDF o imágenes. Se leen para crear un borrador semanal; comprueba cada comida antes de guardarlo.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Tu dieta viene de otro profesional. Dentu no la prescribe ni la modifica automáticamente.',
          ),
          const SizedBox(height: 20),
          if (_borrador == null) ...[
            OutlinedButton.icon(
              onPressed: _ocupado ? null : _elegirDocumentos,
              icon: const Icon(Icons.attach_file),
              label: const Text('Elegir PDF o imágenes'),
            ),
            OutlinedButton.icon(
              onPressed: _ocupado ? null : _elegirFotos,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Elegir fotos'),
            ),
            OutlinedButton.icon(
              onPressed: _ocupado ? null : _tomarFoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Tomar foto'),
            ),
            for (var i = 0; i < _archivos.length; i++)
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(_archivos[i].split(RegExp(r'[/\\]')).last),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Quitar archivo',
                  onPressed: _ocupado
                      ? null
                      : () => setState(() => _archivos.removeAt(i)),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _ocupado ? null : _extraer,
              child: const Text('Leer mi dieta'),
            ),
          ] else ...[
            Text(
              'Revisa el borrador',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Corrige cualquier texto ilegible. Los días vacíos quedan sin comidas; puedes completarlos aquí.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombre,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Nombre del plan'),
            ),
            TextField(
              controller: _notas,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Indicaciones generales',
              ),
            ),
            for (final dia in kDiasSemana) _editorDia(dia),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _ocupado ? null : _guardar,
              child: const Text('Guardar y usar este plan'),
            ),
            TextButton(
              onPressed: _ocupado
                  ? null
                  : () => setState(() => _borrador = null),
              child: const Text('Elegir otros archivos'),
            ),
          ],
          if (_ocupado)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _editorDia(String dia) {
    final dias = _borrador!['dias'] as Map<String, dynamic>;
    final comidas = dias[dia] as Map<String, dynamic>;
    return Card(
      child: ExpansionTile(
        title: Text(kNombreDia[dia] ?? dia),
        subtitle: Text(
          '${comidas.values.where((v) => (v as String).trim().isNotEmpty).length} comidas',
        ),
        children: [
          for (final tiempo in kTiempos)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextFormField(
                key: ValueKey('$dia-$tiempo'),
                initialValue: comidas[tiempo] as String? ?? '',
                maxLines: 2,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: kNombreTiempo[tiempo] ?? tiempo,
                ),
                onChanged: (texto) => comidas[tiempo] = texto,
              ),
            ),
        ],
      ),
    );
  }
}
