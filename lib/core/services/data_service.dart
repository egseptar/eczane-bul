import '../../models/place_model.dart';
import '../../data/dummy_data.dart';
import '../constants/api_constants.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/duty_pharmacy_service.dart';

/// Uygulama genelinde veri yönetimini koordine eden ana servis katmanı.
///
/// Sorumlulukları:
///   1. Kullanıcı konumunu al
///   2. Nöbetçi eczaneleri ve hastaneleri gerçek API'lardan çek
///   3. API/internet hatası varsa dummy veriye düş (fallback)
///   4. Tüm listeyi tek bir [DataResult] nesnesi olarak sun
class DataService {
  DataService._();
  static final DataService _instance = DataService._();
  static DataService get instance => _instance;

  // ─────────────────────────────────────────
  //  Ana Veri Yükleme
  // ─────────────────────────────────────────

  /// Uygulamanın ana veri yükleme akışı.
  /// Gerçek API → başarısız → dummy fallback.
  Future<DataResult> loadAllData() async {
    // 1. Kullanıcı konumunu al
    double userLat = LocationService.defaultLat;
    double userLng = LocationService.defaultLng;
    String city = 'İstanbul';
    String district = 'Kadıköy';
    bool locationObtained = false;

    try {
      final position = await LocationService.instance.getCurrentPosition();
      userLat = position.latitude;
      userLng = position.longitude;
      locationObtained = true;

      // Gerçek ters coğrafi kodlama (Reverse Geocoding)
      final addr = await LocationService.instance.getAddressFromCoordinates(userLat, userLng);
      if (!addr.isUnknown) {
        if (addr.city.isNotEmpty) {
          city = addr.city
              .replaceAll('Province', '')
              .replaceAll('İli', '')
              .replaceAll('Büyükşehir', '')
              .trim();
        }
        if (addr.district.isNotEmpty) {
          district = addr.district;
        }
      } else {
        final resolved = _resolveCity(userLat, userLng);
        city = resolved.$1;
        district = resolved.$2;
      }
    } catch (_) {
      // Konum alınamadı — varsayılan konum ile devam et
    }

    // 2. Gerçek API çağrıları (paralel)
    bool usedFallback = false;
    List<PlaceModel> pharmacies = [];
    List<PlaceModel> hospitals = [];

    try {
      final results = await Future.wait([
        _fetchPharmacies(city: city, district: district, lat: userLat, lng: userLng),
        _fetchHospitals(lat: userLat, lng: userLng),
      ]).timeout(const Duration(seconds: 12));

      pharmacies = results[0];
      hospitals = results[1];

      // Hastaneler boş döndüyse (Google Places API kısıtlaması vb.) hazır hastane verilerini yükle
      if (hospitals.isEmpty) {
        hospitals = DummyData.hospitals;
      }

      // Canlı eczane verisi çekilemediyse hazır eczane verilerine düş ve uyarı ver
      if (pharmacies.isEmpty) {
        usedFallback = true;
        pharmacies = DummyData.pharmacies;
      }
    } catch (_) {
      // Timeout veya ağ hatası — fallback verileri yükle
      usedFallback = true;
      if (pharmacies.isEmpty) pharmacies = DummyData.pharmacies;
      if (hospitals.isEmpty) hospitals = DummyData.hospitals;
    }

    // 3. Mesafeleri hesapla ve sırala
    pharmacies = _calculateDistances(pharmacies, userLat, userLng);
    hospitals = _calculateDistances(hospitals, userLat, userLng);

    return DataResult(
      pharmacies: pharmacies,
      hospitals: hospitals,
      userLat: userLat,
      userLng: userLng,
      locationObtained: locationObtained,
      usedFallback: usedFallback,
      isBusinessHours: isBusinessHours(),
    );
  }

  // ─────────────────────────────────────────
  //  Zaman ve Mesai Kontrolü
  // ─────────────────────────────────────────

  /// Cihaz saatini kontrol eder.
  /// Mesai Saatleri: Pazartesi - Cumartesi 08:30 - 19:00.
  /// Mesai Dışı: Hafta içi/Cumartesi 19:00 - 08:30 ve Pazar tüm gün.
  static bool isBusinessHours([DateTime? time]) {
    final now = time ?? DateTime.now();
    final weekday = now.weekday;

    if (weekday == DateTime.sunday) {
      return false;
    }

    final totalMinutes = now.hour * 60 + now.minute;
    const startMinutes = 8 * 60 + 30; // 08:30 -> 510 dk
    const endMinutes = 19 * 60;        // 19:00 -> 1140 dk

    return totalMinutes >= startMinutes && totalMinutes < endMinutes;
  }

  // ─────────────────────────────────────────
  //  Nöbetçi / Açık Eczane Yönlendirmesi
  // ─────────────────────────────────────────

