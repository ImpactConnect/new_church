import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/departments/models/department_model.dart';

final _departmentsForFormProvider =
    StreamProvider.autoDispose.family<List<DepartmentModel>, String>(
  (ref, branchId) =>
      ref.watch(departmentRepositoryProvider).watchDepartments(branchId),
);

final _allMembersForFormProvider =
    StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) =>
      ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

/// Create / Edit member form.
/// Secretary: full CRUD. Lead Pastor: view-only (redirected to MemberDetailScreen).
class MemberFormScreen extends ConsumerStatefulWidget {
  const MemberFormScreen({super.key, this.member});
  final MemberModel? member;

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _residentAddressCtrl;
  late final TextEditingController _professionCtrl;
  String _gender = 'male';
  String _maritalStatus = 'single';
  String _status = 'active';
  DateTime _joinDate = DateTime.now();
  DateTime? _dob;
  DateTime? _weddingDate;
  List<String> _selectedDeptIds = [];
  List<_RelationEntry> _relations = [];
  bool _saving = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _firstNameCtrl = TextEditingController(text: m?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: m?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: m?.phone ?? '');
    _emailCtrl = TextEditingController(text: m?.email ?? '');
    _imageUrlCtrl =
        TextEditingController(text: m?.profileImageUrl ?? '');
    _residentAddressCtrl = TextEditingController(text: m?.residentAddress ?? '');
    _professionCtrl = TextEditingController(text: m?.profession ?? '');
    _gender = m?.gender ?? 'male';
    _maritalStatus = m?.maritalStatus ?? 'single';
    _status = m?.memberStatus ?? 'active';
    _joinDate = m?.joinDate ?? DateTime.now();
    _dob = m?.dob;
    _weddingDate = m?.weddingDate;
    _selectedDeptIds = List.from(m?.departmentIds ?? []);
    _relations = (m?.relations ?? [])
        .map((r) => _RelationEntry.fromModel(r))
        .toList();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _imageUrlCtrl.dispose();
    _residentAddressCtrl.dispose();
    _professionCtrl.dispose();
    for (final r in _relations) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final branchId = ref.read(currentBranchIdProvider);
      final relations = _relations
          .where((r) => r.memberId != null && r.relationship.isNotEmpty)
          .map((r) => MemberRelation(
                memberId: r.memberId!,
                memberName: r.memberName!,
                relationship: r.relationship,
                customRelationship: r.customRelCtrl.text.trim().isNotEmpty
                    ? r.customRelCtrl.text.trim()
                    : null,
              ))
          .toList();
      final imageUrl = _imageUrlCtrl.text.trim();
      final member = MemberModel(
        id: widget.member?.id ?? '',
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty
            ? null
            : _emailCtrl.text.trim(),
        gender: _gender,
        joinDate: _joinDate,
        memberStatus: _status,
        dob: _dob,
        maritalStatus: _maritalStatus,
        weddingDate: _maritalStatus == 'married' ? _weddingDate : null,
        departmentIds: _selectedDeptIds,
        roleId: widget.member?.roleId,
        importBatchId: widget.member?.importBatchId,
        importedAt: widget.member?.importedAt,
        profileImageUrl: imageUrl.isEmpty ? null : imageUrl,
        residentAddress: _residentAddressCtrl.text.trim().isEmpty ? null : _residentAddressCtrl.text.trim(),
        profession: _professionCtrl.text.trim().isEmpty ? null : _professionCtrl.text.trim(),
        relations: relations,
      );
      await ref.read(memberRepositoryProvider).saveMember(branchId, member);
      nav.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error saving member: $e'),
        backgroundColor: CmsTheme.danger,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final deptsAsync = ref.watch(_departmentsForFormProvider(branchId));
    final allMembersAsync = ref.watch(_allMembersForFormProvider(branchId));

