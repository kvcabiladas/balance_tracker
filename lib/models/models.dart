import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { owedToMe, owedToThem }

class PaymentRecord {
  final String id;
  final double amount;
  final DateTime date;
  final String method;

  PaymentRecord({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method,
    };
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['date'] is Timestamp) {
      parsedDate = (json['date'] as Timestamp).toDate();
    } else if (json['date'] is String) {
      parsedDate = DateTime.parse(json['date']);
    } else {
      parsedDate = DateTime.now();
    }

    return PaymentRecord(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: parsedDate,
      method: json['method'] ?? 'Cash',
    );
  }
}

class TabTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String methodOfUtang; // 'Cash', 'GCash', 'Bank', 'Others: ...'
  final String description;
  final List<PaymentRecord> payments;

  TabTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.methodOfUtang,
    required this.description,
    required this.payments,
  });

  double get settledAmount {
    return payments.fold(0.0, (acc, payment) => acc + payment.amount);
  }

  double get remainingAmount {
    final rem = amount - settledAmount;
    return rem < 0 ? 0.0 : rem;
  }

  bool get isPaid {
    return remainingAmount <= 0.01;
  }

  TabTransaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? methodOfUtang,
    String? description,
    List<PaymentRecord>? payments,
  }) {
    return TabTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      methodOfUtang: methodOfUtang ?? this.methodOfUtang,
      description: description ?? this.description,
      payments: payments ?? this.payments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'methodOfUtang': methodOfUtang,
      'description': description,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  factory TabTransaction.fromJson(Map<String, dynamic> json) {
    final paymentsList = (json['payments'] as List?)
            ?.map((pJson) => PaymentRecord.fromJson(Map<String, dynamic>.from(pJson)))
            .toList() ??
        <PaymentRecord>[];

    DateTime parsedDate;
    if (json['date'] is Timestamp) {
      parsedDate = (json['date'] as Timestamp).toDate();
    } else if (json['date'] is String) {
      parsedDate = DateTime.parse(json['date']);
    } else {
      parsedDate = DateTime.now();
    }

    return TabTransaction(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] == 'owedToMe'
          ? TransactionType.owedToMe
          : TransactionType.owedToThem,
      date: parsedDate,
      methodOfUtang: json['methodOfUtang'] ?? json['category'] ?? 'Cash',
      description: json['description'] ?? '',
      payments: paymentsList,
    );
  }
}

class PersonTab {
  final String id;
  final String name;
  final String description;
  final String avatarColorHex;
  final List<TabTransaction> transactions;

  PersonTab({
    required this.id,
    required this.name,
    this.description = '',
    required this.avatarColorHex,
    required this.transactions,
  });

  double get netBalance {
    double total = 0.0;
    for (var tx in transactions) {
      if (!tx.isPaid) {
        if (tx.type == TransactionType.owedToMe) {
          total += tx.remainingAmount;
        } else {
          total -= tx.remainingAmount;
        }
      }
    }
    return total;
  }

  double get totalOwedToMe {
    return transactions
        .where((tx) => !tx.isPaid && tx.type == TransactionType.owedToMe)
        .fold(0.0, (acc, tx) => acc + tx.remainingAmount);
  }

  double get totalIOweThem {
    return transactions
        .where((tx) => !tx.isPaid && tx.type == TransactionType.owedToThem)
        .fold(0.0, (acc, tx) => acc + tx.remainingAmount);
  }

  DateTime get lastActiveDate {
    if (transactions.isEmpty) return DateTime.now();
    return transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  PersonTab copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarColorHex,
    List<TabTransaction>? transactions,
  }) {
    return PersonTab(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
      transactions: transactions ?? this.transactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatarColorHex': avatarColorHex,
      'transactions': transactions.map((tx) => tx.toJson()).toList(),
    };
  }

  factory PersonTab.fromJson(Map<String, dynamic> json) {
    final rawTransactions = json['transactions'] as List? ?? [];
    return PersonTab(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      avatarColorHex: json['avatarColorHex'] ?? 'FF9CAF88',
      transactions: rawTransactions
          .map((txJson) => TabTransaction.fromJson(Map<String, dynamic>.from(txJson)))
          .toList(),
    );
  }
}

class DeletedItem {
  final String id;
  final String type; // 'person' or 'transaction'
  final String displayName;
  final Map<String, dynamic> data;
  final DateTime deletedAt;
  final String? parentPersonId;
  final String? parentPersonName;

  DeletedItem({
    required this.id,
    required this.type,
    required this.displayName,
    required this.data,
    required this.deletedAt,
    this.parentPersonId,
    this.parentPersonName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'displayName': displayName,
      'data': data,
      'deletedAt': deletedAt.toIso8601String(),
      'parentPersonId': parentPersonId,
      'parentPersonName': parentPersonName,
    };
  }

  factory DeletedItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['deletedAt'] is Timestamp) {
      parsedDate = (json['deletedAt'] as Timestamp).toDate();
    } else if (json['deletedAt'] is String) {
      parsedDate = DateTime.parse(json['deletedAt']);
    } else {
      parsedDate = DateTime.now();
    }

    return DeletedItem(
      id: json['id'] ?? '',
      type: json['type'] ?? 'person',
      displayName: json['displayName'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      deletedAt: parsedDate,
      parentPersonId: json['parentPersonId'],
      parentPersonName: json['parentPersonName'],
    );
  }
}
