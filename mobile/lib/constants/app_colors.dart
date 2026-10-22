import 'package:flutter/material.dart';

class AppColors {
  // === PRIMARY BRAND COLORS - Buti's Bloc ===
  static const primaryBlue =
      Color(0xFF2457DB); // Main button blue - Login, Apply, Done, Log Out
  static const primaryBlueDark =
      Color(0xFF1845D6); // Darker variant for pressed state
  static const darkBlue = Color(0xFF0F2C77); // Logo text BUTI'S BLOC & headers
  static const logoYellow = Color(0xFFF5A623); // Building logo yellow part

  // === BACKGROUNDS & FILLS ===
  static const backgroundWhite = Color(0xFFFFFFFF);
  static const backgroundGrey =
      Color(0xFFF1F1F1); // Page 2 Create Account container
  static const lightGreyFill =
      Color(0xFFEFEFEF); // Page 1 Email/Password input fill
  static const searchGrey = Color(0xFFE0E0E0); // Page 4 Search bar
  static const bottomNavGrey =
      Color(0xFFD9D9D9); // Bottom navigation bar background
  static const cardGrey =
      Color(0xFFD3D3D3); // Page 4 Featured Rooms cards (R4000/R3850)
  static const iconCircleGrey =
      Color(0xFFD9D9D9); // Page 5 & 6 circle icons background

  // === ACCOUNT CREATED PAGE (Page 3) ===
  static const lightBlueCircle = Color(0xFFE8EFFF); // Outer circle behind check
  static const checkBlue = Color(0xFF8CB9FF); // Inner blue circle
  static const checkWhite = Color(0xFFFFFFFF); // Check icon

  // === STATUS COLORS (Page 13 - My Request) ===
  static const statusReceived =
      Color(0xFF00FF00); // Wi-Fi connection - Received - Green
  static const statusReceivedLight = Color(0xFF4ADE80); // Lighter green
  static const statusInProgress =
      Color(0xFFF0A040); // Outside Shower water - Orange
  static const statusOpen = Color(0xFF3B82F6); // Broken Bulb - Blue
  static const studentBadgeGreen = Color(0xFF00FF00); // Page 11 Student badge

  // === TEXT & ACCENTS ===
  static const textBlack = Color(0xFF000000);
  static const textGrey = Color(0xFF6B7280);
  static const textDarkGrey = Color(0xFF9CA3AF);
  static const borderBlack = Color(0xFF000000);
  static const borderGrey =
      Color(0xFFD3D3D3); // Page 10 Application Details border
  static const redLink = Color(0xFFFF0000); // Sign Up, I agree Rules - Red
  static const redError = Color(0xFFDC2626);

  // === NSFAS BADGE (Page 10) ===
  static const nsfasYes = Color(0xFF4ADE80); // Yes badge green

  // === MATERIAL THEME HELPERS ===
  static const primarySwatch = primaryBlue;

  static const gradientBlue = LinearGradient(
    colors: [primaryBlue, darkBlue],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
