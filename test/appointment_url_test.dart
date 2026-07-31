import 'package:flutter_test/flutter_test.dart';
import 'package:eczane_bul/core/services/places_service.dart';
import 'package:eczane_bul/models/place_model.dart';

void main() {
  group('PlacesService.resolveAppointmentUrl Tests', () {
    test('Non-hospital places return null', () {
      expect(
        PlacesService.resolveAppointmentUrl(
          'Acıbadem Eczanesi',
          PlaceType.pharmacy,
        ),
        isNull,
      );
    });

    test('Priority 1 - Direct appointment URLs', () {
      expect(
        PlacesService.resolveAppointmentUrl(
          'Acıbadem Kadıköy Hastanesi',
          PlaceType.hospital,
        ),
        'https://www.acibadem.com.tr/acibademonline/#/login?returnUrl=%2Fdashboard',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'VM Medical Park Kocaeli',
          PlaceType.hospital,
        ),
        'https://www.medicalpark.com.tr/randevu-al/bilgi-dogrulama',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Memorial Şişli Hastanesi',
          PlaceType.hospital,
        ),
        'https://www.memorial.com.tr/randevu-al',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Medicana Kadıköy',
          PlaceType.hospital,
        ),
        'https://www.medicana.com.tr/online-randevu',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Medipol Mega Hastaneler Kompleksi',
          PlaceType.hospital,
        ),
        'https://online.medipol.com.tr/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Liv Hospital Ulus',
          PlaceType.hospital,
        ),
        'https://www.livhospital.com/randevu-al/bilgi-dogrulama',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Florence Nightingale Hastanesi',
          PlaceType.hospital,
        ),
        'https://www.florence.com.tr/online-randevu',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Başkent Üniversitesi Hastanesi',
          PlaceType.hospital,
        ),
        'https://ankara.baskenthastaneleri.com/tr/online-islemler/randevu',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Hisar Intercontinental Hospital',
          PlaceType.hospital,
        ),
        contains('hisarhospital.com/randevu-al'),
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Anadolu Sağlık Merkezi',
          PlaceType.hospital,
        ),
        'https://www.anadolusaglik.org/doktorlar',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Dünyagöz Altunizade',
          PlaceType.hospital,
        ),
        'https://www.dunyagoz.com/tr/islemler/randevu?anaRandevu',
      );
    });

    test('Priority 2 - Newly added hospitals & clinics (Homepage URLs)', () {
      expect(
        PlacesService.resolveAppointmentUrl(
          'Lokman Hekim Hastanesi',
          PlaceType.hospital,
        ),
        'https://www.lokmanhekim.com.tr/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Bayındır Hastanesi Kavaklıdere',
          PlaceType.hospital,
        ),
        'https://www.bayindirhastanesi.com.tr/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Koru Ankara Hastanesi',
          PlaceType.hospital,
        ),
        'https://www.koruhastanesi.com/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Kolan International Hospital',
          PlaceType.hospital,
        ),
        'https://www.kolanhastanesi.com.tr/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Sanko Üniversitesi Hastanesi',
          PlaceType.hospital,
        ),
        'https://www.sankotip.com/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Veni Vidi Göz Merkezi',
          PlaceType.hospital,
        ),
        'https://www.venividigoz.com/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Hospitadent Diş Hastanesi',
          PlaceType.hospital,
        ),
        'https://www.hospitadent.com/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'DentGroup Ağız ve Diş Sağlığı',
          PlaceType.hospital,
        ),
        'https://www.dentgroup.com.tr/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Yeditepe Üniversitesi Diş Hastanesi',
          PlaceType.hospital,
        ),
        'https://yeditepedishastanesi.com/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Okan Üniversitesi Diş Hastanesi',
          PlaceType.hospital,
        ),
        'https://okandishastanesi.com/',
      );
    });

    test('Priority 3 - Fallback to MHRS for public/unmatched hospitals', () {
      expect(
        PlacesService.resolveAppointmentUrl(
          'Ankara Şehir Hastanesi',
          PlaceType.hospital,
        ),
        'https://mhrs.gov.tr/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Haydarpaşa Numune Eğitim ve Araştırma Hastanesi',
          PlaceType.hospital,
        ),
        'https://mhrs.gov.tr/',
      );
      expect(
        PlacesService.resolveAppointmentUrl(
          'Rastgele Özel Poliklinik',
          PlaceType.hospital,
        ),
        'https://mhrs.gov.tr/',
      );
    });
  });
}