    return Scaffold(
      backgroundColor: CmsTheme.bg,
      appBar: AppBar(
        backgroundColor: CmsTheme.sidebar,
        foregroundColor: CmsTheme.textPrimary,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Member' : 'Add Member',
          style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16),
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CmsButton(
              label: 'Save',
              icon: Icons.check,
              compact: true,
              loading: _saving,
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Image ─────────────────────────────────────────
              _sectionTitle('Profile Photo'),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar preview
                  _buildAvatarPreview(),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Image URL',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: CmsTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _imageUrlCtrl,
                          style: const TextStyle(
                              color: CmsTheme.textPrimary,
                              fontFamily: 'Inter'),
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            hintText: 'https://…',
                            hintStyle: TextStyle(
                                color: CmsTheme.textMuted,
                                fontSize: 13),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Paste a direct image URL or use an image hosting service.',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: CmsTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Personal Information ──────────────────────────────────
              _sectionTitle('Personal Information'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _field('First Name', _firstNameCtrl,
                        required: true)),
                const SizedBox(width: 16),
                Expanded(
                    child: _field('Last Name', _lastNameCtrl,
                        required: true)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _field('Phone Number', _phoneCtrl,
                        keyboard: TextInputType.phone)),
                const SizedBox(width: 16),
                Expanded(
                    child: _field('Email Address', _emailCtrl,
                        keyboard: TextInputType.emailAddress)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _field('Resident Address', _residentAddressCtrl,
                        keyboard: TextInputType.streetAddress)),
                const SizedBox(width: 16),
                Expanded(
                    child: _field('Profession', _professionCtrl)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _dropdown('Gender', _gender, ['male', 'female'],
                        (v) => setState(() => _gender = v!))),
                const SizedBox(width: 16),
                Expanded(
                    child: _dropdown(
                        'Marital Status',
                        _maritalStatus,
                        ['single', 'married', 'widowed', 'divorced'],
                        (v) => setState(() => _maritalStatus = v!))),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _datePicker('Date of Birth', _dob,
                        (d) => setState(() => _dob = d))),
                const SizedBox(width: 16),
                Expanded(
                    child: _datePicker('Join Date *', _joinDate,
                        (d) => setState(() => _joinDate = d ?? _joinDate))),
              ]),
              if (_maritalStatus == 'married') ...[
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _datePicker('Wedding Date', _weddingDate,
                        (d) => setState(() => _weddingDate = d)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox.shrink()),
                ]),
              ],
              const SizedBox(height: 28),

              // ── Membership ────────────────────────────────────────────
              _sectionTitle('Membership'),
              const SizedBox(height: 16),
              _dropdown('Status', _status,
                  ['active', 'inactive', 'transferred'],
                  (v) => setState(() => _status = v!)),
              const SizedBox(height: 16),
              const Text('Departments',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CmsTheme.textSecondary)),
              const SizedBox(height: 8),
              deptsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Could not load departments',
                    style: TextStyle(color: CmsTheme.danger)),
                data: (depts) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: depts.map((d) {
                    final selected = _selectedDeptIds.contains(d.id);
                    return FilterChip(
                      label: Text(d.name,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: selected
                                  ? Colors.white
                                  : CmsTheme.textSecondary)),
                      selected: selected,
                      selectedColor: CmsTheme.accent,
                      backgroundColor: CmsTheme.surfaceElevated,
                      side: BorderSide(
                          color: selected
                              ? CmsTheme.accent
                              : CmsTheme.border),
                      checkmarkColor: Colors.white,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedDeptIds.add(d.id);
                          } else {
                            _selectedDeptIds.remove(d.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // ── Family & Relationships ────────────────────────────────
              _sectionTitle('Family & Relationships'),
              const SizedBox(height: 4),
              const Text(
                  'Link this member to others in the church directory.',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: CmsTheme.textMuted)),
              const SizedBox(height: 16),
              allMembersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) =>
                    const Text('Could not load member directory',
                        style: TextStyle(color: CmsTheme.danger)),
                data: (allMembers) {
                  final otherMembers = allMembers
                      .where((m) => m.id != (widget.member?.id ?? ''))
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < _relations.length; i++)
                        _RelationRow(
                          key: ValueKey(i),
                          entry: _relations[i],
                          allMembers: otherMembers,
                          existingRelationIds: _relations
                              .where((r) => r != _relations[i])
                              .map((r) => r.memberId ?? '')
                              .where((id) => id.isNotEmpty)
                              .toList(),
                          onRemove: () => setState(
                              () => _relations.removeAt(i)),
                          onChanged: () => setState(() {}),
                        ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _relations.add(_RelationEntry())),
                        icon: const Icon(Icons.add_circle_outline,
                            color: CmsTheme.accent, size: 18),
                        label: const Text('Add Relation',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: CmsTheme.accent)),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPreview() {
    final url = _imageUrlCtrl.text.trim();
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(48),
        child: Image.network(
          url,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(),
        ),
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final initials =
        '${first.isNotEmpty ? first[0].toUpperCase() : ''}${last.isNotEmpty ? last[0].toUpperCase() : ''}';
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: CmsTheme.brandGradient,
        borderRadius: BorderRadius.circular(48),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CmsTheme.textPrimary)),
          const SizedBox(height: 6),
          Container(
              height: 2,
              width: 32,
              decoration: BoxDecoration(
                gradient: CmsTheme.brandGradient,
                borderRadius: BorderRadius.circular(1),
              )),
        ],
      );

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false,
      TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CmsTheme.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(
              color: CmsTheme.textPrimary, fontFamily: 'Inter'),
          validator: required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  Widget _dropdown(String label, String value, List<String> options,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CmsTheme.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: CmsTheme.surfaceElevated,
          style: const TextStyle(
              color: CmsTheme.textPrimary,
              fontFamily: 'Inter',
              fontSize: 14),
          decoration: const InputDecoration(),
          items: options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(_humanize(o)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _datePicker(String label, DateTime? value,
      ValueChanged<DateTime?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CmsTheme.textSecondary)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                        primary: CmsTheme.accent)),
                child: child!,
              ),
            );
            onChanged(d);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CmsTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: CmsTheme.textMuted),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
                      : 'Select date',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: value != null
                          ? CmsTheme.textPrimary
                          : CmsTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _humanize(String s) {
    if (s.isEmpty) return '';
    return '${s[0].toUpperCase()}${s.substring(1).replaceAll('-', ' ')}';
  }
}

