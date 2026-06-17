import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/image_proxy.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Welcome back, Admin!',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _StatCard(
                label: 'Total Sermons',
                color: Colors.orange,
                icon: Icons.audiotrack,
                collection: 'sermons',
              ),
              const SizedBox(width: 16),
              _StatCard(
                label: 'Members',
                color: Colors.blue,
                icon: Icons.people,
                collection: 'members',
              ),
              const SizedBox(width: 16),
              _StatCard(
                label: 'Upcoming Events',
                color: Colors.green,
                icon: Icons.event,
                collection: 'events',
              ),
              const SizedBox(width: 16),
              _StatCard(
                label: 'Devotionals',
                color: Colors.purple,
                icon: Icons.book,
                collection: 'devotionals',
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Stream Status
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Live Stream Status',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('live_streams')
                              .limit(1)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text('No stream configured.');
                            }
                            final data = snapshot.data!.docs.first.data()
                                as Map<String, dynamic>;
                            final isLive = data['isLive'] ?? false;
                            final platform = data['platform'] ?? 'N/A';
                            final title = data['title'] ?? 'Untitled';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isLive
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isLive ? 'LIVE NOW' : 'Offline',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isLive
                                              ? Colors.red
                                              : Colors.grey)),
                                ]),
                                const SizedBox(height: 8),
                                Text('Title: $title'),
                                Text('Platform: $platform'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Recent Notifications
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recent Notifications',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('push_notifications')
                              .orderBy('createdAt', descending: true)
                              .limit(5)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text('No notifications sent yet.');
                            }
                            return Column(
                              children: snapshot.data!.docs.map((doc) {
                                final d =
                                    doc.data() as Map<String, dynamic>;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.notifications,
                                    color: d['status'] == 'sent'
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 20,
                                  ),
                                  title: Text(d['title'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(d['status'] ?? 'pending',
                                      style: const TextStyle(fontSize: 11)),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recent Sermons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Sermons',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sermons')
                        .orderBy('dateCreated', descending: true)
                        .limit(4)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.data!.docs.isEmpty) {
                        return const Text('No sermons uploaded yet.');
                      }
                      return Row(
                        children: snapshot.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return Expanded(
                            child: Card(
                              color: Colors.orange[50],
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (d['thumbnailUrl'] != null)
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        child: Image.network(
                                          ImageProxy.proxy(d['thumbnailUrl']),
                                          height: 80,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(height: 80, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(d['title'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(d['preacherName'] ?? '',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final String collection;

  const _StatCard({
    required this.label,
    required this.color,
    required this.icon,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  FutureBuilder<AggregateQuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection(collection)
                        .count()
                        .get(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.count ?? 0;
                      return Text(
                        '$count',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: color),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
