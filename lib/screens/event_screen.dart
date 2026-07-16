import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'event_details_screen.dart';
import '../models/event.dart' as app_event;
import '../services/event_service.dart';
import '../utils/toast_utils.dart';
import '../widgets/hero_header_widget.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({Key? key}) : super(key: key);

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  List<app_event.Event> _upcomingEvents = [];
  List<app_event.Event> _pastEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final eventMap = await _eventService.getAllEvents();
      if (mounted) {
        setState(() {
          _upcomingEvents = eventMap['upcoming'] ?? [];
          _pastEvents = eventMap['past'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSampleEvents() async {
    setState(() => _isLoading = true);
    try {
      await _eventService.addSampleEvents();
      await _loadEvents(); // Reload events after adding samples
    } catch (e) {
      print('Error adding sample events: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchEvents(String query) async {
    setState(() => _isLoading = true);
    try {
      final eventMap = await _eventService.searchEvents(query);
      if (mounted) {
        setState(() {
          _upcomingEvents = eventMap['upcoming'] ?? [];
          _pastEvents = eventMap['past'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching events: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEventDetails(app_event.Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventDetailsScreen(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.transparent : null,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF161622),
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Events',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          const SliverToBoxAdapter(
            child: HeroHeaderWidget(imagePath: 'assets/images/events_header.jpg'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  if (value.isEmpty) {
                    _loadEvents();
                  } else {
                    _searchEvents(value);
                  }
                },
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                if (_isLoading)
                  const _ShimmerEventList()
                else if (_upcomingEvents.isEmpty && _pastEvents.isEmpty)
                  const Center(
                    child: Text('No events found'),
                  )
                else ...[
                  // Upcoming Events Section
                  if (_upcomingEvents.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Upcoming Events',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Theme.of(context).primaryColor,
                                ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _upcomingEvents.length,
                          itemBuilder: (context, index) {
                            final event = _upcomingEvents[index];
                            return _EventCard(
                              event: event,
                              onTap: () => _showEventDetails(event),
                            );
                          },
                        ),
                      ],
                    ),
                  // Past Events Section
                  if (_pastEvents.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Past Events',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pastEvents.length,
                          itemBuilder: (context, index) {
                            final event = _pastEvents[index];
                            return _EventCard(
                              event: event,
                              onTap: () => _showEventDetails(event),
                              isPast: true,
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final app_event.Event event;
  final VoidCallback onTap;
  final bool isPast;

  const _EventCard({
    required this.event,
    required this.onTap,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isPast) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!),
        ),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: event.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: event.imageUrl,
                        height: 90,
                        width: 90,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                          child: Container(
                            height: 90,
                            width: 90,
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 90,
                          width: 90,
                          color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                          child: Icon(Icons.church,
                              size: 24, color: isDark ? Colors.white30 : Colors.grey[400]),
                        ),
                      )
                    : Container(
                        height: 90,
                        width: 90,
                        color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                        child: Icon(Icons.church,
                            size: 24, color: isDark ? Colors.white30 : Colors.grey[400]),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: isDark ? Colors.white60 : Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM d, y').format(event.effectiveDate),
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      elevation: 4,
      shadowColor: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: event.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                        child: Container(
                          height: 220,
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 220,
                        color: isDark ? const Color(0xFF0F172A) : Colors.grey[200],
                        child: Icon(Icons.church,
                            size: 48, color: isDark ? Colors.white30 : Colors.grey[400]),
                      ),
                    )
                  : Container(
                      height: 220,
                      color: isDark ? const Color(0xFF0F172A) : Colors.grey[200],
                      child:
                          Icon(Icons.church, size: 48, color: isDark ? Colors.white30 : Colors.grey[400]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF6366F1).withOpacity(0.2) : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month,
                                size: 16,
                                color: isDark ? const Color(0xFF818CF8) : Theme.of(context).primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d, y').format(event.effectiveDate),
                              style: TextStyle(
                                color: isDark ? const Color(0xFF818CF8) : Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (event.venue.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: isDark ? Colors.white60 : Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.venue,
                                  style: TextStyle(
                                      color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerEventList extends StatelessWidget {
  const _ShimmerEventList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                      child: Container(
                        height: 20,
                        width: double.infinity,
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                      child: Container(
                        height: 16,
                        width: 150,
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
