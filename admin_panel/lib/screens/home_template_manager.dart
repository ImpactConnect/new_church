import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// ─── Model (mirrors the app's HomeTileModel) ─────────────────────────────────
enum TileLayoutStyle {
  standard,
  splitLeft,
  splitRight;

  String get value => name;

  String get label {
    switch (this) {
      case TileLayoutStyle.splitLeft:
        return 'Text Left / Image Right';
      case TileLayoutStyle.splitRight:
        return 'Image Left / Text Right';
      case TileLayoutStyle.standard:
        return 'Standard (Full Overlay)';
    }
  }

  static TileLayoutStyle fromString(String? v) {
    switch (v) {
      case 'splitLeft':
        return TileLayoutStyle.splitLeft;
      case 'splitRight':
        return TileLayoutStyle.splitRight;
      default:
        return TileLayoutStyle.standard;
    }
  }
}

// ─── Known routes users can navigate to ───────────────────────────────────────
const _kRouteOptions = [
  {'label': 'Home', 'value': '/home'},
  {'label': 'Bible / AI Bible', 'value': '/bible'},
  {'label': 'Sermons', 'value': '/sermons'},
  {'label': 'Devotionals', 'value': '/devotional'},
  {'label': 'Live Stream', 'value': '/live'},
  {'label': 'Events', 'value': '/events'},
  {'label': 'Hymns', 'value': '/hymns'},
  {'label': 'Blog', 'value': '/blog'},
  {'label': 'Library', 'value': '/library'},
  {'label': 'Members Connect', 'value': '/members'},
  {'label': 'Videos', 'value': '/videos'},
  {'label': 'Gallery', 'value': '/gallery'},
  {'label': 'Notes', 'value': '/notes'},
  {'label': 'Settings', 'value': '/settings'},
  {'label': 'Donations', 'value': '/donations'},
];

// ─── Homepage Template Manager ────────────────────────────────────────────────
class HomeTemplateManager extends StatefulWidget {
  const HomeTemplateManager({super.key});

  @override
  State<HomeTemplateManager> createState() => _HomeTemplateManagerState();
}

