import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart' as app_event;
import '../utils/toast_utils.dart';
import '../services/local_notification_service.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  final app_event.Event event;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final DeviceCalendarPlugin _deviceCalendarPlugin;

  @override
  void initState() {
    super.initState();
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  Future<bool> _requestCalendarPermissions() async {
    final status = await Permission.calendar.request();
    if (status.isDenied) {
      ToastUtils.showToast('Calendar permission is required to add events');
      return false;
    }
    if (status.isPermanentlyDenied) {
      ToastUtils.showToast('Please enable calendar permission in app settings');
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  Future<void> _addToCalendar() async {
    try {
      final hasPermission = await _requestCalendarPermissions();
      if (!hasPermission) {
        return;
      }

      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          ToastUtils.showToast('Calendar permission is required');
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess) {
        ToastUtils.showToast('Failed to get calendars');
        return;
      }

      final calendars = calendarsResult.data;
      if (calendars == null || calendars.isEmpty) {
        ToastUtils.showToast('No calendars found');
        return;
      }

      // Use the first available calendar
      final calendar = calendars.first;

      RecurrenceRule? recurrenceRule;
      if (widget.event.recurrence == 'daily') {
        recurrenceRule = RecurrenceRule(RecurrenceFrequency.Daily);
      } else if (widget.event.recurrence == 'weekly') {
        recurrenceRule = RecurrenceRule(RecurrenceFrequency.Weekly);
      } else if (widget.event.recurrence == 'monthly') {
        recurrenceRule = RecurrenceRule(RecurrenceFrequency.Monthly);
      }

      final eventToCreate = Event(
        calendar.id,
        title: widget.event.title,
        description: widget.event.description,
        start: TZDateTime.from(widget.event.effectiveDate, local),
        end: TZDateTime.from(widget.event.endDate, local),
        location: widget.event.venue,
        recurrenceRule: recurrenceRule,
      );

      final createEventResult =
          await _deviceCalendarPlugin.createOrUpdateEvent(eventToCreate);
      if (createEventResult?.isSuccess ?? false) {
        ToastUtils.showToast(
            '${widget.event.title} has been added to your calendar');
      } else {
        ToastUtils.showToast('Failed to add event to calendar');
      }
    } catch (e) {
      print('Error adding event to calendar: $e');
      ToastUtils.showToast('Failed to add event to calendar');
    }
  }

  void _shareEvent() {
    final String shareText = '''
${widget.event.title}

Date: ${DateFormat('MMM d, y').format(widget.event.effectiveDate)}
Time: ${widget.event.programmeTime}
Venue: ${widget.event.venue}

${widget.event.description}
''';
    Share.share(shareText);
  }

  Future<void> _joinEvent() async {
    final url = Uri.parse(widget.event.joinLink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ToastUtils.showToast('Could not launch join link');
    }
  }

  Future<void> _setReminder() async {
    try {
      await LocalNotificationService().scheduleEventReminder(
        id: widget.event.id.hashCode,
        eventTime: widget.event.effectiveDate,
        title: 'Upcoming Event: ${widget.event.title}',
        body:
            'Starting soon at ${widget.event.programmeTime}. Tap to see details!',
      );
      ToastUtils.showToast('Push notification reminder set!');
    } catch (e) {
      ToastUtils.showToast('Failed to set reminder');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  automaticallyImplyLeading:
                      false, // Hide back button for bottom sheet
                  backgroundColor: Theme.of(context).primaryColor,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.event.imageUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: widget.event.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image)),
                          )
                        else
                          Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.church,
                                  size: 64, color: Colors.grey)),
                        // Gradient overlay to make title readable
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 32,
                          left: 20,
                          right: 20,
                          child: Text(
                            widget.event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 8)
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    transform: Matrix4.translationValues(0.0, -24.0, 0.0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action Buttons Row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _ActionButton(
                                  icon: Icons.notifications_active,
                                  label: 'Reminder',
                                  onTap: _setReminder,
                                ),
                                const SizedBox(width: 16),
                                _ActionButton(
                                  icon: Icons.calendar_today,
                                  label: 'Calendar',
                                  onTap: _addToCalendar,
                                ),
                                const SizedBox(width: 16),
                                _ActionButton(
                                  icon: Icons.share,
                                  label: 'Share',
                                  onTap: _shareEvent,
                                ),
                                if (widget.event.joinLink.isNotEmpty) ...[
                                  const SizedBox(width: 16),
                                  _ActionButton(
                                    icon: Icons.videocam,
                                    label: 'Join Online',
                                    onTap: _joinEvent,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Info Cards
                          _buildModernInfoRow(
                              Icons.calendar_month,
                              'Date',
                              DateFormat('MMMM d, yyyy')
                                  .format(widget.event.effectiveDate)),
                          if (widget.event.programmeTime.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildModernInfoRow(Icons.access_time, 'Time',
                                widget.event.programmeTime),
                          ],
                          if (widget.event.venue.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildModernInfoRow(Icons.location_on, 'Location',
                                widget.event.venue),
                          ],

                          if (widget.event.description.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Text(
                              'About Event',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.event.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    height: 1.6,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernInfoRow(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