// ─────────────────────────── Relation State ─────────────────────────────────

class _RelationEntry {
  String? memberId;
  String? memberName;
  String relationship = '';
  final TextEditingController customRelCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();
  bool showDropdown = false;

  _RelationEntry();

  factory _RelationEntry.fromModel(MemberRelation r) {
    final entry = _RelationEntry();
    entry.memberId = r.memberId;
    entry.memberName = r.memberName;
    entry.relationship = r.relationship;
    entry.searchCtrl.text = r.memberName;
    if (r.customRelationship != null) {
      entry.customRelCtrl.text = r.customRelationship!;
    }
    return entry;
  }

  void dispose() {
    customRelCtrl.dispose();
    searchCtrl.dispose();
  }
}

// ─────────────────────────── Relation Row Widget ─────────────────────────────

class _RelationRow extends StatefulWidget {
  const _RelationRow({
    super.key,
    required this.entry,
    required this.allMembers,
    required this.existingRelationIds,
    required this.onRemove,
    required this.onChanged,
  });

  final _RelationEntry entry;
  final List<MemberModel> allMembers;
  final List<String> existingRelationIds;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_RelationRow> createState() => _RelationRowState();
}

class _RelationRowState extends State<_RelationRow> {
  static const _relationshipTypes = [
    'Wife', 'Husband', 'Son', 'Daughter', 'Cousin',
    'Grandparent', 'Sibling', 'Friend', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final candidates = entry.searchCtrl.text.isNotEmpty
        ? widget.allMembers
            .where((m) =>
                !widget.existingRelationIds.contains(m.id) &&
                m.fullName
                    .toLowerCase()
                    .contains(entry.searchCtrl.text.toLowerCase()) &&
                m.id != entry.memberId)
            .take(6)
            .toList()
        : <MemberModel>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Relation',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CmsTheme.textSecondary)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 16, color: CmsTheme.textMuted),
                onPressed: widget.onRemove,
                tooltip: 'Remove relation',
                constraints: const BoxConstraints(
                    minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Member search
          if (entry.memberId != null) ...[
            // Selected member chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: CmsTheme.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: CmsTheme.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 14, color: CmsTheme.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(entry.memberName ?? '',
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: CmsTheme.textPrimary)),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      entry.memberId = null;
                      entry.memberName = null;
                      entry.searchCtrl.clear();
                      widget.onChanged();
                    }),
                    child: const Icon(Icons.close,
                        size: 14, color: CmsTheme.textMuted),
                  ),
                ],
              ),
            ),
          ] else ...[
            TextField(
              controller: entry.searchCtrl,
              style: const TextStyle(
                  color: CmsTheme.textPrimary,
                  fontFamily: 'Inter',
                  fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search member name…',
                hintStyle:
                    TextStyle(color: CmsTheme.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search,
                    size: 16, color: CmsTheme.textMuted),
                isDense: true,
              ),
              onChanged: (_) {
                setState(() => entry.showDropdown = true);
                widget.onChanged();
              },
              onTap: () => setState(() => entry.showDropdown = true),
            ),
            if (entry.showDropdown && candidates.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: CmsTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CmsTheme.border),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: candidates.length,
                  itemBuilder: (_, i) {
                    final m = candidates[i];
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
                        entry.memberId = m.id;
                        entry.memberName = m.fullName;
                        entry.searchCtrl.text = m.fullName;
                        entry.showDropdown = false;
                        widget.onChanged();
                      }),
                    );
                  },
                ),
              ),
            ],
          ],
          const SizedBox(height: 10),
          // Relationship type
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: entry.relationship.isEmpty
                      ? null
                      : entry.relationship,
                  dropdownColor: CmsTheme.surfaceElevated,
                  hint: const Text('Relationship type',
                      style: TextStyle(
                          color: CmsTheme.textMuted,
                          fontFamily: 'Inter',
                          fontSize: 13)),
                  style: const TextStyle(
                      color: CmsTheme.textPrimary,
                      fontFamily: 'Inter',
                      fontSize: 13),
                  decoration: const InputDecoration(isDense: true),
                  items: _relationshipTypes
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    entry.relationship = v ?? '';
                    widget.onChanged();
                  }),
                ),
              ),
              // Custom field when 'Other'
              if (entry.relationship == 'Other') ...[
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: entry.customRelCtrl,
                    style: const TextStyle(
                        color: CmsTheme.textPrimary,
                        fontFamily: 'Inter',
                        fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Specify…',
                      hintStyle: TextStyle(
                          color: CmsTheme.textMuted, fontSize: 13),
                      isDense: true,
                    ),
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
