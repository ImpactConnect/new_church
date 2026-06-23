import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PrayerTestimoniesManager extends StatelessWidget {
  const PrayerTestimoniesManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prayers & Testimonies',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: 'Testimonies (Pending & Approved)'),
                Tab(text: 'Prayer Requests'),
              ],
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: TabBarView(
                children: [
                  _TestimoniesTab(),
                  _PrayerRequestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimoniesTab extends StatelessWidget {
  const _TestimoniesTab();

  void _approveTestimony(BuildContext context, String docId, Map<String, dynamic> data) async {
    try {
      // 1. Add to public testimonies collection
      await FirebaseFirestore.instance.collection('testimonies').add({
        'testifier': data['userName'] ?? 'Anonymous',
        'testimony': data['content'] ?? '',
        'dateShared': FieldValue.serverTimestamp(),
        'imageUrl': null,
      });

      // 2. Mark as approved in prayer_testimonies collection
      await FirebaseFirestore.instance.collection('prayer_testimonies').doc(docId).update({
        'status': 'approved',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Testimony approved and published!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve testimony: $e')),
        );
      }
    }
  }

  void _editTestimony(BuildContext context, String docId, Map<String, dynamic> data) {
    final TextEditingController contentController = TextEditingController(text: data['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Testimony'),
        content: TextField(
          controller: contentController,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edit testimony content...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('prayer_testimonies').doc(docId).update({
                  'content': contentController.text.trim(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Testimony updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')),
                  );
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prayer_testimonies')
          .where('type', isEqualTo: 'testimony')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return const Center(child: Text('No testimonies found.'));
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final isApproved = data['status'] == 'approved';
              final createdAt = data['createdAt'] as Timestamp?;
              final dateStr = createdAt != null
                  ? DateFormat('MMM d, y • h:mm a').format(createdAt.toDate())
                  : 'Unknown Date';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                title: Row(
                  children: [
                    Text(data['userName'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isApproved ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isApproved ? 'Approved' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: isApproved ? Colors.green[700] : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(data['content'] ?? ''),
                  ],
                ),
                trailing: isApproved ? null : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit Testimony',
                      onPressed: () => _editTestimony(context, doc.id, data),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveTestimony(context, doc.id, data),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PrayerRequestsTab extends StatelessWidget {
  const _PrayerRequestsTab();

  void _markAsPrayed(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('prayer_testimonies').doc(docId).update({
        'status': 'prayed',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as prayed for!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prayer_testimonies')
          .where('type', isEqualTo: 'prayer')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return const Center(child: Text('No prayer requests found.'));
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final isPrayed = data['status'] == 'prayed';
              final createdAt = data['createdAt'] as Timestamp?;
              final dateStr = createdAt != null
                  ? DateFormat('MMM d, y • h:mm a').format(createdAt.toDate())
                  : 'Unknown Date';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                title: Row(
                  children: [
                    Text(data['userName'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (isPrayed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Prayed For',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Needs Prayer',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(data['content'] ?? ''),
                  ],
                ),
                trailing: isPrayed ? null : ElevatedButton.icon(
                  onPressed: () => _markAsPrayed(context, doc.id),
                  icon: const Icon(Icons.volunteer_activism, size: 16),
                  label: const Text('Mark Prayed For'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
