import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../models/sermon_category.dart';
import '../utils/image_proxy.dart';

class SermonCategoryManager extends StatefulWidget {
  const SermonCategoryManager({super.key});

  @override
  State<SermonCategoryManager> createState() => _SermonCategoryManagerState();
}

class _SermonCategoryManagerState extends State<SermonCategoryManager> {
  List<SermonCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final snapshot = await FirebaseFirestore.instance.collection('sermon_categories').get();
    final sermonSnap = await FirebaseFirestore.instance.collection('sermons').get();
    
    final explicitCategories = snapshot.docs.map((doc) => SermonCategory.fromFirestore(doc)).toList();
    final existingNames = explicitCategories.map((c) => c.name.toLowerCase()).toSet();
    final List<SermonCategory> allCategories = List.from(explicitCategories);
    
    for (var doc in sermonSnap.docs) {
      final cat = (doc.data()['category'] as String? ?? '').trim();
      if (cat.isNotEmpty && !existingNames.contains(cat.toLowerCase())) {
        existingNames.add(cat.toLowerCase());
        allCategories.add(SermonCategory(id: '', name: cat, imageUrl: '', description: ''));
      }
    }

    setState(() {
      _categories = allCategories..sort((a, b) => a.name.compareTo(b.name));
      _isLoading = false;
    });
  }

  void _showAddEditDialog([SermonCategory? category]) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    String imageUrl = category?.imageUrl ?? '';
    Uint8List? imageBytes;
    String? imageFileName;
    bool isSaving = false;
    String imageSource = 'file';
    final urlCtrl = TextEditingController(text: imageUrl);
    List<Map<String, dynamic>>? existingMedia;
    bool loadingExisting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(category == null ? 'Add Category/Album' : 'Edit Category/Album'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Short Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Cover Image Source', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Radio<String>(value: 'file', groupValue: imageSource, onChanged: (v) => setDialogState(() => imageSource = v!)),
                          const Text('Upload File'),
                          Radio<String>(value: 'url', groupValue: imageSource, onChanged: (v) => setDialogState(() => imageSource = v!)),
                          const Text('Image URL'),
                          Radio<String>(value: 'existing', groupValue: imageSource, onChanged: (v) {
                            setDialogState(() => imageSource = v!);
                            if (existingMedia == null && !loadingExisting) {
                              setDialogState(() => loadingExisting = true);
                              FirebaseFirestore.instance.collection('sermons').get().then((snap) {
                                setDialogState(() {
                                  existingMedia = snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                                  loadingExisting = false;
                                });
                              });
                            }
                          }),
                          const Text('Existing'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: imageSource == 'file' && imageBytes != null
                            ? Image.memory(imageBytes!, fit: BoxFit.cover)
                            : imageUrl.isNotEmpty
                                ? Image.network(ImageProxy.proxy(imageUrl), fit: BoxFit.cover)
                                : const Center(child: Text('No Image Selected')),
                      ),
                      const SizedBox(height: 8),
                      if (imageSource == 'file')
                        ElevatedButton.icon(
                          onPressed: () async {
                            final res = await FilePicker.pickFiles(type: FileType.image, withData: true);
                            if (res != null && res.files.first.bytes != null) {
                              setDialogState(() {
                                imageBytes = res.files.first.bytes;
                                imageFileName = res.files.first.name;
                                imageUrl = ''; // clear url so we preview memory
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                        ),
                      if (imageSource == 'url')
                        TextField(
                          controller: urlCtrl,
                          decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
                          onChanged: (val) => setDialogState(() => imageUrl = val),
                        ),
                      if (imageSource == 'existing')
                        loadingExisting
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: existingMedia?.length ?? 0,
                                  itemBuilder: (context, i) {
                                    final item = existingMedia![i];
                                    final thumbUrl = (item['thumbnailUrl'] ?? item['imageUrl'])?.toString() ?? '';
                                    if (thumbUrl.isEmpty) return const SizedBox.shrink();
                                    return GestureDetector(
                                      onTap: () => setDialogState(() => imageUrl = thumbUrl),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 100,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: imageUrl == thumbUrl ? Colors.blue : Colors.transparent, width: 3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(ImageProxy.proxy(thumbUrl), fit: BoxFit.cover),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      if (isSaving)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            String finalImageUrl = imageUrl;
                            if (imageSource == 'file' && imageBytes != null) {
                              final ref = FirebaseStorage.instance.ref('sermons/categories/${DateTime.now().millisecondsSinceEpoch}_$imageFileName');
                              await ref.putData(imageBytes!);
                              finalImageUrl = await ref.getDownloadURL();
                            } else if (imageSource == 'url') {
                              finalImageUrl = urlCtrl.text.trim();
                            }

                            final data = {
                              'name': name,
                              'description': descCtrl.text.trim(),
                              'imageUrl': finalImageUrl,
                            };

                            if (category == null || category.id.isEmpty) {
                              await FirebaseFirestore.instance.collection('sermon_categories').add(data);
                            } else {
                              await FirebaseFirestore.instance.collection('sermon_categories').doc(category.id).update(data);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadCategories();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          } finally {
                            if (mounted) setDialogState(() => isSaving = false);
                          }
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteCategory(SermonCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category.id.isEmpty ? 'Cannot Delete' : 'Delete Category'),
        content: Text(category.id.isEmpty 
            ? 'This is a virtual category. It will automatically disappear when no sermons are assigned to "${category.name}".'
            : 'Are you sure you want to delete "${category.name}"? This won\'t delete the actual sermons.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: category.id.isEmpty ? Colors.grey : Colors.red, foregroundColor: Colors.white),
              onPressed: category.id.isEmpty 
                  ? () => Navigator.pop(context)
                  : () async {
                      await FirebaseFirestore.instance.collection('sermon_categories').doc(category.id).delete();
                      if (mounted) {
                        Navigator.pop(context);
                        _loadCategories();
                      }
                    },
              child: Text(category.id.isEmpty ? 'OK' : 'Delete'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Manage Albums / Categories', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                      ? const Center(child: Text('No categories found. Add one above.'))
                      : ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: category.imageUrl.isNotEmpty
                                      ? Image.network(ImageProxy.proxy(category.imageUrl), width: 60, height: 60, fit: BoxFit.cover)
                                      : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.folder, color: Colors.grey)),
                                ),
                                title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: category.description.isNotEmpty 
                                    ? Text(category.description, maxLines: 2, overflow: TextOverflow.ellipsis)
                                    : Text(category.id.isEmpty ? 'Virtual Album' : 'Album', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showAddEditDialog(category),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteCategory(category),
                                      tooltip: 'Delete',
                                    ),
                                  ],
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
