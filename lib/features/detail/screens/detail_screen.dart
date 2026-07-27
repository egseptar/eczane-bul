import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/place_model.dart';
import '../widgets/review_card_widget.dart';
import '../widgets/info_row_widget.dart';
import '../../common/widgets/ad_banner_widget.dart';

class DetailScreen extends StatefulWidget {
  final PlaceModel place;

  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  PlaceModel get place => widget.place;

  Future<void> _callPlace() async {
    HapticFeedback.lightImpact();
    final rawPhone = place.phone.trim();
    if (rawPhone.isEmpty) return;

    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arama başlatılamadı.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arama yapılırken bir hata oluştu.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _getDirections() async {
    HapticFeedback.lightImpact();
    final mapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}';
    final uri = Uri.parse(mapsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yol tarifi bağlantısı açılamadı.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yol tarifi açılırken bir hata oluştu.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openAppointmentUrl() async {
    HapticFeedback.lightImpact();
    final url = place.appointmentUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Randevu adresi açılamadı.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı açılırken bir hata oluştu.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildRatingSection(),
                      const SizedBox(height: 20),
                      _buildInfoSection(),
                      if (place.branches.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildBranchesSection(),
                      ],
                      if (place.tags.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildTagsSection(),
                      ],
                      const SizedBox(height: 20),
                      _buildReviewsSection(),
                      const SizedBox(height: 16),
                      _buildDisclaimer(),
                      const SizedBox(height: 20),
                      const Center(child: AdBannerWidget()),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Sabit alt butonlar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroHeader(),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final isPharmacy = place.isPharmacy;
    final gradient =
        isPharmacy ? AppColors.pharmacyGradient : AppColors.primaryGradient;

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isPharmacy
                        ? Icons.local_pharmacy_rounded
                        : Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                place.name,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      place.typeLabel,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (place.isOpen
                              ? AppColors.openGreen
                              : AppColors.closedRed)
                          .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: place.isOpen
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          place.isOpen ? 'AÇIK' : 'KAPALI',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    if (place.rating <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Değerlendirme Bulunmuyor',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Bu kurum için henüz resmi değerlendirme puanı girilmemiştir.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                place.rating.toStringAsFixed(1),
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final full = i < place.rating.floor();
                  final half = !full && i < place.rating;
                  return Icon(
                    full
                        ? Icons.star_rounded
                        : half
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                    color: AppColors.starGold,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatCount(place.reviewsCount)} değerlendirme',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(width: 24),
          Container(
            width: 1,
            height: 70,
            color: AppColors.divider,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRatingBar(5, 0.72),
                _buildRatingBar(4, 0.18),
                _buildRatingBar(3, 0.06),
                _buildRatingBar(2, 0.03),
                _buildRatingBar(1, 0.01),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  stars >= 4 ? AppColors.starGold : AppColors.textTertiary,
                ),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bilgiler',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            InfoRowWidget(
              icon: Icons.location_on_rounded,
              label: 'ADRES',
              value: place.address,
            ),
            const SizedBox(height: 8),
            InfoRowWidget(
              icon: Icons.phone_rounded,
              label: 'TELEFON',
              value: place.phone,
              iconColor: AppColors.green,
              valueColor: AppColors.green,
            ),
            const SizedBox(height: 8),
            InfoRowWidget(
              icon: Icons.access_time_rounded,
              label: 'ÇALIŞMA SAATLERİ',
              value: place.workingHours ?? 'Bilinmiyor',
              isHighlighted: place.isOnDuty,
              iconColor: place.isOpen ? AppColors.openGreen : AppColors.closedRed,
            ),
            const SizedBox(height: 8),
            InfoRowWidget(
              icon: Icons.directions_walk_rounded,
              label: 'UZAKLIK',
              value: place.distanceText,
              iconColor: AppColors.teal,
              valueColor: AppColors.teal,
            ),
            if (place.dutyEndTime != null) ...[
              const SizedBox(height: 8),
              InfoRowWidget(
                icon: Icons.schedule_rounded,
                label: 'NÖBET BİTİŞİ',
                value: place.dutyEndTime!,
                iconColor: AppColors.emergencyRed,
                valueColor: AppColors.emergencyRed,
                isHighlighted: true,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBranchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uzmanlık Alanları',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: place.branches.map((branch) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.tealSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.medical_services_rounded,
                    size: 12,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    branch,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Özellikler',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: place.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlueSurface,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '# $tag',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final reviews = place.reviews.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Kullanıcı Yorumları',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text(
                'Tümünü Gör',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (reviews.isEmpty)
          Center(
            child: Text(
              'Henüz yorum yok.',
              style: AppTextStyles.bodySmall,
            ),
          )
        else
          ...reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReviewCardWidget(review: r),
              )),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emergencyRedSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.emergencyRed.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.emergencyRed,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppConstants.disclaimerText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.emergencyRedDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final hasAppointment = place.appointmentUrl != null && place.appointmentUrl!.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Yol Tarifi
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _getDirections,
              icon: const Icon(Icons.directions_rounded, size: 17),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(hasAppointment ? 'Yol Tarifi' : 'Yol Tarifi Al'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // E-Randevu Butonu (yalnızca randevu adresi varsa)
          if (hasAppointment) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openAppointmentUrl,
                icon: const Icon(Icons.calendar_month_rounded, size: 17),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('E-Randevu'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Ara
          Expanded(
            child: ElevatedButton.icon(
              onPressed: place.phone.trim().isNotEmpty ? _callPlace : null,
              icon: const Icon(Icons.phone_rounded, size: 17),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(hasAppointment ? 'Ara' : 'Hemen Ara'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                disabledBackgroundColor: AppColors.green.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                shadowColor: AppColors.green.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}B';
    }
    return count.toString();
  }
}
