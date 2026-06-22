import 'dart:html' as html;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/member.dart';

// ── Credential helper ────────────────────────────────────────────────────────
String _generateUsername(String firstName, String lastName) {
  final fn = firstName.trim().toLowerCase().replaceAll(' ', '');
  final ln = lastName.trim().toLowerCase().replaceAll(' ', '');
  final num = Random().nextInt(900) + 100;
  return '$fn.$ln$num';
}

String _generatePassword({int length = 10}) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#!';
  final rng = Random.secure();
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

// ── Copyable credential chip ──────────────────────────────────────────────────
Widget credentialChip(BuildContext context, String label, String value) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Row(
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 13))),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          tooltip: 'Copy',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copied!')));
          },
        ),
      ],
    ),
  );
}

// ── Add Member Form ──────────────────────────────────────────────────────────
class AddMemberForm extends StatefulWidget {
  const AddMemberForm({super.key});
  @override
  State<AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends State<AddMemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _fnCtrl = TextEditingController();
  final _lnCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _spouseCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();

  DateTime? _dob;
  String _gender = 'Male';
  String _maritalStatus = 'Single';
  List<String> _selectedGroups = [];
  bool _isStudent = false;
  bool _saving = false;
  bool _uploadingImage = false;

  String? _genUsername;
  String? _genPassword;

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickAndUploadImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;

    final file = input.files!.first;
    setState(() => _uploadingImage = true);

