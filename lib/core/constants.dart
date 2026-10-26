/// Constantes globales de SAMAI.
class AppConstants {
  static const appName = 'SAMAI';

  /// Versión del texto de consentimiento / política. Si cambia, se vuelve a
  /// pedir consentimiento al usuario.
  static const consentVersion = '1.0';

  /// Umbral de ansiedad (0-10) desde el cual se activa el protocolo de ayuda.
  static const crisisAnxietyThreshold = 9;

  /// Tiempo en segundo plano tras el cual se vuelve a pedir PIN/biometría.
  static const relockAfter = Duration(seconds: 30);

  /// Duraciones disponibles para los ejercicios (minutos).
  static const durations = [2, 5, 10];

  // ---- Google Play Billing ----
  /// ID del producto de suscripción creado en Play Console.
  static const premiumProductId = 'samai_premium_mensual';
  static const premiumFallbackPrice = 'S/ 10.00';

  /// Debe coincidir con la oferta de prueba configurada en Play Console.
  static const trialDays = 7;

  /// Nombre del paquete (applicationId) — debe coincidir con android/app/build.gradle.kts
  static const packageName = 'pe.samai.samai';

  static String get manageSubscriptionUrl =>
      'https://play.google.com/store/account/subscriptions?sku=$premiumProductId&package=$packageName';

  /// Número de ejercicios gratuitos.
  static const freeExerciseCount = 3;
}

/// Líneas de ayuda en Perú. Verificar vigencia antes de cada publicación.
class CrisisLines {
  /// Línea 113 Salud (MINSA), opción 5: salud mental, gratuita, 24 h.
  static const minsa = '113';
  static const minsaWhatsapp = '51952842623';
  static const samu = '106';
  static const policia = '105';
  static const bomberos = '116';
}
