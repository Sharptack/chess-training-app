import 'package:flutter/material.dart';

/// Responsive utilities for handling different screen sizes
class ResponsiveUtils {
  // Breakpoints for different device sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Returns the screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Returns the screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is mobile size
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < mobileBreakpoint;
  }

  /// Check if device is tablet size
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if device is desktop size
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= desktopBreakpoint;
  }

  /// Get device type enum
  static DeviceType getDeviceType(BuildContext context) {
    if (isMobile(context)) return DeviceType.mobile;
    if (isTablet(context)) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Get responsive horizontal padding based on screen width
  static double getHorizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobileBreakpoint) {
      return 16.0;
    } else if (width < tabletBreakpoint) {
      return 24.0;
    } else {
      return 32.0;
    }
  }

  /// Get responsive vertical padding based on screen height
  static double getVerticalPadding(BuildContext context) {
    final height = screenHeight(context);
    if (height < 700) {
      return 12.0;
    } else if (height < 900) {
      return 16.0;
    } else {
      return 24.0;
    }
  }

  /// Get responsive grid column count
  static int getGridColumnCount(BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
  }) {
    if (isMobile(context)) return mobileColumns;
    if (isTablet(context)) return tabletColumns;
    return desktopColumns;
  }

  /// Get responsive spacing based on screen size
  static double getSpacing(BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get responsive value based on screen size
  static T getValue<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Calculate responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = screenWidth(context);
    if (width < mobileBreakpoint) {
      return baseSize * 0.9;
    } else if (width < tabletBreakpoint) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }

  /// Get chess board size based on available space
  static double getChessBoardSize(BuildContext context, BoxConstraints constraints) {
    final padding = getHorizontalPadding(context) * 2;
    final maxSize = constraints.maxWidth - padding;
    final maxHeight = constraints.maxHeight * 0.7; // Leave room for UI
    return maxSize < maxHeight ? maxSize : maxHeight;
  }

  /// Get icon size based on device type
  static double getIconSize(BuildContext context, {
    double mobile = 24.0,
    double tablet = 28.0,
    double desktop = 32.0,
  }) {
    return getValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Extension on BuildContext for easier access to responsive utilities
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);
  double get screenWidth => ResponsiveUtils.screenWidth(this);
  double get screenHeight => ResponsiveUtils.screenHeight(this);
  double get horizontalPadding => ResponsiveUtils.getHorizontalPadding(this);
  double get verticalPadding => ResponsiveUtils.getVerticalPadding(this);
}
