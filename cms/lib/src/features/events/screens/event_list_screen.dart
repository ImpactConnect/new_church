import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/events/models/event_model.dart';
import 'package:cms/src/features/events/screens/attendance_screen.dart';

final _eventsProvider = StreamProvider.autoDispose.family<List<EventModel>, String>(
  (ref, branchId) => ref.watch(eventRepositoryProvider).watchEvents(branchId),
);

class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final eventsAsync = ref.watch(_eventsProvider(branchId));
    final canManage = user?.can(AppPermission.manageEvents) ?? false;
    final canRecordAtt = user?.can(AppPermission.recordAttendance) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Events & Services',
            subtitle: 'Schedule church programs and track attendance',
            actions: [
              if (canManage)
                CmsButton(
                  label: 'Schedule Event',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showEventDialog(context, ref, branchId, null),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
              data: (events) {
                if (events.isEmpty) {
                  return CmsEmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'No upcoming events',
                    subtitle: 'Schedule your first church service or program.',
                    action: canManage
                        ? CmsButton(
                            label: 'Schedule Event',
                            icon: Icons.add,
                            onPressed: () => _showEventDialog(context, ref, branchId, null),
                          )
                        : null,
                  );
                }
                return ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _EventCard(
                    event: events[i],
                    canManage: canManage,
                    canRecordAtt: canRecordAtt,
                    onTakeAttendance: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AttendanceScreen(event: events[i])),
                    ),
                    onEdit: () => _showEventDialog(context, ref, branchId, events[i]),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDialog(BuildContext context, WidgetRef ref, String branchId, EventModel? event) {
    showDialog(
      context: context,
      builder: (_) => _EventFormDialog(branchId: branchId, ref: ref, event: event),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.canManage,
    required this.canRecordAtt,
    required this.onTakeAttendance,
    required this.onEdit,
    required this.onDelete,
  });

  final EventModel event;
  final bool canManage;
  final bool canRecordAtt;
  final VoidCallback onTakeAttendance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        children: [
          // Date box badge
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: CmsTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.dateTime.day.toString(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CmsTheme.accent,
                  ),
                ),
                Text(
                  _monthName(event.dateTime.month),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CmsTheme.textSecondary,
                  ),
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
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CmsTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: CmsTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.category,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: CmsTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(event.location, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                    const SizedBox(width: 16),
                    const Icon(Icons.people_outline, size: 14, color: CmsTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('${event.headcount} attended', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          if (canRecordAtt)
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

  String _monthName(int m) => switch (m) {
    1 => 'JAN', 2 => 'FEB', 3 => 'MAR', 4 => 'APR',
    5 => 'MAY', 6 => 'JUN', 7 => 'JUL', 8 => 'AUG',
    9 => 'SEP', 10 => 'OCT', 11 => 'NOV', 12 => 'DEC',
    _ => '',
  };
}

class _EventFormDialog extends StatefulWidget {
  const _EventFormDialog({required this.branchId, required this.ref, this.event});
  final String branchId;
  final WidgetRef ref;
  final EventModel? event;

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locCtrl;
  String _category = 'Sunday Service';
  DateTime _dateTime = DateTime.now();
  bool _saving = false;

  static const _categories = ['Sunday Service', 'Midweek Service', 'Vigil', 'Youth Service', 'Special Event'];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _locCtrl = TextEditingController(text: e?.location ?? 'Main Auditorium');
    _category = e?.category ?? 'Sunday Service';
    _dateTime = e?.dateTime ?? DateTime.now();
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
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: Text(
        widget.event == null ? 'Schedule Event' : 'Edit Event',
        style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Title', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          dropdownColor: CmsTheme.surfaceElevated,
                          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                          decoration: const InputDecoration(),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Location', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _locCtrl,
                          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                          decoration: const InputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary)),
        ),
        CmsButton(
          label: 'Save',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final ev = EventModel(
                id: widget.event?.id ?? '',
                title: _titleCtrl.text.trim(),
                description: _descCtrl.text.trim(),
                dateTime: _dateTime,
                location: _locCtrl.text.trim(),
                category: _category,
                headcount: widget.event?.headcount ?? 0,
              );
              await widget.ref.read(eventRepositoryProvider).saveEvent(widget.branchId, ev);
              if (context.mounted) Navigator.pop(context);
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
