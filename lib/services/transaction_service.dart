import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item.dart';

class TransactionService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  /// Saves the sale and updates all affected product stocks atomically.
  ///
  /// Returns the generated receipt number so the same value can be shown
  /// on the receipt screen and transaction history.
  Future<String> saveTransaction({
    required List<CartItem> cart,
    required double total,
    required double cash,
    required double change,
  }) async {
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      throw Exception('No logged-in user.');
    }

    if (cart.isEmpty) {
      throw Exception('The cart is empty.');
    }

    if (cash < total) {
      throw Exception('Insufficient cash.');
    }

    final transactionRef = firestore.collection('transactions').doc();

    final DateTime now = DateTime.now();
    final String receiptNumber =
        'EU-${now.millisecondsSinceEpoch}-${transactionRef.id.substring(0, 6).toUpperCase()}';

    await firestore.runTransaction((transaction) async {
      final List<Map<String, dynamic>> items = [];

      for (final item in cart) {
        final productRef = firestore.collection('products').doc(item.id);
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception('${item.productName} no longer exists.');
        }

        final productData = productSnapshot.data()!;
        final int currentStock = (productData['stock'] as num?)?.toInt() ?? 0;

        final int stockToDeduct = item.totalStockQuantity;

        if (stockToDeduct <= 0) {
          throw Exception('Invalid quantity for ${item.productName}.');
        }

        if (currentStock < stockToDeduct) {
          throw Exception(
            'Not enough stock for ${item.productName}. '
            'Available: $currentStock, required: $stockToDeduct.',
          );
        }

        items.add(item.toMap());

        transaction.update(productRef, {
          'stock': currentStock - stockToDeduct,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(transactionRef, {
        'receiptNumber': receiptNumber,
        'transactionNumber': receiptNumber,
        'total': total,
        'cash': cash,
        'change': change,
        'createdAt': FieldValue.serverTimestamp(),
        'items': items,

        // User who processed the transaction
        'processedById': currentUser.uid,
        'processedByEmail': currentUser.email ?? '',
        'processedByName':
            currentUser.displayName ?? currentUser.email ?? 'Cashier',

        // Used by the owner dashboard transaction badge.
        'isViewedByOwner': false,

        // Allows safe cancellation instead of permanently deleting records.
        'status': 'completed',
        'voidedAt': null,
        'voidedById': null,
        'voidReason': null,
      });
    });

    return receiptNumber;
  }

  /// Voids a completed transaction and restores its product stocks atomically.
  Future<void> voidTransaction({
    required String transactionId,
    required String reason,
  }) async {
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      throw Exception('No logged-in user.');
    }

    final cleanReason = reason.trim();

    if (cleanReason.isEmpty) {
      throw Exception('A void reason is required.');
    }

    final transactionRef = firestore
        .collection('transactions')
        .doc(transactionId);

    await firestore.runTransaction((transaction) async {
      final transactionSnapshot = await transaction.get(transactionRef);

      if (!transactionSnapshot.exists) {
        throw Exception('Transaction no longer exists.');
      }

      final data = transactionSnapshot.data()!;
      final String status = (data['status'] ?? 'completed')
          .toString()
          .toLowerCase();

      if (status == 'voided') {
        throw Exception('This transaction has already been voided.');
      }

      final List<dynamic> items =
          data['items'] as List<dynamic>? ?? <dynamic>[];

      for (final rawItem in items) {
        if (rawItem is! Map) continue;

        final item = Map<String, dynamic>.from(rawItem);

        final String productId = (item['productId'] ?? '').toString().trim();

        if (productId.isEmpty) continue;

        final int quantityToRestore =
            (item['totalStockQuantity'] as num?)?.toInt() ??
            (item['quantity'] as num?)?.toInt() ??
            0;

        if (quantityToRestore <= 0) continue;

        final productRef = firestore.collection('products').doc(productId);

        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) continue;

        final currentStock =
            (productSnapshot.data()?['stock'] as num?)?.toInt() ?? 0;

        transaction.update(productRef, {
          'stock': currentStock + quantityToRestore,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(transactionRef, {
        'status': 'voided',
        'voidedAt': FieldValue.serverTimestamp(),
        'voidedById': currentUser.uid,
        'voidedByEmail': currentUser.email ?? '',
        'voidReason': cleanReason,
      });
    });
  }
}
