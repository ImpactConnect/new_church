import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/community_post.dart';
import '../../models/community_user.dart';
import '../../services/community_post_service.dart';

class CreateCommunityPostScreen extends StatefulWidget {
  final CommunityUser currentUser;
  final PostType initialType;
  const CreateCommunityPostScreen({Key? key, required this.currentUser, this.initialType = PostType.post}) : super(key: key);

  @override
  State<CreateCommunityPostScreen> createState() => _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _postService = CommunityPostService();
  
  late PostType _selectedType;
  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = pickedFile);
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('community_posts')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
          
      if (kIsWeb) {
        await ref.putData(await image.readAsBytes());
      } else {
        await ref.putFile(File(image.path));
      }
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter content for your post')));
      return;
    }

    if (_selectedType != PostType.post && title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
      if (!mounted) return;
      if (imageUrl == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
        return;
      }
    }

    final post = await _postService.createPost(
      author: widget.currentUser,
      title: _selectedType == PostType.post ? '' : title,
      content: content,
      type: _selectedType,
      imageUrls: _selectedType == PostType.post && imageUrl != null ? [imageUrl] : null,
      bannerUrl: _selectedType == PostType.article ? imageUrl : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (post != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create post')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the height based on keyboard visibility
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9, // max 90% of screen height
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                Text(
                  _selectedType == PostType.post 
                      ? 'Create Post' 
                      : _selectedType == PostType.question 
                          ? 'Ask a Question' 
                          : 'Write Article',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_isLoading)
                  const SizedBox(width: 48, height: 20, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                else
                  TextButton(
                    onPressed: _submitPost,
                    child: Text('POST', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field (Only for Questions and Articles)
                  if (_selectedType != PostType.post) ...[
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: _selectedType == PostType.question ? 'What is your question?' : 'Article Title',
                        hintStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLength: 100,
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                  ],

                  // Content Field
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: _selectedType == PostType.question 
                          ? 'Share the details of your question...' 
                          : _selectedType == PostType.article 
                              ? 'Write your article content here...' 
                              : "What's on your mind?",
                      border: InputBorder.none,
                    ),
                    maxLines: _selectedType == PostType.article ? null : 6,
                    minLines: 3,
                    maxLength: _selectedType == PostType.article ? 5000 : 500,
                  ),
                  const SizedBox(height: 16),

                  // Image Picker
                  if (_selectedType != PostType.question) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb 
                                    ? Image.network(_selectedImage!.path, fit: BoxFit.cover) 
                                    : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to add an image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
