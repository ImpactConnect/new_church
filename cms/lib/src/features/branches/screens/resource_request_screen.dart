import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/branches/models/resource_request_model.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _resourceRequestsProvider = StreamProvider.autoDispose.family<List<ResourceRequestModel>, String>(
  (ref, branchId) {
    final db = ref.watch(firestoreProvider);
    return db
        .collection('resourceRequests')
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ResourceRequestModel.fromFirestore(d.data(), d.id)).toList());
  },
);

// ── Screen ────────────────────────────────────────────────────────────────────

class ResourceRequestScreen extends ConsumerStatefulWidget {
  const ResourceRequestScreen({super.key});

  @override
  ConsumerState<ResourceRequestScreen> createState() => _ResourceRequestScreenState();
}

class _ResourceRequestScreenState extends ConsumerState<ResourceRequestScreen> {
  String _statusFilter = 'all';

  static const _categories = [
    ('Equipment', 'equipment', Icons.settings_outlined),
    ('Materials', 'materials', Icons.inventory_2_outlined),
    ('Vehicle', 'vehicle', Icons.directions_car_outlined),
    ('Furniture', 'furniture', Icons.chair_outlined),
    ('Other', 'other', Icons.more_horiz_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final requestsAsync = ref.watch(_resourceRequestsProvider(branchId));

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Resource Requests',
            subtitle: 'Request equipment, materials, or resources from Head Church',
            actions: [
              CmsButton(
                label: 'New Request',
                icon: Icons.add_circle_outline,
                compact: true,
                onPressed: () => _showRequestDialog(context, ref, branchId, user),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (label, value) in [('All', 'all'), ('Pending', 'pending'), ('Approved', 'approved'), ('Rejected', 'rejected'), ('Fulfilled', 'fulfilled')])
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
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
              data: (items) {
                final filtered = _statusFilter == 'all' ? items : items.where((r) => r.status == _statusFilter).toList();
                if (filtered.isEmpty) {
                  return CmsEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No resource requests',
                    subtitle: 'Submit a request for equipment, materials, or vehicles from Head Church.',
                    action: CmsButton(
                      label: 'New Request',
                      icon: Icons.add_circle_outline,
                      onPressed: () => _showRequestDialog(context, ref, branchId, user),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ResourceRequestCard(item: filtered[i], categories: _categories),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRequestDialog(BuildContext context, WidgetRef ref, String branchId, dynamic user) async {
    final itemCtrl = TextEditingController();
    final justCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    String category = 'equipment';
    String urgency = 'medium';
    int quantity = 1;
    bool saving = false;

    final branchDoc = await ref.read(branchRepositoryProvider).getBranch(branchId);
    final branchName = branchDoc?.name ?? 'Branch';

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: CmsTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Resource Request', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('Item Description *', itemCtrl),
                  const SizedBox(height: 14),

                  // Category
                  const Text('Category', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (label, val, _) in _categories)
                        ChoiceChip(
                          label: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                          selected: category == val,
                          onSelected: (_) => setS(() => category = val),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quantity
                  Row(
                    children: [
                      const Text('Quantity:', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setS(() { if (quantity > 1) quantity--; }),
                      ),
                      Text('$quantity', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setS(() => quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Urgency
                  const Text('Urgency', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (label, val) in [('Low', 'low'), ('Medium', 'medium'), ('High', 'high')])
                        ChoiceChip(
                          label: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                          selected: urgency == val,
                          selectedColor: val == 'high' ? CmsTheme.danger.withValues(alpha: 0.2)
                              : val == 'medium' ? CmsTheme.warning.withValues(alpha: 0.2)
                              : CmsTheme.success.withValues(alpha: 0.2),
                          onSelected: (_) => setS(() => urgency = val),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _field('Estimated Cost ₦ (optional)', costCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  _field('Justification / Reason *', justCtrl, maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: CmsTheme.accent),
              onPressed: saving
                  ? null
                  : () async {
                      if (itemCtrl.text.trim().isEmpty || justCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill in all required fields')));
                        return;
                      }
                      setS(() => saving = true);
                      try {
                        final req = ResourceRequestModel(
                          id: '',
                          branchId: branchId,
                          branchName: branchName,
                          requestedBy: user?.uid ?? '',
                          requestedByName: user?.displayName ?? user?.email ?? '',
                          itemDescription: itemCtrl.text.trim(),
                          category: category,
                          quantity: quantity,
                          urgency: urgency,
                          status: 'pending',
                          estimatedCost: double.tryParse(costCtrl.text.trim()),
                          justification: justCtrl.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        await ref.read(firestoreProvider).collection('resourceRequests').add(req.toFirestore());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Resource request submitted to Head Church'), backgroundColor: CmsTheme.success),
                          );
                        }
                      } catch (e) {
                        setS(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger));
                        }
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request Card ──────────────────────────────────────────────────────────────

class _ResourceRequestCard extends StatelessWidget {
  const _ResourceRequestCard({required this.item, required this.categories});
  final ResourceRequestModel item;
  final List<(String, String, IconData)> categories;

  @override
  Widget build(BuildContext context) {
    final (_, __, catIcon) = categories.firstWhere((c) => c.$2 == item.category, orElse: () => ('Other', 'other', Icons.more_horiz_outlined));
    final statusColor = switch (item.status) {
      'approved'  => CmsTheme.success,
      'rejected'  => CmsTheme.danger,
      'fulfilled' => CmsTheme.info,
      _           => CmsTheme.warning,
    };
    final urgencyColor = switch (item.urgency) {
      'high'   => CmsTheme.danger,
      'medium' => CmsTheme.warning,
      _        => CmsTheme.success,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(catIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.itemDescription,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(item.status.toUpperCase(), style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip('Qty: ${item.quantity}', CmsTheme.textSecondary),
                    _chip(item.category.toUpperCase(), CmsTheme.info),
                    _chip(item.urgency.toUpperCase(), urgencyColor),
                    if (item.estimatedCost != null) _chip('~₦${item.estimatedCost!.toStringAsFixed(0)}', CmsTheme.textSecondary),
                  ],
                ),
                if (item.justification != null) ...[
                  const SizedBox(height: 4),
                  Text(item.justification!, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (item.responseNote != null) ...[
                  const SizedBox(height: 4),
                  Text('Response: ${item.responseNote}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.info)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      );
}

Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
  return TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    maxLines: maxLines,
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
