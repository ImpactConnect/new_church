import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/correspondence/models/correspondence_model.dart';

final _correspondenceProvider = StreamProvider.autoDispose.family<List<CorrespondenceModel>, String>(
  (ref, branchId) => ref.watch(correspondenceRepositoryProvider).watchCorrespondence(branchId),
);

class CorrespondenceScreen extends ConsumerStatefulWidget {
  const CorrespondenceScreen({super.key});

  @override
  ConsumerState<CorrespondenceScreen> createState() => _CorrespondenceScreenState();
}

class _CorrespondenceScreenState extends ConsumerState<CorrespondenceScreen> {
  String _typeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final itemsAsync = ref.watch(_correspondenceProvider(branchId));

    final canLog = user?.can(AppPermission.logCorrespondence) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Correspondence',
            subtitle: 'Log physical and official church mail',
            actions: [
              if (canLog)
                CmsButton(
                  label: 'Log Mail',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showLogDialog(context, ref, branchId, user!),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ChoiceChip(
                label: const Text('All Mail', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _typeFilter == 'all',
                onSelected: (_) => setState(() => _typeFilter = 'all'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Incoming', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _typeFilter == 'incoming',
                onSelected: (_) => setState(() => _typeFilter = 'incoming'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Outgoing', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _typeFilter == 'outgoing',
                onSelected: (_) => setState(() => _typeFilter = 'outgoing'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CmsCard(
              padding: EdgeInsets.zero,
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                data: (items) {
                  final filtered = items.where((i) => _typeFilter == 'all' || i.type == _typeFilter).toList();
                  if (filtered.isEmpty) {
                    return CmsEmptyState(
                      icon: Icons.mail_outline,
                      title: 'No correspondence logged',
                      subtitle: 'Log incoming letters or outgoing mail.',
                      action: canLog
                          ? CmsButton(
                              label: 'Log Mail',
                              icon: Icons.add,
                              onPressed: () => _showLogDialog(context, ref, branchId, user!),
                            )
                          : null,
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DataTable2(
                      columnSpacing: 16,
                      horizontalMargin: 20,
                      minWidth: 700,
                      headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                      dataRowColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) return CmsTheme.surfaceElevated;
                        return CmsTheme.surface;
                      }),
                      columns: const [
                        DataColumn2(label: Text('Type', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                        DataColumn2(label: Text('Subject', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.L),
                        DataColumn2(label: Text('Sender / Recipient', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                        DataColumn2(label: Text('Date', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                        DataColumn2(label: Text('Logged By', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                      ],
                      rows: filtered.map((item) => _buildRow(item)).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow2 _buildRow(CorrespondenceModel item) {
    final isIncoming = item.type == 'incoming';
    return DataRow2(
      cells: [
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (isIncoming ? CmsTheme.info : CmsTheme.accent).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isIncoming ? 'IN' : 'OUT',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isIncoming ? CmsTheme.info : CmsTheme.accent,
            ),
          ),
        )),
        DataCell(Text(item.subject, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary))),
        DataCell(Text(item.senderOrRecipient, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary))),
        DataCell(Text('${item.date.day}/${item.date.month}/${item.date.year}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted))),
        DataCell(Text(item.loggedByName, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted))),
      ],
    );
  }

  void _showLogDialog(BuildContext context, WidgetRef ref, String branchId, dynamic user) {
    showDialog(
      context: context,
      builder: (_) => _CorrespondenceFormDialog(branchId: branchId, ref: ref, user: user),
    );
  }
}

class _CorrespondenceFormDialog extends StatefulWidget {
  const _CorrespondenceFormDialog({required this.branchId, required this.ref, required this.user});
  final String branchId;
  final WidgetRef ref;
  final dynamic user;

  @override
  State<_CorrespondenceFormDialog> createState() => _CorrespondenceFormDialogState();
}

class _CorrespondenceFormDialogState extends State<_CorrespondenceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjCtrl = TextEditingController();
  final _partyCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'incoming';
  bool _saving = false;

  @override
  void dispose() {
    _subjCtrl.dispose();
    _partyCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
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
      title: const Text('Log Correspondence', style: TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      dropdownColor: CmsTheme.surfaceElevated,
                      style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'incoming', child: Text('Incoming Mail')),
                        DropdownMenuItem(value: 'outgoing', child: Text('Outgoing Mail')),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _refCtrl,
                      style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                      decoration: const InputDecoration(labelText: 'Ref Number (optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _subjCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(labelText: 'Subject / Description'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _partyCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: InputDecoration(labelText: _type == 'incoming' ? 'Sender Name/Org' : 'Recipient Name/Org'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(labelText: 'Notes / Summary'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: 'Save Entry',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final model = CorrespondenceModel(
                id: '',
                type: _type,
                subject: _subjCtrl.text.trim(),
                senderOrRecipient: _partyCtrl.text.trim(),
                date: DateTime.now(),
                loggedBy: widget.user.uid,
                loggedByName: widget.user.displayName ?? widget.user.email,
                notes: _notesCtrl.text.trim(),
                referenceNumber: _refCtrl.text.trim().isNotEmpty ? _refCtrl.text.trim() : null,
              );
              await widget.ref.read(correspondenceRepositoryProvider).logCorrespondence(widget.branchId, model);
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
