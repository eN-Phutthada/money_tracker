import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/nothing_ui_components.dart';
import '../controllers/dashboard_controller.dart';

/// บัตรวิเคราะห์และแนวโน้มการเงินสไตล์ Nothing OS Design
/// 1. กราฟแนวโน้มกระแสเงินสดสุทธิย้อนหลัง 6 เดือน (Nothing Monochrome Spline Chart w/ Red Peak Pulse)
/// 2. กราฟวงแหวนสัดส่วนรายจ่ายพร้อม Center Cutout Metric และการ์ดหมวดหมู่สไตล์ Nothing OS (Monochrome & Red Accents)
class FlFinanceChartCard extends StatefulWidget {
  const FlFinanceChartCard({super.key});

  @override
  State<FlFinanceChartCard> createState() => _FlFinanceChartCardState();
}

class _FlFinanceChartCardState extends State<FlFinanceChartCard> {
  final DashboardController controller = Get.find<DashboardController>();
  int _touchedPieIndex = -1;

  IconData _getCategoryIcon(String category) {
    if (category.contains('อาหาร') || category.contains('ของกิน') || category.contains('Food')) return Icons.fastfood_outlined;
    if (category.contains('กาแฟ') || category.contains('เครื่องดื่ม') || category.contains('Coffee')) return Icons.local_cafe_outlined;
    if (category.contains('เดินทาง') || category.contains('รถ') || category.contains('Transport')) return Icons.directions_subway_outlined;
    if (category.contains('ช้อปปิ้ง') || category.contains('Shopping')) return Icons.shopping_bag_outlined;
    if (category.contains('ของใช้') || category.contains('Personal')) return Icons.inventory_2_outlined;
    if (category.contains('ที่อยู่อาศัย') || category.contains('Housing')) return Icons.home_outlined;
    if (category.contains('สาธารณูปโภค') || category.contains('Utilities')) return Icons.bolt_outlined;
    if (category.contains('บันเทิง') || category.contains('Entertainment')) return Icons.movie_outlined;
    if (category.contains('สุขภาพ') || category.contains('Health')) return Icons.health_and_safety_outlined;
    if (category.contains('การศึกษา') || category.contains('Education')) return Icons.school_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isSpline = controller.selectedChartIndex.value == 0;

      return NothingCard(
        showDotGrid: true,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER WITH NOTHING OS GLYPH & SEGMENTED SWITCH ---
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;

                final toggleWidget = Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF000000) : const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      _buildNothingTabItem(
                        index: 0,
                        title: 'TREND',
                        icon: Icons.show_chart_rounded,
                        isDark: isDark,
                        expand: isNarrow,
                      ),
                      _buildNothingTabItem(
                        index: 1,
                        title: 'DONUT',
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
                        color: isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.insights_rounded,
                          color: isDark ? Colors.white : Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const NothingLedIndicator(color: AppColors.nothingRed, size: 6, isPulsing: true),
                              const SizedBox(width: 6),
                              Expanded(
                                child: NothingDotText(
                                  'ANALYTICS // TRENDS',
                                  fontSize: 12.5,
                                  letterSpacing: 1.2,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.formattedPeriodTitle.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.nothingSubtext : const Color(0xFF6B7280),
                              letterSpacing: 0.6,
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
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: isSpline ? _buildNothingSplineChart(isDark) : _buildNothingDonutChart(isDark),
            ),
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 350)).slideY(begin: 0.04);
    });
  }

  Widget _buildNothingTabItem({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF222222) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isSelected
              ? Border.all(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.1),
                  width: 0.8,
                )
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
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? AppColors.nothingSubtext : const Color(0xFF888888)),
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.8,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? AppColors.nothingSubtext : const Color(0xFF888888)),
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
  // VIEW 1: NOTHING OS MONOCHROME SPLINE CHART
  // ==========================================
  Widget _buildNothingSplineChart(bool isDark) {
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

    final diff = maxY - minY;
    final pad = diff == 0 ? 1000.0 : diff * 0.24;
    minY -= pad;
    maxY += pad;

    return Column(
      key: const ValueKey('NothingSplineView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick Stat Ribbon (Nothing Monospace Pill)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.08),
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
                    const NothingLedIndicator(color: AppColors.nothingRed, size: 6),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'PEAK: $peakMonthName // ${currencyFmt.format(peakNet)}',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
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
                      NothingLedIndicator(
                        color: avgNet >= 0 ? (isDark ? Colors.white : Colors.black) : AppColors.nothingRed,
                        size: 6,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AVG: ${currencyFmt.format(avgNet)}',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: avgNet >= 0
                              ? (isDark ? Colors.white : Colors.black)
                              : AppColors.nothingRed,
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

        // LineChart with Smooth Curves and Nothing Red Peak Accent
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
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.05),
                  strokeWidth: 0.9,
                  dashArray: [4, 4],
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
                            (data[index]['month'] as String).toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: isPeak ? FontWeight.w800 : FontWeight.w500,
                              color: isPeak
                                  ? AppColors.nothingRed
                                  : (isDark ? AppColors.nothingSubtext : const Color(0xFF888888)),
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
                  getTooltipColor: (_) => isDark ? const Color(0xFF000000) : Colors.white,
                  tooltipBorderRadius: BorderRadius.circular(10),
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final item = data[index];
                      final net = spot.y;
                      return LineTooltipItem(
                        '${item['month']}\n${currencyFmt.format(net)}',
                        GoogleFonts.shareTechMono(
                          color: net >= 0
                              ? (isDark ? Colors.white : Colors.black)
                              : AppColors.nothingRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
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
                  color: isDark ? Colors.white : Colors.black,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isPeak = index == peakIndex;
                      return FlDotCirclePainter(
                        radius: isPeak ? 5 : 3.5,
                        color: isPeak
                            ? AppColors.nothingRed
                            : (isDark ? Colors.white : Colors.black),
                        strokeWidth: isPeak ? 2.5 : 1.5,
                        strokeColor: isDark ? const Color(0xFF000000) : Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.05),
                        Colors.transparent,
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
  // VIEW 2: NOTHING OS MONOCHROME & RED DONUT
  // ==========================================
  Widget _buildNothingDonutChart(bool isDark) {
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
                size: 38,
                color: isDark ? AppColors.nothingSubtext : const Color(0xFF999999),
              ),
              const SizedBox(height: 10),
              Text(
                'no_expense_records'.tr,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
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

    // Palette with high contrast Nothing OS tones
    final nothingPalette = [
      AppColors.nothingRed,
      isDark ? Colors.white : const Color(0xFF222222),
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666),
      isDark ? const Color(0xFF777777) : const Color(0xFFAAAAAA),
      const Color(0xFFD97706), // Amber
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
    ];

    final sections = categories.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedPieIndex;
      final radius = isTouched ? 32.0 : 25.0;
      final color = nothingPalette[index % nothingPalette.length];

      return PieChartSectionData(
        color: color,
        value: (item['amount'] as num).toDouble(),
        title: '',
        radius: radius,
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${(item['percentage'] as num).toStringAsFixed(0)}%',
                  style: GoogleFonts.shareTechMono(
                    color: isDark ? Colors.white : Colors.black,
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
      key: const ValueKey('NothingDonutView'),
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
                  sectionsSpace: 3,
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
                        ? (activeCategory['name'] as String).tr.toUpperCase()
                        : 'EXPENSES',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isDark ? AppColors.nothingSubtext : const Color(0xFF777777),
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
                      style: GoogleFonts.shareTechMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: activeCategory != null
                            ? nothingPalette[_touchedPieIndex % nothingPalette.length]
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                  if (activeCategory != null) ...[
                    Text(
                      '${(activeCategory['percentage'] as num).toStringAsFixed(1)}%',
                      style: GoogleFonts.shareTechMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: nothingPalette[_touchedPieIndex % nothingPalette.length],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nothing OS Category Capsule Cards (Top 4 Categories)
        ...categories.take(4).toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final color = nothingPalette[idx % nothingPalette.length];
          final String catName = (item['name'] as String).tr;
          final double pct = (item['percentage'] as num).toDouble();
          final double amount = (item['amount'] as num).toDouble();
          final icon = _getCategoryIcon(item['name'] as String);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.nothingBorder : Colors.black.withValues(alpha: 0.07),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Category Squircle Icon
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      const SizedBox(width: 8),

                      // Name
                      Expanded(
                        child: Text(
                          catName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
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
                          style: GoogleFonts.shareTechMono(
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
                          style: GoogleFonts.shareTechMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Mini Segmented Progress Indicator
                  NothingSegmentedBar(
                    progress: pct / 100,
                    segments: 10,
                    activeColor: color,
                    height: 3,
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
