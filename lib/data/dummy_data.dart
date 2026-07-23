import '../models/place_model.dart';
import '../models/review_model.dart';

class DummyData {
  DummyData._();

  // ─────────────────────────────────────────
  //  REVIEWS
  // ─────────────────────────────────────────

  static const List<ReviewModel> _reviewsAkcay = [
    ReviewModel(
      id: 'r1',
      authorName: 'Ayşe Kara',
      authorInitials: 'AK',
      rating: 5.0,
      comment:
          'Gece 02:00\'de gittiğimde çok ilgili ve yardımsever personel vardı. '
          'İlaçlarımı kolayca buldular, fiyatlar da makul. Kesinlikle tavsiye ederim!',
      timeAgo: '3 gün önce',
      helpfulCount: 12,
    ),
    ReviewModel(
      id: 'r2',
      authorName: 'Mehmet Yılmaz',
      authorInitials: 'MY',
      rating: 4.5,
      comment:
          'Nöbetçi eczane olduğu için bayramlarda da açık. Eczacı hanım çok bilgili, '
          'ilaç etkileşimleri hakkında detaylı bilgi verdi.',
      timeAgo: '1 hafta önce',
      helpfulCount: 8,
    ),
    ReviewModel(
      id: 'r3',
      authorName: 'Fatma Demir',
      authorInitials: 'FD',
      rating: 4.0,
      comment:
          'Konum olarak merkezi, otopark problemi var ama yürüyerek ulaşmak mümkün. '
          'Stok çeşitliliği iyi.',
      timeAgo: '2 hafta önce',
      helpfulCount: 5,
    ),
  ];

  static const List<ReviewModel> _reviewsMerkez = [
    ReviewModel(
      id: 'r4',
      authorName: 'Hasan Çelik',
      authorInitials: 'HÇ',
      rating: 5.0,
      comment:
          'Her zaman stoğu dolu, personel güleryüzlü. Gece nöbetinde bile '
          'aynı kaliteli hizmeti sunuyorlar.',
      timeAgo: '5 gün önce',
      helpfulCount: 15,
    ),
    ReviewModel(
      id: 'r5',
      authorName: 'Zeynep Arslan',
      authorInitials: 'ZA',
      rating: 4.5,
      comment:
          'Çocuğum için reçeteli ilaç aradım, hemen buldular ve nasıl kullanılacağını '
          'çok güzel anlattılar. Teşekkürler!',
      timeAgo: '10 gün önce',
      helpfulCount: 9,
    ),
    ReviewModel(
      id: 'r6',
      authorName: 'Ali Öztürk',
      authorInitials: 'AÖ',
      rating: 4.0,
      comment:
          'Fiyatlar standart. Takviye ilaçlar için iyi bir seçim, bekleme süresi kısa.',
      timeAgo: '3 hafta önce',
      helpfulCount: 3,
    ),
  ];

  static const List<ReviewModel> _reviewsUnivers = [
    ReviewModel(
      id: 'r7',
      authorName: 'Selin Kaya',
      authorInitials: 'SK',
      rating: 5.0,
      comment:
          'Göz acilinde başka hastanede bekleyemezdik. Burada triage çok hızlı, '
          'doktor muayenesine 30 dakikada girdik. Gerçekten mükemmel organizasyon.',
      timeAgo: '2 gün önce',
      helpfulCount: 28,
    ),
    ReviewModel(
      id: 'r8',
      authorName: 'Burak Şahin',
      authorInitials: 'BŞ',
      rating: 4.5,
      comment:
          'Göz kliniği ekibi son derece deneyimli. Retina uzmanı Prof. Dr. buradaydı, '
          'çok detaylı muayene yaptı. Teknik ekipman da çok gelişmiş.',
      timeAgo: '1 hafta önce',
      helpfulCount: 19,
    ),
    ReviewModel(
      id: 'r9',
      authorName: 'Merve Koç',
      authorInitials: 'MK',
      rating: 4.0,
      comment:
          'Otopark sorunu yaşandı, biraz uzak yere park ettim. '
          'Ama klinik içi hizmet çok iyiydi, temizlik üst düzeyde.',
      timeAgo: '2 hafta önce',
      helpfulCount: 7,
    ),
  ];

