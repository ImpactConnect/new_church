import 'dart:html' as html;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      final memberData = <String, dynamic>{
        'name': fullName,
        'email': email,
        'username': username.toLowerCase(),
        'hasCredentials': true,
        'role': 'member',
        '_authUid': uid,
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
      };

      // Write to top-level members collection
      await FirebaseFirestore.instance.collection('members').doc(uid).set(memberData);

      // Write to CMS branch members collection
      try {
        await FirebaseFirestore.instance
            .collection('branches')
            .doc('default-branch')
            .collection('members')
            .doc(uid)
            .set(memberData);
      } catch (e) {
        print('CMS branch member save error: $e');
      }

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

        final csvMemberData = <String, dynamic>{
          'name': name,
          'email': authEmail,
          'username': username.toLowerCase(),
          'hasCredentials': true,
          'role': 'member',
          '_authUid': cred.user!.uid,
          'phoneNumber': phone,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('members')
            .doc(cred.user!.uid)
            .set(csvMemberData);

        try {
          await FirebaseFirestore.instance
              .collection('branches')
              .doc('default-branch')
              .collection('members')
              .doc(cred.user!.uid)
              .set(csvMemberData);
        } catch (e) {
          print('CMS branch member CSV upload note: $e');
        }

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

// ── Mobile App Community Credentials & Password Reset Panel ───────────────────
class PasswordResetPanel extends StatefulWidget {
  final DocumentSnapshot? memberDoc;
  final String? prefilledEmail;
  final String? prefilledName;
  final VoidCallback? onCredentialsUpdated;

  const PasswordResetPanel({
    super.key,
    this.memberDoc,
    this.prefilledEmail,
    this.prefilledName,
    this.onCredentialsUpdated,
  });

  @override
  State<PasswordResetPanel> createState() => _PasswordResetPanelState();
}

class _PasswordResetPanelState extends State<PasswordResetPanel> {
  bool _isLoading = false;
  String? _errorMsg;
  String? _existingUsername;
  String? _existingEmail;
  late String _memberName;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final data = widget.memberDoc?.data() as Map<String, dynamic>? ?? {};

    _memberName = widget.prefilledName ?? (data['name'] as String?)?.trim() ?? '';
    if (_memberName.isEmpty) {
      final fn = (data['firstName'] as String?)?.trim() ?? '';
      final ln = (data['lastName'] as String?)?.trim() ?? '';
      _memberName = '$fn $ln'.trim();
    }
    if (_memberName.isEmpty) _memberName = 'Member';

    _existingUsername = (data['username'] as String?)?.trim();
    if (_existingUsername != null && _existingUsername!.isEmpty) {
      _existingUsername = null;
    }

    _existingEmail = (data['email'] as String?)?.trim() ?? widget.prefilledEmail?.trim();
    if (_existingEmail != null && _existingEmail!.isEmpty) {
      _existingEmail = null;
    }
  }

  Future<void> _generateLoginDetails() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final parts = _memberName.split(RegExp(r'\s+'));
    final fn = parts.isNotEmpty ? parts.first : '';
    final ln = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final generatedUsername = _generateUsername(fn, ln);
    final email = (_existingEmail != null && _existingEmail!.isNotEmpty)
        ? _existingEmail!
        : '$generatedUsername@impactconnect.app';
    final generatedPassword = _generatePassword();

    try {
      // 1. Create account in Auth via secondary app
      FirebaseApp? tempApp;
      try {
        final appName = 'TempMemberAuth_${DateTime.now().millisecondsSinceEpoch}';
        tempApp = await Firebase.initializeApp(
          name: appName,
          options: Firebase.app().options,
        );
        final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
        final userCred = await tempAuth.createUserWithEmailAndPassword(
          email: email,
          password: generatedPassword,
        );
        if (userCred.user != null) {
          await userCred.user!.updateDisplayName(_memberName);
        }
        await tempAuth.signOut();
      } catch (e) {
        print('Secondary Auth creation note: $e');
      } finally {
        await tempApp?.delete();
      }

      // 2. Queue admin task
      await FirebaseFirestore.instance.collection('admin_tasks').add({
        'type': 'create_community_user',
        'email': email,
        'username': generatedUsername,
        'newPassword': generatedPassword,
        'displayName': _memberName,
        'requestedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update member document in Firestore (both CMS branch & top-level)
      if (widget.memberDoc != null) {
        final updatePayload = <String, dynamic>{
          'username': generatedUsername.toLowerCase(),
          'email': email,
          'hasCredentials': true,
          'role': 'member',
          'communityAccountCreated': true,
          'hasCommunityAccount': true,
        };

        final docRef = widget.memberDoc!.reference;
        await docRef.set(updatePayload, SetOptions(merge: true));

        try {
          await FirebaseFirestore.instance
              .collection('members')
              .doc(widget.memberDoc!.id)
              .set(updatePayload, SetOptions(merge: true));
        } catch (e) {
          print('Top-level member update note: $e');
        }
      }

      setState(() {
        _existingUsername = generatedUsername;
        _existingEmail = email;
        _isLoading = false;
      });

      widget.onCredentialsUpdated?.call();

      // Show generated credentials modal
      if (mounted) {
        _showGeneratedCredentialsDialog(
          title: '✓ App Login Credentials Generated',
          username: generatedUsername,
          email: email,
          password: generatedPassword,
          subtitle: 'Credentials generated successfully! Copy and share these login details with $_memberName.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Error generating login details: $e';
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _existingEmail ?? '';
    if (email.isEmpty) {
      setState(() => _errorMsg = 'Email is required to reset password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final newPw = _generatePassword();

    try {
      await FirebaseFirestore.instance.collection('admin_tasks').add({
        'type': 'password_reset',
        'email': email,
        'newPassword': newPw,
        'requestedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showGeneratedCredentialsDialog(
          title: '🔑 New Password Generated',
          username: _existingUsername ?? '—',
          email: email,
          password: newPw,
          subtitle: 'A new password has been set for $_memberName. Copy and share it with the member.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Error resetting password: $e';
      });
    }
  }

  void _showGeneratedCredentialsDialog({
    required String title,
    required String username,
    required String email,
    required String password,
    required String subtitle,
  }) {
    final allCredsText = 'Username: $username\nEmail: $email\nPassword: $password';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.vpn_key_outlined, color: Colors.indigo, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 16),
              credentialChip(context, 'Username', username),
              credentialChip(context, 'Email', email),
              credentialChip(context, 'Password', password),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: allCredsText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ All credentials copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy_all, size: 18),
                  label: const Text('Copy All Details'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.indigo[300]!),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingAccount = _existingUsername != null && _existingUsername!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Row(
            children: [
              Icon(
                hasExistingAccount ? Icons.verified_user_rounded : Icons.app_registration_rounded,
                color: hasExistingAccount ? Colors.green[700] : Colors.indigo[700],
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasExistingAccount ? 'Community Access' : 'App Access Status',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasExistingAccount ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: hasExistingAccount ? Colors.green[300]! : Colors.orange[300]!),
                ),
                child: Text(
                  hasExistingAccount ? 'Active' : 'No Credentials',
                  style: TextStyle(
                    color: hasExistingAccount ? Colors.green[800] : Colors.orange[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],

          // ── CASE 1: MEMBER HAS NO APP CREDENTIALS YET ──────────────────────────
          if (!hasExistingAccount) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo[50]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.indigo[700]),
                      const SizedBox(width: 8),
                      Text(
                        'No Mobile Login Generated',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo[900]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_memberName does not have mobile app community login details. Click below to generate login credentials.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _generateLoginDetails,
                icon: const Icon(Icons.vpn_key_outlined, size: 18),
                label: const Text('Generate Login Details'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.indigo[700],
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ]

          // ── CASE 2: MEMBER ALREADY HAS APP CREDENTIALS ────────────────────────
          else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Username:', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _existingUsername!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                  if (_existingEmail != null && _existingEmail!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Login Email:', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _existingEmail!,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _resetPassword,
                icon: const Icon(Icons.lock_reset, size: 20),
                label: const Text('Reset Password'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
