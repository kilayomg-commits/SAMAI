import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';

/// Suscripción Premium con Google Play Billing (vía in_app_purchase).
///
/// - Producto: suscripción `samai_premium_mensual`, plan base mensual S/ 10.00
///   con oferta de prueba gratuita configurada en Play Console.
/// - Google Play es la fuente de verdad: al iniciar se consultan las compras
///   activas; si la suscripción venció, Premium se desactiva.
/// - Las compras se reconocen (acknowledge) con completePurchase, requisito de
///   Google Play (si no, se reembolsan a los 3 días).
/// - Cancelación: enlace directo a la gestión de suscripciones de Google Play.
///
/// PRODUCCIÓN: para evitar fraude, validar el purchaseToken en un servidor con
/// la Google Play Developer API (ver docs/ARQUITECTURA.md, fase 2).
class BillingService extends ChangeNotifier {
  BillingService({required this.onPremiumChanged});

  final Future<void> Function(bool active) onPremiumChanged;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  bool busy = false;
  String? error;
  ProductDetails? product;
  bool _entitlementSeen = false;

  String get price => product?.price ?? AppConstants.premiumFallbackPrice;

  Future<void> init() async {
    try {
      available = await _iap.isAvailable();
      if (!available) return;
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) {
          error = 'No se pudo completar la operación con Google Play.';
          busy = false;
          notifyListeners();
        },
      );
      final resp =
          await _iap.queryProductDetails({AppConstants.premiumProductId});
      if (resp.productDetails.isNotEmpty) {
        product = resp.productDetails.first;
      }
      await refreshEntitlement();
    } catch (e) {
      debugPrint('Billing init error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Consulta compras activas. Si Play responde y no hay suscripción vigente,
  /// se desactiva Premium. Si Play no está disponible, se respeta la caché.
  Future<void> refreshEntitlement() async {
    if (!available) return;
    _entitlementSeen = false;
    try {
      await _iap.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!_entitlementSeen) await onPremiumChanged(false);
    } catch (e) {
      debugPrint('restorePurchases error: $e');
    }
  }

  Future<void> buy() async {
    error = null;
    if (!available || product == null) {
      error = 'Google Play no está disponible en este dispositivo o el '
          'producto aún no está publicado.';
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: product!));
    } catch (e) {
      busy = false;
      error = 'No se pudo iniciar la compra.';
      notifyListeners();
    }
  }

  Future<void> restore() async {
    busy = true;
    notifyListeners();
    await refreshEntitlement();
    busy = false;
    notifyListeners();
  }

  Future<void> openManageSubscription() => launchUrl(
        Uri.parse(AppConstants.manageSubscriptionUrl),
        mode: LaunchMode.externalApplication,
      );

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != AppConstants.premiumProductId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          busy = true;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _entitlementSeen = true;
          busy = false;
          await onPremiumChanged(true);
        case PurchaseStatus.error:
          busy = false;
          error = p.error?.message ?? 'Error en la compra.';
        case PurchaseStatus.canceled:
          busy = false;
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
