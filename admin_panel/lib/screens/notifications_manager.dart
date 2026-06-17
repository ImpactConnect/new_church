import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fcm_admin_service.dart';

class NotificationsManager extends StatefulWidget {
  const NotificationsManager({super.key});

  @override
  State<NotificationsManager> createState() => _NotificationsManagerState();
}

class _NotificationsManagerState extends State<NotificationsManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _isSending = false;
  bool _saveAsAnnouncement = true;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _scheduledDate = date;
          _scheduledTime = time;
        });
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    DateTime? sendAfter;
    if (_scheduledDate != null && _scheduledTime != null) {
      sendAfter = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );
    }

    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    final success = await FcmAdminService.sendNotification(
      title: title,
      content: message,
      sendAfter: sendAfter,
    );

    if (success && _saveAsAnnouncement) {
      await FirebaseFirestore.instance.collection('announcements').add({
        'message': '$title\n$message',
        'timePosted': sendAfter != null
            ? Timestamp.fromDate(sendAfter)
            : FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sendAfter != null ? 'Notification scheduled!' : 'Notification sent!')),
        );
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _scheduledDate = null;
          _scheduledTime = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to queue notification. Please try again.')),
        );
      }
    }
  }

  Future<void> _sendQuickAlert(String title, String body) async {
    final success = await FcmAdminService.sendNotification(title: title, content: body);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Alert sent: $title' : 'Failed to send alert')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Compose Form
          Expanded(
            flex: 1,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Broadcast Notification',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Message Body',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Schedule picker
                  InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Schedule Delivery',
                                    style: TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                  _scheduledDate != null && _scheduledTime != null
                                      ? '${_scheduledDate!.toLocal().toString().split(' ')[0]} at ${_scheduledTime!.format(context)}'
                                      : 'Send Immediately',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (_scheduledDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() {
                                _scheduledDate = null;
                                _scheduledTime = null;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Also save as Church Announcement'),
                    subtitle: const Text('Visible in the app\'s announcement feed'),
                    value: _saveAsAnnouncement,
                    onChanged: (val) => setState(() => _saveAsAnnouncement = val),
                  ),
                  const SizedBox(height: 16),
                  if (_isSending)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      onPressed: _sendNotification,
                      icon: const Icon(Icons.send),
                      label: Text(
                          _scheduledDate != null ? 'Schedule Notification' : 'Send Now'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          // Right: Status & Quick Actions
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Automated Triggers 🤖',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _statusTile(Icons.check_circle, Colors.green, 'New Sermon Upload → Auto Notify'),
                      _statusTile(Icons.check_circle, Colors.green, 'Live Stream Go Live → Auto Notify'),
                      _statusTile(Icons.check_circle, Colors.green, 'New Event Created → Auto Notify'),
                      _statusTile(Icons.check_circle, Colors.green, 'Devotional Published → Auto Scheduled'),
                      _statusTile(Icons.settings, Colors.orange,
                          'Birthdays & Anniversaries → Cloud Function Required'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Quick Actions ⚡',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _quickActionButton(
                  icon: Icons.radio,
                  label: '📻 Broadcast Live Radio Alert',
                  color: Colors.red,
                  onTap: () => _sendQuickAlert(
                    '📻 Live Radio Started',
                    'Join our 24/7 Impact Connect Radio broadcast now!',
                  ),
                ),
                const SizedBox(height: 8),
                _quickActionButton(
                  icon: Icons.volunteer_activism,
                  label: '🙏 General Prayer Request Alert',
                  color: Colors.purple,
                  onTap: () => _sendQuickAlert(
                    '🙏 Corporate Prayer Time',
                    'Join us right now in corporate prayer. Open the app to participate.',
                  ),
                ),
                const SizedBox(height: 8),
                _quickActionButton(
                  icon: Icons.campaign,
                  label: '📢 Church Service Reminder',
                  color: Colors.orange,
                  onTap: () => _sendQuickAlert(
                    '⛪ Church Service Today',
                    'Don\'t forget! Service starts soon. See you there!',
                  ),
                ),
                const SizedBox(height: 8),
                _quickActionButton(
                  icon: Icons.monetization_on,
                  label: '💰 Giving / Offering Alert',
                  color: Colors.green,
                  onTap: () => _sendQuickAlert(
                    '💰 Give Today',
                    'Support the ministry of Impact Connect. Your giving makes a difference.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTile(IconData icon, Color color, String label) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
