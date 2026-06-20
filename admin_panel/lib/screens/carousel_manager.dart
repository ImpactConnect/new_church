import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/image_proxy.dart';
import '../models/carousel_item.dart';
import 'banner_form_dialog.dart';

class CarouselManager extends StatefulWidget {
  const CarouselManager({super.key});

  @override
  State<CarouselManager> createState() => _CarouselManagerState();
}

class _CarouselManagerState extends State<CarouselManager> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.list_alt, color: Theme.of(context).primaryColor, size: 28),
                      const SizedBox(width: 12),
                      const Text('Active Banners (Drag to reorder)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const BannerFormDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Banner'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('carousel_items').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No active banners found.'));
                    
                    final docs = snapshot.data!.docs.toList();
                    docs.sort((a, b) {
                      final aOrder = (a.data() as Map<String, dynamic>)['order'] as int? ?? 0;
                      final bOrder = (b.data() as Map<String, dynamic>)['order'] as int? ?? 0;
                      return aOrder.compareTo(bOrder);
                    });

                    return ReorderableListView.builder(
                      itemCount: docs.length,
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final item = docs.removeAt(oldIndex);
                        docs.insert(newIndex, item);
                        final batch = FirebaseFirestore.instance.batch();
                        for (int i = 0; i < docs.length; i++) {
                          batch.update(docs[i].reference, {'order': i});
                        }
                        batch.commit();
                      },
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final item = CarouselItem.fromFirestore(data, doc.id);
                        return Card(
                          key: ValueKey(doc.id),
                          child: ListTile(
                            leading: item.imageUrl != null 
                              ? Image.network(ImageProxy.proxy(item.imageUrl!), width: 80, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.error))
                              : const Icon(Icons.image),
                            title: Text(item.title),
                            subtitle: Text('Order: ${item.order} | Active: ${item.isActive}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => BannerFormDialog(bannerToEdit: item),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Banner'),
                                        content: const Text('Are you sure you want to delete this banner?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm != true) return;

                                    if (item.imageUrl != null) {
                                      try {
                                        final ref = FirebaseStorage.instance.refFromURL(item.imageUrl!);
                                        await ref.delete();
                                      } catch (e) {
                                        debugPrint('Error deleting image: $e');
                                      }
                                    }
                                    await FirebaseFirestore.instance.collection('carousel_items').doc(item.id).delete();
                                  },
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
    );
  }
}
