import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

// --- 1. MONEY ZONE CHART (Smooth Green Line) ---
class MoneyZoneChart extends StatelessWidget {
  final List<FlSpot>? spots;
  const MoneyZoneChart({super.key, this.spots});

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> chartSpots = spots != null && spots!.isNotEmpty
        ? spots!
        : const [
            FlSpot(0, 2),
            FlSpot(1, 2.5),
            FlSpot(2, 1.8),
            FlSpot(3, 3),
            FlSpot(4, 2.8),
            FlSpot(5, 4),
            FlSpot(6, 3.5),
          ];

    return SizedBox(
      height: 80,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: chartSpots,
              isCurved: true,
              color: AppTheme.accentGreen,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGreen.withOpacity(0.28),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. SALES GOAL CIRCLE (75% Indicator) ---
class SalesGoalCircle extends StatelessWidget {
  const SalesGoalCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 100,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: 270,
              sectionsSpace: 0,
              centerSpaceRadius: 35,
              sections: [
                PieChartSectionData(
                  color: AppTheme.accentGreen,
                  value: 75,
                  radius: 10,
                  showTitle: false,
                ),
                PieChartSectionData(
                  color: Colors.white.withOpacity(0.08),
                  value: 25,
                  radius: 10,
                  showTitle: false,
                ),
              ],
            ),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "75%",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "Achieved",
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. STATUS CARD (Pending/Cooking/Ready) ---
class OrderStatusCard extends StatelessWidget {
  final String id;
  final String status;
  final String time;
  final Color color;

  const OrderStatusCard({
    super.key,
    required this.id,
    required this.status,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order #$id",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "($time)",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
