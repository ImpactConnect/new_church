import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/departments/models/department_model.dart';
import 'package:cms/src/features/members/models/member_model.dart';

// ─────────────────────────── Providers ─────────────────────────────────────

final _deptMembersProvider =
    StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) =>
      ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

// ─────────────────────────── Screen ────────────────────────────────────────

class DepartmentDetailScreen extends ConsumerStatefulWidget {
  const DepartmentDetailScreen({
    super.key,
    required this.dept,
    required this.branchId,
  });

  final DepartmentModel dept;
  final String branchId;

  @override
  ConsumerState<DepartmentDetailScreen> createState() =>
      _DepartmentDetailScreenState();
}

class _DepartmentDetailScreenState
    extends ConsumerState<DepartmentDetailScreen> {
  late DepartmentModel _dept;

  @override
  void initState() {
    super.initState();
    _dept = widget.dept;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final canManage = (user?.can(AppPermission.manageDepartments) ?? false) &&
        user?.roleId != AppRole.leadPastor;
    final allMembersAsync = ref.watch(_deptMembersProvider(widget.branchId));


    return Scaffold(
      backgroundColor: CmsTheme.bg,
      appBar: AppBar(
        backgroundColor: CmsTheme.sidebar,
        foregroundColor: CmsTheme.textPrimary,
        elevation: 0,
        title: Text(
          _dept.name,
          style: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: CmsButton(
                label: 'Edit Department',
                icon: Icons.edit_outlined,
                compact: true,
                onPressed: () => _showEditDialog(context, allMembersAsync.valueOrNull ?? []),
              ),
            ),
        ],
      ),
      body: allMembersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: CmsTheme.danger))),
        data: (allMembers) {
          final deptMembers = allMembers
              .where((m) => _dept.memberIds.contains(m.id))
              .toList()
            ..sort((a, b) => a.lastName.compareTo(b.lastName));
          final leader = _dept.headMemberId != null
              ? allMembers
                  .where((m) => m.id == _dept.headMemberId)
                  .firstOrNull
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dept info card ──────────────────────────────────────
                CmsCard(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: CmsTheme.brandGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.groups_outlined,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_dept.name,
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: CmsTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _InfoChip(
                                    icon: Icons.category_outlined,
                                    label: _dept.departmentType),
                                const SizedBox(width: 10),
                                _InfoChip(
                                    icon: Icons.people_outline,
                                    label:
                                        '${_dept.memberIds.length} member${_dept.memberIds.length == 1 ? '' : 's'}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Leader ──────────────────────────────────────────────
                CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Department Leader',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CmsTheme.textSecondary)),
                      const SizedBox(height: 12),
                      if (leader != null)
                        _MemberTile(
                          member: leader,
                          trailing: const _RoleBadge('Leader'),
                          showRemove: false,
                          onRemove: null,
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.person_off_outlined,
                                size: 18, color: CmsTheme.textMuted),
                            const SizedBox(width: 8),
                            const Text('No leader assigned',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: CmsTheme.textMuted)),
                            if (canManage) ...[
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _showEditDialog(context, allMembers),
                                icon: const Icon(Icons.add,
                                    size: 14, color: CmsTheme.accent),
                                label: const Text('Assign',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: CmsTheme.accent)),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Members ─────────────────────────────────────────────
                CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Members (${deptMembers.length})',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CmsTheme.textSecondary),
                          ),
                          if (canManage)
                            TextButton.icon(
                              onPressed: () => _showAddMemberSheet(
                                  context, allMembers, deptMembers),
                              icon: const Icon(Icons.person_add_outlined,
                                  size: 14, color: CmsTheme.accent),
                              label: const Text('Add Member',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: CmsTheme.accent)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (deptMembers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text('No members in this department yet.',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: CmsTheme.textMuted)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: deptMembers.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: CmsTheme.border),
                          itemBuilder: (_, i) {
                            final m = deptMembers[i];
                            final isLeader = m.id == _dept.headMemberId;
                            return _MemberTile(
                              member: m,
                              trailing: isLeader
                                  ? const _RoleBadge('Leader')
                                  : null,
                              showRemove: canManage,
                              onRemove: canManage
                                  ? () => _removeMember(m.id)
                                  : null,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────── Actions ─────────────────────────────────────

  Future<void> _removeMember(String memberId) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Remove Member',
      message: 'Remove this member from the department?',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (!ok || !mounted) return;
    await ref
        .read(departmentRepositoryProvider)
        .removeMemberFromDepartment(widget.branchId, _dept.id, memberId);
    setState(() {
      _dept = _dept.copyWith(
          memberIds: List.from(_dept.memberIds)..remove(memberId));
    });
  }

  void _showAddMemberSheet(BuildContext context, List<MemberModel> allMembers,
      List<MemberModel> currentMembers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CmsTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddMemberSheet(
        allMembers: allMembers,
        currentMemberIds: _dept.memberIds,
        onAdd: (member) async {
          await ref
              .read(departmentRepositoryProvider)
              .addMemberToDepartment(widget.branchId, _dept.id, member.id);
          setState(() {
            _dept = _dept.copyWith(
                memberIds: List.from(_dept.memberIds)..add(member.id));
          });
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, List<MemberModel> allMembers) {
    showDialog(
      context: context,
      builder: (_) => _EditDepartmentDialog(
        dept: _dept,
        branchId: widget.branchId,
        allMembers: allMembers,
        ref: ref,
        onSaved: (updated) => setState(() => _dept = updated),
      ),
    );
  }
}

// ─────────────────────────── Sub-widgets ────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CmsTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: CmsTheme.accent),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CmsTheme.accent)),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CmsTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border:
            Border.all(color: CmsTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CmsTheme.warning)),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.showRemove,
    required this.onRemove,
    this.trailing,
  });
  final MemberModel member;
  final bool showRemove;
  final VoidCallback? onRemove;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _MemberAvatar(member: member, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CmsTheme.textPrimary)),
                Text(member.phone,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: CmsTheme.textMuted)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (showRemove) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  size: 18, color: CmsTheme.danger),
              onPressed: onRemove,
              tooltip: 'Remove from department',
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, this.radius = 16});
  final MemberModel member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (member.profileImageUrl != null &&
        member.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(member.profileImageUrl!),
        onBackgroundImageError: (_, __) {},
        backgroundColor: CmsTheme.accent.withValues(alpha: 0.15),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: CmsTheme.accent.withValues(alpha: 0.15),
      child: Text(
        member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : '?',
        style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w600,
            color: CmsTheme.accent),
      ),
    );
  }
}

