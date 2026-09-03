import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/event.dart' as app_event;
import 'event_details_screen.dart';

class ChurchCalendarScreen extends StatefulWidget {
  const ChurchCalendarScreen({Key? key}) : super(key: key);

  @override
  State<ChurchCalendarScreen> createState() => _ChurchCalendarScreenState();
}

class _ChurchCalendarScreenState extends State<ChurchCalendarScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _selectedYear = DateTime.now().year;
  bool _isLoading = true;
  String? _errorMsg;

  // Map: month index (1-12) -> list of events for that month
  Map<int, List<app_event.Event>> _calendarByMonth = {};

  static const List<String> _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      // 1. Fetch from root 'events' collection AND branch 'events' subcollections
      final Map<String, DocumentSnapshot> combinedDocs = {};

      try {
        final rootSnap = await _db.collection('events').get();
        for (final doc in rootSnap.docs) {
          combinedDocs[doc.id] = doc;
        }
      } catch (e) {
        print('Error fetching root events: $e');
      }

      try {
        final groupSnap = await _db.collectionGroup('events').get();
        for (final doc in groupSnap.docs) {
          combinedDocs[doc.id] = doc;
        }
      } catch (e) {
        print('Error fetching branch subcollection events: $e');
      }

      final Map<int, List<app_event.Event>> grouped = {};

      for (final doc in combinedDocs.values) {
        try {
          final event = app_event.Event.fromFirestore(doc);
          // Only show approved events matching the selected year
          if (!event.isApproved) continue;
          if (event.startDate.year != _selectedYear) continue;

          final month = event.startDate.month;
          grouped.putIfAbsent(month, () => []).add(event);
        } catch (e) {
          print('Error parsing event doc ${doc.id}: $e');
        }
      }

      for (final list in grouped.values) {
        list.sort((a, b) => a.startDate.compareTo(b.startDate));
      }

      if (mounted) {
        setState(() {
          _calendarByMonth = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Failed to load calendar. Please try again.';
        });
      }
    }
  }

  void _showEventDetails(app_event.Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventDetailsScreen(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6FB);
    final today = DateTime.now();

    final totalProgrammes =
        _calendarByMonth.values.fold(0, (acc, list) => acc + list.length);
    final activeMonths = _calendarByMonth.keys.length;
    final thisMonthCount = _calendarByMonth[today.month]?.length ?? 0;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: const Color(0xFF1A3A5C),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A3A5C), Color(0xFF2E7D9A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Icon(Icons.calendar_month_rounded,
                          size: 36, color: Colors.white70),
                      const SizedBox(height: 8),
                      const Text(
                        'Church Calendar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Annual Programme Schedule',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              centerTitle: true,
            ),
          ),

          // ── Year Picker ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left,
                        color: isDark ? Colors.white70 : Colors.grey[700]),
                    onPressed: () {
                      setState(() => _selectedYear--);
                      _loadCalendar();
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D9A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      '$_selectedYear Church Year',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A3A5C),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right,
                        color: isDark ? Colors.white70 : Colors.grey[700]),
                    onPressed: () {
                      setState(() => _selectedYear++);
                      _loadCalendar();
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Summary Stats ─────────────────────────────────────
          if (!_isLoading && _errorMsg == null)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBadge(
                      label: 'Total',
                      value: '$totalProgrammes',
                      icon: Icons.event_note_outlined,
                      color: const Color(0xFF2E7D9A),
                    ),
                    _StatBadge(
                      label: 'Months',
                      value: '$activeMonths',
                      icon: Icons.date_range_outlined,
                      color: Colors.deepOrange,
                    ),
                    _StatBadge(
                      label: 'This Month',
                      value: '$thisMonthCount',
                      icon: Icons.today_outlined,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

          // ── Body ──────────────────────────────────────────────
          if (_isLoading)
            const SliverToBoxAdapter(child: _LoadingShimmer())
          else if (_errorMsg != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(_errorMsg!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : Colors.grey[600])),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadCalendar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_calendarByMonth.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_outlined,
                        size: 60,
                        color: isDark
                            ? Colors.white24
                            : Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No programmes scheduled for $_selectedYear',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The church calendar for this year will appear\nhere once approved in the CMS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white38
                              : Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── Structured Monthly Calendar Table ──────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final month = index + 1;
                  final events = _calendarByMonth[month];
                  if (events == null || events.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final isCurrentMonth =
                      month == today.month && _selectedYear == today.year;
                  final cardBg = isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white;
                  final headerBg = isCurrentMonth
                      ? const Color(0xFF1A3A5C)
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE8EEF5));

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: headerBg,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCurrentMonth
                                    ? Icons.radio_button_checked
                                    : Icons.circle_outlined,
                                size: 14,
                                color: isCurrentMonth
                                    ? Colors.white
                                    : const Color(0xFF2E7D9A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _monthNames[month],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isCurrentMonth
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF1A3A5C)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCurrentMonth
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : const Color(0xFF2E7D9A).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${events.length} prog.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isCurrentMonth
                                        ? Colors.white
                                        : const Color(0xFF2E7D9A),
                                  ),
                                ),
                              ),
                              if (isCurrentMonth) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Current',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Table with column headers
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Column headers
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Row(
                                  children: [
                                    _colHeader('DATE', 80),
                                    _colHeader('PROGRAMME', null, flex: true),
                                    _colHeader('VENUE', 100),
                                    _colHeader('TIME', 80),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, thickness: 0.5),

                              // Event rows
                              ...events.asMap().entries.map((entry) {
                                final i = entry.key;
                                final ev = entry.value;
                                final isPast = ev.endDate.isBefore(today);
                                final isToday =
                                    ev.startDate.year == today.year &&
                                        ev.startDate.month == today.month &&
                                        ev.startDate.day == today.day;
                                final isMultiDay =
                                    ev.endDate.day != ev.startDate.day ||
                                        ev.endDate.month != ev.startDate.month;

                                final rowColor = isToday
                                    ? Colors.green.withValues(alpha: 0.06)
                                    : isPast
                                        ? (isDark
                                            ? Colors.white.withValues(alpha: 0.02)
                                            : Colors.grey.withValues(alpha: 0.04))
                                        : Colors.transparent;

                                return Column(
                                  children: [
                                    if (i > 0)
                                      Divider(
                                          height: 1,
                                          thickness: 0.3,
                                          color: isDark
                                              ? Colors.white12
                                              : Colors.grey.shade200),
                                    InkWell(
                                      onTap: () => _showEventDetails(ev),
                                      child: Container(
                                        color: rowColor,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Date cell
                                            SizedBox(
                                              width: 80,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    DateFormat('MMM d').format(ev.startDate),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: isToday
                                                          ? Colors.green
                                                          : isPast
                                                              ? (isDark
                                                                  ? Colors.white38
                                                                  : Colors.grey)
                                                              : (isDark
                                                                  ? Colors.white
                                                                  : const Color(0xFF1A3A5C)),
                                                    ),
                                                  ),
                                                  if (isMultiDay)
                                                    Text(
                                                      '– ${DateFormat('MMM d').format(ev.endDate)}',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isDark
                                                            ? Colors.white38
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                  if (isToday)
                                                    Container(
                                                      margin: const EdgeInsets.only(top: 3),
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 5, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text('Today',
                                                          style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 9)),
                                                    ),
                                                ],
                                              ),
                                            ),

                                            // Programme title
                                            Expanded(
                                              child: Text(
                                                ev.title,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isPast
                                                      ? (isDark
                                                          ? Colors.white38
                                                          : Colors.grey[500])
                                                      : (isDark
                                                          ? Colors.white
                                                          : Colors.black87),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            // Venue
                                            SizedBox(
                                              width: 100,
                                              child: Text(
                                                ev.venue.isNotEmpty ? ev.venue : 'Main Sanctuary',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.grey[600],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            // Time
                                            SizedBox(
                                              width: 80,
                                              child: Text(
                                                ev.programmeTime.isNotEmpty
                                                    ? ev.programmeTime
                                                    : DateFormat('h:mm a').format(ev.startDate),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
                childCount: 12,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _colHeader(String text, double? width, {bool flex = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final child = Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white38 : Colors.grey[500],
        letterSpacing: 0.5,
      ),
    );
    if (flex) return Expanded(child: child);
    return SizedBox(width: width, child: child);
  }
}

// ── Stat Badge ────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color)),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.grey[600],
              )),
        ],
      ),
    );
  }
}

// ── Loading Shimmer ───────────────────────────────────────────────────────────

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 130,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