    try {
      final ref = FirebaseStorage.instance.ref('member_photos/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      final task = await ref.putBlob(file);
      final url = await task.ref.getDownloadURL();
      setState(() => _photoUrlCtrl.text = url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select date of birth')));
      return;
    }
    setState(() => _saving = true);

    final username = _generateUsername(_fnCtrl.text, _lnCtrl.text);
    final password = _generatePassword();
    final email = _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : '$username@impactconnect.app';

    try {
      FirebaseApp secondary;
      try {
        secondary = Firebase.app('MemberCreation');
      } catch (_) {
        secondary = await Firebase.initializeApp(name: 'MemberCreation', options: Firebase.app().options);
      }

      final cred = await FirebaseAuth.instanceFor(app: secondary).createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      await FirebaseAuth.instanceFor(app: secondary).signOut();

      final fullName = '${_fnCtrl.text.trim()} ${_lnCtrl.text.trim()}';
      await FirebaseFirestore.instance.collection('members').doc(uid).set({
        'name': fullName,
        'email': email,
        'username': username,
        'phoneNumber': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'gender': _gender,
        'maritalStatus': _maritalStatus.toLowerCase(),
        'spouseName': _spouseCtrl.text.trim(),
        'occupation': _isStudent ? 'Student' : _professionCtrl.text.trim(),
        'schoolName': _isStudent ? _schoolCtrl.text.trim() : null,
        'stateOfOrigin': _stateCtrl.text.trim(),
        'churchGroups': _selectedGroups,
        'photoUrl': _photoUrlCtrl.text.trim().isNotEmpty ? _photoUrlCtrl.text.trim() : null,
        'birthDate': Timestamp.fromDate(_dob!),
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (final group in _selectedGroups) {
        try {
          final groupsSnap = await FirebaseFirestore.instance
              .collection('community_groups')
              .where('name', isEqualTo: group)
              .limit(1)
              .get();
              
          if (groupsSnap.docs.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('community_groups')
                .doc(groupsSnap.docs.first.id)
                .update({
              'members': FieldValue.arrayUnion([uid])
            });
          }
        } catch (e) {
          print('Error assigning to community group $group: $e');
        }
      }

      setState(() {
        _genUsername = username;
        _genPassword = password;
        _saving = false;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    setState(() {
      _dob = null;
      _gender = 'Male';
      _maritalStatus = 'Single';
      _selectedGroups = [];
      _isStudent = false;
      _genUsername = null;
      _genPassword = null;
    });
    for (final c in [_fnCtrl, _lnCtrl, _phoneCtrl, _addressCtrl, _professionCtrl, _schoolCtrl, _spouseCtrl, _stateCtrl, _emailCtrl, _photoUrlCtrl]) c.clear();
  }

  InputDecoration _dec(String label, {Widget? suffix}) => InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, suffixIcon: suffix);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name row
            Row(children: [
              Expanded(child: TextFormField(controller: _fnCtrl, decoration: _dec('First Name'), validator: (v) => v!.isEmpty ? 'Required' : null)),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _lnCtrl, decoration: _dec('Last Name'), validator: (v) => v!.isEmpty ? 'Required' : null)),
            ]),
            const SizedBox(height: 12),

            // DOB + Gender
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: _dec('Date of Birth'),
                    child: Text(_dob == null ? 'Select date' : '${_dob!.day}/${_dob!.month}/${_dob!.year}', style: TextStyle(color: _dob == null ? Colors.grey : Colors.black, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: _dec('Gender'),
                  items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _gender = v!),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Phone + Email
            Row(children: [
              Expanded(child: TextFormField(controller: _phoneCtrl, decoration: _dec('Phone Number'), keyboardType: TextInputType.phone)),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _emailCtrl, decoration: _dec('Email (optional)'))),
            ]),
            const SizedBox(height: 12),

            // Photo URL
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _photoUrlCtrl,
                  decoration: _dec('Image URL'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _uploadingImage ? null : _pickAndUploadImage,
                icon: _uploadingImage ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file),
                label: const Text('Upload'),
              ),
            ]),
            const SizedBox(height: 12),

            // Address
            TextFormField(controller: _addressCtrl, decoration: _dec('Address')),
            const SizedBox(height: 12),

            // Profession / Student toggle
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Is a Student?', style: TextStyle(fontSize: 13)), value: _isStudent, onChanged: (v) => setState(() => _isStudent = v)),
            if (_isStudent) TextFormField(controller: _schoolCtrl, decoration: _dec('School Name')) else TextFormField(controller: _professionCtrl, decoration: _dec('Profession / Occupation')),
            const SizedBox(height: 12),

            // Marital status
            DropdownButtonFormField<String>(
              value: _maritalStatus,
              decoration: _dec('Marital Status'),
              items: ['Single', 'Married', 'Divorced', 'Widowed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _maritalStatus = v!),
            ),
            if (_maritalStatus == 'Married') ...[
              const SizedBox(height: 12),
              TextFormField(controller: _spouseCtrl, decoration: _dec('Spouse Name')),
            ],
            const SizedBox(height: 12),

            // Church group + State
            Row(children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('church_groups').orderBy('name').snapshots(),
                  builder: (context, snap) {
                    List<String> groups = [];
                    if (snap.hasData) {
                      groups.addAll(snap.data!.docs.map((d) => d['name'] as String).toList());
                    }
                    if (groups.isEmpty) return const Text('No church groups available', style: TextStyle(color: Colors.grey));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Church Groups / Units:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: groups.map((g) {
                            final isSelected = _selectedGroups.contains(g);
                            return FilterChip(
                              label: Text(g),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedGroups.add(g);
                                  } else {
                                    _selectedGroups.remove(g);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _stateCtrl, decoration: _dec('State of Origin'))),
            ]),
            const SizedBox(height: 20),

            // Action buttons
            if (_saving)
              const Center(child: CircularProgressIndicator())
            else if (_genUsername != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green[200]!)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 8), Text('Member Created — Login Credentials', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                    const SizedBox(height: 10),
                    credentialChip(context, 'Username', _genUsername!),
                    credentialChip(context, 'Password', _genPassword!),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: _reset, icon: const Icon(Icons.add), label: const Text('Add Another Member'), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 46))),
            ] else
              ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Create Member & Generate Credentials'), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 46))),
          ],
        ),
      ),
    );
  }
}

// ── CSV Bulk Upload ──────────────────────────────────────────────────────────
class CsvUploadPanel extends StatefulWidget {
  const CsvUploadPanel({super.key});
  @override
  State<CsvUploadPanel> createState() => _CsvUploadPanelState();
}

