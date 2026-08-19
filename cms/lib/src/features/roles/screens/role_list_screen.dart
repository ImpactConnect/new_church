import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/roles/models/role_model.dart';
import 'package:cms/src/features/members/models/member_model.dart';

final _rolesProvider = StreamProvider.autoDispose.family<List<RoleModel>, String>(
  (ref, branchId) => ref.watch(roleRepositoryProvider).watchRoles(branchId),
);

final _membersWithRolesProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId).map(
    (members) => members.where((m) => m.roleId != null && m.roleId!.isNotEmpty).toList(),
  ),
);

final _allMembersProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

class RoleListScreen extends ConsumerWidget {
  const RoleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final rolesAsync = ref.watch(_rolesProvider(branchId));
    final assignedAsync = ref.watch(_membersWithRolesProvider(branchId));
    final canManage = user?.can(AppPermission.manageRoles) ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Roles & Permissions',
            subtitle: 'Assign and review role assignments across the branch',
            actions: [
              if (canManage) ...[
                CmsButton(
                  label: 'Create Custom Role',
                  icon: Icons.add_moderator_outlined,
                  compact: true,
                  onPressed: () => _showCreateRoleDialog(context, ref, branchId),
                ),
                const SizedBox(width: 10),
                CmsButton(
                  label: 'Provision Staff Account',
                  icon: Icons.person_add_alt_1_outlined,
                  compact: true,
                  variant: CmsButtonVariant.secondary,
                  onPressed: () => _showProvisionStaffDialog(context, ref, branchId),
                ),
                const SizedBox(width: 10),
                CmsButton(
                  label: 'Assign Role',
                  icon: Icons.badge_outlined,
                  compact: true,
                  variant: CmsButtonVariant.secondary,
                  onPressed: () => _showAssignDialog(context, ref, branchId),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          // Role catalog cards
          rolesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (roles) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: roles.map((r) => _RoleCatalogCard(role: r, branchId: branchId, canManage: canManage, ref: ref)).toList(),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Assigned Officers',
            style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          assignedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger)),
            ),
            data: (members) {
              if (members.isEmpty) {
                return const CmsEmptyState(
                  icon: Icons.shield_outlined,
                  title: 'No role assignments yet',
                  subtitle: 'Use "Assign Role" to give members access to the system.',
                );
              }
              return rolesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (roles) {
                  final roleMap = {for (final r in roles) r.id: r};
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: CmsTheme.border),
                    itemBuilder: (_, i) {
                      final m = members[i];
                      final role = m.roleId != null ? roleMap[m.roleId] : null;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: CmsTheme.surfaceElevated,
                          child: Text(
                            m.firstName.isNotEmpty ? m.firstName[0] : '?',
                            style: const TextStyle(color: CmsTheme.accent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(m.fullName, style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text(m.email ?? m.phone, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: CmsTheme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                role?.displayName ?? m.roleId ?? 'Role',
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: CmsTheme.accent),
                              ),
                            ),
                            if (canManage) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.person_remove_outlined, size: 18, color: CmsTheme.danger),
                                tooltip: 'Remove role',
                                onPressed: () async {
                                  final ok = await showConfirmDialog(
                                    context,
                                    title: 'Remove Role',
                                    message: 'Remove ${m.fullName}\'s role assignment?',
                                    confirmLabel: 'Remove',
                                    danger: true,
                                  );
                                  if (ok) {
                                    await ref.read(roleRepositoryProvider).assignRole(
                                      branchId, m.id, '',
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref, String branchId) {
    showDialog(
      context: context,
      builder: (_) => _RoleAssignDialog(branchId: branchId),
    );
  }

  void _showCreateRoleDialog(BuildContext context, WidgetRef ref, String branchId, {RoleModel? existingRole}) {
    showDialog(
      context: context,
      builder: (_) => _CreateRoleDialog(branchId: branchId, existingRole: existingRole),
    );
  }

  void _showProvisionStaffDialog(BuildContext context, WidgetRef ref, String branchId) {
    showDialog(
      context: context,
      builder: (_) => ProvisionStaffDialog(branchId: branchId),
    );
  }
}

class _RoleCatalogCard extends StatelessWidget {
  const _RoleCatalogCard({
    required this.role,
    required this.branchId,
    required this.canManage,
    required this.ref,
  });

  final RoleModel role;
  final String branchId;
  final bool canManage;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isCustom = role.isCustom;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCustom ? CmsTheme.accent.withValues(alpha: 0.5) : CmsTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isCustom
                      ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)])
                      : CmsTheme.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCustom ? Icons.admin_panel_settings : Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.displayName,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCustom ? 'Custom Role' : 'System Role',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isCustom ? CmsTheme.accent : CmsTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage && isCustom) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: CmsTheme.textSecondary),
                  tooltip: 'Edit permissions',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => _CreateRoleDialog(branchId: branchId, existingRole: role),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: CmsTheme.danger),
                  tooltip: 'Delete custom role',
                  onPressed: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Delete Role',
                      message: 'Delete custom role "${role.displayName}"? Members with this role will lose their permissions.',
                      confirmLabel: 'Delete',
                      danger: true,
                    );
                    if (ok) {
                      await ref.read(roleRepositoryProvider).deleteCustomRole(branchId, role.id);
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${role.permissions.length} permissions enabled',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: role.permissions.take(4).map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: CmsTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(p, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textSecondary)),
            )).toList()
              ..addAll(role.permissions.length > 4 ? [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CmsTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('+${role.permissions.length - 4} more', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textMuted)),
                ),
              ] : []),
          ),
        ],
      ),
    );
  }
}

