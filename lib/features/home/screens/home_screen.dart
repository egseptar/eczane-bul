import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/places_service.dart';
import '../../../models/place_model.dart';
import '../widgets/emergency_bottom_sheet.dart';
import '../widgets/map_widget.dart';
import '../widgets/place_card_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../../detail/screens/detail_screen.dart';
import '../../map/screens/full_screen_map_screen.dart';
import '../../common/widgets/ad_banner_widget.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────
//  Alt Navigasyon Sekme Türleri
// ─────────────────────────────────────────
enum NavTab { pharmacy, hospital, symptom, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ───────────────────────────────
  NavTab _activeTab = NavTab.pharmacy;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _usedFallback = false;
  bool _locationObtained = false;
  bool _isBusinessHours = true;
  double? _userLat;
  double? _userLng;
  String? _selectedSymptomBranch;
  String? _selectedSymptomTag;

  List<PlaceModel> _allPharmacies = [];
  List<PlaceModel> _allHospitals = [];

  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ─── Lifecycle ──────────────────────────

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Veri Yükleme ───────────────────────

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await DataService.instance.loadAllData();
    if (!mounted) return;

    setState(() {
      _allPharmacies = result.pharmacies;
      _allHospitals = result.hospitals;
      _usedFallback = result.usedFallback;
      _locationObtained = result.locationObtained;
      _isBusinessHours = result.isBusinessHours;
      _userLat = result.userLat;
      _userLng = result.userLng;
      _isLoading = false;
    });
    _animController.forward(from: 0);

