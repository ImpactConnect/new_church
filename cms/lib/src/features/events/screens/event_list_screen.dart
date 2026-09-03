import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/auth/models/cms_user_model.dart';
import 'package:cms/src/features/events/models/event_model.dart';
import 'package:cms/src/features/events/screens/attendance_screen.dart';

final _eventsProvider = StreamProvider.autoDispose.family<List<EventModel>, String>(
  (ref, branchId) => ref.watch(eventRepositoryProvider).watchEvents(branchId),
);

class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final eventsAsync = ref.watch(_eventsProvider(branchId));
    final canManage = user?.can(AppPermission.manageEvents) ?? false;
    final canRecordAtt = user?.can(AppPermission.recordAttendance) ?? false;
    final isLeadPastor = user?.roleId == AppRole.leadPastor;

    final events = eventsAsync.valueOrNull ?? [];
    final pendingCount = events.where((e) => e.isPending).length;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          CmsPageHeader(
            title: 'Master Events & Church Calendar',
            subtitle: 'Secretary event authoring, Lead Pastor review queue, and church calendar management',
            actions: [
              if (canManage) ...[
                CmsButton(
                  label: '+ Yearly Calendar',
                  icon: Icons.calendar_today_outlined,
                  compact: true,
                  variant: CmsButtonVariant.secondary,
                  onPressed: () => _showYearlyCalendarDialog(context, ref, branchId, user),
                ),
                const SizedBox(width: 10),
                CmsButton(
                  label: '+ Schedule Event',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showEventDialog(context, ref, branchId, null, user),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // ── Tabs Navigation ─────────────────────────────────────────
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: CmsTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CmsTheme.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: CmsTheme.accent,
                borderRadius: BorderRadius.circular(7),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: CmsTheme.textSecondary,
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                const Tab(text: 'Events of the Week'),
                const Tab(text: 'Events of the Month'),
                const Tab(text: 'Yearly Calendar'),
                const Tab(text: 'Special Programmes'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Approval Queue'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: CmsTheme.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Tab Views Content ─────────────────────────────────────────
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
              data: (allEvents) {
                final now = DateTime.now();

                // 1. Events of the Week
                final weekEvents = allEvents.where((e) {
                  final diff = e.effectiveStartDate.difference(now).inDays;
                  return diff >= -1 && diff <= 7;
                }).toList();

                // 2. Events of the Month
                final monthEvents = allEvents.where((e) {
                  return e.effectiveStartDate.month == now.month && e.effectiveStartDate.year == now.year;
                }).toList();

                // 3. Yearly Calendar Events
                final yearlyEvents = allEvents.where((e) {
                  return e.eventType == 'yearly_calendar' || e.year == now.year;
                }).toList()..sort((a, b) => a.effectiveStartDate.compareTo(b.effectiveStartDate));

                // 4. Special Programmes (Weddings, Revivals, Crusades, Conferences)
                final specialProgrammes = allEvents.where((e) {
                  final t = e.eventType.toLowerCase();
                  return t.contains('wedding') || t.contains('revival') || t.contains('conference') || t.contains('anniversary') || t.contains('special');
                }).toList();

                // 5. Pending Approval Events
                final pendingEvents = allEvents.where((e) => e.isPending).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList(context, ref, branchId, weekEvents, canManage, canRecordAtt, isLeadPastor, user, 'No events scheduled for this week.'),
                    _buildEventList(context, ref, branchId, monthEvents, canManage, canRecordAtt, isLeadPastor, user, 'No events scheduled for this month.'),
                    _buildYearlyCalendarTable(context, ref, branchId, yearlyEvents, canManage, isLeadPastor, user),
                    _buildEventList(context, ref, branchId, specialProgrammes, canManage, canRecordAtt, isLeadPastor, user, 'No special programmes (Weddings/Revivals) created.'),
                    _buildEventList(context, ref, branchId, pendingEvents, canManage, canRecordAtt, isLeadPastor, user, 'No pending event submissions for pastor review.'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Structured Monthly Table for Yearly Calendar ─────────────────────────
  Widget _buildYearlyCalendarTable(
    BuildContext context,
    WidgetRef ref,
    String branchId,
    List<EventModel> events,
    bool canManage,
    bool isLeadPastor,
    CmsUserModel? user,
  ) {
    if (events.isEmpty) {
      return const CmsEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No Yearly Calendar',
        subtitle: 'No yearly calendar entries yet. Use "+ Yearly Calendar" to create the church year programme.',
      );
    }

    // Group by month
    final Map<int, List<EventModel>> byMonth = {};
    for (final e in events) {
      final m = e.effectiveStartDate.month;
      byMonth.putIfAbsent(m, () => []).add(e);
    }

    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final now = DateTime.now();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int m = 1; m <= 12; m++) ...[
            if (byMonth.containsKey(m)) ...[
              // Month Header Row
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8, bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: m == now.month
                      ? LinearGradient(colors: [CmsTheme.accent, CmsTheme.accent.withValues(alpha: 0.7)])
                      : null,
                  color: m == now.month ? null : CmsTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: m == now.month ? CmsTheme.accent : CmsTheme.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      m == now.month ? Icons.radio_button_checked : Icons.calendar_month_outlined,
                      size: 16,
                      color: m == now.month ? Colors.white : CmsTheme.accent,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      monthNames[m],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: m == now.month ? Colors.white : CmsTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: m == now.month ? Colors.white.withValues(alpha: 0.2) : CmsTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${byMonth[m]!.length} programme${byMonth[m]!.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: m == now.month ? Colors.white : CmsTheme.accent,
                        ),
                      ),
                    ),
                    if (m == now.month) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Current Month',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Inter')),
                      ),
                    ],
                  ],
                ),
              ),

              // Table for this month's events
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: CmsTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CmsTheme.border),
                ),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(90),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1),
                    5: FixedColumnWidth(140),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(color: CmsTheme.border, width: 0.5),
                  ),
                  children: [
                    // Table header
                    TableRow(
                      decoration: BoxDecoration(color: CmsTheme.surfaceElevated),
                      children: const [
                        _TableHeader('Date'),
                        _TableHeader('Programme Title'),
                        _TableHeader('Venue'),
                        _TableHeader('Type'),
                        _TableHeader('Status'),
                        _TableHeader('Actions'),
                      ],
                    ),
                    // Event rows
                    for (final ev in byMonth[m]!)
                      TableRow(
                        decoration: BoxDecoration(
                          color: ev.isPending
                              ? CmsTheme.warning.withValues(alpha: 0.04)
                              : Colors.transparent,
                        ),
                        children: [
                          // Date
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('MMM d').format(ev.effectiveStartDate),
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                                ),
                                if (ev.effectiveEndDate.day != ev.effectiveStartDate.day)
                                  Text(
                                    '– ${DateFormat('MMM d').format(ev.effectiveEndDate)}',
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted),
                                  ),
                                Text(
                                  DateFormat('h:mm a').format(ev.effectiveStartDate),
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          // Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev.title,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary),
                                ),
                                if (ev.description.isNotEmpty)
                                  Text(
                                    ev.description,
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          // Venue
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Text(ev.location, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                          ),
                          // Type
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Text(_formatEventType(ev.eventType), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
                          ),
                          // Status
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: _StatusBadge(status: ev.status, reason: ev.rejectionReason),
                          ),
                          // Actions
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // View details
                                IconButton(
                                  tooltip: 'View Details',
                                  icon: const Icon(Icons.visibility_outlined, size: 16, color: CmsTheme.textSecondary),
                                  onPressed: () => _showEventDetailDialog(context, ref, branchId, ev, isLeadPastor),
                                ),
                                if (isLeadPastor && ev.isPending) ...[
                                  IconButton(
                                    tooltip: 'Approve',
                                    icon: const Icon(Icons.check_circle_outline, size: 16, color: CmsTheme.success),
                                    onPressed: () async {
                                      await ref.read(eventRepositoryProvider).approveEvent(branchId, ev.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Approved "${ev.title}"'), backgroundColor: CmsTheme.success),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Reject',
                                    icon: const Icon(Icons.cancel_outlined, size: 16, color: CmsTheme.danger),
                                    onPressed: () => _promptReject(context, ref, branchId, ev),
                                  ),
                                ],
                                if (canManage) ...[
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(Icons.edit_outlined, size: 16, color: CmsTheme.accent),
                                    onPressed: () => _showEventDialog(context, ref, branchId, ev, user),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete_outline, size: 16, color: CmsTheme.danger),
                                    onPressed: () async {
                                      final ok = await showConfirmDialog(
                                        context,
                                        title: 'Delete Event',
                                        message: 'Delete "${ev.title}"?',
                                        confirmLabel: 'Delete',
                                        danger: true,
                                      );
                                      if (ok) await ref.read(eventRepositoryProvider).deleteEvent(branchId, ev.id);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEventList(
    BuildContext context,
    WidgetRef ref,
    String branchId,
    List<EventModel> events,
    bool canManage,
    bool canRecordAtt,
    bool isLeadPastor,
    CmsUserModel? user,
    String emptyMessage,
  ) {
    if (events.isEmpty) {
      return CmsEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No Matching Events',
        subtitle: emptyMessage,
      );
    }
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _EventCard(
        event: events[i],
        branchId: branchId,
        ref: ref,
        canManage: canManage,
        canRecordAtt: canRecordAtt,
        isLeadPastor: isLeadPastor,
        onTakeAttendance: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AttendanceScreen(event: events[i])),
        ),
        onEdit: () => _showEventDialog(context, ref, branchId, events[i], user),
        onViewDetail: () => _showEventDetailDialog(context, ref, branchId, events[i], isLeadPastor),
        onDelete: () async {
          final ok = await showConfirmDialog(
            context,
            title: 'Delete Event',
            message: 'Delete "${events[i].title}"?',
            confirmLabel: 'Delete',
            danger: true,
          );
          if (ok) {
            await ref.read(eventRepositoryProvider).deleteEvent(branchId, events[i].id);
          }
        },
      ),
    );
  }

  void _showEventDialog(BuildContext context, WidgetRef ref, String branchId, EventModel? event, CmsUserModel? user) {
    showDialog(
      context: context,
      builder: (_) => _EventFormDialog(branchId: branchId, ref: ref, event: event, user: user),
    );
  }

  void _showYearlyCalendarDialog(BuildContext context, WidgetRef ref, String branchId, CmsUserModel? user) {
    showDialog(
      context: context,
      builder: (_) => _YearlyCalendarBatchDialog(branchId: branchId, ref: ref, user: user),
    );
  }

  void _showEventDetailDialog(BuildContext context, WidgetRef ref, String branchId, EventModel event, bool isLeadPastor) {
    showDialog(
      context: context,
      builder: (_) => _EventDetailDialog(event: event, branchId: branchId, ref: ref, isLeadPastor: isLeadPastor),
    );
  }

  void _promptReject(BuildContext context, WidgetRef ref, String branchId, EventModel event) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CmsTheme.surfaceElevated,
        title: Text('Reject "${event.title}"', style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
          CmsButton(
            label: 'Reject',
            compact: true,
            variant: CmsButtonVariant.danger,
            onPressed: () async {
              final reason = ctrl.text.trim().isEmpty ? 'Not approved by Pastor' : ctrl.text.trim();
              await ref.read(eventRepositoryProvider).rejectEvent(branchId, event.id, reason);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  String _formatEventType(String type) => switch (type) {
    'yearly_calendar' => 'Yearly Calendar',
    'wedding_programme' => 'Wedding Programme',
    'revival_programme' => 'Revival Programme',
    'conference' => 'Conference',
    'anniversary' => 'Anniversary',
    'sunday_service' => 'Sunday Service',
    'midweek_service' => 'Midweek Service',
    _ => 'Special Programme',
  };
}

// ─────────────────────────── Table Header Cell ───────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: CmsTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────── Event Detail Dialog ─────────────────────────────

class _EventDetailDialog extends StatelessWidget {
  const _EventDetailDialog({
    required this.event,
    required this.branchId,
    required this.ref,
    required this.isLeadPastor,
  });

  final EventModel event;
  final String branchId;
  final WidgetRef ref;
  final bool isLeadPastor;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, MMMM d, yyyy');
    final timeFmt = DateFormat('h:mm a');

    String _formatType(String t) => switch (t) {
      'yearly_calendar' => 'Church Year Calendar',
      'wedding_programme' => 'Wedding Programme',
      'revival_programme' => 'Revival Programme',
      'conference' => 'Conference / Convention',
      'anniversary' => 'Church Anniversary',
      'sunday_service' => 'Sunday Service',
      'midweek_service' => 'Midweek Service',
      _ => 'Special Programme',
    };

    final isMultiDay = event.effectiveEndDate.day != event.effectiveStartDate.day ||
        event.effectiveEndDate.month != event.effectiveStartDate.month;

    return AlertDialog(
      backgroundColor: CmsTheme.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CmsTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_note, color: CmsTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: event.status, reason: event.rejectionReason),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(color: CmsTheme.border),
              const SizedBox(height: 8),

              // Programme Type
              _DetailRow(
                icon: Icons.label_outline,
                label: 'Programme Type',
                value: _formatType(event.eventType),
              ),
              const SizedBox(height: 12),

              // Dates
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Start Date & Time',
                value: '${fmt.format(event.effectiveStartDate)}\n${timeFmt.format(event.effectiveStartDate)}',
              ),
              const SizedBox(height: 12),

              if (isMultiDay) ...[
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'End Date & Time',
                  value: '${fmt.format(event.effectiveEndDate)}\n${timeFmt.format(event.effectiveEndDate)}',
                ),
                const SizedBox(height: 12),
              ],

              // Venue
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Venue / Location',
                value: event.location.isEmpty ? 'Main Auditorium' : event.location,
              ),
              const SizedBox(height: 12),

              // Description
              if (event.description.isNotEmpty) ...[
                _DetailRow(
                  icon: Icons.notes_outlined,
                  label: 'Description & Details',
                  value: event.description,
                ),
                const SizedBox(height: 12),
              ],

              // Created by
              if (event.createdByName != null) ...[
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Submitted By',
                  value: '${event.createdByName} (${event.createdByRole ?? 'Secretary'})',
                ),
                const SizedBox(height: 12),
              ],

              // Rejection reason
              if (event.rejectionReason != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CmsTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CmsTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cancel_outlined, color: CmsTheme.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rejection Reason',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: CmsTheme.danger)),
                            const SizedBox(height: 4),
                            Text(event.rejectionReason!,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Flyer / media
              if (event.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.image_outlined,
                  label: 'Flyer / Banner URL',
                  value: event.mediaUrls.first,
                ),
              ],

              const SizedBox(height: 16),

              // Pastor approval actions
              if (isLeadPastor && event.isPending) ...[
                const Divider(color: CmsTheme.border),
                const SizedBox(height: 12),
                const Text(
                  'Lead Pastor Decision',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: CmsTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CmsButton(
                        label: 'Approve Event',
                        icon: Icons.check_circle_outline,
                        compact: false,
                        onPressed: () async {
                          await ref.read(eventRepositoryProvider).approveEvent(branchId, event.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Approved "${event.title}"'), backgroundColor: CmsTheme.success),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CmsButton(
                        label: 'Reject Event',
                        icon: Icons.cancel_outlined,
                        compact: false,
                        variant: CmsButtonVariant.danger,
                        onPressed: () {
                          Navigator.pop(context);
                          _showRejectDialog(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: CmsTheme.textSecondary)),
        ),
      ],
    );
  }

  void _showRejectDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CmsTheme.surfaceElevated,
        title: Text('Reject "${event.title}"', style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
          CmsButton(
            label: 'Reject',
            compact: true,
            variant: CmsButtonVariant.danger,
            onPressed: () async {
              final reason = ctrl.text.trim().isEmpty ? 'Not approved by Pastor' : ctrl.text.trim();
              await ref.read(eventRepositoryProvider).rejectEvent(branchId, event.id, reason);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: CmsTheme.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Event Card ──────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.branchId,
    required this.ref,
    required this.canManage,
    required this.canRecordAtt,
    required this.isLeadPastor,
    required this.onTakeAttendance,
    required this.onEdit,
    required this.onViewDetail,
    required this.onDelete,
  });

  final EventModel event;
  final String branchId;
  final WidgetRef ref;
  final bool canManage;
  final bool canRecordAtt;
  final bool isLeadPastor;
  final VoidCallback onTakeAttendance;
  final VoidCallback onEdit;
  final VoidCallback onViewDetail;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isWeekend = event.effectiveStartDate.weekday == DateTime.saturday || event.effectiveStartDate.weekday == DateTime.sunday;
    final isMultiDay = event.effectiveEndDate.day != event.effectiveStartDate.day ||
        event.effectiveEndDate.month != event.effectiveStartDate.month;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: event.isPending ? CmsTheme.warning.withValues(alpha: 0.5) : CmsTheme.border,
          width: event.isPending ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Date box badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (isWeekend ? CmsTheme.accent : CmsTheme.success).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (isWeekend ? CmsTheme.accent : CmsTheme.success).withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.effectiveStartDate.day.toString(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isWeekend ? CmsTheme.accent : CmsTheme.success,
                  ),
                ),
                Text(
                  _monthName(event.effectiveStartDate.month),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary),
                ),
                if (isMultiDay)
                  Text(
                    '– ${event.effectiveEndDate.day} ${_monthName(event.effectiveEndDate.month)}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: CmsTheme.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        event.title,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: event.status, reason: event.rejectionReason),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: CmsTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: CmsTheme.border),
                      ),
                      child: Text(
                        _formatEventType(event.eventType),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: CmsTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(event.location, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time_outlined, size: 14, color: CmsTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('h:mm a').format(event.effectiveStartDate)}${isMultiDay ? ' – ${DateFormat('MMM d, h:mm a').format(event.effectiveEndDate)}' : ''}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
                    ),
                    if (event.createdByName != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.person_outline, size: 14, color: CmsTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('By ${event.createdByName}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // View detail button (always shown)
          CmsButton(
            label: 'View',
            icon: Icons.visibility_outlined,
            compact: true,
            variant: CmsButtonVariant.secondary,
            onPressed: onViewDetail,
          ),
          const SizedBox(width: 8),

          // Approval buttons for Pastor
          if (isLeadPastor && event.isPending) ...[
            CmsButton(
              label: 'Approve',
              icon: Icons.check,
              compact: true,
              onPressed: () async {
                await ref.read(eventRepositoryProvider).approveEvent(branchId, event.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Approved "${event.title}"'), backgroundColor: CmsTheme.success),
                );
              },
            ),
            const SizedBox(width: 8),
            CmsButton(
              label: 'Reject',
              icon: Icons.close,
              compact: true,
              variant: CmsButtonVariant.danger,
              onPressed: () => _promptReject(context, branchId, event),
            ),
            const SizedBox(width: 8),
          ],

          // Attendance button for Officers
          if (canRecordAtt && event.isApproved)
            CmsButton(
              label: 'Attendance',
              icon: Icons.how_to_reg_outlined,
              compact: true,
              variant: CmsButtonVariant.secondary,
              onPressed: onTakeAttendance,
            ),

          if (canManage) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              color: CmsTheme.surfaceElevated,
              icon: const Icon(Icons.more_vert, size: 18, color: CmsTheme.textSecondary),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: CmsTheme.danger, fontFamily: 'Inter'))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _promptReject(BuildContext context, String branchId, EventModel event) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CmsTheme.surfaceElevated,
        title: Text('Reject "${event.title}"', style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter')),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
          CmsButton(
            label: 'Reject',
            compact: true,
            variant: CmsButtonVariant.danger,
            onPressed: () async {
              final reason = ctrl.text.trim().isEmpty ? 'Not approved by Pastor' : ctrl.text.trim();
              await ref.read(eventRepositoryProvider).rejectEvent(branchId, event.id, reason);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => switch (m) {
    1 => 'JAN', 2 => 'FEB', 3 => 'MAR', 4 => 'APR',
    5 => 'MAY', 6 => 'JUN', 7 => 'JUL', 8 => 'AUG',
    9 => 'SEP', 10 => 'OCT', 11 => 'NOV', 12 => 'DEC',
    _ => '',
  };

  String _formatEventType(String type) => switch (type) {
    'yearly_calendar' => 'Yearly Calendar',
    'wedding_programme' => 'Wedding Programme',
    'revival_programme' => 'Revival Programme',
    'conference' => 'Conference',
    'anniversary' => 'Anniversary',
    'sunday_service' => 'Sunday Service',
    'midweek_service' => 'Midweek Service',
    _ => 'Special Programme',
  };
}

// ─────────────────────────── Status Badge ────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.reason});
  final String status;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    if (s == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: CmsTheme.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CmsTheme.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 12, color: CmsTheme.success),
            SizedBox(width: 4),
            Text('Approved', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: CmsTheme.success)),
          ],
        ),
      );
    } else if (s == 'pending_approval' || s == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: CmsTheme.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CmsTheme.warning.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 12, color: CmsTheme.warning),
            SizedBox(width: 4),
            Text('Pending Review', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: CmsTheme.warning)),
          ],
        ),
      );
    } else {
      return Tooltip(
        message: reason ?? 'Rejected by Lead Pastor',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: CmsTheme.danger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: CmsTheme.danger.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel_outlined, size: 12, color: CmsTheme.danger),
              SizedBox(width: 4),
              Text('Rejected', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: CmsTheme.danger)),
            ],
          ),
        ),
      );
    }
  }
}

