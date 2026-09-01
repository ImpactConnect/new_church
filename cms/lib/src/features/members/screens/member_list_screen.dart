import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
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
  String _baptismFilter = 'all';
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Member Directory',
            subtitle: 'Pastoral record management, demographics & member care',
            actions: [
              if (membersAsync.valueOrNull != null && membersAsync.valueOrNull!.isNotEmpty)
                CmsButton(
                  label: 'Export CSV',
                  icon: Icons.download_outlined,
                  variant: CmsButtonVariant.secondary,
                  compact: true,
                  onPressed: () => _exportCsv(context, _filter(membersAsync.valueOrNull!)),
                ),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
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
          const SizedBox(height: 12),

          // ── Compact KPI Summary Cards ──────────────────────────────────────
          membersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (members) {
              final now = DateTime.now();
              final activeCount = members.where((m) => m.memberStatus == 'active').length;
              final joinedThisMonth = members.where((m) =>
                m.joinDate.month == now.month && m.joinDate.year == now.year
              ).length;
              final birthdaysThisMonth = members.where((m) =>
                m.dob != null && m.dob!.month == now.month
              ).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    _kpiCard('Total Membership', '${members.length}', CmsTheme.accent, Icons.groups_outlined),
                    const SizedBox(width: 12),
                    _kpiCard('Active Members', '$activeCount', CmsTheme.success, Icons.check_circle_outline),
                    const SizedBox(width: 12),
                    _kpiCard('Joined This Month', '$joinedThisMonth', const Color(0xFF8B5CF6), Icons.person_add_alt_outlined),
                    const SizedBox(width: 12),
                    _kpiCard('Birthdays This Month', '$birthdaysThisMonth', CmsTheme.warning, Icons.cake_outlined),
                  ],
                ),
              );
            },
          ),

          // ── Single Row Filter Bar ───────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 220,
                  child: CmsSearchField(
                    controller: _searchCtrl,
                    hint: 'Search name, phone, code…',
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
                _FilterDropdown(
                  label: 'Age',
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
                const SizedBox(width: 8),
                _FilterDropdown(
                  label: 'Baptism',
                  value: _baptismFilter,
                  items: const {
                    'all': 'All',
                    'yes': 'Baptized',
                    'no': 'Not Baptized',
                  },
                  onChanged: (v) => setState(() => _baptismFilter = v ?? 'all'),
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(width: 8),
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
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Data table with Maximized Space ────────────────────────────────
          Expanded(
            child: CmsCard(
              padding: EdgeInsets.zero,
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
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
                          ? 'No members registered'
                          : 'No matching members found',
                      subtitle: _searchQuery.isEmpty && canCreate
                          ? 'Add your first church member to start tracking.'
                          : 'Try adjusting your search or filters.',
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

                  return Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: CmsTheme.surface,
                      dividerColor: CmsTheme.border,
                    ),
                    child: DataTable2(
                      columnSpacing: 16,
                      horizontalMargin: 16,
                      minWidth: 800,
                      sortColumnIndex: _sortIndex(),
                      sortAscending: _sortAsc,
                      columns: [
                        const DataColumn2(
                          label: Text('Member Code', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)),
                          size: ColumnSize.S,
                          fixedWidth: 120,
                        ),
                        DataColumn2(
                          label: _headerText('Member Name & Email'),
                          size: ColumnSize.L,
                          onSort: (_, asc) => _setSort('lastName', asc),
                        ),
                        const DataColumn2(
                          label: Text('Phone Number', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)),
                          size: ColumnSize.M,
                        ),
                        const DataColumn2(
                          label: Text('Gender / Marital', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: _headerText('Status'),
                          size: ColumnSize.S,
                          onSort: (_, asc) => _setSort('memberStatus', asc),
                        ),
                        DataColumn2(
                          label: _headerText('Joined Date'),
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

  Widget _kpiCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CmsTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CmsTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CmsTheme.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: CmsTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        // Member Code
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CmsTheme.bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: CmsTheme.border),
            ),
            child: Text(
              m.memberCode?.isNotEmpty == true ? m.memberCode! : '—',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CmsTheme.textSecondary,
              ),
            ),
          ),
        ),

        // Name & Email
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: CmsTheme.accent.withValues(alpha: 0.15),
                backgroundImage: (m.profileImageUrl != null && m.profileImageUrl!.isNotEmpty)
                    ? NetworkImage(m.profileImageUrl!)
                    : null,
                child: (m.profileImageUrl == null || m.profileImageUrl!.isEmpty)
                    ? Text(
                        m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CmsTheme.accent,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fullName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CmsTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (m.email?.isNotEmpty == true)
                      Text(
                        m.email!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: CmsTheme.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Phone
        DataCell(
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 13, color: CmsTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                m.phone,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: CmsTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Gender & Marital
        DataCell(
          Text(
            '${_capitalize(m.gender)}${m.maritalStatus != null ? " • ${_capitalize(m.maritalStatus!)}" : ""}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: CmsTheme.textSecondary,
            ),
          ),
        ),

        // Status Badge
        DataCell(StatusBadge(m.memberStatus)),

        // Joined Date
        DataCell(
          Text(
            DateFormat('dd/MM/yyyy').format(m.joinDate),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: CmsTheme.textSecondary,
            ),
          ),
        ),

        // Options
        DataCell(
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              size: 18,
              color: CmsTheme.textSecondary,
            ),
            onPressed: () => _showOptions(context, m, canEdit),
          ),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context, MemberModel m, bool canEdit) {
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
              leading: const Icon(Icons.person_outline, color: CmsTheme.accent),
              title: const Text('View Profile', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailScreen(member: m)));
              },
            ),
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: CmsTheme.textSecondary),
                title: const Text('Edit Member Details', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MemberFormScreen(member: m)));
                },
              ),
            if (canEdit && m.memberStatus == 'active')
              ListTile(
                leading: const Icon(Icons.person_off_outlined, color: CmsTheme.warning),
                title: const Text('Mark as Inactive', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
                onTap: () async {
                  Navigator.pop(context);
                  final branchId = ref.read(currentBranchIdProvider);
                  await ref.read(memberRepositoryProvider).updateMemberStatus(branchId, m.id, 'inactive');
                },
              ),
            if (canEdit && m.memberStatus == 'inactive')
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: CmsTheme.success),
                title: const Text('Re-activate Member', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
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

  void _exportCsv(BuildContext context, List<MemberModel> members) {
    final rows = <List<dynamic>>[
      ['Member Code', 'First Name', 'Last Name', 'Phone', 'Email', 'Gender', 'Status', 'Marital Status', 'Profession', 'Join Date', 'Water Baptized', 'Address'],
      ...members.map((m) => [
        m.memberCode ?? '',
        m.firstName,
        m.lastName,
        m.phone,
        m.email ?? '',
        m.gender,
        m.memberStatus,
        m.maritalStatus ?? '',
        m.profession ?? '',
        DateFormat('yyyy-MM-dd').format(m.joinDate),
        m.waterBaptized == true ? 'Yes' : 'No',
        m.residentAddress ?? '',
      ]),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csvData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${members.length} members to CSV format.'),
        backgroundColor: CmsTheme.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  List<MemberModel> _filter(List<MemberModel> all) {
    var list = all;
    if (_statusFilter != 'all') {
      list = list.where((m) => m.memberStatus == _statusFilter).toList();
    }
    if (_genderFilter != 'all') {
      list = list.where((m) => m.gender.toLowerCase() == _genderFilter.toLowerCase()).toList();
    }
    if (_maritalFilter != 'all') {
      list = list.where((m) => (m.maritalStatus ?? '').toLowerCase() == _maritalFilter.toLowerCase()).toList();
    }
    if (_baptismFilter != 'all') {
      final isBap = _baptismFilter == 'yes';
      list = list.where((m) => (m.waterBaptized ?? false) == isBap).toList();
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
      list = list.where((m) {
        final name = m.fullName.toLowerCase();
        final phone = m.phone.toLowerCase();
        final code = (m.memberCode ?? '').toLowerCase();
        final email = (m.email ?? '').toLowerCase();
        final prof = (m.profession ?? '').toLowerCase();
        return name.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            code.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            prof.contains(_searchQuery);
      }).toList();
    }

    list.sort((a, b) {
      final cmp = switch (_sortColumn) {
        'memberStatus' => a.memberStatus.compareTo(b.memberStatus),
        'joinDate' => a.joinDate.compareTo(b.joinDate),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _statusFilter != 'all' ||
      _genderFilter != 'all' ||
      _maritalFilter != 'all' ||
      _ageGroupFilter != 'all' ||
      _baptismFilter != 'all';

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
      _statusFilter = 'all';
      _genderFilter = 'all';
      _maritalFilter = 'all';
      _ageGroupFilter = 'all';
      _baptismFilter = 'all';
    });
  }

  int? _sortIndex() => switch (_sortColumn) {
        'memberStatus' => 4,
        'joinDate' => 5,
        _ => 1,
      };

  void _setSort(String col, bool asc) {
    setState(() {
      _sortColumn = col;
      _sortAsc = asc;
    });
  }

  Widget _headerText(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CmsTheme.textSecondary,
        ),
      );

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
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
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: CmsTheme.textSecondary,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              dropdownColor: CmsTheme.surfaceElevated,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CmsTheme.textPrimary,
              ),
              items: items.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
