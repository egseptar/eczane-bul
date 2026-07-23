import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum FilterType { all, pharmacy, hospital, symptom }

class CategoryFilterWidget extends StatelessWidget {
  final FilterType selected;
  final ValueChanged<FilterType> onChanged;

  const CategoryFilterWidget({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(
            label: 'Tümü',
            icon: Icons.apps_rounded,
            type: FilterType.all,
            activeColor: AppColors.primaryBlue,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Nöbetçi Eczaneler',
            icon: Icons.local_pharmacy_rounded,
            type: FilterType.pharmacy,
            activeColor: AppColors.emergencyRed,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Hastaneler',
            icon: Icons.local_hospital_rounded,
            type: FilterType.hospital,
            activeColor: AppColors.teal,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Ne Şikayetiniz Var?',
            icon: Icons.medical_information_rounded,
            type: FilterType.symptom,
            activeColor: AppColors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required FilterType type,
    required Color activeColor,
  }) {
    final isSelected = selected == type;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : activeColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