// ─────────────────────────── Event Form Dialog ─────────────────────────────

class _EventFormDialog extends StatefulWidget {
  const _EventFormDialog({required this.branchId, required this.ref, this.event, this.user});
  final String branchId;
  final WidgetRef ref;
  final EventModel? event;
  final CmsUserModel? user;

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _mediaUrlCtrl;

  String _category = 'Sunday Service';
  String _eventType = 'special_event';
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _saving = false;

  static const _eventTypes = [
    DropdownMenuItem(value: 'yearly_calendar', child: Text('Church Year Calendar Event')),
    DropdownMenuItem(value: 'wedding_programme', child: Text('Wedding Programme')),
    DropdownMenuItem(value: 'revival_programme', child: Text('Revival Programme')),
    DropdownMenuItem(value: 'conference', child: Text('Conference / Convention')),
    DropdownMenuItem(value: 'anniversary', child: Text('Church Anniversary')),
    DropdownMenuItem(value: 'special_event', child: Text('Special Event')),
    DropdownMenuItem(value: 'sunday_service', child: Text('Sunday Service')),
    DropdownMenuItem(value: 'midweek_service', child: Text('Midweek Service')),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _locCtrl = TextEditingController(text: e?.location ?? 'Main Auditorium');
    _mediaUrlCtrl = TextEditingController(text: e?.mediaUrls.isNotEmpty == true ? e!.mediaUrls.first : '');
    _category = e?.category ?? 'Sunday Service';
    _eventType = e?.eventType ?? 'special_event';

    final start = e?.effectiveStartDate ?? DateTime.now();
    final end = e?.effectiveEndDate ?? DateTime.now().add(const Duration(hours: 2));
    _startDate = start;
    _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
    _endDate = end;
    _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _mediaUrlCtrl.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isPastorOrAdmin = widget.user?.roleId == AppRole.leadPastor || widget.user?.roleId == 'admin';
    final startDT = _combine(_startDate, _startTime);
    final endDT = _combine(_endDate, _endTime);

    return AlertDialog(
      backgroundColor: CmsTheme.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          const Icon(Icons.event, color: CmsTheme.accent, size: 22),
          const SizedBox(width: 8),
          Text(
            widget.event == null ? 'Schedule Church Event' : 'Edit Event',
            style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                if (!isPastorOrAdmin)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CmsTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: CmsTheme.accent, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Events entered by Secretary will be submitted to the Lead Pastor for review & approval before appearing on the Church Calendar.',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Title
                const Text('Event / Programme Title', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'e.g. Annual Youth Revival 2026'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Programme Classification', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _eventType,
                            dropdownColor: CmsTheme.surfaceElevated,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(),
                            items: _eventTypes,
                            onChanged: (v) => setState(() => _eventType = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Venue / Location', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _locCtrl,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(hintText: 'Main Sanctuary'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Start Date & Time ────────────────────────────────────
                const Text('Start Date & Time', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _pickStartDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(color: CmsTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: CmsTheme.border)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 15, color: CmsTheme.accent),
                              const SizedBox(width: 8),
                              Text(DateFormat('EEE, MMM d, yyyy').format(_startDate), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(color: CmsTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: CmsTheme.border)),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 15, color: CmsTheme.accent),
                              const SizedBox(width: 8),
                              Text(_startTime.format(context), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── End Date & Time ──────────────────────────────────────
                const Text('End Date & Time', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _pickEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(color: CmsTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: CmsTheme.border)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 15, color: CmsTheme.success),
                              const SizedBox(width: 8),
                              Text(DateFormat('EEE, MMM d, yyyy').format(_endDate), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(color: CmsTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: CmsTheme.border)),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 15, color: CmsTheme.success),
                              const SizedBox(width: 8),
                              Text(_endTime.format(context), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Banner URL & Description
                TextFormField(
                  controller: _mediaUrlCtrl,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(labelText: 'Banner / Flyer URL (Optional)', prefixIcon: Icon(Icons.image_outlined, size: 16, color: CmsTheme.textMuted)),
                ),
                const SizedBox(height: 12),

                const Text('Programme Description & Details', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'Enter agenda, guest ministers, or special instructions…'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary)),
        ),
        CmsButton(
          label: isPastorOrAdmin ? 'Publish Event' : 'Submit for Pastor Review',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final initialStatus = isPastorOrAdmin ? 'approved' : 'pending_approval';
              final ev = EventModel(
                id: widget.event?.id ?? '',
                title: _titleCtrl.text.trim(),
                description: _descCtrl.text.trim(),
                dateTime: startDT,
                startDate: startDT,
                endDate: endDT,
                location: _locCtrl.text.trim(),
                category: _category,
                eventType: _eventType,
                year: _startDate.year,
                status: widget.event?.status ?? initialStatus,
                createdByName: widget.user?.displayName ?? widget.user?.email ?? 'Secretary',
                createdByRole: widget.user?.roleId ?? 'secretary',
                mediaUrls: _mediaUrlCtrl.text.trim().isNotEmpty ? [_mediaUrlCtrl.text.trim()] : const [],
              );
              await widget.ref.read(eventRepositoryProvider).saveEvent(widget.branchId, ev);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isPastorOrAdmin ? 'Event published!' : 'Submitted to Lead Pastor for review.'),
                    backgroundColor: isPastorOrAdmin ? CmsTheme.success : CmsTheme.accent,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger),
                );
              }
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
        ),
      ],
    );
  }
}

