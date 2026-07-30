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

  /// Verilen koordinat etrafındaki tüm hastaneleri geniş yarıçap ile getirir.
  Future<List<PlaceModel>> getNearbyHospitals({
    required double latitude,
    required double longitude,
    int radius = ApiConstants.maxSearchRadius,
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
    int radius = ApiConstants.maxSearchRadius,
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
  //  Normalizasyon ve Triyaj Sıralama Algoritması
  // ─────────────────────────────────────────

  /// Türkçe karakter ve isim normalizasyonu
  static String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('.', '');
  }

  /// 8 Ana Şikayet Senaryosu ve Keyword Haritası
  static const Map<String, List<String>> symptomKeywordMap = {
    'trauma': ['ortopedi', 'travma', 'kemik', 'fizik', 'spor'],
    'eye': ['goz', 'dunyagoz', 'optik', 'kudret', 'maya'],
    'dental': ['dis', 'dental', 'dent', 'agiz', 'cene'],
    'cardio': ['kalp', 'kardiyoloji', 'gogus', 'damar', 'siyamiersek'],
    'pediatric': ['cocuk', 'pediatri', 'bebek'],
    'obgyn': ['kadin', 'dogum', 'jinekoloji', 'zeynepkamil'],
    'dermatology': ['yanik', 'cilt', 'deri', 'dermatoloji', 'plastik'],
    'general': [],
  };

  /// Tam Teşekküllü Hastane (Genel/Fallback) Keywordleri
  static const List<String> generalHospitalKeywords = [
    'devlet',
    'sehir',
    'egitim',
    'arastirma',
    'universite',
    'medicalpark',
    'acibadem',
    'memorial',
    'medicana',
  ];

  /// Şikayete göre keyword listesi seçer
  static List<String> getKeywordsForSymptom(String? branch, String? tag) {
    final b = normalizeText(branch ?? '');
    final t = normalizeText(tag ?? '');

    if (b.contains('ortopedi') || b.contains('travma') || t.contains('orthopedics')) {
      return symptomKeywordMap['trauma']!;
    }
    if (b.contains('goz') || t.contains('ophthalmology') || t.contains('eye')) {
      return symptomKeywordMap['eye']!;
    }
    if (b.contains('dis') || b.contains('agiz') || t.contains('dental')) {
      return symptomKeywordMap['dental']!;
    }
    if (b.contains('kalp') || b.contains('kardiyoloji') || b.contains('gogus') || t.contains('cardiology')) {
      return symptomKeywordMap['cardio']!;
    }
    if (b.contains('cocuk') || b.contains('pediatri') || t.contains('pediatric')) {
      return symptomKeywordMap['pediatric']!;
    }
    if (b.contains('kadin') || b.contains('dogum') || b.contains('jinekoloji') || t.contains('obgyn')) {
      return symptomKeywordMap['obgyn']!;
    }
    if (b.contains('yanik') || b.contains('cilt') || b.contains('deri') || b.contains('dermatoloji') || t.contains('dermatology')) {
      return symptomKeywordMap['dermatology']!;
    }
    return symptomKeywordMap['general']!;
  }

  /// Hastaneleri akıllı triyaj önceliğine göre sıralar:
  /// Öncelik 1: Uzmanlık eşleşmesi (Özel dal)
  /// Öncelik 2: Tam teşekküllü genel acil hastaneleri (Devlet, Şehir vb.)
  /// Öncelik 3: Diğer poliklinik ve tıp merkezleri
  /// Kendi içlerinde mesafeye göre sıralanır.
  static List<PlaceModel> sortHospitalsByTriage({
    required List<PlaceModel> hospitals,
    String? symptomBranch,
    String? symptomTag,
  }) {
    final keywords = getKeywordsForSymptom(symptomBranch, symptomTag);

    int getPriority(PlaceModel h) {
      final normName = normalizeText(h.name);
      final normBranches = h.branches.map(normalizeText).toList();

      // Öncelik 1: Uzmanlık Eşleşmesi
      if (keywords.isNotEmpty) {
        final matchesName = keywords.any((k) => normName.contains(k));
        final matchesBranch = normBranches.any((b) => keywords.any((k) => b.contains(k)));
        if (matchesName || matchesBranch) return 1;
      }

      // Öncelik 2: Tam Teşekküllü Hastaneler
      final isGeneralHospital = generalHospitalKeywords.any((k) => normName.contains(k)) ||
          normBranches.any((b) => generalHospitalKeywords.any((k) => b.contains(k))) ||
          h.emergencyTags.contains('has_general_emergency');

      if (isGeneralHospital) return 2;

      // Öncelik 3: Diğerleri
      return 3;
    }

    final sorted = List<PlaceModel>.from(hospitals);
    sorted.sort((a, b) {
      final pA = getPriority(a);
      final pB = getPriority(b);
      if (pA != pB) {
        return pA.compareTo(pB);
      }
      return a.distanceKm.compareTo(b.distanceKm);
    });
    return sorted;
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
    final allParsedPlaces = <PlaceModel>[];
    String? nextPageToken;
    int pageCount = 0;
    const maxPages = 3; // Maksimum 60 sonuç (3 sayfa * 20 sonuç)

    do {
      pageCount++;
      final params = <String, String>{
        'location': '$latitude,$longitude',
        'radius': '$radius',
        'type': type,
        'language': 'tr',
        'key': ApiConstants.googleApiKey,
      };

      if (nextPageToken != null && nextPageToken.isNotEmpty) {
        params['pagetoken'] = nextPageToken;
      } else if (keyword != null && keyword.isNotEmpty) {
        params['keyword'] = keyword;
      }

      final uri = Uri.parse(ApiConstants.nearbySearchEndpoint)
          .replace(queryParameters: params);

      // ignore: avoid_print
      print('[PlacesService] NearbySearch İstek URL (Sayfa $pageCount): $uri');

      try {
        final response = await _client.get(uri).timeout(const Duration(seconds: 12));

        // ignore: avoid_print
        print('[PlacesService] HTTP Yanıt Kodu (Sayfa $pageCount): ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'UNKNOWN';

          if (status == 'OK' || status == 'ZERO_RESULTS') {
            final results = data['results'] as List<dynamic>? ?? [];

            for (var i = 0; i < results.length; i++) {
              try {
                final rawItem = results[i] as Map<String, dynamic>;
                final place = _mapToPlaceModel(rawItem, placeType);
                if (!allParsedPlaces.any((p) => p.id == place.id)) {
                  allParsedPlaces.add(place);
                }
              } catch (e, stack) {
                // ignore: avoid_print
                print('[PlacesService] Öğesi #$i dönüştürülürken hata: $e');
                // ignore: avoid_print
                print('[PlacesService] Stacktrace: $stack');
              }
            }

            // Sayfalandırma token kontrolü
            nextPageToken = data['next_page_token'] as String?;

            if (nextPageToken != null && nextPageToken.isNotEmpty && pageCount < maxPages) {
              // ignore: avoid_print
              print('[PlacesService] next_page_token bulundu. 2 saniye bekleniyor...');
              await Future.delayed(const Duration(seconds: 2));
            } else {
              nextPageToken = null;
            }
          } else {
            // ignore: avoid_print
            print('[PlacesService] API status yanıtı OK değil ($type Sayfa $pageCount): $status');
            nextPageToken = null;
          }
        } else {
          nextPageToken = null;
        }
      } catch (e, stack) {
        // ignore: avoid_print
        print('[PlacesService] Ağ veya JSON Hatası ($type Sayfa $pageCount): $e');
        // ignore: avoid_print
        print('[PlacesService] Stacktrace: $stack');
        nextPageToken = null;
      }
    } while (nextPageToken != null && nextPageToken.isNotEmpty && pageCount < maxPages);

    return allParsedPlaces;
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
      final appointmentUrl = _resolveAppointmentUrl(name, type);

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
        appointmentUrl: appointmentUrl,
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
        appointmentUrl: _resolveAppointmentUrl(json['name']?.toString() ?? '', type),
      );
    }
  }

  /// Hastane adına göre otomatik E-Randevu URL'si atar (MHRS ve Özel Markalar).
  static String? resolveAppointmentUrl(String name, PlaceType type) {
    if (type != PlaceType.hospital) return null;

    final normalizedName = name
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('.', '');

    String assignedUrl;

    // 1. Acıbadem
    if (normalizedName.contains('acibadem')) {
      assignedUrl =
          'https://www.acibadem.com.tr/acibademonline/#/login?returnUrl=%2Fdashboard';
    }
    // 2. Medical Park / VM Medical Park
    else if (normalizedName.contains('medicalpark') ||
        normalizedName.contains('vmmedical')) {
      assignedUrl =
          'https://www.medicalpark.com.tr/randevu-al/bilgi-dogrulama';
    }
    // 3. Memorial
    else if (normalizedName.contains('memorial')) {
      assignedUrl = 'https://www.memorial.com.tr/randevu-al';
    }
    // 4. Medicana
    else if (normalizedName.contains('medicana')) {
      assignedUrl = 'https://www.medicana.com.tr/online-randevu';
    }
    // 5. Medipol
    else if (normalizedName.contains('medipol')) {
      assignedUrl = 'https://online.medipol.com.tr/';
    }
    // 6. Liv Hospital
    else if (normalizedName.contains('livhospital') ||
        normalizedName.contains('liv')) {
      assignedUrl =
          'https://www.livhospital.com/randevu-al/bilgi-dogrulama';
    }
    // 7. Florence Nightingale
    else if (normalizedName.contains('florence') ||
        normalizedName.contains('nightingale')) {
      assignedUrl = 'https://www.florence.com.tr/online-randevu';
    }
    // 8. Başkent Hastanesi
    else if (normalizedName.contains('baskent')) {
      assignedUrl =
          'https://ankara.baskenthastaneleri.com/tr/online-islemler/randevu';
    }
    // 9. Hisar Hospital
    else if (normalizedName.contains('hisar')) {
      assignedUrl =
          'https://hisarhospital.com/randevu-al/?utm_term=hisar%20hastanesi%20randevu&utm_campaign=Branding+Search&utm_source=adwords&utm_medium=ppc&hsa_acc=7469825535&hsa_cam=8540911371&hsa_grp=125669721536&hsa_ad=627906579021&hsa_src=g&hsa_tgt=kwd-487119120378&hsa_kw=hisar%20hastanesi%20randevu&hsa_mt=b&hsa_net=adwords&hsa_ver=3&gad_source=1&gad_campaignid=8540911371&gclid=Cj0KCQjwg5zTBhCLARIsAP2AFU718R-cVWMJE8vbBZIi4m6SudaTPbmug4AN1WN8eXegPEQ_QabpvDgaAusnEALw_wcB#/appointment';
    }
    // 10. Anadolu Sağlık Merkezi
    else if (normalizedName.contains('anadolusaglik') ||
        (normalizedName.contains('anadolu') &&
            normalizedName.contains('saglik'))) {
      assignedUrl = 'https://www.anadolusaglik.org/doktorlar';
    }
    // 11. Dünyagöz
    else if (normalizedName.contains('dunyagoz') ||
        (normalizedName.contains('dunya') &&
            normalizedName.contains('goz'))) {
      assignedUrl =
          'https://www.dunyagoz.com/tr/islemler/randevu?anaRandevu';
    }
    // 12. Devlet, Şehir, Eğitim, Üniversite ve tüm diğer kamu/genel/özel hastaneler için MHRS
    else {
      assignedUrl = 'https://mhrs.gov.tr/';
    }

    print('🏥 HASTANE EŞLEŞTİRME -> İsim: $name | Atanan URL: $assignedUrl');
    return assignedUrl;
  }

  String? _resolveAppointmentUrl(String name, PlaceType type) =>
      resolveAppointmentUrl(name, type);

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
