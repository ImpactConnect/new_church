import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/assets/models/asset_model.dart';
import 'package:intl/intl.dart';

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
  String _conditionFilter = 'all';
  bool _isSeeding = false;

  final _currencyFmt = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _seedData(String branchId) async {
    setState(() => _isSeeding = true);
    try {
      await ref.read(assetRepositoryProvider).seedSampleAssets(branchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Sample church inventory seeded successfully!'), backgroundColor: CmsTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seeding assets: $e'), backgroundColor: CmsTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final assetsAsync = ref.watch(_assetsProvider(branchId));

    final canManagePhysical = user?.can(AppPermission.manageAssetPhysical) ?? false;
    final canManageFinancial = user?.can(AppPermission.manageAssetFinancial) ?? false;
    final isLeadPastor = user?.roleId == AppRole.leadPastor;
    final canEdit = !isLeadPastor && (canManagePhysical || canManageFinancial || user?.roleId == AppRole.secretary || user?.roleId == AppRole.assetManager);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmsPageHeader(
            title: 'Assets & Inventory Register',
            subtitle: 'Track physical equipment, condition health reports, locations, and financial valuations',
            actions: [
              if (!canEdit) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: CmsTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CmsTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 16, color: CmsTheme.accent),
                      SizedBox(width: 6),
                      Text(
                        'View-Only (Lead Pastor Oversight)',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: CmsTheme.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (canEdit) ...[
                CmsButton(
                  label: 'Add Asset',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => _showAssetDialog(context, ref, branchId, null, user!),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // ── Executive Metric Summary Cards ─────────────────────────────────────
          assetsAsync.when(
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (assets) {
              final totalCount = assets.length;
              final totalCost = assets.fold<double>(0, (sum, a) => sum + a.purchaseCost);
              final totalValue = assets.fold<double>(0, (sum, a) => sum + a.currentBookValue);
              final excellentCount = assets.where((a) => a.condition == 'Excellent').length;
              final goodCount = assets.where((a) => a.condition == 'Good').length;
              final needsAttentionCount = assets.where((a) => a.condition == 'Fair' || a.condition == 'Poor' || a.condition == 'Under Maintenance').length;

              return Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'TOTAL REGISTERED ASSETS',
                      value: '$totalCount Items',
                      icon: Icons.inventory_2_outlined,
                      accentColor: CmsTheme.accent,
                      subtitle: 'Active church inventory',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'CURRENT INVENTORY VALUATION',
                      value: _currencyFmt.format(totalValue),
                      icon: Icons.account_balance_wallet_outlined,
                      accentColor: CmsTheme.accent,
                      subtitle: 'Original Cost: ${_currencyFmt.format(totalCost)}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'CONDITION HEALTH',
                      value: '$excellentCount Exc / $goodCount Good',
                      icon: Icons.health_and_safety_outlined,
                      accentColor: CmsTheme.success,
                      subtitle: needsAttentionCount > 0 ? '$needsAttentionCount item(s) need attention' : 'All assets in good health',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Search & Filter Toolbar ────────────────────────────────────────────
          Row(
            children: [
              CmsSearchField(
                controller: _searchCtrl,
                hint: 'Search assets by name, tag ID, location, or serial…',
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
              const SizedBox(width: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _categoryFilterChip('all', 'All Categories'),
                    const SizedBox(width: 6),
                    _categoryFilterChip('Electronics & Media', 'Electronics & Media'),
                    const SizedBox(width: 6),
                    _categoryFilterChip('Instruments & Sound', 'Instruments & Sound'),
                    const SizedBox(width: 6),
                    _categoryFilterChip('Furniture & Fixtures', 'Furniture & Fixtures'),
                    const SizedBox(width: 6),
                    _categoryFilterChip('Vehicles', 'Vehicles'),
                    const SizedBox(width: 6),
                    _categoryFilterChip('Office Equipment', 'Office Equipment'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Data Table ────────────────────────────────────────────────────────
          Expanded(
            child: CmsCard(
              padding: EdgeInsets.zero,
              child: assetsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading assets: $e', style: const TextStyle(color: CmsTheme.danger))),
                data: (assets) {
                  final filtered = assets.where((a) {
                    if (_categoryFilter != 'all' && a.category != _categoryFilter) return false;
                    if (_conditionFilter != 'all' && a.condition != _conditionFilter) return false;
                    if (_searchQuery.isNotEmpty) {
                      final matchName = a.name.toLowerCase().contains(_searchQuery);
                      final matchLoc = a.location.toLowerCase().contains(_searchQuery);
                      final matchTag = (a.tagId ?? '').toLowerCase().contains(_searchQuery);
                      final matchSerial = (a.serialNumber ?? '').toLowerCase().contains(_searchQuery);
                      return matchName || matchLoc || matchTag || matchSerial;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return CmsEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: assets.isEmpty ? 'No Assets Registered' : 'No Matching Assets Found',
                      subtitle: assets.isEmpty 
                          ? 'Click "Add Asset" to start tracking church inventory.'
                          : 'Try clearing your search query or category filters.',
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DataTable2(
                      columnSpacing: 16,
                      horizontalMargin: 20,
                      minWidth: 1050,
                      headingRowColor: WidgetStateProperty.all(CmsTheme.surfaceElevated),
                      dataRowColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) return CmsTheme.surfaceElevated;
                        return CmsTheme.surface;
                      }),
                      columns: const [
                        DataColumn2(label: Text('TAG / ID', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)), size: ColumnSize.S),
                        DataColumn2(label: Text('ASSET NAME', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)), size: ColumnSize.L),
                        DataColumn2(label: Text('CATEGORY', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)), size: ColumnSize.M),
                        DataColumn2(label: Text('LOCATION', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)), size: ColumnSize.M),
                        DataColumn2(label: Text('DEPARTMENT', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)), size: ColumnSize.M),
                        DataColumn2(label: Text('CONDITION', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)), fixedWidth: 150),
                        DataColumn2(label: Text('PURCHASE COST', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)), size: ColumnSize.M, numeric: true),
                        DataColumn2(label: Text('BOOK VALUE', style: TextStyle(color: CmsTheme.textSecondary, fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold)), size: ColumnSize.M, numeric: true),
                      ],
                      rows: filtered.map((asset) => DataRow2(
                        onTap: () => _showAssetDialog(context, ref, branchId, asset, user!),
                        cells: [
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: CmsTheme.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                asset.tagId ?? 'N/A',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: CmsTheme.accent),
                              ),
                            ),
                          ),
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asset.name,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: CmsTheme.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (asset.serialNumber != null && asset.serialNumber!.isNotEmpty)
                                  Text(
                                    'S/N: ${asset.serialNumber}',
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textMuted),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(Text(asset.category, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
                          DataCell(Text(asset.location, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
                          DataCell(Text(asset.assignedDepartmentId ?? '—', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textSecondary))),
                          DataCell(_conditionChip(asset.condition)),
                          DataCell(Text(_currencyFmt.format(asset.purchaseCost), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: CmsTheme.textPrimary))),
                          DataCell(Text(_currencyFmt.format(asset.currentBookValue), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: CmsTheme.accent))),
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

  Widget _categoryFilterChip(String value, String label) {
    final isSelected = _categoryFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: isSelected ? Colors.white : CmsTheme.textSecondary)),
      selected: isSelected,
      selectedColor: CmsTheme.accent,
      backgroundColor: CmsTheme.surfaceElevated,
      onSelected: (_) => setState(() => _categoryFilter = value),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: CmsTheme.textMuted, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: CmsTheme.textSecondary)),
              ],
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
      'Under Maintenance' => Colors.purple,
      _ => CmsTheme.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        condition,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
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
  late final TextEditingController _tagCtrl;
  late final TextEditingController _serialCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _deptCtrl;
  late final TextEditingController _vendorCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _valCtrl;
  late final TextEditingController _notesCtrl;

  String _category = 'Electronics & Media';
  String _condition = 'Good';
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _tagCtrl = TextEditingController(text: a?.tagId ?? '');
    _serialCtrl = TextEditingController(text: a?.serialNumber ?? '');
    _locCtrl = TextEditingController(text: a?.location ?? 'Main Auditorium');
    _deptCtrl = TextEditingController(text: a?.assignedDepartmentId ?? 'Media & Technical');
    _vendorCtrl = TextEditingController(text: a?.vendor ?? '');
    _costCtrl = TextEditingController(text: a?.purchaseCost.toString() ?? '0');
    _valCtrl = TextEditingController(text: a?.currentBookValue.toString() ?? '0');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');

    _category = a?.category ?? 'Electronics & Media';
    _condition = a?.condition ?? 'Good';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    _serialCtrl.dispose();
    _locCtrl.dispose();
    _deptCtrl.dispose();
    _vendorCtrl.dispose();
    _costCtrl.dispose();
    _valCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPhysical = widget.user.can(AppPermission.manageAssetPhysical);
    final canFinancial = widget.user.can(AppPermission.manageAssetFinancial);
    final isReadOnly = !canPhysical && !canFinancial;

    return AlertDialog(
      backgroundColor: CmsTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: CmsTheme.border),
      ),
      title: Row(
        children: [
          Icon(isReadOnly ? Icons.visibility_outlined : Icons.inventory_2_outlined, color: CmsTheme.accent),
          const SizedBox(width: 8),
          Text(
            widget.asset == null ? 'Add Asset to Inventory' : (isReadOnly ? 'Asset Details' : 'Edit Asset Record'),
            style: const TextStyle(fontFamily: 'Inter', color: CmsTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('ASSET NAME *'),
                TextFormField(
                  controller: _nameCtrl,
                  readOnly: isReadOnly,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'e.g. Behringer X32 Sound Console'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Asset name is required' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('TAG / ASSET ID'),
                          TextFormField(
                            controller: _tagCtrl,
                            readOnly: isReadOnly,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(hintText: 'e.g. AUD-SND-001'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('SERIAL NUMBER'),
                          TextFormField(
                            controller: _serialCtrl,
                            readOnly: isReadOnly,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(hintText: 'e.g. S/N-99821'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('CATEGORY'),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            dropdownColor: CmsTheme.surfaceElevated,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(),
                            items: const [
                              DropdownMenuItem(value: 'Electronics & Media', child: Text('Electronics & Media')),
                              DropdownMenuItem(value: 'Instruments & Sound', child: Text('Instruments & Sound')),
                              DropdownMenuItem(value: 'Furniture & Fixtures', child: Text('Furniture & Fixtures')),
                              DropdownMenuItem(value: 'Vehicles', child: Text('Vehicles')),
                              DropdownMenuItem(value: 'Office Equipment', child: Text('Office Equipment')),
                              DropdownMenuItem(value: 'Real Estate & Buildings', child: Text('Real Estate & Buildings')),
                            ],
                            onChanged: isReadOnly ? null : (v) => setState(() => _category = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('CONDITION STATUS'),
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
                              DropdownMenuItem(value: 'Under Maintenance', child: Text('Under Maintenance')),
                            ],
                            onChanged: isReadOnly ? null : (v) => setState(() => _condition = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('PHYSICAL LOCATION'),
                          TextFormField(
                            controller: _locCtrl,
                            readOnly: isReadOnly,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(hintText: 'e.g. Main Auditorium Stage'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('ASSIGNED DEPARTMENT'),
                          TextFormField(
                            controller: _deptCtrl,
                            readOnly: isReadOnly,
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(hintText: 'e.g. Media & Technical'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildLabel('VENDOR / SUPPLIER'),
                TextFormField(
                  controller: _vendorCtrl,
                  readOnly: isReadOnly,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'e.g. ProSound Electronics Ikeja'),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('PURCHASE COST (₦)'),
                          TextFormField(
                            controller: _costCtrl,
                            readOnly: isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(hintText: '0.00'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('CURRENT BOOK VALUE (₦)'),
                          TextFormField(
                            controller: _valCtrl,
                            readOnly: isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                            decoration: const InputDecoration(hintText: '0.00'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildLabel('NOTES & MAINTENANCE HISTORY'),
                TextFormField(
                  controller: _notesCtrl,
                  readOnly: isReadOnly,
                  maxLines: 2,
                  style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
                  decoration: const InputDecoration(hintText: 'Enter servicing schedule or special instructions…'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!isReadOnly && widget.asset != null) ...[
          CmsButton(
            label: 'Delete Asset',
            variant: CmsButtonVariant.danger,
            compact: true,
            loading: _deleting,
            onPressed: () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Delete Asset Record',
                message: 'Remove "${widget.asset!.name}" from inventory entirely?',
                confirmLabel: 'Delete',
                danger: true,
              );
              if (ok) {
                setState(() => _deleting = true);
                try {
                  await widget.ref.read(assetRepositoryProvider).deleteAsset(widget.branchId, widget.asset!.id);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting asset: $e'), backgroundColor: CmsTheme.danger),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _deleting = false);
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isReadOnly ? 'Close' : 'Cancel', style: const TextStyle(color: CmsTheme.textSecondary)),
        ),
        if (!isReadOnly)
          CmsButton(
            label: widget.asset == null ? 'Save New Asset' : 'Save Changes',
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
                  tagId: _tagCtrl.text.trim().isNotEmpty ? _tagCtrl.text.trim() : null,
                  serialNumber: _serialCtrl.text.trim().isNotEmpty ? _serialCtrl.text.trim() : null,
                  vendor: _vendorCtrl.text.trim().isNotEmpty ? _vendorCtrl.text.trim() : null,
                  assignedDepartmentId: _deptCtrl.text.trim().isNotEmpty ? _deptCtrl.text.trim() : null,
                  purchaseCost: double.tryParse(_costCtrl.text.trim()) ?? 0.0,
                  currentBookValue: double.tryParse(_valCtrl.text.trim()) ?? 0.0,
                  notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
                  purchaseDate: widget.asset?.purchaseDate ?? DateTime.now(),
                  lastMaintenanceDate: DateTime.now(),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: CmsTheme.textMuted, letterSpacing: 0.5),
      ),
    );
  }
}

