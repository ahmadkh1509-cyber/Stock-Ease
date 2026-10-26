import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String barcode;
  final double buyPrice;
  final double sellPrice;
  final int quantity;
  final int lowStockLimit;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    required this.lowStockLimit,
  });

  // A product is "low" when quantity reaches or falls below its limit
  bool get isLowStock => quantity <= lowStockLimit;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Product(
      id: doc.id,
      name: d['name'] ?? '',
      barcode: d['barcode'] ?? '',
      buyPrice: (d['buyPrice'] ?? 0).toDouble(),
      sellPrice: (d['sellPrice'] ?? 0).toDouble(),
      quantity: (d['quantity'] ?? 0).toInt(),
      lowStockLimit: (d['lowStockLimit'] ?? 5).toInt(),
    );
  }

  // The id is not stored inside the document, it is the document name
  Map<String, dynamic> toMap() => {
    'name': name,
    'barcode': barcode,
    'buyPrice': buyPrice,
    'sellPrice': sellPrice,
    'quantity': quantity,
    'lowStockLimit': lowStockLimit,
  };
}
