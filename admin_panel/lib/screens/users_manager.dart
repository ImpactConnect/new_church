import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersManager extends StatefulWidget {
  const UsersManager({super.key});

  @override
  State<UsersManager> createState() => _UsersManagerState();
}

class _UsersManagerState extends State<UsersManager> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isSaving = false;

  String _generateUsername(String name) {
    final parts = name.trim().toLowerCase().split(RegExp(r'\s+'));
    final fn = parts.isNotEmpty ? parts.first.replaceAll(RegExp(r'[^a-z]'), '') : 'user';
    final ln = parts.length > 1 ? parts.last.replaceAll(RegExp(r'[^a-z]'), '') : '';
    final num = Random().nextInt(900) + 100;
    return ln.isNotEmpty ? '$fn.$ln$num' : '$fn$num';
  }

  String _generatePassword({int length = 10}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#!';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _generateCredentials(DocumentSnapshot memberDoc) async {
    final data = memberDoc.data() as Map<String, dynamic>;
    final name = (data['name'] ?? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}').toString().trim();
    final existingUsername = data['username'] as String?;

    if (existingUsername != null && existingUsername.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name already has credentials (username: $existingUsername)')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    final username = _generateUsername(name).toLowerCase();
    final password = _generatePassword();
    final email = (data['email'] as String?)?.isNotEmpty == true
        ? (data['email'] as String).trim()
        : '$username@impactconnect.app';

    String? authUid;

    try {
      // Create Firebase Auth user using secondary app to avoid admin logout
      FirebaseApp secondary;
      try {
        secondary = Firebase.app('CredentialGeneration');
      } catch (_) {
        secondary = await Firebase.initializeApp(
            name: 'CredentialGeneration', options: Firebase.app().options);
      }

      try {
        final cred = await FirebaseAuth.instanceFor(app: secondary)
            .createUserWithEmailAndPassword(email: email, password: password);
        authUid = cred.user?.uid;
        await FirebaseAuth.instanceFor(app: secondary).signOut();
      } catch (authError) {
        print('Secondary Auth creation note (will queue admin task if needed): $authError');
        // Queue admin task to ensure Auth user password is set even if account already existed
        await FirebaseFirestore.instance.collection('admin_tasks').add({
          'type': 'create_community_user',
          'email': email,
          'username': username,
          'newPassword': password,
          'displayName': name,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }

      final updatePayload = <String, dynamic>{
        'username': username,
        'email': email,
        'role': 'member',
        'hasCredentials': true,
        'credentialGeneratedAt': FieldValue.serverTimestamp(),
        if (authUid != null) '_authUid': authUid,
      };

      // 1. Update the CMS branch member doc
      await FirebaseFirestore.instance
          .collection('branches')
          .doc('default-branch')
          .collection('members')
          .doc(memberDoc.id)
          .set(updatePayload, SetOptions(merge: true));

      // 2. Also update top-level members doc
      try {
        await FirebaseFirestore.instance
            .collection('members')
            .doc(memberDoc.id)
            .set(updatePayload, SetOptions(merge: true));
      } catch (e) {
        print('Top-level member update note: $e');
      }

      setState(() => _isSaving = false);

      if (mounted) {
        _showCredentialsDialog(context, name, username, password);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating credentials: $e')));
      }
    }
  }

  void _showCredentialsDialog(
      BuildContext context, String name, String username, String password) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('Credentials Generated',
                    style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For: $name',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 16),
            _copyableField(context, 'Username', username),
            const SizedBox(height: 8),
            _copyableField(context, 'Password', password),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Share these credentials with the member securely. They can use them to log into the mobile app community.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _copyableField(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
              child: Text(value,
                  style:
                      const TextStyle(fontFamily: 'monospace', fontSize: 13))),
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

  Future<void> _resetPassword(DocumentSnapshot memberDoc) async {
    final data = memberDoc.data() as Map<String, dynamic>;
    final name = (data['name'] ?? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}').toString().trim();
    final username = (data['username'] as String?)?.trim() ?? '';
    final email = (data['email'] as String?)?.trim().isNotEmpty == true
        ? (data['email'] as String).trim()
        : '$username@impactconnect.app';

    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No email found for password reset.')));
      return;
    }

    final newPassword = _generatePassword();

    try {
      // 1. Queue admin task for background Auth sync
      await FirebaseFirestore.instance.collection('admin_tasks').add({
        'type': 'password_reset',
        'email': email,
        'newPassword': newPassword,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // 2. Update Firestore documents
      final updateData = <String, dynamic>{
        'email': email,
        'hasCredentials': true,
      };

      await FirebaseFirestore.instance
          .collection('branches')
          .doc('default-branch')
          .collection('members')
          .doc(memberDoc.id)
          .set(updateData, SetOptions(merge: true));

      try {
        await FirebaseFirestore.instance
            .collection('members')
            .doc(memberDoc.id)
            .set(updateData, SetOptions(merge: true));
      } catch (e) {
        print('Top-level member update note: $e');
      }

      if (mounted) {
        _showCredentialsDialog(
            context, name, username, newPassword);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.manage_accounts, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Generate Login Credentials',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                      'Select a member from the CMS directory to generate their mobile app login credentials.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Search ──────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search members by name, email, or phone...',
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tabs: All Members / With Credentials ─────────────────
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.indigo,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.indigo,
                    tabs: const [
                      Tab(text: 'All CMS Members'),
                      Tab(text: 'With Credentials'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMembersList(showOnlyWithCredentials: false),
                        _buildMembersList(showOnlyWithCredentials: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList({required bool showOnlyWithCredentials}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('branches')
          .doc('default-branch')
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading members'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs.toList();

        // Sort by name
        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db = b.data() as Map<String, dynamic>;
          final na = (da['name'] ?? '${da['firstName'] ?? ''} ${da['lastName'] ?? ''}').toString().trim().toLowerCase();
          final nb = (db['name'] ?? '${db['firstName'] ?? ''} ${db['lastName'] ?? ''}').toString().trim().toLowerCase();
          return na.compareTo(nb);
        });

        // Filter by credentials status
        if (showOnlyWithCredentials) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final username = data['username'] as String?;
            return username != null && username.isNotEmpty;
          }).toList();
        }

        // Filter by search
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) ||
                email.contains(_searchQuery) ||
                phone.contains(_searchQuery);
          }).toList();
        }

        // Remove admin accounts from the list
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'] != 'admin' && data['roleId'] != 'admin';
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  showOnlyWithCredentials
                      ? 'No members with credentials yet'
                      : 'No members found',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            String name = (data['name'] as String?)?.trim() ?? '';
            if (name.isEmpty) {
              name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
            }
            if (name.isEmpty) name = 'Unknown';

            final email = data['email'] ?? '';
            final phone = data['phone'] ?? data['phoneNumber'] ?? '';
            final username = data['username'] as String?;
            final hasCredentials =
                username != null && username.isNotEmpty;
            final gender = data['gender'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      backgroundColor: hasCredentials
                          ? Colors.green[50]
                          : Colors.indigo[50],
                      child: hasCredentials
                          ? Icon(Icons.verified_user,
                              color: Colors.green[600], size: 20)
                          : Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ),
                              if (gender != null)
                                Icon(
                                  gender == 'male'
                                      ? Icons.male
                                      : Icons.female,
                                  size: 16,
                                  color: gender == 'male'
                                      ? Colors.blue[300]
                                      : Colors.pink[300],
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hasCredentials
                                ? 'Username: $username  ·  $email'
                                : '$email${phone.isNotEmpty ? '  ·  $phone' : ''}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Actions
                    if (hasCredentials)
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'reset') _resetPassword(doc);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'reset',
                              child: Row(children: [
                                Icon(Icons.lock_reset, size: 18),
                                SizedBox(width: 8),
                                Text('Reset Password'),
                              ])),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _generateCredentials(doc),
                        icon: const Icon(Icons.vpn_key, size: 16),
                        label: const Text('Generate',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
