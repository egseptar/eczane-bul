import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';

/// 112 Acil Çağrı onay kartı.
///
/// [userLat] / [userLng] mevcut konuma göre açık adresi çözer.
/// Kullanıcı "Aramayı Başlat" butonuna basmadan numara çevrilmez.
class EmergencyBottomSheet extends StatefulWidget {
  final double? userLat;
  final double? userLng;

  const EmergencyBottomSheet({
    super.key,
    this.userLat,
    this.userLng,
  });

  /// [showModalBottomSheet] yardımcısı — doğrudan çağırın.
  static Future<void> show(
    BuildContext context, {
    double? userLat,
    double? userLng,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmergencyBottomSheet(
        userLat: userLat,
        userLng: userLng,
      ),
    );
  }

  @override
  State<EmergencyBottomSheet> createState() => _EmergencyBottomSheetState();
}

class _EmergencyBottomSheetState extends State<EmergencyBottomSheet>
    with SingleTickerProviderStateMixin {
  AddressResult? _address;
  bool _loadingAddress = true;
  bool _calling = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    // Nabız animasyonu — kırmızı buton için
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _resolveAddress();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  //  Adres Çözümleme
  // ─────────────────────────────────────────

  Future<void> _resolveAddress() async {
    final lat = widget.userLat ?? LocationService.defaultLat;
    final lng = widget.userLng ?? LocationService.defaultLng;

    final result = await LocationService.instance
        .getAddressFromCoordinates(lat, lng);

    if (mounted) {
      setState(() {
        _address = result;
        _loadingAddress = false;
      });
    }
  }

  // ─────────────────────────────────────────
  //  112 Araması
  // ─────────────────────────────────────────

  Future<void> _call112() async {
    if (_calling) return;
    setState(() => _calling = true);

    final uri = Uri(scheme: 'tel', path: '112');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Bu cihazda telefon araması desteklenmiyor.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.emergencyRed,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _calling = false);
      if (mounted) Navigator.pop(context);
    }
  }

  // ─────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tutma çubuğu ──
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Kırmızı uyarı başlığı ──
          _buildHeader(),

          // ── Ayırıcı ──
          const Divider(height: 1, thickness: 1),

          // ── Konum alanı ──
          _buildLocationSection(),

          const Divider(height: 1, thickness: 1),

          // ── Butonlar ──
          _buildActions(bottomPadding),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          // Nabız ikonu
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: _pulseAnim.value,
              child: child,
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.emergencyRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '112 Acil Çağrı',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.emergencyRed,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Acil çağrı merkezini aramak üzeresiniz.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Konum Alanı
  // ─────────────────────────────────────────

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 16, color: AppColors.emergencyRed),
              const SizedBox(width: 6),
              Text(
                'Mevcut Konumunuz',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Adres alanı — yüklenirken shimmer
          _loadingAddress ? _buildAddressShimmer() : _buildAddressCard(),
        ],
      ),
    );
  }

  Widget _buildAddressShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 22,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final address = _address!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: address.isUnknown
            ? AppColors.warningOrange.withValues(alpha: 0.08)
            : AppColors.emergencyRedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isUnknown
              ? AppColors.warningOrange.withValues(alpha: 0.3)
              : AppColors.emergencyRed.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ana adres
          Text(
            address.shortAddress,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: address.isUnknown
                  ? AppColors.warningOrange
                  : AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (address.fullAddress != address.shortAddress &&
              !address.isUnknown) ...[
            const SizedBox(height: 6),
            Text(
              address.fullAddress,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          // Koordinat bilgisi
          if (address.coordinateText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.gps_fixed_rounded,
                    size: 11, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  address.coordinateText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
          // Bilinmeyen konum uyarısı
          if (address.isUnknown) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ Konumunuzu 112 operatörüne sözlü olarak bildirin.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warningOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Aksiyon Butonları
  // ─────────────────────────────────────────

  Widget _buildActions(double bottomPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 20),
      child: Column(
        children: [
          // App Store Guideline 1.4.1 Tıbbi Uyarı Notu
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '⚠️ Yasal Bilgilendirme: Bu uygulama yalnızca konum yönlendirmesi sağlar ve tıbbi teşhis koymaz. Hayati durumlarda derhal 112 ile iletişime geçiniz.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10.5,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Aramayı Başlat
          ScaleTransition(
            scale: _pulseAnim,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calling ? null : _call112,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  disabledBackgroundColor:
                      AppColors.emergencyRed.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 6,
                  shadowColor:
                      AppColors.emergencyRed.withValues(alpha: 0.4),
                ),
                icon: _calling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.call_rounded, size: 22),
                label: Text(
                  _calling ? 'Aranıyor...' : '📞  Aramayı Başlat — 112',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // İptal
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.border, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'İptal',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
