import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/event.dart';
import '../services/fcm_admin_service.dart';
import '../utils/image_proxy.dart';

class EventsManager extends StatefulWidget {
  const EventsManager({super.key});

  @override
  State<EventsManager> createState() => _EventsManagerState();
}

class _EventsManagerState extends State<EventsManager> {
  String _searchQuery = '';
  
  int _currentPage = 0;
  final int _rowsPerPage = 20;

  final Set<String> _selectedEventIds = {};
  bool _isPerformingAction = false;

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

  void _showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: event.imageUrl.isEmpty 
                    ? Container(width: 400, height: 250, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 50, color: Colors.grey))
                    : Image.network(
                        ImageProxy.proxy(event.imageUrl),
                        width: 400,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 400,
                          height: 250,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                _DetailRow('Description:', event.description),
                _DetailRow('Venue:', event.venue),
                _DetailRow('Time:', event.programmeTime),
                _DetailRow('Start Date:', '${event.startDate.toLocal()}'.split(' ')[0]),
                _DetailRow('End Date:', '${event.endDate.toLocal()}'.split(' ')[0]),
                _DetailRow('Status:', event.isUpcoming ? 'Upcoming' : 'Past'),
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
                _showUploadDialog(event: event);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                _deleteEvent(event.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Delete')),
        ],
      )
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('events').doc(id).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showUploadDialog({Event? event}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: event?.title ?? '');
    final descCtrl = TextEditingController(text: event?.description ?? '');
    final venueCtrl = TextEditingController(text: event?.venue ?? '');
    final timeCtrl = TextEditingController(text: event?.programmeTime ?? '');
    
    DateTime startDate = event?.startDate ?? DateTime.now();
    DateTime endDate = event?.endDate ?? DateTime.now().add(const Duration(days: 1));
    bool isUpcoming = event?.isUpcoming ?? true;

    String thumbMode = event != null && event.imageUrl.isNotEmpty ? 'url' : 'file';
    final thumbUrlCtrl = TextEditingController(text: event?.imageUrl ?? '');
    Uint8List? thumbBytes;
    String? thumbFileName;
    
    bool isUploading = false;
    double progress = 0;

    Future<void> pickDate(bool isStart, StateSetter setDialogState) async {
      final date = await showDatePicker(
        context: context,
        initialDate: isStart ? startDate : endDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (date != null) {
        setDialogState(() {
          if (isStart) startDate = date;
          else endDate = date;
        });
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(event == null ? 'Create New Event' : 'Edit Event', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: venueCtrl,
                              decoration: const InputDecoration(labelText: 'Venue', border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: timeCtrl,
                              decoration: const InputDecoration(labelText: 'Time (e.g. 10:00 AM)', border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: ListTile(
                            title: const Text('Start Date'),
                            subtitle: Text('${startDate.toLocal()}'.split(' ')[0]),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => pickDate(true, setDialogState),
                          )),
                          Expanded(child: ListTile(
                            title: const Text('End Date'),
                            subtitle: Text('${endDate.toLocal()}'.split(' ')[0]),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => pickDate(false, setDialogState),
                          )),
                        ],
                      ),
                      SwitchListTile(
                        title: const Text('Is Upcoming Event?'),
                        value: isUpcoming,
                        onChanged: (val) => setDialogState(() => isUpcoming = val),
                      ),
                      const SizedBox(height: 16),
                      
                      const Text('Event Flyer / Image', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                if (res != null) setDialogState(() { thumbBytes = res.files.first.bytes; thumbFileName = res.files.first.name; });
                              },
                              icon: const Icon(Icons.image), label: const Text('Select Image'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(thumbFileName ?? 'No image selected', overflow: TextOverflow.ellipsis)),
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
                  if (thumbMode == 'file' && thumbBytes == null && event == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a flyer image')));
                    return;
                  } else if (thumbMode == 'url' && finalThumbUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter flyer URL')));
                    return;
                  }

                  setDialogState(() => isUploading = true);
                  
                  try {
                    if (thumbMode == 'file' && thumbBytes != null) {
                      final ref = FirebaseStorage.instance.ref('events/${DateTime.now().millisecondsSinceEpoch}_$thumbFileName');
                      final task = ref.putData(thumbBytes!);
                      task.snapshotEvents.listen((e) => setDialogState(() => progress = e.bytesTransferred / e.totalBytes));
                      await task;
                      finalThumbUrl = await ref.getDownloadURL();
                    }

                    final data = {
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'venue': venueCtrl.text.trim(),
                      'programmeTime': timeCtrl.text.trim(),
                      'startDate': Timestamp.fromDate(startDate),
                      'endDate': Timestamp.fromDate(endDate),
                      'isUpcoming': isUpcoming,
                      'imageUrl': finalThumbUrl,
                      'createdAt': FieldValue.serverTimestamp(),
                    };

                    if (event == null) {
                      await FirebaseFirestore.instance.collection('events').add(data);
                      // Auto Push Notification
                      await FcmAdminService.sendNotification(
                        title: '📅 Upcoming Event: ${titleCtrl.text.trim()}',
                        content: 'Join us on ${startDate.toLocal().toString().split(' ')[0]} at ${venueCtrl.text.trim()}. Tap for more details!',
                      );
                    } else {
                      await FirebaseFirestore.instance.collection('events').doc(event.id).update(data);
                    }
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(event == null ? 'Event created!' : 'Event updated!')));
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    if (mounted) setDialogState(() => isUploading = false);
                  }
                },
                child: Text(event == null ? 'Create' : 'Save Changes'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _applyBatchAction(String action) async {
    if (_selectedEventIds.isEmpty) return;
    setState(() => _isPerformingAction = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      if (action == 'Delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Confirm Bulk Delete'),
            content: Text('Delete ${_selectedEventIds.length} events?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Delete')),
            ],
          )
        );
        if (confirm != true) {
          setState(() => _isPerformingAction = false);
          return;
        }

        for (final id in _selectedEventIds) {
          final ref = FirebaseFirestore.instance.collection('events').doc(id);
          batch.delete(ref);
        }
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action "$action" applied.')));
        setState(() => _selectedEventIds.clear());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _isPerformingAction = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').orderBy('startDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs;

        var filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = data['title']?.toString() ?? '';
          
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            if (!title.toLowerCase().contains(q)) return false;
          }
          return true;
        }).toList();

        final totalItems = filteredDocs.length;
        final totalPages = (totalItems / _rowsPerPage).ceil();
        if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
        
        final startIndex = _currentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage < totalItems) ? startIndex + _rowsPerPage : totalItems;
        final pagedDocs = filteredDocs.sublist(startIndex, endIndex);

        bool allSelected = pagedDocs.isNotEmpty && pagedDocs.every((doc) => _selectedEventIds.contains(doc.id));
        bool someSelected = pagedDocs.any((doc) => _selectedEventIds.contains(doc.id)) && !allSelected;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Events Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ElevatedButton.icon(
                          onPressed: () => _showUploadDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Event'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search events...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 0; }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_selectedEventIds.isNotEmpty) ...[
                          DropdownButton<String>(
                            hint: const Text('Bulk Actions'),
                            items: ['Delete'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                            onChanged: (v) {
                              if (v != null) _applyBatchAction(v);
                            },
                          ),
                          const SizedBox(width: 16),
                          if (_isPerformingAction) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // Data Table
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                              columns: [
                                DataColumn(
                                  label: Checkbox(
                                    value: allSelected ? true : (someSelected ? null : false),
                                    tristate: true,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedEventIds.addAll(pagedDocs.map((d) => d.id));
                                        } else {
                                          _selectedEventIds.removeAll(pagedDocs.map((d) => d.id));
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const DataColumn(label: Text('Flyer', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Event Title', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Venue', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Date Created', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: pagedDocs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final event = Event.fromFirestore(doc);
                                final isSelected = _selectedEventIds.contains(event.id);

                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: (val) {
                                    setState(() {
                                      if (val == true) _selectedEventIds.add(event.id);
                                      else _selectedEventIds.remove(event.id);
                                    });
                                  },
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) _selectedEventIds.add(event.id);
                                            else _selectedEventIds.remove(event.id);
                                          });
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: event.imageUrl.isEmpty 
                                            ? Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 20))
                                            : Image.network(
                                                ImageProxy.proxy(event.imageUrl), 
                                                width: 50, 
                                                height: 50, 
                                                fit: BoxFit.cover,
                                                errorBuilder: (c,e,s) => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 20)),
                                              ),
                                        ),
                                      ),
                                      onTap: () => _showEventDetails(event),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 250,
                                        child: Text(
                                          event.title, 
                                          style: const TextStyle(fontWeight: FontWeight.w600), 
                                          overflow: TextOverflow.ellipsis, 
                                          maxLines: 2,
                                        ),
                                      ),
                                      onTap: () => _showEventDetails(event),
                                    ),
                                    DataCell(
                                      Text(event.venue),
                                      onTap: () => _showEventDetails(event),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: event.isUpcoming ? Colors.green.shade100 : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          event.isUpcoming ? 'Upcoming' : 'Past',
                                          style: TextStyle(
                                            color: event.isUpcoming ? Colors.green.shade700 : Colors.grey.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      onTap: () => _showEventDetails(event),
                                    ),
                                    DataCell(
                                      Text('${event.createdAt.toLocal()}'.split(' ')[0]),
                                      onTap: () => _showEventDetails(event),
                                    ),
                                    DataCell(
                                      Text('${event.startDate.toLocal()}'.split(' ')[0]),
                                      onTap: () => _showEventDetails(event),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      // Pagination Footer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
