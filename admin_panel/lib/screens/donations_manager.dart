import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class DonationsManager extends StatelessWidget {
  const DonationsManager({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donations Management',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create and manage donation options, bank accounts, and Paystack links.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDonationDialog(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Donation'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donations')
                  .orderBy('sortOrder')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No donations created yet.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(24),
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final batch = FirebaseFirestore.instance.batch();
                    final items = docs.toList();
                    final item = items.removeAt(oldIndex);
                    items.insert(newIndex, item);
                    for (var i = 0; i < items.length; i++) {
                      batch.update(items[i].reference, {'sortOrder': i});
                    }
                    batch.commit();
                  },
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isActive = data['isActive'] as bool? ?? true;
                    
                    return Card(
                      key: ValueKey(doc.id),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.volunteer_activism, color: Colors.blue),
                        title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (val) => doc.reference.update({'isActive': val}),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showDonationDialog(context, doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () => _deleteDonation(context, doc),
                            ),
                            const Icon(Icons.drag_handle, color: Colors.grey),
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
    );
  }

  void _showDonationDialog(BuildContext context, QueryDocumentSnapshot? doc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DonationFormDialog(doc: doc),
    );
  }

  Future<void> _deleteDonation(BuildContext context, QueryDocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Donation?'),
        content: Text('Are you sure you want to delete "${doc['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await doc.reference.delete();
    }
  }
}

class _DonationFormDialog extends StatefulWidget {
  const _DonationFormDialog({this.doc});
  final QueryDocumentSnapshot? doc;

  @override
  State<_DonationFormDialog> createState() => _DonationFormDialogState();
}

class _DonationFormDialogState extends State<_DonationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _fixedAmountCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNameCtrl;
  late TextEditingController _accountNumberCtrl;
  late TextEditingController _paystackCtrl;

  bool _isFixedAmount = false;
  bool _isActive = true;
  bool _saving = false;

  String _thumbMode = 'file';
  late TextEditingController _thumbUrlCtrl;
  Uint8List? _thumbBytes;
  String? _thumbFileName;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data() as Map<String, dynamic>?;
    _titleCtrl = TextEditingController(text: data?['title'] ?? '');
    _descCtrl = TextEditingController(text: data?['description'] ?? '');
    
    _isFixedAmount = data?['isFixedAmount'] ?? false;
    final fixedAmt = data?['fixedAmount'] as num?;
    _fixedAmountCtrl = TextEditingController(text: fixedAmt != null ? fixedAmt.toString() : '');
    
    _bankNameCtrl = TextEditingController(text: data?['bankName'] ?? '');
    _accountNameCtrl = TextEditingController(text: data?['accountName'] ?? '');
    _accountNumberCtrl = TextEditingController(text: data?['accountNumber'] ?? '');
    _paystackCtrl = TextEditingController(text: data?['paystackLink'] ?? '');
    
    final imgUrl = data?['imageUrl'] ?? '';
    _thumbMode = (imgUrl.isNotEmpty && !imgUrl.contains('firebase')) ? 'url' : 'file';
    _thumbUrlCtrl = TextEditingController(text: imgUrl);

    _isActive = data?['isActive'] ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _fixedAmountCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _paystackCtrl.dispose();
    _thumbUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String finalImgUrl = _thumbUrlCtrl.text.trim();
      
      if (_thumbMode == 'file' && _thumbBytes != null) {
        final ref = FirebaseStorage.instance.ref('donations/${DateTime.now().millisecondsSinceEpoch}_$_thumbFileName');
        final task = ref.putData(_thumbBytes!);
        task.snapshotEvents.listen((e) => setState(() => _progress = e.bytesTransferred / e.totalBytes));
        await task;
        finalImgUrl = await ref.getDownloadURL();
      }

      final collection = FirebaseFirestore.instance.collection('donations');
      
      int sortOrder = 0;
      if (widget.doc == null) {
        final snap = await collection.orderBy('sortOrder', descending: true).limit(1).get();
        if (snap.docs.isNotEmpty) {
          sortOrder = ((snap.docs.first.data()['sortOrder'] as num?)?.toInt() ?? 0) + 1;
        }
      } else {
        sortOrder = (widget.doc!.data() as Map<String, dynamic>)['sortOrder'] as int? ?? 0;
      }

      final payload = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'isFixedAmount': _isFixedAmount,
        'fixedAmount': _isFixedAmount ? double.tryParse(_fixedAmountCtrl.text.trim()) : null,
        'bankName': _bankNameCtrl.text.trim().isEmpty ? null : _bankNameCtrl.text.trim(),
        'accountName': _accountNameCtrl.text.trim().isEmpty ? null : _accountNameCtrl.text.trim(),
        'accountNumber': _accountNumberCtrl.text.trim().isEmpty ? null : _accountNumberCtrl.text.trim(),
        'paystackLink': _paystackCtrl.text.trim().isEmpty ? null : _paystackCtrl.text.trim(),
        'imageUrl': finalImgUrl.isEmpty ? null : finalImgUrl,
        'sortOrder': sortOrder,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.doc == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await collection.add(payload);
      } else {
        await widget.doc!.reference.update(payload);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.doc != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Donation' : 'Add Donation'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('General Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Donation Title *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                const Text('Donation Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Radio(value: 'url', groupValue: _thumbMode, onChanged: (v) => setState(() => _thumbMode = v.toString())),
                    const Text('URL'),
                    Radio(value: 'file', groupValue: _thumbMode, onChanged: (v) => setState(() => _thumbMode = v.toString())),
                    const Text('Upload File'),
                  ],
                ),
                if (_thumbMode == 'url')
                  TextFormField(
                    controller: _thumbUrlCtrl,
                    decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
                  )
                else
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? res = await FilePicker.pickFiles(type: FileType.image, withData: true);
                          if (res != null) {
                            setState(() { 
                              _thumbBytes = res.files.first.bytes; 
                              _thumbFileName = res.files.first.name; 
                            });
                          }
                        },
                        icon: const Icon(Icons.image), label: const Text('Select Image'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_thumbFileName ?? 'No image selected', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                if (_saving && _thumbMode == 'file' && _thumbBytes != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 4),
                      Text('Uploading... ${(_progress * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                const SizedBox(height: 24),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fixed Amount'),
                  subtitle: const Text('Is this for a fixed sum, or open-ended?'),
                  value: _isFixedAmount,
                  onChanged: (v) => setState(() => _isFixedAmount = v),
                ),
                if (_isFixedAmount) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _fixedAmountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount (₦) *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (!_isFixedAmount) return null;
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 32),
                
                const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Provide bank details, a Paystack link, or both.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _bankNameCtrl,
                  decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountNameCtrl,
                  decoration: const InputDecoration(labelText: 'Account Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountNumberCtrl,
                  decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 24),
                TextFormField(
                  controller: _paystackCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Paystack Payment Link',
                    border: OutlineInputBorder(),
                    hintText: 'https://paystack.com/pay/...',
                  ),
                ),
                
                const SizedBox(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Inactive donations are hidden from users.'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
