import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../config/app_config.dart';
import '../../utils/result.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';

class IapRepository extends ChangeNotifier {
  IapRepository({required ApiService api}) : _api = api;

  final ApiService _api;
  final InAppPurchase _tienda = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _suscripcion;

  bool requerido = false;
  bool activo = false;
  bool tiendaDisponible = false;
  bool ocupado = false;
  ProductDetails? producto;
  String? error;

  Future<bool> preparar() async {
    ocupado = true;
    error = null;
    notifyListeners();
    final estado = await _api.consultarIap();
    if (estado case Error(:final error)) {
      this.error = _mensaje(error);
      ocupado = false;
      notifyListeners();
      return false;
    }
    _aplicarEstado((estado as Ok<Map<String, dynamic>>).value);
    if (!requerido || activo) {
      ocupado = false;
      notifyListeners();
      return true;
    }
    if (!Platform.isIOS) {
      error = 'La suscripción está disponible por ahora solo en iPhone.';
      ocupado = false;
      notifyListeners();
      return false;
    }
    _suscripcion ??= _tienda.purchaseStream.listen(
      _procesarCompras,
      onError: (_) {
        error = 'No se pudo consultar la compra.';
        ocupado = false;
        notifyListeners();
      },
    );
    tiendaDisponible = await _tienda.isAvailable();
    if (!tiendaDisponible) {
      error = 'App Store no está disponible en este momento.';
    } else {
      final respuesta = await _tienda.queryProductDetails({
        AppConfig.iapProductId,
      });
      producto = respuesta.productDetails.firstOrNull;
      if (respuesta.error != null || producto == null) {
        error = 'La suscripción todavía no está disponible en App Store.';
      }
    }
    ocupado = false;
    notifyListeners();
    return activo;
  }

  Future<void> comprar() async {
    final producto = this.producto;
    if (producto == null || ocupado) return;
    ocupado = true;
    error = null;
    notifyListeners();
    final iniciada = await _tienda.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: producto),
    );
    if (!iniciada) {
      ocupado = false;
      error = 'No se pudo iniciar la compra.';
      notifyListeners();
    }
  }

  Future<void> restaurar() async {
    if (ocupado) return;
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      await _tienda.restorePurchases();
    } catch (_) {
      ocupado = false;
      error = 'No se pudieron restaurar las compras.';
      notifyListeners();
    }
  }

  Future<void> _procesarCompras(List<PurchaseDetails> compras) async {
    for (final compra in compras.where(
      (item) => item.productID == AppConfig.iapProductId,
    )) {
      if (compra.status == PurchaseStatus.pending) {
        ocupado = true;
        notifyListeners();
        continue;
      }
      if (compra.status == PurchaseStatus.error) {
        ocupado = false;
        error = compra.error?.message ?? 'La compra no se pudo completar.';
        notifyListeners();
        continue;
      }
      if (compra.status == PurchaseStatus.canceled) {
        ocupado = false;
        notifyListeners();
        continue;
      }
      final validacion = await _api.validarCompraApple(
        compra.verificationData.serverVerificationData,
      );
      if (validacion case Ok(:final value)) {
        _aplicarEstado(value);
        error = null;
        if (compra.pendingCompletePurchase) {
          await _tienda.completePurchase(compra);
        }
      } else if (validacion case Error(:final error)) {
        this.error = _mensaje(error);
      }
      ocupado = false;
      notifyListeners();
    }
  }

  void _aplicarEstado(Map<String, dynamic> json) {
    requerido = json['requerido'] as bool? ?? false;
    activo = json['activo'] as bool? ?? false;
  }

  String _mensaje(Exception exception) => switch (exception) {
    ApiException(:final mensaje) => mensaje,
    _ => 'No se pudo comprobar la suscripción.',
  };

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}
