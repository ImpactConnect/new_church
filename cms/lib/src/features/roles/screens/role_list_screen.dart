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
              if (canManage)
                CmsButton(
                  label: 'Assign Role',
                  icon: Icons.person_add_outlined,
                  compact: true,
                  onPressed: () => _showAssignDialog(context, ref, branchId),
                ),
              const SizedBox(width: 10),
              if (canManage)
                CmsButton(
                  label: 'Seed Roles',
                  icon: Icons.settings_outlined,
                  compact: true,
                  variant: CmsButtonVariant.secondary,
                  onPressed: () async {
                    await ref.read(roleRepositoryProvider).seedRoles(branchId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Roles seeded in Firestore'),
                          backgroundColor: CmsTheme.success,
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Demo Accounts Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CmsTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_outlined, color: CmsTheme.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Demo Staff Logins & Credentials',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CmsTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use the pre-configured credentials below to test different roles and permission levels:',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _loginChip('Lead Pastor', 'lead@churchmobile.com', 'password123'),
                    _loginChip('Secretary', 'secretary@churchmobile.com', 'password123'),
                    _loginChip('Finance Dept', 'finance@churchmobile.com', 'password123'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Role catalog cards
          rolesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (roles) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: roles.map((r) => _RoleCatalogCard(role: r)).toList(),
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
                  icon: Icons.admin_panel_settings_outlined,
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: CmsTheme.accent.withValues(alpha: 0.15),
                          child: Text(
                            m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : '?',
                            style: const TextStyle(color: CmsTheme.accent, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(
                          m.fullName,
                          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: CmsTheme.textPrimary),
                        ),
                        subtitle: Text(
                          m.phone,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (role != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: CmsTheme.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  role.displayName,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.accent),
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

  Widget _loginChip(String roleName, String email, String password) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CmsTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CmsTheme.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              roleName,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: CmsTheme.accent),
            ),
          ),
          const SizedBox(width: 8),
          SelectableText(
            '$email ($password)',
            style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12, color: CmsTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref, String branchId) {
    showDialog(
      context: context,
      builder: (_) => _RoleAssignDialog(branchId: branchId, ref: ref),
    );
  }
}

class _RoleCatalogCard extends StatelessWidget {
  const _RoleCatalogCard({required this.role});
  final RoleModel role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: CmsTheme.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                role.displayName,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${role.permissions.length} permissions',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: role.permissions.take(5).map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: CmsTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(p, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textSecondary)),
            )).toList()
              ..addAll(role.permissions.length > 5 ? [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CmsTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('+${role.permissions.length - 5} more', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: CmsTheme.textMuted)),
                ),
              ] : []),
          ),
        ],
      ),
    );
  }
}

class _RoleAssignDialog extends StatefulWidget {
  const _RoleAssignDialog({required this.branchId, required this.ref});
  final String branchId;
  final WidgetRef ref;

  @override
  State<_RoleAssignDialog> createState() => _RoleAssignDialogState();
}

class _RoleAssignDialogState extends State<_RoleAssignDialog> {
  String? _selectedMemberId;
  String? _selectedRoleId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final membersAsync = widget.ref.watch(_allMembersProvider(widget.branchId));
    final rolesAsync = widget.ref.watch(_rolesProvider(widget.branchId));

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
                    await widget.ref.read(roleRepositoryProvider).assignRole(
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

