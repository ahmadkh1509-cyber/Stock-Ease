import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/stock_transaction.dart';
import '../services/stock_transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _service = TransactionService();
  StreamSubscription<List<StockTransaction>>? _sub;
  String? _uid;

  List<StockTransaction> _transactions = [];
  bool _isSaving = false;
  String? _errorMessage;

  // ---------- Stats for the dashboard ----------
  double _todaySales = 0;
  double _todayProfit = 0;
  int _itemsSoldToday = 0;
  double _growthPercent = 0;
  List<double> _weeklySales = List<double>.filled(7, 0); // last item = today

  List<StockTransaction> get transactions => _transactions;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  double get todaySales => _todaySales;
  double get todayProfit => _todayProfit;
  int get itemsSoldToday => _itemsSoldToday;
  double get growthPercent => _growthPercent;
  List<double> get weeklySales => _weeklySales;

  // Called by ChangeNotifierProxyProvider whenever AuthProvider changes
  void updateUser(String? uid) {
    if (uid == _uid) return;

    _sub?.cancel();
    _uid = uid;
    _transactions = [];
    _errorMessage = null;
    _calculate();

    if (uid == null) return; // logged out

    // Start of the day, 6 days ago (so we cover 7 days including today)
    final now = DateTime.now();
    final since = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    _sub = _service
        .watchSince(uid, since)
        .listen(
          (list) {
            _transactions = list;
            _errorMessage = null;
            _calculate();
            notifyListeners();
          },
          onError: (_) {
            _errorMessage = 'Could not load transactions. Please try again.';
            notifyListeners();
          },
        );
  }

  void _calculate() {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);

    final sales = List<double>.filled(7, 0);
    double profit = 0;
    int sold = 0;

    for (final tx in _transactions) {
      if (!tx.isSale) continue;

      final day = DateTime.utc(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );
      final daysAgo = today.difference(day).inDays;
      if (daysAgo < 0 || daysAgo > 6) continue;

      sales[6 - daysAgo] += tx.revenue;

      if (daysAgo == 0) {
        profit += tx.profit;
        sold += tx.quantity;
      }
    }

    final todayTotal = sales[6];
    final yesterdayTotal = sales[5];

    // Avoid dividing by zero when yesterday had no sales
    double growth;
    if (yesterdayTotal == 0) {
      growth = todayTotal > 0 ? 100 : 0;
    } else {
      growth = (todayTotal - yesterdayTotal) / yesterdayTotal * 100;
    }

    _weeklySales = sales;
    _todaySales = todayTotal;
    _todayProfit = profit;
    _itemsSoldToday = sold;
    _growthPercent = growth;
  }

  // true = success, false = failed (message is in errorMessage)
  Future<bool> recordMovement({
    required String productId,
    required int quantity,
    required bool isIn,
  }) async {
    if (_uid == null) {
      _errorMessage = 'You are not signed in';
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.recordMovement(
        uid: _uid!,
        productId: productId,
        quantity: quantity,
        isIn: isIn,
      );
      return true;
    } on StockException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirebaseException catch (e) {
      _errorMessage = _mapError(e.code);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong, please try again';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to do this';
      case 'unavailable':
        return 'Please check your internet connection';
      default:
        return 'Error: $code';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
