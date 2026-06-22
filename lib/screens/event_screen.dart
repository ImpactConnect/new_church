import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'event_details_screen.dart';
import '../models/event.dart' as app_event;
import '../services/event_service.dart';
import '../utils/toast_utils.dart';

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
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/events_header.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: const Text(
                'Events',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
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
                                  color: Theme.of(context).primaryColor,
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
                                  color: Colors.grey[600],
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
    if (isPast) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        color: Colors.white,
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
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 90,
                            width: 90,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 90,
                          width: 90,
                          color: Colors.grey[100],
                          child: Icon(Icons.church,
                              size: 24, color: Colors.grey[400]),
                        ),
                      )
                    : Container(
                        height: 90,
                        width: 90,
                        color: Colors.grey[100],
                        child: Icon(Icons.church,
                            size: 24, color: Colors.grey[400]),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM d, y').format(event.effectiveDate),
                            style: TextStyle(
                              color: Colors.grey[600],
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
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
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
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 220,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 220,
                        color: Colors.grey[200],
                        child: Icon(Icons.church,
                            size: 48, color: Colors.grey[400]),
                      ),
                    )
                  : Container(
                      height: 220,
                      color: Colors.grey[200],
                      child:
                          Icon(Icons.church, size: 48, color: Colors.grey[400]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month,
                                size: 16,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d, y').format(event.effectiveDate),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
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
                                  size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.venue,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 20,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 16,
                        width: 150,
                        color: Colors.white,
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
