class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'SağlıkSync';
  static const String appTagline = 'Yakındaki Eczane & Hastaneler';

  // Emergency
  static const String emergencyNumber = '112';
  static const String disclaimerText =
      '⚠️ Hayatı tehdit eden acil durumlarda lütfen 112\'yi arayınız.';

  // Filter Categories
  static const String filterAll = 'Tümü';
  static const String filterPharmacy = 'Nöbetçi Eczaneler';
  static const String filterHospital = 'Hastaneler';
  static const String filterSymptom = 'Ne Şikayetiniz Var?';

  // Place Types
  static const String typePharmacy = 'pharmacy';
  static const String typeHospital = 'hospital';
  static const String typeClinic = 'clinic';

  // Symptom Categories
  static const List<Map<String, String>> symptomCategories = [
    {
      'id': 'eye',
      'title': 'Göz / Görme',
      'icon': '👁️',
      'branch': 'Göz Hastalıkları',
      'color': '0xFF1565C0',
    },
    {
      'id': 'chest',
      'title': 'Nefes Darlığı / Göğüs',
      'icon': '🫁',
      'branch': 'Göğüs Hastalıkları',
      'color': '0xFF00897B',
    },
    {
      'id': 'pediatric',
      'title': 'Çocuk Acil',
      'icon': '👶',
      'branch': 'Çocuk Sağlığı ve Hastalıkları (Pediatri)',
      'color': '0xFFE91E63',
    },
    {
      'id': 'dental',
      'title': 'Diş Acil',
      'icon': '🦷',
      'branch': 'Ağız ve Diş Sağlığı',
      'color': '0xFFF57C00',
    },
    {
      'id': 'trauma',
      'title': 'Genel Travma / Kırık',
      'icon': '🦴',
      'branch': 'Ortopedi ve Travmatoloji',
      'color': '0xFF7B1FA2',
    },
  ];

  // Branch Categories
  static const Map<String, List<String>> branchCategories = {
    'Dahili (İç) Bilimler': [
      'Dahiliye (İç Hastalıkları)',
      'Kardiyoloji',
      'Nöroloji',
      'Dermatoloji (Cildiye)',
      'Göğüs Hastalıkları',
      'Çocuk Sağlığı ve Hastalıkları (Pediatri)',
    ],
    'Cerrahi Bilimler': [
      'Genel Cerrahi',
      'Kadın Hastalıkları ve Doğum',
      'Ortopedi ve Travmatoloji',
      'Kulak Burun Boğaz (KBB)',
      'Göz Hastalıkları',
      'Beyin ve Sinir Cerrahisi',
      'Üroloji',
    ],
  };
}
