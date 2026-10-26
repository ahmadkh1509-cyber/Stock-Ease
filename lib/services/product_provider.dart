import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();
  StreamSubscription<List<Product>>? _sub;
  String? _uid;

  List<Product> _products = [];
  bool _isLoading = false; // first load from Firestore
  bool _isSaving = false; // add / update / delete in progress
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  // Low stock products, lowest quantity first
  List<Product> get lowStock {
    final list = _products.where((p) => p.isLowStock).toList();
    list.sort((a, b) => a.quantity.compareTo(b.quantity));
    return list;
  }

  // Called by ChangeNotifierProxyProvider whenever AuthProvider changes
  void updateUser(String? uid) {
    if (uid == _uid) return; // same user, nothing to do

    _sub?.cancel();
    _uid = uid;
    _products = [];
    _errorMessage = null;

    if (uid == null) {
      _isLoading = false; // logged out
      return;
    }

    _isLoading = true;
    _sub = _service
        .watchProducts(uid)
        .listen(
          (list) {
            _products = list;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (_) {
            _isLoading = false;
            _errorMessage = 'Could not load products. Please try again.';
            notifyListeners();
          },
        );
  }

  List<Product> filtered({String query = '', bool lowStockOnly = false}) {
    final q = query.trim().toLowerCase();
    return _products.where((p) {
      if (lowStockOnly && !p.isLowStock) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.barcode.contains(q);
    }).toList();
  }

  // Used by the form to stop two products sharing one barcode
  bool barcodeExists(String barcode, {String? excludeId}) {
    final code = barcode.trim();
    if (code.isEmpty) return false;
    return _products.any((p) => p.barcode == code && p.id != excludeId);
  }

  // true = success, false = failed (message is in errorMessage)
  Future<bool> addProduct(Product product) {
    return _save(() => _service.addProduct(_uid!, product));
  }

  Future<bool> updateProduct(Product product) {
    return _save(() => _service.updateProduct(_uid!, product));
  }

  Future<bool> deleteProduct(String productId) {
    return _save(() => _service.deleteProduct(_uid!, productId));
  }

  // Common logic: saving on, try, catch error, saving off
  Future<bool> _save(Future<void> Function() action) async {
    if (_uid == null) {
      _errorMessage = 'You are not signed in';
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
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
      case 'not-found':
        return 'This product no longer exists';
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
