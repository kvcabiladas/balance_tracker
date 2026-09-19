import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/tab_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/add_payment_sheet.dart';
import '../widgets/add_transaction_sheet.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personTabId;

  const PersonDetailScreen({
    super.key,
    required this.personTabId,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final Set<String> _expandedTxIds = {};

  void _showAddTransaction(BuildContext context, TransactionType type) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddTransactionSheet(
        personId: widget.personTabId,
        initialType: type,
      ),
    );
  }

  void _showAddPayment(BuildContext context, TabTransaction tx) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddPaymentSheet(
        personId: widget.personTabId,
        transaction: tx,
      ),
    );
  }

  void _showTransactionOptions(BuildContext context, String personId, TabTransaction tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<TabProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      const Text(
                        'Entry Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tx.description.isEmpty ? 'Transaction Details' : tx.description,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormat('MMMM dd, yyyy').format(tx.date)} • ${tx.methodOfUtang}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Record Payment (Full or Partial)
                  if (!tx.isPaid)
                    ListTile(
                      leading: const Icon(
                        Icons.add_task,
                        color: Color(0xFF9CAF88),
                      ),
                      title: const Text(
                        'Record Payment (Settle)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9CAF88),
                        ),
                      ),
                      subtitle: const Text('Record a full or partial settlement'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close choices
                        _showAddPayment(context, tx); // Open record payment sheet
                      },
                    ),
                  if (!tx.isPaid) const SizedBox(height: 8),

                  // 2. Quick Settle Toggle
                  ListTile(
                    leading: Icon(
                      tx.isPaid ? Icons.undo : Icons.check_circle_outline,
                      color: const Color(0xFF9CAF88),
                    ),
                    title: Text(
                      tx.isPaid ? 'Mark as Unpaid' : 'Quick Settle Full Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(tx.isPaid ? 'Clear all recorded payment logs' : 'Instantly log full payment'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    onTap: () {
                      if (tx.isPaid) {
                        provider.toggleTransactionPaid(personId, tx.id);
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context); // Close choices dialog
                        _showQuickSettleDialog(context, provider, personId, tx.id);
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // 3. Delete Transaction
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFB91C1C),
                    ),
                    title: const Text(
                      'Delete Entry',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                    subtitle: const Text('Delete this entry permanently'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeleteTransaction(context, provider, personId, tx.id);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQuickSettleDialog(BuildContext context, TabProvider provider, String personId, String transactionId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF9CAF88)),
                title: const Text('GCash', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  provider.toggleTransactionPaid(personId, transactionId, 'GCash');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Color(0xFF9CAF88)),
                title: const Text('Bank', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  provider.toggleTransactionPaid(personId, transactionId, 'Bank');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.money, color: Color(0xFF9CAF88)),
                title: const Text('Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  provider.toggleTransactionPaid(personId, transactionId, 'Cash');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.more_horiz, color: Color(0xFF9CAF88)),
                title: const Text('Others (Specify)', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context); // Close choice dialog
                  _showCustomSettleMethodDialog(context, provider, personId, transactionId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomSettleMethodDialog(BuildContext context, TabProvider provider, String personId, String transactionId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Specify Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF9CAF88), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please specify the method';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  provider.toggleTransactionPaid(
                    personId, 
                    transactionId, 
                    'Others: ${textController.text.trim()}',
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9CAF88),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Confirm Settle'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTransaction(BuildContext context, TabProvider provider, String personId, String txId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete entry?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this entry? It will be moved to Recently Deleted, where you can restore it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTransaction(personId, txId);
              Navigator.pop(context);

              // Show SnackBar with Undo
              if (provider.trash.isNotEmpty) {
                final recentlyDeleted = provider.trash.last;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Entry moved to Recently Deleted.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: const Color(0xFF9CAF88),
                      onPressed: () {
                        provider.restoreItem(recentlyDeleted);
                      },
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditPersonDialog(BuildContext context, TabProvider provider, PersonTab person) {
    final nameController = TextEditingController(text: person.name);
    final descriptionController = TextEditingController(text: person.description);
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Spacer(),
                        Text(
                          'Edit Tab',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: "Person's Name",
                        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF9CAF88), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: "Description (Optional)",
                        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF9CAF88), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          provider.editPerson(person.id, nameController.text, descriptionController.text);
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9CAF88),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeletePerson(BuildContext context, TabProvider provider, PersonTab tab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${tab.name}?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will move the tab and all its transactions to Recently Deleted, where you can restore it or delete it permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              provider.deletePerson(tab.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to HomeScreen

              // Show SnackBar with Undo
              if (provider.trash.isNotEmpty) {
                final recentlyDeleted = provider.trash.last;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Moved "${tab.name}" to Recently Deleted.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: const Color(0xFF9CAF88),
                      onPressed: () {
                        provider.restoreItem(recentlyDeleted);
                      },
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Delete Tab', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, String personId, String transactionId, String paymentId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete payment?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this payment record? This will increase the outstanding balance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              Provider.of<TabProvider>(context, listen: false).deletePayment(personId, transactionId, paymentId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Consumer<TabProvider>(
      builder: (context, provider, child) {
        // Find the person's tab
        final index = provider.tabs.indexWhere((t) => t.id == widget.personTabId);
        if (index == -1) {
          return const Scaffold(
            body: Center(child: Text('Tab no longer exists')),
          );
        }
        final tab = provider.tabs[index];
        final balance = tab.netBalance;

        // Group transactions into Active vs Paid
        final activeTxs = tab.transactions.where((t) => !t.isPaid).toList();
        final paidTxs = tab.transactions.where((t) => t.isPaid).toList();

        // Sort both lists by date descending
        activeTxs.sort((a, b) => b.date.compareTo(a.date));
        paidTxs.sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF9CAF88),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                onPressed: () async {
                  await PdfService.exportPersonTabPdf(tab);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showEditPersonDialog(context, provider, tab);
                  } else if (value == 'delete') {
                    _confirmDeletePerson(context, provider, tab);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Edit tab'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Color(0xFFB91C1C)),
                        SizedBox(width: 8),
                        Text('Delete tab', style: TextStyle(color: Color(0xFFB91C1C))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary top block
              Container(
                color: const Color(0xFF9CAF88),
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TAB',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tab.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tab.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7D9369), // Complementary deeper shade for summary card
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NET BALANCE',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            balance == 0
                                ? 'Settled'
                                : currencyFormat.format(balance.abs()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: Colors.white.withOpacity(0.15),
                            height: 1,
                            thickness: 1,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'outstanding balance',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormat.format(tab.totalOwedToMe),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'overpayment',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormat.format(tab.totalIOweThem),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filter/Actions Toolbar
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ENTRIES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Row(
                      children: [
                        if (activeTxs.isNotEmpty) ...[
                          TextButton.icon(
                            icon: const Icon(Icons.handshake_outlined, size: 16),
                            label: const Text('Settle All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF9CAF88),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: const Color(0xFF9CAF88).withOpacity(0.12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              provider.settleAllForPerson(tab.id);
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // List Timeline
              Expanded(
                child: tab.transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tab is empty',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Log a transaction to start the tab',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90, top: 4),
                        children: [
                          // Active Transactions
                          if (activeTxs.isNotEmpty) ...[
                            ...activeTxs.map((tx) => _buildTransactionCard(context, tab.id, tx)),
                          ],

                          // Settled Transactions
                          if (paidTxs.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'SETTLED / PAID',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...paidTxs.map((tx) => _buildTransactionCard(context, tab.id, tx)),
                          ],
                        ],
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTransaction(context, TransactionType.owedToMe),
            backgroundColor: const Color(0xFF9CAF88),
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            child: const Icon(Icons.add, size: 28),
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, String personId, TabTransaction tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwedTx = tx.type == TransactionType.owedToMe;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final isExpanded = _expandedTxIds.contains(tx.id);

    // Colors
    final bulletColor = isOwedTx ? const Color(0xFF9CAF88) : const Color(0xFFB91C1C); // Sage Green / Red
    final amountColor = isOwedTx ? const Color(0xFF9CAF88) : const Color(0xFFB91C1C); // Green/Red
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCardColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCardColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showTransactionOptions(context, personId, tx),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Bullet point
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0, right: 10.0),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tx.isPaid ? const Color(0xFF94A3B8) : bulletColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // 2. Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.description.isEmpty ? tx.methodOfUtang : tx.description,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isOwedTx ? "outstanding balance" : "overpayment"} • ${DateFormat('MMMM dd, yyyy').format(tx.date)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 3. Amount and status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(tx.amount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: tx.isPaid ? const Color(0xFF94A3B8) : amountColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.isPaid ? 'Paid' : '${currencyFormat.format(tx.remainingAmount)} left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tx.isPaid
                              ? const Color(0xFF94A3B8)
                              : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Horizontal line before actions/payments
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),

          // Action row inside card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Log payment button (if outstanding)
                if (!tx.isPaid) ...[
                  ElevatedButton(
                    onPressed: () => _showAddPayment(context, tx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9CAF88),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Log payment',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Payments dropdown pill (if there are payments)
                if (tx.payments.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedTxIds.remove(tx.id);
                        } else {
                          _expandedTxIds.add(tx.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4EC), // soft light sage green
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${tx.payments.length} payment${tx.payments.length > 1 ? "s" : ""}',
                            style: const TextStyle(
                              color: Color(0xFF9CAF88),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 14,
                            color: const Color(0xFF9CAF88),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) => AddTransactionSheet(
                            personId: personId,
                            initialType: tx.type,
                            transactionToEdit: tx,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Trash delete icon
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFB91C1C)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDeleteTransaction(context, Provider.of<TabProvider>(context, listen: false), personId, tx.id),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expanded Nested Payments List
          if (isExpanded && tx.payments.isNotEmpty) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tx.payments.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                itemBuilder: (context, index) {
                  final payment = tx.payments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Subtitle icon or spacer
                        const Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.grey),
                        const SizedBox(width: 8),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment.method,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMMM dd, yyyy').format(payment.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Amount
                        Text(
                          currencyFormat.format(payment.amount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.black54),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) => AddPaymentSheet(
                                    personId: personId,
                                    transaction: tx,
                                    paymentToEdit: payment,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            // Delete payment button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFB91C1C)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _confirmDeletePayment(context, personId, tx.id, payment.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
