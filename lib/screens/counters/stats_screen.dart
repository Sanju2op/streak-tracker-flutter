import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../constants/colors.dart';
import '../../models/counter.dart';
import '../../models/reset.dart';
import '../../providers/counter_provider.dart';
import '../../providers/db_provider.dart';
import '../../utils/stats_utils.dart';
import '../../widgets/error_state.dart';

class StatsScreen extends ConsumerStatefulWidget {
  final String counterId;

  const StatsScreen({super.key, required this.counterId});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  List<Reset> _resets = [];
  Counter? _counter;
  bool _loading = true;
  Object? _error;
  String _selectedPeriod = 'daily';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final db = ref.read(dbAdapterProvider);
      final resets = await db.getResets(widget.counterId);

      final countersAsync = ref.read(countersNotifierProvider);
      final counter = countersAsync.whenOrNull(
        data: (list) {
          try {
            return list.firstWhere((c) => c.id == widget.counterId);
          } catch (_) {
            return null;
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _resets = resets;
        _counter = counter;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    if (_counter == null) return const SizedBox.shrink();

    String text;
    switch (_selectedPeriod) {
      case 'daily':
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final idx = value.toInt();
        text = (idx >= 0 && idx < days.length) ? days[idx] : '';
        break;
      case 'weekly':
        final now = DateTime.now();
        final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStarts = [
          for (var offset = 11; offset >= 0; offset--)
            currentWeekStart.subtract(Duration(days: offset * 7)),
        ];
        final idx = value.toInt();
        if (idx >= 0 && idx < weekStarts.length) {
          final dt = weekStarts[idx];
          text = DateFormat('MMM d').format(dt);
        } else {
          text = '';
        }
        break;
      case 'yearly':
        text = value.toInt().toString();
        break;
      default:
        text = '';
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: context.textSecondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countersAsync = ref.watch(countersNotifierProvider);
    final counter =
        countersAsync.whenOrNull(
          data: (list) {
            try {
              return list.firstWhere((c) => c.id == widget.counterId);
            } catch (_) {
              return null;
            }
          },
        ) ??
        _counter;

    if (_loading) {
      return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: context.bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: kAccentBlue, size: 28),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Stats',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: context.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: context.bgColor,
        appBar: _buildAppBar(context),
        body: ErrorState(onRetry: _load),
      );
    }

    if (counter == null) {
      return Scaffold(
        backgroundColor: context.bgColor,
        appBar: _buildAppBar(context),
        body: Center(
          child: Text(
            'Counter not found',
            style: TextStyle(color: context.textPrimary),
          ),
        ),
      );
    }

    final startDateStr = DateFormat(
      'd MMM yyyy',
    ).format(DateTime.fromMillisecondsSinceEpoch(counter.createdAt));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'TOTAL · ${_resets.length} resets · $startDateStr – Now',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Tab selector
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: ['daily', 'weekly', 'yearly'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.textSecondary.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          period[0].toUpperCase() + period.substring(1),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? context.textPrimary
                                : context.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Chart Card
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: kCardRadius,
              ),
              child: _resets.isEmpty
                  ? Center(
                      child: Text(
                        'No resets yet',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        barGroups: _getBarGroups(counter),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: _bottomTitle,
                              reservedSize: 30,
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.bgColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: kAccentBlue, size: 28),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Stats',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: context.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  List<BarChartGroupData> _getBarGroups(Counter counter) {
    final color = hexToColor(counter.color);
    final rawGroups = buildBarChartData(_resets, _selectedPeriod);

    // Convert to use the right color
    return rawGroups.map((g) {
      return BarChartGroupData(
        x: g.x,
        barRods: g.barRods.map((r) {
          return BarChartRodData(
            toY: r.toY,
            color: color,
            width: _selectedPeriod == 'yearly'
                ? 30
                : (_selectedPeriod == 'daily' ? 20 : 12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          );
        }).toList(),
      );
    }).toList();
  }
}
