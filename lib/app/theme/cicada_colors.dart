import 'package:flutter/material.dart';

/// Semantic color system for CICADA tactical HUD
class CicadaColors {
  CicadaColors._();

  // Base
  static const background = Color(0xFF0B0F14);
  static const surface = Color(0xFF141A22);
  static const surfaceLight = Color(0xFF1C2430);
  static const border = Color(0xFF2A3444);
  static const borderLight = Color(0xFF3A4A5A);

  // Semantic
  static const accent = Color(0xFFFFB84D); // Primary CTA, warnings
  static const energy = Color(0xFF55D0FF); // Online status, active
  static const data = Color(0xFF7C3AED); // Data, links, interactive
  static const ok = Color(0xFF3FB950); // Success, installed
  static const alert = Color(0xFFFF7B72); // Error, danger
  static const error = Color(0xFFFF7B72); // Alias for alert
  static const warning = Color(0xFFFFB84D); // Alias for accent
  static const info = Color(0xFF55D0FF); // Alias for energy
  static const muted = Color(0xFF8B949E); // Secondary text

  // Text
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textTertiary = Color(0xFF6E7681);
}
