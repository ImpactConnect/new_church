import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/sub_groups/models/sub_group_model.dart';
import 'package:cms/src/features/sub_groups/models/sub_group_meeting_model.dart';
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

class _SubGroupListScreenState extends ConsumerState<SubGroupListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final subGroupsAsync = ref.watch(_subGroupsProvider(branchId));
    final canManageGroups = user?.roleId == AppRole.leadPastor ||
        user?.roleId == AppRole.secretary ||
        user?.roleId == AppRole.branchPastor ||
        (user?.can(AppPermission.manageSubGroups) ?? false);
    final canProvisionCredentials = user?.roleId == AppRole.leadPastor ||
        (user?.can(AppPermission.manageRoles) ?? false); // Lead Pastor ONLY

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CmsPageHeader(
                title: 'Sub-Groups & Fellowships',
                subtitle: 'Manage House Fellowships, Sunday School Classes, and Sub-Group Operations',
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

              // Filter & Navigation Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: CmsTheme.accent,
                labelColor: CmsTheme.accent,
                unselectedLabelColor: CmsTheme.textMuted,
                tabs: const [
                  Tab(text: 'All Sub-Groups Directory'),
                  Tab(text: 'Group Meetings & Entry'),
                  Tab(text: 'Sub-Group Analytics & Reports'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Directory & Group Management
              _buildDirectoryTab(subGroupsAsync, branchId, canManageGroups, canProvisionCredentials),

              // Tab 2: Group Meetings & Entry (Mobile-First Entry Screen)
              _buildMeetingsTab(branchId, subGroupsAsync, user),

              // Tab 3: Analytics & Reports
              _buildReportsTab(branchId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectoryTab(
    AsyncValue<List<SubGroupModel>> subGroupsAsync,
    String branchId,
    bool canManageGroups,
    bool canProvisionCredentials,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Category Filter
          Row(
            children: [
              SizedBox(
                width: 300,
                height: 38,
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
                  DropdownMenuItem(value: 'houseFellowship', child: Text('House Fellowships')),
                  DropdownMenuItem(value: 'sundaySchool', child: Text('Sunday School Classes')),
                  DropdownMenuItem(value: 'bibleStudy', child: Text('Bible Study Units')),
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
                  subtitle: 'Use "Create Sub-Group" to set up House Fellowships or Sunday School classes.',
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMeetingsTab(String branchId, AsyncValue<List<SubGroupModel>> subGroupsAsync, dynamic user) {
    return subGroupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
      data: (groups) {
        if (groups.isEmpty) {
          return const CmsEmptyState(
            icon: Icons.meeting_room_outlined,
            title: 'No sub-groups available',
            subtitle: 'Register a sub-group first to record meeting reports.',
          );
        }

        return _MeetingRecorderView(branchId: branchId, groups: groups);
      },
    );
  }

  Widget _buildReportsTab(String branchId) {
    final meetingsAsync = ref.watch(_allMeetingsProvider(branchId));

    return meetingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading report data: $e', style: const TextStyle(color: CmsTheme.danger))),
      data: (meetings) {
        final totalAttendance = meetings.fold<int>(0, (sum, m) => sum + m.headCount);
        final totalOffering = meetings.fold<double>(0.0, (sum, m) => sum + m.offeringAmount);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CmsCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: CmsTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.people_alt_outlined, color: CmsTheme.accent, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Sub-Group Attendance', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text('$totalAttendance attendees', style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: CmsTheme.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
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
                              const Text('Total Sub-Group Offerings', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text('₦${totalOffering.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: CmsTheme.success)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Recent Sub-Group Meeting Reports', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
              const SizedBox(height: 12),
              if (meetings.isEmpty)
                const CmsEmptyState(
                  icon: Icons.assessment_outlined,
                  title: 'No meeting reports submitted yet',
                  subtitle: 'Recording officers can submit meeting reports from their sub-group dashboard.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: meetings.length,
                  separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 1),
                  itemBuilder: (context, i) {
                    final m = meetings[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: CmsTheme.surfaceElevated,
                        child: Icon(Icons.class_outlined, color: CmsTheme.accent, size: 18),
                      ),
                      title: Text('Meeting Date: ${m.meetingDate.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                      subtitle: Text('Attendees: ${m.headCount} | ${m.attendeeMemberIds.length} checked by name', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                      trailing: Text('₦${m.offeringAmount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: CmsTheme.success)),
                    );
                  },
                ),
            ],
          ),
        );
      },
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
    return Container(
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
              if (canManageGroups) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_alt, size: 14),
                  label: const Text('Manage Members', style: TextStyle(fontSize: 11)),
                  onPressed: () => _showMemberAssignModal(context, ref, branchId, group),
                ),
                const Spacer(),
              ],
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
    );
  }

  void _showMemberAssignModal(BuildContext context, WidgetRef ref, String branchId, SubGroupModel group) {
    showDialog(
      context: context,
      builder: (_) => _SubGroupMemberAssignDialog(branchId: branchId, group: group),
    );
  }
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
      _selectedOfficerId = g.recordingOfficerMemberId;
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
  late Set<String> _selectedMemberIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedMemberIds = Set<String>.from(widget.group.memberIds);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_allMembersProvider(widget.branchId));

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: CmsTheme.border)),
      title: Text('Assign Members to "${widget.group.name}"', style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 500,
        height: 450,
        child: membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e', style: const TextStyle(color: CmsTheme.danger)),
          data: (members) {
            return ListView.separated(
              itemCount: members.length,
              separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 1),
              itemBuilder: (context, i) {
                final m = members[i];
                final isSelected = _selectedMemberIds.contains(m.id);
                return CheckboxListTile(
                  title: Text(m.fullName, style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary)),
                  subtitle: Text(m.phone.isNotEmpty ? m.phone : (m.email ?? ''), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                  value: isSelected,
                  activeColor: CmsTheme.accent,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
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
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: 'Save Assignments',
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
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger));
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
        ),
      ],
    );
  }
}