  static const List<ReviewModel> _reviewsKalp = [
    ReviewModel(
      id: 'r10',
      authorName: 'Osman Yıldız',
      authorInitials: 'OY',
      rating: 5.0,
      comment:
          'Kalp krizi şüphesiyle götürüldüm, anında müdahale ettiler. '
          'Kardiyoloji ekibi olağanüstü profesyoneldi. Hayatımı kurtardılar.',
      timeAgo: '4 gün önce',
      helpfulCount: 45,
    ),
    ReviewModel(
      id: 'r11',
      authorName: 'Hatice Polat',
      authorInitials: 'HP',
      rating: 4.5,
      comment:
          'EKG ve ekokardiyografi sonuçları aynı gün verildi. '
          'Doktor çok sabırlı anlattı, hiç acelecilik hissetmedim.',
      timeAgo: '1 hafta önce',
      helpfulCount: 22,
    ),
    ReviewModel(
      id: 'r12',
      authorName: 'Erkan Güneş',
      authorInitials: 'EG',
      rating: 4.0,
      comment:
          'Çok kalabalık olmasına rağmen bekleme süresi makul tuttu. '
          'Hemşireler ilgili ve sakin, panik yaşamadım.',
      timeAgo: '3 hafta önce',
      helpfulCount: 11,
    ),
  ];

  static const List<ReviewModel> _reviewsPediatri = [
    ReviewModel(
      id: 'r13',
      authorName: 'Neslihan Aydın',
      authorInitials: 'NA',
      rating: 5.0,
      comment:
          'Gece yarısı çocuğum ateşlendi, hemen geldik. Çocuk acil servisi '
          'çok düzenli ve hızlıydı. Doktor çok şefkatli davrandı.',
      timeAgo: '1 gün önce',
      helpfulCount: 33,
    ),
    ReviewModel(
      id: 'r14',
      authorName: 'Tarık Erdoğan',
      authorInitials: 'TE',
      rating: 4.5,
      comment:
          'Çocuk doktorları gerçekten uzman. Oyun alanı ve renkli dekor '
          'çocuğun korkusunu azaltıyor, harika bir ortam.',
      timeAgo: '5 gün önce',
      helpfulCount: 18,
    ),
    ReviewModel(
      id: 'r15',
      authorName: 'Dilek Aslan',
      authorInitials: 'DA',
      rating: 4.0,
      comment:
          'Bebek dostu hastane, emzirme odaları var. Park yeri geniş, '
          'gece de güvenli hissettiriyor.',
      timeAgo: '2 hafta önce',
      helpfulCount: 9,
    ),
  ];

  static const List<ReviewModel> _reviewsOrtopedi = [
    ReviewModel(
      id: 'r16',
      authorName: 'Emre Bulut',
      authorInitials: 'EB',
      rating: 5.0,
      comment:
          'Diz ameliyatımı burada yaptırdım. Ameliyathane temizliği mükemmel, '
          'cerrahi ekip çok deneyimli. Kısa sürede iyileştim.',
      timeAgo: '3 gün önce',
      helpfulCount: 26,
    ),
    ReviewModel(
      id: 'r17',
      authorName: 'Gülsüm Tekin',
      authorInitials: 'GT',
      rating: 4.5,
      comment:
          'Kırık tespiti için röntgen anında çekildi, uzman hemen değerlendirdi. '
          'Alçı işlemi çok hızlı tamamlandı.',
      timeAgo: '1 hafta önce',
      helpfulCount: 14,
    ),
    ReviewModel(
      id: 'r18',
      authorName: 'Kadir Yurt',
      authorInitials: 'KY',
      rating: 4.0,
      comment:
          'Fizyoterapi bölümü de var, ameliyat sonrası rehabilitasyon imkânı sağlıyor. '
          'Tek çatı altında her şey mevcut.',
      timeAgo: '3 hafta önce',
      helpfulCount: 8,
    ),
  ];

  // ─────────────────────────────────────────
  //  PHARMACIES (ECZANELER)
  // ─────────────────────────────────────────

