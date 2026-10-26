import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('products');
  }

  Stream<List<Product>> watchProducts(String uid) {
    return _collection(uid).snapshots().map((snapshot) {
      final list = snapshot.docs.map(Product.fromDoc).toList();
      // Sort here (not in the query) so A and a are treated the same
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<void> addProduct(String uid, Product product) {
    return _collection(
      uid,
    ).add({...product.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateProduct(String uid, Product product) {
    return _collection(uid).doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String uid, String productId) {
    return _collection(uid).doc(productId).delete();
  }
}