// ── Mobile-First Meeting Entry View ──────────────────────────────────────────

class _MeetingRecorderView extends ConsumerStatefulWidget {
  const _MeetingRecorderView({required this.branchId, required this.groups});
  final String branchId;
  final List<SubGroupModel> groups;

  @override
  ConsumerState<_MeetingRecorderView> createState() => _MeetingRecorderViewState();
}

class _MeetingRecorderViewState extends ConsumerState<_MeetingRecorderView> {
  late String _selectedGroupId;
  final _headCountController = TextEditingController(text: '0');
  final _offeringController = TextEditingController(text: '0.00');
  final _notesController = TextEditingController();
  final Set<String> _attendeeIds = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groups.first.id;
  }

  @override
  void dispose() {
    _headCountController.dispose();
    _offeringController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600), // Mobile-First responsive container
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Selector Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CmsTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CmsTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Active Sub-Group', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textMuted)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedGroupId,
                      dropdownColor: CmsTheme.surfaceElevated,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: CmsTheme.textPrimary),
                      decoration: const InputDecoration(isDense: true),
                      items: widget.groups.map((g) => DropdownMenuItem(value: g.id, child: Text('${g.name} (${g.typeDisplayName})'))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedGroupId = v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Touch-Friendly Headcount Counter
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CmsTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CmsTheme.border),
                ),
                child: Column(
                  children: [
                    const Text('Total Meeting Headcount', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          iconSize: 28,
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            final current = int.tryParse(_headCountController.text) ?? 0;
                            if (current > 0) {
                              setState(() => _headCountController.text = (current - 1).toString());
                            }
                          },
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _headCountController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: CmsTheme.accent),
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton.filledTonal(
                          iconSize: 28,
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final current = int.tryParse(_headCountController.text) ?? 0;
                            setState(() => _headCountController.text = (current + 1).toString());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mobile-Friendly Offering Input
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CmsTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CmsTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Meeting Offering / Collection Amount (₦)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _offeringController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: CmsTheme.success),
                      decoration: const InputDecoration(prefixText: '₦ ', prefixStyle: TextStyle(fontSize: 20, color: CmsTheme.success)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Meeting Notes
              TextField(
                controller: _notesController,
                style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Meeting Notes / Prayer Requests (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Mobile One-Tap Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: CmsButton(
                  label: 'Submit Meeting Report',
                  icon: Icons.send,
                  loading: _submitting,
                  onPressed: () async {
                    setState(() => _submitting = true);
                    try {
                      final meeting = SubGroupMeetingModel(
                        id: '',
                        subGroupId: _selectedGroupId,
                        branchId: widget.branchId,
                        meetingDate: DateTime.now(),
                        headCount: int.tryParse(_headCountController.text) ?? 0,
                        attendeeMemberIds: _attendeeIds.toList(),
                        offeringAmount: double.tryParse(_offeringController.text) ?? 0.0,
                        notes: _notesController.text.trim(),
                      );
                      await ref.read(subGroupRepositoryProvider).recordMeeting(meeting);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Meeting report submitted successfully!'), backgroundColor: CmsTheme.success),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error submitting report: $e'), backgroundColor: CmsTheme.danger),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