class _RoleAssignDialog extends ConsumerStatefulWidget {
  const _RoleAssignDialog({required this.branchId});
  final String branchId;

  @override
  ConsumerState<_RoleAssignDialog> createState() => _RoleAssignDialogState();
}

class _RoleAssignDialogState extends ConsumerState<_RoleAssignDialog> {
  String? _selectedMemberId;
  String? _selectedRoleId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_allMembersProvider(widget.branchId));
    final rolesAsync = ref.watch(_rolesProvider(widget.branchId));

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: const Text('Assign Role', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Member', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
            const SizedBox(height: 6),
            membersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading members', style: TextStyle(color: CmsTheme.danger)),
              data: (members) => DropdownButtonFormField<String>(
                value: _selectedMemberId,
                dropdownColor: CmsTheme.surfaceElevated,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(hintText: 'Select member…'),
                items: members
                    .map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMemberId = v),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Role', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
            const SizedBox(height: 6),
            rolesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading roles', style: TextStyle(color: CmsTheme.danger)),
              data: (roles) => DropdownButtonFormField<String>(
                value: _selectedRoleId,
                dropdownColor: CmsTheme.surfaceElevated,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(hintText: 'Select role…'),
                items: roles
                    .map((r) => DropdownMenuItem(value: r.id, child: Text(r.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRoleId = v),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CmsTheme.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CmsTheme.warning.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Note: The member must sign out and sign back in for the role to take effect in their session.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.warning),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary)),
        ),
        CmsButton(
          label: 'Assign',
          compact: true,
          loading: _saving,
          onPressed: _selectedMemberId != null && _selectedRoleId != null
              ? () async {
                  setState(() => _saving = true);
                  try {
                    await ref.read(roleRepositoryProvider).assignRole(
                      widget.branchId, _selectedMemberId!, _selectedRoleId!,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger),
                      );
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

class _CreateRoleDialog extends ConsumerStatefulWidget {
  const _CreateRoleDialog({
    required this.branchId,
    this.existingRole,
    super.key,
  });

  final String branchId;
  final RoleModel? existingRole;

  @override
  ConsumerState<_CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends ConsumerState<_CreateRoleDialog> {
  late final TextEditingController _nameController;
  late final Set<String> _selectedPermissions;
  bool _saving = false;

  final Map<String, List<String>> _groupedPermissions = {
    'Members & Governance': [
      AppPermission.manageMembers,
      AppPermission.manageRoles,
      AppPermission.manageDepartments,
    ],
    'Sub-Group & Cell Operations': [
      AppPermission.manageSubGroups,
      AppPermission.recordSubGroupAttendance,
      AppPermission.recordSubGroupIncome,
      AppPermission.viewSubGroupReports,
    ],
    'Services & Attendance': [
      AppPermission.recordAttendance,
      AppPermission.manageEvents,
    ],
    'Comms & Announcements': [
      AppPermission.createAnnouncement,
      AppPermission.approveAnnouncement,
      AppPermission.logCorrespondence,
      AppPermission.sendNotifications,
    ],
    'Finance & Expenditure': [
      AppPermission.recordIncome,
      AppPermission.createBudgetRequest,
      AppPermission.approveBudget,
      AppPermission.createExpenditureRequest,
      AppPermission.approveExpenditure,
      AppPermission.recordDisbursement,
    ],
    'Assets & Inventory': [
      AppPermission.manageAssetPhysical,
      AppPermission.manageAssetFinancial,
    ],
    'Reports & Analytics': [
      AppPermission.viewFinancialReports,
      AppPermission.viewNonFinancialReports,
      AppPermission.viewBranchReports,
    ],
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingRole?.name ?? '');
    _selectedPermissions = Set<String>.from(widget.existingRole?.permissions ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRole != null;

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: Text(
        isEditing ? 'Edit Custom Role' : 'Create Custom Role',
        style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 600,
        height: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Role Title', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(
                  hintText: 'e.g. Media Director, Youth Pastor, Protocol Officer…',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Permissions', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                  Text(
                    '${_selectedPermissions.length} selected',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.accent, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._groupedPermissions.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.value.map((perm) {
                          final selected = _selectedPermissions.contains(perm);
                          return FilterChip(
                            selected: selected,
                            label: Text(perm, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: selected ? Colors.white : CmsTheme.textSecondary)),
                            selectedColor: CmsTheme.accent,
                            backgroundColor: CmsTheme.surfaceElevated,
                            side: BorderSide(color: selected ? CmsTheme.accent : CmsTheme.border),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedPermissions.add(perm);
                                } else {
                                  _selectedPermissions.remove(perm);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary)),
        ),
        CmsButton(
          label: isEditing ? 'Save Changes' : 'Create Role',
          compact: true,
          loading: _saving,
          onPressed: _nameController.text.trim().isNotEmpty && _selectedPermissions.isNotEmpty
              ? () async {
                  setState(() => _saving = true);
                  try {
                    final repo = ref.read(roleRepositoryProvider);
                    if (isEditing) {
                      await repo.updateCustomRole(
                        widget.branchId,
                        widget.existingRole!.id,
                        _nameController.text.trim(),
                        _selectedPermissions.toList(),
                      );
                    } else {
                      await repo.createCustomRole(
                        widget.branchId,
                        _nameController.text.trim(),
                        _selectedPermissions.toList(),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger),
                      );
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

class ProvisionStaffDialog extends ConsumerStatefulWidget {
  const ProvisionStaffDialog({required this.branchId, super.key});
  final String branchId;

  @override
  ConsumerState<ProvisionStaffDialog> createState() => _ProvisionStaffDialogState();
}

class _ProvisionStaffDialogState extends ConsumerState<ProvisionStaffDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedRoleId;
  String? _selectedMemberId;
  bool _saving = false;
  bool _obscurePassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    final suffix = List.generate(6, (i) => chars[(rand + i * 17) % chars.length]).join();
    final pwd = 'Pass#$suffix';
    setState(() {
      _passwordController.text = pwd;
      _obscurePassword = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(_rolesProvider(widget.branchId));
    final membersAsync = ref.watch(_allMembersProvider(widget.branchId));

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: const Row(
        children: [
          Icon(Icons.person_add_alt_1_outlined, color: CmsTheme.accent, size: 22),
          SizedBox(width: 10),
          Text('Provision Staff Account', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Existing Member (Optional)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.accent)),
              const SizedBox(height: 6),
              membersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (members) => DropdownButtonFormField<String>(
                  value: _selectedMemberId,
                  dropdownColor: CmsTheme.surfaceElevated,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Search or select existing member…',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('-- None (New Non-Member Staff) --', style: TextStyle(color: CmsTheme.textMuted)),
                    ),
                    ...members.map((m) {
                      final email = m.email ?? '';
                      final phone = m.phone;
                      final label = email.isNotEmpty ? email : (phone.isNotEmpty ? phone : 'No contact');
                      return DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.fullName} ($label)'),
                      );
                    }),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedMemberId = v;
                      if (v != null) {
                        final m = members.firstWhere((element) => element.id == v);
                        _nameController.text = m.fullName;
                        final email = m.email ?? '';
                        if (email.isNotEmpty) _emailController.text = email;
                        if (m.phone.isNotEmpty) _phoneController.text = m.phone;
                        if (m.roleId != null && m.roleId!.isNotEmpty) _selectedRoleId = m.roleId;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Full Name', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(hintText: 'e.g. Pastor John Doe'),
              ),
              const SizedBox(height: 14),
              const Text('Email Address', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(hintText: 'e.g. john.doe@church.org'),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Password', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                  InkWell(
                    onTap: _generatePassword,
                    child: const Text('⚡ Auto-Generate Password', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: CmsTheme.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: InputDecoration(
                  hintText: 'Enter or auto-generate password…',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18, color: CmsTheme.textMuted),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Role', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              rolesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading roles', style: TextStyle(color: CmsTheme.danger)),
                data: (roles) => DropdownButtonFormField<String>(
                  value: _selectedRoleId,
                  dropdownColor: CmsTheme.surfaceElevated,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'Assign role…'),
                  items: roles
                      .map((r) => DropdownMenuItem(value: r.id, child: Text(r.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRoleId = v),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary)),
        ),
        CmsButton(
          label: 'Provision Account',
          compact: true,
          loading: _saving,
          onPressed: _emailController.text.trim().isNotEmpty &&
                  _passwordController.text.trim().isNotEmpty &&
                  _selectedRoleId != null
              ? () async {
                  setState(() => _saving = true);
                  try {
                    await ref.read(roleRepositoryProvider).provisionStaffAccount(
                          branchId: widget.branchId,
                          name: _nameController.text.trim(),
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                          roleId: _selectedRoleId!,
                          phone: _phoneController.text.trim(),
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Account provisioned for ${_emailController.text.trim()} (Password: ${_passwordController.text})'),
                          backgroundColor: CmsTheme.success,
                          duration: const Duration(seconds: 8),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger),
                      );
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