// ─────────────────────────── Yearly Calendar Batch Dialog ──────────────────

class _YearlyCalendarBatchDialog extends StatefulWidget {
  const _YearlyCalendarBatchDialog({required this.branchId, required this.ref, this.user});
  final String branchId;
  final WidgetRef ref;
  final CmsUserModel? user;

  @override
  State<_YearlyCalendarBatchDialog> createState() => _YearlyCalendarBatchDialogState();
}

class _YearlyCalendarBatchDialogState extends State<_YearlyCalendarBatchDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController(text: 'Main Sanctuary');
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  String _type = 'yearly_calendar';
  bool _saving = false;
  int? _editingIndex;

  final List<EventModel> _draftEvents = [];

  static const _types = [
    DropdownMenuItem(value: 'yearly_calendar', child: Text('Church Year Calendar')),
    DropdownMenuItem(value: 'revival_programme', child: Text('Revival Programme')),
    DropdownMenuItem(value: 'conference', child: Text('Conference')),
    DropdownMenuItem(value: 'anniversary', child: Text('Anniversary')),
    DropdownMenuItem(value: 'special_event', child: Text('Special Event')),
    DropdownMenuItem(value: 'wedding_programme', child: Text('Wedding Programme')),
  ];

  DateTime _combine(DateTime d, TimeOfDay t) => DateTime(d.year, d.month, d.day, t.hour, t.minute);

  void _addOrUpdateToList() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final startDT = _combine(_startDate, _startTime);
    final endDT = _combine(_endDate, _endTime);
    final ev = EventModel(
      id: _editingIndex != null ? _draftEvents[_editingIndex!].id : '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? 'Church Year Calendar Event' : _descCtrl.text.trim(),
      dateTime: startDT,
      startDate: startDT,
      endDate: endDT,
      location: _locCtrl.text.trim().isEmpty ? 'Main Sanctuary' : _locCtrl.text.trim(),
      category: 'Special Event',
      eventType: _type,
      year: _startDate.year,
      status: 'pending_approval',
      createdByName: widget.user?.displayName ?? 'Secretary',
    );
    setState(() {
      if (_editingIndex != null) {
        _draftEvents[_editingIndex!] = ev;
        _editingIndex = null;
      } else {
        _draftEvents.add(ev);
      }
      _titleCtrl.clear();
      _descCtrl.clear();
      _locCtrl.text = 'Main Sanctuary';
    });
  }

  void _editEntry(int index) {
    final ev = _draftEvents[index];
    setState(() {
      _editingIndex = index;
      _titleCtrl.text = ev.title;
      _descCtrl.text = ev.description == 'Church Year Calendar Event' ? '' : ev.description;
      _locCtrl.text = ev.location;
      _type = ev.eventType;
      _startDate = ev.effectiveStartDate;
      _startTime = TimeOfDay(hour: ev.effectiveStartDate.hour, minute: ev.effectiveStartDate.minute);
      _endDate = ev.effectiveEndDate;
      _endTime = TimeOfDay(hour: ev.effectiveEndDate.hour, minute: ev.effectiveEndDate.minute);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CmsTheme.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(
        children: [
          Icon(Icons.calendar_month, color: CmsTheme.accent, size: 22),
          SizedBox(width: 8),
          Text('Create Church Year Calendar', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add key annual programmes to the yearly calendar schedule:', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 14),

              // ── Entry Form ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CmsTheme.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _editingIndex != null ? CmsTheme.accent : CmsTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_editingIndex != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 14, color: CmsTheme.accent),
                            const SizedBox(width: 6),
                            Text('Editing entry #${_editingIndex! + 1}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.accent, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => setState(() { _editingIndex = null; _titleCtrl.clear(); _descCtrl.clear(); _locCtrl.text = 'Main Sanctuary'; }),
                              child: const Text('Cancel Edit', style: TextStyle(color: CmsTheme.textMuted, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),

                    // Title & Type row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _titleCtrl,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(hintText: 'Programme title (e.g. Easter Retreat)'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _type,
                            dropdownColor: CmsTheme.surfaceElevated,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter', fontSize: 12),
                            decoration: const InputDecoration(),
                            items: _types,
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Venue
                    TextField(
                      controller: _locCtrl,
                      style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                      decoration: const InputDecoration(
                        hintText: 'Venue / Location',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 14, color: CmsTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Start Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final p = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
                              if (p != null) setState(() { _startDate = p; if (_endDate.isBefore(p)) _endDate = p; });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(color: CmsTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: CmsTheme.border)),
                              child: Row(children: [
                                const Icon(Icons.calendar_today, size: 13, color: CmsTheme.accent),
                                const SizedBox(width: 6),
                                Text('Start: ${DateFormat('MMM d, yyyy').format(_startDate)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary)),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final p = await showTimePicker(context: context, initialTime: _startTime);
                            if (p != null) setState(() => _startTime = p);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(color: CmsTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: CmsTheme.border)),
                            child: Row(children: [
                              const Icon(Icons.access_time, size: 13, color: CmsTheme.accent),
                              const SizedBox(width: 6),
                              Text(_startTime.format(context), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // End Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final p = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime(2035));
                              if (p != null) setState(() => _endDate = p);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(color: CmsTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: CmsTheme.border)),
                              child: Row(children: [
                                const Icon(Icons.calendar_today, size: 13, color: CmsTheme.success),
                                const SizedBox(width: 6),
                                Text('End:  ${DateFormat('MMM d, yyyy').format(_endDate)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary)),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final p = await showTimePicker(context: context, initialTime: _endTime);
                            if (p != null) setState(() => _endTime = p);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(color: CmsTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: CmsTheme.border)),
                            child: Row(children: [
                              const Icon(Icons.access_time, size: 13, color: CmsTheme.success),
                              const SizedBox(width: 6),
                              Text(_endTime.format(context), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Description
                    TextField(
                      controller: _descCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter', fontSize: 12),
                      decoration: const InputDecoration(hintText: 'Brief description (optional)'),
                    ),
                    const SizedBox(height: 10),

                    // Add button
                    Align(
                      alignment: Alignment.centerRight,
                      child: CmsButton(
                        label: _editingIndex != null ? 'Update Entry' : '+ Add to Calendar',
                        icon: _editingIndex != null ? Icons.check : Icons.add,
                        compact: true,
                        onPressed: _addOrUpdateToList,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_draftEvents.isNotEmpty) ...[
                const Text('Draft Calendar Entries:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: CmsTheme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CmsTheme.border),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(1.5),
                      3: FixedColumnWidth(80),
                    },
                    border: TableBorder(horizontalInside: BorderSide(color: CmsTheme.border, width: 0.5)),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: CmsTheme.surfaceElevated),
                        children: const [
                          _TableHeader('Programme'),
                          _TableHeader('Date Range'),
                          _TableHeader('Venue'),
                          _TableHeader('Actions'),
                        ],
                      ),
                      for (int i = 0; i < _draftEvents.length; i++)
                        TableRow(
                          decoration: BoxDecoration(
                            color: _editingIndex == i ? CmsTheme.accent.withValues(alpha: 0.05) : Colors.transparent,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text(_draftEvents[i].title, style: const TextStyle(color: CmsTheme.textPrimary, fontSize: 12, fontFamily: 'Inter')),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(DateFormat('MMM d, yyyy').format(_draftEvents[i].effectiveStartDate), style: const TextStyle(color: CmsTheme.textPrimary, fontSize: 11, fontFamily: 'Inter')),
                                if (_draftEvents[i].effectiveEndDate.day != _draftEvents[i].effectiveStartDate.day)
                                  Text('– ${DateFormat('MMM d, yyyy').format(_draftEvents[i].effectiveEndDate)}', style: const TextStyle(color: CmsTheme.textMuted, fontSize: 11, fontFamily: 'Inter')),
                                Text('${TimeOfDay(hour: _draftEvents[i].effectiveStartDate.hour, minute: _draftEvents[i].effectiveStartDate.minute).format(context)} – ${TimeOfDay(hour: _draftEvents[i].effectiveEndDate.hour, minute: _draftEvents[i].effectiveEndDate.minute).format(context)}', style: const TextStyle(color: CmsTheme.textMuted, fontSize: 10, fontFamily: 'Inter')),
                              ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text(_draftEvents[i].location, style: const TextStyle(color: CmsTheme.textSecondary, fontSize: 11, fontFamily: 'Inter')),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 14, color: CmsTheme.accent),
                                  tooltip: 'Edit',
                                  onPressed: () => _editEntry(i),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 14, color: CmsTheme.danger),
                                  tooltip: 'Remove',
                                  onPressed: () => setState(() => _draftEvents.removeAt(i)),
                                ),
                              ]),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: 'Submit Calendar to Pastor',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (_draftEvents.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one calendar event.')));
              return;
            }
            setState(() => _saving = true);
            try {
              for (final ev in _draftEvents) {
                await widget.ref.read(eventRepositoryProvider).saveEvent(widget.branchId, ev);
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Church Year Calendar submitted for Pastor review!'), backgroundColor: CmsTheme.accent),
                );
              }
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
        ),
      ],
    );
  }
}
