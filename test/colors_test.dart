import 'package:flutter_test/flutter_test.dart';
import 'package:streak_tracker/constants/colors.dart';
import 'package:flutter/material.dart';

void main() {
  group('colorToHex', () {
    test('converts Color to hex string', () {
      const color = Color(0xFFFF0000);
      expect(colorToHex(color), '#FF0000');
    });

    test('converts white', () {
      const color = Color(0xFFFFFFFF);
      expect(colorToHex(color), '#FFFFFF');
    });

    test('converts black', () {
      const color = Color(0xFF000000);
      expect(colorToHex(color), '#000000');
    });
  });

  group('hexToColor', () {
    test('converts hex string to Color', () {
      final color = hexToColor('#FF0000');
      expect(color.value, 0xFFFF0000);
    });

    test('handles lowercase hex', () {
      final color = hexToColor('#ff0000');
      expect(color.value, 0xFFFF0000);
    });

    test('handles hex without hash', () {
      final color = hexToColor('FF0000');
      expect(color.value, 0xFFFF0000);
    });
  });

  group('randomColor', () {
    test('returns a valid Color from palettes', () {
      final color = randomColor();
      // Just check it's a valid Color with full alpha
      expect(color.alpha, 255);
    });
  });

  group('kColorPalettes', () {
    test('has 5 palettes', () {
      expect(kColorPalettes.keys.length, 5);
    });

    test('each palette has 15 colors', () {
      for (final entry in kColorPalettes.entries) {
        expect(entry.value.length, 15,
            reason: '${entry.key} should have 15 colors');
      }
    });

    test('total of 75 colors', () {
      final total =
          kColorPalettes.values.fold<int>(0, (sum, list) => sum + list.length);
      expect(total, 75);
    });

    test('palette names match spec', () {
      expect(kColorPalettes.containsKey('Originals'), isTrue);
      expect(kColorPalettes.containsKey('Earth Tones'), isTrue);
      expect(kColorPalettes.containsKey('Pastels'), isTrue);
      expect(kColorPalettes.containsKey('Landscapes'), isTrue);
      expect(kColorPalettes.containsKey('Metals'), isTrue);
    });
  });

  group('colorToHex and hexToColor roundtrip', () {
    test('roundtrip preserves color', () {
      final allColors =
          kColorPalettes.values.expand((list) => list).toList();
      for (final color in allColors) {
        final hex = colorToHex(color);
        final restored = hexToColor(hex);
        expect(restored.value, color.value,
            reason: 'Color roundtrip failed for $hex');
      }
    });
  });
}
