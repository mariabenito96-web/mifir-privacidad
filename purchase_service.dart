import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ID de la suscripción anual que desbloquea todo el contenido Premium.
/// Tiene que coincidir EXACTAMENTE con el ID de la suscripción que crees en
/// Play Console → Monetizar → Productos → Suscripciones.
/// Ver la guía paso a paso en el README.
const String kPremiumProductId = 'mifir_premium_anual';

/// Convocatorias oficiales que están disponibles gratis en "Practicar por
/// año" y en "Test aleatorio general". El resto de años (y las preguntas
/// no oficiales, y el examen simulacro) requieren la suscripción Premium.
const Set<int> kFreeYears = {2024, 2025};

/// Asignaturas disponibles gratis en "Practicar por asignatura". El resto
/// de asignaturas requieren la suscripción Premium.
const Set<String> kFreeSubjects = {
  'Técnicas Instrumentales',
  'Química Farmacéutica',
};

const String _kPremiumPrefsKey = 'is_premium_unlocked';

/// Tiempo que esperamos a que Google Play conteste al restaurar compras
/// antes de dar por hecho que no hay ninguna suscripción activa.
const Duration _kRestoreTimeout = Duration(seconds: 10);

/// Gestiona la suscripción anual "Premium" (desbloquea todas las
/// convocatorias, todas las asignaturas, las preguntas no oficiales, el
/// examen simulacro, repasar falladas y el ranking online).
///
/// Cómo se decide si alguien es Premium:
/// - Al arrancar la app se pide a Google Play la lista de compras activas.
///   Si aparece una suscripción activa, se concede Premium.
/// - Si Google Play responde y NO hay suscripción activa (por ejemplo
///   porque caducó o se canceló), se revoca el Premium guardado.
/// - Si no hay conexión o la tienda no responde, se mantiene el último
///   estado conocido, para que la app siga usable sin internet. Se
///   revisará de nuevo la próxima vez que haya conexión.
///
/// Nota: esta comprobación es solo local (no hay verificación de recibo en
/// un servidor propio). Es razonable para una app pequeña, pero si más
/// adelante quieres blindarla del todo, lo ideal sería verificar el estado
/// de la suscripción desde un backend con la API de Google Play Developer.
class PurchaseService extends ChangeNotifier {
  PurchaseService._internal();
  static final PurchaseService instance = PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  SharedPreferences? _prefs;
  Timer? _restoreTimer;

  bool _premium = false;
  bool _storeAvailable = false;
  bool _loading = false;
  bool _sawActiveSubscription = false;
  ProductDetails? _product;

  bool get isPremium => _premium;
  bool get storeAvailable => _storeAvailable;
  bool get loading => _loading;
  ProductDetails? get product => _product;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _premium = _prefs?.getBool(_kPremiumPrefsKey) ?? false;

    try {
      _storeAvailable = await _iap.isAvailable();
    } catch (_) {
      _storeAvailable = false;
    }
    if (!_storeAvailable) return;

    _sub = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (_) {});

    try {
      final response = await _iap.queryProductDetails({kPremiumProductId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        notifyListeners();
      }
    } catch (_) {
      // Sin conexión o tienda no disponible todavía; se reintentará la
      // próxima vez que se abra la app.
    }

    // Comprueba si la suscripción sigue activa. Las compras activas llegan
    // por purchaseStream con estado "restored".
    _verifySubscription();
  }

  /// Pregunta a Google Play por las compras activas. Si pasado
  /// [_kRestoreTimeout] no ha llegado ninguna suscripción activa, se
  /// entiende que ya no la hay y se revoca el Premium.
  void _verifySubscription() {
    _sawActiveSubscription = false;
    _restoreTimer?.cancel();
    _restoreTimer = Timer(_kRestoreTimeout, () {
      if (!_sawActiveSubscription && _premium) {
        _revoke();
      }
    });
    _iap.restorePurchases().catchError((_) {
      // Si falla (sin conexión, por ejemplo), no revocamos nada: se
      // mantiene el último estado conocido.
      _restoreTimer?.cancel();
    });
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> buy() async {
    if (_product == null) return;
    _loading = true;
    notifyListeners();
    final param = PurchaseParam(productDetails: _product!);
    // En Android las suscripciones también se compran con buyNonConsumable.
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    _loading = true;
    notifyListeners();
    _verifySubscription();
    // Quita el indicador de carga aunque no llegue nada.
    Timer(_kRestoreTimeout, () {
      if (_loading) {
        _loading = false;
        notifyListeners();
      }
    });
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != kPremiumProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _sawActiveSubscription = true;
          _restoreTimer?.cancel();
          await _grant();
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _loading = false;
          notifyListeners();
          break;
        case PurchaseStatus.pending:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _grant() async {
    _premium = true;
    _loading = false;
    await _prefs?.setBool(_kPremiumPrefsKey, true);
    notifyListeners();
  }

  Future<void> _revoke() async {
    _premium = false;
    _loading = false;
    await _prefs?.setBool(_kPremiumPrefsKey, false);
    notifyListeners();
  }
}
