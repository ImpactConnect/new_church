import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class MobileLeaderIncomeDialog extends StatefulWidget {
  const MobileLeaderIncomeDialog({
    super.key,
    required this.branchId,
    required this.entityId,
    required this.entityName,
    required this.entityType, // 'department' | 'subGroup'
    required this.recordedByName,
  });

  final String branchId;
  final String entityId;
  final String entityName;
  final String entityType;
  final String recordedByName;

  @override
  State<MobileLeaderIncomeDialog> createState() => _MobileLeaderIncomeDialogState();
}

class _MobileLeaderIncomeDialogState extends State<MobileLeaderIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _projectController = TextEditingController();
  final _donorNameController = TextEditingController();
  final _notesController = TextEditingController();

  String _incomeCategory = 'offering'; // 'offering' | 'generalDonation' | 'projectDonation'
  String _paymentMethod = 'cash'; // 'cash' | 'transfer' | 'cheque'
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _projectController.dispose();
    _donorNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: theme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${widget.entityName} Financial Log',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Selector
                const Text('Transaction Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _incomeCategory,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'offering', child: Text('Meeting Offering')),
                    DropdownMenuItem(value: 'generalDonation', child: Text('General Group Donation')),
                    DropdownMenuItem(value: 'projectDonation', child: Text('Individual Project Contribution')),
                  ],
                  onChanged: (v) => setState(() => _incomeCategory = v!),
                ),
                const SizedBox(height: 14),

                // Amount
                const Text('Amount (₦)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'e.g. 15000.00',
                    prefixText: '₦ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter amount';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'Enter valid positive amount';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Payment Method
                const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 14),

                // Project Name (If Project Contribution)
                if (_incomeCategory == 'projectDonation') ...[
                  const Text('Project / Purpose Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _projectController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Choir Sound System, Ushering Uniforms',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (_incomeCategory == 'projectDonation' && (v == null || v.trim().isEmpty))
                        ? 'Project name required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // Donor Name (If Individual Donation/Project)
                if (_incomeCategory == 'projectDonation' || _incomeCategory == 'generalDonation') ...[
                  const Text('Donor / Member Name (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _donorNameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Brother John Doe',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Notes
                const Text('Remarks / Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Optional comments or reference...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submitting ? null : _submitRecord,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, color: Colors.white),
          label: const Text('Save Record', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _submitRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final recordId = const Uuid().v4();
      final recordData = {
        'branchId': widget.branchId,
        'entityId': widget.entityId,
        'entityName': widget.entityName,
        'entityType': widget.entityType,
        'incomeCategory': _incomeCategory,
        'amount': double.parse(_amountController.text.trim()),
        'paymentMethod': _paymentMethod,
        'recordedBy': widget.recordedByName,
        'date': DateTime.now().toIso8601String(),
        if (_projectController.text.trim().isNotEmpty) 'projectName': _projectController.text.trim(),
        if (_donorNameController.text.trim().isNotEmpty) 'donorMemberName': _donorNameController.text.trim(),
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('branches')
          .doc(widget.branchId)
          .collection('group_incomes')
          .doc(recordId)
          .set(recordData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Financial record saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
