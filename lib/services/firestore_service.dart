import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references helper
  CollectionReference<Map<String, dynamic>> _tabsRef(String userId) {
    return _db.collection('users').doc(userId).collection('tabs');
  }

  CollectionReference<Map<String, dynamic>> _trashRef(String userId) {
    return _db.collection('users').doc(userId).collection('trash');
  }

  // Stream active PersonTabs for logged-in user
  Stream<List<PersonTab>> streamTabs(String userId) {
    return _tabsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PersonTab.fromJson(data);
      }).toList();
    });
  }

  // Stream Trash items
  Stream<List<DeletedItem>> streamTrash(String userId) {
    return _trashRef(userId)
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DeletedItem.fromJson(data);
      }).toList();
    });
  }

  // Add new PersonTab
  Future<void> addTab(String userId, PersonTab tab) async {
    await _tabsRef(userId).doc(tab.id).set(tab.toJson());
  }

  // Update existing PersonTab
  Future<void> updateTab(String userId, PersonTab tab) async {
    await _tabsRef(userId).doc(tab.id).update(tab.toJson());
  }

  // Delete PersonTab (move to Trash)
  Future<void> deleteTab(String userId, PersonTab tab) async {
    final trashItem = DeletedItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'person',
      displayName: tab.name,
      data: tab.toJson(),
      deletedAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(_trashRef(userId).doc(trashItem.id), trashItem.toJson());
    batch.delete(_tabsRef(userId).doc(tab.id));
    await batch.commit();
  }

  // Add Transaction to a PersonTab
  Future<void> addTransaction(String userId, PersonTab tab, TabTransaction tx) async {
    final updatedTransactions = [tx, ...tab.transactions];
    final updatedTab = tab.copyWith(transactions: updatedTransactions);
    await updateTab(userId, updatedTab);
  }

  // Update Transaction in a PersonTab
  Future<void> updateTransaction(String userId, PersonTab tab, TabTransaction tx) async {
    final updatedTransactions = tab.transactions.map((t) => t.id == tx.id ? tx : t).toList();
    final updatedTab = tab.copyWith(transactions: updatedTransactions);
    await updateTab(userId, updatedTab);
  }

  // Delete Transaction (move transaction to Trash)
  Future<void> deleteTransaction(String userId, PersonTab tab, TabTransaction tx) async {
    final updatedTransactions = tab.transactions.where((t) => t.id != tx.id).toList();
    final updatedTab = tab.copyWith(transactions: updatedTransactions);

    final trashItem = DeletedItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'transaction',
      displayName: '${tx.description.isEmpty ? tx.methodOfUtang : tx.description} (₱${tx.amount.toStringAsFixed(2)})',
      data: tx.toJson(),
      deletedAt: DateTime.now(),
      parentPersonId: tab.id,
      parentPersonName: tab.name,
    );

    final batch = _db.batch();
    batch.set(_trashRef(userId).doc(trashItem.id), trashItem.toJson());
    batch.set(_tabsRef(userId).doc(tab.id), updatedTab.toJson());
    await batch.commit();
  }

  // Add Payment to a Transaction
  Future<void> addPayment(String userId, PersonTab tab, String transactionId, PaymentRecord payment) async {
    final updatedTransactions = tab.transactions.map((tx) {
      if (tx.id == transactionId) {
        final newPayments = [...tx.payments, payment];
        return tx.copyWith(payments: newPayments);
      }
      return tx;
    }).toList();

    final updatedTab = tab.copyWith(transactions: updatedTransactions);
    await updateTab(userId, updatedTab);
  }

  // Restore deleted item from Trash
  Future<void> restoreTrashItem(String userId, DeletedItem item) async {
    final batch = _db.batch();

    if (item.type == 'person') {
      final restoredTab = PersonTab.fromJson(item.data);
      batch.set(_tabsRef(userId).doc(restoredTab.id), restoredTab.toJson());
    } else if (item.type == 'transaction' && item.parentPersonId != null) {
      final docSnap = await _tabsRef(userId).doc(item.parentPersonId).get();
      if (docSnap.exists) {
        final currentTab = PersonTab.fromJson(docSnap.data()!);
        final restoredTx = TabTransaction.fromJson(item.data);
        final updatedTxs = [...currentTab.transactions, restoredTx];
        batch.update(_tabsRef(userId).doc(currentTab.id), {
          'transactions': updatedTxs.map((t) => t.toJson()).toList(),
        });
      }
    }

    batch.delete(_trashRef(userId).doc(item.id));
    await batch.commit();
  }

  // Permanently delete Trash item
  Future<void> permanentlyDeleteTrashItem(String userId, String itemId) async {
    await _trashRef(userId).doc(itemId).delete();
  }

  // Clear all Trash
  Future<void> clearTrash(String userId) async {
    final snapshot = await _trashRef(userId).get();
    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
