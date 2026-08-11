import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:cms/src/features/finance/screens/disbursement_list_screen.dart';

final _expenditureRequestsProvider = StreamProvider.autoDispose.family<List<ExpenditureRequestModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchExpenditureRequests(branchId),
);

final _approvedExpendituresProvider = StreamProvider.autoDispose.family<List<ExpenditureModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchExpenditures(branchId),
);

class ExpenditureListScreen extends ConsumerStatefulWidget {
  const ExpenditureListScreen({super.key});

  @override
  ConsumerState<ExpenditureListScreen> createState() => _ExpenditureListScreenState();
}

class _ExpenditureListScreenState extends ConsumerState<ExpenditureListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;

    final canRequest = user?.can(AppPermission.createExpenditureRequest) ?? false;
    final canApprove = user?.can(AppPermission.approveExpenditure) ?? false;

    final requestsAsync = ref.watch(_expenditureRequestsProvider(branchId));
    final ledgerAsync = ref.watch(_approvedExpendituresProvider(branchId));

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Expenditure Requests & Ledger',
            subtitle: 'Submit requests against approved budgets and manage disbursement ledgers',
            actions: [
              if (canRequest)
                CmsButton(
                  label: 'Request Expenditure',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showRequestDialog(context, ref, branchId, user!),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: CmsTheme.accent,
            unselectedLabelColor: CmsTheme.textSecondary,
            indicatorColor: CmsTheme.accent,
            tabs: const [
              Tab(text: 'Approved Expenditure Ledger'),
              Tab(text: 'Pending & Past Requests'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Ledger
                CmsCard(
                  padding: EdgeInsets.zero,
                  child: ledgerAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                    data: (items) {
                      if (items.isEmpty) {
                        return const CmsEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No approved expenditures in ledger',
                          subtitle: 'Approved expenditure requests automatically appear here.',
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DataTable2(
                          columnSpacing: 16,
                          horizontalMargin: 20,
                          minWidth: 750,
                          headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                          columns: const [
                            DataColumn2(label: Text('Category', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                            DataColumn2(label: Text('Description', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.L),
                            DataColumn2(label: Text('Approved', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M, numeric: true),
                            DataColumn2(label: Text('Disbursed', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M, numeric: true),
                            DataColumn2(label: Text('Status', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                            DataColumn2(label: SizedBox.shrink(), size: ColumnSize.S, fixedWidth: 120),
                          ],
                          rows: items.map((exp) => DataRow2(
                            cells: [
                              DataCell(Text(exp.category, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary))),
                              DataCell(Text(exp.description, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary))),
                              DataCell(Text('₦${exp.approvedAmount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary))),
                              DataCell(Text('₦${exp.totalDisbursed.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.accent))),
                              DataCell(StatusBadge(exp.status)),
                              DataCell(CmsButton(
                                label: 'Disburse',
                                compact: true,
                                variant: CmsButtonVariant.secondary,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DisbursementListScreen(expenditure: exp)),
                                ),
                              )),
                            ],
                          )).toList(),
                        ),
                      );
                    },
                  ),
                ),

                // Tab 2: Requests
                CmsCard(
                  padding: EdgeInsets.zero,
                  child: requestsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                    data: (requests) {
                      if (requests.isEmpty) {
                        return const CmsEmptyState(
                          icon: Icons.request_quote_outlined,
                          title: 'No expenditure requests',
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DataTable2(
                          columnSpacing: 16,
                          horizontalMargin: 20,
                          minWidth: 700,
                          headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                          columns: const [
                            DataColumn2(label: Text('Category', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                            DataColumn2(label: Text('Description', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.L),
                            DataColumn2(label: Text('Requested (₦)', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M, numeric: true),
                            DataColumn2(label: Text('Status', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                            DataColumn2(label: SizedBox.shrink(), size: ColumnSize.S, fixedWidth: 100),
                          ],
                          rows: requests.map((req) => DataRow2(
                            cells: [
                              DataCell(Text(req.category, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary))),
                              DataCell(Text(req.description, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary))),
                              DataCell(Text('₦${req.amount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary))),
                              DataCell(StatusBadge(req.status)),
                              DataCell(
                                canApprove && req.status == 'pending'
                                    ? CmsButton(
                                        label: 'Approve',
                                        icon: Icons.check,
                                        compact: true,
                                        onPressed: () async {
                                          await ref.read(financeRepositoryProvider).approveExpenditure(
                                            branchId, req.id, user!.uid, user.displayName ?? user.email,
                                          );
                                        },
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          )).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog(BuildContext context, WidgetRef ref, String branchId, dynamic user) {
    showDialog(
      context: context,
      builder: (_) => _ExpenditureFormDialog(branchId: branchId, ref: ref, user: user),
    );
  }
}

class _ExpenditureFormDialog extends StatefulWidget {
  const _ExpenditureFormDialog({required this.branchId, required this.ref, required this.user});
  final String branchId;
  final WidgetRef ref;
  final dynamic user;

  @override
  State<_ExpenditureFormDialog> createState() => _ExpenditureFormDialogState();
}

class _ExpenditureFormDialogState extends State<_ExpenditureFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amtCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Operations';
  bool _saving = false;

  static const _categories = ['Operations', 'Maintenance', 'Evangelism', 'Welfare', 'Utensils', 'Honorarium'];

  @override
  void dispose() {
    _amtCtrl.dispose();
    _descCtrl.dispose();
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
      title: const Text('New Expenditure Request', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _category,
                dropdownColor: CmsTheme.surfaceElevated,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),
              const Text('Requested Amount (₦)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Valid amount' : null,
              ),
              const SizedBox(height: 14),
              const Text('Description / Purpose', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: 'Submit Request',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final req = ExpenditureRequestModel(
                id: '',
                amount: double.parse(_amtCtrl.text.trim()),
                category: _category,
                description: _descCtrl.text.trim(),
                requestedBy: widget.user.uid,
                status: 'pending',
              );
              await widget.ref.read(financeRepositoryProvider).createExpenditureRequest(widget.branchId, req);
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
