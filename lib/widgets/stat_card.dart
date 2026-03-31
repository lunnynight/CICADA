import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';

/// Stat card widget for dashboard
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final Color? iconColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CicadaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CicadaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon + Label
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: iconColor ?? CicadaColors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CicadaColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Main value
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: CicadaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Hint text
            Text(
              hint,
              style: const TextStyle(
                fontSize: 12,
                color: CicadaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
