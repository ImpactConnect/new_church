import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/branches/models/remittance_model.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _remittancesProvider = StreamProvider.autoDispose.family<List<RemittanceModel>, String>(
  (ref, branchId) {
    final db = ref.watch(firestoreProvider);
    return db
        .collection('remittances')
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => RemittanceModel.fromFirestore(d.data(), d.id)).toList());
  },
);

// ── Screen ────────────────────────────────────────────────────────────────────

class RemittanceScreen extends ConsumerStatefulWidget {
  const RemittanceScreen({super.key});

  @override
  ConsumerState<RemittanceScreen> createState() => _RemittanceScreenState();
}

class _RemittanceScreenState extends ConsumerState<RemittanceScreen> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final remittancesAsync = ref.watch(_remittancesProvider(branchId));

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Income Remittance',
            subtitle: 'Submit branch income to Head Church finance department',
            actions: [
              CmsButton(
                label: 'Submit Remittance',
                icon: Icons.send_outlined,
                compact: true,
                onPressed: () => _showSubmitDialog(context, ref, branchId, user),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary metrics
          remittancesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) {
              final total = items.fold<double>(0, (s, r) => s + r.amount);
              final pending = items.where((r) => r.status == 'pending').length;
              final acknowledged = items.where((r) => r.status == 'acknowledged').length;
              return Row(
                children: [
                  _metricCard('Total Remitted', '₦${total.toStringAsFixed(0)}', CmsTheme.success, Icons.paid_outlined),
                  const SizedBox(width: 16),
                  _metricCard('Pending', '$pending', CmsTheme.warning, Icons.hourglass_empty_outlined),
                  const SizedBox(width: 16),
                  _metricCard('Acknowledged', '$acknowledged', CmsTheme.info, Icons.check_circle_outline),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Status filter chips
          Row(
            children: [
              for (final (label, value) in [('All', 'all'), ('Pending', 'pending'), ('Acknowledged', 'acknowledged'), ('Queried', 'queried')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                    selected: _statusFilter == value,
                    onSelected: (_) => setState(() => _statusFilter = value),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: remittancesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
              data: (items) {
                final filtered = _statusFilter == 'all' ? items : items.where((r) => r.status == _statusFilter).toList();
                if (filtered.isEmpty) {
                  return CmsEmptyState(
                    icon: Icons.paid_outlined,
                    title: 'No remittances yet',
                    subtitle: 'Submit your branch income remittance to the Head Church finance department.',
                    action: CmsButton(
                      label: 'Submit Remittance',
                      icon: Icons.send_outlined,
                      onPressed: () => _showSubmitDialog(context, ref, branchId, user),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _RemittanceCard(item: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                  Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSubmitDialog(BuildContext context, WidgetRef ref, String branchId, dynamic user) async {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String paymentMethod = 'bank_transfer';
    DateTime remittanceDate = DateTime.now();
    String period = '${_monthName(DateTime.now().month)} ${DateTime.now().year}';
    bool saving = false;

    // Get branch name
    final branchDoc = await ref.read(branchRepositoryProvider).getBranch(branchId);
    final branchName = branchDoc?.name ?? 'Branch';

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: CmsTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Submit Income Remittance', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Amount (₦)', amountCtrl, keyboardType: TextInputType.number),
                const SizedBox(height: 14),
                _dialogField('Period (e.g. August 2026)', TextEditingController(text: period)
                  ..addListener(() => period = period), initialValue: period,
                  onChanged: (v) => period = v),
                const SizedBox(height: 14),
                _dialogField('Reference Number (optional)', refCtrl),
                const SizedBox(height: 14),
                // Payment method
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: CmsTheme.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: CmsTheme.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Method', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final (label, val) in [('Bank Transfer', 'bank_transfer'), ('Cash', 'cash'), ('Cheque', 'cheque')])
                            ChoiceChip(
                              label: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                              selected: paymentMethod == val,
                              onSelected: (_) => setS(() => paymentMethod = val),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _dialogField('Description / Notes (optional)', descCtrl, maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: CmsTheme.accent),
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                        return;
                      }
                      setS(() => saving = true);
                      try {
                        final remittance = RemittanceModel(
                          id: '',
                          branchId: branchId,
                          branchName: branchName,
                          amount: amount,
                          currency: 'NGN',
                          remittanceDate: remittanceDate,
                          submittedBy: user?.uid ?? '',
                          submittedByName: user?.displayName ?? user?.email ?? '',
                          period: period,
                          status: 'pending',
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          paymentMethod: paymentMethod,
                          referenceNumber: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        await ref.read(firestoreProvider).collection('remittances').add(remittance.toFirestore());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Remittance submitted to Head Church Finance'), backgroundColor: CmsTheme.success),
                          );
                        }
                      } catch (e) {
                        setS(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger));
                        }
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

// ── Remittance Card ────────────────────────────────────────────────────────────

class _RemittanceCard extends StatelessWidget {
  const _RemittanceCard({required this.item});
  final RemittanceModel item;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      'acknowledged' => CmsTheme.success,
      'queried'      => CmsTheme.warning,
      _              => CmsTheme.accent,
    };
    final statusLabel = switch (item.status) {
      'acknowledged' => 'Acknowledged',
      'queried'      => 'Queried',
      _              => 'Pending',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.paid_outlined, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('₦${item.amount.toStringAsFixed(0)}  •  ${item.period}',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(statusLabel, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.paymentMethod?.replaceAll('_', ' ').toUpperCase() ?? ''}${item.referenceNumber != null ? '  •  Ref: ${item.referenceNumber}' : ''}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
                ),
                if (item.queryNote != null) ...[
                  const SizedBox(height: 4),
                  Text('⚠ ${item.queryNote}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.warning)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _dialogField(
  String label,
  TextEditingController ctrl, {
  TextInputType? keyboardType,
  int maxLines = 1,
  String? initialValue,
  void Function(String)? onChanged,
}) {
  return TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    maxLines: maxLines,
    onChanged: onChanged,
    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
      filled: true,
      fillColor: CmsTheme.bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CmsTheme.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CmsTheme.border)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}
