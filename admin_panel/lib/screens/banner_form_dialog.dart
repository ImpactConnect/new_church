import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../models/carousel_item.dart';
import '../utils/image_proxy.dart';

class BannerFormDialog extends StatefulWidget {
  final CarouselItem? bannerToEdit;

  const BannerFormDialog({super.key, this.bannerToEdit});

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _orderController = TextEditingController(text: '0');
  
  bool _isActive = true;
  bool _displayTitle = true;
  CarouselLinkType _linkType = CarouselLinkType.inApp;
  CarouselItemType _itemType = CarouselItemType.other;

  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isUploading = false;
  
  String? _existingImageUrl;
  String? _itemId;

  @override
  void initState() {
    super.initState();
    if (widget.bannerToEdit != null) {
      final item = widget.bannerToEdit!;
      _existingImageUrl = item.imageUrl;
      _titleController.text = item.title;
      _descController.text = item.description ?? '';
      _linkUrlController.text = item.linkUrl ?? '';
      _orderController.text = item.order.toString();
      _isActive = item.isActive;
      _displayTitle = item.displayTitle;
      _linkType = item.linkType ?? CarouselLinkType.inApp;
      _itemType = item.itemType;
      _itemId = item.itemId;
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

  Future<void> _saveCarousel() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image banner')));
      return;
    }

    setState(() => _isUploading = true);
    
    try {
      String? imageUrl = _existingImageUrl;
      if (_imageBytes != null) {
        final imageRef = FirebaseStorage.instance.ref('carousel/${DateTime.now().millisecondsSinceEpoch}_$_imageFileName');
        await imageRef.putData(_imageBytes!);
        imageUrl = await imageRef.getDownloadURL();
      }

      final data = {
        'title': _titleController.text,
        'description': _descController.text,
        'imageUrl': imageUrl,
        'linkUrl': _linkUrlController.text.isNotEmpty ? _linkUrlController.text : null,
        'linkType': _linkType.toString().split('.').last,
        'itemType': _itemType.toString().split('.').last,
        'isActive': _isActive,
        'displayTitle': _displayTitle,
        'order': int.tryParse(_orderController.text) ?? 0,
        'itemId': _itemId,
      };

      if (widget.bannerToEdit == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('carousel_items').add(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner saved!')));
      } else {
        await FirebaseFirestore.instance.collection('carousel_items').doc(widget.bannerToEdit!.id).update(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner updated!')));
      }
      
      if (mounted) {
        Navigator.pop(context); // Close the dialog
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildEntitySelector() {
    if (_itemType == CarouselItemType.other) return const SizedBox.shrink();

    String collectionName = '';
    if (_itemType == CarouselItemType.sermon) collectionName = 'sermons';
    else if (_itemType == CarouselItemType.event) collectionName = 'events';
    else if (_itemType == CarouselItemType.blog) collectionName = 'blogs';
    else if (_itemType == CarouselItemType.video) collectionName = 'videos';
    else if (_itemType == CarouselItemType.library) collectionName = 'books';
    else if (_itemType == CarouselItemType.liveStream) collectionName = 'live_streams';

    if (collectionName.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final items = snapshot.data!.docs;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DropdownButtonFormField<String?>(
            isExpanded: true,
            value: _itemId != null && items.any((doc) => doc.id == _itemId) ? _itemId : null,
            decoration: InputDecoration(labelText: 'Select ${_itemType.name}', border: const OutlineInputBorder()),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Main Page Only')),
              ...items.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? data['eventName'] ?? doc.id;
                return DropdownMenuItem<String?>(value: doc.id, child: Text(title));
              }).toList(),
            ],
            onChanged: (val) {
              setState(() {
                _itemId = val;
                if (_itemType == CarouselItemType.sermon) _linkUrlController.text = '/sermons';
                else if (_itemType == CarouselItemType.event) _linkUrlController.text = '/events';
                else if (_itemType == CarouselItemType.blog) _linkUrlController.text = '/blog';
                else if (_itemType == CarouselItemType.video) _linkUrlController.text = '/videos';
                else if (_itemType == CarouselItemType.library) _linkUrlController.text = '/library';
                else if (_itemType == CarouselItemType.liveStream) _linkUrlController.text = '/live';
                else if (_itemType == CarouselItemType.home) _linkUrlController.text = '';
                else if (_itemType == CarouselItemType.donation) _linkUrlController.text = '';
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.view_carousel, color: Theme.of(context).primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          widget.bannerToEdit != null ? 'Edit Banner' : 'Create New Banner',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CarouselItemType>(
                        isExpanded: true,
                        value: _itemType,
                        decoration: const InputDecoration(labelText: 'Target Type', border: OutlineInputBorder()),
                        items: CarouselItemType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                        onChanged: (val) => setState(() {
                          _itemType = val!;
                          _itemId = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<CarouselLinkType>(
                        value: _linkType,
                        decoration: const InputDecoration(labelText: 'Link Type', border: OutlineInputBorder()),
                        items: CarouselLinkType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                        onChanged: (val) => setState(() => _linkType = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEntitySelector(),
                TextFormField(
                  controller: _linkUrlController,
                  decoration: const InputDecoration(labelText: 'Action Link URL (e.g. /sermons or https://)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _orderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sort Order', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Is Active?'),
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Display Title on App?'),
                        value: _displayTitle,
                        onChanged: (val) => setState(() => _displayTitle = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Select Image'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _imageBytes != null
                          ? Image.memory(_imageBytes!, height: 80, fit: BoxFit.contain, alignment: Alignment.centerLeft)
                          : (_existingImageUrl != null
                              ? Image.network(ImageProxy.proxy(_existingImageUrl!), height: 80, fit: BoxFit.contain, alignment: Alignment.centerLeft, errorBuilder: (c,e,s) => const Text('Error loading image'))
                              : const Text('No image selected')),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_isUploading) const Center(child: CircularProgressIndicator())
                else Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveCarousel,
                        icon: const Icon(Icons.save),
                        label: Text(widget.bannerToEdit == null ? 'Save Banner' : 'Update Banner'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
