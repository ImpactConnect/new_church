import 'dart:async';
import 'package:church_mobile/models/member.dart';
import 'package:church_mobile/widgets/members/member_details_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MembersDirectoryScreen extends StatefulWidget {
  const MembersDirectoryScreen({Key? key}) : super(key: key);

  @override
  State<MembersDirectoryScreen> createState() =>
      _MembersDirectoryScreenState();
}

class _MembersDirectoryScreenState extends State<MembersDirectoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Member> _allMembers = [];
  List<Member> _filtered = [];
  bool _loading = true;
  StreamSubscription? _sub;
  StreamSubscription? _groupsSub;
  StreamSubscription? _officialsSub;

  List<String> _churchGroups = [];
  Set<String> _officialIds = {};
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance.collection('members').orderBy('name').snapshots().listen((snap) {
      final members = snap.docs.map((d) => Member.fromFirestore(d)).toList();
      if (mounted) {
        setState(() {
          _allMembers = members;
          _applyFilter();
          _loading = false;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });

    _groupsSub = FirebaseFirestore.instance.collection('church_groups').orderBy('name').snapshots().listen((snap) {
      if (mounted) {
        setState(() {
          _churchGroups = snap.docs.map((d) => d['name'] as String).toList();
        });
      }
    });

    _officialsSub = FirebaseFirestore.instance.collection('church_officials').snapshots().listen((snap) {
      if (mounted) {
        setState(() {
          _officialIds = snap.docs.map((d) => d['memberId'] as String).toSet();
          _applyFilter();
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _groupsSub?.cancel();
    _officialsSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    _filtered = _allMembers.where((m) {
      if (m.role?.toLowerCase() == 'admin') return false;
      
      final matchesSearch = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          (m.occupation?.toLowerCase().contains(q) ?? false);

      bool matchesGroup = true;
      if (_selectedFilter == 'Church Officials') {
        matchesGroup = _officialIds.contains(m.id);
      } else if (_selectedFilter != 'All') {
        matchesGroup = m.churchGroup == _selectedFilter;
      }

      return matchesSearch && matchesGroup;
    }).toList();
  }

  // ── Upcoming celebrants (next 3 within 30 days) ──────────────────────────
  List<_UpcomingCelebrant> _getUpcomingCelebrants() {
    final now = DateTime.now();
    final results = <_UpcomingCelebrant>[];

    for (final m in _allMembers) {
      for (final isBday in [true, false]) {
        final date = isBday ? m.birthDate : m.weddingDate;
        if (date == null) continue;
        // Find the next occurrence of this day/month
        var next = DateTime(now.year, date.month, date.day);
        if (next.isBefore(DateTime(now.year, now.month, now.day))) {
          next = DateTime(now.year + 1, date.month, date.day);
        }
        final diff = next.difference(DateTime(now.year, now.month, now.day)).inDays;
        if (diff <= 30) {
          results.add(_UpcomingCelebrant(
              member: m, isBirthday: isBday, daysUntil: diff, date: next));
        }
      }
    }

    results.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return results.take(3).toList();
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  // ── Member Card ───────────────────────────────────────────────────────────
  Widget _memberCard(Member member) {
    final initials = member.name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
    final dob = member.birthDate;
    final dobStr = dob != null ? '${dob.day} ${_monthName(dob.month)}' : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showDialog(
          context: context,
          builder: (_) => MemberDetailsDialog(member: member),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar
              member.imageUrl != null
                  ? CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(member.imageUrl!),
                    )
                  : CircleAvatar(
                      radius: 26,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                      child: Text(initials,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              fontSize: 15)),
                    ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    if (member.occupation != null)
                      Text(member.occupation!,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                    if (dobStr != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(children: [
                          Icon(Icons.cake_outlined,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(dobStr,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 11)),
                        ]),
                      ),
                  ],
                ),
              ),
              // Group badge
              if (member.maritalStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.maritalStatus!.toDisplayString(),
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── Upcoming celebrant chip ───────────────────────────────────────────────
  Widget _celebrantChip(_UpcomingCelebrant c) {
    final color = c.isBirthday ? Colors.pink : Colors.purple;
    final icon = c.isBirthday ? Icons.cake_outlined : Icons.favorite_outline;
    final label = c.daysUntil == 0
        ? 'Today!'
        : c.daysUntil == 1
            ? 'Tomorrow'
            : 'In ${c.daysUntil} days';
    final dateStr = '${c.date.day} ${_monthName(c.date.month)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            backgroundImage: c.member.imageUrl != null
                ? NetworkImage(c.member.imageUrl!)
                : null,
            child: c.member.imageUrl == null
                ? Icon(icon, size: 14, color: color)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.member.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text(
                  '${c.isBirthday ? "Birthday" : "Anniversary"} · $dateStr',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upcoming = _getUpcomingCelebrants();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Members Directory',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColorDark,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Search & Filter ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(_applyFilter),
                    decoration: InputDecoration(
                      hintText: 'Search by name or occupation...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(_applyFilter);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Dropdown
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedFilter,
                        icon: Icon(Icons.filter_list, size: 18, color: theme.primaryColor),
                        style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All Members')),
                          const DropdownMenuItem(value: 'Church Officials', child: Text('Church Officials')),
                          if (_churchGroups.isNotEmpty)
                            const DropdownMenuItem(
                              enabled: false,
                              child: Text('── GROUPS ──', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            ),
                          ..._churchGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedFilter = v;
                              _applyFilter();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Upcoming Celebrants ──────────────────────────────────────────
          if (upcoming.isNotEmpty && _searchCtrl.text.isEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Row(children: [
                  Icon(Icons.celebration_outlined,
                      color: theme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  const Text('Upcoming Celebrants',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: upcoming.map(_celebrantChip).toList(),
                ),
              ),
            ),
          ],

          // ── Members list header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(
                children: [
                  Icon(Icons.people_outline,
                      color: theme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _searchCtrl.text.isNotEmpty
                        ? '${_filtered.length} result${_filtered.length == 1 ? "" : "s"}'
                        : 'All Members (${_allMembers.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_search,
                        size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      _searchCtrl.text.isNotEmpty
                          ? 'No members found'
                          : 'No members yet',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _memberCard(_filtered[i]),
                  childCount: _filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UpcomingCelebrant {
  final Member member;
  final bool isBirthday;
  final int daysUntil;
  final DateTime date;
  const _UpcomingCelebrant({
    required this.member,
    required this.isBirthday,
    required this.daysUntil,
    required this.date,
  });
}
