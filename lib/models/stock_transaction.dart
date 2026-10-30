import 'package:cloud_firestore/cloud_firestore.dart';

class StockTransaction {
  final String id;
  final String productId;
  final String productName;
  final String type;
  final int quantity;
  final double unitPrice;
  final double costPrice;
  final DateTime createdAt;

  const StockTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    required this.createdAt,
  });

  bool get isSale => type == 'out';

  double get revenue => isSale ? quantity * unitPrice : 0;
  double get profit => isSale ? quantity * (unitPrice - costPrice) : 0;

  factory StockTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return StockTransaction(
      id: doc.id,
      productId: d['productId'] ?? '',
      productName: d['productName'] ?? '',
      type: d['type'] ?? 'out',
      quantity: (d['quantity'] ?? 0).toInt(),
      unitPrice: (d['unitPrice'] ?? 0).toDouble(),
      costPrice: (d['costPrice'] ?? 0).toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
