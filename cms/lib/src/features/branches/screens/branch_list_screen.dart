import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/branches/models/branch_model.dart';

final _branchesStreamProvider = StreamProvider.autoDispose<List<BranchModel>>(
  (ref) => ref.watch(branchRepositoryProvider).watchBranches(),
);

class BranchListScreen extends ConsumerStatefulWidget {
  const BranchListScreen({super.key});

  @override
  ConsumerState<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends ConsumerState<BranchListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(_branchesStreamProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final canManage = user?.can(AppPermission.manageRoles) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Branch Churches & Regional Directory',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage church branches, provision pastor accounts, and view branch performance analytics.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: CmsTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (canManage)
                CmsButton(
                  label: 'Add Branch Church',
                  icon: Icons.add,
                  onPressed: () => _showAddBranchDialog(context),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Branch Roster Card ─────────────────────────────────────────────
          Expanded(
            child: CmsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter & Search Bar
                  Row(
                    children: [
                      SizedBox(
                        width: 280,
                        height: 38,
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search branch or pastor…',
                            hintStyle: const TextStyle(color: CmsTheme.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 16, color: CmsTheme.textMuted),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CmsTheme.border)),
                          ),
                        ),
                      ),
                      const Spacer(),
                      branchesAsync.when(
                        data: (branches) {
                          final count = branches.where((b) => b.id != 'default-branch' && !b.name.toLowerCase().contains('main branch')).length;
                          return Text(
                            '$count Registered Branches',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: CmsTheme.textMuted),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: branchesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: CmsTheme.danger))),
                      data: (branches) {
                        final subBranches = branches.where((b) => b.id != 'default-branch' && !b.name.toLowerCase().contains('main branch')).toList();
                        final filtered = subBranches.where((b) {
                          final q = _searchQuery.toLowerCase();
                          return b.name.toLowerCase().contains(q) ||
                              b.pastorInCharge.toLowerCase().contains(q) ||
                              b.address.toLowerCase().contains(q);
                        }).toList();


                        if (filtered.isEmpty) {
                          return const Center(
                            child: Text('No branch churches registered yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textMuted)),
                          );
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(color: CmsTheme.border, height: 16),
                          itemBuilder: (context, index) {
                            final b = filtered[index];
                            return _buildBranchRow(context, b, canManage);
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
    );
  }

  Widget _buildBranchRow(BuildContext context, BranchModel b, bool canManage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CmsTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CmsTheme.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_tree_outlined, color: CmsTheme.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      b.name,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: b.active ? CmsTheme.success.withValues(alpha: 0.1) : CmsTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        b.active ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: b.active ? CmsTheme.success : CmsTheme.danger),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: CmsTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      b.address.isEmpty ? 'No address specified' : b.address,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 13, color: CmsTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      b.pastorInCharge.isEmpty ? 'Unassigned' : b.pastorInCharge,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary),
                    ),
                  ],
                ),
                if (b.pastorEmail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    b.pastorEmail!,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created: ${DateFormat('MMM d, yyyy').format(b.createdAt)}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textMuted),
                ),
                if (b.phone.isNotEmpty)
                  Text(
                    'Phone: ${b.phone}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary),
                  ),
              ],
            ),
          ),
          CmsButton(
            label: 'View Branch Details →',
            compact: true,
            variant: CmsButtonVariant.secondary,
            onPressed: () => context.go('/branches/${b.id}'),
          ),
        ],
      ),
    );
  }

  void _showAddBranchDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pastorNameCtrl = TextEditingController();
    final pastorEmailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            backgroundColor: CmsTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Create Branch Church & Provision Pastor Account', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. Branch Church Metadata', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.accent)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Branch Name *', hintText: 'e.g. Grace Assembly Ikeja'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(labelText: 'Physical Address *', hintText: 'e.g. 12 Allen Avenue'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cityCtrl,
                              decoration: const InputDecoration(labelText: 'City', hintText: 'Ikeja'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: stateCtrl,
                              decoration: const InputDecoration(labelText: 'State', hintText: 'Lagos State'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Contact Phone', hintText: '+234...'),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('2. Pastor in Charge Credentials', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.accent)),
                          TextButton.icon(
                            icon: const Icon(Icons.key, size: 14, color: CmsTheme.accent),
                            label: const Text('Auto-Generate', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.accent)),
                            onPressed: () {
                              final branchPart = nameCtrl.text.trim().replaceAll(' ', '');
                              final prefix = branchPart.isNotEmpty ? branchPart.substring(0, branchPart.length > 5 ? 5 : branchPart.length) : 'Pass';
                              final suffix = (100 + (DateTime.now().millisecondsSinceEpoch % 899)).toString();
                              setDlgState(() {
                                passwordCtrl.text = '${prefix}@Pass$suffix';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: pastorNameCtrl,
                        decoration: const InputDecoration(labelText: 'Pastor Full Name *', hintText: 'Pastor John Doe'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: pastorEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Pastor Email Address *', hintText: 'pastor.ikeja@church.org'),
                        validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Initial Account Password *',
                          hintText: 'Click Auto-Generate or enter password',
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: CmsTheme.textMuted)),
              ),
              CmsButton(
                label: saving ? 'Creating…' : 'Create Branch & Account',
                icon: Icons.check,
                onPressed: saving ? null : () async {
                  if (passwordCtrl.text.trim().isEmpty) {
                    final branchPart = nameCtrl.text.trim().replaceAll(' ', '');
                    final prefix = branchPart.isNotEmpty ? branchPart.substring(0, branchPart.length > 5 ? 5 : branchPart.length) : 'Pass';
                    final suffix = (100 + (DateTime.now().millisecondsSinceEpoch % 899)).toString();
                    passwordCtrl.text = '${prefix}@Pass$suffix';
                  }

                  if (!formKey.currentState!.validate()) return;
                  setDlgState(() => saving = true);
                  try {
                    final bName = nameCtrl.text.trim();
                    final pName = pastorNameCtrl.text.trim();
                    final pEmail = pastorEmailCtrl.text.trim();
                    final pPass = passwordCtrl.text.trim();

                    final newBranch = BranchModel(
                      id: '',
                      name: bName,
                      address: addressCtrl.text.trim(),
                      pastorInCharge: pName,
                      phone: phoneCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      state: stateCtrl.text.trim(),
                      createdAt: DateTime.now(),
                    );

                    await ref.read(branchRepositoryProvider).createBranchWithPastor(
                      branch: newBranch,
                      pastorName: pName,
                      pastorEmail: pEmail,
                      password: pPass,
                    );

                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      _showCredentialsHandoverModal(context, bName, pName, pEmail, pPass);
                    }
                  } catch (e) {
                    setDlgState(() => saving = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating branch: $e'), backgroundColor: CmsTheme.danger),
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

  void _showCredentialsHandoverModal(BuildContext context, String branchName, String pastorName, String email, String password) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CmsTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: CmsTheme.success, size: 22),
            SizedBox(width: 8),
            Text('Branch & Pastor Account Provisioned!', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: CmsTheme.textPrimary)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share these credentials securely with the Branch Pastor in charge:', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CmsTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Church Branch: $branchName', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary)),
                    const SizedBox(height: 6),
                    Text('Pastor Name: $pastorName', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Text('Login Email: $email', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.accent)),
                    const SizedBox(height: 6),
                    Text('Initial Password: $password', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: CmsTheme.warning)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          CmsButton(
            label: 'Copy Credentials',
            icon: Icons.copy,
            variant: CmsButtonVariant.secondary,
            onPressed: () {
              final payload = 'Church Branch: $branchName\nPastor: $pastorName\nLogin URL: https://church-mobile-cms.web.app/login\nEmail: $email\nPassword: $password';
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Credentials copied to clipboard!'), backgroundColor: CmsTheme.success),
              );
            },
          ),
          CmsButton(
            label: 'Done',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}

