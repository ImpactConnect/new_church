import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/video_item.dart';
import '../services/fcm_admin_service.dart';
import '../utils/image_proxy.dart';

// ─── Video Manager ────────────────────────────────────────────────────────

class VideoManager extends StatefulWidget {
  const VideoManager({super.key});
  @override
  State<VideoManager> createState() => _VideoManagerState();
}

class _VideoManagerState extends State<VideoManager> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedType = 'All';

  int _currentPage = 0;
  final int _rowsPerPage = 20;

  final Set<String> _selectedVideoIds = {};
  bool _isPerformingAction = false;

  Set<String> _allCategories = {'All'};
  Set<String> _allTypes = {'All'};

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) setState(() => _currentPage++);
  }

  void _prevPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  String _youtubeThumbnail(String videoId) => 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

  String? _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'^.*(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/|(?:watch)?\?v(?:i)?=|&v(?:i)?=)([^#&?]+).*',
      caseSensitive: false,
    );
    return regExp.firstMatch(url)?.group(1);
  }

  void _showVideoDetails(VideoItem video, Map<String, dynamic> rawData) {
    showDialog(
      context: context,
      builder: (context) {
        final views = rawData['views'] ?? 0;
        final likes = rawData['likes'] ?? 0;

        return AlertDialog(
          title: Text(_toTitleCase(video.title)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: video.thumbnailUrl.isEmpty 
                    ? Container(width: 400, height: 150, color: Colors.grey.shade200, child: const Icon(Icons.video_library, size: 50, color: Colors.grey))
                    : Image.network(
                        ImageProxy.proxy(video.thumbnailUrl),
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
                _DetailRow('Type:', video.videoType.toUpperCase()),
                _DetailRow('Category:', video.category),
                _DetailRow('Recommended:', video.isRecommended ? 'Yes' : 'No'),
                if (video.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(video.description),
                ],
                const Divider(height: 32),
                const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(Icons.visibility, 'Views', views.toString()),
                    _StatColumn(Icons.thumb_up, 'Likes', likes.toString()),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              onPressed: () {
                Navigator.pop(context);
                _editVideo(video, rawData);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                _deleteVideo(video.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _editVideo(VideoItem video, Map<String, dynamic> rawData) {
    final titleCtrl = TextEditingController(text: video.title);
    final categoryCtrl = TextEditingController(text: video.category);
    final descCtrl = TextEditingController(text: video.description);
    final preacherCtrl = TextEditingController(text: video.preacher);
    
    String videoType = video.videoType;
    bool isRecommended = video.isRecommended;

    // Media
    String videoMode = 'url';
    String thumbMode = 'url';
    final videoUrlCtrl = TextEditingController(text: video.videoUrl);
    final thumbUrlCtrl = TextEditingController(text: video.thumbnailUrl);
    
    Uint8List? videoBytes;
    String? videoFileName;
    Uint8List? thumbBytes;
    String? thumbFileName;

    bool isSaving = false;
    double progress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Video'),
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
                      initialValue: TextEditingValue(text: video.category),
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
                    TextField(controller: preacherCtrl, decoration: const InputDecoration(labelText: 'Preacher/Speaker')),
                    const SizedBox(height: 8),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: videoType,
                      decoration: const InputDecoration(labelText: 'Video Type'),
                      items: const [
                        DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                        DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
                        DropdownMenuItem(value: 'network', child: Text('Direct MP4')),
                      ],
                      onChanged: (v) => setDialogState(() => videoType = v!),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isRecommended,
                      title: const Text('Recommended (Featured)'),
                      onChanged: (v) => setDialogState(() => isRecommended = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 32),

                    // Video Source
                    const Text('Video Source', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (videoType == 'network') ...[
                      Row(
                        children: [
                          Radio(value: 'url', groupValue: videoMode, onChanged: (v) => setDialogState(() => videoMode = v.toString())),
                          const Text('URL'),
                          Radio(value: 'file', groupValue: videoMode, onChanged: (v) => setDialogState(() => videoMode = v.toString())),
                          const Text('Upload File'),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text('External video must use a URL', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                    ],
                    
                    if (videoType != 'network' || videoMode == 'url')
                      TextField(controller: videoUrlCtrl, decoration: const InputDecoration(labelText: 'Video URL', border: OutlineInputBorder()))
                    else
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              FilePickerResult? res = await FilePicker.pickFiles(type: FileType.video, withData: true);
                              print('[Debug] Video picker (Edit): ${res?.files.first.name}, bytes: ${res?.files.first.bytes?.length}');
                              if (res != null) setDialogState(() { videoBytes = res.files.first.bytes; videoFileName = res.files.first.name; });
                            },
                            icon: const Icon(Icons.videocam), label: const Text('Select Video'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(videoFileName ?? 'No video selected', overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    
                    const SizedBox(height: 16),
                    // Thumbnail
                    const Text('Custom Thumbnail (Optional for YouTube)', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio(value: 'url', groupValue: thumbMode, onChanged: (v) => setDialogState(() => thumbMode = v.toString())),
                        const Text('URL'),
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
                              print('[Debug] Image picker (Edit): ${res?.files.first.name}, bytes: ${res?.files.first.bytes?.length}');
                              if (res != null) setDialogState(() { thumbBytes = res.files.first.bytes; thumbFileName = res.files.first.name; });
                            },
                            icon: const Icon(Icons.image), label: const Text('Select Image'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(thumbFileName ?? 'No file selected', overflow: TextOverflow.ellipsis)),
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
                  setDialogState(() => isSaving = true);
                  try {
                    String finalVideoUrl = videoUrlCtrl.text.trim();
                    if (videoType == 'network' && videoMode == 'file' && videoBytes != null) {
                      final ref = FirebaseStorage.instance.ref('videos/${DateTime.now().millisecondsSinceEpoch}_$videoFileName');
                      final task = ref.putData(videoBytes!);
                      task.snapshotEvents.listen((e) => setDialogState(() => progress = e.bytesTransferred / e.totalBytes));
                      await task;
                      finalVideoUrl = await ref.getDownloadURL();
                    }

                    String finalThumbUrl = thumbUrlCtrl.text.trim();
                    if (thumbMode == 'file' && thumbBytes != null) {
                      final ref = FirebaseStorage.instance.ref('videos/thumbnails/${DateTime.now().millisecondsSinceEpoch}_$thumbFileName');
                      await ref.putData(thumbBytes!);
                      finalThumbUrl = await ref.getDownloadURL();
                    } else if (finalThumbUrl.isEmpty && videoType == 'youtube') {
                      final yid = _extractYouTubeId(finalVideoUrl);
                      if (yid != null) finalThumbUrl = _youtubeThumbnail(yid);
                    }

                    await FirebaseFirestore.instance.collection('videos').doc(video.id).update({
                      'title': titleCtrl.text.trim(),
                      'category': categoryCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'preacher': preacherCtrl.text.trim(),
                      'videoType': videoType,
                      'videoUrl': finalVideoUrl,
                      'thumbnailUrl': finalThumbUrl,
                      'isRecommended': isRecommended,
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video updated!')));
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

  void _deleteVideo(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('videos').doc(id).delete();
              if (mounted) {
                Navigator.pop(context);
                setState(() => _selectedVideoIds.remove(id));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBatchAction(String action) async {
    if (_selectedVideoIds.isEmpty) return;
    setState(() => _isPerformingAction = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedVideoIds) {
        final ref = FirebaseFirestore.instance.collection('videos').doc(id);
        if (action == 'delete') {
          batch.delete(ref);
        } else if (action == 'feature') {
          batch.update(ref, {'isRecommended': true});
        } else if (action == 'unfeature') {
          batch.update(ref, {'isRecommended': false});
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
                  for (final id in _selectedVideoIds) {
                    final ref = FirebaseFirestore.instance.collection('videos').doc(id);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action "$action" applied.')));
        setState(() => _selectedVideoIds.clear());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _isPerformingAction = false);
  }

  void _showYouTubeSettingsDialog() async {
    final apiKeyCtrl = TextEditingController();
    final channelIdCtrl = TextEditingController();
    bool isLoading = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Fetch existing settings once
          if (isLoading) {
            FirebaseFirestore.instance.collection('app_settings').doc('youtube').get().then((doc) {
              if (doc.exists) {
                apiKeyCtrl.text = doc.data()?['apiKey'] ?? '';
                channelIdCtrl.text = doc.data()?['channelId'] ?? '';
              }
              if (mounted) setDialogState(() => isLoading = false);
            }).catchError((e) {
              if (mounted) setDialogState(() => isLoading = false);
            });
          }

          return AlertDialog(
            title: const Text('YouTube Auto-Fetch Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 400,
              child: isLoading 
                ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Configure your YouTube Data API v3 Key and Channel ID here to enable the mobile app to automatically pull recent videos from your channel.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: apiKeyCtrl,
                        decoration: const InputDecoration(labelText: 'YouTube API Key', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: channelIdCtrl,
                        decoration: const InputDecoration(labelText: 'YouTube Channel ID', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Example Channel ID: UCnQGkEdA2-pBfEicB3b7Fzw', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    ],
                  ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context), 
                child: const Text('Cancel')
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
                onPressed: isLoading || isSaving ? null : () async {
                  setDialogState(() => isSaving = true);
                  try {
                    await FirebaseFirestore.instance.collection('app_settings').doc('youtube').set({
                      'apiKey': apiKeyCtrl.text.trim(),
                      'channelId': channelIdCtrl.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('YouTube settings updated successfully')));
                    }
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Settings'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUploadDialog() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final preacherCtrl = TextEditingController();
    
    String videoType = 'youtube';
    bool isRecommended = false;

    String videoMode = 'url';
    String thumbMode = 'url';
    final videoUrlCtrl = TextEditingController();
    final thumbUrlCtrl = TextEditingController();

    Uint8List? videoBytes;
    String? videoFileName;
    Uint8List? thumbBytes;
    String? thumbFileName;
    
    bool isUploading = false;
    double progress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Upload New Video', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Video Title', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) return _allCategories.where((e) => e != 'All');
                          return _allCategories.where((e) => e != 'All' && e.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (selection) => categoryCtrl.text = selection,
                        fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
                          ctrl.addListener(() => categoryCtrl.text = ctrl.text);
                          return TextFormField(
                            controller: ctrl,
                            focusNode: focusNode,
                            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: preacherCtrl,
                        decoration: const InputDecoration(labelText: 'Preacher/Speaker (Optional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: videoType,
                        decoration: const InputDecoration(labelText: 'Video Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                          DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
                          DropdownMenuItem(value: 'network', child: Text('Direct MP4')),
                        ],
                        onChanged: (v) {
                          setDialogState(() {
                            videoType = v!;
                            if (videoType != 'network') videoMode = 'url';
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isRecommended,
                        title: const Text('Recommend (Feature) this Video?'),
                        subtitle: const Text('Sends a push notification'),
                        onChanged: (v) => setDialogState(() => isRecommended = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(height: 24),

                      // Video Source
                      const Text('Video Source', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (videoType == 'network') ...[
                        Row(
                          children: [
                            Radio(value: 'url', groupValue: videoMode, onChanged: (v) => setDialogState(() => videoMode = v.toString())),
                            const Text('URL'),
                            Radio(value: 'file', groupValue: videoMode, onChanged: (v) => setDialogState(() => videoMode = v.toString())),
                            const Text('Upload File'),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        const Text('External video must use a URL', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                      ],

                      if (videoType != 'network' || videoMode == 'url')
                        TextFormField(
                          controller: videoUrlCtrl,
                          decoration: InputDecoration(labelText: videoType == 'youtube' ? 'YouTube URL' : 'Video URL', border: const OutlineInputBorder()),
                        )
                      else
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                FilePickerResult? res = await FilePicker.pickFiles(type: FileType.video, withData: true);
                                print('[Debug] Video picker result: ${res?.files.first.name}, bytes: ${res?.files.first.bytes?.length}');
                                if (res != null) setDialogState(() { videoBytes = res.files.first.bytes; videoFileName = res.files.first.name; });
                              },
                              icon: const Icon(Icons.videocam), label: const Text('Select Video'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(videoFileName ?? 'No video selected', overflow: TextOverflow.ellipsis)),
                          ],
                        ),

                      const SizedBox(height: 16),
                      // Thumbnail
                      const Text('Custom Thumbnail (Optional for YouTube)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                print('[Debug] Image picker result: ${res?.files.first.name}, bytes: ${res?.files.first.bytes?.length}');
                                if (res != null) setDialogState(() { thumbBytes = res.files.first.bytes; thumbFileName = res.files.first.name; });
                              },
                              icon: const Icon(Icons.image), label: const Text('Select Image'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(thumbFileName ?? 'No image', overflow: TextOverflow.ellipsis)),
                          ],
                        ),

                      const SizedBox(height: 16),
                      if (isUploading)
                        Column(
                          children: [
                            LinearProgressIndicator(value: progress),
                            const SizedBox(height: 4),
                            Text('Uploading... ${(progress * 100).toStringAsFixed(1)}%'),
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
                  
                  String finalVideoUrl = videoUrlCtrl.text.trim();
                  if (videoType == 'network' && videoMode == 'file' && videoBytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a video file')));
                    return;
                  } else if ((videoType != 'network' || videoMode == 'url') && finalVideoUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter video URL')));
                    return;
                  }

                  setDialogState(() => isUploading = true);
                  
                  try {
                    if (videoType == 'network' && videoMode == 'file' && videoBytes != null) {
                      final ref = FirebaseStorage.instance.ref('videos/${DateTime.now().millisecondsSinceEpoch}_$videoFileName');
                      final task = ref.putData(videoBytes!);
                      task.snapshotEvents.listen((e) => setDialogState(() => progress = e.bytesTransferred / e.totalBytes));
                      await task;
                      finalVideoUrl = await ref.getDownloadURL();
                    }

                    String finalThumbUrl = thumbUrlCtrl.text.trim();
                    if (thumbMode == 'file' && thumbBytes != null) {
                      final ref = FirebaseStorage.instance.ref('videos/thumbnails/${DateTime.now().millisecondsSinceEpoch}_$thumbFileName');
                      await ref.putData(thumbBytes!);
                      finalThumbUrl = await ref.getDownloadURL();
                    } else if (finalThumbUrl.isEmpty && videoType == 'youtube') {
                      final yid = _extractYouTubeId(finalVideoUrl);
                      if (yid != null) finalThumbUrl = _youtubeThumbnail(yid);
                    }

                    final data = {
                      'title': titleCtrl.text.trim(),
                      'videoUrl': finalVideoUrl,
                      'videoType': videoType,
                      'category': categoryCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'preacher': preacherCtrl.text.trim(),
                      'thumbnailUrl': finalThumbUrl,
                      'isRecommended': isRecommended,
                      'views': 0,
                      'likes': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                    };

                    await FirebaseFirestore.instance.collection('videos').add(data);
                    
                    if (isRecommended) {
                      await FcmAdminService.sendNotification(
                        title: 'New Video: ${titleCtrl.text}',
                        content: 'Check out the new featured video!',
                      );
                    }
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video published!')));
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
      stream: FirebaseFirestore.instance.collection('videos').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs;

        _allCategories = {'All'};
        _allTypes = {'All'};

        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          _allCategories.add(data['category']?.toString() ?? 'Unknown');
          _allTypes.add(data['videoType']?.toString() ?? 'Unknown');
        }

        var filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final video = VideoItem.fromFirestore(doc);
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            if (!video.title.toLowerCase().contains(q)) return false;
          }
          if (_selectedCategory != 'All' && video.category != _selectedCategory) return false;
          if (_selectedType != 'All' && video.videoType != _selectedType) return false;
          return true;
        }).toList();

        final totalItems = filteredDocs.length;
        final totalPages = (totalItems / _rowsPerPage).ceil();
        if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
        
        final startIndex = _currentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage < totalItems) ? startIndex + _rowsPerPage : totalItems;
        final pagedDocs = filteredDocs.sublist(startIndex, endIndex);

        bool allSelected = pagedDocs.isNotEmpty && pagedDocs.every((doc) => _selectedVideoIds.contains(doc.id));
        bool someSelected = pagedDocs.any((doc) => _selectedVideoIds.contains(doc.id)) && !allSelected;

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Video Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('YouTube Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _showYouTubeSettingsDialog,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Upload New Video'),
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

              // Filters
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
                          hintText: 'Search video titles...',
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
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category', isDense: true, border: OutlineInputBorder()),
                        items: _allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() { _selectedCategory = v!; _currentPage = 0; }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Video Type', isDense: true, border: OutlineInputBorder()),
                        items: _allTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() { _selectedType = v!; _currentPage = 0; }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Batch Actions
              if (_selectedVideoIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text('${_selectedVideoIds.length} selected', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 16),
                      if (_isPerformingAction)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      else ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.star, size: 14), label: const Text('Feature'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => _performBatchAction('feature'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.star_border, size: 14), label: const Text('Unfeature'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () => _performBatchAction('unfeature'),
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

              // Custom Fixed-Header Table
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
                                    _selectedVideoIds.addAll(pagedDocs.map((e) => e.id));
                                  } else {
                                    _selectedVideoIds.removeAll(pagedDocs.map((e) => e.id));
                                  }
                                });
                              },
                            ),
                            Expanded(flex: 4, child: const Text('Video Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(flex: 2, child: const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(flex: 2, child: const Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(flex: 1, child: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            const SizedBox(width: 90, child: Text('Recommended', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
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
                            final video = VideoItem.fromFirestore(doc);
                            final isSelected = _selectedVideoIds.contains(doc.id);

                            return InkWell(
                              onTap: () => _showVideoDetails(video, data),
                              child: Container(
                                color: isSelected ? Colors.blue.withValues(alpha: 0.05) : null,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) _selectedVideoIds.add(doc.id);
                                          else _selectedVideoIds.remove(doc.id);
                                        });
                                      },
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: Text(_toTitleCase(video.title), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: Text(video.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(video.videoType.toUpperCase(), style: const TextStyle(fontSize: 13)),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text('${video.postedDate.year}-${video.postedDate.month.toString().padLeft(2,'0')}-${video.postedDate.day.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 13)),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: video.isRecommended ? Colors.orange.shade50 : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(video.isRecommended ? 'FEATURED' : 'NORMAL', style: TextStyle(fontSize: 10, color: video.isRecommended ? Colors.orange : Colors.grey, fontWeight: FontWeight.bold)),
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
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
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

// ─── Gallery Manager ─────────────────────────────────────────────────────

class GalleryManager extends StatefulWidget {
  const GalleryManager({super.key});
  @override
  State<GalleryManager> createState() => _GalleryManagerState();
}

class _GalleryManagerState extends State<GalleryManager> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  int _currentPage = 0;
  final int _rowsPerPage = 24;

  final Set<String> _selectedImageIds = {};
  bool _isPerformingAction = false;

  Set<String> _allCategories = {'All'};

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) setState(() => _currentPage++);
  }

  void _prevPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  void _showImageDetails(String id, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Untitled';
    final category = data['category'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    final likes = data['likes'] ?? 0;
    
    final ts = data['createdAt'] as Timestamp?;
    final date = ts != null ? ts.toDate() : DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_toTitleCase(title)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isEmpty 
                    ? Container(width: 400, height: 250, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 50, color: Colors.grey))
                    : Image.network(
                        ImageProxy.proxy(imageUrl),
                        width: 400,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) {
                          print('[Debug] Image load error in details dialog (Gallery): $e');
                          return Container(
                            width: 400,
                            height: 250,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 16),
                _DetailRow('Category:', category),
                _DetailRow('Date:', '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}'),
                _DetailRow('Likes:', likes.toString()),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              onPressed: () {
                Navigator.pop(context);
                _editImage(id, data);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                _deleteImage(id);
              },
            ),
          ],
        );
      },
    );
  }

  void _editImage(String id, Map<String, dynamic> data) {
    final titleCtrl = TextEditingController(text: data['title']);
    final categoryCtrl = TextEditingController(text: data['category']);
    final tagsCtrl = TextEditingController(text: ((data['tags'] as List<dynamic>?) ?? []).join(', '));
    
    String thumbMode = 'url';
    final thumbUrlCtrl = TextEditingController(text: data['imageUrl']);
    Uint8List? thumbBytes;
    String? thumbFileName;

    bool isSaving = false;
    double progress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Gallery Image'),
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
                      initialValue: TextEditingValue(text: data['category'] ?? ''),
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
                    const Divider(height: 32),

                    const Text('Image Source', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio(value: 'url', groupValue: thumbMode, onChanged: (v) => setDialogState(() => thumbMode = v.toString())),
                        const Text('URL'),
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
                              print('[Debug] Gallery Image picker (Edit): ${res?.files.first.name}, bytes: ${res?.files.first.bytes?.length}');
                              if (res != null) setDialogState(() { thumbBytes = res.files.first.bytes; thumbFileName = res.files.first.name; });
                            },
                            icon: const Icon(Icons.image), label: const Text('Select Image'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(thumbFileName ?? 'No file selected', overflow: TextOverflow.ellipsis)),
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
                  setDialogState(() => isSaving = true);
                  try {
                    String finalThumbUrl = thumbUrlCtrl.text.trim();
                    if (thumbMode == 'file' && thumbBytes != null) {
                      final ref = FirebaseStorage.instance.ref('gallery/${DateTime.now().millisecondsSinceEpoch}_$thumbFileName');
                      final task = ref.putData(thumbBytes!);
                      task.snapshotEvents.listen((e) => setDialogState(() => progress = e.bytesTransferred / e.totalBytes));
                      await task;
                      finalThumbUrl = await ref.getDownloadURL();
                    }

                    await FirebaseFirestore.instance.collection('gallery').doc(id).update({
                      'title': titleCtrl.text.trim(),
                      'category': categoryCtrl.text.trim(),
                      'tags': tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      'imageUrl': finalThumbUrl,
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image updated!')));
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

  void _deleteImage(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('gallery').doc(id).delete();
              if (mounted) {
                Navigator.pop(context);
                setState(() => _selectedImageIds.remove(id));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBatchAction(String action) async {
    if (_selectedImageIds.isEmpty) return;
    setState(() => _isPerformingAction = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedImageIds) {
        final ref = FirebaseFirestore.instance.collection('gallery').doc(id);
        if (action == 'delete') {
          batch.delete(ref);
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
                  for (final id in _selectedImageIds) {
                    final ref = FirebaseFirestore.instance.collection('gallery').doc(id);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action "$action" applied.')));
        setState(() => _selectedImageIds.clear());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _isPerformingAction = false);
  }

  void _showUploadDialog() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    String thumbMode = 'url';
    final thumbUrlCtrl = TextEditingController();
    Uint8List? thumbBytes;
    String? thumbFileName;
    
    bool isUploading = false;
    double progress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Upload New Image', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Image Title', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) return _allCategories.where((e) => e != 'All');
                          return _allCategories.where((e) => e != 'All' && e.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (selection) => categoryCtrl.text = selection,
                        fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
                          ctrl.addListener(() => categoryCtrl.text = ctrl.text);
                          return TextFormField(
                            controller: ctrl,
                            focusNode: focusNode,
                            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tagsCtrl,
                        decoration: const InputDecoration(labelText: 'Tags (comma separated)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),

                      const Text('Image Source', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                print('[Debug] Image picker result: ${res?.files.first.name}, bytes: ${res?.files.first.bytes?.length}');
                                if (res != null) setDialogState(() { thumbBytes = res.files.first.bytes; thumbFileName = res.files.first.name; });
                              },
                              icon: const Icon(Icons.image), label: const Text('Select Image'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(thumbFileName ?? 'No image', overflow: TextOverflow.ellipsis)),
                          ],
                        ),

                      const SizedBox(height: 16),
                      if (isUploading)
                        Column(
                          children: [
                            LinearProgressIndicator(value: progress),
                            const SizedBox(height: 4),
                            Text('Uploading... ${(progress * 100).toStringAsFixed(1)}%'),
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
                  if (thumbMode == 'file' && thumbBytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an image file')));
                    return;
                  } else if (thumbMode == 'url' && finalThumbUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter image URL')));
                    return;
                  }

                  setDialogState(() => isUploading = true);
                  
                  try {
                    if (thumbMode == 'file') {
                      final ref = FirebaseStorage.instance.ref('gallery/${DateTime.now().millisecondsSinceEpoch}_$thumbFileName');
                      final task = ref.putData(thumbBytes!);
                      task.snapshotEvents.listen((e) => setDialogState(() => progress = e.bytesTransferred / e.totalBytes));
                      await task;
                      finalThumbUrl = await ref.getDownloadURL();
                    }

                    final tags = tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    final data = {
                      'title': titleCtrl.text.trim(),
                      'category': categoryCtrl.text.trim(),
                      'tags': tags,
                      'imageUrl': finalThumbUrl,
                      'createdAt': FieldValue.serverTimestamp(),
                      'likes': 0,
                    };

                    await FirebaseFirestore.instance.collection('gallery').add(data);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image published!')));
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
      stream: FirebaseFirestore.instance.collection('gallery').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs;

        _allCategories = {'All'};

        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          _allCategories.add(data['category']?.toString() ?? 'Unknown');
        }

        var filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = data['title']?.toString() ?? '';
          final category = data['category']?.toString() ?? '';
          
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            if (!title.toLowerCase().contains(q)) return false;
          }
          if (_selectedCategory != 'All' && category != _selectedCategory) return false;
          return true;
        }).toList();

        final totalItems = filteredDocs.length;
        final totalPages = (totalItems / _rowsPerPage).ceil();
        if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
        
        final startIndex = _currentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage < totalItems) ? startIndex + _rowsPerPage : totalItems;
        final pagedDocs = filteredDocs.sublist(startIndex, endIndex);

        bool allSelected = pagedDocs.isNotEmpty && pagedDocs.every((doc) => _selectedImageIds.contains(doc.id));
        bool someSelected = pagedDocs.any((doc) => _selectedImageIds.contains(doc.id)) && !allSelected;

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gallery Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Upload New Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _showUploadDialog,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filters
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
                          hintText: 'Search image titles...',
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
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category', isDense: true, border: OutlineInputBorder()),
                        items: _allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() { _selectedCategory = v!; _currentPage = 0; }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Batch Actions
              Row(
                children: [
                  Checkbox(
                    value: allSelected ? true : (someSelected ? null : false),
                    tristate: true,
                    onChanged: (bool? val) {
                      setState(() {
                        if (val == true || val == null) {
                          _selectedImageIds.addAll(pagedDocs.map((e) => e.id));
                        } else {
                          _selectedImageIds.removeAll(pagedDocs.map((e) => e.id));
                        }
                      });
                    },
                  ),
                  const Text('Select All on Page', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 24),
                  if (_selectedImageIds.isNotEmpty) ...[
                    Text('${_selectedImageIds.length} selected', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 16),
                    if (_isPerformingAction)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else ...[
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
                  ]
                ],
              ),
              const SizedBox(height: 12),

              // Grid List
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: pagedDocs.length,
                  itemBuilder: (context, index) {
                    final doc = pagedDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    final isSelected = _selectedImageIds.contains(id);
                    
                    final title = data['title'] ?? 'Untitled';
                    final category = data['category'] ?? '';
                    final imageUrl = data['imageUrl'] ?? '';
                    final ts = data['createdAt'] as Timestamp?;
                    final date = ts != null ? ts.toDate() : DateTime.now();
                    final dateStr = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';

                    return InkWell(
                      onTap: () => _showImageDetails(id, data),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isEmpty 
                              ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey))
                              : Image.network(
                                  ImageProxy.proxy(imageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) {
                                    print('[Debug] Image load error on grid card (Gallery): $e');
                                    return Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey));
                                  },
                                ),
                          ),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent]),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_toTitleCase(title), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                                      Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue, width: 2),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 4, left: 4,
                            child: Checkbox(
                              value: isSelected,
                              activeColor: Colors.blue,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) _selectedImageIds.add(id);
                                  else _selectedImageIds.remove(id);
                                });
                              },
                            ),
                          ),
                        ],
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
        );
      },
    );
  }
}

