import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../constants/colors.dart';

/// Opens a half-height bottom sheet with a paged color palette picker.
///
/// Returns the selected [Color] (as hex string) or `null` if dismissed.
/// See `UI Images/Pick_a_color_drawer_view_create-edit_counter_view.PNG`.
Future<Color?> showColorPickerSheet(
  BuildContext context, {
  Color? currentColor,
}) {
  return showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(borderRadius: kSheetRadius),
    backgroundColor: Colors.white,
    builder: (_) => _ColorPickerBody(currentColor: currentColor),
  );
}

class _ColorPickerBody extends StatefulWidget {
  final Color? currentColor;
  const _ColorPickerBody({this.currentColor});

  @override
  State<_ColorPickerBody> createState() => _ColorPickerBodyState();
}

class _ColorPickerBodyState extends State<_ColorPickerBody> {
  late final PageController _pageController;
  late Color _selected;
  int _currentPage = 0;

  static final _paletteEntries = kColorPalettes.entries.toList();

  @override
  void initState() {
    super.initState();
    _selected = widget.currentColor ?? _paletteEntries.first.value.first;

    // Find which palette page the current color belongs to.
    _currentPage = 0;
    for (int i = 0; i < _paletteEntries.length; i++) {
      if (_paletteEntries[i].value.any(
        (c) => c.toARGB32() == _selected.toARGB32(),
      )) {
        _currentPage = i;
        break;
      }
    }

    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Header: "Pick a color" + close button ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'Pick a color',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: kTextSecondary),
                    onPressed: () => Navigator.pop(context, _selected),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // --- Palette name ---
          Text(
            _paletteEntries[_currentPage].key.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // --- PageView of color grids ---
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _paletteEntries.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (_, index) {
                final colors = _paletteEntries[index].value;
                return _ColorGrid(
                  colors: colors,
                  selected: _selected,
                  onSelect: (color) {
                    setState(() => _selected = color);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // --- Page indicator dots ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_paletteEntries.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 8 : 6,
                height: isActive ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? kTextPrimary
                      : kTextSecondary.withValues(alpha: 0.4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// 5-column × 3-row grid of color circles.
class _ColorGrid extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;

  const _ColorGrid({
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: colors.length,
      itemBuilder: (_, index) {
        final color = colors[index];
        final isSelected = color.toARGB32() == selected.toARGB32();

        return GestureDetector(
          onTap: () => onSelect(color),
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
