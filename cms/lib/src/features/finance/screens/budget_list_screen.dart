import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';

final _budgetsProvider = StreamProvider.autoDispose.family<List<BudgetModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchBudgets(branchId),
);

class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final budgetsAsync = ref.watch(_budgetsProvider(branchId));

    final canRequest = user?.can(AppPermission.createBudgetRequest) ?? false;
    final canApprove = user?.can(AppPermission.approveBudget) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Budget Allocations',
            subtitle: 'Manage fiscal department budgets and budget requests',
            actions: [
              if (canRequest)
                CmsButton(
                  label: 'Request Budget',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showRequestDialog(context, ref, branchId, user!),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: budgetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
              data: (budgets) {
                if (budgets.isEmpty) {
                  return CmsEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No budget allocations',
                    subtitle: 'Submit a budget request for Lead Pastor approval.',
                    action: canRequest
                        ? CmsButton(
                            label: 'Request Budget',
                            icon: Icons.add,
                            onPressed: () => _showRequestDialog(context, ref, branchId, user!),
                          )
                        : null,
                  );
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: budgets.length,
                  itemBuilder: (_, i) => _BudgetCard(
                    budget: budgets[i],
                    canApprove: canApprove,
                    currentUserId: user?.uid ?? '',
                    onApprove: () async {
                      await ref.read(financeRepositoryProvider).approveBudget(
                        branchId, budgets[i].id, user!.uid, user.displayName ?? user.email,
                      );
                    },
                    onReject: () async {
                      await ref.read(financeRepositoryProvider).rejectBudget(
                        branchId, budgets[i].id, 'Rejected by Pastor',
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog(BuildContext context, WidgetRef ref, String branchId, dynamic user) {
    showDialog(
      context: context,
      builder: (_) => _BudgetFormDialog(branchId: branchId, ref: ref, user: user),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.canApprove,
    required this.currentUserId,
    required this.onApprove,
    required this.onReject,
  });

  final BudgetModel budget;
  final bool canApprove;
  final String currentUserId;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final isRequester = currentUserId == budget.requestedBy;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(budget.status),
              const Spacer(),
              Text(
                budget.fiscalPeriod,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            budget.category,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '₦${budget.requestedAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: CmsTheme.accent),
          ),
          const Spacer(),
          if (canApprove && budget.status == 'pending') ...[
            if (isRequester)
              const Text(
                'Segregation of duties: Cannot approve your own request',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.danger),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CmsButton(label: 'Reject', compact: true, variant: CmsButtonVariant.danger, onPressed: onReject),
                  const SizedBox(width: 8),
                  CmsButton(label: 'Approve', icon: Icons.check, compact: true, onPressed: onApprove),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _BudgetFormDialog extends StatefulWidget {
  const _BudgetFormDialog({required this.branchId, required this.ref, required this.user});
  final String branchId;
  final WidgetRef ref;
  final dynamic user;

  @override
  State<_BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<_BudgetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amtCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  String _fiscalYear = 'FY-2026';
  bool _saving = false;

  @override
  void dispose() {
    _amtCtrl.dispose();
    _catCtrl.dispose();
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
      title: const Text('New Budget Request', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Budget Category / Title', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _catCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(hintText: 'e.g. Q3 Youth Convention, Choir Equipment'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fiscal Period', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _fiscalYear,
                          dropdownColor: CmsTheme.surfaceElevated,
                          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                          decoration: const InputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'FY-2026', child: Text('FY-2026')),
                            DropdownMenuItem(value: 'FY-2027', child: Text('FY-2027')),
                          ],
                          onChanged: (v) => setState(() => _fiscalYear = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Requested Amount (₦)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
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
          label: 'Submit Request',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final budget = BudgetModel(
                id: '',
                fiscalPeriod: _fiscalYear,
                category: _catCtrl.text.trim(),
                requestedAmount: double.parse(_amtCtrl.text.trim()),
                status: 'pending',
                requestedBy: widget.user.uid,
              );
              await widget.ref.read(financeRepositoryProvider).createBudgetRequest(widget.branchId, budget);
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
