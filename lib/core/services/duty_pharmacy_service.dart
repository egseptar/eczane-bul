import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/place_model.dart';
import '../constants/api_constants.dart';

/// Türkiye geneli nöbetçi eczane verisi sunan REST API'larla iletişim kurar.
///
/// Desteklenen API formatları:
///   - NosyAPI  : https://nosyapi.com/apiv2/service/pharmacies-on-duty
///   - CollectAPI: https://api.collectapi.com/health/dutyPharmacy
///   - İlgili il/ilçe belediyelerinin açık JSON uç noktaları
///
/// API anahtarı [ApiConstants.nosyApiKey] veya [ApiConstants.collectApiKey]
/// ile sağlanır. Anahtar eksikse fallback dummy data devreye girer.
class DutyPharmacyService {
  DutyPharmacyService._();
  static final DutyPharmacyService _instance = DutyPharmacyService._();
  static DutyPharmacyService get instance => _instance;

  final http.Client _client = http.Client();

  // ─────────────────────────────────────────
  //  Ortak Giriş Noktası
  // ─────────────────────────────────────────

  /// [city] ve [district] parametreleriyle il/ilçeye göre nöbetçi eczaneleri
  /// çeker. Birden fazla kaynak denenir; ilk başarılı yanıt döner.
  Future<List<PlaceModel>> getDutyPharmacies({
    required String city,
    String district = '',
  }) async {
    // 1. NosyAPI'yı dene
    if (ApiConstants.nosyApiKey.isNotEmpty &&
        ApiConstants.nosyApiKey != 'YOUR_NOSY_API_KEY') {
      final result = await _fetchFromNosyApi(city: city, district: district);
      if (result.isNotEmpty) return result;
    }

    // 2. CollectAPI'yı dene
    if (ApiConstants.collectApiKey.isNotEmpty &&
        ApiConstants.collectApiKey != 'YOUR_COLLECT_API_KEY') {
      final result =
          await _fetchFromCollectApi(city: city, district: district);
      if (result.isNotEmpty) return result;
    }

    // 3. Hiçbir API çalışmadı — boş liste döndür (caller fallback yapar)
    return [];
  }

  // ─────────────────────────────────────────
  //  NosyAPI Entegrasyonu
  //  Belge: https://nosyapi.com/docs/pharmacy
  // ─────────────────────────────────────────

  Future<List<PlaceModel>> _fetchFromNosyApi({
    required String city,
    String district = '',
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.nosyApiPharmacyUrl).replace(
        queryParameters: {
          'city': city,
          if (district.isNotEmpty) 'district': district,
          'apikey': ApiConstants.nosyApiKey,
        },
      );

      final response = await _client
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results =
            (data['result'] ?? data['data'] ?? []) as List<dynamic>;
        return results
            .whereType<Map<String, dynamic>>()
            .map(_mapNosyToPlaceModel)
            .toList();
      }
    } catch (_) {
      // Sessizce geç, bir sonraki kaynağı dene
    }
    return [];
  }

  PlaceModel _mapNosyToPlaceModel(Map<String, dynamic> json) {
    final lat = _parseDouble(json['latitude'] ?? json['lat']);
    final lng = _parseDouble(json['longitude'] ?? json['long'] ?? json['lng']);

    return PlaceModel(
      id: 'nosy_${json['id'] ?? json['eczaneId'] ?? _hashString(json['name']?.toString() ?? '')}',
      name: json['name']?.toString() ?? json['eczaneAdi']?.toString() ?? 'Eczane',
      type: PlaceType.pharmacy,
      rating: _parseDouble(json['rating']) ?? 4.0,
      reviewsCount: (json['ratingCount'] as int?) ?? 0,
      distanceKm: 0.0,
      address: [
        json['address'] ?? json['adres'],
        json['district'] ?? json['ilce'],
        json['city'] ?? json['il'],
      ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
      phone: json['phone']?.toString() ?? json['telefon']?.toString() ?? '',
      isOpen: true,
      isOnDuty: true,
      branches: const [],
      tags: const ['Nöbetçi', '24 Saat'],
      reviews: const [],
      latitude: lat ?? 41.0,
      longitude: lng ?? 29.0,
      workingHours: '24 Saat Açık',
      dutyEndTime: json['dutyEnd']?.toString() ?? json['nobetBitis']?.toString(),
    );
  }

  // ─────────────────────────────────────────
  //  CollectAPI Entegrasyonu
  //  Belge: https://collectapi.com/api/health
  // ─────────────────────────────────────────

  Future<List<PlaceModel>> _fetchFromCollectApi({
    required String city,
    String district = '',
  }) async {
    try {
      final key = ApiConstants.collectApiKey.trim();
      final authHeader = key.startsWith('apikey ') ? key : 'apikey $key';

      final queryParams = <String, String>{
        'il': city,
        if (district.isNotEmpty && district != city) 'ilce': district,
      };

      var uri = Uri.parse(ApiConstants.collectApiPharmacyUrl).replace(
        queryParameters: queryParams,
      );

      var response = await _client.get(uri, headers: {
        'content-type': 'application/json',
        'authorization': authHeader,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        var results = (data['result'] ?? []) as List<dynamic>;

        // Eğer ilçe ile sonuç çıkmadıysa tüm şehri dene
        if (results.isEmpty && queryParams.containsKey('ilce')) {
          uri = Uri.parse(ApiConstants.collectApiPharmacyUrl).replace(
            queryParameters: {'il': city},
          );
          response = await _client.get(uri, headers: {
            'content-type': 'application/json',
            'authorization': authHeader,
          }).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final dataCity = json.decode(response.body) as Map<String, dynamic>;
            results = (dataCity['result'] ?? []) as List<dynamic>;
          }
        }

        return results
            .whereType<Map<String, dynamic>>()
            .map(_mapCollectToPlaceModel)
            .toList();
      }
    } catch (_) {
      // Sessizce geç
    }
    return [];
  }

  PlaceModel _mapCollectToPlaceModel(Map<String, dynamic> json) {
    double? lat = _parseDouble(json['latitude'] ?? json['lat']);
    double? lng = _parseDouble(json['longitude'] ?? json['lng'] ?? json['long']);

    // CollectAPI "loc" alanını ("lat,lng" formatında) ayrıştır
    if ((lat == null || lng == null) && json['loc'] != null) {
      final locStr = json['loc'].toString().trim();
      final parts = locStr.split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
      }
    }

    return PlaceModel(
      id: 'collect_${_hashString(json['name']?.toString() ?? '')}',
      name: json['name']?.toString() ?? 'Nöbetçi Eczane',
      type: PlaceType.pharmacy,
      rating: 4.5,
      reviewsCount: 18,
      distanceKm: 0.0,
      address: json['address']?.toString() ?? json['adres']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['telefon']?.toString() ?? '',
      isOpen: true,
      isOnDuty: true,
      branches: const [],
      tags: const ['Nöbetçi', '24 Saat'],
      reviews: const [],
      latitude: lat ?? 41.0,
      longitude: lng ?? 29.0,
      workingHours: '24 Saat Açık',
    );
  }

  // ─────────────────────────────────────────
  //  Yardımcı Fonksiyonlar
  // ─────────────────────────────────────────

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int _hashString(String s) {
    var hash = 0;
    for (var i = 0; i < s.length; i++) {
      hash = (hash * 31 + s.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  void dispose() => _client.close();
}
