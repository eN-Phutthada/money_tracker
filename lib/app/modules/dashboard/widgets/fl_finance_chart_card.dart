import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรวิเคราะห์และแนวโน้มการเงินสไตล์ Luxury Modern FinTech Hub 2026
/// 1. กราฟแนวโน้มกระแสเงินสดสุทธิย้อนหลัง 6 เดือน (Enhanced Spline Area Chart)
/// 2. กราฟวงแหวนสัดส่วนรายจ่ายพร้อม Center Cutout Metric และการ์ดแคปซูลหมวดหมู่ (Interactive Donut)
class FlFinanceChartCard extends StatefulWidget {
  const FlFinanceChartCard({super.key});

  @override
  State<FlFinanceChartCard> createState() => _FlFinanceChartCardState();
}

class _FlFinanceChartCardState extends State<FlFinanceChartCard> {
  final DashboardController controller = Get.find<DashboardController>();
  int _touchedPieIndex = -1;

  IconData _getCategoryIcon(String category) {
    if (category.contains('อาหาร') || category.contains('ของกิน') || category.contains('Food')) return Icons.fastfood_rounded;
    if (category.contains('กาแฟ') || category.contains('เครื่องดื่ม') || category.contains('Coffee')) return Icons.local_cafe_rounded;
    if (category.contains('เดินทาง') || category.contains('รถ') || category.contains('Transport')) return Icons.directions_subway_rounded;
    if (category.contains('ช้อปปิ้ง') || category.contains('Shopping')) return Icons.shopping_bag_rounded;
    if (category.contains('ของใช้') || category.contains('Personal')) return Icons.inventory_2_rounded;
    if (category.contains('ที่อยู่อาศัย') || category.contains('Housing')) return Icons.home_rounded;
    if (category.contains('สาธารณูปโภค') || category.contains('Utilities')) return Icons.flash_on_rounded;
    if (category.contains('บันเทิง') || category.contains('Entertainment')) return Icons.movie_rounded;
    if (category.contains('สุขภาพ') || category.contains('Health')) return Icons.health_and_safety_rounded;
    if (category.contains('การศึกษา') || category.contains('Education')) return Icons.school_rounded;
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isSpline = controller.selectedChartIndex.value == 0;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.8),
                width: 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- RESPONSIVE HEADER WITH ICON & SEGMENTED TOGGLE ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 360;

