import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';

final _disbursementsForExpenditureProvider = StreamProvider.autoDispose.family<List<DisbursementModel>, (String, String)>(
  (ref, params) => ref.watch(financeRepositoryProvider).watchDisbursements(params.$1, params.$2),
);

final _allExpendituresProvider = StreamProvider.autoDispose.family<List<ExpenditureModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchExpenditures(branchId),
);

class DisbursementListScreen extends ConsumerStatefulWidget {
  const DisbursementListScreen({super.key, this.expenditure});
  final ExpenditureModel? expenditure;

  @override
  ConsumerState<DisbursementListScreen> createState() => _DisbursementListScreenState();
}

class _DisbursementListScreenState extends ConsumerState<DisbursementListScreen> {
  ExpenditureModel? _selectedExpenditure;

  @override
  void initState() {
    super.initState();
    _selectedExpenditure = widget.expenditure;
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;

    final expendituresAsync = ref.watch(_allExpendituresProvider(branchId));
    final canDisburse = user?.can(AppPermission.recordDisbursement) ?? false;

    return Scaffold(
      backgroundColor: CmsTheme.bg,
      appBar: AppBar(
        backgroundColor: CmsTheme.sidebar,
        foregroundColor: CmsTheme.textPrimary,
        elevation: 0,
        title: const Text('Disbursements Ledger', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expenditure selector dropdown
            expendituresAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading expenditures: $e', style: const TextStyle(color: CmsTheme.danger)),
              data: (expenditures) {
                if (expenditures.isEmpty) {
                  return const CmsEmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No approved expenditures available for disbursement',
                    subtitle: 'Approved expenditure requests will populate this dropdown.',
                  );
                }

                _selectedExpenditure ??= expenditures.first;
                final current = expenditures.firstWhere((e) => e.id == _selectedExpenditure?.id, orElse: () => expenditures.first);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: current.id,
                            dropdownColor: CmsTheme.surfaceElevated,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(labelText: 'Select Approved Expenditure Line'),
                            items: expenditures.map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text('${e.category} — ${e.description} (Approved: ₦${e.approvedAmount.toStringAsFixed(2)})'),
                            )).toList(),
                            onChanged: (id) {
                              setState(() {
                                _selectedExpenditure = expenditures.firstWhere((e) => e.id == id);
                              });
                            },
                          ),
                        ),
                        if (canDisburse && current.remainingBalance > 0) ...[
                          const SizedBox(width: 16),
                          CmsButton(
                            label: 'Record Disbursement',
                            icon: Icons.add,
                            compact: true,
                            onPressed: () => _showDisburseDialog(context, ref, branchId, current, user!),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Summary card
                    Row(
                      children: [
                        _metricCard('Approved Total', '₦${current.approvedAmount.toStringAsFixed(2)}', CmsTheme.textPrimary),
                        const SizedBox(width: 16),
                        _metricCard('Total Disbursed', '₦${current.totalDisbursed.toStringAsFixed(2)}', CmsTheme.accent),
                        const SizedBox(width: 16),
                        _metricCard(
                          'Remaining Balance',
                          '₦${current.remainingBalance.toStringAsFixed(2)}',
                          current.remainingBalance > 0 ? CmsTheme.success : CmsTheme.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Table of disbursements
                    Consumer(
                      builder: (context, ref, _) {
                        final disbAsync = ref.watch(_disbursementsForExpenditureProvider((branchId, current.id)));
                        return disbAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                          data: (items) {
                            if (items.isEmpty) {
                              return const CmsEmptyState(
                                icon: Icons.payments_outlined,
                                title: 'No disbursements recorded for this expenditure yet',
                              );
                            }
                            return CmsCard(
                              padding: EdgeInsets.zero,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: DataTable2(
                                  columnSpacing: 16,
                                  horizontalMargin: 20,
                                  minWidth: 700,
                                  headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                                  columns: const [
                                    DataColumn2(label: Text('Date', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                                    DataColumn2(label: Text('Recipient Name', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                                    DataColumn2(label: Text('Purpose / Notes', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.L),
                                    DataColumn2(label: Text('Disbursed Amount', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M, numeric: true),
                                    DataColumn2(label: Text('Disbursed By', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                                  ],
                                  rows: items.map((d) => DataRow2(
                                    cells: [
                                      DataCell(Text('${d.date.day}/${d.date.month}/${d.date.year}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
                                      DataCell(Text(d.recipientName, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary))),
                                      DataCell(Text(d.purpose, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary))),
                                      DataCell(Text('₦${d.amountDisbursed.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: CmsTheme.accent))),
                                      DataCell(Text(d.disbursedBy, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted))),
                                    ],
                                  )).toList(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    ),
  );

  void _showDisburseDialog(BuildContext context, WidgetRef ref, String branchId, ExpenditureModel expenditure, dynamic user) {
    showDialog(
      context: context,
      builder: (_) => _DisbursementFormDialog(branchId: branchId, ref: ref, expenditure: expenditure, user: user),
    );
  }
}

class _DisbursementFormDialog extends StatefulWidget {
  const _DisbursementFormDialog({
    required this.branchId,
    required this.ref,
    required this.expenditure,
    required this.user,
  });

  final String branchId;
  final WidgetRef ref;
  final ExpenditureModel expenditure;
  final dynamic user;

  @override
  State<_DisbursementFormDialog> createState() => _DisbursementFormDialogState();
}

class _DisbursementFormDialogState extends State<_DisbursementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amtCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amtCtrl.dispose();
    _recipientCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.expenditure.remainingBalance;

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: const Text('Record Disbursement', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Balance: ₦${remaining.toStringAsFixed(2)}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.accent),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _recipientCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(labelText: 'Recipient Name / Vendor'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(labelText: 'Disbursement Amount (₦)'),
                validator: (v) {
                  final amt = double.tryParse(v ?? '');
                  if (amt == null || amt <= 0) return 'Enter valid amount';
                  if (amt > remaining) return 'Exceeds balance (₦${remaining.toStringAsFixed(2)})';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _purposeCtrl,
                maxLines: 2,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(labelText: 'Purpose / Payment Details'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: 'Save Disbursement',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final disb = DisbursementModel(
                id: '',
                amountDisbursed: double.parse(_amtCtrl.text.trim()),
                date: DateTime.now(),
                recipientName: _recipientCtrl.text.trim(),
                purpose: _purposeCtrl.text.trim(),
                disbursedBy: widget.user.displayName ?? widget.user.email,
              );
              await widget.ref.read(financeRepositoryProvider).recordDisbursement(
                widget.branchId, widget.expenditure.id, disb,
              );
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger),
                );
              }
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
        ),
      ],
    );
  }
}
