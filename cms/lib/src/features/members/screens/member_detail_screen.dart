import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/members/screens/member_form_screen.dart';
import 'package:cms/src/features/departments/models/department_model.dart';

final _departmentsForDetailProvider =
    StreamProvider.autoDispose.family<List<DepartmentModel>, String>(
  (ref, branchId) =>
      ref.watch(departmentRepositoryProvider).watchDepartments(branchId),
);

class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({
    super.key,
    required this.member,
  });

  final MemberModel member;

  @override
  ConsumerState<MemberDetailScreen> createState() =>
      _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  late MemberModel _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final canManage = (user?.can(AppPermission.manageMembers) ?? false) &&
        user?.roleId != AppRole.leadPastor;
    final deptsAsync = ref.watch(_departmentsForDetailProvider(branchId));

    return Scaffold(
      backgroundColor: CmsTheme.bg,
      appBar: AppBar(
        backgroundColor: CmsTheme.bg,
        foregroundColor: CmsTheme.textPrimary,
        elevation: 0,
        title: const Text(
          'Member Profile',
          style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16),
        ),
        actions: [
          if (canManage) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: CmsButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                variant: CmsButtonVariant.secondary,
                compact: true,
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            MemberFormScreen(member: _member)),
                  );
                  if (result == true && mounted) {
                    final updated = await ref
                        .read(memberRepositoryProvider)
                        .getMember(branchId, _member.id);
                    if (updated != null && mounted) {
                      setState(() => _member = updated);
                    }
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 28, left: 4, top: 8, bottom: 8),
              child: CmsButton(
                label: 'Delete',
                icon: Icons.delete_outline,
                variant: CmsButtonVariant.danger,
                compact: true,
                onPressed: () => _confirmDelete(context, branchId),
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Banner & Info ──────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [CmsTheme.accent, Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: CmsTheme.bg, width: 4),
                    ),
                    child: _buildAvatar(100),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: StatusBadge(_member.memberStatus),
                ),
              ],
            ),
            const SizedBox(height: 56), // space for avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _member.fullName,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: CmsTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _IconBadge(
                          icon: Icons.phone_outlined,
                          text: _member.phone),
                      if (_member.email != null)
                        _IconBadge(
                            icon: Icons.email_outlined,
                            text: _member.email!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Joined ${_formatDate(_member.joinDate)}',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CmsTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Detailed Information Grid ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSectionCard(
                        title: 'Personal Information',
                        icon: Icons.person_outline,
                        content: Column(
                          children: [
                            _InfoRow(
                                label: 'Gender',
                                value: _capitalize(_member.gender)),
                            _InfoRow(
                                label: 'Marital Status',
                                value: _capitalize(
                                    _member.maritalStatus ?? 'Unknown')),
                            _InfoRow(
                                label: 'Date of Birth',
                                value: _member.dob != null
                                    ? _formatDate(_member.dob!)
                                    : 'Not provided'),
                            _InfoRow(
                                label: 'Profession',
                                value: _member.profession ?? 'Not provided'),
                            _InfoRow(
                                label: 'Wedding Date',
                                value: _member.weddingDate != null
                                    ? _formatDate(_member.weddingDate!)
                                    : 'Not provided',
                                isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Contact Address',
                        icon: Icons.location_on_outlined,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _member.residentAddress ?? 'No address provided',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: _member.residentAddress != null
                                      ? CmsTheme.textPrimary
                                      : CmsTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildSectionCard(
                        title: 'Ministry & Departments',
                        icon: Icons.groups_outlined,
                        content: deptsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Error loading departments'),
                          data: (depts) {
                            final memberDepts = depts
                                .where((d) =>
                                    _member.departmentIds.contains(d.id))
                                .toList();
                            if (memberDepts.isEmpty) {
                              return const Text(
                                  'Not assigned to any department.',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: CmsTheme.textMuted));
                            }
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: memberDepts
                                  .map((d) => _DeptChip(name: d.name))
                                  .toList(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_member.relations.isNotEmpty)
                        _buildSectionCard(
                          title: 'Family & Relationships',
                          icon: Icons.family_restroom_outlined,
                          content: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _member.relations.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 24, color: CmsTheme.border),
                            itemBuilder: (_, i) {
                              final r = _member.relations[i];
                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        CmsTheme.surfaceElevated,
                                    child: const Icon(
                                        Icons.person_outline,
                                        size: 20,
                                        color: CmsTheme.textSecondary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.memberName,
                                            style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: CmsTheme.textPrimary)),
                                        Text(r.displayRelationship,
                                            style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                color: CmsTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: CmsTheme.success
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(r.displayRelationship,
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: CmsTheme.success)),
                                  ),
                                ],
                              );
                            },
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
    );
  }

  // ─────────────────────────── Widget Builders ─────────────────────────────

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(16),
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
                  color: CmsTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: CmsTheme.accent),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CmsTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildAvatar(double size) {
    final url = _member.profileImageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(size),
        ),
      );
    }
    return _initialsAvatar(size);
  }

  Widget _initialsAvatar(double size) {
    final initials =
        '${_member.firstName.isNotEmpty ? _member.firstName[0].toUpperCase() : ''}${_member.lastName.isNotEmpty ? _member.lastName[0].toUpperCase() : ''}';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: CmsTheme.brandGradient,
        borderRadius: BorderRadius.circular(size),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      ),
    );
  }

  // ─────────────────────────── Helpers ─────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, String branchId) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Member',
      message:
          'Permanently delete ${_member.fullName}? This cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok || !mounted) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(memberRepositoryProvider)
          .deleteMember(branchId, _member.id);
      if (mounted) nav.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: CmsTheme.danger));
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}';

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────── Sub-widgets ──────────────────────────────

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CmsTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CmsTheme.textSecondary),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CmsTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: CmsTheme.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: CmsTheme.textMuted)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CmsTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _DeptChip extends StatelessWidget {
  const _DeptChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: CmsTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined,
              size: 16, color: CmsTheme.accent),
          const SizedBox(width: 8),
          Text(name,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CmsTheme.accent)),
        ],
      ),
    );
  }
}
