/// Tüm API anahtar ve uç nokta sabitlerini barındırır.
///
/// ⚠️  Bu dosyayı .gitignore'a ekleyerek gerçek anahtarlarınızın
///     version control'e gitmesini engelleyin.
class ApiConstants {
  ApiConstants._();

  // ─────────────────────────────────────────
  //  Google Maps & Places
  // ─────────────────────────────────────────

  /// Google Maps SDK (Android/iOS/Web) ve Places API anahtarı.
  /// https://console.cloud.google.com/ → Credentials → API Key
  /// Etkinleştirilmesi gereken API'lar:
  ///   • Maps SDK for Android
  ///   • Maps SDK for iOS
  ///   • Maps JavaScript API
  ///   • Places API
  ///   • Geocoding API
  static const String googleApiKey = 'AIzaSyC3FadTCaMeWDCFocu0ihbIIRHhCT7UQoQ';

  static const String placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';
  static const String nearbySearchEndpoint =
      '$placesBaseUrl/nearbysearch/json';
  static const String placeDetailsEndpoint = '$placesBaseUrl/details/json';
  static const String geocodingBaseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  // ─────────────────────────────────────────
  //  NosyAPI — Nöbetçi Eczane
  //  https://nosyapi.com/docs/pharmacy
  // ─────────────────────────────────────────

  /// NosyAPI anahtarı. https://nosyapi.com adresinden ücretsiz alın.
  static const String nosyApiKey = 'YOUR_NOSY_API_KEY';

  static const String nosyApiPharmacyUrl =
      'https://nosyapi.com/apiv2/service/pharmacies-on-duty';

  // ─────────────────────────────────────────
  //  CollectAPI — Nöbetçi Eczane (Alternatif)
  //  https://collectapi.com/api/health
  // ─────────────────────────────────────────

  /// CollectAPI anahtarı. https://collectapi.com adresinden alın.
  static const String collectApiKey = '0h6sNpPyHzZm8tSuszcdD9:7pHNgfnkOcTjW54VMXnfmO';

  static const String collectApiPharmacyUrl =
      'https://api.collectapi.com/health/dutyPharmacy';

  // ─────────────────────────────────────────
  //  Arama Parametreleri
  // ─────────────────────────────────────────

  /// Varsayılan yakın çevre arama yarıçapı (metre)
  static const int defaultSearchRadius = 2000;

  /// Maksimum arama yarıçapı (metre)
  static const int maxSearchRadius = 25000;

  // ─────────────────────────────────────────
  //  API Sağlık Kontrolü
  // ─────────────────────────────────────────

  /// Google API anahtarı girilmiş mi?
  static bool get hasGoogleKey =>
      googleApiKey.isNotEmpty && googleApiKey != 'YOUR_GOOGLE_API_KEY';

  /// Herhangi bir eczane API anahtarı mevcut mu?
  static bool get hasPharmacyApiKey =>
      (nosyApiKey.isNotEmpty && nosyApiKey != 'YOUR_NOSY_API_KEY') ||
      (collectApiKey.isNotEmpty && collectApiKey != 'YOUR_COLLECT_API_KEY');
}
