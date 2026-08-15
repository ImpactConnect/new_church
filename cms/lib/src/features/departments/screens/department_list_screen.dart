import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/departments/models/department_model.dart';
import 'package:cms/src/features/departments/screens/department_detail_screen.dart';
import 'package:cms/src/features/members/models/member_model.dart';

final _departmentsProvider =
    StreamProvider.autoDispose.family<List<DepartmentModel>, String>(
  (ref, branchId) =>
      ref.watch(departmentRepositoryProvider).watchDepartments(branchId),
);

final _allMembersForDeptProvider =
    StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) =>
      ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

class DepartmentListScreen extends ConsumerWidget {
  const DepartmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final deptsAsync = ref.watch(_departmentsProvider(branchId));
    final allMembersAsync = ref.watch(_allMembersForDeptProvider(branchId));
    final canManage = user?.can(AppPermission.manageDepartments) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Departments & Units',
            subtitle: 'Ministry groups and their members',
            actions: [
              if (canManage)
                CmsButton(
                  label: 'New Department',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showNewForm(
                    context,
                    ref,
                    branchId,
                    allMembersAsync.valueOrNull ?? [],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: deptsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: CmsTheme.danger))),
              data: (depts) {
                if (depts.isEmpty) {
                  return CmsEmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No departments yet',
                    subtitle: canManage
                        ? 'Create your first ministry department.'
                        : 'No departments have been created yet.',
                    action: canManage
                        ? CmsButton(
                            label: 'New Department',
                            icon: Icons.add,
                            onPressed: () => _showNewForm(
                              context,
                              ref,
                              branchId,
                              allMembersAsync.valueOrNull ?? [],
                            ),
                          )
                        : null,
                  );
                }
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: depts.length,
                  itemBuilder: (_, i) => _DepartmentCard(
                    dept: depts[i],
                    canManage: canManage,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DepartmentDetailScreen(
                          dept: depts[i],
                          branchId: branchId,
                        ),
                      ),
                    ),
                    onEdit: () => _showEditForm(
                      context,
                      ref,
                      branchId,
                      depts[i],
                      allMembersAsync.valueOrNull ?? [],
                    ),
                    onDelete: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: 'Delete Department',
                        message:
                            'Delete "${depts[i].name}"? This cannot be undone.',
                        confirmLabel: 'Delete',
                        danger: true,
                      );
                      if (ok) {
                        await ref
                            .read(departmentRepositoryProvider)
                            .deleteDepartment(branchId, depts[i].id);
                      }
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

  void _showNewForm(BuildContext ctx, WidgetRef ref, String branchId,
      List<MemberModel> allMembers) {
    showDialog(
      context: ctx,
      builder: (_) => _DepartmentFormDialog(
        branchId: branchId,
        dept: null,
        ref: ref,
        allMembers: allMembers,
      ),
    );
  }

  void _showEditForm(BuildContext ctx, WidgetRef ref, String branchId,
      DepartmentModel dept, List<MemberModel> allMembers) {
    showDialog(
      context: ctx,
      builder: (_) => _DepartmentFormDialog(
        branchId: branchId,
        dept: dept,
        ref: ref,
        allMembers: allMembers,
      ),
    );
  }
}

// ─────────────────────────── Card ───────────────────────────────────────────

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.dept,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });
  final DepartmentModel dept;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: CmsTheme.brandGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.groups_outlined,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CmsTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dept.departmentType,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: CmsTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    color: CmsTheme.surfaceElevated,
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: CmsTheme.textSecondary),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit',
                              style: TextStyle(
                                  color: CmsTheme.textPrimary,
                                  fontFamily: 'Inter'))),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(
                                  color: CmsTheme.danger,
                                  fontFamily: 'Inter'))),
                    ],
                  ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 14, color: CmsTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${dept.memberIds.length} member${dept.memberIds.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: CmsTheme.textSecondary),
                ),
                if (dept.headMemberName != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.person_outline,
                      size: 14, color: CmsTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dept.headMemberName!,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: CmsTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: 16, color: CmsTheme.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Form Dialog ────────────────────────────────────

class _DepartmentFormDialog extends StatefulWidget {
  const _DepartmentFormDialog({
    required this.branchId,
    required this.ref,
    required this.allMembers,
    this.dept,
  });
  final String branchId;
  final WidgetRef ref;
  final DepartmentModel? dept;
  final List<MemberModel> allMembers;

  @override
  State<_DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<_DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String _type = 'General';
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
    _nameCtrl = TextEditingController(text: widget.dept?.name ?? '');
    _type = widget.dept?.departmentType ?? 'General';
    _headMemberId = widget.dept?.headMemberId;
    _headMemberName = widget.dept?.headMemberName ??
        widget.allMembers
            .where((m) => m.id == widget.dept?.headMemberId)
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
    final leaderCandidates = _leaderSearch.isNotEmpty && _headMemberId == null
        ? widget.allMembers
            .where((m) => m.fullName
                .toLowerCase()
                .contains(_leaderSearch.toLowerCase()))
            .take(6)
            .toList()
        : <MemberModel>[];

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CmsTheme.border)),
      title: Text(
        widget.dept == null ? 'New Department' : 'Edit Department',
        style: const TextStyle(
            fontFamily: 'Inter',
            color: CmsTheme.textPrimary,
            fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                const Text('Department Name',
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                // Type
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
                // Leader
                const Text('Department Leader',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                if (_headMemberId != null) ...[
                  // Selected chip
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
                        const Icon(Icons.person,
                            size: 16, color: CmsTheme.accent),
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
                          }),
                          child: const Icon(Icons.close,
                              size: 16, color: CmsTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  TextField(
                    style: const TextStyle(
                        color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                    decoration: const InputDecoration(
                      hintText: 'Search and select leader…',
                      hintStyle: TextStyle(
                          color: CmsTheme.textMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.search,
                          size: 16, color: CmsTheme.textMuted),
                    ),
                    onChanged: (v) => setState(() {
                      _leaderSearch = v;
                      _showLeaderDropdown = v.isNotEmpty;
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
            final nav = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            try {
              final dept = DepartmentModel(
                id: widget.dept?.id ?? '',
                name: _nameCtrl.text.trim(),
                departmentType: _type,
                headMemberId: _headMemberId,
                headMemberName: _headMemberName,
                memberIds: widget.dept?.memberIds ?? [],
              );
              await widget.ref
                  .read(departmentRepositoryProvider)
                  .saveDepartment(widget.branchId, dept);
              nav.pop();
            } catch (e) {
              messenger.showSnackBar(SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: CmsTheme.danger));
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
        ),
      ],
    );
  }
}
