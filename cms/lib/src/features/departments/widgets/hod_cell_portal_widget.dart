import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/finance/models/group_income_model.dart';
import 'package:cms/src/features/members/models/member_model.dart';

final _groupIncomesProvider = StreamProvider.autoDispose.family<List<GroupIncomeRecordModel>, ({String branchId, String entityId})>(
  (ref, arg) => ref.watch(groupIncomeRepositoryProvider).watchGroupIncomes(arg.branchId, arg.entityId),
);

final _allMembersForIncomeProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

class HodCellPortalWidget extends ConsumerStatefulWidget {
  const HodCellPortalWidget({
    super.key,
    required this.branchId,
    required this.entityId,
    required this.entityName,
    required this.entityType, // 'department' | 'subGroup'
  });

  final String branchId;
  final String entityId;
  final String entityName;
  final String entityType;

  @override
  ConsumerState<HodCellPortalWidget> createState() => _HodCellPortalWidgetState();
}

class _HodCellPortalWidgetState extends ConsumerState<HodCellPortalWidget> {
  final _currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final incomesAsync = ref.watch(
      _groupIncomesProvider((branchId: widget.branchId, entityId: widget.entityId)),
    );
    final membersAsync = ref.watch(_allMembersForIncomeProvider(widget.branchId));

    final user = ref.watch(cmsUserProvider).valueOrNull;
    final isPastorOrSecretaryOrAdmin = user?.roleId == AppRole.leadPastor ||
        user?.roleId == AppRole.secretary ||
        user?.roleId == 'admin';

    final canRecordIncome = !isPastorOrSecretaryOrAdmin &&
        (user?.roleId == AppRole.departmentHead ||
         user?.roleId == AppRole.cellLeader ||
         (user?.can(AppPermission.recordDepartmentIncome) ?? false) ||
         (user?.can(AppPermission.recordSubGroupIncome) ?? false));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        incomesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading financial records: $err', style: const TextStyle(color: CmsTheme.danger)),
          data: (incomes) {
            double totalOffering = 0;
            double totalDonations = 0;
            double totalProjectFunds = 0;

            for (final inc in incomes) {
              if (inc.incomeCategory == 'offering') {
                totalOffering += inc.amount;
              } else if (inc.incomeCategory == 'generalDonation') {
                totalDonations += inc.amount;
              } else if (inc.incomeCategory == 'projectDonation') {
                totalProjectFunds += inc.amount;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── KPI Summary Cards ───────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Meeting Offering',
                        value: _currencyFormat.format(totalOffering),
                        icon: Icons.payments_outlined,
                        color: CmsTheme.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricCard(
                        title: 'General Group Donations',
                        value: _currencyFormat.format(totalDonations),
                        icon: Icons.volunteer_activism_outlined,
                        color: CmsTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricCard(
                        title: 'Project Funds Raised',
                        value: _currencyFormat.format(totalProjectFunds),
                        icon: Icons.account_tree_outlined,
                        color: CmsTheme.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Action Buttons Row ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.entityName} Financial Income Records (${incomes.length})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CmsTheme.textPrimary,
                      ),
                    ),
                    if (canRecordIncome)
                      Wrap(
                        spacing: 10,
                        children: [
                          CmsButton(
                            label: 'Record Offering',
                            icon: Icons.add,
                            compact: true,
                            onPressed: () => _showRecordIncomeDialog(
                              context,
                              category: 'offering',
                              allMembers: membersAsync.valueOrNull ?? [],
                            ),
                          ),
                          CmsButton(
                            label: 'Record Donation',
                            icon: Icons.add,
                            compact: true,
                            onPressed: () => _showRecordIncomeDialog(
                              context,
                              category: 'generalDonation',
                              allMembers: membersAsync.valueOrNull ?? [],
                            ),
                          ),
                          CmsButton(
                            label: 'Individual Project Donation',
                            icon: Icons.assignment_turned_in_outlined,
                            compact: true,
                            onPressed: () => _showRecordIncomeDialog(
                              context,
                              category: 'projectDonation',
                              allMembers: membersAsync.valueOrNull ?? [],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Records Data Table ──────────────────────────────────────
                if (incomes.isEmpty)
                  const CmsEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No financial records logged',
                    subtitle: 'Use the buttons above to log offerings, bulk donations, or project contributions.',
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: CmsTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CmsTheme.border),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(2.0),
                        2: FlexColumnWidth(1.8),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1.2),
                        5: FlexColumnWidth(1.0),
                      },
                      children: [
                        // Header
                        TableRow(
                          decoration: const BoxDecoration(
                            color: CmsTheme.surfaceElevated,
                            border: Border(bottom: BorderSide(color: CmsTheme.border)),
                          ),
                          children: const [
                            _TableCell('Date', isHeader: true),
                            _TableCell('Type / Category', isHeader: true),
                            _TableCell('Donor / Source', isHeader: true),
                            _TableCell('Project / Purpose', isHeader: true),
                            _TableCell('Amount', isHeader: true),
                            _TableCell('Method', isHeader: true),
                          ],
                        ),
                        // Rows
                        ...incomes.map((inc) {
                          final dateStr = DateFormat('dd/MM/yyyy').format(inc.date);
                          final donorStr = inc.donorMemberName?.isNotEmpty == true
                              ? inc.donorMemberName!
                              : (inc.incomeCategory == 'offering' ? 'General Meeting' : 'Anonymous');

                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: CmsTheme.border)),
                            ),
                            children: [
                              _TableCell(dateStr),
                              _TableCell(inc.categoryDisplayName),
                              _TableCell(donorStr),
                              _TableCell(inc.projectName ?? 'N/A'),
                              _TableCell(
                                _currencyFormat.format(inc.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: CmsTheme.success),
                              ),
                              _TableCell(inc.paymentMethod.toUpperCase()),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showRecordIncomeDialog(
    BuildContext ctx, {
    required String category,
    required List<MemberModel> allMembers,
  }) {
    showDialog(
      context: ctx,
      builder: (_) => _RecordGroupIncomeDialog(
        branchId: widget.branchId,
        entityId: widget.entityId,
        entityName: widget.entityName,
        entityType: widget.entityType,
        category: category,
        allMembers: allMembers,
      ),
    );
  }
}

// ── Metric Card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Table Cell Widget ────────────────────────────────────────────────────────

class _TableCell extends StatelessWidget {
  const _TableCell(this.text, {this.isHeader = false, this.style});
  final String text;
  final bool isHeader;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: style ??
            TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
              color: isHeader ? CmsTheme.textSecondary : CmsTheme.textPrimary,
            ),
      ),
    );
  }
}

