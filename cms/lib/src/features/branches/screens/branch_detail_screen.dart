import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/branches/models/branch_model.dart';
import 'package:cms/src/features/events/models/event_model.dart';
import 'package:cms/src/features/members/models/member_model.dart';
import 'package:cms/src/features/finance/models/budget_model.dart';
import 'package:cms/src/routing/app_router.dart';

final _branchDetailStreamProvider = StreamProvider.autoDispose.family<BranchModel?, String>(
  (ref, branchId) => ref.watch(branchRepositoryProvider).watchBranch(branchId),
);

final _branchEventsProvider = StreamProvider.autoDispose.family<List<EventModel>, String>(
  (ref, branchId) => ref.watch(eventRepositoryProvider).watchEvents(branchId),
);

final _branchMembersProvider = StreamProvider.autoDispose.family<List<MemberModel>, String>(
  (ref, branchId) => ref.watch(memberRepositoryProvider).watchMembers(branchId),
);


final _branchIncomeProvider = StreamProvider.autoDispose.family<List<IncomeModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchIncome(branchId),
);

final _branchGivingProvider = StreamProvider.autoDispose.family<List<GivingModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchGiving(branchId),
);

final _branchExpendituresProvider = StreamProvider.autoDispose.family<List<ExpenditureModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchApprovedExpenditures(branchId),
);

final _branchExpRequestsProvider = StreamProvider.autoDispose.family<List<ExpenditureRequestModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchExpenditureRequests(branchId),
);

final _branchBudgetsProvider = StreamProvider.autoDispose.family<List<BudgetModel>, String>(
  (ref, branchId) => ref.watch(financeRepositoryProvider).watchBudgets(branchId),
);

class BranchDetailScreen extends ConsumerStatefulWidget {
  const BranchDetailScreen({super.key, required this.branchId});

  final String branchId;

