import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/sub_groups/models/sub_group_model.dart';
import 'package:cms/src/features/sub_groups/models/sub_group_meeting_model.dart';
import 'package:cms/src/features/departments/widgets/hod_cell_portal_widget.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/roles/screens/role_list_screen.dart';

final _subGroupMembersProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

final _subGroupMeetingsProvider = StreamProvider.autoDispose.family<List<SubGroupMeetingModel>, ({String branchId, String groupId})>(
  (ref, arg) => ref.watch(subGroupRepositoryProvider).watchMeetingsForGroup(arg.branchId, arg.groupId),
);

class SubGroupDetailScreen extends ConsumerStatefulWidget {
  const SubGroupDetailScreen({
    super.key,
    required this.group,
    required this.branchId,
  });

  final SubGroupModel group;
  final String branchId;

  @override
  ConsumerState<SubGroupDetailScreen> createState() => _SubGroupDetailScreenState();
}

class _SubGroupDetailScreenState extends ConsumerState<SubGroupDetailScreen> {
  late SubGroupModel _group;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final isLeadPastor = user?.roleId == AppRole.leadPastor;
    final isSecretaryOrAdmin = (user?.roleId == AppRole.secretary ||
        user?.roleId == 'admin' ||
        (user?.can(AppPermission.manageSubGroups) ?? false)) && !isLeadPastor;
    final canProvisionCredentials = isLeadPastor ||
        (user?.can(AppPermission.manageRoles) ?? false);

    final membersAsync = ref.watch(_subGroupMembersProvider(widget.branchId));
    final meetingsAsync = ref.watch(
      _subGroupMeetingsProvider((branchId: widget.branchId, groupId: _group.id)),
    );

