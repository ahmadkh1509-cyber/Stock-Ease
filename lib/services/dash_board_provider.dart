import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  // ---------- Dummy data (will be replaced when we build transactions) ----------
  final double todaySales = 18450;
  final double growthPercent = 12;
  final double todayProfit = 4200;
  final int itemsSold = 64;

  // Last 7 days of sales, the last value is today
  final List<double> weeklySales = [
    8000,
    12000,
    9500,
    15000,
    11000,
    14000,
    18450,
  ];
}