  @override
  ConsumerState<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends ConsumerState<BranchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _memberSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchAsync = ref.watch(_branchDetailStreamProvider(widget.branchId));
    final currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return branchAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, __) => Scaffold(body: Center(child: Text('Error loading branch: $err', style: const TextStyle(color: CmsTheme.danger)))),
      data: (branch) {
        if (branch == null) {
          return const Scaffold(body: Center(child: Text('Branch church not found.', style: TextStyle(color: CmsTheme.textMuted))));
        }

        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Navigation & Branch Title Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: CmsTheme.textPrimary),
                    onPressed: () => context.go(AppRoutes.branches),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            branch.name,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: branch.active ? CmsTheme.success.withValues(alpha: 0.1) : CmsTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              branch.active ? 'ACTIVE BRANCH' : 'INACTIVE',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: branch.active ? CmsTheme.success : CmsTheme.danger),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pastor-in-Charge: ${branch.pastorInCharge} ${branch.pastorEmail != null ? "(${branch.pastorEmail})" : ""} · Address: ${branch.address}',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tab Selector Header Bar
              Container(
                decoration: BoxDecoration(
                  color: CmsTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CmsTheme.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: CmsTheme.accent,
                  unselectedLabelColor: CmsTheme.textSecondary,
                  indicatorColor: CmsTheme.accent,
                  labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(icon: Icon(Icons.how_to_reg_outlined, size: 18), text: 'Attendance Reports & Growth'),
                    Tab(icon: Icon(Icons.monetization_on_outlined, size: 18), text: 'Financial Reports & Ledger'),
                    Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Fund & Budget Requests'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab Views Container
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAttendanceTab(widget.branchId),
                    _buildFinanceTab(widget.branchId, currencyFmt),
                    _buildRequestsTab(widget.branchId, currencyFmt),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 1: Attendance Reports & Growth + Branch Members Directory ──────────
  Widget _buildAttendanceTab(String branchId) {
    final eventsAsync = ref.watch(_branchEventsProvider(branchId));
    final membersAsync = ref.watch(_branchMembersProvider(branchId));
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final isLeadPastor = user?.can(AppPermission.manageRoles) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Metrics Summary Cards
        Row(

          children: [
            _buildStatCard(
              'Branch Members',
              '${membersAsync.valueOrNull?.length ?? 0}',
              'Registered branch members',
              Icons.people_outline,
              CmsTheme.accent,
            ),
            const SizedBox(width: 14),
            _buildStatCard(
              'Average Attendance',
              eventsAsync.when(
                data: (evs) {
                  final total = evs.fold<int>(0, (s, e) => s + e.headcount);
                  return evs.isNotEmpty ? '${(total / evs.length).round()} attendees' : '0 attendees';
                },
                loading: () => '…',
                error: (_, __) => '0 attendees',
              ),
              'Per service average',
              Icons.show_chart,
              CmsTheme.success,
            ),
            const SizedBox(width: 14),
            _buildStatCard(
              'Services Logged',
              '${eventsAsync.valueOrNull?.length ?? 0}',
              'Total services recorded',
              Icons.event_note,
              CmsTheme.info,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Main Content Split View: Left (Members Directory) & Right (Service Attendance Log)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Branch Members Directory
              Expanded(
                flex: 3,
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_alt_outlined, color: CmsTheme.accent, size: 18),
                          const SizedBox(width: 8),
                          const Text('Branch Members Directory', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                          const Spacer(),
                          SizedBox(
                            width: 180,
                            height: 32,
                            child: TextField(
                              onChanged: (v) => setState(() => _memberSearchQuery = v),
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Search member…',
                                hintStyle: const TextStyle(color: CmsTheme.textMuted, fontSize: 12),
                                prefixIcon: const Icon(Icons.search, size: 14, color: CmsTheme.textMuted),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: CmsTheme.border)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: membersAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: CmsTheme.danger))),
                          data: (members) {
                            final filtered = members.where((m) {
                              final q = _memberSearchQuery.toLowerCase();
                              return m.fullName.toLowerCase().contains(q) ||
                                  m.phone.contains(q) ||
                                  (m.email != null && m.email!.toLowerCase().contains(q));
                            }).toList();

                            if (filtered.isEmpty) {
                              return const Center(
                                child: Text('No branch members registered yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted)),
                              );
                            }

                            return ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 10),
                              itemBuilder: (context, i) {
                                final m = filtered[i];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: CmsTheme.accent.withValues(alpha: 0.15),
                                    child: Text(m.firstName.isNotEmpty ? m.firstName[0] : 'M', style: const TextStyle(color: CmsTheme.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  title: Text(m.fullName, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                                  subtitle: Text('${m.phone} ${m.email != null ? "· ${m.email}" : ""}', style: const TextStyle(fontSize: 11, color: CmsTheme.textMuted)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: m.memberStatus == 'active' ? CmsTheme.success.withValues(alpha: 0.1) : CmsTheme.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      m.memberStatus.toUpperCase(),
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: m.memberStatus == 'active' ? CmsTheme.success : CmsTheme.warning),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Right Column: Service Attendance Log
              Expanded(
                flex: 3,
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_available, color: CmsTheme.accent, size: 18),
                          const SizedBox(width: 8),
                          const Text('Branch Service Attendance Log', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                          const Spacer(),
                          eventsAsync.when(
                            data: (events) => Text('${events.length} Services Recorded', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: eventsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: CmsTheme.danger))),
                          data: (events) {
                            if (events.isEmpty) {
                              return const Center(
                                child: Text('No service attendance reports logged for this branch yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted)),
                              );
                            }

                            return ListView.separated(

                              itemCount: events.length,
                              separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 12),
                              itemBuilder: (context, index) {
                                final ev = events[index];
                                return ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: CmsTheme.info.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.people_alt_outlined, color: CmsTheme.info, size: 20),
                                  ),
                                  title: Text(ev.title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                                  subtitle: Text('${DateFormat('EEE, MMM d, yyyy').format(ev.dateTime)} · ${ev.category}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: CmsTheme.surfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: CmsTheme.border),
                                    ),
                                    child: Text('${ev.headcount} Attendees', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: CmsTheme.success)),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRecordAttendanceDialog(BuildContext context, String branchId) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: 'Sunday Service');
    final headcountCtrl = TextEditingController();
    String category = 'Sunday Service';
    DateTime selectedDate = DateTime.now();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            backgroundColor: CmsTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Record Branch Service Attendance', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Service Title *', hintText: 'e.g. Sunday Celebration Service'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Service Category *'),
                      items: const [
                        DropdownMenuItem(value: 'Sunday Service', child: Text('Sunday Service')),
                        DropdownMenuItem(value: 'Midweek Service', child: Text('Midweek Service')),
                        DropdownMenuItem(value: 'Special Event', child: Text('Special Event')),
                        DropdownMenuItem(value: 'Vigil', child: Text('Vigil')),
                      ],
                      onChanged: (v) => setDlgState(() => category = v ?? 'Sunday Service'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: headcountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Attendance Headcount *', hintText: 'e.g. 150'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 16, color: CmsTheme.accent),
                        const SizedBox(width: 8),
                        Text('Service Date: ${DateFormat('EEE, MMM d, yyyy').format(selectedDate)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary)),
                        const Spacer(),
                        TextButton(
                          child: const Text('Change Date', style: TextStyle(color: CmsTheme.accent, fontSize: 12)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setDlgState(() => selectedDate = picked);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: CmsTheme.textMuted)),
              ),
              CmsButton(
                label: saving ? 'Saving…' : 'Record Attendance',
                icon: Icons.check,
                onPressed: saving ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDlgState(() => saving = true);
                  try {
                    final event = EventModel(
                      id: '',
                      title: titleCtrl.text.trim(),
                      description: 'Branch service attendance report',
                      location: 'Branch Sanctuary',
                      category: category,
                      dateTime: selectedDate,
                      headcount: int.parse(headcountCtrl.text.trim()),
                    );

                    await ref.read(eventRepositoryProvider).saveEvent(branchId, event);
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Service attendance recorded successfully!'), backgroundColor: CmsTheme.success),
                      );
                    }
                  } catch (e) {
                    setDlgState(() => saving = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error recording attendance: $e'), backgroundColor: CmsTheme.danger),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, String branchId) {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String gender = 'male';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            backgroundColor: CmsTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Add Branch Member', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstNameCtrl,
                            decoration: const InputDecoration(labelText: 'First Name *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: lastNameCtrl,
                            decoration: const InputDecoration(labelText: 'Last Name *'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number *', hintText: '+234...'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: const InputDecoration(labelText: 'Gender *'),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                      ],
                      onChanged: (v) => setDlgState(() => gender = v ?? 'male'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: CmsTheme.textMuted)),
              ),
              CmsButton(
                label: saving ? 'Adding…' : 'Add Member',
                icon: Icons.check,
                onPressed: saving ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDlgState(() => saving = true);
                  try {
                    final member = MemberModel(
                      id: '',
                      firstName: firstNameCtrl.text.trim(),
                      lastName: lastNameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                      gender: gender,
                      joinDate: DateTime.now(),
                      memberStatus: 'active',
                    );
                    await ref.read(memberRepositoryProvider).saveMember(branchId, member);
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Branch member registered successfully!'), backgroundColor: CmsTheme.success),
                      );
                    }
                  } catch (e) {
                    setDlgState(() => saving = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding member: $e'), backgroundColor: CmsTheme.danger),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }


  // ── Tab 2: Financial Reports & Scoped Ledger ──────────────────────────────
  Widget _buildFinanceTab(String branchId, NumberFormat currencyFmt) {
    final incomeAsync = ref.watch(_branchIncomeProvider(branchId));
    final givingAsync = ref.watch(_branchGivingProvider(branchId));
    final expAsync = ref.watch(_branchExpendituresProvider(branchId));

    final totalIncome = (incomeAsync.valueOrNull ?? []).fold<double>(0, (s, x) => s + x.amount) +
        (givingAsync.valueOrNull ?? []).fold<double>(0, (s, x) => s + x.amount);
    final totalExp = (expAsync.valueOrNull ?? []).fold<double>(0, (s, x) => s + x.approvedAmount);
    final netPosition = totalIncome - totalExp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatCard('Branch Total Revenue', currencyFmt.format(totalIncome), 'Tithes, offerings & income', Icons.trending_up, CmsTheme.success),
            const SizedBox(width: 14),
            _buildStatCard('Approved Expenditures', currencyFmt.format(totalExp), 'Authorized branch expenses', Icons.receipt_long_outlined, CmsTheme.accent),
            const SizedBox(width: 14),
            _buildStatCard('Net Operating Position', '${netPosition >= 0 ? '+' : ''}${currencyFmt.format(netPosition)}', netPosition >= 0 ? 'Surplus' : 'Deficit', netPosition >= 0 ? Icons.check_circle_outline : Icons.warning_amber_rounded, netPosition >= 0 ? CmsTheme.success : CmsTheme.danger),
          ],
        ),
        const SizedBox(height: 20),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Revenue Transactions (Incomes & Giving)', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: [
                            ...(givingAsync.valueOrNull ?? []).map((g) => ListTile(
                              dense: true,
                              title: Text('Giving (${g.type.toUpperCase()})', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
                              subtitle: Text(DateFormat('MMM d, yyyy').format(g.date), style: const TextStyle(fontSize: 11, color: CmsTheme.textMuted)),
                              trailing: Text(currencyFmt.format(g.amount), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: CmsTheme.success)),
                            )),
                            ...(incomeAsync.valueOrNull ?? []).map((inc) => ListTile(
                              dense: true,
                              title: Text(inc.source, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
                              subtitle: Text('${inc.formType.toUpperCase()} · ${DateFormat('MMM d, yyyy').format(inc.date)}', style: const TextStyle(fontSize: 11, color: CmsTheme.textMuted)),
                              trailing: Text(currencyFmt.format(inc.amount), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: CmsTheme.success)),
                            )),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Approved Expenditure Ledger', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: [
                            ...(expAsync.valueOrNull ?? []).map((exp) => ListTile(
                              dense: true,
                              title: Text(exp.description, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
                              subtitle: Text('${exp.category} · ${DateFormat('MMM d, yyyy').format(exp.date)}', style: const TextStyle(fontSize: 11, color: CmsTheme.textMuted)),
                              trailing: Text(currencyFmt.format(exp.approvedAmount), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: CmsTheme.accent)),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 3: Fund & Budget Requests ─────────────────────────────────────────
  Widget _buildRequestsTab(String branchId, NumberFormat currencyFmt) {
    final expReqAsync = ref.watch(_branchExpRequestsProvider(branchId));
    final budgetReqAsync = ref.watch(_branchBudgetsProvider(branchId));
    final user = ref.watch(cmsUserProvider).valueOrNull;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expenditure Fund Requests
        Expanded(
          child: CmsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Branch Expenditure Requests', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                const SizedBox(height: 12),
                expReqAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: CmsTheme.danger))),
                  data: (requests) {
                    if (requests.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No expenditure requests submitted by this branch.', style: TextStyle(fontSize: 12, color: CmsTheme.textMuted))),
                      );
                    }
                    return Expanded(
                      child: ListView.separated(
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 10),
                        itemBuilder: (context, i) {
                          final r = requests[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CmsTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: CmsTheme.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.description, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                                      Text('Category: ${r.category} · Status: ${r.status.toUpperCase()}', style: const TextStyle(fontSize: 11, color: CmsTheme.textMuted)),
                                    ],
                                  ),
                                ),
                                Text(currencyFmt.format(r.amount), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: CmsTheme.warning)),
                                if (r.status == 'pending' && (user?.can(AppPermission.approveExpenditure) ?? false)) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: CmsTheme.success, size: 20),
                                    onPressed: () => ref.read(financeRepositoryProvider).approveExpenditure(branchId, r.id, user!.uid, user.displayName ?? user.email),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Budget Requests
        Expanded(
          child: CmsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Branch Fiscal Budget Requests', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                const SizedBox(height: 12),
                budgetReqAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: CmsTheme.danger))),
                  data: (budgets) {
                    if (budgets.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No budget requests submitted by this branch.', style: TextStyle(fontSize: 12, color: CmsTheme.textMuted))),
                      );
                    }
                    return Expanded(
                      child: ListView.separated(
                        itemCount: budgets.length,
                        separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 10),
                        itemBuilder: (context, i) {
                          final b = budgets[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CmsTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: CmsTheme.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.category, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                                      Text('Period: ${b.fiscalPeriod} · Status: ${b.status.toUpperCase()}', style: const TextStyle(fontSize: 11, color: CmsTheme.textMuted)),
                                    ],
                                  ),
                                ),
                                Text(currencyFmt.format(b.requestedAmount), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: CmsTheme.warning)),
                                if (b.status == 'pending' && (user?.can(AppPermission.approveBudget) ?? false)) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: CmsTheme.success, size: 20),
                                    onPressed: () => ref.read(financeRepositoryProvider).approveBudget(branchId, b.id, user!.uid, user.displayName ?? user.email),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String val, String sub, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: CmsTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CmsTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                  Text(val, style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
                  Text(sub, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CmsTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
          const Spacer(),
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
