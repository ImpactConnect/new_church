import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/image_proxy.dart';
import 'package:file_picker/file_picker.dart';
import '../models/carousel_item.dart';

class CarouselManager extends StatefulWidget {
  const CarouselManager({super.key});

  @override
  State<CarouselManager> createState() => _CarouselManagerState();
}

class _CarouselManagerState extends State<CarouselManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _orderController = TextEditingController(text: '0');
  
  bool _isActive = true;
  CarouselLinkType _linkType = CarouselLinkType.inApp;
  CarouselItemType _itemType = CarouselItemType.other;

  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageFileName = result.files.first.name;
      });
    }
  }

  Future<void> _saveCarousel() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image banner')));
      return;
    }

    setState(() => _isUploading = true);
    
    try {
      final imageRef = FirebaseStorage.instance.ref('carousel/\${DateTime.now().millisecondsSinceEpoch}_\$_imageFileName');
      await imageRef.putData(_imageBytes!);
      final imageUrl = await imageRef.getDownloadURL();

      final data = {
        'title': _titleController.text,
        'description': _descController.text,
        'imageUrl': imageUrl,
        'linkUrl': _linkUrlController.text.isNotEmpty ? _linkUrlController.text : null,
        'linkType': _linkType.toString().split('.').last,
        'itemType': _itemType.toString().split('.').last,
        'isActive': _isActive,
        'order': int.tryParse(_orderController.text) ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('carousel_items').add(data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner saved!')));
        _titleController.clear();
        _descController.clear();
        _linkUrlController.clear();
        _orderController.text = '0';
        setState(() {
          _imageBytes = null;
          _imageFileName = null;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Home Screen Banner', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
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
                            value: _itemType,
                            decoration: const InputDecoration(labelText: 'Target Type', border: OutlineInputBorder()),
                            items: CarouselItemType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                            onChanged: (val) => setState(() => _itemType = val!),
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
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Upload Banner Image'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_imageFileName ?? 'No image selected')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_isUploading) const Center(child: CircularProgressIndicator())
                    else ElevatedButton.icon(
                      onPressed: _saveCarousel,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Banner'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Banners', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('carousel_items').orderBy('order').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          final item = CarouselItem.fromFirestore(data, snapshot.data!.docs[index].id);
                          return Card(
                            child: ListTile(
                              leading: item.imageUrl != null 
                                ? Image.network(ImageProxy.proxy(item.imageUrl!), width: 80, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.error))
                                : const Icon(Icons.image),
                              title: Text(item.title),
                              subtitle: Text('Order: \${item.order} | Active: \${item.isActive}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => FirebaseFirestore.instance.collection('carousel_items').doc(item.id).delete(),
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
        ],
      ),
    );
  }
}
