import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../models/skill.dart';

/// Diagonal stripe overlay painter (Arknights aesthetic).
class DiagonalStripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const gap = 10.0;
    const extent = 48.0;
    for (var i = 0; i < 4; i++) {
      final offset = i * gap;
      canvas.drawLine(
        Offset(size.width - extent + offset, 0),
        Offset(size.width, extent - offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Corner bracket painter.
class CornerBracketsPainter extends CustomPainter {
  final Color color;

  CornerBracketsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const len = 6.0;
    // Top-left
    canvas.drawLine(const Offset(0, len), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    // Bottom-right
    canvas.drawLine(
      Offset(size.width - len, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - len),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Skill card widget displaying skill info and install/uninstall actions.
class SkillCard extends StatelessWidget {
  final Skill skill;
  final bool isInstalled;
  final bool isInstalling;
  final bool openclawRunning;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  const SkillCard({
    super.key,
    required this.skill,
    required this.isInstalled,
    required this.isInstalling,
    required this.openclawRunning,
    required this.onInstall,
    required this.onUninstall,
  });

  Color get _accentColor {
    if (isInstalled) return CicadaColors.ok;
    if (skill.isBundled) return CicadaColors.accent;
    return CicadaColors.data;
  }

  String get _rarityDots {
    if (skill.isBundled) return '◆◆◆';
    if (skill.downloads > 5000) return '◆◆';
    return '◆';
  }

  Color get _rarityColor {
    if (skill.isBundled) return CicadaColors.accent;
    if (skill.downloads > 5000) return CicadaColors.data;
    return CicadaColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CornerBracketsPainter(_accentColor),
      child: Container(
        decoration: BoxDecoration(
          color: CicadaColors.surface,
          border: Border(
            top: BorderSide(color: _accentColor, width: 2),
            left: const BorderSide(color: CicadaColors.border, width: 1),
            right: const BorderSide(color: CicadaColors.border, width: 1),
            bottom: const BorderSide(color: CicadaColors.border, width: 1),
          ),
        ),
        child: ClipRect(
          child: Stack(
            children: [
              // Diagonal stripe overlay top-right
              Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CustomPaint(painter: DiagonalStripesPainter()),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Icon(Icons.extension, color: _accentColor, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            skill.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: CicadaColors.textPrimary,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _rarityDots,
                          style: TextStyle(
                            fontSize: 9,
                            color: _rarityColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Badges row
                    Row(
                      children: [
                        if (skill.isBundled) ...[
                          Badge(label: 'BUILT-IN', color: CicadaColors.accent),
                          const SizedBox(width: 4),
                        ],
                        if (isInstalled)
                          Badge(label: 'DEPLOYED', color: CicadaColors.ok),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      skill.description,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: CicadaColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Meta row
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 11,
                          color: CicadaColors.textTertiary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          skill.author,
                          style: const TextStyle(
                            fontSize: 10,
                            color: CicadaColors.textTertiary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (skill.downloads > 0) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.download_outlined,
                            size: 11,
                            color: CicadaColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDownloads(skill.downloads),
                            style: const TextStyle(
                              fontSize: 10,
                              color: CicadaColors.textTertiary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        if (skill.isBundled && skill.downloads == 0) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.offline_bolt_outlined,
                            size: 11,
                            color: CicadaColors.accent.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'OFFLINE',
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  CicadaColors.accent.withValues(alpha: 0.8),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: isInstalling
                          ? OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: CicadaColors.border,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              child: const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: CicadaColors.data,
                                ),
                              ),
                            )
                          : isInstalled
                              ? OutlinedButton(
                                  onPressed:
                                      openclawRunning ? onUninstall : null,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: CicadaColors.border,
                                    ),
                                    foregroundColor: openclawRunning
                                        ? CicadaColors.muted
                                        : CicadaColors.textTertiary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  child: const Text('[ REMOVE ]'),
                                )
                              : ElevatedButton(
                                  onPressed: openclawRunning ? onInstall : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: skill.isBundled
                                        ? CicadaColors.accent
                                        : CicadaColors.data,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        CicadaColors.surface,
                                    disabledForegroundColor:
                                        CicadaColors.textTertiary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.5,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    skill.isBundled
                                        ? '[ DEPLOY ]'
                                        : '[ ACQUIRE ]',
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDownloads(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

/// Small label badge widget.
class Badge extends StatelessWidget {
  final String label;
  final Color color;

  const Badge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
