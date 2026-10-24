import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette - Refined Slate & Deep Indigo
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color primaryDark = Color(0xFF020617); // Slate 950

  // Brand Accent - Electric Blue
  static const Color accent = Color(0xFF2563EB); // Blue 600
  static const Color accentLight = Color(0xFF3B82F6); // Blue 500
  static const Color accentHover = Color(0xFF1D4ED8); // Blue 700

  // Backgrounds
  static const Color scaffoldBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100

  // Neutral Colors & Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFEEF2F6);

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successBackground = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningBackground = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorBackground = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0EA5E9); // Sky 500
  static const Color infoBackground = Color(0xFFF0F9FF);

  // Status Badges
  static const Color statusPendingPayment = Color(0xFFD97706);
  static const Color statusPendingVerification = Color(0xFF8B5CF6);
  static const Color statusVerified = Color(0xFF10B981);
  static const Color statusProcessing = Color(0xFF3B82F6);
  static const Color statusShipped = Color(0xFF0284C7);
  static const Color statusDelivered = Color(0xFF059669);
  static const Color statusCancelled = Color(0xFF64748B);
  static const Color statusRejected = Color(0xFFDC2626);
}
