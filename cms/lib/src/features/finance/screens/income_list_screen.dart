import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';

final _incomeProvider = StreamProvider.autoDispose.family<List<IncomeModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchIncome(branchId),
);

class IncomeListScreen extends ConsumerStatefulWidget {
  const IncomeListScreen({super.key});

  @override
  ConsumerState<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends ConsumerState<IncomeListScreen> {
  String _paymentFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final incomeAsync = ref.watch(_incomeProvider(branchId));

    final canRecord = user?.can(AppPermission.recordIncome) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Income & Revenues',
            subtitle: 'Record and track tithes, offerings, donations, and special funds',
            actions: [
              if (canRecord)
                CmsButton(
                  label: 'Record Income',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showRecordDialog(context, ref, branchId, user!),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Total metric cards
          incomeAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) {
              final total = items.fold<double>(0, (sum, i) => sum + i.amount);
              final cash = items.where((i) => i.formType == 'cash').fold<double>(0, (sum, i) => sum + i.amount);
              final transfer = items.where((i) => i.formType == 'transfer').fold<double>(0, (sum, i) => sum + i.amount);

              return Row(
                children: [
                  _statCard('Total Revenue', '₦${total.toStringAsFixed(2)}', CmsTheme.success, Icons.trending_up),
                  const SizedBox(width: 16),
                  _statCard('Cash Inflow', '₦${cash.toStringAsFixed(2)}', CmsTheme.accent, Icons.payments_outlined),
                  const SizedBox(width: 16),
                  _statCard('Bank Transfer', '₦${transfer.toStringAsFixed(2)}', CmsTheme.info, Icons.account_balance_outlined),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ChoiceChip(
                label: const Text('All Types', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _paymentFilter == 'all',
                onSelected: (_) => setState(() => _paymentFilter = 'all'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Cash', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _paymentFilter == 'cash',
                onSelected: (_) => setState(() => _paymentFilter = 'cash'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Bank Transfer', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _paymentFilter == 'transfer',
                onSelected: (_) => setState(() => _paymentFilter = 'transfer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CmsCard(
              padding: EdgeInsets.zero,
              child: incomeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                data: (items) {
                  final filtered = items.where((i) => _paymentFilter == 'all' || i.formType == _paymentFilter).toList();
                  if (filtered.isEmpty) {
                    return CmsEmptyState(
                      icon: Icons.monetization_on_outlined,
                      title: 'No income recorded yet',
                      subtitle: 'Record church collections and general offerings.',
                      action: canRecord
                          ? CmsButton(
                              label: 'Record Income',
                              icon: Icons.add,
                              onPressed: () => _showRecordDialog(context, ref, branchId, user!),
                            )
                          : null,
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DataTable2(
                      columnSpacing: 16,
                      horizontalMargin: 20,
                      minWidth: 700,
                      headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                      dataRowColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) return CmsTheme.surfaceElevated;
                        return CmsTheme.surface;
                      }),
                      columns: const [
                        DataColumn2(label: Text('Date', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                        DataColumn2(label: Text('Source / Fund', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.L),
                        DataColumn2(label: Text('Payment Method', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                        DataColumn2(label: Text('Amount', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M, numeric: true),
                        DataColumn2(label: Text('Recorded By', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                      ],
                      rows: filtered.map((item) => _buildRow(item)).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow2 _buildRow(IncomeModel item) {
    return DataRow2(
      cells: [
        DataCell(Text('${item.date.day}/${item.date.month}/${item.date.year}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
        DataCell(Text(item.source, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: CmsTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(item.formType.toUpperCase(), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: CmsTheme.accent)),
        )),
        DataCell(Text('₦${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: CmsTheme.success))),
        DataCell(Text(item.recordedBy, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted))),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
            ],
          ),
        ],
      ),
    ),
  );

  void _showRecordDialog(BuildContext context, WidgetRef ref, String branchId, dynamic user) {
    showDialog(
      context: context,
      builder: (_) => _IncomeFormDialog(branchId: branchId, ref: ref, user: user),
    );
  }
}

class _IncomeFormDialog extends StatefulWidget {
  const _IncomeFormDialog({required this.branchId, required this.ref, required this.user});
  final String branchId;
  final WidgetRef ref;
  final dynamic user;

  @override
  State<_IncomeFormDialog> createState() => _IncomeFormDialogState();
}

class _IncomeFormDialogState extends State<_IncomeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amtCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _formType = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _amtCtrl.dispose();
    _sourceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: const Text('Record Church Revenue', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Source / Description', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _sourceCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(hintText: 'e.g. Sunday Service Offering, Building Fund'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amount (₦)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _amtCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                          decoration: const InputDecoration(),
                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'Valid amount' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Method', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _formType,
                          dropdownColor: CmsTheme.surfaceElevated,
                          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                          decoration: const InputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'transfer', child: Text('Bank Transfer')),
                            DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                          ],
                          onChanged: (v) => setState(() => _formType = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(hintText: 'Additional notes (optional)…'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: 'Save Entry',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final item = IncomeModel(
                id: '',
                amount: double.parse(_amtCtrl.text.trim()),
                source: _sourceCtrl.text.trim(),
                formType: _formType,
                recordedBy: widget.user.displayName ?? widget.user.email,
                date: DateTime.now(),
                comment: _notesCtrl.text.trim(),
              );
              await widget.ref.read(financeRepositoryProvider).recordIncome(widget.branchId, item);
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
