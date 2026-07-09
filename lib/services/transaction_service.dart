import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';

class TransactionService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> saveTransaction({
    required List<CartItem> cart,
    required double total,
    required double cash,
    required double change,
  }) async {
    final batch = firestore.batch();

    final transactionRef = firestore.collection("transactions").doc();

    final List<Map<String, dynamic>> items = [];

    for (final item in cart) {
      items.add({
        "productId": item.id,
        "productName": item.productName,
        "price": item.price,
        "quantity": item.quantity,
        "subtotal": item.subtotal,
      });

      final productRef = firestore.collection("products").doc(item.id);

      final product = await productRef.get();

      final currentStock = product["stock"] as int;

      batch.update(productRef, {"stock": currentStock - item.quantity});
    }

    batch.set(transactionRef, {
      "total": total,

      "cash": cash,

      "change": change,

      "createdAt": Timestamp.now(),

      "items": items,
    });

    await batch.commit();
  }
}
