import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/departments/models/department_model.dart';

final _departmentsForFormProvider = StreamProvider.autoDispose.family<List<DepartmentModel>, String>(
  (ref, branchId) => ref.watch(departmentRepositoryProvider).watchDepartments(branchId),
);

/// Create / Edit member form.
/// Secretary: full CRUD. Lead Pastor: can edit status only.
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
  String _gender = 'male';
  String _maritalStatus = 'single';
  String _status = 'active';
  DateTime _joinDate = DateTime.now();
  DateTime? _dob;
  List<String> _selectedDeptIds = [];
  bool _saving = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _firstNameCtrl = TextEditingController(text: m?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: m?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: m?.phone ?? '');
    _gender = m?.gender ?? 'male';
    _maritalStatus = m?.maritalStatus ?? 'single';
    _status = m?.memberStatus ?? 'active';
    _joinDate = m?.joinDate ?? DateTime.now();
    _dob = m?.dob;
    _selectedDeptIds = List.from(m?.departmentIds ?? []);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final branchId = ref.read(currentBranchIdProvider);
      final member = MemberModel(
        id: widget.member?.id ?? '',
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        gender: _gender,
        joinDate: _joinDate,
        memberStatus: _status,
        dob: _dob,
        maritalStatus: _maritalStatus,
        departmentIds: _selectedDeptIds,
        roleId: widget.member?.roleId,
        importBatchId: widget.member?.importBatchId,
        importedAt: widget.member?.importedAt,
      );
      await ref.read(memberRepositoryProvider).saveMember(branchId, member);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving member: $e'),
            backgroundColor: CmsTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final deptsAsync = ref.watch(_departmentsForFormProvider(branchId));

    return Scaffold(
      backgroundColor: CmsTheme.bg,
      appBar: AppBar(
        backgroundColor: CmsTheme.sidebar,
        foregroundColor: CmsTheme.textPrimary,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Member' : 'Add Member',
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              // Personal Information
              _sectionTitle('Personal Information'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _field('First Name', _firstNameCtrl, required: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _field('Last Name', _lastNameCtrl, required: true)),
                ],
              ),
              const SizedBox(height: 16),
              _field('Phone Number', _phoneCtrl, keyboard: TextInputType.phone),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _dropdown(
                      'Gender',
                      _gender,
                      ['male', 'female'],
                      (v) => setState(() => _gender = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _dropdown(
                      'Marital Status',
                      _maritalStatus,
                      ['single', 'married', 'widowed', 'divorced'],
                      (v) => setState(() => _maritalStatus = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _datePicker('Date of Birth', _dob, (d) => setState(() => _dob = d)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _datePicker(
                      'Join Date *',
                      _joinDate,
                      (d) => setState(() => _joinDate = d ?? _joinDate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _sectionTitle('Membership'),
              const SizedBox(height: 16),
              _dropdown(
                'Status',
                _status,
                ['active', 'inactive', 'transferred'],
                (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              // Department selection
              const Text(
                'Departments',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CmsTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              deptsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Could not load departments', style: TextStyle(color: CmsTheme.danger)),
                data: (depts) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: depts.map((d) {
                    final selected = _selectedDeptIds.contains(d.id);
                    return FilterChip(
                      label: Text(
                        d.name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: selected ? Colors.white : CmsTheme.textSecondary,
                        ),
                      ),
                      selected: selected,
                      selectedColor: CmsTheme.accent,
                      backgroundColor: CmsTheme.surfaceElevated,
                      side: BorderSide(
                        color: selected ? CmsTheme.accent : CmsTheme.border,
                      ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: CmsTheme.textPrimary,
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CmsTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CmsTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: CmsTheme.surfaceElevated,
          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter', fontSize: 14),
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

  Widget _datePicker(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CmsTheme.textSecondary,
          ),
        ),
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
                  colorScheme: const ColorScheme.dark(primary: CmsTheme.accent),
                ),
                child: child!,
              ),
            );
            onChanged(d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CmsTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: CmsTheme.textMuted),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
                      : 'Select date',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: value != null ? CmsTheme.textPrimary : CmsTheme.textMuted,
                  ),
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
