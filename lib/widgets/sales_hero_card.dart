import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constantscolors.dart';

class SalesHeroCard extends StatelessWidget {
  final double sales;
  final double growthPercent;
  final List<double> weeklySales;

  const SalesHeroCard({
    super.key,
    required this.sales,
    required this.growthPercent,
    required this.weeklySales,
  });

  @override
  Widget build(BuildContext context) {
    const chartHeight = 56.0;
    final maxValue = weeklySales.reduce((a, b) => a > b ? a : b);
    final isPositive = growthPercent >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's sales",
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Rs ${NumberFormat('#,##0').format(sales)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${isPositive ? '+' : ''}${growthPercent.toStringAsFixed(0)}% from yesterday',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mini bar chart
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end, // bars start from the bottom
              children: List.generate(weeklySales.length, (i) {
                final isToday = i == weeklySales.length - 1;
                final barHeight = chartHeight * (weeklySales[i] / maxValue);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: isToday ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