                    final toggleWidget = Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                        children: [
                          _buildTabItem(
                            index: 0,
                            title: 'trend_spline'.tr,
                            icon: Icons.show_chart_rounded,
                            isDark: isDark,
                            expand: isNarrow,
                          ),
                          _buildTabItem(
                            index: 1,
                            title: 'donut_pie'.tr,
                            icon: Icons.pie_chart_outline_rounded,
                            isDark: isDark,
                            expand: isNarrow,
                          ),
                        ],
                      ),
                    );

                    final titleWidget = Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            color: AppColors.primary,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'analytics_and_trends'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                controller.formattedPeriodTitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          titleWidget,
                          const SizedBox(height: 12),
                          toggleWidget,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titleWidget),
                        const SizedBox(width: 12),
                        toggleWidget,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // --- ANIMATED SWITCHER BETWEEN SPLINE AND DONUT ---
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: isSpline ? _buildSplineLineChart(isDark) : _buildDonutPieChart(isDark),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 380), delay: const Duration(milliseconds: 80)).slideY(begin: 0.04);
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
      onTap: () {
        HapticFeedback.selectionClick();
        controller.selectedChartIndex.value = index;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 0.8,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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
  // VIEW 1: ENHANCED SPLINE AREA LINE CHART
  // ==========================================
  Widget _buildSplineLineChart(bool isDark) {
    final data = controller.trailing6MonthsData;
    if (data.isEmpty) return const SizedBox(height: 200);

    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;
    int peakIndex = 0;
    double peakNet = -double.infinity;
    double totalNet = 0.0;

    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['net'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
      totalNet += val;
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
      if (val > peakNet) {
        peakNet = val;
        peakIndex = i;
      }
    }

    final double avgNet = spots.isNotEmpty ? totalNet / spots.length : 0.0;
    final String peakMonthName = data[peakIndex]['month'] as String;

    // Add padding to Y range
    final diff = maxY - minY;
    final pad = diff == 0 ? 1000.0 : diff * 0.22;
    minY -= pad;
    maxY += pad;

    return Column(
      key: const ValueKey('SplineView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick Stat Ribbon (Peak Month & Average Net)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6) : AppColors.surfaceSecondary.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Peak Month Stat
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${'peak_month'.tr}: $peakMonthName (${currencyFmt.format(peakNet)})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Average Net Stat
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: avgNet >= 0 ? AppColors.primary : AppColors.deficitText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${'monthly_avg_net'.tr}: ${currencyFmt.format(avgNet)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: avgNet >= 0 ? AppColors.primary : AppColors.deficitText,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // LineChart with Smooth Cubic Curves
        SizedBox(
          height: 195,
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
                  color: isDark
                      ? AppColors.darkDivider.withValues(alpha: 0.6)
                      : AppColors.divider,
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
                    reservedSize: 26,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        final isPeak = index == peakIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[index]['month'] as String,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isPeak ? FontWeight.w800 : FontWeight.w500,
                              color: isPeak
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkTextTertiary : AppColors.textSecondary),
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
                  getTooltipColor: (_) => isDark ? const Color(0xFF1B2236) : Colors.white,
                  tooltipBorderRadius: BorderRadius.circular(12),
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final item = data[index];
                      final net = spot.y;
                      return LineTooltipItem(
                        '${item['month']}\n${currencyFmt.format(net)}',
                        TextStyle(
                          color: net >= 0 ? AppColors.primary : AppColors.deficitText,
                          fontWeight: FontWeight.w800,
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                  ),
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isPeak = index == peakIndex;
                      return FlDotCirclePainter(
                        radius: isPeak ? 5.5 : 4,
                        color: isPeak ? const Color(0xFF06B6D4) : (isDark ? AppColors.darkSurface : Colors.white),
                        strokeWidth: isPeak ? 3 : 2.5,
                        strokeColor: isPeak ? Colors.white : AppColors.primary,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.22),
                        const Color(0xFF06B6D4).withValues(alpha: 0.0),
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
  // VIEW 2: INTERACTIVE DONUT PIE & CATEGORY CARDS
  // ==========================================
  Widget _buildDonutPieChart(bool isDark) {
    final categories = controller.categoryBreakdown;
    final currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);

    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 42,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                'no_expense_records'.tr,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final double totalExpenses = controller.actualExpenses;
    final Map<String, dynamic>? activeCategory = (_touchedPieIndex >= 0 && _touchedPieIndex < categories.length)
        ? categories[_touchedPieIndex]
        : null;

    final sections = categories.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedPieIndex;
      final radius = isTouched ? 34.0 : 26.0;

      return PieChartSectionData(
        color: item['color'] as Color,
        value: (item['amount'] as num).toDouble(),
        title: '',
        radius: radius,
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(item['percentage'] as num).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.15,
      );
    }).toList();

    return Column(
      key: const ValueKey('DonutView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Donut Chart with Center Cutout Metric
        SizedBox(
          height: 165,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
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
                  sectionsSpace: 3.5,
                  centerSpaceRadius: 44,
                  sections: sections,
                ),
              ),

              // Center Hole Readout
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    activeCategory != null
                        ? (activeCategory['name'] as String).tr
                        : 'total_expenses_cutout'.tr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      activeCategory != null
                          ? currencyFmt.format(activeCategory['amount'])
                          : currencyFmt.format(totalExpenses),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: activeCategory != null
                            ? (activeCategory['color'] as Color)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      ),
                    ),
                  ),
                  if (activeCategory != null) ...[
                    Text(
                      '${(activeCategory['percentage'] as num).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: activeCategory['color'] as Color,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Modern Category Capsule Cards (Top 4 Categories)
        ...categories.take(4).map((item) {
          final color = item['color'] as Color;
          final String catName = (item['name'] as String).tr;
          final double pct = (item['percentage'] as num).toDouble();
          final double amount = (item['amount'] as num).toDouble();
          final icon = _getCategoryIcon(item['name'] as String);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.5) : AppColors.surfaceSecondary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.border.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Category Icon Squircle
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.2 : 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      const SizedBox(width: 8),

                      // Name
                      Expanded(
                        child: Text(
                          catName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Percentage Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Amount
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          currencyFmt.format(amount),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Mini Progress Bar of Proportion
                  Stack(
                    children: [
                      Container(
                        height: 3,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: (pct / 100).clamp(0.0, 1.0),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
