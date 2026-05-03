import 'dart:math';

import 'package:flutter/material.dart';

const Map<String, List<Color>> kColorPalettes = {
  'Originals': [
    Color(0xFFFF1744),
    Color(0xFFE91E63),
    Color(0xFFC653C4),
    Color(0xFF843DF2),
    Color(0xFF432CDD),
    Color(0xFFB9E91F),
    Color(0xFF4DE328),
    Color(0xFF2ECC71),
    Color(0xFF26C6DA),
    Color(0xFF3A78ED),
    Color(0xFFFFC400),
    Color(0xFFFFA90A),
    Color(0xFFFF741E),
    Color(0xFFFF5544),
    Color(0xFFFF5571),
  ],
  'Earth Tones': [
    Color(0xFF5D4037),
    Color(0xFF795548),
    Color(0xFF8D6E63),
    Color(0xFFA1887F),
    Color(0xFFBCAAA4),
    Color(0xFF6D4C41),
    Color(0xFF8A5A44),
    Color(0xFFA66A44),
    Color(0xFFC47A3A),
    Color(0xFFD9984A),
    Color(0xFF827717),
    Color(0xFF9E9D24),
    Color(0xFF7CB342),
    Color(0xFF558B2F),
    Color(0xFF33691E),
  ],
  'Pastels': [
    Color(0xFFFF8A80),
    Color(0xFFFF80AB),
    Color(0xFFEA80FC),
    Color(0xFFB388FF),
    Color(0xFF8C9EFF),
    Color(0xFF82B1FF),
    Color(0xFF80D8FF),
    Color(0xFF84FFFF),
    Color(0xFFA7FFEB),
    Color(0xFFB9F6CA),
    Color(0xFFCCFF90),
    Color(0xFFF4FF81),
    Color(0xFFFFFF8D),
    Color(0xFFFFE57F),
    Color(0xFFFFD180),
  ],
  'Landscapes': [
    Color(0xFF0D47A1),
    Color(0xFF1565C0),
    Color(0xFF0277BD),
    Color(0xFF00838F),
    Color(0xFF00695C),
    Color(0xFF1B5E20),
    Color(0xFF2E7D32),
    Color(0xFF689F38),
    Color(0xFFAFB42B),
    Color(0xFFF9A825),
    Color(0xFFFF8F00),
    Color(0xFFEF6C00),
    Color(0xFFD84315),
    Color(0xFFBF360C),
    Color(0xFF4E342E),
  ],
  'Metals': [
    Color(0xFF263238),
    Color(0xFF37474F),
    Color(0xFF455A64),
    Color(0xFF546E7A),
    Color(0xFF607D8B),
    Color(0xFF78909C),
    Color(0xFF90A4AE),
    Color(0xFFA7B0B8),
    Color(0xFFB0BEC5),
    Color(0xFFCFD8DC),
    Color(0xFF8E8E93),
    Color(0xFFA1A1A6),
    Color(0xFFB8B8BD),
    Color(0xFFC7C7CC),
    Color(0xFFD1D1D6),
  ],
};

String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

Color hexToColor(String hex) {
  return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
}

Color randomColor() {
  final all = kColorPalettes.values.expand((colors) => colors).toList();
  return all[Random().nextInt(all.length)];
}
