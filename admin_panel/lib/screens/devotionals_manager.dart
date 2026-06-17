import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/devotional.dart';
import '../services/fcm_admin_service.dart';

class DevotionalsManager extends StatefulWidget {
  const DevotionalsManager({super.key});

  @override
  State<DevotionalsManager> createState() => _DevotionalsManagerState();
}

class _DevotionalsManagerState extends State<DevotionalsManager> {
  String _searchQuery = '';
  int _currentPage = 0;
  final int _rowsPerPage = 20;

  final Set<String> _selectedDevotionalIds = {};
  bool _isPerformingAction = false;

  void _showUploadDialog({Devotional? devotional}) {
    final titleCtrl = TextEditingController(text: devotional?.topic ?? '');
    final authorCtrl = TextEditingController(text: devotional?.author ?? '');
    final verseCtrl = TextEditingController(
      text: (devotional != null && devotional.bibleVerse.contains('-') && devotional.bibleVerseText.isEmpty)
          ? devotional.bibleVerse.split('-')[0].trim()
          : devotional?.bibleVerse ?? '',
    );
    final verseTextCtrl = TextEditingController(
      text: (devotional?.bibleVerseText.isNotEmpty == true)
          ? devotional!.bibleVerseText
          : (devotional != null && devotional.bibleVerse.contains('-')
              ? devotional.bibleVerse.split('-').sublist(1).join('-').trim()
              : ''),
    );
    final contentCtrl = TextEditingController(text: devotional?.content ?? '');
    final prayerCtrl = TextEditingController(
      text: devotional?.prayerPoints.join('\n') ?? '',
    );
    DateTime selectedDate = devotional?.date ?? DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSaving = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(devotional == null ? 'Create Devotional' : 'Edit Devotional'),
              content: SizedBox(
                width: 500,
                child: Form(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: authorCtrl,
                                decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: verseCtrl,
                                decoration: const InputDecoration(labelText: 'Bible Verse (e.g. John 3:16)', border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: verseTextCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Bible Verse Text', border: OutlineInputBorder(), alignLabelWithHint: true),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Devotional Date'),
                          subtitle: Text('${selectedDate.toLocal()}'.split(' ')[0]),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) setDialogState(() => selectedDate = date);
                          },
                          tileColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: contentCtrl,
                          maxLines: 8,
                          decoration: const InputDecoration(labelText: 'Main Content', border: OutlineInputBorder(), alignLabelWithHint: true),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: prayerCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Prayer Points (One per line)', border: OutlineInputBorder(), alignLabelWithHint: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Topic and Content are required.')));
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    try {
                      final prayerPoints = prayerCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
                      final data = {
                        'topic': titleCtrl.text.trim(),
                        'author': authorCtrl.text.trim(),
                        'bibleVerse': verseCtrl.text.trim(),
                        'bibleVerseText': verseTextCtrl.text.trim(),
                        'content': contentCtrl.text.trim(),
                        'prayerPoints': prayerPoints,
                        'date': Timestamp.fromDate(selectedDate),
                        'createdAt': FieldValue.serverTimestamp(),
                      };

                      if (devotional == null) {
                        await FirebaseFirestore.instance.collection('devotionals').add(data);
                        
                        final contentStr = contentCtrl.text.trim();
                        final preview = contentStr.length > 50 ? '${contentStr.substring(0, 50)}...' : contentStr;
                        
                        await FcmAdminService.sendNotification(
                          title: '📖 Daily Devotional: ${titleCtrl.text.trim()}',
                          content: preview,
                          sendAfter: selectedDate.isAfter(DateTime.now()) 
                              ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6, 0)
                              : null,
                        );
                      } else {
                        await FirebaseFirestore.instance.collection('devotionals').doc(devotional.id).update(data);
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(devotional == null ? 'Devotional published!' : 'Devotional updated!')));
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : Text(devotional == null ? 'Publish' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDevotionalDetails(Devotional dev) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Devotional Details'),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow('Topic:', dev.topic),
                  _DetailRow('Author:', dev.author),
                  _DetailRow('Bible Verse:', dev.bibleVerse.contains('-') && dev.bibleVerseText.isEmpty ? dev.bibleVerse.split('-')[0].trim() : dev.bibleVerse),
                  const SizedBox(height: 8),
                  const Text('Bible Verse Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      dev.bibleVerseText.isNotEmpty 
                        ? dev.bibleVerseText 
                        : (dev.bibleVerse.contains('-') ? dev.bibleVerse.split('-').sublist(1).join('-').trim() : dev.bibleVerse), 
                      style: const TextStyle(fontStyle: FontStyle.italic, height: 1.5)
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow('Devotional Date:', '${dev.date.toLocal()}'.split(' ')[0]),
                  _DetailRow('Date Created:', '${dev.createdAt.toLocal()}'.split(' ')[0]),
                  const SizedBox(height: 16),
                  const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(dev.content, style: const TextStyle(height: 1.5)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Prayer Points:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (dev.prayerPoints.isEmpty) const Text('None')
                  else ...dev.prayerPoints.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(p)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete Devotional'),
                    content: const Text('Are you sure you want to delete this devotional?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseFirestore.instance.collection('devotionals').doc(dev.id).delete();
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              onPressed: () {
                Navigator.pop(context);
                _showUploadDialog(devotional: dev);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyBatchAction(String action) async {
    if (_selectedDevotionalIds.isEmpty) return;
    
    setState(() => _isPerformingAction = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      if (action == 'Delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Confirm Bulk Delete'),
            content: Text('Delete ${_selectedDevotionalIds.length} devotionals?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Delete')),
            ],
          ),
        );

        if (confirm != true) {
          setState(() => _isPerformingAction = false);
          return;
        }

        for (final id in _selectedDevotionalIds) {
          batch.delete(FirebaseFirestore.instance.collection('devotionals').doc(id));
        }
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action "$action" applied.')));
        setState(() => _selectedDevotionalIds.clear());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) setState(() => _currentPage++);
  }

  void _prevPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Row(
            children: [
              const Text('Devotionals Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showUploadDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create New Devotional'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search devotionals...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => setState(() { _searchQuery = val.toLowerCase(); _currentPage = 0; }),
                          ),
                        ),
                        const Spacer(flex: 1),
                        if (_selectedDevotionalIds.isNotEmpty) ...[
                          Text('${_selectedDevotionalIds.length} selected'),
                          const SizedBox(width: 16),
                          PopupMenuButton<String>(
                            onSelected: _applyBatchAction,
                            child: ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.settings),
                              label: const Text('Bulk Actions'),
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'Delete', child: Text('Delete Selected', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('devotionals').orderBy('date', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        var docs = snapshot.data!.docs;

                        if (_searchQuery.isNotEmpty) {
                          docs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final topic = (data['topic'] ?? '').toString().toLowerCase();
                            final author = (data['author'] ?? '').toString().toLowerCase();
                            return topic.contains(_searchQuery) || author.contains(_searchQuery);
                          }).toList();
                        }

                        final totalItems = docs.length;
                        final totalPages = (totalItems / _rowsPerPage).ceil();
                        
                        if (_currentPage >= totalPages && totalPages > 0) {
                          _currentPage = totalPages - 1;
                        }

                        final startIndex = _currentPage * _rowsPerPage;
                        final endIndex = (startIndex + _rowsPerPage > totalItems) ? totalItems : startIndex + _rowsPerPage;
                        final pagedDocs = docs.sublist(startIndex, endIndex);

                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                                    columns: [
                                      DataColumn(
                                        label: Checkbox(
                                          value: _selectedDevotionalIds.length == pagedDocs.length && pagedDocs.isNotEmpty,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedDevotionalIds.addAll(pagedDocs.map((d) => d.id));
                                              } else {
                                                _selectedDevotionalIds.clear();
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const DataColumn(label: Text('Topic', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Author', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Bible Verse', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Devotional Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Date Created', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: pagedDocs.map((doc) {
                                      final dev = Devotional.fromFirestore(doc);
                                      final isSelected = _selectedDevotionalIds.contains(dev.id);

                                      return DataRow(
                                        selected: isSelected,
                                        onSelectChanged: (_) => _showDevotionalDetails(dev),
                                        cells: [
                                          DataCell(
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedDevotionalIds.add(dev.id);
                                                  } else {
                                                    _selectedDevotionalIds.remove(dev.id);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 250,
                                              child: Text(
                                                dev.topic, 
                                                style: const TextStyle(fontWeight: FontWeight.w600), 
                                                overflow: TextOverflow.ellipsis, 
                                                maxLines: 2,
                                              ),
                                            ),
                                            onTap: () => _showDevotionalDetails(dev),
                                          ),
                                          DataCell(
                                            Text(dev.author),
                                            onTap: () => _showDevotionalDetails(dev),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 150,
                                              child: Text(
                                                dev.bibleVerse.contains('-') ? dev.bibleVerse.split('-')[0].trim() : dev.bibleVerse,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            onTap: () => _showDevotionalDetails(dev),
                                          ),
                                          DataCell(
                                            Text('${dev.date.toLocal()}'.split(' ')[0]),
                                            onTap: () => _showDevotionalDetails(dev),
                                          ),
                                          DataCell(
                                            Text('${dev.createdAt.toLocal()}'.split(' ')[0]),
                                            onTap: () => _showDevotionalDetails(dev),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            
                            if (totalItems > 0)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Showing ${startIndex + 1} to $endIndex of $totalItems entries', style: TextStyle(color: Colors.grey.shade600)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: _currentPage > 0 ? _prevPage : null,
                                        ),
                                        Text('Page ${_currentPage + 1} of ${totalPages > 0 ? totalPages : 1}'),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: _currentPage < totalPages - 1 ? () => _nextPage(totalPages) : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
