import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/tab_provider.dart';

class AddTransactionSheet extends StatefulWidget {
  final String personId;
  final TransactionType initialType;
  final TabTransaction? transactionToEdit;

  const AddTransactionSheet({
    super.key,
    required this.personId,
    required this.initialType,
    this.transactionToEdit,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _customMethodController = TextEditingController();

  late TransactionType _transactionType;
  DateTime _selectedDate = DateTime.now();
  String _selectedMethod = 'Cash'; // Default method

  final List<Map<String, dynamic>> _methodsList = [
    {'name': 'Cash', 'icon': Icons.money},
    {'name': 'GCash', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'Bank', 'icon': Icons.account_balance},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialType;
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _transactionType = tx.type;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _descController.text = tx.description;
      _selectedDate = tx.date;
      
      String method = tx.methodOfUtang;
      if (method.startsWith('Other: ')) {
        _selectedMethod = 'Other';
        _customMethodController.text = method.substring(7);
      } else {
        _selectedMethod = method;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _customMethodController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF9CAF88), // Sage Green #9caf88
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1E293B) : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitData() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    // Build the method of utang string
    String methodOfUtang = _selectedMethod;
    if (_selectedMethod == 'Other') {
      final customInput = _customMethodController.text.trim();
      methodOfUtang = customInput.isEmpty ? 'Other' : 'Other: $customInput';
    }

    final provider = Provider.of<TabProvider>(context, listen: false);
    final isEditing = widget.transactionToEdit != null;
    final transaction = TabTransaction(
      id: isEditing ? widget.transactionToEdit!.id : const Uuid().v4(),
      amount: amount,
      type: _transactionType,
      date: _selectedDate,
      methodOfUtang: methodOfUtang,
      description: _descController.text.trim(),
      payments: isEditing ? widget.transactionToEdit!.payments : const [],
    );

    if (isEditing) {
      provider.editTransaction(widget.personId, transaction.id, transaction);
    } else {
      provider.addTransaction(widget.personId, transaction);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme colors matching the sage green aesthetic
    final primaryGreen = const Color(0xFF9CAF88);
    final lightGreenBg = const Color(0xFFF0F4EC);
    final roseColor = const Color(0xFFB91C1C);
    final lightRoseBg = const Color(0xFFFFEAEA);

    final isOwed = _transactionType == TransactionType.owedToMe;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header with Close X
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      Text(
                        widget.transactionToEdit != null ? 'Edit entry' : 'Add entry',
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
                  const SizedBox(height: 16),

                  // 2. Visual banner showing active type
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isOwed ? lightGreenBg : lightRoseBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        isOwed ? 'outstanding balance' : 'overpayment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isOwed ? primaryGreen : roseColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Selection toggles side-by-side
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _transactionType = TransactionType.owedToMe),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: isOwed ? primaryGreen : Colors.transparent,
                            side: BorderSide(
                              color: isOwed ? primaryGreen : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'outstanding balance',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOwed ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _transactionType = TransactionType.owedToThem),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: !isOwed ? roseColor : Colors.transparent,
                            side: BorderSide(
                              color: !isOwed ? roseColor : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'overpayment',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !isOwed ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Amount Input Field
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount (₱)',
                      labelStyle: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      floatingLabelStyle: TextStyle(color: isOwed ? primaryGreen : roseColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isOwed ? primaryGreen : roseColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Please enter a valid amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. Description Input Field
                  TextFormField(
                    controller: _descController,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      floatingLabelStyle: TextStyle(color: isOwed ? primaryGreen : roseColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isOwed ? primaryGreen : roseColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Method Selector Label
                  Text(
                    'Method',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Method of Utang Chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _methodsList.length,
                      itemBuilder: (context, index) {
                        final item = _methodsList[index];
                        final methodName = item['name'] as String;
                        final isSelected = _selectedMethod == methodName;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                                const SizedBox(width: 4),
                                Text(methodName),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: isOwed ? primaryGreen : roseColor,
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey[200] : Colors.grey[800]),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedMethod = methodName;
                                });
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide.none,
                            showCheckmark: false,
                          ),
                        );
                      },
                    ),
                  ),

                  // Show custom method input if "Other" is selected
                  if (_selectedMethod == 'Other') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customMethodController,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Specify Method',
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        floatingLabelStyle: TextStyle(color: isOwed ? primaryGreen : roseColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isOwed ? primaryGreen : roseColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (value) {
                        if (_selectedMethod == 'Other') {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please specify payment method';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 20),

                  // 7. Date picker field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: isOwed ? primaryGreen : roseColor,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 8. Buttons at the bottom
                  ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOwed ? primaryGreen : roseColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      widget.transactionToEdit != null ? 'Save changes' : 'Add entry',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
