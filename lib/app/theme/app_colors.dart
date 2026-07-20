import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0F766E);
  static const primarySoft = Color(0xFFE5F3F1);

  // Semantic feature names all resolve to the single DarJar accent.
  static const community = primary;
  static const marketplace = primary;
  static const marketplaceSoft = primarySoft;
  static const services = primary;
  static const servicesSoft = primarySoft;
  static const warning = Color(0xFFE97824);
  static const warningSoft = Color(0xFFFFF1E5);
  static const danger = Color(0xFFE5484D);
  static const canvas = Color(0xFFF8F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF17151D);
  static const inkMuted = Color(0xFF6D6976);
  static const outline = Color(0xFFE7E3EA);
}
