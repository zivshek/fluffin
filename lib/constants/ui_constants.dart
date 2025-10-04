import 'package:flutter/material.dart';

/// UI Constants for consistent design across the app
class UIConstants {
  // Screen breakpoints
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;

  // Card dimensions
  static const double posterCardWidthMobile = 130.0;
  static const double posterCardWidthTablet = 150.0;
  static const double posterCardWidthDesktop = 160.0;

  // Continue watching and next up card dimensions
  static const double continueWatchingCardWidth = 280.0;
  static const double nextUpCardWidth = 280.0;
  static const double continueWatchingHeight = 200.0;
  static const double nextUpHeight = 200.0;

  // Library category card dimensions
  static const double libraryCategoryCardWidth = 280.0;
  static const double libraryCategoryCardHeight = 160.0;

  // Section heights
  static const double posterSectionHeight = 270.0;

  // Poster card dimensions
  static const double posterCardImageHeight = 200.0;
  static const double posterTextSpacing = 8.0;
  static const double posterTitleYearSpacing = 2.0;
  static const double libraryCategorySectionHeight = 160.0;

  // Spacing
  static const double sectionSpacing = 16.0;
  static const double cardSpacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 12.0;
  static const double largeSpacing = 32.0;

  // Padding
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets sectionPadding =
      EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(8.0);

  // Border radius
  static const double cardBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  // Colors
  static const Color primaryColor = Color(0xFF00A4DC);
  static const Color backgroundColor = Colors.white;
  static const Color cardBackgroundColor = Color(0xFFF5F5F5);
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Colors.grey;

  // Typography
  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textSecondaryColor,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );

  static const TextStyle cardSubtitleStyle = TextStyle(
    fontSize: 12,
    color: textSecondaryColor,
  );

  static const TextStyle continueWatchingTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle nextUpTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  // Helper methods
  static double getPosterCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= desktopBreakpoint) {
      return posterCardWidthDesktop;
    } else if (screenWidth >= tabletBreakpoint) {
      return posterCardWidthTablet;
    } else {
      return posterCardWidthMobile;
    }
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
    } else {
      return screenPadding;
    }
  }

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Image dimensions for API calls
  static const int posterImageWidth = 300;
  static const int posterImageHeight = 450;
  static const int backdropImageWidth = 800;
  static const int backdropImageHeight = 450;
  static const int thumbnailImageWidth = 500;
  static const int thumbnailImageHeight = 280;
}