  static final List<PlaceModel> pharmacies = [
    PlaceModel(
      id: 'ph1',
      name: 'Akçay Nöbetçi Eczanesi',
      type: PlaceType.pharmacy,
      rating: 4.7,
      reviewsCount: 142,
      distanceKm: 0.35,
      address: 'Atatürk Cad. No:47, Kadıköy, İstanbul',
      phone: '0216 338 12 45',
      isOpen: true,
      isOnDuty: true,
      branches: [],
      tags: ['24 Saat', 'Nöbetçi', 'Online Reçete'],
      reviews: _reviewsAkcay,
      latitude: 40.9903,
      longitude: 29.0221,
      workingHours: '24 Saat Açık',
      dutyEndTime: 'Yarın 09:00\'a kadar',
    ),
    PlaceModel(
      id: 'ph2',
      name: 'Merkez Eczanesi',
      type: PlaceType.pharmacy,
      rating: 4.5,
      reviewsCount: 98,
      distanceKm: 0.72,
      address: 'İstiklal Cad. No:112, Beyoğlu, İstanbul',
      phone: '0212 244 55 67',
      isOpen: true,
      isOnDuty: true,
      branches: [],
      tags: ['Nöbetçi', 'Fitoterapik Ürünler'],
      reviews: _reviewsMerkez,
      latitude: 41.0338,
      longitude: 28.9784,
      workingHours: '24 Saat Açık',
      dutyEndTime: 'Yarın 09:00\'a kadar',
    ),
    PlaceModel(
      id: 'ph3',
      name: 'Sağlık Eczanesi',
      type: PlaceType.pharmacy,
      rating: 4.3,
      reviewsCount: 67,
      distanceKm: 1.1,
      address: 'Bağdat Cad. No:234, Maltepe, İstanbul',
      phone: '0216 452 78 90',
      isOpen: false,
      isOnDuty: false,
      branches: [],
      tags: ['Bebek Ürünleri', 'Kozmetik'],
      reviews: _reviewsAkcay,
      latitude: 40.9352,
      longitude: 29.1301,
      workingHours: '09:00 - 21:00',
    ),
    PlaceModel(
      id: 'ph4',
      name: 'Yıldız Eczanesi',
      type: PlaceType.pharmacy,
      rating: 4.6,
      reviewsCount: 211,
      distanceKm: 1.45,
      address: 'Nispetiye Cad. No:8, Beşiktaş, İstanbul',
      phone: '0212 357 88 22',
      isOpen: true,
      isOnDuty: true,
      branches: [],
      tags: ['24 Saat', 'Nöbetçi', 'Otomasyon Sistemi'],
      reviews: _reviewsMerkez,
      latitude: 41.0790,
      longitude: 29.0178,
      workingHours: '24 Saat Açık',
      dutyEndTime: 'Yarın 09:00\'a kadar',
    ),
    PlaceModel(
      id: 'ph5',
      name: 'Güneş Eczanesi',
      type: PlaceType.pharmacy,
      rating: 4.1,
      reviewsCount: 55,
      distanceKm: 1.8,
      address: 'Turgut Özal Cad. No:55, Eyüpsultan, İstanbul',
      phone: '0212 512 66 31',
      isOpen: false,
      isOnDuty: false,
      branches: [],
      tags: ['Bitkisel Ürünler', 'Medikal Cihaz'],
      reviews: _reviewsAkcay,
      latitude: 41.0532,
      longitude: 28.9145,
      workingHours: '08:30 - 22:00',
    ),
  ];

  // ─────────────────────────────────────────
  //  HOSPITALS (HASTANELER)
  // ─────────────────────────────────────────

