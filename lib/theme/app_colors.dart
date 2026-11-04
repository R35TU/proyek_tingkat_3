import 'package:flutter/material.dart';

/// Corporate Slate Color Palette
/// Referensi resmi palet tema:
/// - Navy Slate: #202938 (Header, navbar, sidebar, primary buttons, active states)
/// - Slate: #64748B (Secondary text, icons, subtle borders)
/// - Soft Gray: #F3F4F6 (Background halaman, input fields)
/// - White: #FFFFFF (Card, modal, content surfaces)
class AppColors {
  // ─── CORPORATE SLATE PRIMARY PALETTE ───
  static const Color navySlate = Color(0xFF202938);
  static const Color slate = Color(0xFF64748B);
  static const Color softGray = Color(0xFFF3F4F6);
  static const Color white = Colors.white;

  // ─── SLATE SHADES & SURFACE ACCENTS ───
  static const Color slateLighter = Color(0xFFF1F5F9); // Subtle chip / pill background
  static const Color slateLight = Color(0xFFE2E8F0);   // Subtle container / border
  static const Color slateDark = Color(0xFF334155);    // Intermediate dark text
  static const Color slateNavyDark = Color(0xFF0F172A);// Deepest slate navy

  // ─── SYSTEM & COMPATIBILITY ALIASES ───
  // Primary action color throughout the entire app is now Corporate Navy Slate
  static const Color primaryBlue = navySlate;
  static const Color primary = navySlate;
  static const Color background = softGray;
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = slate;
  static const Color inputBackground = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color blueLight = slateLighter; // Soft slate pill background

  // ─── STATUS & ALERT COLORS (kept outside Corporate Slate as requested) ───
  static const Color primaryRed = Color(0xFFDC2626);     // Danger / Delete / Error
  static const Color successGreen = Color(0xFF10B981);  // Success / Selesai / Positive
  static const Color warningOrange = Color(0xFFF59E0B); // Warning / Pending
}