// ─────────────────────────── Add Member Sheet ────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({
    required this.allMembers,
    required this.currentMemberIds,
    required this.onAdd,
  });
  final List<MemberModel> allMembers;
  final List<String> currentMemberIds;
  final void Function(MemberModel) onAdd;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.allMembers
        .where((m) =>
            !widget.currentMemberIds.contains(m.id) &&
            m.fullName.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.lastName.compareTo(b.lastName));

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Member to Department',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CmsTheme.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(
                  fontFamily: 'Inter', color: CmsTheme.textPrimary),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search member by name…',
                hintStyle:
                    const TextStyle(color: CmsTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: CmsTheme.textMuted),
                filled: true,
                fillColor: CmsTheme.bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: CmsTheme.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: CmsTheme.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: CmsTheme.accent, width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: candidates.isEmpty
                  ? const Center(
                      child: Text('No members found.',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: CmsTheme.textMuted)))
                  : ListView.builder(
                      itemCount: candidates.length,
                      itemBuilder: (_, i) {
                        final m = candidates[i];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 0),
                          leading: _MemberAvatar(member: m, radius: 18),
                          title: Text(m.fullName,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: CmsTheme.textPrimary)),
                          subtitle: Text(m.phone,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: CmsTheme.textMuted)),
                          trailing: const Icon(Icons.add_circle_outline,
                              color: CmsTheme.accent, size: 20),
                          onTap: () => widget.onAdd(m),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Edit Dialog ────────────────────────────────────

