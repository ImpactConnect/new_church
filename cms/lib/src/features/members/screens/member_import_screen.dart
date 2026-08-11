import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/members/models/member_model.dart';

/// Validated member row ready (or not) for import.
class _ImportRow {
  _ImportRow({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.gender,
    required this.joinDate,
    this.errors = const [],
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String gender;
  final DateTime? joinDate;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;

  MemberModel toModel(String importBatchId) => MemberModel(
    id: '',
    firstName: firstName,
    lastName: lastName,
    phone: phone,
    gender: gender.toLowerCase(),
    joinDate: joinDate ?? DateTime.now(),
    memberStatus: 'active',
    importBatchId: importBatchId,
    importedAt: DateTime.now(),
  );
}

class MemberImportScreen extends ConsumerStatefulWidget {
  const MemberImportScreen({super.key});

  @override
  ConsumerState<MemberImportScreen> createState() => _MemberImportScreenState();
}

class _MemberImportScreenState extends ConsumerState<MemberImportScreen> {
  List<_ImportRow> _rows = [];
  bool _picked = false;
  bool _importing = false;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    _fileName = file.name;
    final content = utf8.decode(file.bytes!);
    final rows = const CsvToListConverter(eol: '\n').convert(content);

    if (rows.isEmpty) {
      setState(() { _rows = []; _picked = true; });
      return;
    }

    // Skip header row, parse remaining
    final header = rows.first.map((c) => c.toString().toLowerCase().trim()).toList();
    final parsed = <_ImportRow>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c.toString().trim().isEmpty)) continue;

      String get(String col) {
        final idx = header.indexOf(col);
        return idx >= 0 && idx < row.length ? row[idx].toString().trim() : '';
      }

      final errors = <String>[];
      final firstName = get('firstname') != '' ? get('firstname') : get('first name') != '' ? get('first name') : get('first_name');
      final lastName = get('lastname') != '' ? get('lastname') : get('last name') != '' ? get('last name') : get('last_name');
      final phone = get('phone');
      final gender = get('gender');
      final joinDateStr = get('joindate') != '' ? get('joindate') : get('join date') != '' ? get('join date') : get('join_date');

      if (firstName.isEmpty) errors.add('First name missing');
      if (lastName.isEmpty) errors.add('Last name missing');
      if (phone.isEmpty) errors.add('Phone missing');
      if (!['male', 'female', 'm', 'f'].contains(gender.toLowerCase())) errors.add('Invalid gender');

      DateTime? joinDate;
      if (joinDateStr.isNotEmpty) {
        joinDate = DateTime.tryParse(joinDateStr);
        if (joinDate == null) errors.add('Invalid join date');
      }

      parsed.add(_ImportRow(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        gender: gender.toLowerCase() == 'm' ? 'male' : gender.toLowerCase() == 'f' ? 'female' : gender.toLowerCase(),
        joinDate: joinDate,
        errors: errors,
      ));
    }

    setState(() {
      _rows = parsed;
      _picked = true;
    });
  }

  Future<void> _import() async {
    final validRows = _rows.where((r) => !r.hasErrors).toList();
    if (validRows.isEmpty) return;

    setState(() => _importing = true);
    try {
      final branchId = ref.read(currentBranchIdProvider);
      final batchId = const Uuid().v4();
      final members = validRows.map((r) => r.toModel(batchId)).toList();
      await ref.read(memberRepositoryProvider).importMembers(branchId, members, batchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Imported ${members.length} members successfully.'),
            backgroundColor: CmsTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: CmsTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = _rows.where((r) => !r.hasErrors).length;
    final invalid = _rows.where((r) => r.hasErrors).length;

    return Scaffold(
      backgroundColor: CmsTheme.bg,
      appBar: AppBar(
        backgroundColor: CmsTheme.sidebar,
        foregroundColor: CmsTheme.textPrimary,
        elevation: 0,
        title: const Text('Import Members from CSV', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            CmsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CSV Format', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: CmsTheme.textPrimary)),
                  const SizedBox(height: 8),
                  const Text(
                    'Required columns: FirstName, LastName, Phone, Gender (male/female), JoinDate (YYYY-MM-DD)\n'
                    'Optional: MaritalStatus, DateOfBirth',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CmsButton(
                        label: _picked ? 'Change File' : 'Choose CSV File',
                        icon: Icons.upload_file_outlined,
                        variant: CmsButtonVariant.secondary,
                        onPressed: _pickFile,
                      ),
                      if (_fileName != null) ...[
                        const SizedBox(width: 12),
                        Text(_fileName!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (_picked && _rows.isNotEmpty) ...[
              const SizedBox(height: 20),
              // Summary
              Row(
                children: [
                  _summaryBadge('${_rows.length} Total', CmsTheme.accent),
                  const SizedBox(width: 8),
                  _summaryBadge('$valid Valid', CmsTheme.success),
                  if (invalid > 0) ...[
                    const SizedBox(width: 8),
                    _summaryBadge('$invalid Errors', CmsTheme.danger),
                  ],
                  const Spacer(),
                  CmsButton(
                    label: 'Import $valid Members',
                    icon: Icons.cloud_upload_outlined,
                    loading: _importing,
                    onPressed: valid > 0 ? _import : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Preview table
              Expanded(
                child: CmsCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(2),
                          5: FlexColumnWidth(3),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: CmsTheme.surfaceElevated),
                            children: ['First Name', 'Last Name', 'Phone', 'Gender', 'Join Date', 'Issues']
                                .map((h) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Text(h, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)),
                                    ))
                                .toList(),
                          ),
                          ..._rows.map((r) => TableRow(
                            decoration: BoxDecoration(
                              color: r.hasErrors ? CmsTheme.danger.withValues(alpha: 0.05) : null,
                              border: const Border(bottom: BorderSide(color: CmsTheme.border, width: 0.5)),
                            ),
                            children: [
                              _tableCell(r.firstName, error: r.errors.contains('First name missing')),
                              _tableCell(r.lastName, error: r.errors.contains('Last name missing')),
                              _tableCell(r.phone, error: r.errors.contains('Phone missing')),
                              _tableCell(r.gender, error: r.errors.contains('Invalid gender')),
                              _tableCell(
                                r.joinDate != null
                                    ? '${r.joinDate!.day}/${r.joinDate!.month}/${r.joinDate!.year}'
                                    : '—',
                                error: r.errors.contains('Invalid join date'),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: r.hasErrors
                                    ? Text(
                                        r.errors.join(', '),
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.danger),
                                      )
                                    : const Icon(Icons.check_circle_outline, size: 16, color: CmsTheme.success),
                              ),
                            ],
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ] else if (_picked && _rows.isEmpty)
              const Expanded(
                child: CmsEmptyState(
                  icon: Icons.table_rows_outlined,
                  title: 'No rows found',
                  subtitle: 'The CSV file appears to be empty or has only a header row.',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _tableCell(String text, {bool error = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Text(
      text.isEmpty ? '—' : text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: error ? CmsTheme.danger : CmsTheme.textSecondary,
      ),
    ),
  );
}