class _CsvUploadPanelState extends State<CsvUploadPanel> {
  bool _uploading = false;
  int _uploaded = 0;
  String? _log;

  Future<void> _pickAndUpload() async {
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;

    setState(() { _uploading = true; _uploaded = 0; _log = null; });

    final reader = html.FileReader();
    reader.readAsText(input.files!.first);
    await reader.onLoad.first;
    final content = reader.result as String;
    final lines = content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) {
      setState(() => _uploading = false);
      return;
    }

    // Skip header row
    final dataRows = lines.skip(1).toList();
    final log = StringBuffer();
    int count = 0;

    for (final row in dataRows) {
      final cols = row.split(',').map((c) => c.trim()).toList();
      if (cols.length < 3) continue;
      try {
        final name = cols[0];
        final email = cols.length > 1 ? cols[1] : '';
        final phone = cols.length > 2 ? cols[2] : '';
        final parts = name.split(' ');
        final fn = parts.isNotEmpty ? parts.first : name;
        final ln = parts.length > 1 ? parts.last : '';
        final username = _generateUsername(fn, ln);
        final password = _generatePassword();
        final authEmail = email.isNotEmpty && email.contains('@')
            ? email
            : '$username@impactconnect.app';

        FirebaseApp secondary;
        try {
          secondary = Firebase.app('BulkUpload');
        } catch (_) {
          secondary = await Firebase.initializeApp(
              name: 'BulkUpload', options: Firebase.app().options);
        }
        final cred = await FirebaseAuth.instanceFor(app: secondary)
            .createUserWithEmailAndPassword(
                email: authEmail, password: password);
        await FirebaseAuth.instanceFor(app: secondary).signOut();

        await FirebaseFirestore.instance
            .collection('members')
            .doc(cred.user!.uid)
            .set({
          'name': name,
          'email': authEmail,
          'username': username,
          'phoneNumber': phone,
          'createdAt': FieldValue.serverTimestamp(),
        });

        log.writeln('✅ $name → user: $username | pw: $password');
        count++;
        setState(() => _uploaded = count);
      } catch (e) {
        log.writeln('❌ ${cols[0]}: $e');
      }
    }

    setState(() {
      _uploading = false;
      _log = log.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bulk Upload via CSV',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'CSV format: Name, Email, Phone (header row skipped)',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Pick CSV & Upload'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white),
          ),
          if (_uploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: null),
            const SizedBox(height: 8),
            Text('Uploaded $_uploaded members…'),
          ],
          if (_log != null) ...[
            const SizedBox(height: 16),
            const Text('Upload Log:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_log!,
                  style: const TextStyle(
                      fontSize: 11, fontFamily: 'monospace')),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Password Reset for existing member ──────────────────────────────────────
class PasswordResetPanel extends StatefulWidget {
  final String? prefilledEmail;
  final String? prefilledName;
  const PasswordResetPanel({super.key, this.prefilledEmail, this.prefilledName});
  @override
  State<PasswordResetPanel> createState() => _PasswordResetPanelState();
}

class _PasswordResetPanelState extends State<PasswordResetPanel> {
  late final TextEditingController _emailCtrl;
  String? _newPassword;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl =
        TextEditingController(text: widget.prefilledEmail ?? '');
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _resetting = true);
    final newPw = _generatePassword();
    try {
      await FirebaseFirestore.instance.collection('admin_tasks').add({
        'type': 'password_reset',
        'email': email,
        'newPassword': newPw,
        'requestedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _newPassword = newPw;
        _resetting = false;
      });
    } catch (e) {
      setState(() => _resetting = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.prefilledName != null)
            Text('Resetting password for: ${widget.prefilledName}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Member Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          if (_resetting)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton.icon(
              onPressed: _resetPassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Generate New Password'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white),
            ),
          if (_newPassword != null) ...[
            const SizedBox(height: 14),
            credentialChip(context, 'New Password', _newPassword!),
            Text(
              'Share this with the member securely. '
              'A password reset task has been queued for the backend.',
              style:
                  TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