class _EditDepartmentDialog extends StatefulWidget {
  const _EditDepartmentDialog({
    required this.dept,
    required this.branchId,
    required this.allMembers,
    required this.ref,
    required this.onSaved,
  });
  final DepartmentModel dept;
  final String branchId;
  final List<MemberModel> allMembers;
  final WidgetRef ref;
  final void Function(DepartmentModel) onSaved;

  @override
  State<_EditDepartmentDialog> createState() => _EditDepartmentDialogState();
}

class _EditDepartmentDialogState extends State<_EditDepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late String _type;
  String? _headMemberId;
  String? _headMemberName;
  String _leaderSearch = '';
  bool _showLeaderDropdown = false;
  bool _saving = false;

  static const _types = [
    'Choir', 'Ushering', 'Welfare', 'Youth', 'Children',
    'Prayer', 'Media', 'Protocol', 'General'
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.dept.name);
    _type = widget.dept.departmentType;
    _headMemberId = widget.dept.headMemberId;
    _headMemberName = widget.dept.headMemberName ??
        widget.allMembers
            .where((m) => m.id == widget.dept.headMemberId)
            .firstOrNull
            ?.fullName;
    _leaderSearch = _headMemberName ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderCandidates = _leaderSearch.isNotEmpty
        ? widget.allMembers
            .where((m) =>
                m.fullName
                    .toLowerCase()
                    .contains(_leaderSearch.toLowerCase()) &&
                m.id != _headMemberId)
            .take(6)
            .toList()
        : <MemberModel>[];

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CmsTheme.border)),
      title: const Text('Edit Department',
          style: TextStyle(
              fontFamily: 'Inter',
              color: CmsTheme.textPrimary,
              fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Name',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(
                      color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text('Type',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor: CmsTheme.surfaceElevated,
                  style: const TextStyle(
                      color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(),
                  items: _types
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),
                const Text('Department Leader',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                // Selected leader chip
                if (_headMemberId != null && !_showLeaderDropdown) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: CmsTheme.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: CmsTheme.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: CmsTheme.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_headMemberName ?? '',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: CmsTheme.textPrimary)),
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _headMemberId = null;
                            _headMemberName = null;
                            _leaderSearch = '';
                            _showLeaderDropdown = true;
                          }),
                          child: const Icon(Icons.close,
                              size: 16, color: CmsTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  TextField(
                    autofocus: false,
                    style: const TextStyle(
                        color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                    decoration: InputDecoration(
                      hintText: 'Search and select leader…',
                      hintStyle: const TextStyle(
                          color: CmsTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: CmsTheme.textMuted),
                    ),
                    onChanged: (v) => setState(() {
                      _leaderSearch = v;
                      _showLeaderDropdown = true;
                    }),
                    onTap: () =>
                        setState(() => _showLeaderDropdown = true),
                  ),
                  if (_showLeaderDropdown && leaderCandidates.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: CmsTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CmsTheme.border),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: leaderCandidates.length,
                        itemBuilder: (_, i) {
                          final m = leaderCandidates[i];
                          return ListTile(
                            dense: true,
                            leading: _MemberAvatar(member: m, radius: 14),
                            title: Text(m.fullName,
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: CmsTheme.textPrimary)),
                            onTap: () => setState(() {
                              _headMemberId = m.id;
                              _headMemberName = m.fullName;
                              _showLeaderDropdown = false;
                            }),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: CmsTheme.textSecondary)),
        ),
        CmsButton(
          label: 'Save',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final updated = widget.dept.copyWith(
                name: _nameCtrl.text.trim(),
                departmentType: _type,
                headMemberId: _headMemberId,
                headMemberName: _headMemberName,
              );
              await widget.ref
                  .read(departmentRepositoryProvider)
                  .saveDepartment(widget.branchId, updated);
              widget.onSaved(updated);
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: CmsTheme.danger),
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