    return Scaffold(
      backgroundColor: CmsTheme.bg,
      appBar: AppBar(
        backgroundColor: CmsTheme.sidebar,
        foregroundColor: CmsTheme.textPrimary,
        elevation: 0,
        title: Text(
          _group.name,
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          if (isSecretaryOrAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: CmsButton(
                label: 'Edit Group',
                icon: Icons.edit_outlined,
                compact: true,
                onPressed: () => _showEditDialog(context, membersAsync.valueOrNull ?? []),
              ),
            ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading members: $e', style: const TextStyle(color: CmsTheme.danger))),
        data: (allMembers) {
          final groupMembers = allMembers.where((m) => _group.memberIds.contains(m.id)).toList()
            ..sort((a, b) => a.lastName.compareTo(b.lastName));
          final officer = _group.recordingOfficerMemberId.isNotEmpty
              ? allMembers.where((m) => m.id == _group.recordingOfficerMemberId).firstOrNull
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Group Info Card ──────────────────────────────────────────
                CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: CmsTheme.brandGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_group.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _Chip(icon: Icons.category_outlined, label: _group.typeDisplayName),
                                    const SizedBox(width: 10),
                                    _Chip(icon: Icons.people_outline, label: '${_group.memberIds.length} members assigned'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: CmsTheme.border, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 16, color: CmsTheme.accent),
                                const SizedBox(width: 8),
                                Text('${_group.meetingDay} at ${_group.meetingTime}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: CmsTheme.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _group.locationAddress.isNotEmpty ? _group.locationAddress : 'Location TBD',
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Officer / Leader Details Card ───────────────────────────
                CmsCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: CmsTheme.surfaceElevated,
                        child: Icon(Icons.badge_outlined, color: CmsTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Designated Officer / Cell Leader', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              _group.officerName ?? officer?.fullName ?? 'Not Assigned',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      if (canProvisionCredentials)
                        CmsButton(
                          label: 'Provision Key',
                          icon: Icons.vpn_key_outlined,
                          compact: true,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => ProvisionStaffDialog(branchId: widget.branchId),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Members Card ─────────────────────────────────────────────
                CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assigned Members (${groupMembers.length})',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                          ),
                          if (isSecretaryOrAdmin)
                            TextButton.icon(
                              onPressed: () => _showAddMemberSheet(context, allMembers),
                              icon: const Icon(Icons.person_add_outlined, size: 14, color: CmsTheme.accent),
                              label: const Text('Add Member', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.accent)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (groupMembers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text('No members assigned to this group yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: groupMembers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: CmsTheme.border),
                          itemBuilder: (_, i) {
                            final m = groupMembers[i];
                            final isOfficer = m.id == _group.recordingOfficerMemberId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: CmsTheme.accent.withValues(alpha: 0.15),
                                    child: Text(
                                      m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CmsTheme.accent),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.fullName, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary)),
                                        Text(m.phone.isNotEmpty ? m.phone : (m.email ?? 'No contact'), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                  if (isOfficer)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: CmsTheme.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                                      child: const Text('Cell Officer', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: CmsTheme.warning)),
                                    ),
                                  if (isSecretaryOrAdmin) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: CmsTheme.danger),
                                      onPressed: () => _removeMember(m.id),
                                      tooltip: 'Remove from group',
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Meeting Reports Ledger Card ─────────────────────────────
                CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Meeting & Attendance Ledger', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('Meeting reports logged by cell officer/subgroup head', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
                      const SizedBox(height: 16),
                      meetingsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error loading meetings: $err', style: const TextStyle(color: CmsTheme.danger)),
                        data: (meetings) {
                          if (meetings.isEmpty) {
                            return const CmsEmptyState(
                              icon: Icons.event_note_outlined,
                              title: 'No meeting reports submitted',
                              subtitle: 'Meeting reports recorded by the officer will appear here.',
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: meetings.length,
                            separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 1),
                            itemBuilder: (context, i) {
                              final m = meetings[i];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: CmsTheme.surfaceElevated,
                                  child: Icon(Icons.event, color: CmsTheme.accent, size: 18),
                                ),
                                title: Text(
                                  'Date: ${DateFormat('EEE, MMM d, yyyy').format(m.meetingDate)}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                                ),
                                subtitle: Text(
                                  'Attendance: ${m.headCount} head count | ${m.attendeeMemberIds.length} named check-ins\nNotes: ${m.notes.isNotEmpty ? m.notes : "None"}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₦${m.offeringAmount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: CmsTheme.success)),
                                    const Text('Offering', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textMuted)),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Sub-Group Financial Income Portal ────────────────────────
                HodCellPortalWidget(
                  branchId: widget.branchId,
                  entityId: _group.id,
                  entityName: _group.name,
                  entityType: 'subGroup',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeMember(String memberId) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Remove Member',
      message: 'Remove this member from the sub-group?',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (!ok || !mounted) return;
    final updatedIds = List<String>.from(_group.memberIds)..remove(memberId);
    await ref.read(subGroupRepositoryProvider).assignMembersToGroup(widget.branchId, _group.id, updatedIds);
    setState(() => _group = _group.copyWith(memberIds: updatedIds));
  }

  void _showAddMemberSheet(BuildContext context, List<MemberModel> allMembers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CmsTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddMemberModal(
        allMembers: allMembers,
        currentMemberIds: _group.memberIds,
        onAdd: (member) async {
          final updatedIds = List<String>.from(_group.memberIds)..add(member.id);
          await ref.read(subGroupRepositoryProvider).assignMembersToGroup(widget.branchId, _group.id, updatedIds);
          setState(() => _group = _group.copyWith(memberIds: updatedIds));
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, List<MemberModel> allMembers) {
    // Re-use edit sub-group logic
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: CmsTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: CmsTheme.accent),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: CmsTheme.accent)),
        ],
      ),
    );
  }
}

class _AddMemberModal extends StatefulWidget {
  const _AddMemberModal({
    required this.allMembers,
    required this.currentMemberIds,
    required this.onAdd,
  });

  final List<MemberModel> allMembers;
  final List<String> currentMemberIds;
  final void Function(MemberModel) onAdd;

  @override
  State<_AddMemberModal> createState() => _AddMemberModalState();
}

class _AddMemberModalState extends State<_AddMemberModal> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final candidates = widget.allMembers.where((m) {
      final isNotMember = !widget.currentMemberIds.contains(m.id);
      if (_query.trim().isEmpty) return isNotMember;
      final q = _query.toLowerCase();
      return isNotMember && (m.fullName.toLowerCase().contains(q) || m.phone.toLowerCase().contains(q) || (m.email ?? '').toLowerCase().contains(q));
    }).toList()..sort((a, b) => a.lastName.compareTo(b.lastName));

    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxHeight: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Member to ${_query.isNotEmpty ? "Group" : "Group"}', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: CmsTheme.textPrimary)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontSize: 13),
            decoration: const InputDecoration(hintText: 'Search member name or phone…', prefixIcon: Icon(Icons.search, size: 18, color: CmsTheme.textMuted)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: candidates.isEmpty
                ? const Center(child: Text('No members available', style: TextStyle(color: CmsTheme.textMuted)))
                : ListView.separated(
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 1),
                    itemBuilder: (context, i) {
                      final m = candidates[i];
                      return ListTile(
                        title: Text(m.fullName, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                        subtitle: Text(m.phone.isNotEmpty ? m.phone : (m.email ?? ''), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
                        trailing: OutlinedButton(
                          onPressed: () => widget.onAdd(m),
                          child: const Text('Add', style: TextStyle(fontSize: 11, color: CmsTheme.accent)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
