import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/audit/models/audit_log_model.dart';

final _auditLogsProvider = StreamProvider.autoDispose.family<List<AuditLogModel>, String>(
  (ref, branchId) => ref.watch(auditLogRepositoryProvider).watchAuditLogs(branchId, limit: 100),
);

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _searchCtrl = TextEditingController();
  String _moduleFilter = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final logsAsync = ref.watch(_auditLogsProvider(branchId));

    // Audit logs are full view for Lead Pastor, scoped or restricted for others
    final canViewFull = user?.can(AppPermission.manageRoles) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Audit Trail',
            subtitle: 'Immutable record of system activity and data changes',
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CmsTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CmsTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: CmsTheme.accent),
                    SizedBox(width: 6),
                    Text(
                      'Tamper-Proof Ledger',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CmsTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CmsSearchField(
                controller: _searchCtrl,
                hint: 'Search logs by actor or document…',
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _moduleFilter,
                dropdownColor: CmsTheme.surfaceElevated,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter', fontSize: 13),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Modules')),
                  DropdownMenuItem(value: 'members', child: Text('Members')),
                  DropdownMenuItem(value: 'departments', child: Text('Departments')),
                  DropdownMenuItem(value: 'roles', child: Text('Roles')),
                  DropdownMenuItem(value: 'budgets', child: Text('Budgets')),
                  DropdownMenuItem(value: 'expenditures', child: Text('Expenditures')),
                ],
                onChanged: (v) => setState(() => _moduleFilter = v ?? 'all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CmsCard(
              padding: EdgeInsets.zero,
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error loading audit logs: $e', style: const TextStyle(color: CmsTheme.danger)),
                ),
                data: (logs) {
                  final filtered = logs.where((l) {
                    if (_moduleFilter != 'all' && l.module != _moduleFilter) return false;
                    if (!canViewFull && l.performedBy != user?.uid) return false;
                    if (_searchQuery.isNotEmpty) {
                      return l.performedByName.toLowerCase().contains(_searchQuery) ||
                          l.documentId.toLowerCase().contains(_searchQuery) ||
                          l.action.toLowerCase().contains(_searchQuery);
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const CmsEmptyState(
                      icon: Icons.history_outlined,
                      title: 'No audit records found',
                      subtitle: 'System activities will automatically log here.',
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
                        DataColumn2(label: Text('Timestamp', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                        DataColumn2(label: Text('Module', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                        DataColumn2(label: Text('Action', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                        DataColumn2(label: Text('Performed By', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                        DataColumn2(label: Text('Document ID', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.L),
                      ],
                      rows: filtered.map((log) => _buildRow(log)).toList(),
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

  DataRow2 _buildRow(AuditLogModel log) {
    return DataRow2(
      cells: [
        DataCell(Text(_formatDateTime(log.timestamp), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: CmsTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(log.module, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: CmsTheme.accent)),
        )),
        DataCell(StatusBadge(log.action)),
        DataCell(Text(log.performedByName.isNotEmpty ? log.performedByName : log.performedBy, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary))),
        DataCell(Text(log.documentId, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