// ── Dialog: Log Financial Record ─────────────────────────────────────────────

class _RecordGroupIncomeDialog extends ConsumerStatefulWidget {
  const _RecordGroupIncomeDialog({
    required this.branchId,
    required this.entityId,
    required this.entityName,
    required this.entityType,
    required this.category,
    required this.allMembers,
  });

  final String branchId;
  final String entityId;
  final String entityName;
  final String entityType;
  final String category;
  final List<MemberModel> allMembers;

  @override
  ConsumerState<_RecordGroupIncomeDialog> createState() => _RecordGroupIncomeDialogState();
}

class _RecordGroupIncomeDialogState extends ConsumerState<_RecordGroupIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _projectCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentMethod = 'cash';
  String? _selectedMemberId;
  String? _selectedMemberName;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _projectCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.category) {
      'offering' => 'Record Meeting Offering',
      'generalDonation' => 'Record General Group Donation',
      'projectDonation' => 'Record Individual Project Donation',
      _ => 'Record Income',
    };

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: CmsTheme.border)),
      title: Text(title, style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                const Text('Amount (₦)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'e.g. 25000.00'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount required';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'Enter a valid positive amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payment Method
                const Text('Payment Method', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  dropdownColor: CmsTheme.surfaceElevated,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 16),

                // Donor Member (If Project Donation or Individual Donation)
                if (widget.category == 'projectDonation' || widget.category == 'generalDonation') ...[
                  const Text('Donor Member (Optional)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedMemberId,
                    dropdownColor: CmsTheme.surfaceElevated,
                    style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                    decoration: const InputDecoration(hintText: 'Select donor member…'),
                    items: widget.allMembers.map((m) {
                      return DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.fullName} ${m.memberCode != null ? "(${m.memberCode})" : ""}'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      final selected = widget.allMembers.firstWhere((m) => m.id == v);
                      setState(() {
                        _selectedMemberId = v;
                        _selectedMemberName = selected.fullName;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Project Name (If Project Donation)
                if (widget.category == 'projectDonation') ...[
                  const Text('Project / Purpose Name', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _projectCtrl,
                    style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                    decoration: const InputDecoration(hintText: 'e.g. Youth Sound System, Ushering Uniforms'),
                    validator: (v) => (widget.category == 'projectDonation' && (v == null || v.trim().isEmpty))
                        ? 'Project name required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                const Text('Notes / Remarks', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'Optional comments or receipt reference…'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: 'Save Record',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final currentUser = ref.read(cmsUserProvider).valueOrNull;
              final record = GroupIncomeRecordModel(
                id: '',
                branchId: widget.branchId,
                entityId: widget.entityId,
                entityName: widget.entityName,
                entityType: widget.entityType,
                incomeCategory: widget.category,
                amount: double.parse(_amountCtrl.text.trim()),
                paymentMethod: _paymentMethod,
                recordedBy: currentUser?.displayName ?? currentUser?.email ?? 'HOD / Leader',
                date: DateTime.now(),
                projectName: _projectCtrl.text.trim().isNotEmpty ? _projectCtrl.text.trim() : null,
                donorMemberId: _selectedMemberId,
                donorMemberName: _selectedMemberName,
                notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
              );

              await ref.read(groupIncomeRepositoryProvider).recordGroupIncome(widget.branchId, record);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Financial income record saved successfully'), backgroundColor: CmsTheme.success),
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
