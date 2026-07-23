import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../models/place_model.dart';

import '../../../core/theme/app_theme.dart';

/// Gerçek Google Maps haritasını, kullanıcı konumunu ve
/// eczane/hastane pinlerini gösteren widget.
class MapWidget extends StatefulWidget {
  final List<PlaceModel> places;
  final Function(PlaceModel)? onMarkerTap;
  final VoidCallback? onExpand;

  const MapWidget({
    super.key,
    required this.places,
    this.onMarkerTap,
    this.onExpand,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;

  LatLng _userPosition = const LatLng(
    LocationService.defaultLat,
    LocationService.defaultLng,
  );

  bool _locationLoaded = false;
  bool _locationError = false;

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
    AppTheme.themeNotifier.addListener(_applyMapStyle);
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_applyMapStyle);
    super.dispose();
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places) {
      _buildMarkers();
    }
  }

  // ─────────────────────────────────────────
  //  Konum başlatma
  // ─────────────────────────────────────────

  Future<void> _initLocation() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
          _locationLoaded = true;
        });
        _buildMarkers();
        _animateCameraToUser();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError = true;
          _locationLoaded = true;
        });
        _buildMarkers();
      }
    }
  }

  // ─────────────────────────────────────────
  //  Marker oluşturma
  // ─────────────────────────────────────────

  void _buildMarkers() {
    final markers = <Marker>{};

    // Kullanıcı konumu — mavi pin
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'Konumunuz',
          snippet: 'Şu an buradasınız',
        ),
        zIndexInt: 10,
      ),
    );

    // Eczane ve hastane pinleri
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
            onTap: () => widget.onMarkerTap?.call(place),
          ),
        ),
      );
    }

    setState(() => _markers = markers);
  }

  Future<void> _animateCameraToUser() async {
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userPosition, zoom: 14.5),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userPosition,
                zoom: 14.5,
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
              compassEnabled: false,
              liteModeEnabled: false,
            ),

            // Konum yüklenirken spinner
            if (!_locationLoaded)
              Container(
                color: AppColors.mapBackground.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Konum hatası rozeti
            if (_locationError)
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off_rounded,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        'Konum alınamadı',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Alt overlay — bilgi çubuğu
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    // Konum durumu rozeti
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _locationError
                                  ? AppColors.warningOrange
                                  : AppColors.openGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _locationError
                                ? 'Varsayılan konum'
                                : 'Konumunuz belirlendi',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Haritayı büyüt butonu
                    GestureDetector(
                      onTap: widget.onExpand,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_full_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 5),
                            Text(
                              'Haritayı Aç',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Konumuma dön butonu
            Positioned(
              top: 10,
              right: 12,
              child: GestureDetector(
                onTap: _animateCameraToUser,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
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
