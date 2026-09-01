import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/sub_groups/models/sub_group_model.dart';
import 'package:cms/src/features/sub_groups/models/sub_group_meeting_model.dart';
import 'package:cms/src/features/sub_groups/screens/sub_group_detail_screen.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/roles/screens/role_list_screen.dart';

final _subGroupsProvider = StreamProvider.autoDispose.family<List<SubGroupModel>, String>(
  (ref, branchId) => ref.watch(subGroupRepositoryProvider).watchSubGroups(branchId),
);

final _allMembersProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

final _allMeetingsProvider = StreamProvider.autoDispose.family<List<SubGroupMeetingModel>, String>(
  (ref, branchId) => ref.watch(subGroupRepositoryProvider).watchAllSubGroupMeetings(branchId),
);

class SubGroupListScreen extends ConsumerStatefulWidget {
  const SubGroupListScreen({super.key});

  @override
  ConsumerState<SubGroupListScreen> createState() => _SubGroupListScreenState();
}

class _SubGroupListScreenState extends ConsumerState<SubGroupListScreen> {
  String _searchQuery = '';
  String _selectedType = 'all';

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final subGroupsAsync = ref.watch(_subGroupsProvider(branchId));
    final meetingsAsync = ref.watch(_allMeetingsProvider(branchId));

    final isLeadPastor = user?.roleId == AppRole.leadPastor;
    // Only Secretary and Admin can create sub-groups or assign members (NOT Lead Pastor)
    final canManageGroups = (user?.roleId == AppRole.secretary ||
        user?.roleId == 'admin' ||
        (user?.can(AppPermission.manageSubGroups) ?? false)) && !isLeadPastor;
    
