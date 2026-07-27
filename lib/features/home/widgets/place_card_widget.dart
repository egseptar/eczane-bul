import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/place_model.dart';

class PlaceCardWidget extends StatelessWidget {
  final PlaceModel place;
  final String? badgeText;
  final VoidCallback? onTap;

  const PlaceCardWidget({
    super.key,
    required this.place,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: place.isPharmacy
                ? AppColors.emergencyRed.withValues(alpha: 0.15)
                : AppColors.primaryBlue.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst bölüm: İkon + Başlık + Mesafe
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                place.name,
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place.typeLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: place.isPharmacy
                                ? AppColors.emergencyRed
                                : AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (place.branches.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            place.branches.take(2).join(' • '),
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Öneri rozeti (semptom seçildiyse)
            if (badgeText != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF00897B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        badgeText!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Adres
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      place.address,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Alt satır: Puan + Mesafe + Çalışma saati
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  // Yıldız puanı veya Değerlendirme Yok
                  if (place.rating > 0) ...[
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.starGold,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (place.reviewsCount > 0) ...[
                      const SizedBox(width: 3),
                      Text(
                        '(${_formatCount(place.reviewsCount)})',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ] else ...[
                    Icon(
                      Icons.star_outline_rounded,
                      color: AppColors.textTertiary,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Değerlendirme Yok',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],

                  const SizedBox(width: 14),

                  // Mesafe
                  Container(
                    width: 1,
                    height: 14,
                    color: AppColors.divider,
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.directions_walk_rounded,
                    size: 15,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    place.distanceText,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  // Çalışma durumu
                  if (place.isOnDuty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRedSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.emergencyRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.emergencyRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'NÖBETÇİ',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.emergencyRed,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: place.isOpen
                            ? AppColors.greenSurface
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        place.isOpen ? 'AÇIK' : 'KAPALI',
                        style: AppTextStyles.caption.copyWith(
                          color: place.isOpen
                              ? AppColors.openGreen
                              : AppColors.textTertiary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: place.isPharmacy
            ? AppColors.pharmacyGradient
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (place.isPharmacy ? AppColors.emergencyRed : AppColors.primaryBlue)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        place.isPharmacy
            ? Icons.local_pharmacy_rounded
            : Icons.local_hospital_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (place.isOnDuty) {
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}B';
    }
    return count.toString();
  }
}
