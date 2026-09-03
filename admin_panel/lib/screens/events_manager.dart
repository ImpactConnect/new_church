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

class _EventsManagerState extends State<EventsManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _searchQuery = '';
  int _currentPage = 0;
  final int _rowsPerPage = 20;

  final Set<String> _selectedEventIds = {};
  bool _isPerformingAction = false;

  // Tab 2 (Monthly Calendar) filters & state
  int _calSelectedYear = DateTime.now().year;
  int _calSelectedMonth = DateTime.now().month;
  bool _isLoadingCal = false;
  List<DocumentSnapshot> _monthlyCalendarDocs = [];

  static const List<String> _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _loadMonthlyCalendar();
      }
    });
    _loadMonthlyCalendar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyCalendar() async {
    setState(() => _isLoadingCal = true);
    try {
      final docs = await _fetchMonthlyCalendarDocs();
      if (mounted) {
        setState(() {
          _monthlyCalendarDocs = docs;
          _isLoadingCal = false;
        });
      }
    } catch (e) {
      print('Error loading monthly calendar: $e');
      if (mounted) {
        setState(() {
          _monthlyCalendarDocs = [];
          _isLoadingCal = false;
        });
      }
    }
  }

  Future<List<DocumentSnapshot>> _fetchMonthlyCalendarDocs() async {
    final Map<String, DocumentSnapshot> docsMap = {};

    // 1. Fetch from root 'events' collection
    try {
      final rootSnap =
          await FirebaseFirestore.instance.collection('events').get();
      for (final doc in rootSnap.docs) {
        docsMap[doc.id] = doc;
      }
    } catch (e) {
      print('Root events fetch error: $e');
    }

    // 2. Fetch from branch events subcollections
    try {
      final branchesSnap =
          await FirebaseFirestore.instance.collection('branches').get();
      for (final branchDoc in branchesSnap.docs) {
        final bEventsSnap = await branchDoc.reference.collection('events').get();
        for (final doc in bEventsSnap.docs) {
          if (!docsMap.containsKey(doc.id)) {
            docsMap[doc.id] = doc;
          }
        }
      }
    } catch (e) {
      print('Branch subcollections fetch error: $e');
    }

    final List<DocumentSnapshot> monthlyCalendarList = [];

    for (final doc in docsMap.values) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final status = (data['status']?.toString() ?? 'approved').toLowerCase();
        if (status != 'approved') continue;

        final rawDate = data['startDate'] ?? data['dateTime'] ?? data['date'];
        DateTime dt = DateTime.now();
        if (rawDate != null) {
          if (rawDate is Timestamp) {
            dt = rawDate.toDate();
          } else if (rawDate is DateTime) {
            dt = rawDate;
          } else {
            dt = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
          }
        }

        if (dt.year == _calSelectedYear && dt.month == _calSelectedMonth) {
          monthlyCalendarList.add(doc);
        }
      } catch (_) {}
    }

    monthlyCalendarList.sort((a, b) {
      final da = (a.data() as Map<String, dynamic>)['startDate'];
      final db = (b.data() as Map<String, dynamic>)['startDate'];
      DateTime dta = DateTime.now();
      DateTime dtb = DateTime.now();
      if (da is Timestamp) dta = da.toDate();
      if (db is Timestamp) dtb = db.toDate();
      return dta.compareTo(dtb);
    });

    return monthlyCalendarList;
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
                      ? Container(
                          width: 400,
                          height: 250,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image,
                              size: 50, color: Colors.grey))
                      : Image.network(
                          ImageProxy.proxy(event.imageUrl),
                          width: 400,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 400,
                            height: 250,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image,
                                size: 50, color: Colors.grey),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                _DetailRow('Description:', event.description),
                _DetailRow('Venue:', event.venue),
                _DetailRow('Time:', event.programmeTime),
                _DetailRow('Start Date:', '${event.startDate.toLocal()}'.split(' ')[0]),
                _DetailRow('End Date:', '${event.endDate.toLocal()}'.split(' ')[0]),
                if (event.joinLink.isNotEmpty) _DetailRow('Join Link:', event.joinLink),
                _DetailRow('Recurrence:', event.recurrence.toUpperCase()),
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
              label: const Text('Edit Details'),
              onPressed: () {
                Navigator.pop(context);
                _showUploadDialog(event: event);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
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
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(c, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                    child: const Text('Delete')),
              ],
            ));

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('events').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Event deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showUploadDialog(
      {Event? event,
      String? defaultTitle,
      DateTime? defaultDate,
      String? defaultVenue}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: event?.title ?? defaultTitle ?? '');
    final descCtrl = TextEditingController(text: event?.description ?? '');
    final venueCtrl =
        TextEditingController(text: event?.venue ?? defaultVenue ?? 'Main Sanctuary');
    final timeCtrl =
        TextEditingController(text: event?.programmeTime ?? '9:00 AM - 12:00 PM');
    final joinLinkCtrl = TextEditingController(text: event?.joinLink ?? '');

    DateTime startDate = event?.startDate ?? defaultDate ?? DateTime.now();
    DateTime endDate =
        event?.endDate ?? defaultDate ?? DateTime.now().add(const Duration(days: 1));
    String recurrence = event?.recurrence ?? 'none';

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
        lastDate: DateTime(2035),
      );
      if (date != null) {
        setDialogState(() {
          if (isStart) {
            startDate = date;
            if (endDate.isBefore(startDate)) endDate = startDate;
          } else {
            endDate = date;
          }
        });
      }
    }

    showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(event == null
                  ? 'Enrich & Publish Event to App'
                  : 'Edit Published App Event'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Event Title',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description & Agenda Details',
                            border: OutlineInputBorder(),
                            hintText:
                                'Add agenda, guest ministers, or special instructions…',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: venueCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Venue / Location',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: timeCtrl,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Time (e.g. 10:00 AM - 12:00 PM)',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.access_time),
                                ),
                                onTap: () async {
                                  final startTime = await showTimePicker(
                                    context: context,
                                    initialTime: const TimeOfDay(hour: 10, minute: 0),
                                    helpText: 'Select Start Time',
                                  );
                                  if (startTime != null && context.mounted) {
                                    final endTime = await showTimePicker(
                                      context: context,
                                      initialTime: startTime,
                                      helpText: 'Select End Time',
                                    );
                                    if (endTime != null && context.mounted) {
                                      final startStr = startTime.format(context);
                                      final endStr = endTime.format(context);
                                      timeCtrl.text = '$startStr - $endStr';
                                    }
                                  }
                                },
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: const Text('Start Date'),
                                subtitle: Text('${startDate.toLocal()}'.split(' ')[0]),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () => pickDate(true, setDialogState),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: const Text('End Date'),
                                subtitle: Text('${endDate.toLocal()}'.split(' ')[0]),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () => pickDate(false, setDialogState),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: joinLinkCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Join Link (Zoom, Meet, Telegram, etc.)',
                            border: OutlineInputBorder(),
                            hintText: 'https://...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: recurrence,
                          decoration: const InputDecoration(
                              labelText: 'Recurrence', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(
                                value: 'none', child: Text('None (One-time event)')),
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => recurrence = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Event Flyer / Banner Image',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Radio<String>(
                                value: 'url',
                                groupValue: thumbMode,
                                onChanged: (v) =>
                                    setDialogState(() => thumbMode = v.toString())),
                            const Text('URL'),
                            Radio<String>(
                                value: 'file',
                                groupValue: thumbMode,
                                onChanged: (v) =>
                                    setDialogState(() => thumbMode = v.toString())),
                            const Text('Upload File'),
                          ],
                        ),
                        if (thumbMode == 'url')
                          TextFormField(
                            controller: thumbUrlCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Image URL', border: OutlineInputBorder()),
                          )
                        else
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  FilePickerResult? res = await FilePicker.pickFiles(
                                      type: FileType.image, withData: true);
                                  if (res != null) {
                                    setDialogState(() {
                                      thumbBytes = res.files.first.bytes;
                                      thumbFileName = res.files.first.name;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.image),
                                label: const Text('Select Image'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(thumbFileName ?? 'No image selected',
                                      overflow: TextOverflow.ellipsis)),
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
                if (!isUploading)
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                if (!isUploading)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      String finalThumbUrl = thumbUrlCtrl.text.trim();
                      if (thumbMode == 'file' &&
                          thumbBytes == null &&
                          event == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Select a flyer image')));
                        return;
                      }

                      setDialogState(() => isUploading = true);

                      try {
                        if (thumbMode == 'file' && thumbBytes != null) {
                          final ref = FirebaseStorage.instance.ref(
                              'events/${DateTime.now().millisecondsSinceEpoch}_$thumbFileName');
                          final task = ref.putData(thumbBytes!);
                          task.snapshotEvents.listen((e) => setDialogState(
                              () => progress = e.bytesTransferred / e.totalBytes));
                          await task;
                          finalThumbUrl = await ref.getDownloadURL();
                        }

                        final docId = event?.id.isNotEmpty == true
                            ? event!.id
                            : FirebaseFirestore.instance.collection('events').doc().id;

                        final data = {
                          'id': docId,
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'venue': venueCtrl.text.trim(),
                          'location': venueCtrl.text.trim(),
                          'programmeTime': timeCtrl.text.trim(),
                          'startDate': Timestamp.fromDate(startDate),
                          'endDate': Timestamp.fromDate(endDate),
                          'joinLink': joinLinkCtrl.text.trim(),
                          'recurrence': recurrence,
                          'imageUrl': finalThumbUrl,
                          'status': 'approved',
                          'isPublishedToApp': true,
                          'year': startDate.year,
                          'updatedAt': FieldValue.serverTimestamp(),
                          if (event == null) 'createdAt': FieldValue.serverTimestamp(),
                        };

                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(docId)
                            .set(data, SetOptions(merge: true));

                        // Push notification
                        if (event == null) {
                          await FcmAdminService.sendNotification(
                            title: '📅 Upcoming Event: ${titleCtrl.text.trim()}',
                            content:
                                'Join us on ${startDate.toLocal().toString().split(' ')[0]} at ${venueCtrl.text.trim()}. Tap for more details!',
                          );
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(event == null
                                      ? 'Event published on App!'
                                      : 'Event details updated!')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      } finally {
                        if (mounted) setDialogState(() => isUploading = false);
                      }
                    },
                    child: Text(event == null ? 'Publish to App' : 'Save Changes'),
                  ),
              ],
            );
          },
        );
      },
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
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(c, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white),
                        child: const Text('Delete')),
                  ],
                ));
        if (confirm != true) {
          setState(() => _isPerformingAction = false);
          return;
        }

        for (final id in _selectedEventIds) {
          final ref =
              FirebaseFirestore.instance.collection('events').doc(id);
          batch.delete(ref);
        }
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action "$action" applied.')));
        setState(() => _selectedEventIds.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    if (mounted) setState(() => _isPerformingAction = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Events Management',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    ElevatedButton.icon(
                      onPressed: () => _showUploadDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New App Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF3B82F6),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF3B82F6),
                  indicatorWeight: 3,
                  labelStyle:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.event_available),
                      text: 'App Published Events',
                    ),
                    Tab(
                      icon: Icon(Icons.calendar_month),
                      text: 'Monthly Church Calendar Events',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPublishedEventsTab(),
                _buildMonthlyCalendarTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: App Published Events ────────────────────────────────────────────
  Widget _buildPublishedEventsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading events: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;

        final List<DocumentSnapshot> validDocs = [];
        for (final doc in allDocs) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            final title = data['title']?.toString() ?? '';

            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              if (!title.toLowerCase().contains(q)) continue;
            }
            validDocs.add(doc);
          } catch (_) {}
        }

        validDocs.sort((a, b) {
          try {
            final ea = Event.fromFirestore(a);
            final eb = Event.fromFirestore(b);
            return eb.startDate.compareTo(ea.startDate);
          } catch (_) {
            return 0;
          }
        });

        final filteredDocs = validDocs;

        final totalItems = filteredDocs.length;
        final totalPages = (totalItems / _rowsPerPage).ceil();
        if (_currentPage >= totalPages && totalPages > 0) {
          _currentPage = totalPages - 1;
        }

        final startIndex = _currentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage < totalItems)
            ? startIndex + _rowsPerPage
            : totalItems;
        final pagedDocs = filteredDocs.sublist(startIndex, endIndex);

        bool allSelected = pagedDocs.isNotEmpty &&
            pagedDocs.every((doc) => _selectedEventIds.contains(doc.id));
        bool someSelected =
            pagedDocs.any((doc) => _selectedEventIds.contains(doc.id)) &&
                !allSelected;

        return Column(
          children: [
            // Search & Bulk Actions Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search published events...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (v) =>
                          setState(() { _searchQuery = v; _currentPage = 0; }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_selectedEventIds.isNotEmpty) ...[
                    DropdownButton<String>(
                      hint: const Text('Bulk Actions'),
                      items: ['Delete']
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _applyBatchAction(v);
                      },
                    ),
                    const SizedBox(width: 16),
                    if (_isPerformingAction)
                      const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // DataTable
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
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
                            headingRowColor:
                                WidgetStateProperty.all(Colors.grey.shade50),
                            columns: [
                              DataColumn(
                                label: Checkbox(
                                  value: allSelected
                                      ? true
                                      : (someSelected ? null : false),
                                  tristate: true,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedEventIds
                                            .addAll(pagedDocs.map((d) => d.id));
                                      } else {
                                        _selectedEventIds
                                            .removeAll(pagedDocs.map((d) => d.id));
                                      }
                                    });
                                  },
                                ),
                              ),
                              const DataColumn(
                                  label: Text('Flyer',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(
                                  label: Text('Event Title',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(
                                  label: Text('Venue',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(
                                  label: Text('Status',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(
                                  label: Text('Start Date',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(
                                  label: Text('Actions',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: pagedDocs.map((doc) {
                              final event = Event.fromFirestore(doc);
                              final isSelected =
                                  _selectedEventIds.contains(event.id);

                              return DataRow(
                                selected: isSelected,
                                onSelectChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedEventIds.add(event.id);
                                    } else {
                                      _selectedEventIds.remove(event.id);
                                    }
                                  });
                                },
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedEventIds.add(event.id);
                                          } else {
                                            _selectedEventIds.remove(event.id);
                                          }
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
                                            ? Container(
                                                width: 50,
                                                height: 50,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image, size: 20))
                                            : Image.network(
                                                ImageProxy.proxy(event.imageUrl),
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Container(
                                                    width: 50,
                                                    height: 50,
                                                    color: Colors.grey.shade200,
                                                    child: const Icon(Icons.broken_image,
                                                        size: 20)),
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
                                    Text(event.venue.isNotEmpty ? event.venue : 'Main Sanctuary'),
                                    onTap: () => _showEventDetails(event),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: event.isUpcoming
                                            ? Colors.green.shade100
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        event.isUpcoming ? 'Upcoming' : 'Past',
                                        style: TextStyle(
                                          color: event.isUpcoming
                                              ? Colors.green.shade700
                                              : Colors.grey.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    onTap: () => _showEventDetails(event),
                                  ),
                                  DataCell(
                                    Text('${event.startDate.toLocal()}'.split(' ')[0]),
                                    onTap: () => _showEventDetails(event),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 18, color: Color(0xFF3B82F6)),
                                          tooltip: 'Edit Details',
                                          onPressed: () => _showUploadDialog(event: event),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 18, color: Colors.redAccent),
                                          tooltip: 'Delete Event',
                                          onPressed: () => _deleteEvent(event.id),
                                        ),
                                      ],
                                    ),
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
                          Text(
                              'Showing ${startIndex + 1} to $endIndex of $totalItems entries',
                              style: TextStyle(color: Colors.grey.shade600)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 0 ? _prevPage : null,
                              ),
                              Text(
                                  'Page ${_currentPage + 1} of ${totalPages > 0 ? totalPages : 1}'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _currentPage < totalPages - 1
                                    ? () => _nextPage(totalPages)
                                    : null,
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
        );
      },
    );
  }

  // ── Tab 2: Monthly Church Calendar Events ──────────────────────────────────
  Widget _buildMonthlyCalendarTab() {
    if (_isLoadingCal) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Filter Bar for Month & Year
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: Color(0xFF3B82F6)),
              const SizedBox(width: 10),
              const Text('Select Month:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _calSelectedMonth,
                items: List.generate(12, (i) => i + 1)
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(_monthNames[m]),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _calSelectedMonth = val);
                    _loadMonthlyCalendar();
                  }
                },
              ),
              const SizedBox(width: 24),
              const Text('Year:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _calSelectedYear,
                items: [2025, 2026, 2027, 2028, 2029, 2030]
                    .map((y) => DropdownMenuItem(
                          value: y,
                          child: Text('$y'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _calSelectedYear = val);
                    _loadMonthlyCalendar();
                  }
                },
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_monthlyCalendarDocs.length} Calendar Event${_monthlyCalendarDocs.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Table of Monthly Calendar Events
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: _monthlyCalendarDocs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No Church Calendar entries for ${_monthNames[_calSelectedMonth]} $_calSelectedYear',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Approved yearly calendar programmes created in CMS will appear here for you to enrich with flyers & details before publishing to the mobile app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(Colors.grey.shade50),
                      columns: const [
                        DataColumn(
                            label: Text('Date',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Programme Title',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Venue / Location',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Category / Type',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _monthlyCalendarDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title']?.toString() ?? 'Programme';
                        final venue = data['venue']?.toString() ??
                            data['location']?.toString() ??
                            'Main Sanctuary';
                        final eventType =
                            data['eventType']?.toString() ?? 'yearly_calendar';

                        DateTime startDate = DateTime.now();
                        final rawDate = data['startDate'] ??
                            data['dateTime'] ??
                            data['date'];
                        if (rawDate != null) {
                          if (rawDate is Timestamp) {
                            startDate = rawDate.toDate();
                          } else if (rawDate is DateTime) {
                            startDate = rawDate;
                          } else {
                            startDate =
                                DateTime.tryParse(rawDate.toString()) ??
                                    DateTime.now();
                          }
                        }

                        final Event calEvent = Event.fromFirestore(doc);

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '${_monthNames[startDate.month].substring(0, 3)} ${startDate.day}, ${startDate.year}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 260,
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(venue)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _formatType(eventType),
                                  style: const TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.add_photo_alternate,
                                    size: 16),
                                label: const Text('Add Details & Publish'),
                                onPressed: () {
                                  _showUploadDialog(
                                    defaultTitle: title,
                                    defaultDate: startDate,
                                    defaultVenue: venue,
                                    event: calEvent.imageUrl.isNotEmpty ? calEvent : null,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _formatType(String type) => switch (type) {
        'yearly_calendar' => 'Church Calendar',
        'wedding_programme' => 'Wedding',
        'revival_programme' => 'Revival',
        'conference' => 'Conference',
        'anniversary' => 'Anniversary',
        'sunday_service' => 'Sunday Service',
        'midweek_service' => 'Midweek Service',
        _ => 'Special Event',
      };
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
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
