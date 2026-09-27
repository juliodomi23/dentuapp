import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/iap_repository.dart';

class SuscripcionImportacionScreen extends StatefulWidget {
  const SuscripcionImportacionScreen({super.key});

  @override
  State<SuscripcionImportacionScreen> createState() =>
      _SuscripcionImportacionScreenState();
}

class _SuscripcionImportacionScreenState
    extends State<SuscripcionImportacionScreen> {
  late final IapRepository _iap;

  @override
  void initState() {
    super.initState();
    _iap = context.read<IapRepository>()..addListener(_alCambiar);
  }

  void _alCambiar() {
    if (_iap.activo && mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _iap.removeListener(_alCambiar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar mi dieta')),
      body: ListenableBuilder(
        listenable: _iap,
        builder: (context, _) {
          final producto = _iap.producto;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.document_scanner_outlined, size: 72),
              const SizedBox(height: 20),
              Text(
                producto?.title ?? 'Dentu Personal',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Importa dietas en PDF o foto, revisa el borrador y organiza tu plan semanal.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: producto == null || _iap.ocupado
                    ? null
                    : _iap.comprar,
                child: Text(
                  producto == null
                      ? 'Suscripción no disponible'
                      : 'Suscribirme por ${producto.price} al mes',
                ),
              ),
              TextButton(
                onPressed: _iap.ocupado ? null : _iap.restaurar,
                child: const Text('Restaurar compras'),
              ),
              const SizedBox(height: 12),
              const Text(
                'El pago se cargará a tu cuenta de Apple. La suscripción se renueva automáticamente cada mes, salvo que la canceles al menos 24 horas antes de terminar el periodo actual. Puedes administrarla o cancelarla desde la configuración de suscripciones de tu cuenta de Apple.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              if (_iap.ocupado)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_iap.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _iap.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