    if (_usedFallback) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFallbackBanner());
    }
  }

  void _showFallbackBanner() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: AppColors.warningOrange,
        content: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Canlı veri servisine ulaşılamadı — demo verileri gösteriliyor.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              _loadData();
            },
            child: Text('Yenile',
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: Text('Kapat',
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  // ─── Filtrelenmiş Liste ─────────────────

  List<PlaceModel> get _filteredPlaces {
    List<PlaceModel> base;
    switch (_activeTab) {
      case NavTab.pharmacy:
        base = _allPharmacies;
        break;
      case NavTab.hospital:
        base = PlacesService.sortHospitalsByTriage(
          hospitals: _allHospitals,
          symptomBranch: _selectedSymptomBranch,
          symptomTag: _selectedSymptomTag,
        );
        break;
      default:
        base = [..._allPharmacies, ..._allHospitals]
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
    }
    if (_searchQuery.isEmpty) return base;
    final q = PlacesService.normalizeText(_searchQuery);
    return base.where((p) {
      final normName = PlacesService.normalizeText(p.name);
      final normAddr = PlacesService.normalizeText(p.address);
      final normBranches = p.branches.map(PlacesService.normalizeText);
      return normName.contains(q) ||
          normAddr.contains(q) ||
          normBranches.any((b) => b.contains(q));
    }).toList();
  }

  // ─── Navigasyon Aksiyonları ─────────────

  void _onNavTap(NavTab tab) {
    if (tab == NavTab.symptom) {
      _showSymptomSheet();
      return;
    }
    if (tab == NavTab.settings) {
      _showSettingsSheet();
      return;
    }
    setState(() {
      _activeTab = tab;
      _searchQuery = '';
      _searchController.clear();
      if (tab == NavTab.pharmacy) {
        _selectedSymptomBranch = null;
        _selectedSymptomTag = null;
      }
      _animController.reset();
      _animController.forward();
    });
  }

  // ─── 112 Acil ────────────────────────────

  Future<void> _showEmergencySheet() async {
    await EmergencyBottomSheet.show(
      context,
      userLat: _userLat,
      userLng: _userLng,
    );
  }

  // ─── Şikayet Modal ─────────────────────

  void _showSymptomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SymptomBottomSheet(
        onSymptomSelected: (branch, tag) {
          setState(() {
            _activeTab = NavTab.hospital;
            _selectedSymptomBranch = branch;
            _selectedSymptomTag = tag;
          });
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Menü & Ayarlar Modal Bottom Sheet
  // ─────────────────────────────────────────

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SettingsBottomSheet(),
    );
  }

  // ─────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? const Color(0xFF1E2638) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        extendBody: true,
        bottomNavigationBar: _buildBottomAppBar(),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Header ──
              _buildHeader(),
              // ── Harita + Kart Listesi ──
              Expanded(
                child: _isLoading
                    ? _buildShimmer()
                    : _buildMapWithList(),
              ),
              // Banner Reklamı (Alt Barın Hemen Üstünde)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: AdBannerWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Alt Navigasyon Barı
  // ─────────────────────────────────────────

  Widget _buildBottomAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomPadding > 0 ? bottomPadding : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.14 : 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildNavItem(
                    tab: NavTab.pharmacy,
                    outlinedIcon: Icons.local_pharmacy_outlined,
                    filledIcon: Icons.local_pharmacy_rounded,
                    label: 'Eczane',
                    activeColor: AppColors.pharmacyActive,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    tab: NavTab.hospital,
                    outlinedIcon: Icons.local_hospital_outlined,
                    filledIcon: Icons.local_hospital_rounded,
                    label: 'Hastane',
                    activeColor: AppColors.hospitalActive,
                  ),
                ),
                
                // Merkez Yüzen 112 Acil Butonu (Center Docked)
                Expanded(
                  child: GestureDetector(
                    onTap: _showEmergencySheet,
                    onLongPress: _showEmergencySheet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.emergency112,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emergency112.withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                          SizedBox(height: 2),
                          Text(
                            '112 Acil',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: _buildNavItem(
                    tab: NavTab.symptom,
                    outlinedIcon: Icons.healing_outlined,
                    filledIcon: Icons.healing_rounded,
                    label: 'Şikayet',
                    activeColor: AppColors.symptomActive,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    tab: NavTab.settings,
                    outlinedIcon: Icons.grid_view_outlined,
                    filledIcon: Icons.grid_view_rounded,
                    label: 'Menü',
                    activeColor: AppColors.menuActive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required NavTab tab,
    required IconData outlinedIcon,
    required IconData filledIcon,
    required String label,
    required Color activeColor,
  }) {
    final isActive = _activeTab == tab &&
        tab != NavTab.symptom &&
        tab != NavTab.settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onNavTap(tab),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isActive ? filledIcon : outlinedIcon,
                key: ValueKey('${tab.name}_$isActive'),
                size: 21,
                color: isActive ? activeColor : AppColors.iconInactive,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? activeColor : AppColors.iconInactive,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                fontSize: 10,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Logo + başlık (SağlıkSync markalama)
              Image.asset(
                'assets/images/logo.png',
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _locationObtained
                            ? Icons.my_location_rounded
                            : Icons.location_off_rounded,
                        size: 11,
                        color: _locationObtained
                            ? AppColors.openGreen
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _locationObtained
                            ? 'Konumunuz alındı'
                            : 'Varsayılan konum',
                        style: AppTextStyles.caption.copyWith(
                          color: _locationObtained
                              ? AppColors.openGreen
                              : AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      if (_usedFallback) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warningOrange
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Örnek veri',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warningOrange,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Tema Değiştirici
              GestureDetector(
                onTap: () {
                  final notifier = AppTheme.themeNotifier;
                  notifier.value = notifier.value == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: AppTheme.themeNotifier,
                    builder: (_, mode, __) {
                      final isDark = mode == ThemeMode.dark;
                      return Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      );
                    },
                  ),
                ),
              ),
              // Yenile
              GestureDetector(
                onTap: _loadData,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        )
                      : Icon(Icons.refresh_rounded,
                          size: 18, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SearchBarWidget(
            controller: _searchController,
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Harita + Kart Listesi
  // ─────────────────────────────────────────

  Widget _buildMapWithList() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Harita — tam genişlik, yüksek
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: MapWidget(
                places: _filteredPlaces,
                onMarkerTap: (place) => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailScreen(place: place)),
                ),
                onExpand: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenMapScreen(
                      places: _filteredPlaces,
                      userLat: _userLat,
                      userLng: _userLng,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Liste başlığı
          SliverToBoxAdapter(child: _buildListHeader()),

          // Boş durum veya liste
          _filteredPlaces.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MediaQuery.of(context).padding.bottom + 90,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => PlaceCardWidget(
                        place: _filteredPlaces[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetailScreen(place: _filteredPlaces[i]),
                          ),
                        ),
                      ),
                      childCount: _filteredPlaces.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    final isPharmacy = _activeTab == NavTab.pharmacy;
    final String titleText;
    final IconData headerIcon;
    final Color iconColor;

    if (isPharmacy) {
      if (_isBusinessHours) {
        titleText = 'Açık Eczaneler';
        headerIcon = Icons.local_pharmacy_rounded;
        iconColor = AppColors.pharmacyActive;
      } else {
        titleText = 'Nöbetçi Eczaneler';
        headerIcon = Icons.nightlife_rounded;
        iconColor = AppColors.emergencyRed;
      }
    } else {
      titleText = 'Hastaneler';
      headerIcon = Icons.local_hospital_rounded;
      iconColor = AppColors.hospitalActive;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  headerIcon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                titleText,
                style: AppTextStyles.headlineSmall
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredPlaces.length} sonuç',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // Eczane Sekmesinde Kurumsal Durum Rozeti (Chip)
          if (_activeTab == NavTab.pharmacy) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _isBusinessHours
                    ? AppColors.openGreen.withValues(alpha: isDark ? 0.2 : 0.08)
                    : AppColors.emergencyRed.withValues(alpha: isDark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isBusinessHours
                      ? AppColors.openGreen.withValues(alpha: 0.3)
                      : AppColors.emergencyRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isBusinessHours
                        ? Icons.storefront_rounded
                        : Icons.nightlife_rounded,
                    size: 15,
                    color: _isBusinessHours
                        ? AppColors.openGreen
                        : AppColors.emergencyRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isBusinessHours
                        ? 'Şu An Açık Eczaneler (Mesai Saatleri: 08:30 - 19:00)'
                        : 'Nöbetçi Eczaneler (7/24 Aktif Nöbet Hizmeti)',
                    style: AppTextStyles.caption.copyWith(
                      color: _isBusinessHours
                          ? AppColors.openGreen
                          : AppColors.emergencyRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_activeTab == NavTab.hospital && _selectedSymptomBranch != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_rounded, size: 14, color: AppColors.primaryBlue),
                  const SizedBox(width: 6),
                  Text(
                    'Şikayet: $_selectedSymptomBranch',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSymptomBranch = null;
                      });
                    },
                    child: const Icon(Icons.cancel_rounded, size: 16, color: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Shimmer
  // ─────────────────────────────────────────

  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Harita shimmer
          Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(
              height: 280,
              width: double.infinity,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          // Başlık shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: AppColors.shimmerBase,
              highlightColor: AppColors.shimmerHighlight,
              child: Row(
                children: [
                  Container(
                      width: 180,
                      height: 20,
                      color: Theme.of(context).colorScheme.surface),
                  const Spacer(),
                  Container(
                      width: 60,
                      height: 20,
                      color: Theme.of(context).colorScheme.surface),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Kart shimerler
          ...List.generate(5, (_) => _buildShimmerCard()),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: double.infinity,
                      height: 14,
                      color: Theme.of(context).colorScheme.surface),
                  const SizedBox(height: 8),
                  Container(
                      width: 120,
                      height: 12,
                      color: Theme.of(context).colorScheme.surface),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Boş Durum
  // ─────────────────────────────────────────

  Widget _buildEmptyState() {
    final isHospitalTab = _activeTab == NavTab.hospital;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isHospitalTab
                  ? AppColors.primaryBlue.withValues(alpha: 0.12)
                  : AppColors.primaryBlueSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHospitalTab
                  ? Icons.local_hospital_outlined
                  : Icons.search_off_rounded,
              color: AppColors.primaryBlue,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isHospitalTab
                ? 'Yakında uygun sağlık kuruluşu bulunamadı.'
                : 'Sonuç bulunamadı',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isHospitalTab
                ? 'Konumunuza yakın tanımlı bir hastane bulunamadı veya arama yarıçapı içerisinde yer almıyor.'
                : 'Arama kriterlerinizi değiştirmeyi veya haritayı yakınlaştırmayı deneyin.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Yeniden Ara'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Şikayet Modal Bottom Sheet
// ─────────────────────────────────────────

// ─────────────────────────────────────────
//  Şikayet Modal Bottom Sheet
// ─────────────────────────────────────────

class _SymptomBottomSheet extends StatelessWidget {
  final void Function(String branch, String tag) onSymptomSelected;

  const _SymptomBottomSheet({required this.onSymptomSelected});

  static final List<Map<String, dynamic>> _symptoms = [
    {
      'icon': Icons.monitor_heart_outlined,
      'title': 'Göğüs Ağrısı / Nefes',
      'desc': 'Kalp krizi şüphesi, çarpıntı, göğüste baskı, nefes darlığı.',
      'branch': 'Kardiyoloji',
      'tag': 'has_cardiology_emergency',
    },
    {
      'icon': Icons.personal_injury_outlined,
      'title': 'Kırık / Çıkık / Düşme',
      'desc': 'Şiddetli ağrı, hareket kaybı, travma.',
      'branch': 'Ortopedi ve Travmatoloji',
      'tag': 'has_orthopedics_emergency',
    },
    {
      'icon': Icons.water_drop_outlined,
      'title': 'Kesik / Kanama',
      'desc': 'Şiddetli kanama, derin yara, uzuv yaralanması.',
      'branch': 'Genel Cerrahi',
      'tag': 'has_general_surgery',
    },
    {
      'icon': Icons.child_care_outlined,
      'title': 'Çocuk Acil',
      'desc': 'Yüksek ateş, havale, yutma, ani rahatsızlık.',
      'branch': 'Çocuk Sağlığı ve Hastalıkları (Pediatri)',
      'tag': 'has_pediatric_emergency',
    },
    {
      'icon': Icons.psychology_outlined,
      'title': 'Bayılma / Baş Dönmesi',
      'desc': 'Bilinç kaybı, denge kaybı, ani halsizlik.',
      'branch': 'Nöroloji',
      'tag': 'has_neurology_emergency',
    },
    {
      'icon': Icons.thermostat_outlined,
      'title': 'Zehir / Bulantı / Ateş',
      'desc': 'Zehirlenme şüphesi, şiddetli kusma, inatçı ateş.',
      'branch': 'Dahiliye (İç Hastalıkları)',
      'tag': 'has_internal_medicine',
    },
    {
      'icon': Icons.visibility_outlined,
      'title': 'Göz / Görme',
      'desc': 'Görme kaybı, göze cisim batması, kimyasal temas.',
      'branch': 'Göz Hastalıkları',
      'tag': 'has_ophthalmology_emergency',
    },
    {
      'icon': Icons.medical_services_outlined,
      'title': 'Diş Acil',
      'desc': 'Şiddetli diş ağrısı, apse, kırılma.',
      'branch': 'Ağız ve Diş Sağlığı',
      'tag': 'has_dental_emergency',
    },
    {
      'icon': Icons.pregnant_woman_outlined,
      'title': 'Kadın Doğum / Hamilelik',
      'desc': 'Doğum sancısı, kanama, jinekolojik acil.',
      'branch': 'Kadın Hastalıkları ve Doğum',
      'tag': 'has_obgyn_emergency',
    },
    {
      'icon': Icons.health_and_safety_outlined,
      'title': 'Yanık / Cilt / Alerji',
      'desc': 'Şiddetli yanık, alerjik reaksiyon, cilt rahatsızlığı.',
      'branch': 'Dermatoloji (Cildiye)',
      'tag': 'has_dermatology_emergency',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.health_and_safety_outlined,
                        color: AppColors.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Şikayetiniz Nedir?',
                        style: AppTextStyles.headlineSmall
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Acil durumunuza uygun şikayeti seçin',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // App Store Guideline 1.4.1 Tıbbi Bilgilendirme Bandı
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tıbbi Sorumluluk Reddi: Seçimleriniz teşhis koymaz; ilgili branşa sahip en yakın acil polikliniklerini filtreler.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // İçerik
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _symptoms.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) {
                  final item = _symptoms[index];
                  return _buildSymptomCard(context, item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomCard(BuildContext context, Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = item['icon'] as IconData;
    final title = item['title'] as String;
    final desc = item['desc'] as String;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onSymptomSelected(item['branch'] as String, item['tag'] as String);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.12 : 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon Kutusu
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 26,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
            // Başlık
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            // Açıklama
            Expanded(
              child: Text(
                desc,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  App Store Uyumlu Menü & Ayarlar Modal
// ─────────────────────────────────────────

class _SettingsBottomSheet extends StatefulWidget {
  const _SettingsBottomSheet();

  @override
  State<_SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<_SettingsBottomSheet> {
  Future<void> _launchLegalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Hukuki URL açılırken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutma çubuğu
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue
                        .withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_outlined,
                      color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menü & Ayarlar',
                      style: AppTextStyles.headlineSmall
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Uygulama tercihleri ve yasal bilgilendirme',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ── Karanlık Mod Anahtarı ──
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppTheme.themeNotifier,
              builder: (context, mode, child) {
                final isDarkModeActive = mode == ThemeMode.dark;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: isDark ? 0.1 : 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDarkModeActive
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.primaryBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Karanlık Mod (Dark Theme)',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              isDarkModeActive
                                  ? 'Koyu lacivert gece görünümü aktif'
                                  : 'Açık görünüm aktif',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isDarkModeActive,
                        activeColor: AppColors.primaryBlue,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          AppTheme.themeNotifier.value =
                              val ? ThemeMode.dark : ThemeMode.light;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // ── Hukuki Metinler & Yasal Bağlantılar (Apple Guideline) ──
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.1 : 0.05),
                ),
              ),
              child: Column(
                children: [
                  // 1. Gizlilik Politikası
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue
                            .withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Gizlilik Politikası',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Kişisel veri ve konum politikasını inceleyin',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _launchLegalUrl(
                          'https://sites.google.com/view/sagliksync-app/home');
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.1 : 0.05),
                  ),
                  // 2. Kullanım Koşulları
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue
                            .withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Kullanım Koşulları',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Uygulama kullanım şartları ve kurallar',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _launchLegalUrl('https://senin-siten.com/terms');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── App Store Guideline 1.4.1 Tıbbi Sorumluluk Reddi ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.1 : 0.05),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: AppColors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tıbbi Sorumluluk Reddi (Guideline 1.4.1)',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bu uygulama kamuya açık nöbetçi eczane ve acil servis verilerini haritada gösterir. Tıbbi teşhis koymaz veya tedavi sunmaz. Tıbbi kararlarınız için daima doktorunuza danışın.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── App Store Guideline 5.1 Gizlilik ve KVKK ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.1 : 0.05),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gizlilik & Konum Güvenliği (Guideline 5.1)',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Konum verileriniz yalnızca yakın çevrenizdeki nöbetçi eczaneleri mesafeye göre sıralamak için anlık olarak kullanılır ve cihazınızdan dışarı aktarılmaz.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Geliştirici & Versiyon (Guideline 1.5) ──
            Center(
              child: Text(
                'SağlıkSync v1.0.0 (Build 100) • App Store Uyumlu Sürüm',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
