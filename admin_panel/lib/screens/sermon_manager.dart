import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/sermon.dart';
import '../services/fcm_admin_service.dart';
import '../utils/image_proxy.dart';
import 'sermon_category_manager.dart';

class SermonManager extends StatefulWidget {
  const SermonManager({super.key});

  @override
  State<SermonManager> createState() => _SermonManagerState();
}

class _SermonManagerState extends State<SermonManager> {
  String _searchQuery = '';
  String _selectedPreacher = 'All';
  String _selectedCategory = 'All';
  String _selectedTag = 'All';

  int _currentPage = 0;
  final int _rowsPerPage = 20;

  final Set<String> _selectedSermonIds = {};
  bool _isPerformingAction = false;

  Set<String> _allPreachers = {'All'};
  Set<String> _allCategories = {'All'};
  Set<String> _allTags = {'All'};

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _showSermonDetails(Sermon sermon, Map<String, dynamic> rawData) {
    showDialog(
      context: context,
      builder: (context) {
        final listens = rawData['listens'] ?? 0;
        final downloads = rawData['downloads'] ?? 0;
        final bookmarks = rawData['bookmarks'] ?? 0;
        final status = rawData['status'] ?? 'published';

        return AlertDialog(
          title: Text(_toTitleCase(sermon.title)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: sermon.thumbnailUrl.isEmpty 
                    ? Container(width: 400, height: 150, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 50, color: Colors.grey))
                    : Image.network(
                        ImageProxy.proxy(sermon.thumbnailUrl),
                        width: 400,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 400,
                          height: 150,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                _DetailRow('Preacher:', sermon.preacherName),
                _DetailRow('Category:', sermon.category),
                _DetailRow('Tags:', sermon.tags.join(', ')),
                _DetailRow('Status:', status.toString().toUpperCase()),
                const Divider(height: 32),
                const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(Icons.headset, 'Listened', listens.toString()),
                    _StatColumn(Icons.download, 'Downloaded', downloads.toString()),
                    _StatColumn(Icons.bookmark, 'Bookmarked', bookmarks.toString()),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              onPressed: () {
                Navigator.pop(context);
                _editSermon(sermon, rawData);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                _deleteSermon(sermon.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _editSermon(Sermon sermon, Map<String, dynamic> rawData) {
    final titleCtrl = TextEditingController(text: sermon.title);
    final preacherCtrl = TextEditingController(text: sermon.preacherName);
    final categoryCtrl = TextEditingController(text: sermon.category);
    final tagsCtrl = TextEditingController(text: sermon.tags.join(', '));
    String status = rawData['status'] ?? 'published';

    // Media State
    String thumbMode = 'url';
    String audioMode = 'url';
    final thumbUrlCtrl = TextEditingController(text: sermon.thumbnailUrl);
    final audioUrlCtrl = TextEditingController(text: sermon.audioUrl);
    Uint8List? thumbBytes;
    String? thumbFileName;
    Uint8List? audioBytes;
    String? audioFileName;
    
    bool isSaving = false;
    double progress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Sermon'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                    const SizedBox(height: 8),
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: sermon.preacherName),
                      optionsBuilder: (val) {
                        if (val.text.isEmpty) return _allPreachers.where((e) => e != 'All');
                        return _allPreachers.where((e) => e != 'All' && e.toLowerCase().contains(val.text.toLowerCase()));
                      },
                      onSelected: (selection) => preacherCtrl.text = selection,
                      fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                        ctrl.text = preacherCtrl.text;
                        ctrl.addListener(() => preacherCtrl.text = ctrl.text);
                        return TextField(controller: ctrl, focusNode: focus, decoration: const InputDecoration(labelText: 'Preacher'));
                      },
                    ),
                    const SizedBox(height: 8),
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: sermon.category),
                      optionsBuilder: (val) {
                        if (val.text.isEmpty) return _allCategories.where((e) => e != 'All');
                        return _allCategories.where((e) => e != 'All' && e.toLowerCase().contains(val.text.toLowerCase()));
                      },
                      onSelected: (selection) => categoryCtrl.text = selection,
                      fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                        ctrl.text = categoryCtrl.text;
                        ctrl.addListener(() => categoryCtrl.text = ctrl.text);
                        return TextField(controller: ctrl, focusNode: focus, decoration: const InputDecoration(labelText: 'Category'));
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags (comma separated)')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'published', child: Text('Published')),
                        DropdownMenuItem(value: 'archived', child: Text('Archived')),
                      ],
                      onChanged: (v) => setDialogState(() => status = v!),
                    ),
                    const Divider(height: 32),
                    
                    // Thumbnail section
                    const Text('Thumbnail', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio(value: 'url', groupValue: thumbMode, onChanged: (v) => setDialogState(() => thumbMode = v.toString())),
                        const Text('Image URL'),
                        Radio(value: 'file', groupValue: thumbMode, onChanged: (v) => setDialogState(() => thumbMode = v.toString())),
                        const Text('Upload File'),
                      ],
                    ),
                    if (thumbMode == 'url')
                      TextField(controller: thumbUrlCtrl, decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()))
                    else
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              FilePickerResult? res = await FilePicker.pickFiles(type: FileType.image, withData: true);
                              print('[Debug] Sermon Image picker (Edit): ${res?.files.first.name}, bytes: ${res?.files.first.bytes?.length}');
                              if (res != null) setDialogState(() { thumbBytes = res.files.first.bytes; thumbFileName = res.files.first.name; });
                            },
                            icon: const Icon(Icons.image), label: const Text('Select Image'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(thumbFileName ?? 'No file selected', overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Audio section
                    const Text('Audio', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio(value: 'url', groupValue: audioMode, onChanged: (v) => setDialogState(() => audioMode = v.toString())),
                        const Text('Audio URL'),
                        Radio(value: 'file', groupValue: audioMode, onChanged: (v) => setDialogState(() => audioMode = v.toString())),
                        const Text('Upload File'),
                      ],
                    ),
                    if (audioMode == 'url')
                      TextField(controller: audioUrlCtrl, decoration: const InputDecoration(labelText: 'Audio URL', border: OutlineInputBorder()))
                    else
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              FilePickerResult? res = await FilePicker.pickFiles(type: FileType.audio, withData: true);
                              print('[Debug] Sermon Audio picker (Edit): ${res?.files.first.name}, bytes: ${res?.files.first.bytes?.length}');
                              if (res != null) setDialogState(() { audioBytes = res.files.first.bytes; audioFileName = res.files.first.name; });
                            },
                            icon: const Icon(Icons.audiotrack), label: const Text('Select Audio'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(audioFileName ?? 'No file selected', overflow: TextOverflow.ellipsis)),
                        ],
                      ),

                    if (isSaving) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 4),
                      Text('Saving... ${(progress * 100).toStringAsFixed(1)}%'),
                    ]
                  ],
                ),
              ),
            ),
            actions: [
              if (!isSaving) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              if (!isSaving) ElevatedButton(
                onPressed: () async {
                  String finalThumbUrl = thumbUrlCtrl.text.trim();
                  String finalAudioUrl = audioUrlCtrl.text.trim();

                  // Auto-generate YouTube thumbnail if a YT link was pasted in the thumbnail field
                  if (thumbMode == 'url' && (finalThumbUrl.contains('youtube.com') || finalThumbUrl.contains('youtu.be'))) {
                    final ytRegex = RegExp(r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?.*v=|shorts\/|embed\/)|youtu\.be\/)([\w\-]+)', caseSensitive: false);
                    final match = ytRegex.firstMatch(finalThumbUrl);
                    if (match != null) {
                      finalThumbUrl = 'https://img.youtube.com/vi/${match.group(1)}/hqdefault.jpg';
                    }
                  }

                  if (thumbMode == 'file') {
                    if (thumbBytes == null) {
                      // Optional, just ignore file upload if no file
                    }
                  } else {
                    if (finalThumbUrl.isEmpty) {
                      // Optional
                    }
                  }

                  if (audioMode == 'file') {
                    if (audioBytes == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an audio file')));
                      return;
                    }
                  } else {
                    if (finalAudioUrl.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide an audio URL')));
                      return;
                    }
                  }

                  setDialogState(() => isSaving = true);
                  try {
                    if (thumbMode == 'file' && thumbBytes != null) {
                      final thumbRef = FirebaseStorage.instance.ref('sermons/thumbnails/${DateTime.now().millisecondsSinceEpoch}_$thumbFileName');
                      await thumbRef.putData(thumbBytes!);
                      finalThumbUrl = await thumbRef.getDownloadURL();
                    }

                    if (audioMode == 'file' && audioBytes != null) {
                      final audioRef = FirebaseStorage.instance.ref('sermons/audio/${DateTime.now().millisecondsSinceEpoch}_$audioFileName');
                      final uploadTask = audioRef.putData(audioBytes!);
                      uploadTask.snapshotEvents.listen((event) {
                        setDialogState(() => progress = event.bytesTransferred / event.totalBytes);
                      });
                      await uploadTask;
                      finalAudioUrl = await audioRef.getDownloadURL();
                    }

                    await FirebaseFirestore.instance.collection('sermons').doc(sermon.id).update({
                      'title': titleCtrl.text.trim(),
                      'preacherName': preacherCtrl.text.trim(),
                      'category': categoryCtrl.text.trim(),
                      'tags': tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      'status': status,
                      'thumbnailUrl': finalThumbUrl,
                      'audioUrl': finalAudioUrl,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sermon updated!')));
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    if (mounted) setDialogState(() => isSaving = false);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _deleteSermon(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this sermon?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('sermons').doc(id).delete();
              if (mounted) {
                Navigator.pop(context);
                setState(() => _selectedSermonIds.remove(id));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBatchAction(String action) async {
    if (_selectedSermonIds.isEmpty) return;
    setState(() => _isPerformingAction = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedSermonIds) {
        final ref = FirebaseFirestore.instance.collection('sermons').doc(id);
        if (action == 'delete') {
          batch.delete(ref);
        } else if (action == 'archive') {
          batch.update(ref, {'status': 'archived'});
        } else if (action == 'publish') {
          batch.update(ref, {'status': 'published'});
        }
      }

      if (action == 'change_category') {
        String newCat = '';
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Change Category'),
            content: TextField(
              onChanged: (v) => newCat = v,
              decoration: const InputDecoration(labelText: 'New Category Name'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  for (final id in _selectedSermonIds) {
                    final ref = FirebaseFirestore.instance.collection('sermons').doc(id);
                    batch.update(ref, {'category': newCat.trim()});
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        );
        if (newCat.trim().isEmpty) {
          setState(() => _isPerformingAction = false);
          return;
        }
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action "$action" applied to ${_selectedSermonIds.length} items.')));
        setState(() => _selectedSermonIds.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    if (mounted) setState(() => _isPerformingAction = false);
  }

  void _showUploadDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final preacherController = TextEditingController();
    final categoryController = TextEditingController();
    final tagsController = TextEditingController();

    String thumbMode = 'url';
    String audioMode = 'url';
    final thumbUrlCtrl = TextEditingController();
    final audioUrlCtrl = TextEditingController();

    Uint8List? audioBytes;
    String? audioFileName;
    Uint8List? thumbnailBytes;
    String? thumbnailFileName;
    
    bool isUploading = false;
    double uploadProgress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Upload New Sermon', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Sermon Title', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) return _allPreachers.where((e) => e != 'All');
                          return _allPreachers.where((e) => e != 'All' && e.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (selection) => preacherController.text = selection,
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          textEditingController.addListener(() => preacherController.text = textEditingController.text);
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(labelText: 'Preacher Name', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) return _allCategories.where((e) => e != 'All');
                          return _allCategories.where((e) => e != 'All' && e.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (selection) => categoryController.text = selection,
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          textEditingController.addListener(() => categoryController.text = textEditingController.text);
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tagsController,
                        decoration: const InputDecoration(labelText: 'Tags (comma separated)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      
                      // Thumbnail
                      const Text('Thumbnail', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Radio(value: 'url', groupValue: thumbMode, onChanged: (v) => setDialogState(() => thumbMode = v.toString())),
                          const Text('URL'),
                          Radio(value: 'file', groupValue: thumbMode, onChanged: (v) => setDialogState(() => thumbMode = v.toString())),
                          const Text('Upload File'),
                        ],
                      ),
                      if (thumbMode == 'url')
                        TextFormField(
                          controller: thumbUrlCtrl,
                          decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
                        )
                      else
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                FilePickerResult? res = await FilePicker.pickFiles(type: FileType.image, withData: true);
                                print('[Debug] Sermon Image picker (Upload): ${res?.files.first.name}, bytes: ${res?.files.first.bytes?.length}');
                                if (res != null) setDialogState(() { thumbnailBytes = res.files.first.bytes; thumbnailFileName = res.files.first.name; });
                              },
                              icon: const Icon(Icons.image), label: const Text('Select Image'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(thumbnailFileName ?? 'No image', overflow: TextOverflow.ellipsis)),
                          ],
                        ),

                      const SizedBox(height: 16),
                      // Audio
                      const Text('Audio', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Radio(value: 'url', groupValue: audioMode, onChanged: (v) => setDialogState(() => audioMode = v.toString())),
                          const Text('URL'),
                          Radio(value: 'file', groupValue: audioMode, onChanged: (v) => setDialogState(() => audioMode = v.toString())),
                          const Text('Upload File'),
                        ],
                      ),
                      if (audioMode == 'url')
                        TextFormField(
                          controller: audioUrlCtrl,
                          decoration: const InputDecoration(labelText: 'Audio URL', border: OutlineInputBorder()),
                        )
                      else
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                FilePickerResult? res = await FilePicker.pickFiles(type: FileType.audio, withData: true);
                                print('[Debug] Sermon Audio picker (Upload): ${res?.files.first.name}, bytes: ${res?.files.first.bytes?.length}');
                                if (res != null) setDialogState(() { audioBytes = res.files.first.bytes; audioFileName = res.files.first.name; });
                              },
                              icon: const Icon(Icons.audiotrack), label: const Text('Select Audio'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(audioFileName ?? 'No audio', overflow: TextOverflow.ellipsis)),
                          ],
                        ),

                      const SizedBox(height: 16),
                      if (isUploading)
                        Column(
                          children: [
                            LinearProgressIndicator(value: uploadProgress),
                            const SizedBox(height: 4),
                            Text('Uploading... ${(uploadProgress * 100).toStringAsFixed(1)}%'),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (!isUploading) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              if (!isUploading) ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  String finalThumbUrl = thumbUrlCtrl.text.trim();
                  String finalAudioUrl = audioUrlCtrl.text.trim();

                  // Auto-generate YouTube thumbnail if a YT link was pasted in the thumbnail field
                  if (thumbMode == 'url' && (finalThumbUrl.contains('youtube.com') || finalThumbUrl.contains('youtu.be'))) {
                    final ytRegex = RegExp(r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?.*v=|shorts\/|embed\/)|youtu\.be\/)([\w\-]+)', caseSensitive: false);
                    final match = ytRegex.firstMatch(finalThumbUrl);
                    if (match != null) {
                      finalThumbUrl = 'https://img.youtube.com/vi/${match.group(1)}/hqdefault.jpg';
                    }
                  }

                  if (thumbMode == 'file' && thumbnailBytes == null) {
                    // Thumbnail is optional, so we just clear the url
                    finalThumbUrl = '';
                  } else if (thumbMode == 'url' && finalThumbUrl.isEmpty) {
                    // Thumbnail is optional
                    finalThumbUrl = '';
                  }

                  if (audioMode == 'file' && audioBytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an audio file')));
                    return;
                  } else if (audioMode == 'url' && finalAudioUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter audio URL')));
                    return;
                  }

                  setDialogState(() => isUploading = true);
                  
                  try {
                    if (thumbMode == 'file' && thumbnailBytes != null) {
                      final thumbRef = FirebaseStorage.instance.ref('sermons/thumbnails/${DateTime.now().millisecondsSinceEpoch}_$thumbnailFileName');
                      await thumbRef.putData(thumbnailBytes!);
                      finalThumbUrl = await thumbRef.getDownloadURL();
                    }

                    if (audioMode == 'file') {
                      final audioRef = FirebaseStorage.instance.ref('sermons/audio/${DateTime.now().millisecondsSinceEpoch}_$audioFileName');
                      final uploadTask = audioRef.putData(audioBytes!);
                      uploadTask.snapshotEvents.listen((event) {
                        setDialogState(() => uploadProgress = event.bytesTransferred / event.totalBytes);
                      });
                      await uploadTask;
                      finalAudioUrl = await audioRef.getDownloadURL();
                    }

                    final tags = tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    final data = {
                      'title': titleController.text.trim(),
                      'preacherName': preacherController.text.trim(),
                      'category': categoryController.text.trim(),
                      'tags': tags,
                      'thumbnailUrl': finalThumbUrl,
                      'audioUrl': finalAudioUrl,
                      'dateCreated': FieldValue.serverTimestamp(),
                      'status': 'published',
                      'listens': 0,
                      'downloads': 0,
                      'bookmarks': 0,
                    };

                    await FirebaseFirestore.instance.collection('sermons').add(data);
                    await FcmAdminService.sendNotification(
                      title: 'New Sermon: ${titleController.text}',
                      content: 'Listen to the latest message by ${preacherController.text} now!',
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sermon published!')));
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                  } finally {
                    if (mounted) setDialogState(() => isUploading = false);
                  }
                },
                child: const Text('Publish'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sermons').orderBy('dateCreated', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs;

        _allPreachers = {'All'};
        _allCategories = {'All'};
        _allTags = {'All'};

        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          _allPreachers.add(data['preacherName']?.toString() ?? 'Unknown');
          _allCategories.add(data['category']?.toString() ?? 'Unknown');
          final t = data['tags'] as List<dynamic>? ?? [];
          for (var tag in t) {
            _allTags.add(tag.toString());
          }
        }

        var filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final sermon = Sermon.fromMap(data, doc.id);
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            if (!sermon.title.toLowerCase().contains(q) && !sermon.preacherName.toLowerCase().contains(q)) return false;
          }
          if (_selectedPreacher != 'All' && sermon.preacherName != _selectedPreacher) return false;
          if (_selectedCategory != 'All' && sermon.category != _selectedCategory) return false;
          if (_selectedTag != 'All' && !sermon.tags.contains(_selectedTag)) return false;
          return true;
        }).toList();

        final totalItems = filteredDocs.length;
        final totalPages = (totalItems / _rowsPerPage).ceil();
        if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
        
        final startIndex = _currentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage < totalItems) ? startIndex + _rowsPerPage : totalItems;
        final pagedDocs = filteredDocs.sublist(startIndex, endIndex);

        // Compute master checkbox state
        bool allSelected = pagedDocs.isNotEmpty && pagedDocs.every((doc) => _selectedSermonIds.contains(doc.id));
        bool someSelected = pagedDocs.any((doc) => _selectedSermonIds.contains(doc.id)) && !allSelected;

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sermons Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder, size: 18),
                        label: const Text('Manage Albums'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const SermonCategoryManager(),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Upload New Sermon'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _showUploadDialog,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Filters ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by title or preacher...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 0; }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPreacher,
                        decoration: const InputDecoration(labelText: 'Preacher', isDense: true, border: OutlineInputBorder()),
                        items: _allPreachers.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() { _selectedPreacher = v!; _currentPage = 0; }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category', isDense: true, border: OutlineInputBorder()),
                        items: _allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() { _selectedCategory = v!; _currentPage = 0; }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTag,
                        decoration: const InputDecoration(labelText: 'Tag', isDense: true, border: OutlineInputBorder()),
                        items: _allTags.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() { _selectedTag = v!; _currentPage = 0; }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Batch Actions ──
              if (_selectedSermonIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text('${_selectedSermonIds.length} selected', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 16),
                      if (_isPerformingAction)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      else ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.public, size: 14), label: const Text('Publish'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => _performBatchAction('publish'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.archive, size: 14), label: const Text('Archive'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => _performBatchAction('archive'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.category, size: 14), label: const Text('Change Category'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => _performBatchAction('change_category'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete, size: 14), label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => _performBatchAction('delete'),
                        ),
                      ],
                    ],
                  ),
                ),

              // ── Custom Fixed-Header Table ──
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Container(
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: allSelected ? true : (someSelected ? null : false),
                              tristate: true,
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true || val == null) {
                                    _selectedSermonIds.addAll(pagedDocs.map((e) => e.id));
                                  } else {
                                    _selectedSermonIds.removeAll(pagedDocs.map((e) => e.id));
                                  }
                                });
                              },
                            ),
                            Expanded(flex: 3, child: const Text('Sermon Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(flex: 2, child: const Text('Preacher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(flex: 2, child: const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(flex: 1, child: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            const SizedBox(width: 80, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Body List
                      Expanded(
                        child: ListView.separated(
                          itemCount: pagedDocs.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = pagedDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final sermon = Sermon.fromMap(data, doc.id);
                            final isSelected = _selectedSermonIds.contains(doc.id);
                            final status = data['status'] ?? 'published';

                            return InkWell(
                              onTap: () => _showSermonDetails(sermon, data),
                              child: Container(
                                color: isSelected ? Colors.blue.withValues(alpha: 0.05) : null,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) _selectedSermonIds.add(doc.id);
                                          else _selectedSermonIds.remove(doc.id);
                                        });
                                      },
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: Text(_toTitleCase(sermon.title), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: Text(sermon.preacherName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: Text(sermon.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text('${sermon.dateCreated.year}-${sermon.dateCreated.month.toString().padLeft(2,'0')}-${sermon.dateCreated.day.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 13)),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: status == 'published' ? Colors.green.shade50 : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(status.toString().toUpperCase(), style: TextStyle(fontSize: 10, color: status == 'published' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Pagination Footer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Showing ${totalItems == 0 ? 0 : startIndex + 1} to $endIndex of $totalItems entries', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 16),
                            IconButton(icon: const Icon(Icons.chevron_left, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: _currentPage > 0 ? _prevPage : null),
                            const SizedBox(width: 8),
                            Text('Page ${_currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 8),
                            IconButton(icon: const Icon(Icons.chevron_right, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: _currentPage < totalPages - 1 ? () => _nextPage(totalPages) : null),
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
      },
    );
  }
}

// ─── HELPERS ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatColumn(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
