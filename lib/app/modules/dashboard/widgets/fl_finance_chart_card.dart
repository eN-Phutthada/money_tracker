import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';

/// กราฟวิเคราะห์การเงินระดับพรีเมียม ขับเคลื่อนด้วย fl_chart (Spline Area & Donut)
class FlFinanceChartCard extends StatefulWidget {
  const FlFinanceChartCard({super.key});

  @override
  State<FlFinanceChartCard> createState() => _FlFinanceChartCardState();
}

class _FlFinanceChartCardState extends State<FlFinanceChartCard> {
  final DashboardController controller = Get.find<DashboardController>();
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isSpline = controller.selectedChartIndex.value == 0;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Responsive Header with Segmented Toggle
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;

                final toggleWidget = Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      _buildTabItem(
                        index: 0,
                        title: 'แนวโน้ม Spline',
                        icon: Icons.show_chart_rounded,
                        isDark: isDark,
                        expand: isNarrow,
                      ),
                      _buildTabItem(
                        index: 1,
                        title: 'สัดส่วนเค้ก',
                        icon: Icons.pie_chart_outline_rounded,
                        isDark: isDark,
                        expand: isNarrow,
                      ),
                    ],
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'การวิเคราะห์และแนวโน้ม',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      toggleWidget,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'การวิเคราะห์และแนวโน้ม',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    toggleWidget,
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Animated Switcher between LineChart and PieChart
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isSpline ? _buildSplineLineChart(isDark) : _buildDonutPieChart(isDark),
            ),
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 100)).slideY(begin: 0.04);
    });
  }

  Widget _buildTabItem({
    required int index,
    required String title,
    required IconData icon,
    required bool isDark,
    bool expand = false,
  }) {
    final isSelected = controller.selectedChartIndex.value == index;

    Widget btn = GestureDetector(
      onTap: () => controller.selectedChartIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : AppColors.surface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (expand) return Expanded(child: btn);
    return btn;
  }

  // ==========================================
  // FL_CHART 1: SPLINE AREA LINE CHART
  // ==========================================
  Widget _buildSplineLineChart(bool isDark) {
    final data = controller.trailing6MonthsData;
    if (data.isEmpty) return const SizedBox(height: 180);

    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['net'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }

    // Add padding to Y range
    final diff = maxY - minY;
    final pad = diff == 0 ? 1000.0 : diff * 0.2;
    minY -= pad;
    maxY += pad;

    return Column(
      key: const ValueKey('SplineView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'กระแสเงินสุทธิ 6 เดือนล่าสุด',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Net Balance',
                  style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[index]['month'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => isDark ? AppColors.darkSurfaceSecondary : AppColors.surface,
                  tooltipBorderRadius: BorderRadius.circular(12),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final item = data[index];
                      final net = spot.y;
                      return LineTooltipItem(
                        '${item['month']}\n${net.toStringAsFixed(0)} ฿',
                        TextStyle(
                          color: net >= 0 ? AppColors.primary : AppColors.deficitText,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: AppColors.primary,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.28),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FL_CHART 2: DONUT PIE CHART
  // ==========================================
  Widget _buildDonutPieChart(bool isDark) {
    final categories = controller.categoryBreakdown;

    if (categories.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('ไม่มีรายการรายจ่ายในรอบนี้', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final sections = categories.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedPieIndex;
      final radius = isTouched ? 34.0 : 28.0;

      return PieChartSectionData(
        color: item['color'] as Color,
        value: (item['amount'] as num).toDouble(),
        title: '${(item['percentage'] as num).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 12 : 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      key: const ValueKey('DonutView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedPieIndex = -1;
                      return;
                    }
                    _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Legend List
        ...categories.take(4).map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(item['percentage'] as num).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(item['amount'] as num).toStringAsFixed(0)} ฿',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
