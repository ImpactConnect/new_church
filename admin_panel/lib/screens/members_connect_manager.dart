import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'member_widgets.dart';
import '../utils/image_proxy.dart';
import 'prayer_testimonies_manager.dart';

class MembersConnectManager extends StatefulWidget {
  const MembersConnectManager({super.key});

  @override
  State<MembersConnectManager> createState() => _MembersConnectManagerState();
}

class _MembersConnectManagerState extends State<MembersConnectManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue[700],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue[700],
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.person_add_outlined), text: 'Members'),
              Tab(icon: Icon(Icons.group_outlined), text: 'Groups Manager'),
              Tab(icon: Icon(Icons.campaign_outlined), text: 'Announcements'),
              Tab(icon: Icon(Icons.volunteer_activism_outlined), text: 'Prayers & Testimonies'),
              Tab(icon: Icon(Icons.forum_outlined), text: 'Community Posts'),
              Tab(icon: Icon(Icons.person_pin), text: 'Pastor\'s Desk'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _MembersTab(),
              _GroupsManagerTab(),
              _AnnouncementsTab(),
              PrayerTestimoniesManager(),
              _CommunityPostsTab(),
              _PastorsDeskTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── MEMBERS TAB ─────────────────────────────────────────────────────────────
class _MembersTab extends StatefulWidget {
  const _MembersTab();
  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedGroupFilter = 'All';
  List<String> _churchGroups = [];
  StreamSubscription? _groupsSub;

  @override
  void initState() {
    super.initState();
    _groupsSub = FirebaseFirestore.instance.collection('church_groups').orderBy('name').snapshots().listen((snap) {
      if (mounted) {
        setState(() {
          _churchGroups = snap.docs.map((d) => d['name'] as String).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _groupsSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showMemberDetails(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (_) => _AdminMemberDetailsDialog(memberDoc: doc),
    );
  }

  void _showManageGroups(BuildContext context) {
    showDialog(context: context, builder: (_) => const _ManageGroupsDialog());
  }

  void _showManageOfficials(BuildContext context) {
    showDialog(context: context, builder: (_) => const _ManageOfficialsDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search members by name, email, phone, or group...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGroupFilter,
                    hint: const Text('Filter by Group'),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All Groups')),
                      if (_churchGroups.isNotEmpty)
                        const DropdownMenuItem(enabled: false, child: Text('── GROUPS ──', style: TextStyle(color: Colors.grey, fontSize: 10))),
                      ..._churchGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedGroupFilter = v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showManageGroups(context),
                icon: const Icon(Icons.group_work),
                label: const Text('Groups'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showManageOfficials(context),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Officials'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Members are managed via the CMS',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Member List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('branches').doc('default-branch').collection('members').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error loading members'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var docs = snapshot.data!.docs.toList();
              
              // Sort by name
              docs.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;
                final na = (da['name'] ?? '${da['firstName'] ?? ''} ${da['lastName'] ?? ''}').toString().trim().toLowerCase();
                final nb = (db['name'] ?? '${db['firstName'] ?? ''} ${db['lastName'] ?? ''}').toString().trim().toLowerCase();
                return na.compareTo(nb);
              });

              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString().toLowerCase();
                  final groupsList = data['churchGroups'] ?? (data['churchGroup'] != null && data['churchGroup'].toString().isNotEmpty ? [data['churchGroup']] : []);
                  final groupsStr = groupsList.join(', ').toLowerCase();
                  return name.contains(_searchQuery) ||
                         email.contains(_searchQuery) ||
                         phone.contains(_searchQuery) ||
                         groupsStr.contains(_searchQuery);
                }).toList();
              }

              if (_selectedGroupFilter != 'All') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final groupsList = data['churchGroups'] ?? (data['churchGroup'] != null && data['churchGroup'].toString().isNotEmpty ? [data['churchGroup']] : []);
                  return groupsList.contains(_selectedGroupFilter);
                }).toList();
              }

              if (docs.isEmpty) {
                return const Center(child: Text('No members found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  String name = (data['name'] as String?)?.trim() ?? '';
                  if (name.isEmpty) {
                    name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                  }
                  if (name.isEmpty) name = 'Unknown';

                  final email = data['email'] ?? '—';
                  final phone = data['phone'] ?? data['phoneNumber'] ?? '';
                  final groupsList = data['churchGroups'] ?? (data['churchGroup'] != null && data['churchGroup'].toString().isNotEmpty ? [data['churchGroup']] : []);
                  final group = groupsList.join(', ');
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _showMemberDetails(context, docs[i]),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.indigo[50],
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$email${phone.isNotEmpty ? '  ·  $phone' : ''}${group.isNotEmpty ? '  ·  $group' : ''}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── ADMIN MEMBER DETAILS DIALOG ─────────────────────────────────────────────
class _AdminMemberDetailsDialog extends StatefulWidget {
  final DocumentSnapshot memberDoc;
  const _AdminMemberDetailsDialog({required this.memberDoc});

  @override
  State<_AdminMemberDetailsDialog> createState() => _AdminMemberDetailsDialogState();
}

class _AdminMemberDetailsDialogState extends State<_AdminMemberDetailsDialog> {
  bool _isEditing = false;
  bool _saving = false;
  
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _occupationCtrl;
  List<String> _selectedGroups = [];
  late TextEditingController _genderCtrl;
  late TextEditingController _maritalStatusCtrl;
  late TextEditingController _spouseNameCtrl;
  late TextEditingController _schoolNameCtrl;
  late TextEditingController _stateOfOriginCtrl;

  @override
  void initState() {
    super.initState();
    final data = widget.memberDoc.data() as Map<String, dynamic>? ?? {};
    String name = (data['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
    }
    _nameCtrl = TextEditingController(text: name);
    _phoneCtrl = TextEditingController(text: data['phone'] ?? data['phoneNumber'] ?? '');
    _addressCtrl = TextEditingController(text: data['residentAddress'] ?? data['address'] ?? '');
    _occupationCtrl = TextEditingController(text: data['profession'] ?? data['occupation'] ?? '');
    if (data['churchGroups'] != null) {
      _selectedGroups = List<String>.from(data['churchGroups']);
    } else if (data['departmentIds'] != null) {
      _selectedGroups = List<String>.from(data['departmentIds']);
    } else if (data['churchGroup'] != null && data['churchGroup'].toString().isNotEmpty) {
      _selectedGroups = [data['churchGroup']];
    }
    _genderCtrl = TextEditingController(text: data['gender'] ?? '');
    _maritalStatusCtrl = TextEditingController(text: data['maritalStatus'] ?? '');
    _spouseNameCtrl = TextEditingController(text: data['spouseName'] ?? '');
    _schoolNameCtrl = TextEditingController(text: data['schoolName'] ?? '');
    _stateOfOriginCtrl = TextEditingController(text: data['stateOfOrigin'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _occupationCtrl.dispose();
    _genderCtrl.dispose();
    _maritalStatusCtrl.dispose();
    _spouseNameCtrl.dispose();
    _schoolNameCtrl.dispose();
    _stateOfOriginCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      final parts = _nameCtrl.text.trim().split(RegExp(r'\s+'));
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      await FirebaseFirestore.instance.collection('branches').doc('default-branch').collection('members').doc(widget.memberDoc.id).update({
        'name': _nameCtrl.text.trim(),
        'firstName': firstName,
        'lastName': lastName,
        'phone': _phoneCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'residentAddress': _addressCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'profession': _occupationCtrl.text.trim(),
        'occupation': _occupationCtrl.text.trim(),
        'churchGroups': _selectedGroups,
        'gender': _genderCtrl.text.trim(),
        'maritalStatus': _maritalStatusCtrl.text.trim(),
        'spouseName': _spouseNameCtrl.text.trim(),
        'schoolName': _schoolNameCtrl.text.trim(),
        'stateOfOrigin': _stateOfOriginCtrl.text.trim(),
      });

      // Sync member's group chat enrollments
      try {
        final allGroups = await FirebaseFirestore.instance.collection('community_groups').get();
        for (final doc in allGroups.docs) {
          final groupName = doc['name'];
          if (_selectedGroups.contains(groupName)) {
            await doc.reference.update({'members': FieldValue.arrayUnion([widget.memberDoc.id])});
          } else {
            await doc.reference.update({'members': FieldValue.arrayRemove([widget.memberDoc.id])});
          }
        }
      } catch (e) {
        print('Error syncing group membership: $e');
      }

      setState(() {
        _isEditing = false;
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details updated')));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Remove "${_nameCtrl.text}" from the database entirely?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // close alert
              Navigator.pop(context); // close details dialog
              await FirebaseFirestore.instance.collection('branches').doc('default-branch').collection('members').doc(widget.memberDoc.id).delete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildChurchGroupDropdown() {
    if (!_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Church Groups', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 2),
            Text(_selectedGroups.isNotEmpty ? _selectedGroups.join(', ') : '—', style: const TextStyle(fontSize: 14)),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              Text('Church Groups', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
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
                        if (selected) _selectedGroups.add(g);
                        else _selectedGroups.remove(g);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    if (!_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 2),
            Text(controller.text.isNotEmpty ? controller.text : '—', style: const TextStyle(fontSize: 14)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(value.isNotEmpty ? value : '—', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.memberDoc.data() as Map<String, dynamic>? ?? {};
    final email = data['email'] ?? '';
    final username = data['username'] ?? '';
    final birthDateTs = data['birthDate'] as Timestamp?;
    final birthDateStr = birthDateTs != null 
        ? '${birthDateTs.toDate().day}/${birthDateTs.toDate().month}/${birthDateTs.toDate().year}' 
        : 'Unknown';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.indigo,
                    child: Text(
                      _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Member Details', style: TextStyle(fontSize: 12, color: Colors.indigo[300])),
                        Text(_nameCtrl.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Details
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Profile Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              if (!_isEditing)
                                TextButton.icon(
                                  onPressed: () => setState(() => _isEditing = true),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                )
                              else
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = false;
                                          _nameCtrl.text = data['name'] ?? '';
                                          _phoneCtrl.text = data['phoneNumber'] ?? '';
                                          _addressCtrl.text = data['address'] ?? '';
                                          _occupationCtrl.text = data['occupation'] ?? '';
                                          if (data['churchGroups'] != null) {
                                            _selectedGroups = List<String>.from(data['churchGroups']);
                                          } else if (data['churchGroup'] != null && data['churchGroup'].toString().isNotEmpty) {
                                            _selectedGroups = [data['churchGroup']];
                                          } else {
                                            _selectedGroups = [];
                                          }
                                          _genderCtrl.text = data['gender'] ?? '';
                                          _maritalStatusCtrl.text = data['maritalStatus'] ?? '';
                                          _spouseNameCtrl.text = data['spouseName'] ?? '';
                                          _schoolNameCtrl.text = data['schoolName'] ?? '';
                                          _stateOfOriginCtrl.text = data['stateOfOrigin'] ?? '';
                                        });
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _saving ? null : _saveChanges,
                                      child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextField('Full Name', _nameCtrl),
                                    _buildTextField('Phone Number', _phoneCtrl),
                                    _buildTextField('Gender', _genderCtrl),
                                    _buildReadOnlyField('Date of Birth', birthDateStr),
                                    _buildTextField('State of Origin', _stateOfOriginCtrl),
                                    _buildTextField('Address', _addressCtrl),
                                  ],
                                )
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextField('Occupation', _occupationCtrl),
                                    _buildTextField('School Name (If Student)', _schoolNameCtrl),
                                    _buildChurchGroupDropdown(),
                                    _buildTextField('Marital Status', _maritalStatusCtrl),
                                    _buildTextField('Spouse Name', _spouseNameCtrl),
                                  ],
                                )
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          const Text('System Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text('Username: $username', style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Email: $email', style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 24),
                          
                          OutlinedButton.icon(
                            onPressed: _confirmDelete,
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('Delete Member', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Right Column: Password Reset
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                        ),
                        child: PasswordResetPanel(
                          prefilledEmail: email,
                          prefilledName: _nameCtrl.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MANAGE GROUPS DIALOG ──────────────────────────────────────────────────────
class _ManageGroupsDialog extends StatefulWidget {
  const _ManageGroupsDialog();
  @override
  State<_ManageGroupsDialog> createState() => _ManageGroupsDialogState();
}

class _ManageGroupsDialogState extends State<_ManageGroupsDialog> {
  final _ctrl = TextEditingController();

  Future<void> _addGroup() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    await FirebaseFirestore.instance.collection('church_groups').add({'name': name});
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Church Groups / Units', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(labelText: 'New Group Name', isDense: true, border: OutlineInputBorder()),
                    onSubmitted: (_) => _addGroup(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addGroup, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('church_groups').orderBy('name').snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('No groups added yet.'));
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(docs[i]['name'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance.collection('church_groups').doc(docs[i].id).delete(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MANAGE OFFICIALS DIALOG ───────────────────────────────────────────────────
class _ManageOfficialsDialog extends StatefulWidget {
  const _ManageOfficialsDialog();
  @override
  State<_ManageOfficialsDialog> createState() => _ManageOfficialsDialogState();
}

class _ManageOfficialsDialogState extends State<_ManageOfficialsDialog> {
  final _roleCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  
  Map<String, dynamic>? _selectedMember;
  String? _selectedMemberId;

  Future<void> _addOfficial() async {
    if (_selectedMember == null || _roleCtrl.text.trim().isEmpty) return;
    
    await FirebaseFirestore.instance.collection('church_officials').doc(_selectedMemberId).set({
      'memberId': _selectedMemberId,
      'name': _selectedMember!['name'],
      'phoneNumber': _selectedMember!['phoneNumber'],
      'role': _roleCtrl.text.trim(),
      'department': _deptCtrl.text.trim().isNotEmpty ? _deptCtrl.text.trim() : ((_selectedMember!['churchGroups'] ?? []).join(', ')),
      'addedAt': FieldValue.serverTimestamp(),
    });
    
    setState(() {
      _selectedMember = null;
      _selectedMemberId = null;
    });
    _roleCtrl.clear();
    _deptCtrl.clear();
  }

  void _pickMember() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Member'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('branches').doc('default-branch').collection('members').snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  String name = (data['name'] as String?)?.trim() ?? '';
                  if (name.isEmpty) {
                    name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                  }
                  if (name.isEmpty) name = 'Unknown';
                  final phone = data['phone'] ?? data['phoneNumber'] ?? '';

                  return ListTile(
                    title: Text(name),
                    subtitle: Text(phone),
                    onTap: () {
                      setState(() {
                        _selectedMember = data;
                        _selectedMemberId = docs[i].id;
                        _deptCtrl.text = (data['churchGroups'] ?? []).join(', ');
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Church Officials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Official', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickMember,
                          child: Text(_selectedMember == null ? 'Select Member' : _selectedMember!['name']),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _roleCtrl, decoration: const InputDecoration(labelText: 'Role', isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department', isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(onPressed: _addOfficial, child: const Text('Add Official')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('church_officials').orderBy('addedAt').snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('No officials added yet.'));
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${data['role']} • ${data['department']} • ${data['phoneNumber']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => FirebaseFirestore.instance.collection('church_officials').doc(docs[i].id).delete(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ANNOUNCEMENTS TAB ───────────────────────────────────────────────────────
class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();
  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  Future<void> _post() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await FirebaseFirestore.instance.collection('announcements').add({
      'message': _ctrl.text.trim(),
      'timePosted': FieldValue.serverTimestamp(),
    });
    _ctrl.clear();
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 340,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Create Announcement',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true),
                ),
                const SizedBox(height: 14),
                _saving
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _post,
                        icon: const Icon(Icons.send),
                        label: const Text('Post'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46)),
                      ),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('timePosted', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('No announcements yet.'));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.announcement_outlined,
                          color: Colors.blue),
                      title: Text(d['message'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance
                            .collection('announcements')
                            .doc(docs[i].id)
                            .delete(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}


// ─── COMMUNITY POSTS TAB ─────────────────────────────────────────────────────
class _CommunityPostsTab extends StatelessWidget {
  const _CommunityPostsTab();

  Future<void> _deletePost(String docId, Map<String, dynamic> data, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // If it has images, we might want to delete them from storage too.
      // But for now, we just delete the document to regulate.
      await FirebaseFirestore.instance.collection('community_posts').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
             return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No community posts yet.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final title = d['title'] ?? 'No Title';
              final author = d['author_name'] ?? 'Unknown Author';
              final type = d['post_type'] ?? 'post';
              final flagged = d['flagged'] == true;

              IconData typeIcon = Icons.article_outlined;
              Color typeColor = Colors.blueGrey;
              if (type == 'question') {
                typeIcon = Icons.help_outline;
                typeColor = Colors.orange;
              } else if (type == 'article') {
                typeIcon = Icons.library_books;
                typeColor = Colors.indigo;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: flagged ? Colors.red[50] : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: typeColor.withValues(alpha: 0.1),
                    child: Icon(typeIcon, color: typeColor),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'By $author • ${d['likes_count'] ?? 0} likes • ${d['comments_count'] ?? 0} comments',
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: Icon(
                        flagged ? Icons.flag : Icons.flag_outlined,
                        color: flagged ? Colors.red : Colors.grey,
                      ),
                      tooltip: flagged ? 'Unflag' : 'Flag',
                      onPressed: () => FirebaseFirestore.instance
                          .collection('community_posts')
                          .doc(docs[i].id)
                          .update({'flagged': !flagged}),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete Post',
                      onPressed: () => _deletePost(docs[i].id, d, context),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── PASTOR'S DESK TAB ───────────────────────────────────────────────────────
class _PastorsDeskTab extends StatefulWidget {
  const _PastorsDeskTab();

  @override
  State<_PastorsDeskTab> createState() => _PastorsDeskTabState();
}

class _PastorsDeskTabState extends State<_PastorsDeskTab> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _existingImageUrl;
  String? _docId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('ministers_content')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = doc.data();
        setState(() {
          _docId = doc.id;
          _titleCtrl.text = data['title'] ?? '';
          _contentCtrl.text = data['content'] ?? '';
          _existingImageUrl = data['imageUrl'];
          _imageUrlCtrl.text = _existingImageUrl ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageFileName = result.files.first.name;
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isSaving = true);

    try {
      String? imageUrl = _imageUrlCtrl.text.trim();
      if (_imageBytes != null) {
        final imageRef = FirebaseStorage.instance.ref('pastors_desk/${DateTime.now().millisecondsSinceEpoch}_$_imageFileName');
        await imageRef.putData(_imageBytes!);
        imageUrl = await imageRef.getDownloadURL();
      }

      final data = {
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'imageUrl': imageUrl.isEmpty ? null : imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_docId != null) {
        await FirebaseFirestore.instance.collection('ministers_content').doc(_docId).update(data);
      } else {
        final docRef = await FirebaseFirestore.instance.collection('ministers_content').add(data);
        _docId = docRef.id;
      }
      
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!')));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage Pastor\'s Corner', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 15,
                    decoration: const InputDecoration(labelText: 'Content/Writeup', border: OutlineInputBorder(), alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _imageUrlCtrl,
                    decoration: const InputDecoration(labelText: 'Image URL (optional)', border: OutlineInputBorder()),
                    onChanged: (val) {
                      setState(() {
                        _existingImageUrl = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Upload Pastor Image'),
                      ),
                      const SizedBox(width: 16),
                      if (_imageBytes != null)
                        Expanded(child: Image.memory(_imageBytes!, height: 100, fit: BoxFit.contain, alignment: Alignment.centerLeft))
                      else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                        Expanded(
                          child: Image.network(
                            ImageProxy.proxy(_existingImageUrl!),
                            height: 100,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (context, error, stackTrace) => const Text('Error loading image, or image not found.'),
                          ),
                        )
                      else
                        const Expanded(child: Text('No image selected')),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── GROUPS MANAGER TAB ──────────────────────────────────────────────────────


class _GroupsManagerTab extends StatefulWidget {
  const _GroupsManagerTab();

  @override
  State<_GroupsManagerTab> createState() => _GroupsManagerTabState();
}

class _GroupsManagerTabState extends State<_GroupsManagerTab> {
  void _showGroupDetailsDialog(String groupId, DocumentSnapshot groupDoc) {
    showDialog(
      context: context,
      builder: (_) => _AdminGroupDetailsDialog(groupId: groupId, groupDoc: groupDoc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Communication Groups',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                      'Groups and member assignments are managed by the Secretary in the CMS.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Managed by Secretary in CMS',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Groups List from CMS Departments
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('branches')
                  .doc('default-branch')
                  .collection('departments')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('No groups created by Secretary yet.',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text(
                          'The Secretary can create departments and add members in the CMS.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 190,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final groupId = docs[i].id;
                    final name = d['name'] ?? 'Unnamed Group';
                    final deptType = d['departmentType'] ?? 'Department';
                    final imageUrl = d['imageUrl'] ?? d['photoUrl'] ?? '';
                    final memberIds = List<String>.from(d['memberIds'] ?? d['members'] ?? []);
                    final leaderName = d['headMemberName'] ?? 'No leader assigned';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: InkWell(
                        onTap: () => _showGroupDetailsDialog(groupId, docs[i]),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundImage: imageUrl.isNotEmpty
                                        ? NetworkImage(ImageProxy.proxy(imageUrl))
                                        : null,
                                    backgroundColor: Colors.indigo[50],
                                    child: imageUrl.isEmpty
                                        ? Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : 'G',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo,
                                                fontSize: 20))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text(deptType,
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('${memberIds.length} members',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Leader: $leaderName',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'View Details & Chat →',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.indigo[700],
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ADMIN GROUP DETAILS & CONVERSATION DIALOG ────────────────────────────────
class _AdminGroupDetailsDialog extends StatefulWidget {
  final String groupId;
  final DocumentSnapshot groupDoc;

  const _AdminGroupDetailsDialog(
      {required this.groupId, required this.groupDoc});

  @override
  State<_AdminGroupDetailsDialog> createState() =>
      _AdminGroupDetailsDialogState();
}

class _AdminGroupDetailsDialogState extends State<_AdminGroupDetailsDialog> {
  bool _uploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    try {
      FilePickerResult? result =
          await FilePicker.pickFiles(type: FileType.image, withData: true);
      if (result == null || result.files.isEmpty) return;

      setState(() => _uploadingImage = true);

      final file = result.files.first;
      final ref = FirebaseStorage.instance.ref(
          'group_photos/${DateTime.now().millisecondsSinceEpoch}_${file.name}');

      final task = await ref.putData(
          file.bytes!, SettableMetadata(contentType: 'image/jpeg'));
      final url = await task.ref.getDownloadURL();

      // Update CMS department doc
      await FirebaseFirestore.instance
          .collection('branches')
          .doc('default-branch')
          .collection('departments')
          .doc(widget.groupId)
          .update({
        'imageUrl': url,
        'photoUrl': url,
      });

      // Update community_groups doc if present
      try {
        await FirebaseFirestore.instance
            .collection('community_groups')
            .doc(widget.groupId)
            .set({'imageUrl': url}, SetOptions(merge: true));
      } catch (_) {}

      setState(() => _uploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group image updated!')));
      }
    } catch (e) {
      setState(() => _uploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _removeMemberFromGroup(
      String memberId, String memberName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
            'Remove "$memberName" from this group discussion?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Remove from department doc
      await FirebaseFirestore.instance
          .collection('branches')
          .doc('default-branch')
          .collection('departments')
          .doc(widget.groupId)
          .update({
        'memberIds': FieldValue.arrayRemove([memberId]),
      });

      // 2. Remove department from member doc
      await FirebaseFirestore.instance
          .collection('branches')
          .doc('default-branch')
          .collection('members')
          .doc(memberId)
          .update({
        'departmentIds': FieldValue.arrayRemove([widget.groupId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$memberName removed from group.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error removing member: $e')));
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('group_messages')
          .doc(messageId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Message deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _clearAllMessages() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Conversations'),
        content: const Text(
            'Are you sure you want to delete ALL messages in this group discussion? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final messagesSnap = await FirebaseFirestore.instance
          .collection('group_messages')
          .where('groupId', isEqualTo: widget.groupId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in messagesSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All conversation messages cleared.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('branches')
          .doc('default-branch')
          .collection('departments')
          .doc(widget.groupId)
          .snapshots(),
      builder: (context, snap) {
        final data = (snap.data?.data() as Map<String, dynamic>?) ??
            (widget.groupDoc.data() as Map<String, dynamic>? ?? {});

        final name = data['name'] ?? 'Unnamed Group';
        final deptType = data['departmentType'] ?? 'Department';
        final imageUrl = data['imageUrl'] ?? data['photoUrl'] ?? '';
        final leaderName = data['headMemberName'] ?? 'No leader assigned';
        final memberIds =
            List<String>.from(data['memberIds'] ?? data['members'] ?? []);

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 1000,
            height: 720,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dialog Header ───────────────────────────────────────
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(ImageProxy.proxy(imageUrl))
                              : null,
                          backgroundColor: Colors.indigo[50],
                          child: imageUrl.isEmpty
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'G',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _uploadingImage ? null : _pickAndUploadImage,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.indigo,
                              child: _uploadingImage
                                  ? const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.camera_alt,
                                      size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('$deptType  ·  Leader: $leaderName',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickAndUploadImage,
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text('Change Group Image'),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // ── Body Split View: Members (Left) | Chat Messages (Right) ─────
                Expanded(
                  child: Row(
                    children: [
                      // ── LEFT: Members List ──────────────────────────────────
                      Expanded(
                        flex: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Members (${memberIds.length})',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    const Text('Secretary-assigned',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: memberIds.isEmpty
                                    ? const Center(
                                        child: Text(
                                            'No members assigned to this group yet.',
                                            style:
                                                TextStyle(color: Colors.grey)),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(8),
                                        itemCount: memberIds.length,
                                        itemBuilder: (context, idx) {
                                          final mId = memberIds[idx];
                                          return StreamBuilder<DocumentSnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('branches')
                                                .doc('default-branch')
                                                .collection('members')
                                                .doc(mId)
                                                .snapshots(),
                                            builder: (context, mSnap) {
                                              final mData = mSnap.data?.data()
                                                  as Map<String, dynamic>? ?? {};
                                              String mName =
                                                  (mData['name'] as String?)?.trim() ?? '';
                                              if (mName.isEmpty) {
                                                mName =
                                                    '${mData['firstName'] ?? ''} ${mData['lastName'] ?? ''}'
                                                        .trim();
                                              }
                                              if (mName.isEmpty) mName = 'Member ($mId)';

                                              final phone = mData['phone'] ??
                                                  mData['phoneNumber'] ??
                                                  '';

                                              return Card(
                                                margin: const EdgeInsets.only(
                                                    bottom: 6),
                                                child: ListTile(
                                                  dense: true,
                                                  leading: CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: Colors.indigo[50],
                                                    child: Text(
                                                      mName.isNotEmpty
                                                          ? mName[0].toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                          color: Colors.indigo,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  title: Text(mName,
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13)),
                                                  subtitle: phone.isNotEmpty
                                                      ? Text(phone,
                                                          style: const TextStyle(
                                                              fontSize: 11))
                                                      : null,
                                                  trailing: IconButton(
                                                    icon: const Icon(
                                                        Icons.remove_circle_outline,
                                                        color: Colors.red,
                                                        size: 20),
                                                    tooltip:
                                                        'Remove from group discussion',
                                                    onPressed: () =>
                                                        _removeMemberFromGroup(
                                                            mId, mName),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // ── RIGHT: Group Chat Conversation Viewer ───────────────
                      Expanded(
                        flex: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.forum_outlined,
                                            size: 18, color: Colors.indigo),
                                        SizedBox(width: 8),
                                        Text('Group Conversation',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: _clearAllMessages,
                                      icon: const Icon(Icons.delete_sweep,
                                          size: 16, color: Colors.red),
                                      label: const Text('Clear Conversation',
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('group_messages')
                                      .where('groupId', isEqualTo: widget.groupId)
                                      .orderBy('timestamp', descending: true)
                                      .snapshots(),
                                  builder: (context, msgSnap) {
                                    if (msgSnap.hasError) {
                                      return Center(
                                          child: Text('Error: ${msgSnap.error}'));
                                    }
                                    if (!msgSnap.hasData) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }

                                    final messages = msgSnap.data!.docs;

                                    if (messages.isEmpty) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.chat_bubble_outline,
                                                size: 48,
                                                color: Colors.grey[300]),
                                            const SizedBox(height: 12),
                                            const Text(
                                                'No messages in this group discussion yet.',
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: messages.length,
                                      itemBuilder: (context, idx) {
                                        final msgDoc = messages[idx];
                                        final msgData = msgDoc.data()
                                            as Map<String, dynamic>;
                                        final senderName =
                                            msgData['senderName'] ?? 'Unknown';
                                        final messageText =
                                            msgData['message'] ?? '';
                                        final fileUrl =
                                            msgData['fileUrl'] as String?;
                                        final ts =
                                            msgData['timestamp'] as Timestamp?;
                                        final timeStr = ts != null
                                            ? '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
                                            : '';

                                        return Card(
                                          margin: const EdgeInsets.only(
                                              bottom: 8),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor:
                                                      Colors.indigo[100],
                                                  child: Text(
                                                    senderName.isNotEmpty
                                                        ? senderName[0]
                                                            .toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.indigo,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(senderName,
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12)),
                                                          Text(timeStr,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey[500],
                                                                  fontSize: 10)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      if (messageText.isNotEmpty)
                                                        Text(messageText,
                                                            style: const TextStyle(
                                                                fontSize: 13)),
                                                      if (fileUrl != null &&
                                                          fileUrl.isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: 4),
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          child: Image.network(
                                                            ImageProxy.proxy(
                                                                fileUrl),
                                                            height: 120,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 18,
                                                      color: Colors.red),
                                                  tooltip: 'Delete Message',
                                                  onPressed: () =>
                                                      _deleteMessage(msgDoc.id),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


