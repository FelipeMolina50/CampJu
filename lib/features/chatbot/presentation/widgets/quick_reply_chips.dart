import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class QuickReplyChips extends StatelessWidget {
  final List<String> chips;
  final void Function(String) onChipTap;

  const QuickReplyChips({
    super.key,
    required this.chips,
    required this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: chips
            .map((chip) => _ChipItem(label: chip, onTap: () => onChipTap(chip)))
            .toList(),
      ),
    );
  }
}

class _ChipItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChipItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
