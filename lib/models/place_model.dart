import 'review_model.dart';

enum PlaceType { pharmacy, hospital, clinic }

class PlaceModel {
  final String id;
  final String name;
  final PlaceType type;
  final double rating;
  final int reviewsCount;
  final double distanceKm;
  final String address;
  final String phone;
  final bool isOpen;
  final bool isOnDuty; // Nöbetçi mi?
  final List<String> branches; // Uzmanlık alanları / branşlar
  final List<String> tags; // Öne çıkan özellikler
  final List<String> emergencyTags; // Resmî acil yetkinlik etiketleri
  final List<ReviewModel> reviews;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? workingHours;
  final String? dutyEndTime; // Nöbet bitiş saati
  final String? appointmentUrl; // E-Randevu web adresi

  const PlaceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.reviewsCount,
    required this.distanceKm,
    required this.address,
    required this.phone,
    required this.isOpen,
    this.isOnDuty = false,
    this.branches = const [],
    this.tags = const [],
    this.emergencyTags = const [],
    this.reviews = const [],
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.workingHours,
    this.dutyEndTime,
    this.appointmentUrl,
  });

  bool get isPharmacy => type == PlaceType.pharmacy;
  bool get isHospital => type == PlaceType.hospital;
  bool get isClinic => type == PlaceType.clinic;

  String get distanceText {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toInt()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get typeLabel {
    switch (type) {
      case PlaceType.pharmacy:
        return isOnDuty ? 'Nöbetçi Eczane' : 'Eczane';
      case PlaceType.hospital:
        return 'Hastane';
      case PlaceType.clinic:
        return 'Klinik';
    }
  }

  PlaceModel copyWith({
    String? id,
    String? name,
    PlaceType? type,
    double? rating,
    int? reviewsCount,
    double? distanceKm,
    String? address,
    String? phone,
    bool? isOpen,
    bool? isOnDuty,
    List<String>? branches,
    List<String>? tags,
    List<String>? emergencyTags,
    List<ReviewModel>? reviews,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? workingHours,
    String? dutyEndTime,
    String? appointmentUrl,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      distanceKm: distanceKm ?? this.distanceKm,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isOpen: isOpen ?? this.isOpen,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      branches: branches ?? this.branches,
      tags: tags ?? this.tags,
      emergencyTags: emergencyTags ?? this.emergencyTags,
      reviews: reviews ?? this.reviews,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      workingHours: workingHours ?? this.workingHours,
      dutyEndTime: dutyEndTime ?? this.dutyEndTime,
      appointmentUrl: appointmentUrl ?? this.appointmentUrl,
    );
  }
}
