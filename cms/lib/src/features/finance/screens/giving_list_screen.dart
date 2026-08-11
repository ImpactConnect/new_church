import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:cms/src/features/members/models/member_model.dart';

final _givingProvider = StreamProvider.autoDispose.family<List<GivingModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchGiving(branchId),
);

final _membersMapProvider = StreamProvider.autoDispose.family<Map<String, MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId).map(
    (members) => {for (final m in members) m.id: m},
  ),
);

class GivingListScreen extends ConsumerStatefulWidget {
  const GivingListScreen({super.key});

  @override
  ConsumerState<GivingListScreen> createState() => _GivingListScreenState();
}

class _GivingListScreenState extends ConsumerState<GivingListScreen> {
  String _typeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final givingAsync = ref.watch(_givingProvider(branchId));
    final membersMapAsync = ref.watch(_membersMapProvider(branchId));

    final canRecord = user?.can(AppPermission.recordIncome) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Giving & Tithes',
            subtitle: 'Member-linked tithe records, pledges, and offering statements',
            actions: [
              if (canRecord)
                CmsButton(
                  label: 'Record Giving',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showGivingDialog(context, ref, branchId, user!),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ChoiceChip(
                label: const Text('All Giving', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _typeFilter == 'all',
                onSelected: (_) => setState(() => _typeFilter = 'all'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Tithe', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _typeFilter == 'tithe',
                onSelected: (_) => setState(() => _typeFilter = 'tithe'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Offering', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _typeFilter == 'offering',
                onSelected: (_) => setState(() => _typeFilter = 'offering'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Pledge', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _typeFilter == 'pledge',
                onSelected: (_) => setState(() => _typeFilter = 'pledge'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CmsCard(
              padding: EdgeInsets.zero,
              child: givingAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                data: (items) {
                  return membersMapAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (memberMap) {
                      final filtered = items.where((i) => _typeFilter == 'all' || i.type == _typeFilter).toList();
                      if (filtered.isEmpty) {
                        return CmsEmptyState(
                          icon: Icons.volunteer_activism_outlined,
                          title: 'No giving records found',
                          subtitle: 'Record member tithes and pledges.',
                          action: canRecord
                              ? CmsButton(
                                  label: 'Record Giving',
                                  icon: Icons.add,
                                  onPressed: () => _showGivingDialog(context, ref, branchId, user!),
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
                            DataColumn2(label: Text('Member Name', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.L),
                            DataColumn2(label: Text('Type', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                            DataColumn2(label: Text('Amount', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M, numeric: true),
                            DataColumn2(label: Text('Recorded By', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                          ],
                          rows: filtered.map((item) => _buildRow(item, memberMap[item.memberId]?.fullName ?? 'Unknown')).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow2 _buildRow(GivingModel item, String memberName) {
    return DataRow2(
      cells: [
        DataCell(Text('${item.date.day}/${item.date.month}/${item.date.year}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
        DataCell(Text(memberName, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: CmsTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(item.type.toUpperCase(), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: CmsTheme.accent)),
        )),
        DataCell(Text('₦${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: CmsTheme.success))),
        DataCell(Text(item.recordedBy, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted))),
      ],
    );
  }

  void _showGivingDialog(BuildContext context, WidgetRef ref, String branchId, dynamic user) {
    showDialog(
      context: context,
      builder: (_) => _GivingFormDialog(branchId: branchId, ref: ref, user: user),
    );
  }
}

class _GivingFormDialog extends StatefulWidget {
  const _GivingFormDialog({required this.branchId, required this.ref, required this.user});
  final String branchId;
  final WidgetRef ref;
  final dynamic user;

  @override
  State<_GivingFormDialog> createState() => _GivingFormDialogState();
}

class _GivingFormDialogState extends State<_GivingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amtCtrl = TextEditingController();
  String? _selectedMemberId;
  String _type = 'tithe';
  bool _saving = false;

  @override
  void dispose() {
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersMapAsync = widget.ref.watch(_membersMapProvider(widget.branchId));

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: const Text('Record Member Giving', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Member', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              membersMapAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading members', style: TextStyle(color: CmsTheme.danger)),
                data: (map) => DropdownButtonFormField<String>(
                  value: _selectedMemberId,
                  dropdownColor: CmsTheme.surfaceElevated,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'Select member…'),
                  items: map.values.map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName))).toList(),
                  onChanged: (v) => setState(() => _selectedMemberId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Giving Type', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _type,
                          dropdownColor: CmsTheme.surfaceElevated,
                          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                          decoration: const InputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'tithe', child: Text('Tithe')),
                            DropdownMenuItem(value: 'offering', child: Text('Offering')),
                            DropdownMenuItem(value: 'pledge', child: Text('Pledge')),
                          ],
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
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
                ],
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
            if (!_formKey.currentState!.validate() || _selectedMemberId == null) return;
            setState(() => _saving = true);
            try {
              final item = GivingModel(
                id: '',
                memberId: _selectedMemberId!,
                type: _type,
                amount: double.parse(_amtCtrl.text.trim()),
                date: DateTime.now(),
                recordedBy: widget.user.displayName ?? widget.user.email,
              );
              await widget.ref.read(financeRepositoryProvider).recordGiving(widget.branchId, item);
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