  static final List<PlaceModel> hospitals = [
    PlaceModel(
      id: 'h1',
      name: 'Üniversite Göz ve Retina Hastanesi',
      type: PlaceType.hospital,
      rating: 4.8,
      reviewsCount: 1247,
      distanceKm: 1.2,
      address: 'Prof. Dr. Cemil Özden Cad. No:1, Şişli, İstanbul',
      phone: '0212 233 44 55',
      isOpen: true,
      isOnDuty: false,
      branches: ['Göz Hastalıkları', 'Retina', 'Glokom', 'Katarakt Cerrahisi'],
      tags: ['Göz Acili', 'Retina Uzmanı', 'Lazer Tedavi', 'Çocuk Gözü'],
      emergencyTags: ['has_ophthalmology_emergency', 'has_general_emergency'],
      reviews: _reviewsUnivers,
      latitude: 41.0608,
      longitude: 28.9923,
      workingHours: '24 Saat (Acil)',
      appointmentUrl: 'https://mhrs.gov.tr/',
    ),
    PlaceModel(
      id: 'h2',
      name: 'Kalp ve Kardiyoloji Merkezi',
      type: PlaceType.hospital,
      rating: 4.9,
      reviewsCount: 2104,
      distanceKm: 2.1,
      address: 'Abbasağa Mah. Yıldız Cad. No:14, Beşiktaş, İstanbul',
      phone: '0212 310 90 00',
      isOpen: true,
      isOnDuty: false,
      branches: ['Kardiyoloji', 'Kalp ve Damar Cerrahisi', 'Göğüs Hastalıkları', 'Dahiliye (İç Hastalıkları)'],
      tags: ['Kalp Acili', 'Anjiyografi', 'Bypass', 'Ritim Bozukluğu'],
      emergencyTags: ['has_cardiology_emergency', 'has_general_emergency'],
      reviews: _reviewsKalp,
      latitude: 41.0450,
      longitude: 29.0052,
      workingHours: '24 Saat (Acil)',
      appointmentUrl: 'https://mhrs.gov.tr/',
    ),
    PlaceModel(
      id: 'h3',
      name: 'Anne Çocuk Sağlığı Hastanesi',
      type: PlaceType.hospital,
      rating: 4.7,
      reviewsCount: 3215,
      distanceKm: 0.9,
      address: 'Çocuk Sok. No:7, Kadıköy, İstanbul',
      phone: '0216 450 30 30',
      isOpen: true,
      isOnDuty: false,
      branches: [
        'Çocuk Sağlığı ve Hastalıkları (Pediatri)',
        'Çocuk Cerrahisi',
        'Kadın Hastalıkları ve Doğum',
        'Neonatoloji',
      ],
      tags: ['Çocuk Acil', 'Yenidoğan', 'Pediatri', 'Doğum'],
      emergencyTags: ['has_pediatric_emergency', 'has_general_emergency'],
      reviews: _reviewsPediatri,
      latitude: 40.9831,
      longitude: 29.0301,
      workingHours: '24 Saat (Acil)',
      appointmentUrl: 'https://mhrs.gov.tr/',
    ),
    PlaceModel(
      id: 'h4',
      name: 'Ortopedi ve Spor Yaralanmaları Merkezi',
      type: PlaceType.hospital,
      rating: 4.6,
      reviewsCount: 876,
      distanceKm: 1.7,
      address: 'Spor Cad. No:3, Ataşehir, İstanbul',
      phone: '0216 575 77 77',
      isOpen: true,
      isOnDuty: false,
      branches: [
        'Ortopedi ve Travmatoloji',
        'Genel Cerrahi',
        'Beyin ve Sinir Cerrahisi',
        'Fizyoterapi ve Rehabilitasyon',
      ],
      tags: ['Kırık Tespiti', 'Spor Yaralanması', 'Artroskopi', 'Protez'],
      emergencyTags: ['has_orthopedics_emergency', 'has_xray', 'has_general_emergency'],
      reviews: _reviewsOrtopedi,
      latitude: 40.9908,
      longitude: 29.1247,
      workingHours: '24 Saat (Acil)',
      appointmentUrl: 'https://www.acibadem.com.tr/randevu/',
    ),
    PlaceModel(
      id: 'h5',
      name: 'Genel Sağlık Hastanesi',
      type: PlaceType.hospital,
      rating: 4.4,
      reviewsCount: 1532,
      distanceKm: 3.2,
      address: 'Cumhuriyet Cad. No:120, Şişli, İstanbul',
      phone: '0212 219 22 22',
      isOpen: true,
      isOnDuty: false,
      branches: [
        'Dahiliye (İç Hastalıkları)',
        'Nöroloji',
        'Dermatoloji (Cildiye)',
        'Kulak Burun Boğaz (KBB)',
        'Üroloji',
        'Kadın Hastalıkları ve Doğum',
      ],
      tags: ['Poliklinik', 'Labaratuvar', 'Radyoloji', 'Acil Servis'],
      emergencyTags: ['has_general_surgery', 'has_internal_medicine', 'has_neurology_emergency', 'has_dental_emergency', 'has_general_emergency'],
      reviews: _reviewsKalp,
      latitude: 41.0501,
      longitude: 28.9873,
      workingHours: '24 Saat (Acil)',
      appointmentUrl: 'https://mhrs.gov.tr/',
    ),
    PlaceModel(
      id: 'h6',
      name: 'Göğüs ve Solunum Hastalıkları Hastanesi',
      type: PlaceType.hospital,
      rating: 4.5,
      reviewsCount: 689,
      distanceKm: 2.5,
      address: 'Hava Cad. No:22, Bakırköy, İstanbul',
      phone: '0212 570 01 01',
      isOpen: true,
      isOnDuty: false,
      branches: [
        'Göğüs Hastalıkları',
        'Göğüs Cerrahisi',
        'Dahiliye (İç Hastalıkları)',
        'Nöroloji',
      ],
      tags: ['Solunum Acili', 'Astım', 'KOAH', 'Uyku Apnesi'],
      emergencyTags: ['has_cardiology_emergency', 'has_internal_medicine', 'has_general_emergency'],
      reviews: _reviewsUnivers,
      latitude: 40.9718,
      longitude: 28.8703,
      workingHours: '24 Saat (Acil)',
      appointmentUrl: 'https://mhrs.gov.tr/',
    ),
  ];

  // ─────────────────────────────────────────
  //  COMPUTED / FILTERED DATA
  // ─────────────────────────────────────────

  static List<PlaceModel> get allPlaces => [...pharmacies, ...hospitals];

  static List<PlaceModel> get dutyPharmacies =>
      pharmacies.where((p) => p.isOnDuty).toList();

  /// Verilen semptom branşına göre hastaneleri öncelik sırasına göre sıralar
  static List<PlaceModel> getHospitalsForBranch(String branch) {
    final prioritized = hospitals.where((h) => h.branches.contains(branch)).toList();
    final rest = hospitals.where((h) => !h.branches.contains(branch)).toList();
    return [...prioritized, ...rest];
  }

  static PlaceModel? getPlaceById(String id) {
    try {
      return allPlaces.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
