import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/members/screens/member_detail_screen.dart';
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
  String _genderFilter = 'all';
  String _maritalFilter = 'all';
  String _ageGroupFilter = 'all';
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

    final canCreate = (user?.can(AppPermission.manageMembers) ?? false) &&
        user?.roleId != AppRole.leadPastor;

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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CmsSearchField(
                controller: _searchCtrl,
                hint: 'Search name, phone, profession…',
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
              _FilterDropdown(
                label: 'Status',
                value: _statusFilter,
                items: const {
                  'all': 'All',
                  'active': 'Active',
                  'inactive': 'Inactive',
                  'transferred': 'Transferred',
                },
                onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
              ),
              _FilterDropdown(
                label: 'Gender',
                value: _genderFilter,
                items: const {
                  'all': 'All',
                  'male': 'Male',
                  'female': 'Female',
                },
                onChanged: (v) => setState(() => _genderFilter = v ?? 'all'),
              ),
              _FilterDropdown(
                label: 'Marital',
                value: _maritalFilter,
                items: const {
                  'all': 'All',
                  'single': 'Single',
                  'married': 'Married',
                  'widowed': 'Widowed',
                  'divorced': 'Divorced',
                },
                onChanged: (v) => setState(() => _maritalFilter = v ?? 'all'),
              ),
              _FilterDropdown(
                label: 'Age Group',
                value: _ageGroupFilter,
                items: const {
                  'all': 'All',
                  '1-10': '1-10 yrs',
                  '11-18': '11-18 yrs',
                  '19-40': '19-40 yrs',
                  '41-59': '41-59 yrs',
                  '60+': '60+ yrs',
                },
                onChanged: (v) => setState(() => _ageGroupFilter = v ?? 'all'),
              ),
              if (_hasActiveFilters)
                InkWell(
                  onTap: _clearFilters,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: CmsTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CmsTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt_off, size: 14, color: CmsTheme.danger),
                        SizedBox(width: 4),
                        Text(
                          'Clear',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CmsTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
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
        MaterialPageRoute(builder: (_) => MemberDetailScreen(member: m)),
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
              leading: const Icon(Icons.person_outline, color: CmsTheme.textSecondary),
              title: const Text('View Details', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailScreen(member: m)));
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
    if (_genderFilter != 'all') {
      list = list
          .where((m) => m.gender.toLowerCase() == _genderFilter.toLowerCase())
          .toList();
    }
    if (_maritalFilter != 'all') {
      list = list
          .where((m) => (m.maritalStatus ?? '').toLowerCase() == _maritalFilter.toLowerCase())
          .toList();
    }
    if (_ageGroupFilter != 'all') {
      list = list.where((m) {
        final age = _calculateAge(m.dob);
        if (age == null) return false;
        return switch (_ageGroupFilter) {
          '1-10' => age >= 1 && age <= 10,
          '11-18' => age >= 11 && age <= 18,
          '19-40' => age >= 19 && age <= 40,
          '41-59' => age >= 41 && age <= 59,
          '60+' => age >= 60,
          _ => true,
        };
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((m) =>
        m.fullName.toLowerCase().contains(_searchQuery) ||
        m.phone.contains(_searchQuery) ||
        (m.profession != null && m.profession!.toLowerCase().contains(_searchQuery))
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

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _statusFilter != 'all' ||
      _genderFilter != 'all' ||
      _maritalFilter != 'all' ||
      _ageGroupFilter != 'all';

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _statusFilter = 'all';
      _genderFilter = 'all';
      _maritalFilter = 'all';
      _ageGroupFilter = 'all';
    });
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



class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: CmsTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CmsTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: CmsTheme.surfaceElevated,
          isDense: true,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CmsTheme.textPrimary,
          ),
          icon: const Icon(Icons.arrow_drop_down, color: CmsTheme.textSecondary, size: 18),
          items: items.entries.map((e) {
            return DropdownMenuItem<String>(
              value: e.key,
              child: Text('$label: ${e.value}'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