  Future<List<PlaceModel>> _fetchPharmacies({
    required String city,
    required String district,
    required double lat,
    required double lng,
  }) async {
    final isWorkingHours = isBusinessHours();

    if (isWorkingHours) {
      // Mesai Saatleri İçinde: Google Places API'ye istek at (opennow=true)
      if (ApiConstants.hasGoogleKey) {
        final googlePharmacies = await PlacesService.instance.getNearbyPharmacies(
          latitude: lat,
          longitude: lng,
        );
        if (googlePharmacies.isNotEmpty) return googlePharmacies;
      }

      // Fallback: CollectAPI / NosyAPI
      if (ApiConstants.hasPharmacyApiKey) {
        return DutyPharmacyService.instance.getDutyPharmacies(
          city: city,
          district: district,
        );
      }
    } else {
      // Mesai Dışı Saatlerde: Google API'yi yoksay, CollectAPI Nöbetçi Eczane uç noktasına git
      if (ApiConstants.hasPharmacyApiKey) {
        final dutyPharmacies = await DutyPharmacyService.instance.getDutyPharmacies(
          city: city,
          district: district,
        );
        if (dutyPharmacies.isNotEmpty) return dutyPharmacies;
      }

      // Fallback: Google Places
      if (ApiConstants.hasGoogleKey) {
        return PlacesService.instance.getNearbyPharmacies(
          latitude: lat,
          longitude: lng,
        );
      }
    }

    return [];
  }

  // ─────────────────────────────────────────
  //  Hastane Çekme
  // ─────────────────────────────────────────

  Future<List<PlaceModel>> _fetchHospitals({
    required double lat,
    required double lng,
  }) async {
    if (!ApiConstants.hasGoogleKey) return [];
    return PlacesService.instance.getNearbyHospitals(
      latitude: lat,
      longitude: lng,
      radius: ApiConstants.maxSearchRadius,
    );
  }

  // ─────────────────────────────────────────
  //  Mesafe Hesaplama & Sıralama
  // ─────────────────────────────────────────

  List<PlaceModel> _calculateDistances(
    List<PlaceModel> places,
    double userLat,
    double userLng,
  ) {
    final updated = places.map((p) {
      final meters = LocationService.instance.distanceBetween(
        startLat: userLat,
        startLng: userLng,
        endLat: p.latitude,
        endLng: p.longitude,
      );
      return p.copyWith(distanceKm: meters / 1000);
    }).toList();

    updated.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return updated;
  }

  // ─────────────────────────────────────────
  //  Şehir/İlçe Çözümleme (Kutu Yöntemi)
  // ─────────────────────────────────────────

  /// Koordinata göre büyük şehirleri tespit eder.
  /// Gerçek uygulamada Reverse Geocoding kullanılmalıdır.
  (String, String) _resolveCity(double lat, double lng) {
    if (lat >= 40.8 && lat <= 41.2 && lng >= 28.5 && lng <= 29.5) {
      // İstanbul
      if (lng < 29.0) return ('İstanbul', 'Fatih');
      if (lat < 41.0) return ('İstanbul', 'Kadıköy');
      return ('İstanbul', 'Beşiktaş');
    }
    if (lat >= 39.8 && lat <= 40.0 && lng >= 32.7 && lng <= 33.0) {
      return ('Ankara', 'Çankaya');
    }
    if (lat >= 38.3 && lat <= 38.6 && lng >= 26.9 && lng <= 27.3) {
      return ('İzmir', 'Konak');
    }
    if (lat >= 40.1 && lat <= 40.3 && lng >= 29.0 && lng <= 29.2) {
      return ('Bursa', 'Osmangazi');
    }
    if (lat >= 36.8 && lat <= 37.1 && lng >= 35.2 && lng <= 35.5) {
      return ('Adana', 'Seyhan');
    }
    // Bilinmeyen şehir — İstanbul varsayılanı
    return ('İstanbul', 'Kadıköy');
  }
}

// ─────────────────────────────────────────
//  DataResult — Veri Paketi
// ─────────────────────────────────────────

/// [DataService.loadAllData] çıktısı. Tüm uygulama verisi burada taşınır.
class DataResult {
  final List<PlaceModel> pharmacies;
  final List<PlaceModel> hospitals;
  final double userLat;
  final double userLng;
  final bool locationObtained;
  final bool usedFallback;
  final bool isBusinessHours;

  const DataResult({
    required this.pharmacies,
    required this.hospitals,
    required this.userLat,
    required this.userLng,
    required this.locationObtained,
    required this.usedFallback,
    required this.isBusinessHours,
  });

  List<PlaceModel> get all => [...pharmacies, ...hospitals];
}
