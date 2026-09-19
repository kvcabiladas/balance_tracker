import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

enum FilterType { all, active, settled }
enum SortType { alphabetical, highestBalance, lowestBalance, lastActive }

class TabProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<PersonTab> _tabs = [];
  List<DeletedItem> _trash = [];
  bool _isLoading = true;
  String? _userId;

  StreamSubscription<List<PersonTab>>? _tabsSubscription;
  StreamSubscription<List<DeletedItem>>? _trashSubscription;

  String _searchQuery = '';
  FilterType _filterType = FilterType.all;
  SortType _sortType = SortType.lastActive;

  List<PersonTab> get tabs => _tabs;
  List<DeletedItem> get trash => _trash;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  FilterType get filterType => _filterType;
  SortType get sortType => _sortType;

  void updateUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;

    _tabsSubscription?.cancel();
    _trashSubscription?.cancel();

    if (userId == null || userId.isEmpty) {
      _tabs = [];
      _trash = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _tabsSubscription = _firestoreService.streamTabs(userId).listen(
      (tabsData) {
        _tabs = tabsData;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Error streaming tabs: $error");
        _isLoading = false;
        notifyListeners();
      },
    );

    _trashSubscription = _firestoreService.streamTrash(userId).listen(
      (trashData) {
        _trash = trashData;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Error streaming trash: $error");
      },
    );
  }

  @override
  void dispose() {
    _tabsSubscription?.cancel();
    _trashSubscription?.cancel();
    super.dispose();
  }

  double get totalOwedToMe => _tabs.fold(0.0, (acc, tab) => acc + tab.totalOwedToMe);
  double get totalIOweThem => _tabs.fold(0.0, (acc, tab) => acc + tab.totalIOweThem);
  double get netTotalBalance => totalOwedToMe - totalIOweThem;

  List<PersonTab> get filteredTabs {
    List<PersonTab> result = List.from(_tabs);
    if (_searchQuery.isNotEmpty) {
      result = result.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_filterType == FilterType.active) {
      result = result.where((t) => t.netBalance.abs() > 0.01).toList();
    } else if (_filterType == FilterType.settled) {
      result = result.where((t) => t.netBalance.abs() <= 0.01).toList();
    }
    if (_sortType == SortType.alphabetical) {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortType == SortType.highestBalance) {
      result.sort((a, b) => b.netBalance.compareTo(a.netBalance));
    } else if (_sortType == SortType.lowestBalance) {
      result.sort((a, b) => a.netBalance.compareTo(b.netBalance));
    } else if (_sortType == SortType.lastActive) {
      result.sort((a, b) => b.lastActiveDate.compareTo(a.lastActiveDate));
    }
    return result;
  }

  void setSearchQuery(String q) { _searchQuery = q; notifyListeners(); }
  void setFilterType(FilterType t) { _filterType = t; notifyListeners(); }
  void setSortType(SortType t) { _sortType = t; notifyListeners(); }

  // Helpers
  PersonTab? _getPerson(String id) {
    try { return _tabs.firstWhere((t) => t.id == id); } catch (_) { return null; }
  }

  TabTransaction? _getTx(PersonTab tab, String txId) {
    try { return tab.transactions.firstWhere((t) => t.id == txId); } catch (_) { return null; }
  }

  // ALIAS METHODS FOR TABKEEPER UI

  Future<void> addPerson(String name, {String description = ''}) async {
    if (_userId == null) return;
    final tab = PersonTab(
      id: const Uuid().v4(),
      name: name,
      description: description,
      avatarColorHex: 'FF9CAF88',
      transactions: [],
    );
    await _firestoreService.addTab(_userId!, tab);
  }

  Future<void> editPerson(String id, String name, String description, [String? color]) async {
    if (_userId == null) return;
    final tab = _getPerson(id);
    if (tab != null) {
      await _firestoreService.updateTab(_userId!, tab.copyWith(name: name, description: description, avatarColorHex: color ?? tab.avatarColorHex));
    }
  }

  Future<void> deletePerson(String id) async {
    if (_userId == null) return;
    final tab = _getPerson(id);
    if (tab != null) await _firestoreService.deleteTab(_userId!, tab);
  }

  Future<void> deleteMultiplePersons(List<String> ids) async {
    if (_userId == null) return;
    for (final id in ids) {
      await deletePerson(id);
    }
  }

  Future<void> deleteAllPersons() async {
    if (_userId == null) return;
    for (final tab in _tabs) {
      await _firestoreService.deleteTab(_userId!, tab);
    }
  }

  Future<void> addTransaction(String personId, TabTransaction tx) async {
    if (_userId == null) return;
    final tab = _getPerson(personId);
    if (tab != null) await _firestoreService.addTransaction(_userId!, tab, tx);
  }

  Future<void> editTransaction(String personId, String txId, TabTransaction tx) async {
    if (_userId == null) return;
    final tab = _getPerson(personId);
    if (tab != null) await _firestoreService.updateTransaction(_userId!, tab, tx);
  }

  Future<void> deleteTransaction(String personId, String txId) async {
    if (_userId == null) return;
    final tab = _getPerson(personId);
    if (tab != null) {
      final tx = _getTx(tab, txId);
      if (tx != null) await _firestoreService.deleteTransaction(_userId!, tab, tx);
    }
  }

  Future<void> toggleTransactionPaid(String personId, String txId, [String method = 'Cash']) async {
    if (_userId == null) return;
    final tab = _getPerson(personId);
    if (tab == null) return;
    final tx = _getTx(tab, txId);
    if (tx == null) return;

    if (tx.isPaid) {
      await _firestoreService.updateTransaction(_userId!, tab, tx.copyWith(payments: []));
    } else {
      final payment = PaymentRecord(id: const Uuid().v4(), amount: tx.remainingAmount, date: DateTime.now(), method: 'Cash');
      await _firestoreService.addPayment(_userId!, tab, tx.id, payment);
    }
  }

  Future<void> recordPayment(String personId, String txId, PaymentRecord payment) async {
    if (_userId == null) return;
    final tab = _getPerson(personId);
    if (tab != null) await _firestoreService.addPayment(_userId!, tab, txId, payment);
  }

  // Alias for backward compatibility if any UI uses `addPayment` instead of `recordPayment`
  Future<void> addPayment(String personId, String txId, PaymentRecord payment) async {
    await recordPayment(personId, txId, payment);
  }

  Future<void> editPayment(String personId, String txId, String paymentId, PaymentRecord payment) async {
    if (_userId == null) return;
    final tab = _getPerson(personId);
    if (tab == null) return;
    final tx = _getTx(tab, txId);
    if (tx == null) return;

    final updatedPayments = tx.payments.map((p) => p.id == payment.id ? payment : p).toList();
    await _firestoreService.updateTransaction(_userId!, tab, tx.copyWith(payments: updatedPayments));
  }

  Future<void> deletePayment(String personId, String txId, String paymentId) async {
    if (_userId == null) return;
    final tab = _getPerson(personId);
    if (tab == null) return;
    final tx = _getTx(tab, txId);
    if (tx == null) return;

    final updatedPayments = tx.payments.where((p) => p.id != paymentId).toList();
    await _firestoreService.updateTransaction(_userId!, tab, tx.copyWith(payments: updatedPayments));
  }

  Future<void> settleAllForPerson(String personId) async {
    if (_userId == null) return;
    final tab = _getPerson(personId);
    if (tab == null) return;

    final updatedTxs = tab.transactions.map((tx) {
      if (!tx.isPaid) {
        final payment = PaymentRecord(id: const Uuid().v4(), amount: tx.remainingAmount, date: DateTime.now(), method: 'Cash');
        return tx.copyWith(payments: [...tx.payments, payment]);
      }
      return tx;
    }).toList();

    await _firestoreService.updateTab(_userId!, tab.copyWith(transactions: updatedTxs));
  }

  Future<void> restoreItem(DeletedItem item) async {
    if (_userId == null) return;
    await _firestoreService.restoreTrashItem(_userId!, item);
  }

  Future<void> permanentlyDeleteItem(String itemId) async {
    if (_userId == null) return;
    await _firestoreService.permanentlyDeleteTrashItem(_userId!, itemId);
  }

  Future<void> clearTrash() async {
    if (_userId == null) return;
    await _firestoreService.clearTrash(_userId!);
  }
}
