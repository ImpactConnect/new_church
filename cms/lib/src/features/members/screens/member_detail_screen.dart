import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

// Member giving stream
final _memberGivingProvider = StreamProvider.autoDispose.family<List<dynamic>, ({String branchId, String memberName})>(
  (ref, args) {
    final db = ref.watch(firestoreProvider);
    return db
      .collection('branches').doc(args.branchId)
      .collection('giving')
      .where('memberId', isEqualTo: args.memberName)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
  },
);

class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({
    super.key,
    required this.member,
  });

  final MemberModel member;

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
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
    final isPastor = user?.roleId == AppRole.leadPastor || user?.roleId == AppRole.branchPastor;
    final deptsAsync = ref.watch(_departmentsForDetailProvider(branchId));
    final givingAsync = ref.watch(_memberGivingProvider((branchId: branchId, memberName: _member.fullName)));

    return Scaffold(
      backgroundColor: CmsTheme.bg,
      appBar: AppBar(
        backgroundColor: CmsTheme.sidebar,
        foregroundColor: CmsTheme.textPrimary,
        elevation: 0,
        title: Text(
          '${_member.fullName} Profile',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
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
                      builder: (_) => MemberFormScreen(member: _member),
                    ),
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
              padding: const EdgeInsets.only(right: 24, left: 4, top: 8, bottom: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Hero Banner Card ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: CmsTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CmsTheme.border),
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [CmsTheme.accent, Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                      ),
                      Positioned(
                        bottom: -36,
                        left: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: CmsTheme.surface, width: 4),
                          ),
                          child: _buildAvatar(88),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: StatusBadge(_member.memberStatus),
                      ),
                    ],
                  ),
                  const SizedBox(height: 44),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _member.fullName,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: CmsTheme.textPrimary,
                                    ),
                                  ),
                                  if (_member.memberCode?.isNotEmpty == true) ...[
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: CmsTheme.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        _member.memberCode!,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: CmsTheme.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 18,
                                runSpacing: 8,
                                children: [
                                  _metaItem(Icons.phone_outlined, _member.phone),
                                  if (_member.email?.isNotEmpty == true) _metaItem(Icons.email_outlined, _member.email!),
                                  if (_member.profession?.isNotEmpty == true) _metaItem(Icons.work_outline, _member.profession!),
                                  _metaItem(Icons.calendar_today_outlined, 'Joined ${DateFormat("dd MMM yyyy").format(_member.joinDate)}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 2. Single Comprehensive Profile Card for all Details ────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CmsTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CmsTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section A: Personal Info & Spiritual Milestones ──────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Personal & Contact
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('Personal & Contact Information', Icons.person_outline),
                            const SizedBox(height: 16),
                            _infoRow('Full Name', _member.fullName),
                            _infoRow('Phone Number', _member.phone),
                            _infoRow('Email Address', _member.email ?? 'Not provided'),
                            _infoRow('Gender', _capitalize(_member.gender)),
                            _infoRow('Marital Status', _capitalize(_member.maritalStatus ?? 'Unknown')),
                            _infoRow('Date of Birth', _member.dob != null ? DateFormat('dd MMMM yyyy').format(_member.dob!) : 'Not provided'),
                            _infoRow('Residential Address', _member.residentAddress ?? 'Not provided'),
                            _infoRow('Profession', _member.profession ?? 'Not provided', isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),

                      // Right: Spiritual & Milestones
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('Spiritual & Church Milestones', Icons.church_outlined),
                            const SizedBox(height: 16),
                            _infoRow('Membership Code', _member.memberCode ?? '—'),
                            _infoRow('Member Status', _capitalize(_member.memberStatus)),
                            _infoRow('Joined Church', DateFormat('dd MMMM yyyy').format(_member.joinDate)),
                            _infoRow(
                              'Water Baptism',
                              _member.waterBaptized == true
                                  ? 'Yes (${_member.waterBaptismDate != null ? DateFormat("dd/MM/yyyy").format(_member.waterBaptismDate!) : "Date N/A"})'
                                  : 'Not yet',
                            ),
                            _infoRow(
                              'Holy Spirit Baptism',
                              _member.holySpiritBaptized == true
                                  ? 'Yes (${_member.holySpiritBaptismDate != null ? DateFormat("dd/MM/yyyy").format(_member.holySpiritBaptismDate!) : "Date N/A"})'
                                  : 'Not yet',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: CmsTheme.border),
                  ),

                  // ── Section B: Placement & Emergency / Pastoral Care ──────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Departments & Cell Group
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('Assigned Departments & Cell Group Placement', Icons.groups_outlined),
                            const SizedBox(height: 16),
                            deptsAsync.when(
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const Text('Error loading departments'),
                              data: (depts) {
                                final memberDepts = depts.where((d) => _member.departmentIds.contains(d.id)).toList();
                                if (memberDepts.isEmpty) {
                                  return const Text('Not assigned to any department', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textMuted));
                                }
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: memberDepts.map((d) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: CmsTheme.accent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_outline, size: 14, color: CmsTheme.accent),
                                          const SizedBox(width: 6),
                                          Text(d.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.accent)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            if (_member.subGroupName?.isNotEmpty == true) ...[
                              const SizedBox(height: 16),
                              _infoRow('Cell Group / Fellowship', _member.subGroupName!, isLast: true),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),

                      // Right: Emergency Contact & Pastoral Care Notes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_member.emergencyContactName?.isNotEmpty == true) ...[
                              _sectionHeader('Emergency Contact Information', Icons.phone_in_talk_outlined),
                              const SizedBox(height: 16),
                              _infoRow('Contact Person', _member.emergencyContactName!),
                              _infoRow('Contact Phone', _member.emergencyContactPhone ?? '—'),
                              _infoRow('Relationship', _member.emergencyContactRelation ?? '—', isLast: true),
                              const SizedBox(height: 16),
                            ],
                            if (isPastor && _member.pastoralNotes?.isNotEmpty == true) ...[
                              _sectionHeader('Pastoral Care Notes (Confidential)', Icons.lock_outline),
                              const SizedBox(height: 12),
                              Text(
                                _member.pastoralNotes!,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: CmsTheme.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ] else if (_member.emergencyContactName?.isEmpty != false) ...[
                              _sectionHeader('Pastoral Care Status', Icons.favorite_outline),
                              const SizedBox(height: 12),
                              const Text(
                                'Member status active & up to date in pastoral system.',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: CmsTheme.border),
                  ),

                  // ── Section C: Family Relationships ──────────────────────
                  _sectionHeader('Family Relationships & Linked Members', Icons.family_restroom_outlined),
                  const SizedBox(height: 16),
                  _member.relations.isEmpty
                      ? const Text('No family relationships linked.', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textMuted))
                      : Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: _member.relations.map((rel) {
                            return Container(
                              width: 280,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: CmsTheme.bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: CmsTheme.border),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: CmsTheme.accent.withValues(alpha: 0.15),
                                    child: Text(
                                      rel.memberName.isNotEmpty ? rel.memberName[0].toUpperCase() : '?',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: CmsTheme.accent, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rel.memberName,
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          rel.displayRelationship,
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.accent),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios, size: 12, color: CmsTheme.textSecondary),
                                    onPressed: () async {
                                      final branchId = ref.read(currentBranchIdProvider);
                                      final linked = await ref.read(memberRepositoryProvider).getMember(branchId, rel.memberId);
                                      if (linked != null && context.mounted) {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailScreen(member: linked)));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: CmsTheme.border),
                  ),

                  // ── Section D: Giving & Financial Records ───────────────
                  _sectionHeader('Giving & Financial Records', Icons.monetization_on_outlined),
                  const SizedBox(height: 16),
                  givingAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Giving record stream active', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textMuted)),
                    data: (records) {
                      if (records.isEmpty) {
                        return const Text('No financial giving records on system for this member.', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textMuted));
                      }
                      return Column(
                        children: records.map<Widget>((r) {
                          final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
                          final type = r['type'] as String? ?? 'Giving';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(type.toUpperCase(), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary))),
                                Text('₦${amt.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.success)),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: CmsTheme.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: CmsTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CmsTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: CmsTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double size) {
    final url = _member.profileImageUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CmsTheme.accent.withValues(alpha: 0.15),
        image: (url != null && url.isNotEmpty)
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: (url == null || url.isEmpty)
          ? Center(
              child: Text(
                _member.firstName.isNotEmpty ? _member.firstName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w700,
                  color: CmsTheme.accent,
                ),
              ),
            )
          : null,
    );
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _confirmDelete(BuildContext context, String branchId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: CmsTheme.surface,
        title: const Text('Delete Member Profile?', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
        content: Text('Are you sure you want to delete ${_member.fullName}? This operation cannot be undone.', style: const TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CmsTheme.danger, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(memberRepositoryProvider).deleteMember(branchId, _member.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete Member', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }
}
