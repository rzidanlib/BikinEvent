import 'package:flutter/material.dart';

/// Semua warna aplikasi didefinisikan di sini, sesuai Color Palette design.
/// Jangan hardcode Colors.xxx langsung di halaman — selalu rujuk ke sini.
class AppColors {
  AppColors._(); // mencegah class ini diinstansiasi

  // Primary
  static const Color primary = Color(0xFFF76B10); // Orange
  static const Color primaryLight1 = Color(0xFFF98B3D);
  static const Color primaryLight2 = Color(0xFFFAAA6B);
  static const Color primaryLight3 = Color(0xFFFCC99A);

  // Secondary
  static const Color yellow = Color(0xFFFBBE47);
  static const Color blue = Color(0xFF3E82F7);
  static const Color green = Color(0xFF29D697);
  static const Color darkOrange = Color(0xFF8C3700);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFF0F0EE);
  static const Color grey2 = Color(0xFFE1E1E1);
  static const Color softDarkish = Color(0xFF4A4D55);

  // Gradient
  static const Color orangeLinearStart = Color(0xFFF76B10);
  static const Color blackLinear = Color(0xFF171924);
  static const Color buttonLinear = Color(0xFF20222C);

  // Text
  static const Color textBlack = Color(0xFF20222C);
  static const Color textWhite = Color(0xFFFDFDFD);

  // State
  static const Color info = Color(0xFF2F80ED);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFE2B93B);
  static const Color error = Color(0xFFEB5757);

  // Background
  static const Color background = Color(0xFFF0F0EE);

  // Gradient yang siap pakai untuk tombol/hero section
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [buttonLinear, blackLinear],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color heroDarkStart = Color(0xFF20222C);
  static const Color heroDarkEnd = Color(0xFF171924);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [heroDarkStart, heroDarkEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Overlay gelap tipis di atas gambar poster, supaya teks/icon tetap terbaca
  static LinearGradient imageOverlayGradient = LinearGradient(
    colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