    final canProvisionCredentials = isLeadPastor || (user?.can(AppPermission.manageRoles) ?? false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Sub-Groups & Fellowships',
            subtitle: 'Manage House Fellowships, Sunday School Classes, and Cell Operations',
            actions: [
              if (canManageGroups)
                CmsButton(
                  label: 'Create Sub-Group',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showGroupDialog(context, ref, branchId),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Metrics Overview Bar
          subGroupsAsync.when(
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (groups) {
              final meetings = meetingsAsync.valueOrNull ?? [];
              return _buildMetricsBar(groups, meetings);
            },
          ),
          const SizedBox(height: 24),

          // Search & Category Filters
          Row(
            children: [
              SizedBox(
                width: 320,
                height: 40,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search group name, officer, or location…',
                    hintStyle: const TextStyle(color: CmsTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 16, color: CmsTheme.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CmsTheme.border)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedType,
                dropdownColor: CmsTheme.surfaceElevated,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Group Types')),
                  DropdownMenuItem(value: 'houseFellowship', child: Text('House Fellowships / Cell Groups')),
                  DropdownMenuItem(value: 'sundaySchool', child: Text('Sunday School Classes')),
                  DropdownMenuItem(value: 'bibleStudy', child: Text('Bible Study Units')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Discipleship Groups')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          subGroupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading sub-groups: $err', style: const TextStyle(color: CmsTheme.danger)),
            data: (groups) {
              final filtered = groups.where((g) {
                final matchQuery = g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (g.officerName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    g.locationAddress.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchType = _selectedType == 'all' || g.type == _selectedType;
                return matchQuery && matchType;
              }).toList();

              if (filtered.isEmpty) {
                return const CmsEmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No sub-groups registered',
                  subtitle: 'Use "Create Sub-Group" (Secretary role) to set up House Fellowships or Sunday School classes.',
                );
              }

              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: filtered.map((g) => _SubGroupCard(
                  group: g,
                  branchId: branchId,
                  canManageGroups: canManageGroups,
                  canProvisionCredentials: canProvisionCredentials,
                  ref: ref,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBar(List<SubGroupModel> groups, List<SubGroupMeetingModel> meetings) {
    final totalGroups = groups.length;
    final houseFellowships = groups.where((g) => g.type == 'houseFellowship').length;
    final totalMembers = groups.fold<int>(0, (sum, g) => sum + g.memberIds.length);
    final totalOfferings = meetings.fold<double>(0.0, (sum, m) => sum + m.offeringAmount);

    return Row(
      children: [
        Expanded(
          child: CmsCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: CmsTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.home_work_outlined, color: CmsTheme.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Sub-Groups', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text('$totalGroups groups', style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: CmsTheme.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CmsCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: CmsTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.groups_outlined, color: CmsTheme.warning, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('House Fellowships', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text('$houseFellowships cell units', style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: CmsTheme.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CmsCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: CmsTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.person_search_outlined, color: CmsTheme.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assigned Members', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text('$totalMembers members', style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: CmsTheme.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CmsCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: CmsTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: CmsTheme.success, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Meetings Income', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text('₦${totalOfferings.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: CmsTheme.success)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showGroupDialog(BuildContext context, WidgetRef ref, String branchId, {SubGroupModel? existingGroup}) {
    showDialog(
      context: context,
      builder: (_) => _SubGroupFormDialog(branchId: branchId, existingGroup: existingGroup),
    );
  }
}

class _SubGroupCard extends StatelessWidget {
  const _SubGroupCard({
    required this.group,
    required this.branchId,
    required this.canManageGroups,
    required this.canProvisionCredentials,
    required this.ref,
  });

  final SubGroupModel group;
  final String branchId;
  final bool canManageGroups;
  final bool canProvisionCredentials;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubGroupDetailScreen(group: group, branchId: branchId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 340,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CmsTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.home_work_outlined, color: CmsTheme.accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                      Text(group.typeDisplayName, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: CmsTheme.textMuted),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: CmsTheme.textMuted),
                const SizedBox(width: 6),
                Text('${group.meetingDay} at ${group.meetingTime}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: CmsTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(child: Text(group.locationAddress.isNotEmpty ? group.locationAddress : 'Location TBD', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: CmsTheme.textMuted),
                const SizedBox(width: 6),
                Text('${group.memberIds.length} members assigned', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
              ],
            ),
            const Divider(height: 24, color: CmsTheme.border),

            // Officer Badge & Provision Action
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 14, color: CmsTheme.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Officer: ${group.officerName ?? 'Not Assigned'}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Actions
            Row(
              children: [
                if (canManageGroups)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_alt, size: 14),
                    label: const Text('Manage Members', style: TextStyle(fontSize: 11)),
                    onPressed: () => _showMemberAssignModal(context, ref, branchId, group),
                  )
                else
                  const Text('Click card to view details & reports', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.accent, fontStyle: FontStyle.italic)),
                const Spacer(),
                // Lead Pastor Exclusive Credential Provisioning
                if (canProvisionCredentials)
                  IconButton(
                    icon: const Icon(Icons.vpn_key_outlined, size: 18, color: CmsTheme.accent),
                    tooltip: 'Provision Officer Login Credentials (Lead Pastor Only)',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ProvisionStaffDialog(branchId: branchId),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showMemberAssignModal(BuildContext context, WidgetRef ref, String branchId, SubGroupModel group) {
  showDialog(
    context: context,
    builder: (_) => _SubGroupMemberAssignDialog(branchId: branchId, group: group),
  );
}

class _SubGroupFormDialog extends ConsumerStatefulWidget {
  const _SubGroupFormDialog({required this.branchId, this.existingGroup});

  final String branchId;
  final SubGroupModel? existingGroup;

  @override
  ConsumerState<_SubGroupFormDialog> createState() => _SubGroupFormDialogState();
}

class _SubGroupFormDialogState extends ConsumerState<_SubGroupFormDialog> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _dayController = TextEditingController(text: 'Sunday');
  final _timeController = TextEditingController(text: '17:00');
  String _selectedType = 'houseFellowship';
  String? _selectedOfficerId;
  String? _selectedOfficerName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingGroup != null) {
      final g = widget.existingGroup!;
      _nameController.text = g.name;
      _locationController.text = g.locationAddress;
      _dayController.text = g.meetingDay;
      _timeController.text = g.meetingTime;
      _selectedType = g.type;
      _selectedOfficerId = g.recordingOfficerMemberId.isNotEmpty ? g.recordingOfficerMemberId : null;
      _selectedOfficerName = g.officerName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _dayController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_allMembersProvider(widget.branchId));
    final isEditing = widget.existingGroup != null;

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: CmsTheme.border)),
      title: Text(isEditing ? 'Edit Sub-Group' : 'Create New Sub-Group', style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Group Name', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(hintText: 'e.g. Grace House Fellowship 1, Sunday School Class A…'),
              ),
              const SizedBox(height: 14),
              const Text('Group Type', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: CmsTheme.surfaceElevated,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                items: const [
                  DropdownMenuItem(value: 'houseFellowship', child: Text('House Fellowship / Cell Group')),
                  DropdownMenuItem(value: 'sundaySchool', child: Text('Sunday School Class')),
                  DropdownMenuItem(value: 'bibleStudy', child: Text('Bible Study Unit')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Discipleship Group')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 14),
              const Text('Designate Recording Officer', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              membersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Could not load members', style: TextStyle(color: CmsTheme.danger)),
                data: (members) => DropdownButtonFormField<String>(
                  value: _selectedOfficerId,
                  dropdownColor: CmsTheme.surfaceElevated,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'Select recording officer…'),
                  items: members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedOfficerId = v;
                      if (v != null) {
                        final m = members.firstWhere((element) => element.id == v);
                        _selectedOfficerName = m.fullName;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Meeting Day', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(controller: _dayController, style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Meeting Time', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(controller: _timeController, style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Location / Address', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _locationController,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(hintText: 'e.g. 14 Allen Avenue, Ikeja, Lagos'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: isEditing ? 'Save Changes' : 'Create Group',
          compact: true,
          loading: _saving,
          onPressed: _nameController.text.trim().isNotEmpty
              ? () async {
                  setState(() => _saving = true);
                  try {
                    final repo = ref.read(subGroupRepositoryProvider);
                    final group = SubGroupModel(
                      id: widget.existingGroup?.id ?? '',
                      branchId: widget.branchId,
                      name: _nameController.text.trim(),
                      type: _selectedType,
                      recordingOfficerMemberId: _selectedOfficerId ?? '',
                      officerName: _selectedOfficerName,
                      locationAddress: _locationController.text.trim(),
                      meetingDay: _dayController.text.trim(),
                      meetingTime: _timeController.text.trim(),
                    );
                    if (isEditing) {
                      await repo.updateSubGroup(group);
                    } else {
                      await repo.createSubGroup(group);
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger));
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                }
              : null,
        ),
      ],
    );
  }
}

class _SubGroupMemberAssignDialog extends ConsumerStatefulWidget {
  const _SubGroupMemberAssignDialog({required this.branchId, required this.group});

  final String branchId;
  final SubGroupModel group;

  @override
  ConsumerState<_SubGroupMemberAssignDialog> createState() => _SubGroupMemberAssignDialogState();
}

class _SubGroupMemberAssignDialogState extends ConsumerState<_SubGroupMemberAssignDialog> {
  final Set<String> _selectedMemberIds = {};
  bool _saving = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selectedMemberIds.addAll(widget.group.memberIds);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_allMembersProvider(widget.branchId));

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: CmsTheme.border)),
      title: Text('Assign Members to ${widget.group.name}', style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
      content: SizedBox(
        width: 480,
        height: 400,
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search members by name…',
                prefixIcon: Icon(Icons.search, size: 16, color: CmsTheme.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                data: (members) {
                  final filtered = members.where((m) => m.fullName.toLowerCase().contains(_search)).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No members found', style: TextStyle(color: CmsTheme.textMuted)));
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 1),
                    itemBuilder: (context, i) {
                      final m = filtered[i];
                      final isChecked = _selectedMemberIds.contains(m.id);
                      return CheckboxListTile(
                        value: isChecked,
                        title: Text(m.fullName, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary)),
                        subtitle: Text(m.phone.isNotEmpty ? m.phone : (m.email ?? ''), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedMemberIds.add(m.id);
                            } else {
                              _selectedMemberIds.remove(m.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: 'Save Members',
          compact: true,
          loading: _saving,
          onPressed: () async {
            setState(() => _saving = true);
            try {
              await ref.read(subGroupRepositoryProvider).assignMembersToGroup(
                widget.branchId,
                widget.group.id,
                _selectedMemberIds.toList(),
              );
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger));
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
