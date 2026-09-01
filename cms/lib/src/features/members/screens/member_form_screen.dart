import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
/// Multi-section form supporting spiritual milestones, emergency contact, cell group, and family relations.
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
  late final TextEditingController _memberCodeCtrl;
  late final TextEditingController _emergencyNameCtrl;
  late final TextEditingController _emergencyPhoneCtrl;
  late final TextEditingController _emergencyRelationCtrl;
  late final TextEditingController _pastoralNotesCtrl;

  String _gender = 'male';
  String _maritalStatus = 'single';
  String _status = 'active';
  DateTime _joinDate = DateTime.now();
  DateTime? _dob;
  DateTime? _weddingDate;

  bool _waterBaptized = false;
  DateTime? _waterBaptismDate;
  bool _holySpiritBaptized = false;
  DateTime? _holySpiritBaptismDate;

  String? _subGroupId;
  String? _subGroupName;

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
    _imageUrlCtrl = TextEditingController(text: m?.profileImageUrl ?? '');
    _residentAddressCtrl = TextEditingController(text: m?.residentAddress ?? '');
    _professionCtrl = TextEditingController(text: m?.profession ?? '');
    _memberCodeCtrl = TextEditingController(text: m?.memberCode ?? '');
    _emergencyNameCtrl = TextEditingController(text: m?.emergencyContactName ?? '');
    _emergencyPhoneCtrl = TextEditingController(text: m?.emergencyContactPhone ?? '');
    _emergencyRelationCtrl = TextEditingController(text: m?.emergencyContactRelation ?? '');
    _pastoralNotesCtrl = TextEditingController(text: m?.pastoralNotes ?? '');

    _gender = (m?.gender.isNotEmpty == true) ? m!.gender : 'male';
    _maritalStatus = (m?.maritalStatus?.isNotEmpty == true) ? m!.maritalStatus! : 'single';
    _status = (m?.memberStatus.isNotEmpty == true) ? m!.memberStatus : 'active';
    _joinDate = m?.joinDate ?? DateTime.now();
    _dob = m?.dob;
    _weddingDate = m?.weddingDate;

    _waterBaptized = m?.waterBaptized ?? false;
    _waterBaptismDate = m?.waterBaptismDate;
    _holySpiritBaptized = m?.holySpiritBaptized ?? false;
    _holySpiritBaptismDate = m?.holySpiritBaptismDate;

    _subGroupId = m?.subGroupId;
    _subGroupName = m?.subGroupName;

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
    _memberCodeCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _emergencyRelationCtrl.dispose();
    _pastoralNotesCtrl.dispose();
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
      final code = _memberCodeCtrl.text.trim();

      final member = MemberModel(
        id: widget.member?.id ?? '',
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        memberCode: code.isEmpty ? null : code,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
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
        waterBaptized: _waterBaptized,
        waterBaptismDate: _waterBaptized ? _waterBaptismDate : null,
        holySpiritBaptized: _holySpiritBaptized,
        holySpiritBaptismDate: _holySpiritBaptized ? _holySpiritBaptismDate : null,
        subGroupId: _subGroupId,
        subGroupName: _subGroupName,
        emergencyContactName: _emergencyNameCtrl.text.trim().isEmpty ? null : _emergencyNameCtrl.text.trim(),
        emergencyContactPhone: _emergencyPhoneCtrl.text.trim().isEmpty ? null : _emergencyPhoneCtrl.text.trim(),
        emergencyContactRelation: _emergencyRelationCtrl.text.trim().isEmpty ? null : _emergencyRelationCtrl.text.trim(),
        pastoralNotes: _pastoralNotesCtrl.text.trim().isEmpty ? null : _pastoralNotesCtrl.text.trim(),
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
          _isEditing ? 'Edit Member Profile' : 'New Member Registration',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CmsButton(
              label: _saving ? 'Saving…' : 'Save Member',
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
              // ── 1. Personal & Contact Information ─────────────────────────
              _buildSectionCard(
                title: '1. Personal & Contact Details',
                icon: Icons.person_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatarPreview(),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profile Image URL',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _imageUrlCtrl,
                                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                                keyboardType: TextInputType.url,
                                decoration: const InputDecoration(
                                  hintText: 'https://…',
                                  hintStyle: TextStyle(color: CmsTheme.textMuted, fontSize: 13),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _field('First Name *', _firstNameCtrl, required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('Last Name *', _lastNameCtrl, required: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _field('Phone Number *', _phoneCtrl, keyboard: TextInputType.phone, required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('Email Address', _emailCtrl, keyboard: TextInputType.emailAddress)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdown(
                            label: 'Gender *',
                            value: _gender,
                            items: const {'male': 'Male', 'female': 'Female'},
                            onChanged: (v) => setState(() => _gender = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _field('Residential Address', _residentAddressCtrl)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 2. Demographics & Emergency Contact ──────────────────────
              _buildSectionCard(
                title: '2. Demographics & Emergency Contact',
                icon: Icons.contact_phone_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _datePicker(
                            label: 'Date of Birth',
                            value: _dob,
                            onPicked: (d) => setState(() => _dob = d),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _dropdown(
                            label: 'Marital Status',
                            value: _maritalStatus,
                            items: const {
                              'single': 'Single',
                              'married': 'Married',
                              'widowed': 'Widowed',
                              'divorced': 'Divorced',
                            },
                            onChanged: (v) => setState(() => _maritalStatus = v!),
                          ),
                        ),
                      ],
                    ),
                    if (_maritalStatus == 'married') ...[
                      const SizedBox(height: 16),
                      _datePicker(
                        label: 'Wedding Anniversary Date',
                        value: _weddingDate,
                        onPicked: (d) => setState(() => _weddingDate = d),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _field('Profession / Occupation', _professionCtrl),
                    const SizedBox(height: 20),

                    const Divider(color: CmsTheme.border),
                    const SizedBox(height: 12),
                    const Text(
                      'Emergency Contact',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('Contact Person Name', _emergencyNameCtrl)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('Contact Phone', _emergencyPhoneCtrl, keyboard: TextInputType.phone)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('Relationship (e.g. Spouse)', _emergencyRelationCtrl)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 3. Church Placement & Spiritual Milestones ──────────────
              _buildSectionCard(
                title: '3. Church Placement & Spiritual Milestones',
                icon: Icons.church_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _field('Member Code / Unique ID (e.g. MEM-0042)', _memberCodeCtrl)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _dropdown(
                            label: 'Membership Status',
                            value: _status,
                            items: const {
                              'active': 'Active',
                              'inactive': 'Inactive',
                              'transferred': 'Transferred',
                            },
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _datePicker(
                            label: 'Date Joined Church',
                            value: _joinDate,
                            onPicked: (d) => setState(() => _joinDate = d),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Baptism switches
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CmsTheme.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CmsTheme.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: _waterBaptized,
                                activeColor: CmsTheme.accent,
                                onChanged: (v) => setState(() => _waterBaptized = v),
                              ),
                              const SizedBox(width: 8),
                              const Text('Water Baptized', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                              if (_waterBaptized) ...[
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _datePicker(
                                    label: 'Water Baptism Date',
                                    value: _waterBaptismDate,
                                    onPicked: (d) => setState(() => _waterBaptismDate = d),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Switch(
                                value: _holySpiritBaptized,
                                activeColor: CmsTheme.accent,
                                onChanged: (v) => setState(() => _holySpiritBaptized = v),
                              ),
                              const SizedBox(width: 8),
                              const Text('Holy Spirit Baptized', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                              if (_holySpiritBaptized) ...[
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _datePicker(
                                    label: 'Holy Spirit Baptism Date',
                                    value: _holySpiritBaptismDate,
                                    onPicked: (d) => setState(() => _holySpiritBaptismDate = d),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Department assignments
                    const Text('Department Assignments', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                    const SizedBox(height: 10),
                    deptsAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error loading departments: $e', style: const TextStyle(color: CmsTheme.danger)),
                      data: (depts) {
                        if (depts.isEmpty) return const Text('No departments configured.', style: TextStyle(color: CmsTheme.textMuted));
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: depts.map((d) {
                            final sel = _selectedDeptIds.contains(d.id);
                            return FilterChip(
                              label: Text(d.name),
                              selected: sel,
                              selectedColor: CmsTheme.accent.withValues(alpha: 0.2),
                              checkmarkColor: CmsTheme.accent,
                              labelStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: sel ? CmsTheme.accent : CmsTheme.textSecondary,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedDeptIds.add(d.id);
                                  } else {
                                    _selectedDeptIds.remove(d.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Pastoral notes
                    _field('Pastoral Care Notes (Confidential)', _pastoralNotesCtrl, maxLines: 3),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 4. Family Relationships ────────────────────────────────────
              _buildSectionCard(
                title: '4. Family Relationships & Linked Members',
                icon: Icons.family_restroom_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    allMembersAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error loading member list: $e', style: const TextStyle(color: CmsTheme.danger)),
                      data: (allMembers) {
                        final available = allMembers.where((m) => m.id != widget.member?.id).toList();
                        return Column(
                          children: [
                            ..._relations.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final rel = entry.value;
                              return _buildRelationRow(idx, rel, available);
                            }),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _relations.add(_RelationEntry())),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Family Relation', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save button at bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter')),
                  ),
                  const SizedBox(width: 16),
                  CmsButton(
                    label: _saving ? 'Saving…' : 'Save Member Profile',
                    icon: Icons.check,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
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
              Icon(icon, color: CmsTheme.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CmsTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildAvatarPreview() {
    final url = _imageUrlCtrl.text.trim();
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: CmsTheme.accent.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: CmsTheme.accent, width: 2),
        image: (url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true)
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url.isEmpty
          ? const Icon(Icons.person, color: CmsTheme.accent, size: 36)
          : null,
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          decoration: const InputDecoration(
            hintStyle: TextStyle(color: CmsTheme.textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: items.containsKey(value) ? value : items.keys.first,
          dropdownColor: CmsTheme.surfaceElevated,
          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
  }) {
    final text = value != null ? DateFormat('dd/MM/yyyy').format(value) : 'Select date';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1920),
              lastDate: DateTime(2050),
            );
            if (picked != null) onPicked(picked);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: CmsTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: value != null ? CmsTheme.textPrimary : CmsTheme.textMuted,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 16, color: CmsTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelationRow(int idx, _RelationEntry rel, List<MemberModel> availableMembers) {
    const relTypes = [
      'Spouse',
      'Child',
      'Parent',
      'Sibling',
      'Cousin',
      'Grandparent',
      'Friend',
      'Other',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: rel.memberId,
              hint: const Text('Select Linked Member', style: TextStyle(fontSize: 12, color: CmsTheme.textMuted)),
              dropdownColor: CmsTheme.surfaceElevated,
              style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter', fontSize: 13),
              items: availableMembers.map((m) {
                return DropdownMenuItem(
                  value: m.id,
                  child: Text(m.fullName),
                );
              }).toList(),
              onChanged: (v) {
                final match = availableMembers.firstWhere((m) => m.id == v);
                setState(() {
                  rel.memberId = match.id;
                  rel.memberName = match.fullName;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: relTypes.contains(rel.relationship) ? rel.relationship : relTypes.first,
              dropdownColor: CmsTheme.surfaceElevated,
              style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter', fontSize: 13),
              items: relTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => rel.relationship = v!),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: CmsTheme.danger, size: 18),
            onPressed: () => setState(() => _relations.removeAt(idx)),
          ),
        ],
      ),
    );
  }
}

class _RelationEntry {
  _RelationEntry({
    this.memberId,
    this.memberName,
    this.relationship = 'Spouse',
    String? customRel,
  }) : customRelCtrl = TextEditingController(text: customRel ?? '');

  String? memberId;
  String? memberName;
  String relationship;
  final TextEditingController customRelCtrl;

  factory _RelationEntry.fromModel(MemberRelation r) => _RelationEntry(
        memberId: r.memberId,
        memberName: r.memberName,
        relationship: r.relationship,
        customRel: r.customRelationship,
      );

  void dispose() => customRelCtrl.dispose();
}

