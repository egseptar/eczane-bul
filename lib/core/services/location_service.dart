import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Kullanıcının GPS konumunu yönetir.
/// İzin kontrolü, konum alma ve sürekli izleme işlemlerini kapsar.
class LocationService {
  LocationService._();

  static final LocationService _instance = LocationService._();
  static LocationService get instance => _instance;

  // İstanbul Kadıköy - varsayılan konum (izin verilmezse kullanılır)
  static const double defaultLat = 40.9903;
  static const double defaultLng = 29.0221;

  // ─────────────────────────────────────────
  //  İzin Kontrolü
  // ─────────────────────────────────────────

  /// Konum servisinin açık olup olmadığını ve izin durumunu kontrol eder.
  /// Gerekirse izin ister.
  /// [LocationPermission] döndürür — [denied] veya [deniedForever] ise hata fırlatır.
  Future<LocationPermission> checkAndRequestPermission() async {
    // Cihazda konum servisi açık mı?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException(
          'Konum izni reddedildi. Uygulama yakın eczane ve hastaneleri göstermek için konuma ihtiyaç duyar.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException(
        'Konum izni kalıcı olarak reddedildi. Ayarlardan konum iznini manuel olarak etkinleştirin.',
        isPermanent: true,
      );
    }

    return permission;
  }

  // ─────────────────────────────────────────
  //  Tek Seferlik Konum Alma
  // ─────────────────────────────────────────

  /// Kullanıcının anlık konumunu döndürür.
  /// İzin verilmezse varsayılan konumu (Kadıköy, İstanbul) döndürür.
  Future<Position> getCurrentPosition({bool useDefault = true}) async {
    try {
      await checkAndRequestPermission();

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      if (useDefault) {
        // Varsayılan konum döndür
        return Position(
          latitude: defaultLat,
          longitude: defaultLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  //  Sürekli Konum Takibi (Stream)
  // ─────────────────────────────────────────

  /// Kullanıcının konumunu sürekli izleyen stream döndürür.
  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15, // 15 metre hareket edince güncelle
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Yardımcı Fonksiyonlar
  // ─────────────────────────────────────────

  /// İki koordinat arasındaki mesafeyi metre cinsinden döndürür.
  double distanceBetween({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Verilen iki koordinat arasındaki mesafeyi okunabilir formata çevirir.
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // ─────────────────────────────────────────
  //  Ters Coğrafi Kodlama (Reverse Geocoding)
  // ─────────────────────────────────────────

  /// Enlem/boylamı okunabilir açık adrese çevirir.
  /// Hata durumunda varsayılan metin döndürür, asla fırlatmaz.
  Future<AddressResult> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 8));

      if (placemarks.isEmpty) return AddressResult.unknown();

      final p = placemarks.first;

      // Sokak numarası
      final streetNumber =
          (p.subThoroughfare?.isNotEmpty == true) ? '${p.subThoroughfare} ' : '';
      // Sokak adı
      final street =
          (p.thoroughfare?.isNotEmpty == true) ? p.thoroughfare! : '';
      // Mahalle
      final district = p.subLocality?.isNotEmpty == true
          ? p.subLocality!
          : (p.locality ?? '');
      // İlçe / şehir
      final city = p.administrativeArea ?? p.locality ?? '';

      final shortAddress = [
        if (district.isNotEmpty) district,
        if (street.isNotEmpty) '$street $streetNumber'.trim(),
      ].join(', ');

      final fullAddress = [
        if (street.isNotEmpty) '$street $streetNumber'.trim(),
        if (district.isNotEmpty) district,
        if (city.isNotEmpty) city,
      ].join(', ');

      return AddressResult(
        shortAddress: shortAddress.isNotEmpty ? shortAddress : fullAddress,
        fullAddress: fullAddress.isNotEmpty ? fullAddress : 'Adres alınamadı',
        district: district,
        city: city,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      return AddressResult.unknown(
        latitude: latitude,
        longitude: longitude,
      );
    }
  }
}

// ─────────────────────────────────────────
//  Özel Exception Sınıfları
// ─────────────────────────────────────────

class LocationServiceDisabledException implements Exception {
  final String message;
  const LocationServiceDisabledException([
    this.message = 'Konum servisi kapalı. Lütfen cihaz ayarlarından açın.',
  ]);

  @override
  String toString() => message;
}

class LocationPermissionDeniedException implements Exception {
  final String message;
  final bool isPermanent;

  const LocationPermissionDeniedException(
    this.message, {
    this.isPermanent = false,
  });

  @override
  String toString() => message;
}

// ─────────────────────────────────────────
//  AddressResult — Adres Veri Modeli
// ─────────────────────────────────────────

/// [LocationService.getAddressFromCoordinates] sonucu.
class AddressResult {
  final String shortAddress;
  final String fullAddress;
  final String district;
  final String city;
  final double? latitude;
  final double? longitude;
  final bool isUnknown;

  const AddressResult({
    required this.shortAddress,
    required this.fullAddress,
    required this.district,
    required this.city,
    this.latitude,
    this.longitude,
    this.isUnknown = false,
  });

  factory AddressResult.unknown({double? latitude, double? longitude}) {
    return AddressResult(
      shortAddress: 'Konum alınamadı',
      fullAddress: 'Açık adres belirlenemedi',
      district: '',
      city: '',
      latitude: latitude,
      longitude: longitude,
      isUnknown: true,
    );
  }

  /// Koordinat bilgisi varsa "41.0082° K, 28.9784° D" formatında göster.
  String get coordinateText {
    if (latitude == null || longitude == null) return '';
    return '${latitude!.toStringAsFixed(4)}° K, '
        '${longitude!.toStringAsFixed(4)}° D';
  }
}
