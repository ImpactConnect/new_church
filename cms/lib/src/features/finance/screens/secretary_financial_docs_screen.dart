import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';

final _approvedBudgetsProvider =
    StreamProvider.autoDispose.family<List<BudgetModel>, String>(
  (ref, branchId) =>
      ref.watch(financeRepositoryProvider).watchApprovedBudgets(branchId),
);

final _approvedExpendituresProvider =
    StreamProvider.autoDispose.family<List<ExpenditureModel>, String>(
  (ref, branchId) =>
      ref.watch(financeRepositoryProvider).watchApprovedExpenditures(branchId),
);

class SecretaryFinancialDocsScreen extends ConsumerStatefulWidget {
  const SecretaryFinancialDocsScreen({super.key});

  @override
  ConsumerState<SecretaryFinancialDocsScreen> createState() =>
      _SecretaryFinancialDocsScreenState();
}

class _SecretaryFinancialDocsScreenState
    extends ConsumerState<SecretaryFinancialDocsScreen>
    with SingleTickerProviderStateMixin {
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
    final budgetsAsync = ref.watch(_approvedBudgetsProvider(branchId));
    final expendituresAsync = ref.watch(_approvedExpendituresProvider(branchId));

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: CmsPageHeader(
                  title: 'Financial Documentation',
                  subtitle: 'Read-only record of all approved budgets and expenditures',
                ),
              ),
              // Approved-only badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CmsTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CmsTheme.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_outlined, size: 14, color: CmsTheme.success),
                    const SizedBox(width: 6),
                    const Text(
                      'Approved Records Only',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CmsTheme.success,
                      ),
                    ),
                  ],
                ),
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
              Tab(text: 'Approved Budgets'),
              Tab(text: 'Approved Expenditures'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 1: Approved Budgets ──────────────────────────────────
                CmsCard(
                  padding: EdgeInsets.zero,
                  child: budgetsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text('Error: $e',
                          style: const TextStyle(color: CmsTheme.danger)),
                    ),
                    data: (budgets) {
                      if (budgets.isEmpty) {
                        return const CmsEmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'No approved budgets yet',
                          subtitle: 'Approved budget allocations will appear here once the Lead Pastor approves them.',
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DataTable2(
                          columnSpacing: 16,
                          horizontalMargin: 20,
                          minWidth: 760,
                          headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                          dataRowColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return CmsTheme.surfaceElevated;
                            }
                            return CmsTheme.surface;
                          }),
                          columns: const [
                            DataColumn2(
                              label: Text('Category',
                                  style: _colStyle),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Fiscal Period',
                                  style: _colStyle),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Approved Amount',
                                  style: _colStyle),
                              size: ColumnSize.M,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('Description',
                                  style: _colStyle),
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text('Approved By',
                                  style: _colStyle),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Date',
                                  style: _colStyle),
                              size: ColumnSize.S,
                            ),
                          ],
                          rows: budgets.map((b) => DataRow2(
                            cells: [
                              DataCell(Text(
                                b.approvedCategory ?? b.category,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: CmsTheme.textPrimary,
                                ),
                              )),
                              DataCell(Text(
                                b.fiscalPeriod,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: CmsTheme.textSecondary,
                                ),
                              )),
                              DataCell(Text(
                                '₦${(b.approvedAmount ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: CmsTheme.accent,
                                ),
                              )),
                              DataCell(Text(
                                b.approvedDescription ?? b.requestedDescription ?? '—',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: CmsTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )),
                              DataCell(Text(
                                b.approvedBy ?? '—',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: CmsTheme.textMuted,
                                ),
                              )),
                              DataCell(Text(
                                b.approvedAt != null
                                    ? '${b.approvedAt!.day}/${b.approvedAt!.month}/${b.approvedAt!.year}'
                                    : '—',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: CmsTheme.textSecondary,
                                ),
                              )),
                            ],
                          )).toList(),
                        ),
                      );
                    },
                  ),
                ),

                // ── Tab 2: Approved Expenditures ─────────────────────────────
                CmsCard(
                  padding: EdgeInsets.zero,
                  child: expendituresAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text('Error: $e',
                          style: const TextStyle(color: CmsTheme.danger)),
                    ),
                    data: (expenditures) {
                      if (expenditures.isEmpty) {
                        return const CmsEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No approved expenditures yet',
                          subtitle: 'Approved expenditure records will appear here once requests are approved by the Lead Pastor.',
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DataTable2(
                          columnSpacing: 16,
                          horizontalMargin: 20,
                          minWidth: 820,
                          headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                          dataRowColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return CmsTheme.surfaceElevated;
                            }
                            return CmsTheme.surface;
                          }),
                          columns: const [
                            DataColumn2(
                              label: Text('Category', style: _colStyle),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Description', style: _colStyle),
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text('Approved Amount', style: _colStyle),
                              size: ColumnSize.M,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('Disbursed', style: _colStyle),
                              size: ColumnSize.M,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: Text('Status', style: _colStyle),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Approved By', style: _colStyle),
                              size: ColumnSize.M,
                            ),
                            DataColumn2(
                              label: Text('Date', style: _colStyle),
                              size: ColumnSize.S,
                            ),
                          ],
                          rows: expenditures.map((e) => DataRow2(
                            cells: [
                              DataCell(Text(
                                e.category,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: CmsTheme.textPrimary,
                                ),
                              )),
                              DataCell(Text(
                                e.description,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: CmsTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )),
                              DataCell(Text(
                                '₦${e.approvedAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: CmsTheme.accent,
                                ),
                              )),
                              DataCell(Text(
                                '₦${e.totalDisbursed.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: CmsTheme.textSecondary,
                                ),
                              )),
                              DataCell(StatusBadge(e.status)),
                              DataCell(Text(
                                e.approvedBy,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: CmsTheme.textMuted,
                                ),
                              )),
                              DataCell(Text(
                                '${e.date.day}/${e.date.month}/${e.date.year}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: CmsTheme.textSecondary,
                                ),
                              )),
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
}

const _colStyle = TextStyle(
  color: CmsTheme.textSecondary,
  fontFamily: 'Inter',
  fontSize: 12,
  fontWeight: FontWeight.w600,
);
