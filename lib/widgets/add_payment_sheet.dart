import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/tab_provider.dart';

class AddPaymentSheet extends StatefulWidget {
  final String personId;
  final TabTransaction transaction;
  final PaymentRecord? paymentToEdit;

  const AddPaymentSheet({
    super.key,
    required this.personId,
    required this.transaction,
    this.paymentToEdit,
  });

  @override
  State<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _customMethodController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedMethod = 'Cash'; // Default payment method

  final List<Map<String, dynamic>> _methodsList = [
    {'name': 'Cash', 'icon': Icons.money},
    {'name': 'GCash', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'Bank', 'icon': Icons.account_balance},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.paymentToEdit != null) {
      _amountController.text = widget.paymentToEdit!.amount.toStringAsFixed(2);
      _selectedDate = widget.paymentToEdit!.date;
      
      String method = widget.paymentToEdit!.method;
      if (method.contains(' (')) {
        final parts = method.split(' (');
        method = parts[0];
        _noteController.text = parts[1].replaceAll(')', '');
      }
      
      if (method.startsWith('Other: ')) {
        _selectedMethod = 'Other';
        _customMethodController.text = method.substring(7);
      } else {
        _selectedMethod = method;
      }
    } else {
      _amountController.text = widget.transaction.remainingAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customMethodController.dispose();
    _noteController.dispose();
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

  void _submitPayment() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    // Build payment method details
    String paymentMethod = _selectedMethod;
    if (_selectedMethod == 'Other') {
      final customInput = _customMethodController.text.trim();
      paymentMethod = customInput.isEmpty ? 'Other' : 'Other: $customInput';
    }

    // Attach optional note to payment method details or description if available
    final note = _noteController.text.trim();
    String finalMethod = paymentMethod;
    if (note.isNotEmpty) {
      finalMethod = '$paymentMethod ($note)';
    }

    final provider = Provider.of<TabProvider>(context, listen: false);
    final isEditing = widget.paymentToEdit != null;
    final payment = PaymentRecord(
      id: isEditing ? widget.paymentToEdit!.id : const Uuid().v4(),
      amount: amount,
      date: _selectedDate,
      method: finalMethod,
    );

    if (isEditing) {
      provider.editPayment(widget.personId, widget.transaction.id, payment.id, payment);
    } else {
      provider.addPayment(widget.personId, widget.transaction.id, payment);
    }
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? 'Payment updated successfully!' : 'Recorded payment of ₱${amount.toStringAsFixed(2)} successfully!'),
        backgroundColor: const Color(0xFF9CAF88),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingAmount = widget.transaction.remainingAmount;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final primaryColor = const Color(0xFF9CAF88); // Sage Green #9caf88
    final accentGreen = const Color(0xFFF0F4EC);  // Soft light sage green
    final isEditing = widget.paymentToEdit != null;

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
                        widget.paymentToEdit != null ? 'Edit payment' : 'Log payment',
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

                  if (!isEditing) ...[
                    // 2. Banner highlighting remaining balance
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: accentGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Remaining: ${currencyFormat.format(remainingAmount)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 3. Amount input field
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
                      floatingLabelStyle: TextStyle(color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a payment amount';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Please enter a valid amount greater than 0';
                      }
                      if (!isEditing && parsed > remainingAmount + 0.01) {
                        return 'Payment cannot exceed outstanding balance';
                      }
                      return null;
                    },
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 10),

                    // 4. Quick select shortcuts
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _amountController.text = remainingAmount.toStringAsFixed(2);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            'Full',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _amountController.text = (remainingAmount / 2).toStringAsFixed(2);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            'Half',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // 5. Payment method selector
                  Text(
                    'Method',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            selectedColor: primaryColor,
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
                        floatingLabelStyle: TextStyle(color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 2),
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

                  // 6. Date & Note fields (Side by side)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Picker
                      Expanded(
                        child: Column(
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
                                      color: primaryColor,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Note
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Note',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _noteController,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Optional',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 7. Buttons at the bottom
                  ElevatedButton(
                    onPressed: _submitPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      widget.paymentToEdit != null ? 'Save changes' : 'Log payment',
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
