import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/place_model.dart';
import '../../models/review_model.dart';

/// Google Places API ile iletişim kurar.
/// Nearby Search ve Place Details uç noktalarını kullanır.
class PlacesService {
  PlacesService._();

  static final PlacesService _instance = PlacesService._();
  static PlacesService get instance => _instance;

  final http.Client _client = http.Client();

  // ─────────────────────────────────────────
  //  Nearby Search — Yakındaki Yerler
  // ─────────────────────────────────────────

  /// Verilen koordinat etrafındaki nöbetçi eczaneleri getirir.
  Future<List<PlaceModel>> getNearbyPharmacies({
    required double latitude,
    required double longitude,
    int radius = ApiConstants.defaultSearchRadius,
  }) async {
    return _nearbySearch(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: 'pharmacy',
      placeType: PlaceType.pharmacy,
      keyword: 'eczane nöbetçi',
    );
  }

  /// Verilen koordinat etrafındaki hastaneleri getirir.
  Future<List<PlaceModel>> getNearbyHospitals({
    required double latitude,
    required double longitude,
    int radius = ApiConstants.defaultSearchRadius,
  }) async {
    return _nearbySearch(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: 'hospital',
      placeType: PlaceType.hospital,
    );
  }

  /// Tüm yakın sağlık tesislerini (eczane + hastane) birleştirir.
  Future<List<PlaceModel>> getNearbyHealthPlaces({
    required double latitude,
    required double longitude,
    int radius = ApiConstants.defaultSearchRadius,
  }) async {
    final results = await Future.wait([
      getNearbyPharmacies(latitude: latitude, longitude: longitude, radius: radius),
      getNearbyHospitals(latitude: latitude, longitude: longitude, radius: radius),
    ]);

    final all = [...results[0], ...results[1]];
    // Mesafeye göre sırala
    all.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return all;
  }

  // ─────────────────────────────────────────
  //  Place Details — Yer Detayları
  // ─────────────────────────────────────────

