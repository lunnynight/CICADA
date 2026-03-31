import 'package:flutter/material.dart';
import '../theme/cicada_colors.dart';

/// Tactical HUD panel with corner cut decorations
class HudPanel extends StatelessWidget {
  const HudPanel({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.headerAction,
    this.accent,
    this.padding = const EdgeInsets.all(20),
    this.cornerSize = 8.0,
    this.showGrid = false,
  });

  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final Widget? headerAction;
  final Color? accent;
  final EdgeInsets padding;
  final double cornerSize;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? CicadaColors.accent;
    return CustomPaint(
      painter: _HudBorderPainter(
        accent: accentColor,
        cornerSize: cornerSize,
        showGrid: showGrid,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: CicadaColors.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            title != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _HudTitle(
                            title: title!,
                            icon: titleIcon,
                            accent: accentColor,
                          ),
                        ),
                        if (headerAction != null) headerAction!,
                      ],
                    ),
                    const SizedBox(height: 16),
                    child,
                  ],
                )
                : child,
      ),
    );
  }
}

class _HudTitle extends StatelessWidget {
  const _HudTitle({required this.title, this.icon, required this.accent});
  final String title;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: accent),
        const SizedBox(width: 10),
        if (icon != null) ...[
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
        ],
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: CicadaColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _HudBorderPainter extends CustomPainter {
  _HudBorderPainter({
    required this.accent,
    required this.cornerSize,
    required this.showGrid,
  });
  final Color accent;
  final double cornerSize;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    // Optional dot grid background
    if (showGrid) {
      final dotPaint =
          Paint()
            ..color = CicadaColors.textPrimary.withValues(alpha: 0.05)
            ..style = PaintingStyle.fill;
      const spacing = 16.0;
      const dotRadius = 0.5;
      for (double x = spacing; x < size.width; x += spacing) {
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
        }
      }
    }

    final paint =
        Paint()
          ..color = accent.withValues(alpha: 0.4)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    final cs = cornerSize;

    // Top-left corner bracket
    canvas.drawLine(Offset(0, cs), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(cs, 0), paint);

    // Top-right corner bracket
    canvas.drawLine(Offset(size.width - cs, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cs), paint);

    // Bottom-left corner bracket
    canvas.drawLine(Offset(0, size.height - cs), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cs, size.height), paint);

    // Bottom-right corner bracket
    canvas.drawLine(
      Offset(size.width, size.height - cs),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - cs, size.height),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HudBorderPainter old) =>
      accent != old.accent ||
      cornerSize != old.cornerSize ||
      showGrid != old.showGrid;
}
