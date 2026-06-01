import 'package:flutter/material.dart';
import '../models/xebo_models.dart';

const kDetractorColor = Color(0xFFF24236);
const kPassiveColor = Color(0xFFFFC208);
const kPromoterColor = Color(0xFF2ECC70);

Color npsColor(int score, XeboNPSLabels? labels) {
  if (score <= 6) {
    return labels?.detractorColor != null
        ? hexToNpsColor(labels!.detractorColor!)
        : kDetractorColor;
  }
  if (score <= 8) {
    return labels?.passiveColor != null
        ? hexToNpsColor(labels!.passiveColor!)
        : kPassiveColor;
  }
  return labels?.promoterColor != null
      ? hexToNpsColor(labels!.promoterColor!)
      : kPromoterColor;
}

Color hexToNpsColor(String hex) {
  final c = hex.replaceAll('#', '');
  if (c.length == 6) return Color(int.parse('FF$c', radix: 16));
  if (c.length == 8) return Color(int.parse(c, radix: 16));
  return kDetractorColor;
}

bool isColorDark(Color color) {
  return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b < 0.5;
}