class _HomeTemplateManagerState extends State<HomeTemplateManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _activeTemplateId = 'classic';
  bool _loadingActive = true;

  static const _templates = [
    {'id': 'classic', 'name': 'Classic (Grid Style)'},
    {'id': 'banner_cards', 'name': 'Banner Cards (T30 Style)'},
    {'id': 'banner_style', 'name': 'Banner Style'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _templates.length, vsync: this);
    _loadActiveTemplate();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadActiveTemplate() async {
    final doc = await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('ui_config')
        .get();
    if (mounted) {
      setState(() {
        _activeTemplateId =
            (doc.data()?['activeHomeTemplate'] as String?) ?? 'classic';
        _loadingActive = false;
      });
    }
  }

  Future<void> _setActiveTemplate(String templateId) async {
    await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('ui_config')
        .set({'activeHomeTemplate': templateId}, SetOptions(merge: true));
    setState(() => _activeTemplateId = templateId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Homepage template switched! All users will see the new layout.'),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        const Divider(height: 1),
        // Tab bar
        TabBar(
          controller: _tabCtrl,
          tabs: _templates
              .map((t) => Tab(text: t['name']!))
              .toList(),
          isScrollable: false,
        ),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: _templates.map((t) {
              final templateId = t['id']!;
              return _TemplateTab(
                templateId: templateId,
                templateName: t['name']!,
                isActive: templateId == _activeTemplateId,
                onActivate: () => _setActiveTemplate(templateId),
                loadingActive: _loadingActive,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Homepage Templates',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage the layout users see on the homepage. Changes take effect instantly for all active users.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-template Tab ─────────────────────────────────────────────────────────
class _TemplateTab extends StatelessWidget {
  const _TemplateTab({
    required this.templateId,
    required this.templateName,
    required this.isActive,
    required this.onActivate,
    required this.loadingActive,
  });

  final String templateId;
  final String templateName;
  final bool isActive;
  final VoidCallback onActivate;
  final bool loadingActive;

  @override
  Widget build(BuildContext context) {
    final hasTiles = templateId == 'banner_cards' || templateId == 'banner_style';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Activation card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(templateName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        isActive
                            ? '✅ Currently active — users see this template.'
                            : 'Inactive — click "Activate" to make this the live template.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isActive ? Colors.green[700] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  ElevatedButton(
                    onPressed: loadingActive ? null : onActivate,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo),
                    child: const Text('Activate',
                        style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Templates with editable tiles
        if (hasTiles) ...[
          _TileManagerSection(templateId: templateId),
        ] else ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'The Classic template uses the app\'s built-in layout.\n'
                'No tiles to configure — it automatically shows the banner carousel,\n'
                'quick action buttons, verse of the day, and media sections.',
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Tile Manager Section ─────────────────────────────────────────────────────
class _TileManagerSection extends StatelessWidget {
  const _TileManagerSection({required this.templateId});
  final String templateId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Homepage Tiles',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showTileDialog(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Add Tile'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Drag to reorder. Each tile links to an in-app screen when tapped.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('home_templates')
              .doc(templateId)
              .collection('tiles')
              .orderBy('sortOrder')
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text('Error: ${snap.error}');
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No tiles yet.\nTap "Add Tile" to create the first one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }
            return ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIdx, newIdx) =>
                  _onReorder(context, docs, oldIdx, newIdx),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                return _TileListItem(
                  key: ValueKey(doc.id),
                  doc: doc,
                  templateId: templateId,
                  onEdit: () => _showTileDialog(context, doc),
                  onDelete: () => _deleteTile(context, doc),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _onReorder(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    int oldIdx,
    int newIdx,
  ) async {
    if (newIdx > oldIdx) newIdx--;
    final batch = FirebaseFirestore.instance.batch();
    final reordered = [...docs];
    final moved = reordered.removeAt(oldIdx);
    reordered.insert(newIdx, moved);
    for (var i = 0; i < reordered.length; i++) {
      batch.update(reordered[i].reference, {'sortOrder': i});
    }
    await batch.commit();
  }

  Future<void> _deleteTile(
      BuildContext context, QueryDocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Tile?'),
        content: Text(
            'Are you sure you want to delete "${doc['title']}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await doc.reference.delete();
    }
  }

  void _showTileDialog(BuildContext context, QueryDocumentSnapshot? doc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TileFormDialog(templateId: templateId, doc: doc),
    );
  }
}

// ─── Tile List Item ───────────────────────────────────────────────────────────
class _TileListItem extends StatelessWidget {
  const _TileListItem({
    super.key,
    required this.doc,
    required this.templateId,
    required this.onEdit,
    required this.onDelete,
  });

  final QueryDocumentSnapshot doc;
  final String templateId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final isActive = data['isActive'] as bool? ?? true;
    final imageUrl = data['imageUrl'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderIcon())
              : _placeholderIcon(),
        ),
        title: Text(
          data['title'] as String? ?? '—',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${data['route'] ?? ''}  •  ${TileLayoutStyle.fromString(data['layoutStyle'] as String?).label}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active toggle
            Switch(
              value: isActive,
              onChanged: (val) =>
                  doc.reference.update({'isActive': val}),
            ),
            IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.red),
                onPressed: onDelete),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[200],
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
}

// ─── Tile Form Dialog ─────────────────────────────────────────────────────────
class _TileFormDialog extends StatefulWidget {
  const _TileFormDialog({required this.templateId, this.doc});
  final String templateId;
  final QueryDocumentSnapshot? doc;

  @override
  State<_TileFormDialog> createState() => _TileFormDialogState();
}

class _TileFormDialogState extends State<_TileFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _actionLabelCtrl;
  late TextEditingController _backgroundColorCtrl;

  String _selectedRoute = '/home';
  TileLayoutStyle _layoutStyle = TileLayoutStyle.standard;
  bool _isActive = true;
  bool _showTitle = true;
  bool _showGradient = true;
  String _gradientAlignment = 'centerLeft';
  String _buttonAlignment = 'bottomLeft';
  bool _showExternalText = false;
  late TextEditingController _externalTextCtrl;

  String? _imageUrl;
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data() as Map<String, dynamic>?;
    _titleCtrl = TextEditingController(text: data?['title'] ?? '');
    _subtitleCtrl = TextEditingController(text: data?['subtitle'] ?? '');
    _actionLabelCtrl = TextEditingController(text: data?['actionLabel'] ?? '');
    _backgroundColorCtrl = TextEditingController(text: data?['backgroundColorHex'] ?? '');
    _selectedRoute = data?['route'] ?? '/home';
    _layoutStyle = TileLayoutStyle.fromString(data?['layoutStyle'] as String?);
    _isActive = data?['isActive'] as bool? ?? true;
    _showTitle = data?['showTitle'] as bool? ?? true;
    _showGradient = data?['showGradient'] as bool? ?? true;
    _gradientAlignment = data?['gradientAlignment'] as String? ?? 'centerLeft';
    _buttonAlignment = data?['buttonAlignment'] as String? ?? 'bottomLeft';
    _showExternalText = data?['showExternalText'] as bool? ?? false;
    _externalTextCtrl = TextEditingController(text: data?['externalText'] ?? '');
    _imageUrl = data?['imageUrl'] as String?;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _actionLabelCtrl.dispose();
    _backgroundColorCtrl.dispose();
    _externalTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
    } catch (_) {
      // FilePicker may throw on some platforms
    }
    if (result == null || result.files.isEmpty) return;

    setState(() => _uploading = true);

    try {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file bytes');

      final fileName =
          'home_tiles/${widget.templateId}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      final ref = FirebaseStorage.instance.ref().child(fileName);
      final task = await ref.putData(bytes);
      final url = await task.ref.getDownloadURL();

      setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      // Ensure the template document exists
      final templateRef = FirebaseFirestore.instance
          .collection('home_templates')
          .doc(widget.templateId);
      final templateSnap = await templateRef.get();
      if (!templateSnap.exists) {
        await templateRef.set({
          'name': widget.templateId == 'banner_cards'
              ? 'Banner Cards (T30 Style)'
              : widget.templateId == 'banner_style'
                  ? 'Banner Style'
                  : 'Classic',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final tilesCollection = templateRef.collection('tiles');

      // Compute sort order for new tiles
      int sortOrder = 0;
      if (widget.doc == null) {
        final snap = await tilesCollection
            .orderBy('sortOrder', descending: true)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          sortOrder = ((snap.docs.first.data()['sortOrder'] as num?)
                  ?.toInt() ??
              0) +
              1;
        }
      } else {
        sortOrder = (widget.doc!.data()
                as Map<String, dynamic>)['sortOrder'] as int? ??
            0;
      }

      final payload = {
        'title': _titleCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim().isEmpty
            ? null
            : _subtitleCtrl.text.trim(),
        'actionLabel': _actionLabelCtrl.text.trim().isEmpty
            ? null
            : _actionLabelCtrl.text.trim().toUpperCase(),
        'backgroundColorHex': _backgroundColorCtrl.text.trim().isEmpty
            ? null
            : _backgroundColorCtrl.text.trim(),
        'route': _selectedRoute,
        'imageUrl': _imageUrl ?? '',
        'layoutStyle': _layoutStyle.value,
        'isActive': _isActive,
        'showTitle': _showTitle,
        'showGradient': _showGradient,
        'gradientAlignment': _gradientAlignment,
        'buttonAlignment': _buttonAlignment,
        'showExternalText': _showExternalText,
        'externalText': _externalTextCtrl.text.trim().isEmpty ? null : _externalTextCtrl.text.trim(),
        'sortOrder': sortOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.doc == null) {
        await tilesCollection.add(payload);
      } else {
        await widget.doc!.reference.update(payload);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.doc == null
                ? 'Tile created successfully!'
                : 'Tile updated successfully!'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Save failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.doc != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Tile' : 'New Tile'),
            leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop()),
            actions: [
              TextButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save Tile'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Image Picker ────────────────────────────────────────────
                _buildSectionLabel('Tile Image'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _uploading ? null : _pickAndUploadImage,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _uploading
                        ? const Center(child: CircularProgressIndicator())
                        : _imageUrl != null && _imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(_imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity))
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Click to upload image',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                  ),
                ),
                if (_imageUrl != null && _imageUrl!.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _imageUrl = null),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Remove Image'),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Background Color ─────────────────────────────────────────
                _buildSectionLabel('Background Color (Hex) (optional)'),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _backgroundColorCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. #7A1515',
                    helperText: 'Used if no image is provided, or as the background behind the image.',
                  ),
                  onChanged: (v) => setState(() {}),
                ),
                if (_backgroundColorCtrl.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Text('Preview: ', style: TextStyle(fontSize: 12)),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _parseHexColor(_backgroundColorCtrl.text.trim()),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Layout Style ────────────────────────────────────────────
                _buildSectionLabel('Layout Style'),
                const SizedBox(height: 4),
                DropdownButtonFormField<TileLayoutStyle>(
                  value: _layoutStyle,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: TileLayoutStyle.values
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _layoutStyle = v ?? _layoutStyle),
                ),

                const SizedBox(height: 16),

                // ── Title ────────────────────────────────────────────────────
                _buildSectionLabel('Title *'),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. READ THE DEVOTIONAL',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Title is required' : null,
                  textCapitalization: TextCapitalization.characters,
                ),

                const SizedBox(height: 16),

                // ── Subtitle ─────────────────────────────────────────────────
                _buildSectionLabel('Subtitle (optional)'),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _subtitleCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. OR CATCH UP',
                  ),
                ),

                const SizedBox(height: 16),

                // ── CTA Label ────────────────────────────────────────────────
                _buildSectionLabel('Action Button Label (optional)'),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _actionLabelCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. STUDY, GIVE, WATCH',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),

                const SizedBox(height: 16),

                // ── Destination Route ─────────────────────────────────────────
                _buildSectionLabel('Destination Route *'),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _selectedRoute,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _kRouteOptions
                      .map((r) => DropdownMenuItem<String>(
                          value: r['value'],
                          child: Text('${r['label']}  (${r['value']})')))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedRoute = v ?? _selectedRoute),
                ),

                const SizedBox(height: 16),

                // ── Display Options ───────────────────────────────────────────
                _buildSectionLabel('Display Options'),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Show Title on Tile'),
                  value: _showTitle,
                  onChanged: (v) => setState(() => _showTitle = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (widget.templateId == 'banner_style') ...[
                  SwitchListTile(
                    title: const Text('Add Text Outside Banner'),
                    subtitle: const Text('Displays text below the banner image'),
                    value: _showExternalText,
                    onChanged: (v) => setState(() => _showExternalText = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_showExternalText) ...[
                    const SizedBox(height: 8),
                    _buildSectionLabel('External Text'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _externalTextCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Connect Card',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                SwitchListTile(
                  title: const Text('Show Gradient Overlay'),
                  subtitle: const Text('For Standard Layout only'),
                  value: _showGradient,
                  onChanged: (v) => setState(() => _showGradient = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_showGradient && _layoutStyle == TileLayoutStyle.standard) ...[
                  const SizedBox(height: 12),
                  _buildSectionLabel('Gradient & Text Alignment'),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _gradientAlignment,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'centerLeft', child: Text('Left')),
                      DropdownMenuItem(value: 'centerRight', child: Text('Right')),
                      DropdownMenuItem(value: 'topCenter', child: Text('Top')),
                      DropdownMenuItem(value: 'bottomCenter', child: Text('Bottom')),
                      DropdownMenuItem(value: 'center', child: Text('Center')),
                    ],
                    onChanged: (v) =>
                        setState(() => _gradientAlignment = v ?? _gradientAlignment),
                  ),
                ],

                const SizedBox(height: 16),
                _buildSectionLabel('Button Position'),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _buttonAlignment,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'bottomLeft', child: Text('Bottom Left')),
                    DropdownMenuItem(value: 'bottomRight', child: Text('Bottom Right')),
                    DropdownMenuItem(value: 'topLeft', child: Text('Top Left')),
                    DropdownMenuItem(value: 'topRight', child: Text('Top Right')),
                    DropdownMenuItem(value: 'center', child: Text('Center')),
                  ],
                  onChanged: (v) =>
                      setState(() => _buttonAlignment = v ?? _buttonAlignment),
                ),

                const SizedBox(height: 16),

                // ── Active toggle ─────────────────────────────────────────────
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text(
                      'Inactive tiles are hidden from users but saved.'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));
  }

  Color _parseHexColor(String hexString) {
    hexString = hexString.toUpperCase().replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF$hexString';
    }
    int? val = int.tryParse(hexString, radix: 16);
    return val != null ? Color(val) : Colors.transparent;
  }
}
