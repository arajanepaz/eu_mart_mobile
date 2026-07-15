import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item.dart';

class TransactionService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> saveTransaction({
    required List<CartItem> cart,
    required double total,
    required double cash,
    required double change,
  }) async {
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      throw Exception('No logged-in user.');
    }

    final batch = firestore.batch();
    final transactionRef = firestore.collection('transactions').doc();

    final List<Map<String, dynamic>> items = [];

    for (final item in cart) {
      items.add({
        'productId': item.id,
        'productName': item.productName,
        'price': item.price,
        'quantity': item.quantity,
        'subtotal': item.subtotal,
      });

      final productRef = firestore.collection('products').doc(item.id);
      final productSnapshot = await productRef.get();

      if (!productSnapshot.exists) {
        throw Exception('${item.productName} no longer exists.');
      }

      final productData = productSnapshot.data()!;
      final currentStock = (productData['stock'] as num?)?.toInt() ?? 0;

      if (currentStock < item.quantity) {
        throw Exception('Not enough stock for ${item.productName}.');
      }

      batch.update(productRef, {'stock': currentStock - item.quantity});
    }

    batch.set(transactionRef, {
      'total': total,
      'cash': cash,
      'change': change,
      'createdAt': FieldValue.serverTimestamp(),
      'items': items,

      // User who processed the transaction
      'processedById': currentUser.uid,
      'processedByEmail': currentUser.email ?? '',
    });

    await batch.commit();
  }
}
