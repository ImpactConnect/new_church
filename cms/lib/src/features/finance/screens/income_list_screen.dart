import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
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
  String _typeFilter = 'all';

  static const _incomeCategories = [
    ('Tithe', 'tithe'),
    ('Offering', 'offering'),
    ('Donation', 'donation'),
    ('Building Project', 'building_project'),
    ('Special Seed', 'special_seed'),
    ('Welfare', 'welfare'),
    ('Other', 'other'),
  ];

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
            title: 'Income & Giving',
            subtitle: 'Record and track branch tithes, offerings, donations, building projects, and special funds',
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
              final tithes = items.where((i) => i.source.toLowerCase().contains('tithe')).fold<double>(0, (sum, i) => sum + i.amount);
              final offerings = items.where((i) => i.source.toLowerCase().contains('offering')).fold<double>(0, (sum, i) => sum + i.amount);
              final special = total - tithes - offerings;

              return Row(
                children: [
                  _statCard('Total Income', '₦${total.toStringAsFixed(2)}', CmsTheme.success, Icons.trending_up),
                  const SizedBox(width: 16),
                  _statCard('Tithes Total', '₦${tithes.toStringAsFixed(2)}', CmsTheme.accent, Icons.volunteer_activism_outlined),
                  const SizedBox(width: 16),
                  _statCard('Offerings Total', '₦${offerings.toStringAsFixed(2)}', CmsTheme.info, Icons.payments_outlined),
                  const SizedBox(width: 16),
                  _statCard('Projects / Other', '₦${special.toStringAsFixed(2)}', CmsTheme.warning, Icons.account_balance_outlined),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Income', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                  selected: _typeFilter == 'all',
                  onSelected: (_) => setState(() => _typeFilter = 'all'),
                ),
                const SizedBox(width: 8),
                for (final (label, value) in _incomeCategories) ...[
                  ChoiceChip(
                    label: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                    selected: _typeFilter == value,
                    onSelected: (_) => setState(() => _typeFilter = value),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: CmsCard(
              padding: EdgeInsets.zero,
              child: incomeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                data: (items) {
                  final filtered = items.where((i) {
                    if (_typeFilter == 'all') return true;
                    final src = i.source.toLowerCase();
                    return switch (_typeFilter) {
                      'tithe' => src.contains('tithe'),
                      'offering' => src.contains('offering'),
                      'donation' => src.contains('donation'),
                      'building_project' => src.contains('building'),
                      'special_seed' => src.contains('seed') || src.contains('special'),
                      'welfare' => src.contains('welfare'),
                      _ => !src.contains('tithe') && !src.contains('offering') && !src.contains('donation') && !src.contains('building'),
                    };
                  }).toList();

                  if (filtered.isEmpty) {
                    return CmsEmptyState(
                      icon: Icons.monetization_on_outlined,
                      title: 'No income recorded yet',
                      subtitle: 'Record church collections, tithes, offerings, and donations.',
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
                      minWidth: 750,
                      headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                      dataRowColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) return CmsTheme.surfaceElevated;
                        return CmsTheme.surface;
                      }),
                      columns: const [
                        DataColumn2(label: Text('Date', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                        DataColumn2(label: Text('Income Type / Source', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.L),
                        DataColumn2(label: Text('Payment Method', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                        DataColumn2(label: Text('Amount', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M, numeric: true),
                        DataColumn2(label: Text('Notes', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
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
    final formattedDate = DateFormat('dd/MM/yyyy').format(item.date);
    return DataRow2(
      cells: [
        DataCell(Text(formattedDate, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
        DataCell(Text(item.source, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: CmsTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(item.formType.toUpperCase(), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: CmsTheme.accent)),
        )),
        DataCell(Text('₦${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: CmsTheme.success))),
        DataCell(Text(item.comment ?? '—', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary), overflow: TextOverflow.ellipsis),
                Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary)),
              ],
            ),
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
  final _otherSourceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedCategory = 'Tithe';
  String _formType = 'cash';
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  static const _presetCategories = [
    'Tithe',
    'Offering',
    'Donation',
    'Building Project',
    'Special Seed',
    'Welfare',
    'Other',
  ];

  @override
  void dispose() {
    _amtCtrl.dispose();
    _otherSourceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: const Text('Record Income / Giving', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Income Type Dropdown
                const Text('Income Type / Category *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: CmsTheme.surfaceElevated,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(filled: true, fillColor: CmsTheme.bg),
                  items: _presetCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 14),

                // If 'Other' selected, show custom text input
                if (_selectedCategory == 'Other') ...[
                  const Text('Specify Other Income Name / Type *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _otherSourceCtrl,
                    style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                    decoration: const InputDecoration(hintText: 'e.g. Youth Camp Collection, Thanksgiving', filled: true, fillColor: CmsTheme.bg),
                    validator: (v) => (_selectedCategory == 'Other' && (v == null || v.trim().isEmpty)) ? 'Please specify income name' : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // Date Picker + Amount
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: CmsTheme.bg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: CmsTheme.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: CmsTheme.accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(formattedDateStr, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary), overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Amount (₦) *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _amtCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(filled: true, fillColor: CmsTheme.bg, hintText: '0.00'),
                            validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Enter valid amount' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Payment Method Dropdown
                const Text('Payment Method', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _formType,
                  dropdownColor: CmsTheme.surfaceElevated,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(filled: true, fillColor: CmsTheme.bg),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'in-kind', child: Text('In-Kind')),
                  ],
                  onChanged: (v) => setState(() => _formType = v!),
                ),
                const SizedBox(height: 14),

                const Text('Description / Additional Notes', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'e.g. Service collection notes, bank reference', filled: true, fillColor: CmsTheme.bg),
                ),
              ],
            ),
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

            final sourceName = _selectedCategory == 'Other'
                ? _otherSourceCtrl.text.trim()
                : _selectedCategory;

            try {
              final item = IncomeModel(
                id: '',
                amount: double.parse(_amtCtrl.text.trim()),
                source: sourceName,
                formType: _formType,
                recordedBy: widget.user.displayName ?? widget.user.email,
                date: _selectedDate,
                comment: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              );
              await widget.ref.read(financeRepositoryProvider).recordIncome(widget.branchId, item);
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Income entry saved successfully'), backgroundColor: CmsTheme.success),
                );
              }
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