  /// Belirli bir yer ID'si için detay bilgilerini getirir (telefon, saat, vb.)
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final uri = Uri.parse(ApiConstants.placeDetailsEndpoint).replace(
      queryParameters: {
        'place_id': placeId,
        'fields':
            'name,formatted_address,formatted_phone_number,opening_hours,rating,user_ratings_total,geometry,photos,types,website',
        'language': 'tr',
        'key': ApiConstants.googleApiKey,
      },
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      // Hata durumunda null döndür, çağıran taraf yönetir
    }
    return null;
  }

  // ─────────────────────────────────────────
  //  Private — Nearby Search
  // ─────────────────────────────────────────

  Future<List<PlaceModel>> _nearbySearch({
    required double latitude,
    required double longitude,
    required int radius,
    required String type,
    required PlaceType placeType,
    String? keyword,
  }) async {
    final params = <String, String>{
      'location': '$latitude,$longitude',
      'radius': '$radius',
      'type': type,
      'language': 'tr',
      'key': ApiConstants.googleApiKey,
    };
    if (keyword != null) params['keyword'] = keyword;

    final uri = Uri.parse(ApiConstants.nearbySearchEndpoint)
        .replace(queryParameters: params);

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final results = data['results'] as List<dynamic>? ?? [];
          return results
              .map((r) => _mapToPlaceModel(r as Map<String, dynamic>, placeType))
              .toList();
        }
      }
    } catch (e) {
      // Ağ hatası — boş liste döndür, uygulama dummy dataya düşer
    }
    return [];
  }

  // ─────────────────────────────────────────
  //  JSON → PlaceModel Dönüşümü
  // ─────────────────────────────────────────

  PlaceModel _mapToPlaceModel(Map<String, dynamic> json, PlaceType type) {
    try {
      final geometryLocation = json['geometry']?['location'] as Map<String, dynamic>?;
      final lat = (geometryLocation?['lat'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble() ??
          double.tryParse(json['lat']?.toString() ?? '') ??
          0.0;
      final lng = (geometryLocation?['lng'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble() ??
          double.tryParse(json['lng']?.toString() ?? '') ??
          0.0;

      final openingHours = json['opening_hours'] as Map<String, dynamic>?;
      final isOpen = openingHours?['open_now'] as bool? ?? true;

      final name = (json['name'] as String?)?.trim() ?? 'Sağlık Kuruluşu';
      final address = (json['vicinity'] ?? json['formatted_address'] ?? json['address'])?.toString().trim() ?? '';
      final placeId = (json['place_id'] ?? json['id'])?.toString() ?? '';

      final extractedBranches = _extractBranches(json);
      final branches = (extractedBranches.isEmpty && type == PlaceType.hospital)
          ? const ['Genel Cerrahi', 'Acil Servis', 'Dahiliye', 'Kardiyoloji', 'Ortopedi']
          : extractedBranches;

      final emergencyTags = type == PlaceType.hospital
          ? const [
              'has_general_emergency',
              'has_cardiology_emergency',
              'has_orthopedics_emergency',
              'has_general_surgery',
              'has_pediatric_emergency',
              'has_neurology_emergency',
              'has_internal_medicine',
              'has_ophthalmology_emergency',
              'has_dental_emergency',
            ]
          : const <String>[];

      final rating = (json['rating'] as num?)?.toDouble() ?? 0.0;
      final reviewsCount = (json['user_ratings_total'] as int?) ?? 0;

      return PlaceModel(
        id: placeId.isNotEmpty ? placeId : 'place_${name.hashCode}',
        name: name,
        type: type,
        rating: rating,
        reviewsCount: reviewsCount,
        distanceKm: 0.0,
        address: address,
        phone: (json['formatted_phone_number'] ?? json['phone'])?.toString() ?? '',
        isOpen: isOpen,
        isOnDuty: type == PlaceType.pharmacy && isOpen,
        branches: branches,
        tags: _extractTags(json),
        emergencyTags: emergencyTags,
        reviews: const [],
        latitude: lat,
        longitude: lng,
        workingHours: isOpen ? 'Açık (24 Saat)' : 'Kapalı',
      );
    } catch (_) {
      // Hata durumunda varsayılan güvenli model döndür
      return PlaceModel(
        id: 'place_err_${json['name']?.hashCode ?? 0}',
        name: json['name']?.toString() ?? 'Sağlık Kuruluşu',
        type: type,
        rating: 0.0,
        reviewsCount: 0,
        distanceKm: 0.0,
        address: json['vicinity']?.toString() ?? '',
        phone: '',
        isOpen: true,
        latitude: 0.0,
        longitude: 0.0,
      );
    }
  }

  List<String> _extractBranches(Map<String, dynamic> json) {
    final types = json['types'] as List<dynamic>? ?? [];
    final branchMap = <String, String>{
      'hospital': 'Genel Hastane',
      'doctor': 'Muayenehane',
      'dentist': 'Ağız ve Diş Sağlığı',
      'physiotherapist': 'Fizyoterapi',
      'optician': 'Göz Hastalıkları',
    };
    return types
        .whereType<String>()
        .where(branchMap.containsKey)
        .map((t) => branchMap[t]!)
        .toList();
  }

  List<String> _extractTags(Map<String, dynamic> json) {
    final tags = <String>[];
    final openingHours = json['opening_hours'] as Map<String, dynamic>?;
    if (openingHours?['open_now'] == true) tags.add('Açık');
    if ((json['rating'] as num?)?.toDouble() != null &&
        (json['rating'] as num).toDouble() >= 4.5) {
      tags.add('Yüksek Puan');
    }
    return tags;
  }

  void dispose() {
    _client.close();
  }
}

// ─────────────────────────────────────────
//  PlaceDetails — Detaylı Yer Bilgisi
// ─────────────────────────────────────────

class PlaceDetails {
  final String name;
  final String address;
  final String phone;
  final String? website;
  final double? rating;
  final int? userRatingsTotal;
  final bool? isOpenNow;
  final List<String>? weekdayText;

  const PlaceDetails({
    required this.name,
    required this.address,
    required this.phone,
    this.website,
    this.rating,
    this.userRatingsTotal,
    this.isOpenNow,
    this.weekdayText,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final openingHours = json['opening_hours'] as Map<String, dynamic>?;
    final weekdays = openingHours?['weekday_text'] as List<dynamic>?;

    return PlaceDetails(
      name: json['name'] as String? ?? '',
      address: json['formatted_address'] as String? ?? '',
      phone: json['formatted_phone_number'] as String? ?? '',
      website: json['website'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      isOpenNow: openingHours?['open_now'] as bool?,
      weekdayText: weekdays?.map((e) => e.toString()).toList(),
    );
  }

  /// PlaceDetails'ten tam PlaceModel oluşturur.
  PlaceModel toPlaceModel({
    required String id,
    required PlaceType type,
    required double latitude,
    required double longitude,
    double distanceKm = 0.0,
    List<ReviewModel> reviews = const [],
  }) {
    return PlaceModel(
      id: id,
      name: name,
      type: type,
      rating: rating ?? 0.0,
      reviewsCount: userRatingsTotal ?? 0,
      distanceKm: distanceKm,
      address: address,
      phone: phone,
      isOpen: isOpenNow ?? false,
      isOnDuty: type == PlaceType.pharmacy && (isOpenNow ?? false),
      reviews: reviews,
      latitude: latitude,
      longitude: longitude,
      workingHours: weekdayText?.isNotEmpty == true
          ? weekdayText!.first
          : (isOpenNow == true ? 'Açık' : 'Kapalı'),
    );
  }
}
