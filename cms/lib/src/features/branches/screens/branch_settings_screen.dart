import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/branches/models/branch_model.dart';

final _currentBranchProvider = StreamProvider.autoDispose.family<BranchModel?, String>(
  (ref, branchId) => ref.watch(branchRepositoryProvider).watchBranches().map(
    (branches) => branches.firstWhere((b) => b.id == branchId, orElse: () => BranchModel(
      id: branchId,
      name: 'Main Branch',
      address: '',
      pastorInCharge: '',
      phone: '',
      createdAt: DateTime.now(),
    )),
  ),
);

class BranchSettingsScreen extends ConsumerStatefulWidget {
  const BranchSettingsScreen({super.key});

  @override
  ConsumerState<BranchSettingsScreen> createState() => _BranchSettingsScreenState();
}

class _BranchSettingsScreenState extends ConsumerState<BranchSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _pastorCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _pastorCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  void _populate(BranchModel b) {
    if (_initialized) return;
    _nameCtrl.text = b.name;
    _addressCtrl.text = b.address;
    _pastorCtrl.text = b.pastorInCharge;
    _phoneCtrl.text = b.phone;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _pastorCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String branchId, BranchModel current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = current.copyWith(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        pastorInCharge: _pastorCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      await ref.read(branchRepositoryProvider).saveBranch(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Branch settings saved.'), backgroundColor: CmsTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final branchAsync = ref.watch(_currentBranchProvider(branchId));
    final canEdit = user?.can(AppPermission.manageRoles) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CmsPageHeader(
              title: 'Branch Settings',
              subtitle: 'Configure branch details and contact information',
            ),
            const SizedBox(height: 28),
            branchAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: CmsTheme.danger)),
              data: (branch) {
                if (branch != null) _populate(branch);
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: CmsCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field('Branch Name', _nameCtrl, enabled: canEdit, required: true),
                          const SizedBox(height: 16),
                          _field('Pastor in Charge', _pastorCtrl, enabled: canEdit),
                          const SizedBox(height: 16),
                          _field('Phone Number', _phoneCtrl, enabled: canEdit, keyboard: TextInputType.phone),
                          const SizedBox(height: 16),
                          _field('Address', _addressCtrl, enabled: canEdit, maxLines: 3),
                          const SizedBox(height: 24),
                          if (canEdit)
                            Align(
                              alignment: Alignment.centerRight,
                              child: CmsButton(
                                label: 'Save Changes',
                                icon: Icons.check,
                                loading: _saving,
                                onPressed: () => _save(branchId, branch!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool enabled = true,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboard,
          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}
