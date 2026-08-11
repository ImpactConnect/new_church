import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/assets/models/asset_model.dart';

final _assetsProvider = StreamProvider.autoDispose.family<List<AssetModel>, String>(
  (ref, branchId) => ref.watch(assetRepositoryProvider).watchAssets(branchId),
);

class AssetListScreen extends ConsumerStatefulWidget {
  const AssetListScreen({super.key});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final assetsAsync = ref.watch(_assetsProvider(branchId));

    final canManagePhysical = user?.can(AppPermission.manageAssetPhysical) ?? false;
    final canManageFinancial = user?.can(AppPermission.manageAssetFinancial) ?? false;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Assets & Inventory',
            subtitle: 'Track physical equipment, furniture, and financial asset valuations',
            actions: [
              if (canManagePhysical || canManageFinancial)
                CmsButton(
                  label: 'Add Asset',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showAssetDialog(context, ref, branchId, null, user!),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CmsSearchField(
                controller: _searchCtrl,
                hint: 'Search assets by name or location…',
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('All Categories', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _categoryFilter == 'all',
                onSelected: (_) => setState(() => _categoryFilter = 'all'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Electronics', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _categoryFilter == 'Electronics',
                onSelected: (_) => setState(() => _categoryFilter = 'Electronics'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Furniture', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _categoryFilter == 'Furniture',
                onSelected: (_) => setState(() => _categoryFilter = 'Furniture'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Instruments', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                selected: _categoryFilter == 'Instruments',
                onSelected: (_) => setState(() => _categoryFilter = 'Instruments'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CmsCard(
              padding: EdgeInsets.zero,
              child: assetsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: CmsTheme.danger))),
                data: (assets) {
                  final filtered = assets.where((a) {
                    if (_categoryFilter != 'all' && a.category != _categoryFilter) return false;
                    if (_searchQuery.isNotEmpty) {
                      return a.name.toLowerCase().contains(_searchQuery) ||
                          a.location.toLowerCase().contains(_searchQuery);
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return CmsEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No assets found',
                      subtitle: 'Add physical church equipment to inventory.',
                      action: (canManagePhysical || canManageFinancial)
                          ? CmsButton(
                              label: 'Add Asset',
                              icon: Icons.add,
                              onPressed: () => _showAssetDialog(context, ref, branchId, null, user!),
                            )
                          : null,
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DataTable2(
                      columnSpacing: 16,
                      horizontalMargin: 20,
                      minWidth: 800,
                      headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                      dataRowColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) return CmsTheme.surfaceElevated;
                        return CmsTheme.surface;
                      }),
                      columns: [
                        const DataColumn2(label: Text('Asset Name', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.L),
                        const DataColumn2(label: Text('Category', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                        const DataColumn2(label: Text('Location', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M),
                        const DataColumn2(label: Text('Condition', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.S),
                        if (canManageFinancial)
                          const DataColumn2(label: Text('Purchase Cost (₦)', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M, numeric: true),
                        if (canManageFinancial)
                          const DataColumn2(label: Text('Book Value (₦)', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)), size: ColumnSize.M, numeric: true),
                        const DataColumn2(label: SizedBox.shrink(), size: ColumnSize.S, fixedWidth: 48),
                      ],
                      rows: filtered.map((asset) => DataRow2(
                        cells: [
                          DataCell(Text(asset.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: CmsTheme.textPrimary))),
                          DataCell(Text(asset.category, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
                          DataCell(Text(asset.location, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
                          DataCell(_conditionChip(asset.condition)),
                          if (canManageFinancial)
                            DataCell(Text('₦${asset.purchaseCost.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textPrimary))),
                          if (canManageFinancial)
                            DataCell(Text('₦${asset.currentBookValue.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.accent))),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16, color: CmsTheme.textSecondary),
                            onPressed: () => _showAssetDialog(context, ref, branchId, asset, user!),
                          )),
                        ],
                      )).toList(),
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

  Widget _conditionChip(String condition) {
    final color = switch (condition) {
      'Excellent' => CmsTheme.success,
      'Good' => CmsTheme.info,
      'Fair' => CmsTheme.warning,
      'Poor' => CmsTheme.danger,
      _ => CmsTheme.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(condition, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _showAssetDialog(BuildContext context, WidgetRef ref, String branchId, AssetModel? asset, dynamic user) {
    showDialog(
      context: context,
      builder: (_) => _AssetFormDialog(branchId: branchId, ref: ref, asset: asset, user: user),
    );
  }
}

class _AssetFormDialog extends StatefulWidget {
  const _AssetFormDialog({required this.branchId, required this.ref, this.asset, required this.user});
  final String branchId;
  final WidgetRef ref;
  final AssetModel? asset;
  final dynamic user;

  @override
  State<_AssetFormDialog> createState() => _AssetFormDialogState();
}

class _AssetFormDialogState extends State<_AssetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _valCtrl;
  String _category = 'Furniture';
  String _condition = 'Good';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _locCtrl = TextEditingController(text: a?.location ?? 'Main Auditorium');
    _costCtrl = TextEditingController(text: a?.purchaseCost.toString() ?? '0');
    _valCtrl = TextEditingController(text: a?.currentBookValue.toString() ?? '0');
    _category = a?.category ?? 'Furniture';
    _condition = a?.condition ?? 'Good';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _costCtrl.dispose();
    _valCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canFinancial = widget.user.can(AppPermission.manageAssetFinancial);

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: Text(
        widget.asset == null ? 'Add Asset' : 'Edit Asset',
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
              const Text('Asset Name', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
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
                          items: const [
                            DropdownMenuItem(value: 'Furniture', child: Text('Furniture')),
                            DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                            DropdownMenuItem(value: 'Instruments', child: Text('Instruments')),
                            DropdownMenuItem(value: 'Vehicles', child: Text('Vehicles')),
                            DropdownMenuItem(value: 'Real Estate', child: Text('Real Estate')),
                          ],
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
                        const Text('Condition', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _condition,
                          dropdownColor: CmsTheme.surfaceElevated,
                          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                          decoration: const InputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'Excellent', child: Text('Excellent')),
                            DropdownMenuItem(value: 'Good', child: Text('Good')),
                            DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                            DropdownMenuItem(value: 'Poor', child: Text('Poor')),
                          ],
                          onChanged: (v) => setState(() => _condition = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Physical Location', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locCtrl,
                style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                decoration: const InputDecoration(),
              ),
              if (canFinancial) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Purchase Cost (₦)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Book Value (₦)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: CmsTheme.textSecondary)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _valCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CmsTheme.textSecondary))),
        CmsButton(
          label: 'Save Asset',
          compact: true,
          loading: _saving,
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _saving = true);
            try {
              final model = AssetModel(
                id: widget.asset?.id ?? '',
                name: _nameCtrl.text.trim(),
                category: _category,
                condition: _condition,
                location: _locCtrl.text.trim(),
                purchaseCost: double.tryParse(_costCtrl.text.trim()) ?? 0.0,
                currentBookValue: double.tryParse(_valCtrl.text.trim()) ?? 0.0,
              );
              await widget.ref.read(assetRepositoryProvider).saveAsset(widget.branchId, model);
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
