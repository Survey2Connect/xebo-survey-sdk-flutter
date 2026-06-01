import 'package:flutter/material.dart';
import '../models/xebo_models.dart';

class XeboTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final double cornerRadius;
  final String? fontFamily;

  const XeboTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.cornerRadius,
    this.fontFamily,
  });
}

XeboTheme _currentTheme = const XeboTheme(
  primaryColor: Color(0xFF4F46E5),
  backgroundColor: Color(0xFFFFFFFF),
  textColor: Color(0xFF1F2937),
  cornerRadius: 12,
);

void configureTheme(XeboThemeConfig config) {
  _currentTheme = XeboTheme(
    primaryColor: config.primaryColor != null
        ? _hexToColor(config.primaryColor!)
        : const Color(0xFF4F46E5),
    backgroundColor: config.backgroundColor != null
        ? _hexToColor(config.backgroundColor!)
        : const Color(0xFFFFFFFF),
    textColor: config.textColor != null
        ? _hexToColor(config.textColor!)
        : const Color(0xFF1F2937),
    cornerRadius: config.cornerRadius ?? 12,
    fontFamily: config.fontFamily,
  );
}

XeboTheme getTheme() => _currentTheme;

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  if (cleaned.length == 8) {
    return Color(int.parse(cleaned, radix: 16));
  }
  return const Color(0xFF4F46E5);
}
