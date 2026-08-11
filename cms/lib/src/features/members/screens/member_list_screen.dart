import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/members/screens/member_form_screen.dart';
import 'package:cms/src/features/members/screens/member_import_screen.dart';

final _membersProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortColumn = 'lastName';
  bool _sortAsc = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final membersAsync = ref.watch(_membersProvider(branchId));

    final canCreate = user?.can(AppPermission.manageMembers) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Members',
            subtitle: 'Manage church membership records',
            actions: [
              if (canCreate)
                CmsButton(
                  label: 'Import CSV',
                  icon: Icons.upload_outlined,
                  variant: CmsButtonVariant.secondary,
                  compact: true,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MemberImportScreen()),
                  ),
                ),
              const SizedBox(width: 10),
              if (canCreate)
                CmsButton(
                  label: 'Add Member',
                  icon: Icons.person_add_outlined,
                  compact: true,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MemberFormScreen(),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Filters row
          Row(
            children: [
              CmsSearchField(
                controller: _searchCtrl,
                hint: 'Search by name or phone…',
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
              const SizedBox(width: 12),
              _StatusFilterChip(
                selected: _statusFilter,
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Data table
          Expanded(
            child: CmsCard(
              padding: EdgeInsets.zero,
              child: membersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: CmsTheme.danger),
                  ),
                ),
                data: (members) {
                  final filtered = _filter(members);
                  if (filtered.isEmpty) {
                    return CmsEmptyState(
                      icon: Icons.people_outline,
                      title: _searchQuery.isEmpty
                          ? 'No members yet'
                          : 'No results found',
                      subtitle: _searchQuery.isEmpty && canCreate
                          ? 'Add your first member or import a CSV file.'
                          : null,
                      action: _searchQuery.isEmpty && canCreate
                          ? CmsButton(
                              label: 'Add Member',
                              icon: Icons.person_add_outlined,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MemberFormScreen(),
                                ),
                              ),
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
                      headingRowColor: WidgetStateProperty.all(
                        CmsTheme.surfaceElevated,
                      ),
                      dataRowColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return CmsTheme.surfaceElevated;
                        }
                        return CmsTheme.surface;
                      }),
                      sortColumnIndex: _sortIndex(),
                      sortAscending: _sortAsc,
                      columns: [
                        DataColumn2(
                          label: _headerText('Name'),
                          size: ColumnSize.L,
                          onSort: (_, asc) => _setSort('lastName', asc),
                        ),
                        DataColumn2(
                          label: _headerText('Phone'),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: _headerText('Gender'),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: _headerText('Status'),
                          size: ColumnSize.S,
                          onSort: (_, asc) => _setSort('memberStatus', asc),
                        ),
                        DataColumn2(
                          label: _headerText('Joined'),
                          size: ColumnSize.S,
                          onSort: (_, asc) => _setSort('joinDate', asc),
                        ),
                        const DataColumn2(
                          label: SizedBox.shrink(),
                          size: ColumnSize.S,
                          fixedWidth: 48,
                        ),
                      ],
                      rows: filtered.map((m) => _buildRow(context, m, canCreate)).toList(),
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

  DataRow2 _buildRow(BuildContext context, MemberModel m, bool canEdit) {
    return DataRow2(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MemberFormScreen(member: m)),
      ),
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: CmsTheme.accent.withValues(alpha: 0.15),
                child: Text(
                  m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CmsTheme.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  m.fullName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CmsTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(_cell(m.phone)),
        DataCell(_cell(_capitalize(m.gender))),
        DataCell(StatusBadge(m.memberStatus)),
        DataCell(_cell(_formatDate(m.joinDate))),
        DataCell(
          canEdit
              ? IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: CmsTheme.textSecondary,
                  ),
                  onPressed: () => _showOptions(context, m),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context, MemberModel m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CmsTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: CmsTheme.textSecondary),
              title: const Text('Edit Member', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => MemberFormScreen(member: m)));
              },
            ),
            if (m.memberStatus == 'active')
              ListTile(
                leading: const Icon(Icons.person_off_outlined, color: CmsTheme.warning),
                title: const Text('Mark Inactive', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
                onTap: () async {
                  Navigator.pop(context);
                  final branchId = ref.read(currentBranchIdProvider);
                  await ref.read(memberRepositoryProvider).updateMemberStatus(branchId, m.id, 'inactive');
                },
              ),
            if (m.memberStatus == 'inactive')
              ListTile(
                leading: const Icon(Icons.person_outlined, color: CmsTheme.success),
                title: const Text('Mark Active', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
                onTap: () async {
                  Navigator.pop(context);
                  final branchId = ref.read(currentBranchIdProvider);
                  await ref.read(memberRepositoryProvider).updateMemberStatus(branchId, m.id, 'active');
                },
              ),
          ],
        ),
      ),
    );
  }

  List<MemberModel> _filter(List<MemberModel> all) {
    var list = all;
    if (_statusFilter != 'all') {
      list = list.where((m) => m.memberStatus == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((m) =>
        m.fullName.toLowerCase().contains(_searchQuery) ||
        m.phone.contains(_searchQuery)
      ).toList();
    }
    list.sort((a, b) {
      final cmp = switch (_sortColumn) {
        'memberStatus' => a.memberStatus.compareTo(b.memberStatus),
        'joinDate' => a.joinDate.compareTo(b.joinDate),
        _ => a.lastName.compareTo(b.lastName),
      };
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  void _setSort(String col, bool asc) => setState(() {
    _sortColumn = col;
    _sortAsc = asc;
  });

  int? _sortIndex() => switch (_sortColumn) {
    'lastName' => 0,
    'memberStatus' => 3,
    'joinDate' => 4,
    _ => null,
  };

  Widget _headerText(String t) => Text(
    t,
    style: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: CmsTheme.textSecondary,
    ),
  );

  Widget _cell(String t) => Text(
    t,
    style: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      color: CmsTheme.textSecondary,
    ),
    overflow: TextOverflow.ellipsis,
  );

  String _capitalize(String s) =>
      s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}';

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.selected,
    required this.onChanged,
  });
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in ['all', 'active', 'inactive', 'transferred'])
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                _label(option),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected == option
                      ? Colors.white
                      : CmsTheme.textSecondary,
                ),
              ),
              selected: selected == option,
              selectedColor: CmsTheme.accent,
              backgroundColor: CmsTheme.surfaceElevated,
              side: BorderSide(
                color: selected == option
                    ? CmsTheme.accent
                    : CmsTheme.border,
              ),
              onSelected: (_) => onChanged(option),
            ),
          ),
      ],
    );
  }

  String _label(String s) => switch (s) {
    'all' => 'All',
    'active' => 'Active',
    'inactive' => 'Inactive',
    'transferred' => 'Transferred',
    _ => s,
  };
}
