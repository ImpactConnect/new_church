import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_stream.dart';
import '../services/fcm_admin_service.dart';

String _fmtDate(DateTime dt) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $h:$m $period';
}

class LiveStreamManager extends StatefulWidget {
  const LiveStreamManager({super.key});
  @override
  State<LiveStreamManager> createState() => _LiveStreamManagerState();
}

class _LiveStreamManagerState extends State<LiveStreamManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF3B82F6),
            tabs: const [
              Tab(icon: Icon(Icons.live_tv), text: 'Live Control'),
              Tab(icon: Icon(Icons.history), text: 'Past Streams'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _LiveControlTab(),
              _PastStreamsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Live Control Tab ──────────────────────────────────────────────────────

class _LiveControlTab extends StatefulWidget {
  const _LiveControlTab();
  @override
  State<_LiveControlTab> createState() => _LiveControlTabState();
}

class _LiveControlTabState extends State<_LiveControlTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descController = TextEditingController();
  final _thumbController = TextEditingController();

  String _platform = 'youtube';
  bool _isLive = false;
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;
  String? _streamId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentStream();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descController.dispose();
    _thumbController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentStream() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('live_streams')
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final s = LiveStream.fromFirestore(snapshot.docs.first);
        setState(() {
          _streamId = s.id;
          _titleController.text = s.title;
          _urlController.text = s.url;
          _descController.text = s.description ?? '';
          _thumbController.text = s.thumbnailUrl ?? '';
          _platform = s.platform;
          _isLive = s.isLive;
          _startTime = s.startTime;
          _endTime = s.endTime;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : (_endTime ?? DateTime.now().add(const Duration(hours: 2))),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : (_endTime ?? DateTime.now())),
    );
    if (time == null) return;
    final dt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = dt;
      } else {
        _endTime = dt;
      }
    });
  }

  Future<void> _saveStream() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'title': _titleController.text.trim(),
      'url': _urlController.text.trim(),
      'platform': _platform,
      'isLive': _isLive,
      'description': _descController.text.trim(),
      'thumbnailUrl': _thumbController.text.trim().isNotEmpty
          ? _thumbController.text.trim()
          : null,
      'startTime': Timestamp.fromDate(_startTime),
      'endTime': _endTime != null ? Timestamp.fromDate(_endTime!) : null,
    };

    try {
      if (_streamId == null) {
        final ref = await FirebaseFirestore.instance
            .collection('live_streams')
            .add(data);
        _streamId = ref.id;
      } else {
        await FirebaseFirestore.instance
            .collection('live_streams')
            .doc(_streamId)
            .update(data);
      }

      if (_isLive) {
        await FcmAdminService.sendNotification(
          title: '🔴 We\'re LIVE!',
          content: 'Join the live stream now: ${_titleController.text}',
          topic: 'all',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Live stream settings saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }



    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Form ──
          Expanded(
            flex: 3,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live toggle card
                  _Card(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isLive
                                ? Colors.red.shade50
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.fiber_manual_record,
                              color: _isLive ? Colors.red : Colors.grey,
                              size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLive
                                    ? 'Stream is LIVE'
                                    : 'Stream is Offline',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isLive ? Colors.red : Colors.black,
                                ),
                              ),
                              Text(
                                _isLive
                                    ? 'Users can join the live stream now.'
                                    : 'Toggle to go live and notify users.',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isLive,
                          activeColor: Colors.red,
                          onChanged: (v) => setState(() => _isLive = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Platform & URL
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle('Stream Source'),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _platform,
                          decoration: _inputDeco('Platform', Icons.videocam),
                          items: const [
                            DropdownMenuItem(
                                value: 'youtube', child: Text('YouTube')),
                            DropdownMenuItem(
                                value: 'facebook', child: Text('Facebook Live')),
                            DropdownMenuItem(
                                value: 'vimeo',
                                child: Text('Vimeo (Premium)')),
                            DropdownMenuItem(
                                value: 'hls',
                                child: Text('Custom HLS / RTMP')),
                          ],
                          onChanged: (v) => setState(() => _platform = v!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _urlController,
                          decoration: _inputDeco(
                            _platform == 'youtube'
                                ? 'YouTube Video URL or Live URL'
                                : _platform == 'facebook'
                                    ? 'Facebook Live Video URL'
                                    : _platform == 'vimeo'
                                        ? 'Vimeo Video URL'
                                        : 'HLS Stream URL (m3u8)',
                            Icons.link,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        if (_platform == 'youtube')
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Paste the full YouTube URL, e.g. https://youtube.com/watch?v=xxxxx or a live stream URL.',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle('Stream Details'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration:
                              _inputDeco('Stream Title', Icons.title),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          decoration: _inputDeco(
                              'Description (optional)', Icons.notes),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _thumbController,
                          decoration: _inputDeco(
                            'Thumbnail URL (optional)',
                            Icons.image_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Schedule
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle('Schedule'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _DateTile(
                                label: 'Start Time',
                                value: _fmtDate(_startTime),
                                icon: Icons.play_circle_outline,
                                color: Colors.green,
                                onTap: () =>
                                    _pickDateTime(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateTile(
                                label: 'End Time (optional)',
                                value: _endTime != null
                                    ? _fmtDate(_endTime!)
                                    : 'Not set',
                                icon: Icons.stop_circle_outlined,
                                color: Colors.orange,
                                onTap: () =>
                                    _pickDateTime(isStart: false),
                              ),
                            ),
                          ],
                        ),
                        if (_endTime != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  setState(() => _endTime = null),
                              icon: const Icon(Icons.clear, size: 14),
                              label: const Text('Clear End Time'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveStream,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save & Update Stream',
                        style: const TextStyle(fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLive
                            ? Colors.red
                            : const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // ── Preview / Info Panel ──
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('Platform Guide'),
                      const SizedBox(height: 12),
                      _PlatformGuideItem(
                        icon: Icons.smart_display,
                        color: Colors.red,
                        label: 'YouTube',
                        desc:
                            'Full URL of the live video or scheduled stream. Supports autoplay.',
                      ),
                      const Divider(height: 20),
                      _PlatformGuideItem(
                        icon: Icons.facebook,
                        color: const Color(0xFF1877F2),
                        label: 'Facebook',
                        desc:
                            'Full URL of the Facebook Live video. Embedded via WebView.',
                      ),
                      const Divider(height: 20),
                      _PlatformGuideItem(
                        icon: Icons.video_library,
                        color: const Color(0xFF1AB7EA),
                        label: 'Vimeo',
                        desc:
                            'Full Vimeo video URL. Native player used for smooth playback.',
                      ),
                      const Divider(height: 20),
                      _PlatformGuideItem(
                        icon: Icons.cast,
                        color: Colors.purple,
                        label: 'Custom HLS',
                        desc:
                            'Provide an .m3u8 stream URL from your RTMP server.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _Card(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('live_streams')
                        .where('isLive', isEqualTo: true)
                        .snapshots(),
                    builder: (ctx, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Active Streams'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: count > 0
                                      ? Colors.red.shade50
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.sensors,
                                    color: count > 0
                                        ? Colors.red
                                        : Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                count > 0
                                    ? '$count stream(s) currently live'
                                    : 'No streams are live right now',
                                style: TextStyle(
                                  color: count > 0 ? Colors.red : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
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

// ─── Past Streams Tab ──────────────────────────────────────────────────────

class _PastStreamsTab extends StatelessWidget {
  const _PastStreamsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('live_streams')
          .orderBy('startTime', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No streams recorded yet.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final streams =
            snap.data!.docs.map(LiveStream.fromFirestore).toList();
        final fmt = _fmtDate;

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: streams.length,
          itemBuilder: (ctx, i) {
            final s = streams[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: s.isLive
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _platformIcon(s.platform),
                    color: s.isLive ? Colors.red : Colors.grey,
                  ),
                ),
                title: Text(s.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmt(s.startTime),
                        style: const TextStyle(fontSize: 12)),
                    Row(
                      children: [
                        _PlatformChip(s.platform),
                        const SizedBox(width: 8),
                        if (s.isLive)
                          const Chip(
                            label: Text('LIVE',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.zero,
                            labelPadding: EdgeInsets.symmetric(horizontal: 6),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(ctx, s.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'facebook':
        return Icons.facebook;
      case 'vimeo':
        return Icons.video_library;
      case 'hls':
        return Icons.cast;
      default:
        return Icons.smart_display;
    }
  }

  void _confirmDelete(BuildContext ctx, String id) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Stream'),
        content: const Text('Are you sure you want to delete this stream record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('live_streams')
                  .doc(id)
                  .delete();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1D2E),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _PlatformGuideItem extends StatelessWidget {
  const _PlatformGuideItem(
      {required this.icon,
      required this.color,
      required this.label,
      required this.desc});
  final IconData icon;
  final Color color;
  final String label;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip(this.platform);
  final String platform;

  @override
  Widget build(BuildContext context) {
    const map = {
      'youtube': (label: 'YouTube', color: Colors.red),
      'facebook': (label: 'Facebook', color: Color(0xFF1877F2)),
      'vimeo': (label: 'Vimeo', color: Color(0xFF1AB7EA)),
      'hls': (label: 'HLS', color: Colors.purple),
    };
    final entry = map[platform] ??
        (label: platform, color: Colors.grey as Color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (entry.color as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        entry.label as String,
        style: TextStyle(
            fontSize: 11,
            color: entry.color as Color,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

InputDecoration _inputDeco(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
