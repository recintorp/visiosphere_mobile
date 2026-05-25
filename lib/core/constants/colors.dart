import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary      = Color(0xFF0075A2);
  static const Color primaryLight = Color(0xFF90E0EF);
  static const Color primaryDark  = Color(0xFF00527A);

  // Background
  static const Color background   = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color gradientStart = Color(0xFF0099CC);
  static const Color gradientEnd   = Color(0xFF0075A2);

  // Text Colors
  static const Color textDark  = Color(0xFF333333);
  static const Color textLight = Color(0xFF666666);
  static const Color textHint  = Color(0xFFBBBBBB);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Accent Colors
  static const Color accent  = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA500);
  static const Color error   = Color(0xFFE74C3C);

  // User Type Colors
  static const Color adminColor    = Color(0xFFE91E63);
  static const Color nurseColor    = Color(0xFF2196F3);
  static const Color guardianColor = Color(0xFF4CAF50);

  // ── Dashboard surface tokens (matches web #00212e / #00435c) ──────────────
  static const Color dashBg         = Color(0xFF00212E); // page background
  static const Color dashSurface    = Color(0xFF00435C); // card / panel fill
  static const Color dashSurfaceMid = Color(0xFF003249); // hover / divider
  static const Color dashBorder     = Color(0xFF005271); // card border

  // Dashboard text on dark surface
  static const Color dashTextPrimary   = Color(0xFFFFFFFF);
  static const Color dashTextSecondary = Color(0xFF94A3B8);
  static const Color dashTextMuted     = Color(0xFF64748B);

  // Trend badge colors (matches web BentoStatCard)
  static const Color trendUp      = Color(0xFF4CAF50); // green  — increase
  static const Color trendDown    = Color(0xFFE74C3C); // red    — decrease
  static const Color trendNeutral = Color(0xFF94A3B8); // slate  — no change

  // ── Chart category colors (matches web AlertsChartWidget) ────────────────
  static const Color chartFall       = Color(0xFFEF4444); // red
  static const Color chartAgitation  = Color(0xFFA855F7); // purple
  static const Color chartPacing     = Color(0xFFF97316); // orange
  static const Color chartInactivity = Color(0xFFEAB308); // yellow
  static const Color chartLyingDown  = Color(0xFF64748B); // slate
}