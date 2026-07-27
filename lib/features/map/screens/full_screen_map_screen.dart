import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../models/place_model.dart';
import '../../detail/screens/detail_screen.dart';

/// Tam Ekran Harita Ekranı (Full Screen Map Screen)
///
/// Yakındaki tüm hastane ve eczaneleri harita üzerinde gösterir.
/// Kurumsal ve sade bir arayüze sahiptir.
class FullScreenMapScreen extends StatefulWidget {
  final List<PlaceModel> places;
  final double? userLat;
  final double? userLng;

  const FullScreenMapScreen({
    super.key,
    required this.places,
    this.userLat,
    this.userLng,
  });

  @override
  State<FullScreenMapScreen> createState() => _FullScreenMapScreenState();
}

class _FullScreenMapScreenState extends State<FullScreenMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;

  late LatLng _userPosition;
  Set<Marker> _markers = {};
  PlaceModel? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _userPosition = LatLng(
      widget.userLat ?? LocationService.defaultLat,
      widget.userLng ?? LocationService.defaultLng,
    );
    _buildMarkers();
    AppTheme.themeNotifier.addListener(_applyMapStyle);
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_applyMapStyle);
    super.dispose();
  }

  void _buildMarkers() {
    final markers = <Marker>{};

    // Kullanıcı Konum Pin'i
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'Konumunuz',
          snippet: 'Anlık bulunduğunuz yer',
        ),
        zIndexInt: 10,
      ),
    );

    // Eczane ve Hastane Pin'leri
    for (final place in widget.places) {
      final isPharmacy = place.isPharmacy;
      final hue = isPharmacy
          ? BitmapDescriptor.hueRed
          : BitmapDescriptor.hueCyan;

      markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude, place.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: '${place.typeLabel} • ${place.distanceText}',
            onTap: () => _onPlaceTap(place),
          ),
          onTap: () {
            setState(() {
              _selectedPlace = place;
            });
          },
        ),
      );
    }

    setState(() => _markers = markers);
  }

  void _onPlaceTap(PlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(place: place),
      ),
    );
  }

  Future<void> _animateCameraToUser() async {
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userPosition, zoom: 15.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Tam Ekran Google Haritası
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userPosition,
              zoom: 14.2,
            ),
            onMapCreated: (controller) {
              _controller.complete(controller);
              _mapController = controller;
              _applyMapStyle();
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onTap: (_) {
              if (_selectedPlace != null) {
                setState(() => _selectedPlace = null);
              }
            },
          ),

          // Üst Zarif Header & Geri Butonu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.85 : 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.85 : 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_rounded, color: AppColors.primaryBlue, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Tam Ekran Harita (${widget.places.length} Konum)',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sağ Üst Konum Butonu
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: GestureDetector(
              onTap: _animateCameraToUser,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
            ),
          ),

          // Seçili Mekan Önizleme Kartı (Bottom Card)
          if (_selectedPlace != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => _onPlaceTap(_selectedPlace!),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: _selectedPlace!.isPharmacy
                          ? AppColors.emergencyRed.withValues(alpha: 0.3)
                          : AppColors.primaryBlue.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: _selectedPlace!.isPharmacy
                              ? AppColors.pharmacyGradient
                              : AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _selectedPlace!.isPharmacy
                              ? Icons.local_pharmacy_rounded
                              : Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedPlace!.name,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedPlace!.typeLabel} • ${_selectedPlace!.distanceText}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Detay',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _applyMapStyle() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      final isDark = AppTheme.themeNotifier.value == ThemeMode.dark;
      if (isDark) {
        await controller.setMapStyle(_darkMapStyle);
      } else {
        await controller.setMapStyle(null);
      }
    } catch (_) {}
  }

  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#1A2232"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1A2232"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8A96A3"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#A5B4FC"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#38BDF8"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#111827"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6B7280"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#1F2937"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#111827"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#9CA3AF"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#374151"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#1F2937"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#0F172A"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#4B5563"}]
    }
  ]
  ''';
}
