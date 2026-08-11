import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/events/models/event_model.dart';
import 'package:cms/src/features/members/models/member_model.dart';

final _membersForAttendanceProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);

final _existingAttendanceProvider = StreamProvider.autoDispose.family<List<AttendanceModel>, (String, String)>(
  (ref, params) => ref.watch(eventRepositoryProvider).watchAttendance(params.$1, params.$2),
);

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key, required this.event});
  final EventModel event;

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final Map<String, String> _attendanceState = {}; // memberId -> 'present' | 'absent' | 'excused'
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initAttendance(List<AttendanceModel> existing, List<MemberModel> members) {
    if (_attendanceState.isNotEmpty) return;
    final existingMap = {for (final a in existing) a.memberId: a.status};
    for (final m in members) {
      _attendanceState[m.id] = existingMap[m.id] ?? 'absent';
    }
  }

  Future<void> _saveAttendance(String branchId) async {
    setState(() => _saving = true);
    try {
      final members = ref.read(_membersForAttendanceProvider(branchId)).valueOrNull ?? [];
      final memberMap = {for (final m in members) m.id: m.fullName};

      final records = _attendanceState.entries.map((e) => AttendanceModel(
        id: e.key,
        eventId: widget.event.id,
        memberId: e.key,
        memberName: memberMap[e.key] ?? '',
        status: e.value,
        timestamp: DateTime.now(),
      )).toList();

      await ref.read(eventRepositoryProvider).recordAttendance(branchId, widget.event.id, records);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Attendance saved successfully.'), backgroundColor: CmsTheme.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving attendance: $e'), backgroundColor: CmsTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final membersAsync = ref.watch(_membersForAttendanceProvider(branchId));
    final attendanceAsync = ref.watch(_existingAttendanceProvider((branchId, widget.event.id)));

    return Scaffold(
      backgroundColor: CmsTheme.bg,
      appBar: AppBar(
        backgroundColor: CmsTheme.sidebar,
        foregroundColor: CmsTheme.textPrimary,
        elevation: 0,
        title: Text(
          'Attendance — ${widget.event.title}',
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CmsButton(
              label: 'Save Record',
              icon: Icons.check,
              compact: true,
              loading: _saving,
              onPressed: () => _saveAttendance(branchId),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CmsSearchField(
                  controller: _searchCtrl,
                  hint: 'Filter member roster…',
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
                const Spacer(),
                _summaryChip('Present: ${_countStatus('present')}', CmsTheme.success),
                const SizedBox(width: 8),
                _summaryChip('Absent: ${_countStatus('absent')}', CmsTheme.textMuted),
                const SizedBox(width: 8),
                _summaryChip('Excused: ${_countStatus('excused')}', CmsTheme.warning),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: CmsCard(
                padding: EdgeInsets.zero,
                child: membersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                  data: (members) {
                    return attendanceAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                      data: (existing) {
                        _initAttendance(existing, members);

                        final filtered = members.where((m) =>
                          _searchQuery.isEmpty || m.fullName.toLowerCase().contains(_searchQuery)
                        ).toList();

                        if (filtered.isEmpty) {
                          return const CmsEmptyState(
                            icon: Icons.people_outline,
                            title: 'No members match query',
                          );
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: CmsTheme.border),
                          itemBuilder: (_, i) {
                            final m = filtered[i];
                            final status = _attendanceState[m.id] ?? 'absent';
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: CmsTheme.accent.withValues(alpha: 0.15),
                                child: Text(
                                  m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: CmsTheme.accent, fontWeight: FontWeight.w600),
                                ),
                              ),
                              title: Text(m.fullName, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: CmsTheme.textPrimary)),
                              subtitle: Text(m.phone, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                              trailing: SegmentedButton<String>(
                                selected: {status},
                                onSelectionChanged: (set) {
                                  setState(() => _attendanceState[m.id] = set.first);
                                },
                                segments: const [
                                  ButtonSegment(value: 'present', label: Text('Present', style: TextStyle(fontSize: 12))),
                                  ButtonSegment(value: 'absent', label: Text('Absent', style: TextStyle(fontSize: 12))),
                                  ButtonSegment(value: 'excused', label: Text('Excused', style: TextStyle(fontSize: 12))),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countStatus(String st) => _attendanceState.values.where((v) => v == st).length;

  Widget _summaryChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: color)),
  );
}
