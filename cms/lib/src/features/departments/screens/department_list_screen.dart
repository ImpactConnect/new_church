import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/departments/models/department_model.dart';

final _departmentsProvider = StreamProvider.autoDispose.family<List<DepartmentModel>, String>(
  (ref, branchId) => ref.watch(departmentRepositoryProvider).watchDepartments(branchId),
);

class DepartmentListScreen extends ConsumerWidget {
  const DepartmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final deptsAsync = ref.watch(_departmentsProvider(branchId));
    final canManage = user?.can(AppPermission.manageDepartments) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Departments & Units',
            subtitle: 'Manage ministry groups within this branch',
            actions: [
              if (canManage)
                CmsButton(
                  label: 'New Department',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showForm(context, ref, branchId, null),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: deptsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
              data: (depts) {
                if (depts.isEmpty) {
                  return CmsEmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No departments yet',
                    subtitle: 'Create your first ministry department.',
                    action: canManage
                        ? CmsButton(
                            label: 'New Department',
                            icon: Icons.add,
                            onPressed: () => _showForm(context, ref, branchId, null),
                          )
                        : null,
                  );
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: depts.length,
                  itemBuilder: (_, i) => _DepartmentCard(
                    dept: depts[i],
                    canManage: canManage,
                    onEdit: () => _showForm(context, ref, branchId, depts[i]),
                    onDelete: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: 'Delete Department',
                        message: 'Delete "${depts[i].name}"? This cannot be undone.',
                        confirmLabel: 'Delete',
                        danger: true,
                      );
                      if (ok) {
                        await ref.read(departmentRepositoryProvider).deleteDepartment(branchId, depts[i].id);
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

  void _showForm(BuildContext ctx, WidgetRef ref, String branchId, DepartmentModel? dept) {
    showDialog(
      context: ctx,
      builder: (_) => _DepartmentFormDialog(branchId: branchId, dept: dept, ref: ref),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.dept,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });
  final DepartmentModel dept;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CmsTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_outlined, size: 18, color: CmsTheme.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CmsTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dept.departmentType,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
                    ),
                  ],
                ),
              ),
              if (canManage)
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
          ),
          const Spacer(),
          Text(
            '${dept.memberIds.length} member${dept.memberIds.length == 1 ? '' : 's'}',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DepartmentFormDialog extends StatefulWidget {
  const _DepartmentFormDialog({
    required this.branchId,
    required this.ref,
    this.dept,
  });
  final String branchId;
  final WidgetRef ref;
  final DepartmentModel? dept;

  @override
  State<_DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<_DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String _type = 'General';
  bool _saving = false;

  static const _types = ['Choir', 'Ushering', 'Welfare', 'Youth', 'Children', 'Prayer', 'Media', 'Protocol', 'General'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.dept?.name ?? '');
    _type = widget.dept?.departmentType ?? 'General';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
        widget.dept == null ? 'New Department' : 'Edit Department',
        style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Name', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Type', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: CmsTheme.surfaceElevated,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v!),
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
              final dept = DepartmentModel(
                id: widget.dept?.id ?? '',
                name: _nameCtrl.text.trim(),
                departmentType: _type,
                headMemberId: widget.dept?.headMemberId,
                memberIds: widget.dept?.memberIds ?? [],
              );
              await widget.ref.read(departmentRepositoryProvider).saveDepartment(widget.branchId, dept);
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
